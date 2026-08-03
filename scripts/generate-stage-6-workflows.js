const fs = require("fs");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const outDir = path.join(repoRoot, "n8n-workflows");

const pgCred = { id: "cred_make_ready_pg", name: "Make-Ready Postgres" };
const managerTgCred = { id: "jASZWMlrfp3v2tWH", name: "Make-Ready Manager Telegram Bot" };

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

function load(file) {
  return JSON.parse(fs.readFileSync(path.join(outDir, file), "utf8"));
}

function save(file, data) {
  fs.writeFileSync(path.join(outDir, file), JSON.stringify(data, null, 2) + "\n", "utf8");
}

function node(workflow, name) {
  const found = workflow.nodes.find((n) => n.name === name);
  if (!found) throw new Error(`Node not found: ${workflow.name} / ${name}`);
  return found;
}

function codeNode(id, name, x, y, jsCode) {
  return { id, name, type: "n8n-nodes-base.code", typeVersion: 2, position: [x, y], parameters: { jsCode } };
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
        options: { caseSensitive: true, leftValue: "", typeValidation: "strict", version: 2 },
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

function executeNode(id, name, x, y, workflowId) {
  return {
    id,
    name,
    type: "n8n-nodes-base.executeWorkflow",
    typeVersion: 1,
    position: [x, y],
    parameters: { source: "database", workflowId, options: { waitForSubWorkflow: true } },
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
            { name: "Access-Control-Allow-Origin", value: '={{ $json.cors_origin || "http://localhost:8080" }}' },
          ],
        },
      },
    },
  };
}

function telegramSendNode(id, name, x, y, textExpression) {
  return {
    id,
    name,
    type: "n8n-nodes-base.telegram",
    typeVersion: 1.2,
    position: [x, y],
    parameters: {
      resource: "message",
      operation: "sendMessage",
      chatId: "={{ $json.manager_chat_id }}",
      text: textExpression,
      additionalFields: { disable_web_page_preview: true, appendAttribution: false },
    },
    credentials: { telegramApi: managerTgCred },
  };
}

function telegramApprovalNode(id, name, x, y) {
  return {
    id,
    name,
    type: "n8n-nodes-base.telegram",
    typeVersion: 1.2,
    position: [x, y],
    parameters: {
      resource: "message",
      operation: "sendMessage",
      chatId: "={{ $json.manager_chat_id }}",
      text: "={{ $json.manager_approval_text }}",
      replyMarkup: "inlineKeyboard",
      inlineKeyboard: {
        rows: [
          { row: { buttons: [{ text: "Send", additionalFields: { callback_data: "={{ 'SEND:' + $json.queue_id }}" } }] } },
          { row: { buttons: [{ text: "Edit", additionalFields: { callback_data: "={{ 'EDIT:' + $json.queue_id }}" } }] } },
          { row: { buttons: [{ text: "Hold", additionalFields: { callback_data: "={{ 'HOLD:' + $json.queue_id }}" } }] } },
        ],
      },
      additionalFields: { disable_web_page_preview: true, appendAttribution: false },
    },
    credentials: { telegramApi: managerTgCred },
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
    turn_id, event_type, actor_type, channel, raw_text, parsed_json, created_at
  FROM event_log
  WHERE turn_id IS NOT NULL
  ORDER BY turn_id, created_at DESC, id DESC
), recent_events AS (
  SELECT
    e.turn_id,
    jsonb_agg(jsonb_build_object(
      'event_type', e.event_type,
      'actor_type', e.actor_type,
      'channel', e.channel,
      'text', e.raw_text,
      'created_at', e.created_at,
      'details', e.parsed_json
    ) ORDER BY e.created_at DESC, e.id DESC) AS events
  FROM (
    SELECT e.*, row_number() OVER (PARTITION BY e.turn_id ORDER BY e.created_at DESC, e.id DESC) AS rn
    FROM event_log e
    WHERE e.turn_id IS NOT NULL
  ) e
  WHERE e.rn <= 5
  GROUP BY e.turn_id
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
  ast.alerted_at AS current_alerted_at,
  ast.snooze_until AS current_snooze_until,
  v.name AS current_vendor_name,
  v.trade AS current_vendor_trade,
  le.event_type AS latest_event_type,
  le.actor_type AS latest_event_actor_type,
  le.channel AS latest_event_channel,
  le.raw_text AS latest_event_text,
  le.parsed_json AS latest_event_details,
  le.created_at AS latest_event_at,
  COALESCE(re.events, '[]'::jsonb) AS recent_events,
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
LEFT JOIN recent_events re ON re.turn_id = t.id
CROSS JOIN metrics
WHERE t.status = 'active'
GROUP BY
  t.id, ast.id, ast.seq, ast.stage_code, ast.stage_name, ast.status, ast.sla_hours, ast.activated_at, ast.alerted_at, ast.snooze_until,
  v.id, v.name, v.trade, le.turn_id, le.event_type, le.actor_type, le.channel, le.raw_text, le.parsed_json, le.created_at, re.events,
  metrics.vendor_reply_rate, metrics.auto_handled_rate
ORDER BY t.unit_label;`;

const shapeBoardCode = `const rows = items.map(item => item.json);
const generatedAt = new Date();
const healthRank = { red: 3, amber: 2, green: 1 };
function parseJson(value, fallback) {
  if (Array.isArray(value) || (value && typeof value === 'object')) return value;
  if (!value) return fallback;
  try { return JSON.parse(value); } catch { return fallback; }
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
function healthFor(hours, slaHours, status) {
  if (status === 'awaiting_approval') return 'amber';
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
    details: parseJson(row.latest_event_details, null),
    created_at: row.latest_event_at
  };
}
const turns = rows.map(row => {
  const stages = parseJson(row.stages, []).map(stage => ({
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
  const currentPhoto = stages.find(stage => stage.evidence_photo)?.evidence_photo || null;
  const hours = hoursSince(row.current_activated_at);
  const vacancyDays = wholeVacancyDays(row.moveout_date);
  const dollars = Math.round((Number(row.rent_monthly || 0) / 30) * vacancyDays);
  const health = healthFor(hours, row.current_sla_hours, row.current_stage_status);
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
      alerted_at: row.current_alerted_at,
      snooze_until: row.current_snooze_until,
      assigned_vendor: row.current_vendor_name || 'Unassigned'
    },
    stages,
    latest_event: latestEvent(row),
    recent_events: parseJson(row.recent_events, []),
    evidence_photo: currentPhoto,
    hours_at_stage: Math.round(hours * 10) / 10,
    days_at_stage: Math.round((hours / 24) * 10) / 10,
    days_vacant: vacancyDays,
    dollars_burned: dollars,
    health,
    health_rank: healthRank[health]
  };
}).sort((a, b) => (b.health_rank - a.health_rank) || (b.hours_at_stage - a.hours_at_stage) || a.unit_label.localeCompare(b.unit_label));
return [{ json: {
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
} }];`;

const normalizeVendorApiCode = `const headers = $json.headers || {};
const query = $json.query || {};
const body = $json.body || {};
const configuredToken = 'local-stage-4-vendor-in-token';
const suppliedToken = query.token || headers['x-vendor-in-token'] || headers['X-Vendor-In-Token'] || headers['x-demo-token'] || headers['X-Demo-Token'] || body.token || '';
const text = String(body.text || query.text || '').trim();
const senderRef = String(body.sender_ref || query.sender_ref || '').trim();
const mediaType = String(body.media_type || query.media_type || '').trim();
const mediaFileId = String(body.media_file_id || query.media_file_id || '').trim();
const mediaUrl = String(body.media_url || query.media_url || '').trim();
let receivedAt = String(body.received_at || query.received_at || new Date().toISOString()).trim();
if (Number.isNaN(new Date(receivedAt).getTime())) receivedAt = new Date().toISOString();
const media = mediaType ? { type: mediaType, file_id: mediaFileId || null, local_path: mediaUrl || null } : null;
return [{ json: {
  authorized: Boolean(configuredToken) && String(suppliedToken) === String(configuredToken),
  valid: Boolean(senderRef && (text || media)),
  error: senderRef ? 'text or media is required.' : 'sender_ref is required.',
  envelope: { channel: 'generic', sender_ref: senderRef, text, media, received_at: receivedAt },
  cors_origin: 'http://localhost:8080'
} }];`;

const normalizeTelegramCode = `const message = $json.message || $json.edited_message || {};
const from = message.from || {};
const chat = message.chat || {};
const photos = Array.isArray(message.photo) ? message.photo : [];
const photo = photos.length ? photos[photos.length - 1] : null;
const voice = message.voice || null;
const document = message.document || null;
let media = null;
if (photo) media = { type: 'photo', file_id: photo.file_id || null };
else if (voice) media = { type: 'voice', file_id: voice.file_id || null, duration: voice.duration || null };
else if (document) media = { type: 'unsupported', file_id: document.file_id || null, mime_type: document.mime_type || null };
const text = String(message.text || message.caption || '').trim();
const senderRef = String(chat.id || from.id || '').trim();
return [{ json: {
  channel: 'telegram',
  sender_ref: senderRef,
  text,
  media,
  received_at: message.date ? new Date(Number(message.date) * 1000).toISOString() : new Date().toISOString()
} }];`;

const prepareKnownRouteCode = `const envelope = $json.envelope || {
  channel: $json.channel || 'generic',
  sender_ref: $json.sender_ref || '',
  text: $json.text || '',
  media: $json.media || null,
  received_at: $json.received_at || new Date().toISOString()
};
const match = $json.match || { needs_manager: true, candidates: [], selected: null, score: 0 };
const classification = $('Parse Classification Or Fallback').first().json.classification || { status: 'fallback_missing', intent: 'unclear', confidence: 0 };
const vendor = {
  known: true,
  id: $json.vendor && $json.vendor.id ? $json.vendor.id : $('Parse Classification Or Fallback').first().json.vendor_id,
  name: $json.vendor && $json.vendor.name ? $json.vendor.name : $('Parse Classification Or Fallback').first().json.vendor_name,
  trade: $json.vendor && $json.vendor.trade ? $json.vendor.trade : $('Parse Classification Or Fallback').first().json.vendor_trade
};
const media = envelope.media || null;
const mediaOnly = media && !String(envelope.text || '').trim();
let eventType = 'vendor_inbound';
let outcome = 'logged_no_action';
let shouldNotify = false;
let shouldComplete = false;
if (media && ['voice', 'unsupported'].includes(String(media.type || ''))) {
  eventType = 'unsupported_media';
  outcome = 'unsupported_media';
  shouldNotify = true;
} else if ($json.duplicate_like) {
  eventType = 'duplicate_inbound';
  outcome = 'duplicate_like';
  shouldNotify = true;
} else if (mediaOnly && String(media.type || '') === 'photo') {
  eventType = 'manager_photo_match_needed';
  outcome = 'media_needs_manager';
  shouldNotify = true;
} else if (!classification || classification.confidence < 0.6 || classification.intent === 'unclear') {
  eventType = 'manager_match_needed';
  outcome = 'low_confidence';
  shouldNotify = true;
} else if (match.needs_manager) {
  eventType = 'manager_match_needed';
  outcome = 'manager_match_needed';
  shouldNotify = true;
} else if (match.selected && vendor.id && match.selected.assigned_vendor_id && Number(match.selected.assigned_vendor_id) !== Number(vendor.id)) {
  eventType = 'manager_match_needed';
  outcome = 'stage_vendor_mismatch';
  shouldNotify = true;
} else if (classification.intent === 'stage_complete') {
  outcome = 'completion_requested';
  shouldComplete = true;
} else {
  outcome = classification.intent || 'logged_no_action';
  shouldNotify = true;
}
const candidateText = (match.candidates || []).map(candidate => candidate.unit_label + ' ' + candidate.stage_name + ' (' + candidate.score + ')').join(', ');
let notice = 'Vendor message needs manager review: ' + (vendor.name || 'Known vendor') + ': "' + envelope.text + '"' + (candidateText ? ' Candidates: ' + candidateText : '');
if (outcome === 'duplicate_like') notice = 'Duplicate-like vendor message from ' + (vendor.name || 'Known vendor') + ': "' + envelope.text + '"';
if (outcome === 'media_needs_manager') notice = 'Photo from ' + (vendor.name || 'Known vendor') + ' needs manager review. Choose the unit and stage before updating anything.';
if (outcome === 'unsupported_media') notice = (String(media && media.type || 'media') === 'voice' ? 'Voice message' : 'Unsupported media') + ' from ' + (vendor.name || 'Known vendor') + '. Review it in Telegram; no stage was changed.';
return [{ json: {
  accepted: true,
  outcome,
  event_type: eventType,
  envelope,
  vendor,
  match,
  classification,
  duplicate_like: Boolean($json.duplicate_like),
  needs_manager: Boolean(shouldNotify),
  should_notify_manager: Boolean(shouldNotify),
  should_complete: Boolean(shouldComplete),
  manager_chat_id: 'stage5-manager-chat-id-missing',
  manager_notice_text: notice,
  cors_origin: 'http://localhost:8080'
} }];`;

const logRouterEventQuery = `WITH input AS (
  SELECT
    '{{ String($json.event_type || "vendor_inbound").replace(/'/g, "''") }}'::text AS event_type,
    '{{ String($json.outcome || "logged_no_action").replace(/'/g, "''") }}'::text AS outcome,
    '{{ JSON.stringify($json.envelope || {}).replace(/'/g, "''") }}'::jsonb AS envelope,
    '{{ JSON.stringify($json.vendor || {}).replace(/'/g, "''") }}'::jsonb AS vendor,
    '{{ JSON.stringify($json.match || null).replace(/'/g, "''") }}'::jsonb AS match,
    '{{ JSON.stringify($json.classification || null).replace(/'/g, "''") }}'::jsonb AS classification,
    {{ $json.duplicate_like ? 'true' : 'false' }}::boolean AS duplicate_like,
    {{ $json.needs_manager ? 'true' : 'false' }}::boolean AS needs_manager,
    {{ $json.should_notify_manager ? 'true' : 'false' }}::boolean AS should_notify_manager,
    '{{ String($json.manager_chat_id || "").replace(/'/g, "''") }}'::text AS manager_chat_id,
    '{{ String($json.manager_notice_text || "").replace(/'/g, "''") }}'::text AS manager_notice_text,
    '{{ String(($json.envelope || {}).channel || "generic").replace(/'/g, "''") }}'::text AS channel,
    '{{ String(($json.envelope || {}).sender_ref || "").replace(/'/g, "''") }}'::text AS sender_ref,
    '{{ String(($json.envelope || {}).text || "").replace(/'/g, "''") }}'::text AS raw_text,
    '{{ JSON.stringify(($json.envelope || {}).media || null).replace(/'/g, "''") }}'::jsonb AS media,
    {{ Number($json.vendor && $json.vendor.id ? $json.vendor.id : 0) }}::int AS vendor_id,
    {{ Number($json.match && $json.match.selected ? $json.match.selected.turn_id : 0) }}::int AS turn_id,
    {{ Number($json.match && $json.match.selected ? $json.match.selected.stage_id : 0) }}::int AS stage_id
), inserted AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT
    NULLIF(turn_id, 0),
    NULLIF(stage_id, 0),
    'vendor',
    sender_ref,
    channel,
    event_type,
    raw_text,
    jsonb_build_object('envelope', envelope, 'vendor', vendor, 'match', match, 'classification', classification, 'duplicate_like', duplicate_like, 'needs_manager', needs_manager, 'stage_state_mutated', false)
  FROM input
  RETURNING id
), media_insert AS (
  INSERT INTO media_asset (turn_id, stage_id, vendor_id, channel, sender_ref, media_type, file_id, local_path, caption, status)
  SELECT
    NULLIF(turn_id, 0),
    NULLIF(stage_id, 0),
    NULLIF(vendor_id, 0),
    channel,
    sender_ref,
    CASE WHEN media->>'type' IN ('photo', 'voice') THEN media->>'type' ELSE 'unsupported' END,
    media->>'file_id',
    media->>'local_path',
    raw_text,
    CASE
      WHEN event_type = 'manager_photo_match_needed' THEN 'needs_manager'
      WHEN event_type = 'unsupported_media' THEN 'unsupported'
      ELSE 'received'
    END
  FROM input
  WHERE media IS NOT NULL
  RETURNING id
)
SELECT
  true AS accepted,
  inserted.id AS event_id,
  (SELECT id FROM media_insert LIMIT 1) AS media_asset_id,
  input.outcome,
  input.event_type,
  input.envelope,
  input.vendor,
  input.match,
  input.classification,
  input.duplicate_like,
  input.needs_manager,
  (input.should_notify_manager AND input.manager_chat_id <> '' AND input.manager_chat_id <> 'stage5-manager-chat-id-missing') AS should_notify_manager,
  NULLIF(input.manager_chat_id, 'stage5-manager-chat-id-missing') AS manager_chat_id,
  input.manager_notice_text,
  false AS stage_state_mutated,
  'http://localhost:8080'::text AS cors_origin
FROM input
CROSS JOIN inserted;`;

const completionQuery = `WITH input AS (
  SELECT
    {{ Number($json.match && $json.match.selected ? $json.match.selected.stage_id : $json.stage_id || 0) }}::int AS stage_id,
    '{{ String(($json.envelope || {}).sender_ref || $json.actor_id || "vendor").replace(/'/g, "''") }}'::text AS actor_id,
    '{{ String(($json.envelope || {}).channel || $json.channel || "generic").replace(/'/g, "''") }}'::text AS channel,
    '{{ String(($json.envelope || {}).text || $json.raw_text || "").replace(/'/g, "''") }}'::text AS raw_text,
    '{{ JSON.stringify(($json.envelope || {}).media || null).replace(/'/g, "''") }}'::jsonb AS media,
    '{{ JSON.stringify($json.classification || {}).replace(/'/g, "''") }}'::jsonb AS classification,
    '{{ JSON.stringify($json.match || {}).replace(/'/g, "''") }}'::jsonb AS match,
    '{{ JSON.stringify($json.vendor || {}).replace(/'/g, "''") }}'::jsonb AS vendor_context
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
      completed_via = 'vendor_reply',
      completed_by = input.actor_id,
      evidence_photo = CASE
        WHEN input.media->>'type' = 'photo' THEN COALESCE(NULLIF(input.media->>'local_path', ''), 'data/photos/' || requested.turn_id || '-' || requested.id || '-' || COALESCE(input.media->>'file_id', 'photo') || '.jpg')
        ELSE ts.evidence_photo
      END
  FROM input, requested
  WHERE ts.id = requested.id
    AND ts.status = 'active'
  RETURNING ts.id, ts.turn_id, ts.seq, ts.stage_code, ts.stage_name, ts.completed_at, ts.evidence_photo
), stored_media AS (
  INSERT INTO media_asset (turn_id, stage_id, vendor_id, channel, sender_ref, media_type, file_id, local_path, caption, status)
  SELECT
    mc.turn_id,
    mc.id,
    requested.vendor_id,
    input.channel,
    input.actor_id,
    'photo',
    input.media->>'file_id',
    mc.evidence_photo,
    input.raw_text,
    'stored'
  FROM mark_complete mc
  CROSS JOIN input
  JOIN requested ON requested.id = mc.id
  WHERE input.media->>'type' = 'photo'
  RETURNING id
), next_candidate AS (
  SELECT ns.*, v.name AS vendor_name, v.trade AS vendor_trade, v.telegram_chat_id, v.phone_e164, r.unit_label, r.property_address
  FROM mark_complete mc
  JOIN requested r ON r.id = mc.id
  JOIN turn_stage ns ON ns.turn_id = mc.turn_id
  LEFT JOIN vendor v ON v.id = ns.vendor_id
  WHERE ns.status = 'pending'
    AND ns.seq = (
      SELECT min(candidate.seq)
      FROM turn_stage candidate
      WHERE candidate.turn_id = mc.turn_id
        AND candidate.status = 'pending'
        AND candidate.seq > mc.seq
    )
), activate_inhouse AS (
  UPDATE turn_stage ts
  SET status = 'active',
      activated_at = COALESCE(ts.activated_at, now())
  FROM next_candidate nc
  WHERE ts.id = nc.id
    AND COALESCE(nc.vendor_trade, 'inspect') = 'inspect'
  RETURNING ts.id, ts.stage_name, ts.stage_code
), await_vendor AS (
  UPDATE turn_stage ts
  SET status = 'awaiting_approval',
      activated_at = COALESCE(ts.activated_at, now())
  FROM next_candidate nc
  WHERE ts.id = nc.id
    AND COALESCE(nc.vendor_trade, 'inspect') <> 'inspect'
  RETURNING ts.id, ts.turn_id, ts.seq, ts.stage_code, ts.stage_name, ts.vendor_id
), draft_source AS (
  SELECT
    av.id AS stage_id,
    av.turn_id,
    av.vendor_id,
    nc.vendor_name,
    nc.telegram_chat_id,
    nc.phone_e164,
    nc.unit_label,
    nc.property_address,
    av.stage_name,
    ('Hi ' || COALESCE(nc.vendor_name, 'there') || ', ' || nc.unit_label || ' at ' || nc.property_address || ' is ready for ' || av.stage_name || '. Please reply when it is complete. - Cedar Ridge') AS deterministic_text
  FROM await_vendor av
  JOIN next_candidate nc ON nc.id = av.id
), inserted_queue AS (
  INSERT INTO outbound_queue (turn_id, stage_id, source_stage_id, vendor_id, channel, draft_text, approved_text, deterministic_text, status, draft_model, draft_fallback_used, approval_context)
  SELECT ds.turn_id, ds.stage_id, (SELECT id FROM mark_complete LIMIT 1), ds.vendor_id, 'telegram', left(ds.deterministic_text, 320), left(ds.deterministic_text, 320), left(ds.deterministic_text, 320), 'awaiting_approval', 'gpt-5.6-luna', true,
    jsonb_build_object('vendor_name', ds.vendor_name, 'sender_ref', COALESCE(ds.telegram_chat_id, ds.phone_e164), 'fallback', 'deterministic_template')
  FROM draft_source ds
  WHERE NOT EXISTS (
    SELECT 1 FROM outbound_queue oq
    WHERE oq.stage_id = ds.stage_id
      AND oq.vendor_id = ds.vendor_id
      AND oq.status IN ('awaiting_approval', 'editing')
  )
  RETURNING id, stage_id, vendor_id, draft_text, approved_text
), write_complete AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT mc.turn_id, mc.id, 'vendor', input.actor_id, input.channel, 'stage_complete', input.raw_text,
    jsonb_build_object('classification', input.classification, 'match', input.match, 'media_asset_id', (SELECT id FROM stored_media LIMIT 1), 'stage_state_mutated', true)
  FROM mark_complete mc
  CROSS JOIN input
  RETURNING id
), write_photo AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT mc.turn_id, mc.id, 'system', 'stage-6', 'system', 'photo_stored', mc.evidence_photo,
    jsonb_build_object('media_asset_id', (SELECT id FROM stored_media LIMIT 1), 'path', mc.evidence_photo)
  FROM mark_complete mc
  CROSS JOIN input
  WHERE input.media->>'type' = 'photo'
  RETURNING id
), write_draft AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT ds.turn_id, ds.stage_id, 'system', 'stage-5', 'system', 'msg_drafted', ds.deterministic_text,
    jsonb_build_object('queue_id', iq.id, 'source_stage_id', (SELECT id FROM mark_complete LIMIT 1), 'draft_fallback_used', true)
  FROM draft_source ds
  JOIN inserted_queue iq ON iq.stage_id = ds.stage_id
  RETURNING id
), write_await AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT av.turn_id, av.id, 'system', 'stage-5', 'system', 'stage_awaiting_approval', 'next stage awaiting manager approval',
    jsonb_build_object('queue_id', (SELECT id FROM inserted_queue LIMIT 1))
  FROM await_vendor av
  RETURNING id
)
SELECT
  true AS accepted,
  CASE
    WHEN (SELECT count(*) FROM mark_complete) = 0 THEN 'already_handled_or_not_active'
    WHEN (SELECT count(*) FROM inserted_queue) > 0 THEN 'completed_awaiting_approval'
    WHEN (SELECT count(*) FROM activate_inhouse) > 0 THEN 'completed_next_inhouse_active'
    ELSE 'completed_no_next_stage'
  END AS outcome,
  true AS stage_state_mutated,
  requested.turn_id,
  requested.unit_label,
  requested.property_address,
  requested.id AS completed_stage_id,
  requested.stage_code AS completed_stage_code,
  requested.stage_name AS completed_stage_name,
  (SELECT row_to_json(inserted_queue) FROM inserted_queue LIMIT 1) AS outbound_queue,
  (SELECT row_to_json(next_candidate) FROM next_candidate LIMIT 1) AS next_stage,
  (SELECT evidence_photo FROM mark_complete LIMIT 1) AS evidence_photo,
  'http://localhost:8080'::text AS cors_origin
FROM requested;`;

const managerActionQuery = `WITH input AS (
  SELECT
    upper('{{ String($json.action || "").replace(/'/g, "''") }}')::text AS action,
    {{ Number($json.queue_id || 0) }}::int AS queue_id,
    {{ Number($json.stage_id || 0) }}::int AS stage_id,
    {{ Number($json.turn_id || 0) }}::int AS turn_id,
    '{{ String($json.actor_id || "manager").replace(/'/g, "''") }}'::text AS actor_id,
    '{{ String($json.channel || "board").replace(/'/g, "''") }}'::text AS channel,
    '{{ String($json.edited_text || "").replace(/'/g, "''") }}'::text AS edited_text,
    '{{ String($json.telegram_chat_id || "").replace(/'/g, "''") }}'::text AS telegram_chat_id,
    '{{ String($json.telegram_callback_query_id || "").replace(/'/g, "''") }}'::text AS telegram_callback_query_id
), queue_row AS (
  SELECT oq.*, v.name AS vendor_name, v.telegram_chat_id, v.phone_e164
  FROM outbound_queue oq
  LEFT JOIN vendor v ON v.id = oq.vendor_id
  JOIN input i ON i.queue_id = oq.id
  FOR UPDATE OF oq
), mark_sent AS (
  UPDATE outbound_queue oq
  SET status = 'sent', approved_text = COALESCE(NULLIF(input.edited_text, ''), oq.approved_text, oq.draft_text), decision_by = input.actor_id, decided_at = now(), sent_at = now(), sent_to_sender_ref = COALESCE(queue_row.telegram_chat_id, queue_row.phone_e164)
  FROM input, queue_row
  WHERE input.action = 'SEND' AND oq.id = queue_row.id AND oq.status = 'awaiting_approval'
  RETURNING oq.*
), activate_sent_stage AS (
  UPDATE turn_stage ts
  SET status = 'active', activated_at = now()
  FROM mark_sent ms
  WHERE ts.id = ms.stage_id AND ts.status = 'awaiting_approval'
  RETURNING ts.id, ts.turn_id, ts.stage_code, ts.stage_name
), mark_hold AS (
  UPDATE outbound_queue oq
  SET status = 'held', decision_by = input.actor_id, decided_at = now()
  FROM input, queue_row
  WHERE input.action = 'HOLD' AND oq.id = queue_row.id AND oq.status IN ('awaiting_approval', 'editing')
  RETURNING oq.*
), mark_edit AS (
  UPDATE outbound_queue oq
  SET status = CASE WHEN input.edited_text <> '' THEN 'awaiting_approval' ELSE 'editing' END,
      draft_text = CASE WHEN input.edited_text <> '' THEN input.edited_text ELSE oq.draft_text END,
      approved_text = CASE WHEN input.edited_text <> '' THEN input.edited_text ELSE oq.approved_text END,
      edit_prompted_at = now(),
      decision_by = input.actor_id
  FROM input, queue_row
  WHERE input.action = 'EDIT' AND oq.id = queue_row.id AND oq.status IN ('awaiting_approval', 'editing')
  RETURNING oq.*
), chase_stage AS (
  SELECT ts.id AS stage_id, ts.turn_id, ts.vendor_id, ts.stage_name, t.unit_label, t.property_address, v.name AS vendor_name, v.telegram_chat_id, v.phone_e164
  FROM turn_stage ts
  JOIN "turn" t ON t.id = ts.turn_id
  JOIN vendor v ON v.id = ts.vendor_id
  JOIN input i ON i.stage_id = ts.id
  WHERE i.action = 'CHASE'
    AND ts.status = 'active'
    AND v.trade <> 'inspect'
  FOR UPDATE OF ts
), chase_source AS (
  SELECT *,
    ('Hi ' || COALESCE(vendor_name, 'there') || ', checking in on ' || unit_label || ' at ' || property_address || ' for ' || stage_name || '. Please reply with an update when you can. - Cedar Ridge') AS deterministic_text
  FROM chase_stage
), chase_queue AS (
  INSERT INTO outbound_queue (turn_id, stage_id, source_stage_id, vendor_id, channel, draft_text, approved_text, deterministic_text, status, draft_model, draft_fallback_used, approval_context)
  SELECT turn_id, stage_id, stage_id, vendor_id, 'telegram', left(deterministic_text, 320), left(deterministic_text, 320), left(deterministic_text, 320), 'awaiting_approval', NULL, true,
    jsonb_build_object('kind', 'chase', 'vendor_name', vendor_name, 'sender_ref', COALESCE(telegram_chat_id, phone_e164))
  FROM chase_source cs
  WHERE NOT EXISTS (
    SELECT 1 FROM outbound_queue oq
    WHERE oq.stage_id = cs.stage_id
      AND oq.vendor_id = cs.vendor_id
      AND oq.status IN ('awaiting_approval', 'editing')
  )
  RETURNING *
), skip_stage AS (
  UPDATE turn_stage ts
  SET status = 'skipped', completed_at = now(), completed_via = 'skip', completed_by = input.actor_id
  FROM input
  WHERE input.action = 'SKIP' AND ts.id = input.stage_id AND ts.status IN ('pending', 'active', 'awaiting_approval', 'blocked')
  RETURNING ts.id, ts.turn_id, ts.stage_code, ts.stage_name
), snooze_stage AS (
  UPDATE turn_stage ts
  SET snooze_until = now() + interval '24 hours'
  FROM input
  WHERE input.action = 'SNOOZE' AND ts.id = input.stage_id
  RETURNING ts.id, ts.turn_id, ts.stage_code, ts.stage_name, ts.snooze_until
), cancel_turn AS (
  UPDATE "turn" t
  SET status = 'cancelled'
  FROM input
  WHERE input.action = 'CANCEL' AND t.id = input.turn_id AND t.status = 'active'
  RETURNING t.id, t.unit_label
), cancel_stages AS (
  UPDATE turn_stage ts
  SET status = 'cancelled'
  FROM cancel_turn ct
  WHERE ts.turn_id = ct.id AND ts.status IN ('pending', 'active', 'awaiting_approval', 'blocked')
  RETURNING ts.id
), cancel_queues AS (
  UPDATE outbound_queue oq
  SET status = 'cancelled', decision_by = (SELECT actor_id FROM input), decided_at = now()
  FROM cancel_turn ct
  WHERE oq.turn_id = ct.id AND oq.status IN ('awaiting_approval', 'editing')
  RETURNING oq.id
), action_event AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT
    COALESCE((SELECT turn_id FROM activate_sent_stage LIMIT 1), (SELECT turn_id FROM skip_stage LIMIT 1), (SELECT turn_id FROM snooze_stage LIMIT 1), (SELECT id FROM cancel_turn LIMIT 1), (SELECT turn_id FROM chase_stage LIMIT 1), (SELECT turn_id FROM queue_row LIMIT 1)),
    COALESCE((SELECT id FROM activate_sent_stage LIMIT 1), (SELECT id FROM skip_stage LIMIT 1), (SELECT id FROM snooze_stage LIMIT 1), (SELECT stage_id FROM chase_stage LIMIT 1), (SELECT stage_id FROM queue_row LIMIT 1)),
    'manager',
    input.actor_id,
    input.channel,
    CASE
      WHEN input.action = 'SEND' THEN 'msg_sent'
      WHEN input.action = 'HOLD' THEN 'msg_held'
      WHEN input.action = 'EDIT' AND input.edited_text = '' THEN 'msg_edit_requested'
      WHEN input.action = 'EDIT' THEN 'msg_edited'
      WHEN input.action = 'SKIP' THEN 'stage_skipped'
      WHEN input.action = 'SNOOZE' THEN 'stage_snoozed'
      WHEN input.action = 'CANCEL' THEN 'turn_cancelled'
      WHEN input.action = 'CHASE' THEN 'chase_drafted'
      ELSE 'msg_rejected'
    END,
    input.action,
    jsonb_build_object('queue_id', COALESCE((SELECT id FROM chase_queue LIMIT 1), input.queue_id), 'stage_id', input.stage_id, 'turn_id', input.turn_id, 'edited', input.edited_text <> '')
  FROM input
  WHERE input.action IN ('SEND', 'HOLD', 'EDIT', 'SKIP', 'SNOOZE', 'CANCEL', 'CHASE')
  RETURNING id
)
SELECT
  input.action,
  COALESCE((SELECT id FROM chase_queue LIMIT 1), input.queue_id) AS queue_id,
  input.stage_id,
  input.turn_id,
  CASE
    WHEN (SELECT count(*) FROM mark_sent) > 0 THEN 'sent'
    WHEN (SELECT count(*) FROM mark_hold) > 0 THEN 'held'
    WHEN (SELECT count(*) FROM mark_edit) > 0 AND input.edited_text = '' THEN 'editing'
    WHEN (SELECT count(*) FROM mark_edit) > 0 THEN 'awaiting_approval'
    WHEN (SELECT count(*) FROM chase_queue) > 0 THEN 'chase_awaiting_approval'
    WHEN (SELECT count(*) FROM chase_stage) > 0 THEN 'chase_already_pending'
    WHEN (SELECT count(*) FROM skip_stage) > 0 THEN 'skipped'
    WHEN (SELECT count(*) FROM snooze_stage) > 0 THEN 'snoozed'
    WHEN (SELECT count(*) FROM cancel_turn) > 0 THEN 'cancelled'
    ELSE 'no_change'
  END AS outcome,
  COALESCE((SELECT approved_text FROM mark_sent LIMIT 1), (SELECT approved_text FROM chase_queue LIMIT 1)) AS approved_text,
  (SELECT sent_to_sender_ref FROM mark_sent LIMIT 1) AS sent_to_sender_ref,
  (SELECT row_to_json(activate_sent_stage) FROM activate_sent_stage LIMIT 1) AS activated_stage,
  CASE WHEN (SELECT count(*) FROM chase_queue) > 0 THEN (SELECT 'Manager approval required before sending.\\n\\nDraft to approve:\\n' || approved_text FROM chase_queue LIMIT 1) ELSE NULL END AS manager_approval_text,
  NULLIF(input.telegram_chat_id, '') AS manager_chat_id,
  NULLIF(input.telegram_callback_query_id, '') AS telegram_callback_query_id,
  ((SELECT count(*) FROM chase_queue) > 0 AND input.telegram_chat_id <> '') AS should_send_manager_approval,
  'local_state_only'::text AS delivery_mode,
  'http://localhost:8080'::text AS cors_origin
FROM input;`;

const normalizeManagerActionCode = `const headers = $json.headers || {};
const query = $json.query || {};
const body = $json.body || {};
const configuredToken = 'local-stage-3-demo-token';
const suppliedToken = query.token || headers['x-demo-token'] || headers['X-Demo-Token'] || body.token || '';
return [{ json: {
  authorized: Boolean(configuredToken) && String(suppliedToken) === String(configuredToken),
  action: String(body.action || query.action || '').toUpperCase(),
  queue_id: Number(body.queue_id || query.queue_id || 0),
  stage_id: Number(body.stage_id || query.stage_id || 0),
  turn_id: Number(body.turn_id || query.turn_id || 0),
  actor_id: String(body.actor_id || query.actor_id || 'board-manager'),
  channel: String(body.channel || query.channel || 'board'),
  edited_text: String(body.edited_text || query.edited_text || ''),
  telegram_chat_id: String(body.telegram_chat_id || query.telegram_chat_id || ''),
  cors_origin: 'http://localhost:8080'
} }];`;

const parseManagerCode = `const callback = $json.callback_query || null;
const message = $json.message || $json.edited_message || null;
if (message) {
  const text = String(message.text || '').trim().toLowerCase();
  const chatId = message.chat && message.chat.id ? message.chat.id : '';
  const fromId = message.from ? message.from.id : 'manager-telegram';
  if (text === '/health') return [{ json: { handled: true, route: 'health', actor_id: String(fromId), channel: 'telegram', telegram_chat_id: chatId } }];
  return [{ json: { handled: false, route: 'noop', reason: 'No action taken.', telegram_chat_id: chatId } }];
}
if (!callback) return [{ json: { handled: false, action: 'ignored', reason: 'No callback query.' } }];
const data = String(callback.data || '');
const chatId = callback.message && callback.message.chat ? callback.message.chat.id : '';
const fromId = callback.from ? callback.from.id : 'manager-telegram';
const parts = data.split(':');
const action = parts[0] || 'NOOP';
if (action === 'DONE') return [{ json: { handled: true, route: 'complete', action: 'DONE', stage_id: Number(parts[1] || 0), actor_id: String(fromId), channel: 'digest', telegram_callback_query_id: callback.id, telegram_chat_id: chatId } }];
if (['SEND', 'HOLD', 'EDIT'].includes(action)) return [{ json: { handled: true, route: 'action', action, queue_id: Number(parts[1] || 0), actor_id: String(fromId), channel: 'telegram', telegram_callback_query_id: callback.id, telegram_chat_id: chatId } }];
if (['SKIP', 'SNOOZE', 'CHASE'].includes(action)) return [{ json: { handled: true, route: 'action', action, stage_id: Number(parts[1] || 0), actor_id: String(fromId), channel: 'telegram', telegram_callback_query_id: callback.id, telegram_chat_id: chatId } }];
if (action === 'CANCEL') return [{ json: { handled: true, route: 'action', action, turn_id: Number(parts[1] || 0), actor_id: String(fromId), channel: 'telegram', telegram_callback_query_id: callback.id, telegram_chat_id: chatId } }];
return [{ json: { handled: false, action: 'noop', telegram_callback_query_id: callback.id, telegram_chat_id: chatId, reason: 'No action taken.' } }];`;

const routeDoneCode = `return [{ json: { route_done: $json.route === 'complete', ...$json } }];`;
const routeActionCode = `return [{ json: { route_action: $json.route === 'action', ...$json } }];`;
const routeHealthCode = `return [{ json: { route_health: $json.route === 'health', ...$json } }];`;

const healthQuery = `WITH input AS (
  SELECT
    '{{ String($json.actor_id || "manager").replace(/'/g, "''") }}'::text AS actor_id,
    '{{ String($json.channel || "system").replace(/'/g, "''") }}'::text AS channel
), metrics AS (
  SELECT
    COALESCE((
      SELECT round(100.0 * count(*) FILTER (WHERE completed_via = 'vendor_reply') / nullif(count(*), 0))::int
      FROM turn_stage
      WHERE vendor_id IS NOT NULL AND status IN ('complete', 'skipped') AND completed_at > now() - interval '30 days'
    ), 0) AS vendor_reply_rate,
    COALESCE((
      SELECT round(100.0 * count(*) FILTER (WHERE event_type = 'stage_complete') / nullif(count(*), 0))::int
      FROM event_log
      WHERE actor_type = 'vendor' AND created_at > now() - interval '30 days'
    ), 0) AS auto_handled_rate
), board AS (
  SELECT count(*)::int AS active_turns,
         COALESCE(sum(round((t.rent_monthly / 30) * greatest(0, (current_date - t.moveout_date)))), 0)::int AS dollars_burning_now
  FROM "turn" t
  WHERE t.status = 'active'
), stalled AS (
  SELECT count(*)::int AS stalled_vendor_stages
  FROM turn_stage ts
  JOIN vendor v ON v.id = ts.vendor_id
  WHERE ts.status = 'active'
    AND v.trade <> 'inspect'
    AND ts.sla_hours > 0
    AND ts.activated_at + (ts.sla_hours || ' hours')::interval <= now()
), logged AS (
  INSERT INTO event_log (actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT 'manager', input.actor_id, input.channel, 'health_check', 'manager health check',
    jsonb_build_object('vendor_reply_rate', metrics.vendor_reply_rate, 'auto_handled_rate', metrics.auto_handled_rate, 'active_turns', board.active_turns, 'stalled_vendor_stages', stalled.stalled_vendor_stages)
  FROM input, metrics, board, stalled
  RETURNING id
)
SELECT
  metrics.vendor_reply_rate,
  metrics.auto_handled_rate,
  board.active_turns,
  board.dollars_burning_now,
  stalled.stalled_vendor_stages,
  ('Health check\\nVendor reply rate: ' || metrics.vendor_reply_rate || '%\\nAuto-handled: ' || metrics.auto_handled_rate || '%\\nUnits in turn: ' || board.active_turns || '\\nBurning now: $' || board.dollars_burning_now || '\\nStalled vendor stages: ' || stalled.stalled_vendor_stages) AS health_text,
  'http://localhost:8080'::text AS cors_origin
FROM metrics, board, stalled;`;

const normalizeHealthApiCode = `const headers = $json.headers || {};
const query = $json.query || {};
const configuredToken = 'local-stage-3-demo-token';
const suppliedToken = query.token || headers['x-demo-token'] || headers['X-Demo-Token'] || '';
return [{ json: { authorized: Boolean(configuredToken) && String(suppliedToken) === String(configuredToken), actor_id: 'health-api', channel: 'board', cors_origin: 'http://localhost:8080' } }];`;

const watchdogNormalizeCode = `const query = $json.query || {};
const body = $json.body || {};
return [{ json: {
  now_override: String(body.now_override || query.now_override || ''),
  force_hour: Number(body.force_hour ?? query.force_hour ?? -1),
  manager_chat_id: 'stage5-manager-chat-id-missing',
  cors_origin: 'http://localhost:8080'
} }];`;

const watchdogQuery = `WITH input AS (
  SELECT
    COALESCE(NULLIF('{{ String($json.now_override || "").replace(/'/g, "''") }}', '')::timestamptz, now()) AS current_ts,
    {{ Number($json.force_hour ?? -1) }}::int AS force_hour,
    '{{ String($json.manager_chat_id || "").replace(/'/g, "''") }}'::text AS manager_chat_id
), business AS (
  SELECT
    input.*,
    CASE
      WHEN input.force_hour BETWEEN 0 AND 23 THEN input.force_hour
      ELSE EXTRACT(HOUR FROM input.current_ts AT TIME ZONE 'America/Phoenix')::int
    END AS local_hour
  FROM input
), candidates AS (
  SELECT
    ts.id AS stage_id,
    ts.turn_id,
    ts.stage_name,
    ts.sla_hours,
    ts.activated_at,
    t.unit_label,
    t.property_address,
    t.rent_monthly,
    v.name AS vendor_name,
    round(extract(epoch FROM ((SELECT current_ts FROM input) - ts.activated_at)) / 3600, 1) AS hours_at_stage,
    round((t.rent_monthly / 30) * greatest(0, (date((SELECT current_ts FROM input)) - t.moveout_date)))::int AS dollars_burned
  FROM turn_stage ts
  JOIN "turn" t ON t.id = ts.turn_id
  JOIN vendor v ON v.id = ts.vendor_id
  WHERE t.status = 'active'
    AND ts.status = 'active'
    AND v.trade <> 'inspect'
    AND ts.sla_hours > 0
    AND ts.alerted_at IS NULL
    AND (ts.snooze_until IS NULL OR ts.snooze_until <= (SELECT current_ts FROM input))
    AND ts.activated_at + (ts.sla_hours || ' hours')::interval <= (SELECT current_ts FROM input)
), marked AS (
  UPDATE turn_stage ts
  SET alerted_at = (SELECT current_ts FROM input)
  FROM candidates c, business b
  WHERE b.local_hour >= 8 AND b.local_hour < 18
    AND ts.id = c.stage_id
  RETURNING c.*
), held AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json, created_at)
  SELECT c.turn_id, c.stage_id, 'system', 'stage-6-watchdog', 'system', 'stall_alert_held',
    c.unit_label || ' ' || c.stage_name || ' alert held outside business hours',
    jsonb_build_object('hours_at_stage', c.hours_at_stage, 'local_hour', (SELECT local_hour FROM business)),
    (SELECT current_ts FROM input)
  FROM candidates c, business b
  WHERE NOT (b.local_hour >= 8 AND b.local_hour < 18)
    AND NOT EXISTS (
      SELECT 1 FROM event_log e
      WHERE e.stage_id = c.stage_id
        AND e.event_type = 'stall_alert_held'
        AND e.created_at >= c.activated_at
    )
  RETURNING id
), alert_events AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json, created_at)
  SELECT m.turn_id, m.stage_id, 'system', 'stage-6-watchdog', 'system', 'stall_alert',
    m.unit_label || ' ' || m.stage_name || ' is stalled',
    jsonb_build_object('hours_at_stage', m.hours_at_stage, 'sla_hours', m.sla_hours, 'dollars_burned', m.dollars_burned, 'vendor_name', m.vendor_name),
    (SELECT current_ts FROM input)
  FROM marked m
  RETURNING id
), lines AS (
  SELECT string_agg(unit_label || ' - ' || stage_name || ' - ' || hours_at_stage || 'h at stage - $' || dollars_burned || ' burned', E'\\n' ORDER BY hours_at_stage DESC) AS text
  FROM marked
)
SELECT
  (SELECT count(*) FROM candidates)::int AS candidate_count,
  (SELECT count(*) FROM marked)::int AS alert_count,
  (SELECT count(*) FROM held)::int AS held_count,
  (SELECT local_hour FROM business)::int AS local_hour,
  ((SELECT count(*) FROM marked) > 0) AS alerted,
  ((SELECT count(*) FROM held) > 0) AS held,
  NULLIF((SELECT manager_chat_id FROM input), 'stage5-manager-chat-id-missing') AS manager_chat_id,
  ((SELECT count(*) FROM marked) > 0 AND (SELECT manager_chat_id FROM input) <> '' AND (SELECT manager_chat_id FROM input) <> 'stage5-manager-chat-id-missing') AS should_notify_manager,
  COALESCE('Stall alert\\n' || (SELECT text FROM lines), 'No stall alerts.') AS manager_notice_text,
  'http://localhost:8080'::text AS cors_origin;`;

const digestShapeCode = `const rows = items.map(item => item.json);
const now = new Date();
function parseStages(value) { if (Array.isArray(value)) return value; if (!value) return []; try { return JSON.parse(value); } catch { return []; } }
function hoursSince(value) { if (!value) return 0; return Math.max(0, (now.getTime() - new Date(value).getTime()) / 36e5); }
function healthFor(hours, slaHours, status) { if (status === 'awaiting_approval') return 'amber'; const sla = Number(slaHours || 0); if (sla <= 0) return 'green'; if (hours / sla >= 1) return 'red'; if (hours / sla >= 0.5) return 'amber'; return 'green'; }
const rank = { red: 3, amber: 2, green: 1 };
const turns = rows.map(row => {
  const hours = hoursSince(row.current_activated_at);
  const moveout = new Date(String(row.moveout_date).slice(0, 10) + 'T00:00:00Z');
  const today = new Date(now.toISOString().slice(0, 10) + 'T00:00:00Z');
  return {
    stage_id: Number(row.current_stage_id),
    turn_id: Number(row.turn_id),
    unit_label: row.unit_label,
    current_stage_name: row.current_stage_name,
    current_vendor_name: row.current_vendor_name || 'Unassigned',
    hours_at_stage: Math.round(hours * 10) / 10,
    health: healthFor(hours, row.current_sla_hours, row.current_stage_status),
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
const first = turns[0] || {};
const second = turns[1] || {};
const buttons = [
  { text: first.stage_id ? 'Done ' + first.unit_label : 'No unit', callback_data: first.stage_id ? 'DONE:' + first.stage_id : 'NOOP' },
  { text: first.stage_id ? 'Skip ' + first.unit_label : 'No unit', callback_data: first.stage_id ? 'SKIP:' + first.stage_id : 'NOOP' },
  { text: first.stage_id ? 'Snooze ' + first.unit_label : 'No unit', callback_data: first.stage_id ? 'SNOOZE:' + first.stage_id : 'NOOP' },
  { text: first.stage_id ? 'Chase ' + first.unit_label : 'No unit', callback_data: first.stage_id ? 'CHASE:' + first.stage_id : 'NOOP' },
  { text: first.turn_id ? 'Cancel ' + first.unit_label : 'No unit', callback_data: first.turn_id ? 'CANCEL:' + first.turn_id : 'NOOP' },
  { text: second.stage_id ? 'Done ' + second.unit_label : 'No unit', callback_data: second.stage_id ? 'DONE:' + second.stage_id : 'NOOP' }
];
return [{ json: {
  chat_id: 'stage3-manager-chat-id-missing',
  digest_text: 'Daily make-ready digest\\n' + activeCount + ' units in turn - $' + dollars + ' burning right now\\nVendor reply rate ' + vendorReply + '% - Auto-handled ' + autoHandled + '% (30 days)\\n\\n' + lines.join('\\n'),
  buttons
} }];`;

function updateBoardWorkflow() {
  const board = load("wf-3-board-api.json");
  node(board, "Load Board State").parameters.query = boardQuery;
  node(board, "Shape Board Response").parameters.jsCode = shapeBoardCode;
  save("wf-3-board-api.json", board);
}

function updateVendorWorkflows() {
  const vendorIn = load("wf-4-vendor-in-api.json");
  node(vendorIn, "Normalize Vendor In Request").parameters.jsCode = normalizeVendorApiCode;
  save("wf-4-vendor-in-api.json", vendorIn);

  const vendorTg = load("wf-4-vendor-telegram-ingest.json");
  node(vendorTg, "Normalize Vendor Telegram Message").parameters.jsCode = normalizeTelegramCode;
  save("wf-4-vendor-telegram-ingest.json", vendorTg);

  const router = load("wf-4-vendor-router.json");
  node(router, "Prepare Known Route").parameters.jsCode = prepareKnownRouteCode;
  node(router, "Log Vendor Router Event").parameters.query = logRouterEventQuery;
  save("wf-4-vendor-router.json", router);

  const completion = load("wf-5-vendor-completion-handler.json");
  node(completion, "Complete Stage And Queue Next").parameters.query = completionQuery;
  save("wf-5-vendor-completion-handler.json", completion);
}

function updateManagerActionWorkflow() {
  const core = load("wf-5-manager-action-core.json");
  node(core, "Apply Manager Action").parameters.query = managerActionQuery;
  save("wf-5-manager-action-core.json", core);

  const api = load("wf-5-manager-action-api.json");
  node(api, "Normalize Manager Action").parameters.jsCode = normalizeManagerActionCode;
  save("wf-5-manager-action-api.json", api);
}

function writeManagerRouter() {
  save(
    "wf-3-manager-router.json",
    wf(
      "wf3-manager-router",
      "WF-3 Manager Router",
      [
        { id: "manager-trigger", name: "ManagerTelegramTrigger", type: "n8n-nodes-base.telegramTrigger", typeVersion: 1.3, position: [0, 0], parameters: { updates: ["message", "callback_query"], additionalFields: {} }, credentials: { telegramApi: managerTgCred } },
        codeNode("parse-manager-update", "Parse Manager Update", 240, 0, parseManagerCode),
        ifNode("manager-update-handled", "Manager Update Handled?", 500, 0, "={{ $json.handled }}"),
        codeNode("route-health", "Route Health Command", 760, -260, routeHealthCode),
        ifNode("is-health-command", "Is Health Command?", 1020, -260, "={{ $json.route_health }}"),
        executeNode("call-health-core", "Call Health Core", 1280, -360, "wf6-health-core"),
        telegramSendNode("send-health-report", "Send Health Report", 1540, -360, "={{ $json.health_text }}"),
        codeNode("route-done-callback", "Route Done Callback", 1280, -120, routeDoneCode),
        ifNode("is-done-callback", "Is Done Callback?", 1540, -120, "={{ $json.route_done }}"),
        executeNode("call-completion-core-from-manager", "Call Completion Core From Manager", 1800, -220, "wf3-stage-complete-core"),
        codeNode("route-action-callback", "Route Action Callback", 1800, 20, routeActionCode),
        ifNode("is-action-callback", "Is Action Callback?", 2060, 20, "={{ $json.route_action }}"),
        executeNode("call-manager-action-core", "Call Manager Action Core", 2320, -80, "wf5-manager-action-core"),
        ifNode("manager-action-needs-approval-card", "Manager Action Needs Approval Card?", 2580, -80, "={{ $json.should_send_manager_approval }}"),
        telegramApprovalNode("send-chase-approval-card", "Send Chase Approval Card", 2840, -200),
        { id: "answer-callback", name: "Answer Manager Callback", type: "n8n-nodes-base.telegram", typeVersion: 1.2, position: [2840, 60], parameters: { resource: "callback", operation: "answerQuery", queryId: "={{ $json.telegram_callback_query_id }}", additionalFields: { text: '={{ $json.outcome || $json.manager_response_text || $json.reason || $json.message || "Done" }}', show_alert: false } }, credentials: { telegramApi: managerTgCred } },
        { id: "answer-noop", name: "Answer Ignored Callback", type: "n8n-nodes-base.telegram", typeVersion: 1.2, position: [760, 180], parameters: { resource: "callback", operation: "answerQuery", queryId: "={{ $json.telegram_callback_query_id }}", additionalFields: { text: "No action taken.", show_alert: false } }, credentials: { telegramApi: managerTgCred } },
      ],
      {
        ManagerTelegramTrigger: { main: [[{ node: "Parse Manager Update", type: "main", index: 0 }]] },
        "Parse Manager Update": { main: [[{ node: "Manager Update Handled?", type: "main", index: 0 }]] },
        "Manager Update Handled?": { main: [[{ node: "Route Health Command", type: "main", index: 0 }], [{ node: "Answer Ignored Callback", type: "main", index: 0 }]] },
        "Route Health Command": { main: [[{ node: "Is Health Command?", type: "main", index: 0 }]] },
        "Is Health Command?": { main: [[{ node: "Call Health Core", type: "main", index: 0 }], [{ node: "Route Done Callback", type: "main", index: 0 }]] },
        "Call Health Core": { main: [[{ node: "Send Health Report", type: "main", index: 0 }]] },
        "Route Done Callback": { main: [[{ node: "Is Done Callback?", type: "main", index: 0 }]] },
        "Is Done Callback?": { main: [[{ node: "Call Completion Core From Manager", type: "main", index: 0 }], [{ node: "Route Action Callback", type: "main", index: 0 }]] },
        "Call Completion Core From Manager": { main: [[{ node: "Answer Manager Callback", type: "main", index: 0 }]] },
        "Route Action Callback": { main: [[{ node: "Is Action Callback?", type: "main", index: 0 }]] },
        "Is Action Callback?": { main: [[{ node: "Call Manager Action Core", type: "main", index: 0 }], [{ node: "Answer Ignored Callback", type: "main", index: 0 }]] },
        "Call Manager Action Core": { main: [[{ node: "Manager Action Needs Approval Card?", type: "main", index: 0 }]] },
        "Manager Action Needs Approval Card?": { main: [[{ node: "Send Chase Approval Card", type: "main", index: 0 }], [{ node: "Answer Manager Callback", type: "main", index: 0 }]] },
        "Send Chase Approval Card": { main: [[{ node: "Answer Manager Callback", type: "main", index: 0 }]] },
      },
      false,
    ),
  );
}

function writeDailyDigest() {
  const digest = load("wf-3-daily-digest.json");
  node(digest, "Format Digest Message").parameters.jsCode = digestShapeCode;
  save("wf-3-daily-digest.json", digest);
}

function writeHealthWorkflows() {
  save(
    "wf-6-health-core.json",
    wf("wf6-health-core", "WF-6 Health Core", [
      { id: "trigger", name: "Receive Health Request", type: "n8n-nodes-base.executeWorkflowTrigger", typeVersion: 1.2, position: [0, 0], parameters: { inputSource: "passthrough" } },
      pgNode("load-health-metrics", "Load Health Metrics", 280, 0, healthQuery),
    ], { "Receive Health Request": { main: [[{ node: "Load Health Metrics", type: "main", index: 0 }]] } }, false),
  );

  save(
    "wf-6-health-api.json",
    wf("wf6-health-api", "WF-6 Health API", [
      { id: "webhook-health", name: "GET Health Webhook", type: "n8n-nodes-base.webhook", typeVersion: 2.1, position: [0, 0], webhookId: "wf6-health-api", parameters: { httpMethod: "GET", path: "health", authentication: "none", responseMode: "responseNode", options: { allowedOrigins: "http://localhost:8080" } } },
      codeNode("normalize-health-auth", "Normalize Health Auth", 280, 0, normalizeHealthApiCode),
      ifNode("health-authorized", "Health Authorized?", 560, 0, "={{ $json.authorized }}"),
      executeNode("call-health-core", "Call Health Core", 840, -120, "wf6-health-core"),
      respondNode("respond-health-ok", "Respond Health 200", 1120, -120, 200),
      codeNode("format-health-unauthorized", "Format Health Unauthorized", 840, 120, "return [{ json: { accepted: false, outcome: 'unauthorized', error: 'unauthorized', cors_origin: 'http://localhost:8080' } }];"),
      respondNode("respond-health-unauthorized", "Respond Health 401", 1120, 120, 401),
    ], {
      "GET Health Webhook": { main: [[{ node: "Normalize Health Auth", type: "main", index: 0 }]] },
      "Normalize Health Auth": { main: [[{ node: "Health Authorized?", type: "main", index: 0 }]] },
      "Health Authorized?": { main: [[{ node: "Call Health Core", type: "main", index: 0 }], [{ node: "Format Health Unauthorized", type: "main", index: 0 }]] },
      "Call Health Core": { main: [[{ node: "Respond Health 200", type: "main", index: 0 }]] },
      "Format Health Unauthorized": { main: [[{ node: "Respond Health 401", type: "main", index: 0 }]] },
    }, true),
  );
}

function writeWatchdogWorkflow() {
  save(
    "wf-6-stall-watchdog.json",
    wf("wf6-stall-watchdog", "WF-6 Stall Watchdog", [
      { id: "webhook-watchdog", name: "POST Stall Watchdog Webhook", type: "n8n-nodes-base.webhook", typeVersion: 2.1, position: [0, -120], webhookId: "wf6-stall-watchdog", parameters: { httpMethod: "POST", path: "stall-watchdog", authentication: "none", responseMode: "lastNode", options: { allowedOrigins: "http://localhost:8080" } } },
      { id: "schedule-watchdog", name: "Schedule Stall Watchdog", type: "n8n-nodes-base.scheduleTrigger", typeVersion: 1.2, position: [0, 120], parameters: { rule: { interval: [{ field: "minutes", minutesInterval: 15 }] } } },
      codeNode("normalize-watchdog-run", "Normalize Watchdog Run", 280, 0, watchdogNormalizeCode),
      pgNode("find-and-log-stalls", "Find And Log Stalls", 560, 0, watchdogQuery),
      ifNode("notify-manager-about-stalls", "Notify Manager About Stalls?", 840, 0, "={{ $json.should_notify_manager }}"),
      telegramSendNode("send-stall-alert", "Send Stall Alert", 1120, -120, "={{ $json.manager_notice_text }}"),
      codeNode("return-after-stall-alert", "Return After Stall Alert", 1400, -120, "return [$('Find And Log Stalls').first()];"),
      codeNode("return-watchdog-summary", "Return Watchdog Summary", 1120, 120, "return items;"),
    ], {
      "POST Stall Watchdog Webhook": { main: [[{ node: "Normalize Watchdog Run", type: "main", index: 0 }]] },
      "Schedule Stall Watchdog": { main: [[{ node: "Normalize Watchdog Run", type: "main", index: 0 }]] },
      "Normalize Watchdog Run": { main: [[{ node: "Find And Log Stalls", type: "main", index: 0 }]] },
      "Find And Log Stalls": { main: [[{ node: "Notify Manager About Stalls?", type: "main", index: 0 }]] },
      "Notify Manager About Stalls?": { main: [[{ node: "Send Stall Alert", type: "main", index: 0 }], [{ node: "Return Watchdog Summary", type: "main", index: 0 }]] },
      "Send Stall Alert": { main: [[{ node: "Return After Stall Alert", type: "main", index: 0 }]] },
    }, true),
  );
}

function writeWeeklyDigest() {
  save(
    "wf-6-weekly-digest.json",
    wf("wf6-weekly-digest", "WF-6 Weekly Metric Digest", [
      { id: "schedule-weekly-digest", name: "Schedule Weekly Digest", type: "n8n-nodes-base.scheduleTrigger", typeVersion: 1.2, position: [0, 0], parameters: { rule: { interval: [{ field: "weeks", triggerAtDay: [1], triggerAtHour: 8 }] } } },
      codeNode("prepare-weekly-health-request", "Prepare Weekly Health Request", 280, 0, "return [{ json: { actor_id: 'weekly-digest', channel: 'digest', manager_chat_id: 'stage3-manager-chat-id-missing' } }];"),
      executeNode("call-health-core", "Call Health Core", 560, 0, "wf6-health-core"),
      codeNode("format-weekly-digest", "Format Weekly Digest", 840, 0, "return [{ json: { ...$json, manager_chat_id: 'stage3-manager-chat-id-missing', weekly_text: 'Weekly make-ready metrics\\n' + $json.health_text } }];"),
      pgNode("log-weekly-digest", "Log Weekly Digest", 1120, 0, "INSERT INTO event_log (actor_type, actor_id, channel, event_type, raw_text, parsed_json) VALUES ('system', 'stage-6-weekly-digest', 'digest', 'weekly_digest', '{{ String($json.weekly_text || \"weekly digest\").replace(/'/g, \"''\") }}', jsonb_build_object('vendor_reply_rate', {{ Number($json.vendor_reply_rate || 0) }}, 'auto_handled_rate', {{ Number($json.auto_handled_rate || 0) }})) RETURNING true AS logged, '{{ String($json.weekly_text || \"\").replace(/'/g, \"''\") }}'::text AS weekly_text, NULLIF('{{ String($json.manager_chat_id || \"\").replace(/'/g, \"''\") }}', 'stage3-manager-chat-id-missing') AS manager_chat_id;"),
      ifNode("weekly-manager-chat-configured", "Weekly Manager Chat Configured?", 1400, 0, "={{ Boolean($json.manager_chat_id) }}"),
      telegramSendNode("send-weekly-digest", "Send Weekly Digest", 1680, -120, "={{ $json.weekly_text }}"),
    ], {
      "Schedule Weekly Digest": { main: [[{ node: "Prepare Weekly Health Request", type: "main", index: 0 }]] },
      "Prepare Weekly Health Request": { main: [[{ node: "Call Health Core", type: "main", index: 0 }]] },
      "Call Health Core": { main: [[{ node: "Format Weekly Digest", type: "main", index: 0 }]] },
      "Format Weekly Digest": { main: [[{ node: "Log Weekly Digest", type: "main", index: 0 }]] },
      "Log Weekly Digest": { main: [[{ node: "Weekly Manager Chat Configured?", type: "main", index: 0 }]] },
      "Weekly Manager Chat Configured?": { main: [[{ node: "Send Weekly Digest", type: "main", index: 0 }], []] },
    }, false),
  );
}

updateBoardWorkflow();
updateVendorWorkflows();
updateManagerActionWorkflow();
writeManagerRouter();
writeDailyDigest();
writeHealthWorkflows();
writeWatchdogWorkflow();
writeWeeklyDigest();
