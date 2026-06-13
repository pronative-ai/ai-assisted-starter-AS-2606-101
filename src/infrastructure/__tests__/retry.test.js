const { withRetry } = require('../retry');

describe('withRetry', () => {
  it('returns result immediately on first success', async () => {
    const result = await withRetry(async () => 42);
    expect(result).toBe(42);
  });

  it('retries and succeeds on the second attempt', async () => {
    let attempts = 0;
    const result = await withRetry(
      async () => {
        attempts++;
        if (attempts < 2) throw new Error('transient');
        return 'ok';
      },
      { maxAttempts: 3, backoffMs: 10 }
    );
    expect(result).toBe('ok');
    expect(attempts).toBe(2);
  });

  it('throws the last error after maxAttempts', async () => {
    let attempts = 0;
    await expect(
      withRetry(
        async () => { attempts++; throw new Error('permanent'); },
        { maxAttempts: 3, backoffMs: 10 }
      )
    ).rejects.toThrow('permanent');
    expect(attempts).toBe(3);
  });

  it('calls onRetry with correct attempt number and positive delay', async () => {
    const retries = [];
    await withRetry(
      async (attempt) => { if (attempt < 2) throw new Error('err'); return 'done'; },
      { maxAttempts: 3, backoffMs: 10, onRetry: (err, attempt, delay) => retries.push({ attempt, delay }) }
    );
    expect(retries).toHaveLength(1);
    expect(retries[0].attempt).toBe(1);
    expect(retries[0].delay).toBeGreaterThan(0);
  });

  it('passes attempt number to fn', async () => {
    const seen = [];
    await withRetry(
      async (attempt) => { seen.push(attempt); if (attempt < 3) throw new Error('not yet'); return 'ok'; },
      { maxAttempts: 3, backoffMs: 10 }
    );
    expect(seen).toEqual([1, 2, 3]);
  });
});
