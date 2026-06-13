async function withRetry(fn, options = {}) {
  const { maxAttempts = 3, backoffMs = 500, onRetry } = options;
  let lastError;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn(attempt);
    } catch (err) {
      lastError = err;
      if (attempt === maxAttempts) break;

      const delay = backoffMs * Math.pow(2, attempt - 1) + Math.random() * 100;
      if (onRetry) onRetry(err, attempt, delay);
      await _sleep(delay);
    }
  }

  throw lastError;
}

function _sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = { withRetry };
