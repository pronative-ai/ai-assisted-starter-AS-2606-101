async function queryLogs(db, filters = {}) {
  const { from, to, level, module, pipeline_run_id, order_id, search, limit = 100, offset = 0 } = filters;

  const conditions = [];
  const params = [];

  if (from) { params.push(from); conditions.push(`timestamp >= $${params.length}`); }
  if (to) { params.push(to); conditions.push(`timestamp <= $${params.length}`); }
  if (level) { params.push(level); conditions.push(`level = $${params.length}`); }
  if (module) { params.push(module); conditions.push(`module = $${params.length}`); }
  if (pipeline_run_id) { params.push(pipeline_run_id); conditions.push(`pipeline_run_id = $${params.length}`); }
  if (order_id) { params.push(order_id); conditions.push(`order_id = $${params.length}`); }
  if (search) { params.push(`%${search}%`); conditions.push(`message ILIKE $${params.length}`); }

  const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
  params.push(limit, offset);

  const sql = `
    SELECT id, timestamp, level, pipeline_run_id, module, operation, message, details, order_id, duration_ms
    FROM log_entries
    ${where}
    ORDER BY timestamp DESC
    LIMIT $${params.length - 1} OFFSET $${params.length}
  `;

  const result = await db.query(sql, params);
  return result.rows;
}

async function writeLog(db, entry) {
  const { level, module, operation, message, details, pipeline_run_id, order_id, duration_ms } = entry;
  await db.query(
    `INSERT INTO log_entries (timestamp, level, module, operation, message, details, pipeline_run_id, order_id, duration_ms)
     VALUES (NOW(), $1, $2, $3, $4, $5, $6, $7, $8)`,
    [level, module, operation, message, JSON.stringify(details || {}), pipeline_run_id || null, order_id || null, duration_ms || null]
  );
}

async function archiveLogs(db, olderThan) {
  const result = await db.query(
    `DELETE FROM log_entries WHERE timestamp < $1`,
    [olderThan]
  );
  return result.rowCount;
}

module.exports = { queryLogs, writeLog, archiveLogs };
