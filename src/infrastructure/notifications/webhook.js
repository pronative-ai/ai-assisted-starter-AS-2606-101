const https = require('https');
const http = require('http');
const { URL } = require('url');

function post(webhookUrl, payload) {
  return new Promise((resolve, reject) => {
    const url = new URL(webhookUrl);
    const body = JSON.stringify(payload);
    const lib = url.protocol === 'https:' ? https : http;

    const req = lib.request(
      {
        hostname: url.hostname,
        port: url.port || (url.protocol === 'https:' ? 443 : 80),
        path: url.pathname + url.search,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body)
        }
      },
      (res) => {
        let data = '';
        res.on('data', chunk => { data += chunk; });
        res.on('end', () => resolve({ status: res.statusCode, body: data }));
      }
    );

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function sendAlert(details) {
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;
  if (!webhookUrl) return;

  const { pipelineRunId, error, module } = details;
  await post(webhookUrl, {
    blocks: [
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `:red_circle: *FBM Pipeline — Critical Failure*\n*Run ID:* ${pipelineRunId || 'unknown'}\n*Module:* ${module || 'unknown'}\n*Error:* ${error || 'Unknown error'}`
        }
      }
    ]
  });
}

async function sendDailySummary(stats) {
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;
  if (!webhookUrl) return;

  const { pipelineRunId, ordersRetrieved = 0, ordersProcessed = 0, ordersFlagged = 0, labelsGenerated = 0 } = stats;
  await post(webhookUrl, {
    blocks: [
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `:white_check_mark: *FBM Pipeline — Daily Summary*\n*Run ID:* ${pipelineRunId}\n*Retrieved:* ${ordersRetrieved}  |  *Processed:* ${ordersProcessed}  |  *Flagged:* ${ordersFlagged}  |  *Labels:* ${labelsGenerated}`
        }
      }
    ]
  });
}

module.exports = { sendAlert, sendDailySummary };
