const { createLogger, setDbWriter } = require('../logger');

afterEach(() => setDbWriter(null));

describe('createLogger', () => {
  it('returns an object with all log level methods', () => {
    const logger = createLogger('test-module');
    expect(typeof logger.debug).toBe('function');
    expect(typeof logger.info).toBe('function');
    expect(typeof logger.warn).toBe('function');
    expect(typeof logger.error).toBe('function');
  });

  it('calls dbWriter when set', async () => {
    const writes = [];
    setDbWriter(async (entry) => writes.push(entry));

    const logger = createLogger('test-module');
    logger.info('test-op', 'hello world', { foo: 'bar' }, { pipeline_run_id: 'run_001' });

    await new Promise(r => setTimeout(r, 20));

    expect(writes).toHaveLength(1);
    expect(writes[0].level).toBe('info');
    expect(writes[0].module).toBe('test-module');
    expect(writes[0].operation).toBe('test-op');
    expect(writes[0].pipeline_run_id).toBe('run_001');
  });

  it('does not throw if dbWriter rejects', async () => {
    setDbWriter(async () => { throw new Error('db down'); });
    const logger = createLogger('test-module');
    expect(() => logger.error('op', 'something failed')).not.toThrow();
  });

  it('does not call dbWriter when none is set', () => {
    setDbWriter(null);
    const logger = createLogger('test-module');
    expect(() => logger.info('op', 'message')).not.toThrow();
  });
});
