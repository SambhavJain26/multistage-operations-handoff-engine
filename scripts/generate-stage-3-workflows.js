const fs = require("fs");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const outDir = path.join(repoRoot, "n8n-workflows");
fs.mkdirSync(outDir, { recursive: true });

const pgCred = { id: "cred_make_ready_pg", name: "Make-Ready Postgres" };
const tgCred = { id: "jASZWMlrfp3v2tWH", name: "Make-Ready Manager Telegram Bot" };

function wf(id, name, nodes, connections, active = false) {
  return {
    id,
    name,
    active,
    nodes,
    connections,
    settings: { executionOrder: "v1" },
    staticData: null,
    pinData: {},
    versionId: `${id}-v1`,
    triggerCount: 0,
    tags: [],
  };
}

function codeNode(id, name, x, y, jsCode) {
  return {
    id,
    name,
    type: "n8n-nodes-base.code",
    typeVersion: 2,
    position: [x, y],
    parameters: { jsCode },
  };
}

function pgNode(id, name, x, y, query) {
  return {
    id,
    name,
    type: "n8n-nodes-base.postgres",
    typeVersion: 2.6,
    position: [x, y],
    parameters: { operation: "executeQuery", query, options: {} },
    credentials: { postgres: pgCred },
  };
}

function ifNode(id, name, x, y, expression) {
  return {
    id,
    name,
    type: "n8n-nodes-base.if",
    typeVersion: 2.3,
    position: [x, y],
    parameters: {
      conditions: {
        options: {
          caseSensitive: true,
          leftValue: "",
          typeValidation: "strict",
          version: 2,
        },
        conditions: [
          {
            id: `${id}-condition`,
            leftValue: expression,
            rightValue: true,
            operator: { type: "boolean", operation: "true", singleValue: true },
          },
        ],
        combinator: "and",
      },
      options: {},
    },
  };
}

function respondNode(id, name, x, y, code) {
  return {
    id,
    name,
    type: "n8n-nodes-base.respondToWebhook",
    typeVersion: 1.5,
    position: [x, y],
    parameters: {
      respondWith: "json",
      responseBody: "={{ JSON.stringify($json) }}",
      options: {
        responseCode: code,
        responseHeaders: {
          entries: [
            { name: "Content-Type", value: "application/json" },
            {
              name: "Access-Control-Allow-Origin",
              value:
                '={{ $json.cors_origin || "http://localhost:8080" }}',
            },
          ],
        },
      },
    },
  };
}

function executeNode(id, name, x, y, workflowId) {
  return {
    id,
    name,
    type: "n8n-nodes-base.executeWorkflow",
    typeVersion: 1,
    position: [x, y],
    parameters: {
      source: "database",
      workflowId,
      options: { waitForSubWorkflow: true },
    },
  };
}

const boardQuery = `WITH metrics AS (
  SELECT
    COALESCE((
      SELECT round(100.0 * count(*) FILTER (WHERE completed_via = 'vendor_reply') / nullif(count(*), 0))::int
      FROM turn_stage
      WHERE vendor_id IS NOT NULL
        AND status IN ('complete', 'skipped')
        AND completed_at > now() - interval '30 days'
    ), 0) AS vendor_reply_rate,
    COALESCE((
      SELECT round(100.0 * count(*) FILTER (WHERE event_type = 'stage_complete') / nullif(count(*), 0))::int
      FROM event_log
      WHERE actor_type = 'vendor'
        AND created_at > now() - interval '30 days'
    ), 0) AS auto_handled_rate
), active_stage AS (
  SELECT DISTINCT ON (turn_id) *
  FROM turn_stage
  WHERE status IN ('active', 'awaiting_approval')
  ORDER BY turn_id, CASE WHEN status = 'active' THEN 0 ELSE 1 END, seq
), latest_event AS (
  SELECT DISTINCT ON (turn_id)
    turn_id,
    event_type,
    actor_type,
    channel,
    raw_text,
    created_at
  FROM event_log
  WHERE turn_id IS NOT NULL
  ORDER BY turn_id, created_at DESC, id DESC
)
SELECT
  t.id AS turn_id,
  t.unit_label,
  t.property_address,
  t.rent_monthly::float AS rent_monthly,
  t.notice_date,
  t.moveout_date,
  t.target_ready_date,
  t.status AS turn_status,
  ast.id AS current_stage_id,
  ast.seq AS current_seq,
  ast.stage_code AS current_stage_code,
  ast.stage_name AS current_stage_name,
  ast.status AS current_stage_status,
  ast.sla_hours AS current_sla_hours,
  ast.activated_at AS current_activated_at,
  v.name AS current_vendor_name,
  v.trade AS current_vendor_trade,
  le.event_type AS latest_event_type,
  le.actor_type AS latest_event_actor_type,
  le.channel AS latest_event_channel,
  le.raw_text AS latest_event_text,
  le.created_at AS latest_event_at,
  metrics.vendor_reply_rate,
  metrics.auto_handled_rate,
  jsonb_agg(jsonb_build_object(
    'id', s.id,
    'seq', s.seq,
    'stage_code', s.stage_code,
    'stage_name', s.stage_name,
    'status', s.status,
    'sla_hours', s.sla_hours,
    'activated_at', s.activated_at,
    'completed_at', s.completed_at,
    'completed_via', s.completed_via,
    'vendor_name', sv.name,
    'evidence_photo', s.evidence_photo
  ) ORDER BY s.seq) AS stages
FROM "turn" t
JOIN active_stage ast ON ast.turn_id = t.id
LEFT JOIN vendor v ON v.id = ast.vendor_id
JOIN turn_stage s ON s.turn_id = t.id
LEFT JOIN vendor sv ON sv.id = s.vendor_id
LEFT JOIN latest_event le ON le.turn_id = t.id
CROSS JOIN metrics
WHERE t.status = 'active'
GROUP BY
  t.id, ast.id, ast.seq, ast.stage_code, ast.stage_name, ast.status, ast.sla_hours, ast.activated_at, v.id, v.name, v.trade,
  le.turn_id, le.event_type, le.actor_type, le.channel, le.raw_text, le.created_at,
  metrics.vendor_reply_rate, metrics.auto_handled_rate
ORDER BY t.unit_label;`;

const shapeBoardCode = `const rows = items.map(item => item.json);
const generatedAt = new Date();
const healthRank = { red: 3, amber: 2, green: 1 };
function parseStages(value) {
  if (Array.isArray(value)) return value;
  if (!value) return [];
  try { return JSON.parse(value); } catch { return []; }
}
function hoursSince(value) {
  if (!value) return 0;
  return Math.max(0, (generatedAt.getTime() - new Date(value).getTime()) / 36e5);
}
function wholeVacancyDays(moveoutDate) {
  if (!moveoutDate) return 0;
  const today = new Date(generatedAt.toISOString().slice(0, 10) + 'T00:00:00Z');
  const moveout = new Date(String(moveoutDate).slice(0, 10) + 'T00:00:00Z');
  return Math.max(0, Math.floor((today.getTime() - moveout.getTime()) / 864e5));
}
function healthFor(hours, slaHours) {
  const sla = Number(slaHours || 0);
  if (sla <= 0) return 'green';
  const ratio = hours / sla;
  if (ratio >= 1) return 'red';
  if (ratio >= 0.5) return 'amber';
  return 'green';
}
function latestEvent(row) {
  if (!row.latest_event_type) return null;
  return {
    event_type: row.latest_event_type,
    actor_type: row.latest_event_actor_type,
    channel: row.latest_event_channel,
    text: row.latest_event_text,
    created_at: row.latest_event_at
  };
}
const turns = rows.map(row => {
  const stages = parseStages(row.stages).map(stage => ({
    id: Number(stage.id),
    seq: Number(stage.seq),
    stage_code: stage.stage_code,
    stage_name: stage.stage_name,
    status: stage.status,
    sla_hours: Number(stage.sla_hours || 0),
    activated_at: stage.activated_at,
    completed_at: stage.completed_at,
    completed_via: stage.completed_via,
    vendor_name: stage.vendor_name || 'Unassigned',
    evidence_photo: stage.evidence_photo || null
  }));
  const hours = hoursSince(row.current_activated_at);
  const vacancyDays = wholeVacancyDays(row.moveout_date);
  const dollars = Math.round((Number(row.rent_monthly || 0) / 30) * vacancyDays);
  const health = healthFor(hours, row.current_sla_hours);
  return {
    turn_id: Number(row.turn_id),
    unit_label: row.unit_label,
    property_address: row.property_address,
    rent_monthly: Number(row.rent_monthly || 0),
    notice_date: row.notice_date,
    moveout_date: row.moveout_date,
    target_ready_date: row.target_ready_date,
    current_stage: {
      id: Number(row.current_stage_id),
      seq: Number(row.current_seq),
      stage_code: row.current_stage_code,
      stage_name: row.current_stage_name,
      status: row.current_stage_status,
      sla_hours: Number(row.current_sla_hours || 0),
      activated_at: row.current_activated_at,
      assigned_vendor: row.current_vendor_name || 'Unassigned'
    },
    stages,
    latest_event: latestEvent(row),
    hours_at_stage: Math.round(hours * 10) / 10,
    days_at_stage: Math.round((hours / 24) * 10) / 10,
    days_vacant: vacancyDays,
    dollars_burned: dollars,
    health,
    health_rank: healthRank[health]
  };
}).sort((a, b) => (b.health_rank - a.health_rank) || (b.hours_at_stage - a.hours_at_stage) || a.unit_label.localeCompare(b.unit_label));
const payload = {
  generated_at: generatedAt.toISOString(),
  demo: { label: 'DEMO DATA - Cedar Ridge is fictional', timezone: 'America/Phoenix' },
  metrics: {
    active_turns: turns.length,
    dollars_burning_now: turns.reduce((sum, turn) => sum + turn.dollars_burned, 0),
    vendor_reply_rate: rows[0] ? Number(rows[0].vendor_reply_rate || 0) : 0,
    auto_handled_rate: rows[0] ? Number(rows[0].auto_handled_rate || 0) : 0,
    window_days: 30
  },
  turns,
  cors_origin: 'http://localhost:8080'
};
return [{ json: payload }];`;

const normalizeBoardAuthCode = `const headers = $json.headers || {};
const query = $json.query || {};
const configuredToken = 'local-stage-3-demo-token';
const suppliedToken = query.token || headers['x-demo-token'] || headers['X-Demo-Token'] || '';
return [{ json: {
  authorized: Boolean(configuredToken) && String(suppliedToken) === String(configuredToken),
  cors_origin: 'http://localhost:8080'
} }];`;

const unauthorizedCode = `return [{ json: {
  error: 'unauthorized',
  message: 'Missing or invalid demo token.',
  cors_origin: 'http://localhost:8080'
} }];`;

const guardQuery = `WITH input AS (
  SELECT
    {{ Number($json.stage_id || 0) }}::int AS stage_id,
    '{{ String($json.actor_id || "board-manager").replace(/'/g, "''") }}'::text AS actor_id,
    '{{ String($json.channel || "board").replace(/'/g, "''") }}'::text AS channel,
    '{{ String($json.actor_type || (($json.envelope || {}).actor_type) || "manager").replace(/'/g, "''") }}'::text AS actor_type,
    '{{ String($json.completed_via || (($json.envelope || {}).completed_via) || "").replace(/'/g, "''") }}'::text AS requested_completed_via,
    '{{ String($json.override_token || "").replace(/'/g, "''") }}'::text AS override_token,
    '{{ String($json.override_reason || "").replace(/'/g, "''") }}'::text AS override_reason,
    '{{ String($json.telegram_callback_query_id || "").replace(/'/g, "''") }}'::text AS telegram_callback_query_id,
    '{{ String($json.telegram_chat_id || "").replace(/'/g, "''") }}'::text AS telegram_chat_id,
    '{{ String($json.raw_text || (($json.envelope || {}).text) || "").replace(/'/g, "''") }}'::text AS raw_text,
    '{{ JSON.stringify($json.envelope || {}).replace(/'/g, "''") }}'::jsonb AS envelope,
    '{{ JSON.stringify($json.classification || {}).replace(/'/g, "''") }}'::jsonb AS classification,
    '{{ JSON.stringify($json.match || {}).replace(/'/g, "''") }}'::jsonb AS match,
    '{{ JSON.stringify($json.vendor || {}).replace(/'/g, "''") }}'::jsonb AS vendor_context
), target AS (
  SELECT
    ts.id,
    ts.turn_id,
    ts.seq,
    ts.stage_code,
    ts.stage_name,
    ts.status,
    t.unit_label,
    t.property_address
  FROM turn_stage ts
  JOIN "turn" t ON t.id = ts.turn_id
  JOIN input i ON i.stage_id = ts.id
), stage_rows AS (
  SELECT
    s.turn_id,
    jsonb_agg(jsonb_build_object(
      'id', s.id,
      'seq', s.seq,
      'stage_code', s.stage_code,
      'stage_name', s.stage_name,
      'status', s.status
    ) ORDER BY s.seq) AS stages
  FROM turn_stage s
  WHERE s.turn_id = (SELECT turn_id FROM target)
  GROUP BY s.turn_id
)
SELECT
  input.stage_id AS requested_stage_id,
  input.actor_id,
  input.channel,
  input.actor_type,
  input.requested_completed_via,
  input.override_token,
  input.override_reason,
  input.telegram_callback_query_id,
  input.telegram_chat_id,
  input.raw_text,
  input.envelope,
  input.classification,
  input.match,
  input.vendor_context,
  target.id AS stage_id,
  target.turn_id,
  target.seq,
  target.stage_code,
  target.stage_name,
  target.status,
  target.unit_label,
  target.property_address,
  COALESCE(stage_rows.stages, '[]'::jsonb) AS stages
FROM input
LEFT JOIN target ON TRUE
LEFT JOIN stage_rows ON stage_rows.turn_id = target.turn_id;`;

const guardCode = `const input = $json;
const stages = Array.isArray(input.stages) ? input.stages : (input.stages ? JSON.parse(input.stages) : []);
const stageByCode = new Map(stages.map(stage => [stage.stage_code, stage]));
const targetCode = input.stage_code;
const targetSeq = Number(input.seq);
const stageId = Number(input.stage_id || input.requested_stage_id || 0);
const requestedOverride = String(input.override_token || '').trim();
const overrideAccepted = requestedOverride.startsWith('OVR:' + stageId + ':');
const satisfied = stage => stage && ['complete', 'skipped'].includes(stage.status);
const required = [];
if (!input.stage_id) {
  return [{ json: { ...input, allowed: false, blocked_by: [], reason: 'Stage not found.', override_token: null } }];
}
if (['complete', 'skipped'].includes(input.status)) {
  return [{ json: { ...input, allowed: false, blocked_by: [], reason: input.stage_name + ' is already ' + input.status + '.', override_token: null } }];
}
if (targetSeq > 2) required.push('MOVEOUT');
const ruleMap = {
  PAINT: ['REPAIRS'],
  FLOORING: ['PAINT'],
  DEEP_CLEAN: ['REPAIRS', 'PAINT', 'FLOORING'],
  QA_PHOTOS: ['DEEP_CLEAN'],
  RELIST: ['QA_PHOTOS']
};
for (const code of ruleMap[targetCode] || []) {
  if (!required.includes(code)) required.push(code);
}
const missing = required
  .map(code => stageByCode.get(code))
  .filter(stage => !satisfied(stage))
  .sort((a, b) => Number(a.seq) - Number(b.seq));
if (missing.length === 0 || overrideAccepted) {
  return [{ json: {
    ...input,
    allowed: true,
    override: overrideAccepted,
    blocked_by: missing.map(stage => ({ stage_code: stage.stage_code, stage_name: stage.stage_name, status: stage.status })),
    reason: overrideAccepted ? 'Manager override accepted.' : 'Sequence guard passed.',
    completed_via: overrideAccepted ? 'override' : (input.requested_completed_via || (input.actor_type === 'vendor' ? 'vendor_reply' : 'manual'))
  } }];
}
const first = missing[0];
let reason = first.stage_name + ' is still open on ' + input.unit_label + '.';
if (targetCode === 'DEEP_CLEAN' && first.stage_code === 'REPAIRS') {
  reason = 'Repairs still open on ' + input.unit_label + '. Cleaning before repairs means cleaning twice.';
}
return [{ json: {
  ...input,
  allowed: false,
  override: false,
  blocked_by: missing.map(stage => ({ stage_code: stage.stage_code, stage_name: stage.stage_name, status: stage.status })),
  reason,
  override_token: 'OVR:' + stageId + ':' + Date.now()
} }];`;

const completeQuery = `WITH input AS (
  SELECT
    {{ Number($json.stage_id || 0) }}::int AS stage_id,
    '{{ String($json.actor_id || "board-manager").replace(/'/g, "''") }}'::text AS actor_id,
    '{{ String($json.channel || "board").replace(/'/g, "''") }}'::text AS channel,
    '{{ $json.completed_via === "override" ? "override" : "manual" }}'::text AS completed_via,
    '{{ String($json.telegram_callback_query_id || "").replace(/'/g, "''") }}'::text AS telegram_callback_query_id,
    '{{ String($json.telegram_chat_id || "").replace(/'/g, "''") }}'::text AS telegram_chat_id
), requested AS (
  SELECT ts.*, t.unit_label, t.property_address
  FROM turn_stage ts
  JOIN "turn" t ON t.id = ts.turn_id
  JOIN input i ON i.stage_id = ts.id
  FOR UPDATE OF ts
), mark_complete AS (
  UPDATE turn_stage ts
  SET status = 'complete',
      completed_at = now(),
      completed_via = input.completed_via,
      completed_by = input.actor_id
  FROM input, requested
  WHERE ts.id = requested.id
    AND ts.status IN ('active', 'pending', 'blocked')
  RETURNING ts.id, ts.turn_id, ts.seq, ts.stage_code, ts.stage_name, ts.completed_at, ts.completed_via, ts.completed_by
), activate_next AS (
  UPDATE turn_stage next_stage
  SET status = 'active',
      activated_at = COALESCE(next_stage.activated_at, now())
  FROM mark_complete mc
  WHERE next_stage.turn_id = mc.turn_id
    AND next_stage.status = 'pending'
    AND (SELECT status FROM requested LIMIT 1) = 'active'
    AND next_stage.seq = (
      SELECT min(candidate.seq)
      FROM turn_stage candidate
      WHERE candidate.turn_id = mc.turn_id
        AND candidate.status = 'pending'
        AND candidate.seq > mc.seq
    )
  RETURNING next_stage.id, next_stage.seq, next_stage.stage_code, next_stage.stage_name
), write_event AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT
    mc.turn_id,
    mc.id,
    'manager',
    input.actor_id,
    input.channel,
    CASE WHEN input.completed_via = 'override' THEN 'override' ELSE 'manual_advance' END,
    'manager marked ' || mc.stage_code || ' done',
    jsonb_build_object('completed_via', input.completed_via, 'source', input.channel, 'next_stage_id', (SELECT id FROM activate_next LIMIT 1))
  FROM mark_complete mc
  CROSS JOIN input
  RETURNING id
)
SELECT
  requested.turn_id,
  requested.unit_label,
  requested.property_address,
  requested.id AS stage_id,
  requested.stage_code,
  requested.stage_name,
  requested.status AS previous_status,
  COALESCE(mark_complete.completed_via, requested.completed_via) AS completed_via,
  mark_complete.completed_at,
  mark_complete.completed_by,
  (mark_complete.id IS NOT NULL) AS updated,
  (SELECT row_to_json(activate_next) FROM activate_next LIMIT 1) AS next_stage,
  NULLIF(input.telegram_callback_query_id, '') AS telegram_callback_query_id,
  NULLIF(input.telegram_chat_id, '') AS telegram_chat_id
FROM requested
LEFT JOIN mark_complete ON mark_complete.id = requested.id
CROSS JOIN input;`;

const successCode = `const nextStage = typeof $json.next_stage === 'string' && $json.next_stage ? JSON.parse($json.next_stage) : $json.next_stage;
const updated = Boolean($json.updated);
const response = {
  allowed: true,
  updated,
  message: updated
    ? $json.unit_label + ' - ' + $json.stage_name + ' marked done.'
    : $json.unit_label + ' - ' + $json.stage_name + ' was already handled.',
  turn_id: Number($json.turn_id),
  stage_id: Number($json.stage_id),
  stage_code: $json.stage_code,
  stage_name: $json.stage_name,
  completed_via: $json.completed_via,
  completed_at: $json.completed_at,
  completed_by: $json.completed_by,
  next_stage: nextStage || null,
  manager_response_text: updated
    ? 'Done recorded: ' + $json.unit_label + ' - ' + $json.stage_name + (nextStage ? '. Next: ' + nextStage.stage_name + '.' : '.')
    : 'No change: ' + $json.unit_label + ' - ' + $json.stage_name + ' was already handled.',
  cors_origin: 'http://localhost:8080',
  telegram_callback_query_id: $json.telegram_callback_query_id || null,
  telegram_chat_id: $json.telegram_chat_id || null
};
return [{ json: response }];`;

const blockLogQuery = `WITH input AS (
  SELECT
    {{ Number($json.stage_id || 0) }}::int AS stage_id,
    {{ Number($json.turn_id || 0) }}::int AS turn_id,
    '{{ String($json.stage_code || "").replace(/'/g, "''") }}'::text AS stage_code,
    '{{ String($json.stage_name || "").replace(/'/g, "''") }}'::text AS stage_name,
    '{{ String($json.actor_id || "board-manager").replace(/'/g, "''") }}'::text AS actor_id,
    '{{ String($json.channel || "board").replace(/'/g, "''") }}'::text AS channel,
    '{{ String($json.reason || "Sequence guard blocked the completion.").replace(/'/g, "''") }}'::text AS reason,
    '{{ JSON.stringify($json.blocked_by || []).replace(/'/g, "''") }}'::jsonb AS blocked_by,
    '{{ String($json.override_token || "").replace(/'/g, "''") }}'::text AS override_token,
    '{{ String($json.telegram_callback_query_id || "").replace(/'/g, "''") }}'::text AS telegram_callback_query_id,
    '{{ String($json.telegram_chat_id || "").replace(/'/g, "''") }}'::text AS telegram_chat_id
), inserted AS (
INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
SELECT
  NULLIF(turn_id, 0),
  NULLIF(stage_id, 0),
  'manager',
  actor_id,
  channel,
  'guard_blocked',
  reason,
  jsonb_build_object('blocked_by', blocked_by, 'override_token', override_token)
FROM input
RETURNING id
)
SELECT
  input.stage_id,
  input.turn_id,
  input.stage_code,
  input.stage_name,
  input.reason,
  input.blocked_by,
  input.override_token,
  NULLIF(input.telegram_callback_query_id, '') AS telegram_callback_query_id,
  NULLIF(input.telegram_chat_id, '') AS telegram_chat_id,
  inserted.id AS event_id
FROM input
CROSS JOIN inserted;`;

const blockResponseCode = `return [{ json: {
  allowed: false,
  updated: false,
  message: $json.reason || 'Sequence guard blocked the completion.',
  reason: $json.reason || 'Sequence guard blocked the completion.',
  turn_id: $json.turn_id ? Number($json.turn_id) : null,
  stage_id: Number($json.stage_id || $json.requested_stage_id || 0),
  stage_code: $json.stage_code || null,
  stage_name: $json.stage_name || null,
  blocked_by: $json.blocked_by || [],
  override_token: $json.override_token || null,
  manager_response_text: $json.reason || 'Sequence guard blocked the completion.',
  cors_origin: 'http://localhost:8080',
  telegram_callback_query_id: $json.telegram_callback_query_id || null,
  telegram_chat_id: $json.telegram_chat_id || null
} }];`;

const normalizeCompleteCode = `const headers = $json.headers || {};
const query = $json.query || {};
const body = $json.body || {};
const configuredToken = 'local-stage-3-demo-token';
const suppliedToken = query.token || headers['x-demo-token'] || headers['X-Demo-Token'] || body.token || '';
return [{ json: {
  authorized: Boolean(configuredToken) && String(suppliedToken) === String(configuredToken),
  stage_id: Number(body.stage_id || query.stage_id || 0),
  actor_id: String(body.actor_id || query.actor_id || 'board-manager'),
  channel: String(body.channel || query.channel || 'board'),
  override_token: body.override_token || query.override_token || '',
  override_reason: body.override_reason || query.override_reason || '',
  cors_origin: 'http://localhost:8080'
} }];`;

const digestCode = `const rows = items.map(item => item.json);
const now = new Date();
function parseStages(value) {
  if (Array.isArray(value)) return value;
  if (!value) return [];
  try { return JSON.parse(value); } catch { return []; }
}
function hoursSince(value) {
  if (!value) return 0;
  return Math.max(0, (now.getTime() - new Date(value).getTime()) / 36e5);
}
function healthFor(hours, slaHours) {
  const sla = Number(slaHours || 0);
  if (sla <= 0) return 'green';
  if (hours / sla >= 1) return 'red';
  if (hours / sla >= 0.5) return 'amber';
  return 'green';
}
const rank = { red: 3, amber: 2, green: 1 };
const turns = rows.map(row => {
  const hours = hoursSince(row.current_activated_at);
  const moveout = new Date(String(row.moveout_date).slice(0, 10) + 'T00:00:00Z');
  const today = new Date(now.toISOString().slice(0, 10) + 'T00:00:00Z');
  return {
    stage_id: Number(row.current_stage_id),
    unit_label: row.unit_label,
    property_address: row.property_address,
    current_stage_name: row.current_stage_name,
    current_vendor_name: row.current_vendor_name || 'Unassigned',
    hours_at_stage: Math.round(hours * 10) / 10,
    health: healthFor(hours, row.current_sla_hours),
    dollars_burned: Math.round((Number(row.rent_monthly || 0) / 30) * Math.max(0, Math.floor((today - moveout) / 864e5))),
    stages: parseStages(row.stages)
  };
}).sort((a, b) => (rank[b.health] - rank[a.health]) || (b.hours_at_stage - a.hours_at_stage));
const activeCount = turns.length;
const dollars = turns.reduce((sum, turn) => sum + turn.dollars_burned, 0);
const vendorReply = rows[0] ? Number(rows[0].vendor_reply_rate || 0) : 0;
const autoHandled = rows[0] ? Number(rows[0].auto_handled_rate || 0) : 0;
const lines = turns.map((turn, index) => {
  const age = turn.hours_at_stage >= 24 ? (Math.round((turn.hours_at_stage / 24) * 10) / 10) + 'd' : turn.hours_at_stage + 'h';
  return (index + 1) + '. ' + turn.unit_label + ' - ' + turn.current_stage_name + ' - ' + age + ' - $' + turn.dollars_burned + ' burned';
});
const buttons = turns.slice(0, 6).map(turn => ({ text: 'Done ' + turn.unit_label + ' ' + turn.current_stage_name, callback_data: 'DONE:' + turn.stage_id }));
while (buttons.length < 6) buttons.push({ text: 'No unit', callback_data: 'NOOP' });
return [{ json: {
  chat_id: 'stage3-manager-chat-id-missing',
  digest_text: 'Daily make-ready digest\\n' + activeCount + ' units in turn - $' + dollars + ' burning right now\\nVendor reply rate ' + vendorReply + '% - Auto-handled ' + autoHandled + '% (30 days)\\n\\n' + lines.join('\\n'),
  buttons
} }];`;

const managerParseCode = `const callback = $json.callback_query;
if (!callback) {
  return [{ json: { handled: false, action: 'ignored', reason: 'No callback query.' } }];
}
const data = String(callback.data || '');
const chatId = callback.message && callback.message.chat ? callback.message.chat.id : '';
const fromId = callback.from ? callback.from.id : 'manager-telegram';
if (!data.startsWith('DONE:')) {
  return [{ json: {
    handled: false,
    action: 'noop',
    telegram_callback_query_id: callback.id,
    telegram_chat_id: chatId,
    reason: 'No action taken.'
  } }];
}
return [{ json: {
  handled: true,
  action: 'done',
  stage_id: Number(data.slice(5)),
  actor_id: String(fromId),
  channel: 'digest',
  telegram_callback_query_id: callback.id,
  telegram_chat_id: chatId
} }];`;

const workflowFiles = [];

workflowFiles.push([
  "wf-3-sequence-guard.json",
  wf(
    "wf3-sequence-guard",
    "WF-3 Sequence Guard",
    [
      {
        id: "trigger",
        name: "Receive Guard Request",
        type: "n8n-nodes-base.executeWorkflowTrigger",
        typeVersion: 1.2,
        position: [0, 0],
        parameters: { inputSource: "passthrough" },
      },
      pgNode("load-stage-state", "Load Stage State For Guard", 240, 0, guardQuery),
      codeNode("evaluate-sequence-guard", "Evaluate Sequence Guard", 480, 0, guardCode),
    ],
    {
      "Receive Guard Request": {
        main: [[{ node: "Load Stage State For Guard", type: "main", index: 0 }]],
      },
      "Load Stage State For Guard": {
        main: [[{ node: "Evaluate Sequence Guard", type: "main", index: 0 }]],
      },
    },
    false,
  ),
]);

workflowFiles.push([
  "wf-3-stage-complete-core.json",
  wf(
    "wf3-stage-complete-core",
    "WF-3 Stage Complete Core",
    [
      {
        id: "trigger",
        name: "Receive Completion Request",
        type: "n8n-nodes-base.executeWorkflowTrigger",
        typeVersion: 1.2,
        position: [0, 0],
        parameters: { inputSource: "passthrough" },
      },
      executeNode("call-sequence-guard", "Call Sequence Guard", 240, 0, "wf3-sequence-guard"),
      ifNode("guard-passed", "Guard Passed?", 480, 0, "={{ $json.allowed }}"),
      pgNode("complete-stage", "Complete Stage And Activate Next", 720, -120, completeQuery),
      codeNode("format-completion-success", "Format Completion Success", 960, -120, successCode),
      pgNode("log-guard-block", "Log Guard Block", 720, 120, blockLogQuery),
      codeNode("format-guard-block", "Format Guard Block", 960, 120, blockResponseCode),
    ],
    {
      "Receive Completion Request": {
        main: [[{ node: "Call Sequence Guard", type: "main", index: 0 }]],
      },
      "Call Sequence Guard": {
        main: [[{ node: "Guard Passed?", type: "main", index: 0 }]],
      },
      "Guard Passed?": {
        main: [
          [{ node: "Complete Stage And Activate Next", type: "main", index: 0 }],
          [{ node: "Log Guard Block", type: "main", index: 0 }],
        ],
      },
      "Complete Stage And Activate Next": {
        main: [[{ node: "Format Completion Success", type: "main", index: 0 }]],
      },
      "Log Guard Block": {
        main: [[{ node: "Format Guard Block", type: "main", index: 0 }]],
      },
    },
    false,
  ),
]);

workflowFiles.push([
  "wf-3-board-api.json",
  wf(
    "wf3-board-api",
    "WF-3 Board API",
    [
      {
        id: "webhook-board",
        name: "GET Board Webhook",
        type: "n8n-nodes-base.webhook",
        typeVersion: 2.1,
        position: [0, 0],
        webhookId: "wf3-board-api",
        parameters: {
          httpMethod: "GET",
          path: "board",
          authentication: "none",
          responseMode: "responseNode",
          options: { allowedOrigins: "http://localhost:8080" },
        },
      },
      codeNode("normalize-board-auth", "Normalize Board Auth", 240, 0, normalizeBoardAuthCode),
      ifNode("board-authorized", "Board Authorized?", 480, 0, "={{ $json.authorized }}"),
      pgNode("load-board-state", "Load Board State", 720, -120, boardQuery),
      codeNode("shape-board-response", "Shape Board Response", 960, -120, shapeBoardCode),
      respondNode("respond-board-ok", "Respond Board 200", 1200, -120, 200),
      codeNode("format-board-unauthorized", "Format Board Unauthorized", 720, 120, unauthorizedCode),
      respondNode("respond-board-unauthorized", "Respond Board 401", 960, 120, 401),
    ],
    {
      "GET Board Webhook": {
        main: [[{ node: "Normalize Board Auth", type: "main", index: 0 }]],
      },
      "Normalize Board Auth": {
        main: [[{ node: "Board Authorized?", type: "main", index: 0 }]],
      },
      "Board Authorized?": {
        main: [
          [{ node: "Load Board State", type: "main", index: 0 }],
          [{ node: "Format Board Unauthorized", type: "main", index: 0 }],
        ],
      },
      "Load Board State": {
        main: [[{ node: "Shape Board Response", type: "main", index: 0 }]],
      },
      "Shape Board Response": {
        main: [[{ node: "Respond Board 200", type: "main", index: 0 }]],
      },
      "Format Board Unauthorized": {
        main: [[{ node: "Respond Board 401", type: "main", index: 0 }]],
      },
    },
    true,
  ),
]);

workflowFiles.push([
  "wf-3-stage-complete-api.json",
  wf(
    "wf3-stage-complete-api",
    "WF-3 Stage Complete API",
    [
      {
        id: "webhook-stage-complete",
        name: "POST Stage Complete Webhook",
        type: "n8n-nodes-base.webhook",
        typeVersion: 2.1,
        position: [0, 0],
        webhookId: "wf3-stage-complete-api",
        parameters: {
          httpMethod: "POST",
          path: "stage/complete",
          authentication: "none",
          responseMode: "responseNode",
          options: { allowedOrigins: "http://localhost:8080" },
        },
      },
      codeNode(
        "normalize-completion-request",
        "Normalize Completion Request",
        240,
        0,
        normalizeCompleteCode,
      ),
      ifNode("completion-authorized", "Completion Authorized?", 480, 0, "={{ $json.authorized }}"),
      executeNode("call-completion-core", "Call Completion Core", 720, -120, "wf3-stage-complete-core"),
      ifNode("completion-allowed", "Completion Allowed?", 960, -120, "={{ $json.allowed }}"),
      respondNode("respond-completion-ok", "Respond Completion 200", 1200, -220, 200),
      respondNode("respond-completion-blocked", "Respond Completion 409", 1200, -20, 409),
      codeNode(
        "format-completion-unauthorized",
        "Format Completion Unauthorized",
        720,
        120,
        unauthorizedCode,
      ),
      respondNode("respond-completion-unauthorized", "Respond Completion 401", 960, 120, 401),
    ],
    {
      "POST Stage Complete Webhook": {
        main: [[{ node: "Normalize Completion Request", type: "main", index: 0 }]],
      },
      "Normalize Completion Request": {
        main: [[{ node: "Completion Authorized?", type: "main", index: 0 }]],
      },
      "Completion Authorized?": {
        main: [
          [{ node: "Call Completion Core", type: "main", index: 0 }],
          [{ node: "Format Completion Unauthorized", type: "main", index: 0 }],
        ],
      },
      "Call Completion Core": {
        main: [[{ node: "Completion Allowed?", type: "main", index: 0 }]],
      },
      "Completion Allowed?": {
        main: [
          [{ node: "Respond Completion 200", type: "main", index: 0 }],
          [{ node: "Respond Completion 409", type: "main", index: 0 }],
        ],
      },
      "Format Completion Unauthorized": {
        main: [[{ node: "Respond Completion 401", type: "main", index: 0 }]],
      },
    },
    true,
  ),
]);

workflowFiles.push([
  "wf-3-daily-digest.json",
  wf(
    "wf3-daily-digest",
    "WF-3 Daily Digest",
    [
      {
        id: "manual-trigger",
        name: "Manual Digest Trigger",
        type: "n8n-nodes-base.manualTrigger",
        typeVersion: 1,
        position: [0, -120],
        parameters: {},
      },
      {
        id: "schedule-trigger",
        name: "Daily 7AM Digest Trigger",
        type: "n8n-nodes-base.scheduleTrigger",
        typeVersion: 1.3,
        position: [0, 120],
        parameters: {
          rule: {
            interval: [
              { field: "days", daysInterval: 1, triggerAtHour: 7, triggerAtMinute: 0 },
            ],
          },
        },
      },
      pgNode("load-digest-board-state", "Load Digest Board State", 280, 0, boardQuery),
      codeNode("format-digest-message", "Format Digest Message", 520, 0, digestCode),
      {
        id: "send-digest",
        name: "Send Manager Digest",
        type: "n8n-nodes-base.telegram",
        typeVersion: 1.2,
        position: [760, 0],
        parameters: {
          resource: "message",
          operation: "sendMessage",
          chatId: "={{ $json.chat_id }}",
          text: "={{ $json.digest_text }}",
          replyMarkup: "inlineKeyboard",
          inlineKeyboard: {
            rows: [
              {
                row: {
                  buttons: [
                    {
                      text: "={{ $json.buttons[0].text }}",
                      additionalFields: {
                        callback_data: "={{ $json.buttons[0].callback_data }}",
                      },
                    },
                  ],
                },
              },
              {
                row: {
                  buttons: [
                    {
                      text: "={{ $json.buttons[1].text }}",
                      additionalFields: {
                        callback_data: "={{ $json.buttons[1].callback_data }}",
                      },
                    },
                  ],
                },
              },
              {
                row: {
                  buttons: [
                    {
                      text: "={{ $json.buttons[2].text }}",
                      additionalFields: {
                        callback_data: "={{ $json.buttons[2].callback_data }}",
                      },
                    },
                  ],
                },
              },
              {
                row: {
                  buttons: [
                    {
                      text: "={{ $json.buttons[3].text }}",
                      additionalFields: {
                        callback_data: "={{ $json.buttons[3].callback_data }}",
                      },
                    },
                  ],
                },
              },
              {
                row: {
                  buttons: [
                    {
                      text: "={{ $json.buttons[4].text }}",
                      additionalFields: {
                        callback_data: "={{ $json.buttons[4].callback_data }}",
                      },
                    },
                  ],
                },
              },
              {
                row: {
                  buttons: [
                    {
                      text: "={{ $json.buttons[5].text }}",
                      additionalFields: {
                        callback_data: "={{ $json.buttons[5].callback_data }}",
                      },
                    },
                  ],
                },
              },
            ],
          },
          additionalFields: { disable_web_page_preview: true, appendAttribution: false },
        },
        credentials: { telegramApi: tgCred },
      },
    ],
    {
      "Manual Digest Trigger": {
        main: [[{ node: "Load Digest Board State", type: "main", index: 0 }]],
      },
      "Daily 7AM Digest Trigger": {
        main: [[{ node: "Load Digest Board State", type: "main", index: 0 }]],
      },
      "Load Digest Board State": {
        main: [[{ node: "Format Digest Message", type: "main", index: 0 }]],
      },
      "Format Digest Message": {
        main: [[{ node: "Send Manager Digest", type: "main", index: 0 }]],
      },
    },
    false,
  ),
]);

workflowFiles.push([
  "wf-3-manager-router.json",
  wf(
    "wf3-manager-router",
    "WF-3 Manager Router",
    [
      {
        id: "manager-trigger",
        name: "ManagerTelegramTrigger",
        type: "n8n-nodes-base.telegramTrigger",
        typeVersion: 1.3,
        position: [0, 0],
        parameters: { updates: ["callback_query"], additionalFields: {} },
        credentials: { telegramApi: tgCred },
      },
      codeNode("parse-manager-callback", "Parse Manager Callback", 240, 0, managerParseCode),
      ifNode("callback-is-done", "Callback Is Done?", 480, 0, "={{ $json.handled }}"),
      executeNode(
        "call-core-from-digest",
        "Call Completion Core From Digest",
        720,
        -120,
        "wf3-stage-complete-core",
      ),
      {
        id: "answer-callback",
        name: "Answer Manager Callback",
        type: "n8n-nodes-base.telegram",
        typeVersion: 1.2,
        position: [960, -120],
        parameters: {
          resource: "callback",
          operation: "answerQuery",
          queryId: "={{ $json.telegram_callback_query_id }}",
          additionalFields: {
            text:
              '={{ $json.manager_response_text || $json.reason || $json.message || "Done" }}',
            show_alert: false,
          },
        },
        credentials: { telegramApi: tgCred },
      },
      {
        id: "answer-noop",
        name: "Answer Ignored Callback",
        type: "n8n-nodes-base.telegram",
        typeVersion: 1.2,
        position: [720, 120],
        parameters: {
          resource: "callback",
          operation: "answerQuery",
          queryId: "={{ $json.telegram_callback_query_id }}",
          additionalFields: { text: "No action taken.", show_alert: false },
        },
        credentials: { telegramApi: tgCred },
      },
    ],
    {
      ManagerTelegramTrigger: {
        main: [[{ node: "Parse Manager Callback", type: "main", index: 0 }]],
      },
      "Parse Manager Callback": {
        main: [[{ node: "Callback Is Done?", type: "main", index: 0 }]],
      },
      "Callback Is Done?": {
        main: [
          [{ node: "Call Completion Core From Digest", type: "main", index: 0 }],
          [{ node: "Answer Ignored Callback", type: "main", index: 0 }],
        ],
      },
      "Call Completion Core From Digest": {
        main: [[{ node: "Answer Manager Callback", type: "main", index: 0 }]],
      },
    },
    false,
  ),
]);

for (const [file, data] of workflowFiles) {
  fs.writeFileSync(path.join(outDir, file), JSON.stringify(data, null, 2) + "\n", "utf8");
}
