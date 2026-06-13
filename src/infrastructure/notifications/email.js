const nodemailer = require('nodemailer');
const fs = require('fs');
const path = require('path');

let _transporter = null;

function getTransporter() {
  if (!_transporter) {
    const config = JSON.parse(process.env.NOTIFICATION_EMAIL_CONFIG || '{}');
    _transporter = nodemailer.createTransport(config);
  }
  return _transporter;
}

function loadTemplate(name) {
  return fs.readFileSync(path.join(__dirname, 'templates', name), 'utf8');
}

function interpolate(template, vars) {
  return template.replace(/\{\{(\w+)\}\}/g, (_, key) => (vars[key] != null ? vars[key] : ''));
}

async function sendAlert(details) {
  const { to, pipelineRunId, error, module, timestamp } = details;
  const html = interpolate(loadTemplate('failure-alert.html'), {
    pipelineRunId: pipelineRunId || 'unknown',
    error: error || 'Unknown error',
    module: module || 'unknown',
    timestamp: timestamp || new Date().toISOString()
  });

  await getTransporter().sendMail({
    from: process.env.NOTIFICATION_FROM_EMAIL,
    to,
    subject: `[FBM Pipeline] Critical Failure — Run ${pipelineRunId || 'unknown'}`,
    html
  });
}

async function sendDailySummary(stats) {
  const { to, pipelineRunId, ordersRetrieved, ordersProcessed, ordersFlagged, labelsGenerated, errors, completedAt } = stats;
  const html = interpolate(loadTemplate('daily-summary.html'), {
    pipelineRunId: pipelineRunId || 'unknown',
    ordersRetrieved: ordersRetrieved ?? 0,
    ordersProcessed: ordersProcessed ?? 0,
    ordersFlagged: ordersFlagged ?? 0,
    labelsGenerated: labelsGenerated ?? 0,
    errorCount: errors?.length ?? 0,
    completedAt: completedAt || new Date().toISOString()
  });

  await getTransporter().sendMail({
    from: process.env.NOTIFICATION_FROM_EMAIL,
    to,
    subject: `[FBM Pipeline] Daily Summary — ${new Date().toLocaleDateString('de-DE')}`,
    html
  });
}

module.exports = { sendAlert, sendDailySummary };
