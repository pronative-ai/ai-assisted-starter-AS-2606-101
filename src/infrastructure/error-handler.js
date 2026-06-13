const { withRetry } = require('./retry');

const RETRIABLE_CODES = new Set(['ECONNRESET', 'ECONNREFUSED', 'ETIMEDOUT', 'ENOTFOUND']);

function isRetriable(err) {
  if (err.code && RETRIABLE_CODES.has(err.code)) return true;
  if (err.status === 429) return true; // rate limited
  if (err.status >= 500 && err.status < 600) return true;
  return false;
}

async function withErrorHandling(fn, options = {}) {
  const { logger, operation = 'unknown', maxAttempts = 3 } = options;

  return withRetry(
    async (attempt) => {
      const start = Date.now();
      try {
        const result = await fn();
        if (logger) logger.info(operation, 'completed', {}, { duration_ms: Date.now() - start });
        return result;
      } catch (err) {
        if (logger) logger.error(operation, err.message, { attempt, code: err.code, stack: err.stack });
        throw err;
      }
    },
    {
      maxAttempts,
      onRetry: (err, attempt, delay) => {
        if (logger) {
          logger.warn(operation, `retrying after error (attempt ${attempt})`, {
            delay_ms: Math.round(delay),
            error: err.message,
            retriable: isRetriable(err)
          });
        }
      }
    }
  );
}

module.exports = { withErrorHandling, isRetriable };
