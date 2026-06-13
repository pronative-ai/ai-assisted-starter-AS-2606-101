const { Router } = require('express');

const router = Router();

// Injected by the app bootstrap once a DB pool is available
let _dbCheck = null;

function setDbCheck(fn) {
  _dbCheck = fn;
}

// Liveness — always 200 if the process is up
router.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Readiness — 503 if the DB is unreachable
router.get('/ready', async (_req, res) => {
  try {
    if (_dbCheck) await _dbCheck();
    res.status(200).json({ status: 'ready', timestamp: new Date().toISOString() });
  } catch (err) {
    res.status(503).json({ status: 'not_ready', error: err.message, timestamp: new Date().toISOString() });
  }
});

module.exports = { router, setDbCheck };
