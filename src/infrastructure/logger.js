const pino = require('pino');

const level = process.env.LOG_LEVEL || 'info';

const baseLogger = pino({
  level,
  formatters: {
    level(label) {
      return { level: label };
    }
  },
  timestamp: pino.stdTimeFunctions.isoTime,
  base: null
});

// Injected lazily to avoid circular dependencies with the DB layer
let dbWriter = null;

function setDbWriter(writer) {
  dbWriter = writer;
}

function createLogger(module) {
  const child = baseLogger.child({ module });

  return {
    debug: (operation, message, details, context) =>
      _log(child, 'debug', module, operation, message, details, context),
    info: (operation, message, details, context) =>
      _log(child, 'info', module, operation, message, details, context),
    warn: (operation, message, details, context) =>
      _log(child, 'warn', module, operation, message, details, context),
    error: (operation, message, details, context) =>
      _log(child, 'error', module, operation, message, details, context)
  };
}

function _log(pinoChild, level, module, operation, message, details = {}, context = {}) {
  const { pipeline_run_id, order_id, duration_ms } = context;
  pinoChild[level]({ operation, details, pipeline_run_id, order_id, duration_ms }, message);

  if (dbWriter) {
    dbWriter({ level, module, operation, message, details, pipeline_run_id, order_id, duration_ms })
      .catch(() => {}); // never let logging errors surface to callers
  }
}

module.exports = { createLogger, setDbWriter };
