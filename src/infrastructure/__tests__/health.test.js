const request = require('supertest');
const express = require('express');
const { router, setDbCheck } = require('../health');

afterEach(() => setDbCheck(null));

function createApp() {
  const app = express();
  app.use(router);
  return app;
}

describe('GET /health', () => {
  it('returns 200 with status ok', async () => {
    const res = await request(createApp()).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.timestamp).toBeDefined();
  });
});

describe('GET /ready', () => {
  it('returns 200 when db check passes', async () => {
    setDbCheck(async () => {});
    const res = await request(createApp()).get('/ready');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ready');
  });

  it('returns 503 when db check throws', async () => {
    setDbCheck(async () => { throw new Error('connection refused'); });
    const res = await request(createApp()).get('/ready');
    expect(res.status).toBe(503);
    expect(res.body.status).toBe('not_ready');
    expect(res.body.error).toBe('connection refused');
  });

  it('returns 200 when no db check is configured', async () => {
    setDbCheck(null);
    const res = await request(createApp()).get('/ready');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ready');
  });
});
