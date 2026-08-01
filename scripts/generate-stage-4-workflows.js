const fs = require("fs");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const outDir = path.join(repoRoot, "n8n-workflows");
fs.mkdirSync(outDir, { recursive: true });

const pgCred = { id: "cred_make_ready_pg", name: "Make-Ready Postgres" };
const managerTgCred = { id: "jASZWMlrfp3v2tWH", name: "Make-Ready Manager Telegram Bot" };
const vendorTgCred = { id: "5mBfLarFM6t8Cgcz", name: "Make-Ready Vendor Telegram Bot" };

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
            { name: "Access-Control-Allow-Origin", value: '={{ $json.cors_origin || "http://localhost:8080" }}' },
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

const formFields = [
  { fieldLabel: "Unit label", fieldName: "unit_label", fieldType: "text", placeholder: "12B", requiredField: true },
  { fieldLabel: "Property address", fieldName: "property_address", fieldType: "text", placeholder: "418 Maple St", requiredField: true },
  { fieldLabel: "Monthly rent", fieldName: "rent_monthly", fieldType: "number", placeholder: "1450", requiredField: true },
  { fieldLabel: "Notice date", fieldName: "notice_date", fieldType: "date", requiredField: true },
  { fieldLabel: "Move-out date", fieldName: "moveout_date", fieldType: "date", requiredField: true },
  { fieldLabel: "Target ready date", fieldName: "target_ready_date", fieldType: "date", requiredField: false },
  {
    fieldLabel: "Trash-out vendor",
    fieldName: "trashout_vendor",
    fieldType: "dropdown",
    requiredField: true,
    defaultValue: "QuickHaul Junk Removal",
    fieldOptions: { values: [{ option: "QuickHaul Junk Removal" }, { option: "Cedar Ridge in-house" }] },
  },
  {
    fieldLabel: "Repairs vendor",
    fieldName: "repairs_vendor",
    fieldType: "dropdown",
    requiredField: true,
    defaultValue: "Dale Hutchins",
    fieldOptions: { values: [{ option: "Dale Hutchins" }, { option: "Cedar Ridge in-house" }] },
  },
  {
    fieldLabel: "Paint vendor",
    fieldName: "paint_vendor",
    fieldType: "dropdown",
    requiredField: true,
    defaultValue: "Rivera Painting",
    fieldOptions: { values: [{ option: "Rivera Painting" }, { option: "Cedar Ridge in-house" }] },
  },
  {
    fieldLabel: "Flooring vendor",
    fieldName: "flooring_vendor",
    fieldType: "dropdown",
    requiredField: true,
    defaultValue: "Statewide Flooring",
    fieldOptions: { values: [{ option: "Statewide Flooring" }, { option: "Cedar Ridge in-house" }] },
  },
  {
    fieldLabel: "Deep clean vendor",
    fieldName: "deep_clean_vendor",
    fieldType: "dropdown",
    requiredField: true,
    defaultValue: "Maria's Cleaning Co",
    fieldOptions: { values: [{ option: "Maria's Cleaning Co" }, { option: "Cedar Ridge in-house" }] },
  },
];

const normalizeIntakeCode = `const input = $json;
function pick(...keys) {
  for (const key of keys) {
    if (input[key] !== undefined && input[key] !== null && String(input[key]).trim() !== '') return String(input[key]).trim();
  }
  return '';
}
function dateOnly(value, field) {
  if (!value) throw new Error(field + ' is required.');
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) throw new Error(field + ' is not a valid date.');
  return parsed.toISOString().slice(0, 10);
}
function addDays(dateText, days) {
  const date = new Date(dateText + 'T00:00:00Z');
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}
const unitLabel = pick('unit_label', 'Unit label', 'field-0');
const propertyAddress = pick('property_address', 'Property address', 'field-1');
const rentMonthly = Number(pick('rent_monthly', 'Monthly rent', 'field-2'));
if (!unitLabel) throw new Error('unit_label is required.');
if (!propertyAddress) throw new Error('property_address is required.');
if (!Number.isFinite(rentMonthly) || rentMonthly < 0) throw new Error('rent_monthly must be a non-negative number.');
const noticeDate = dateOnly(pick('notice_date', 'Notice date', 'field-3'), 'notice_date');
const moveoutDate = dateOnly(pick('moveout_date', 'Move-out date', 'field-4'), 'moveout_date');
const targetInput = pick('target_ready_date', 'Target ready date', 'field-5');
const targetReadyDate = targetInput ? dateOnly(targetInput, 'target_ready_date') : addDays(moveoutDate, 5);
return [{ json: {
  unit_label: unitLabel,
  property_address: propertyAddress,
  rent_monthly: rentMonthly,
  notice_date: noticeDate,
  moveout_date: moveoutDate,
  target_ready_date: targetReadyDate,
  trashout_vendor: pick('trashout_vendor', 'Trash-out vendor', 'field-6') || 'QuickHaul Junk Removal',
  repairs_vendor: pick('repairs_vendor', 'Repairs vendor', 'field-7') || 'Dale Hutchins',
  paint_vendor: pick('paint_vendor', 'Paint vendor', 'field-8') || 'Rivera Painting',
  flooring_vendor: pick('flooring_vendor', 'Flooring vendor', 'field-9') || 'Statewide Flooring',
  deep_clean_vendor: pick('deep_clean_vendor', 'Deep clean vendor', 'field-10') || "Maria's Cleaning Co"
} }];`;

const intakeInsertQuery = `WITH input AS (
  SELECT
    '{{ String($json.unit_label || "").replace(/'/g, "''") }}'::text AS unit_label,
    '{{ String($json.property_address || "").replace(/'/g, "''") }}'::text AS property_address,
    {{ Number($json.rent_monthly || 0) }}::numeric AS rent_monthly,
    '{{ String($json.notice_date || "").replace(/'/g, "''") }}'::date AS notice_date,
    '{{ String($json.moveout_date || "").replace(/'/g, "''") }}'::date AS moveout_date,
    '{{ String($json.target_ready_date || "").replace(/'/g, "''") }}'::date AS target_ready_date,
    '{{ String($json.trashout_vendor || "QuickHaul Junk Removal").replace(/'/g, "''") }}'::text AS trashout_vendor,
    '{{ String($json.repairs_vendor || "Dale Hutchins").replace(/'/g, "''") }}'::text AS repairs_vendor,
    '{{ String($json.paint_vendor || "Rivera Painting").replace(/'/g, "''") }}'::text AS paint_vendor,
    '{{ String($json.flooring_vendor || "Statewide Flooring").replace(/'/g, "''") }}'::text AS flooring_vendor,
    '{{ String($json.deep_clean_vendor || "Maria's Cleaning Co").replace(/'/g, "''") }}'::text AS deep_clean_vendor
), inserted_turn AS (
  INSERT INTO "turn" (unit_label, property_address, rent_monthly, notice_date, moveout_date, target_ready_date, status, is_fixture)
  SELECT unit_label, property_address, rent_monthly, notice_date, moveout_date, target_ready_date, 'active', false
  FROM input
  RETURNING id, unit_label, property_address, target_ready_date
), stage_template(seq, stage_code, stage_name, sla_hours) AS (
  VALUES
    (0, 'NOTICE', 'Notice received', 0),
    (1, 'PRE_INSPECT', 'Pre-move-out inspection', 48),
    (2, 'MOVEOUT', 'Move-out / keys returned', 0),
    (3, 'INSPECT_PUNCH', 'Inspection + punch list', 24),
    (4, 'TRASHOUT', 'Trash-out', 24),
    (5, 'REPAIRS', 'Repairs / trades', 72),
    (6, 'PAINT', 'Paint', 48),
    (7, 'FLOORING', 'Flooring', 48),
    (8, 'DEEP_CLEAN', 'Deep clean', 24),
    (9, 'QA_PHOTOS', 'QA walkthrough + photos', 12),
    (10, 'RELIST', 'Relist', 0)
), stage_vendor AS (
  SELECT 'NOTICE'::text AS stage_code, 'Cedar Ridge in-house'::text AS vendor_name FROM input
  UNION ALL SELECT 'PRE_INSPECT', 'Cedar Ridge in-house' FROM input
  UNION ALL SELECT 'MOVEOUT', 'Cedar Ridge in-house' FROM input
  UNION ALL SELECT 'INSPECT_PUNCH', 'Cedar Ridge in-house' FROM input
  UNION ALL SELECT 'TRASHOUT', trashout_vendor FROM input
  UNION ALL SELECT 'REPAIRS', repairs_vendor FROM input
  UNION ALL SELECT 'PAINT', paint_vendor FROM input
  UNION ALL SELECT 'FLOORING', flooring_vendor FROM input
  UNION ALL SELECT 'DEEP_CLEAN', deep_clean_vendor FROM input
  UNION ALL SELECT 'QA_PHOTOS', 'Cedar Ridge in-house' FROM input
  UNION ALL SELECT 'RELIST', 'Cedar Ridge in-house' FROM input
), inserted_stages AS (
  INSERT INTO turn_stage (turn_id, seq, stage_code, stage_name, status, vendor_id, sla_hours, activated_at)
  SELECT
    it.id,
    st.seq,
    st.stage_code,
    st.stage_name,
    CASE WHEN st.stage_code = 'NOTICE' THEN 'active' ELSE 'pending' END,
    v.id,
    st.sla_hours,
    CASE WHEN st.stage_code = 'NOTICE' THEN now() ELSE NULL END
  FROM inserted_turn it
  CROSS JOIN stage_template st
  JOIN stage_vendor sv ON sv.stage_code = st.stage_code
  LEFT JOIN vendor v ON v.name = sv.vendor_name AND v.active = true
  ORDER BY st.seq
  RETURNING id, turn_id, stage_code, status
), write_event AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT
    it.id,
    (SELECT id FROM inserted_stages WHERE stage_code = 'NOTICE' LIMIT 1),
    'manager',
    'intake-form',
    'form',
    'turn_intake',
    'manager submitted turn intake',
    jsonb_build_object(
      'unit_label', input.unit_label,
      'property_address', input.property_address,
      'target_ready_date', input.target_ready_date,
      'stage_count', (SELECT count(*) FROM inserted_stages),
      'initial_stage_code', 'NOTICE'
    )
  FROM inserted_turn it
  CROSS JOIN input
  RETURNING id
)
SELECT
  it.id AS turn_id,
  it.unit_label,
  it.property_address,
  it.target_ready_date,
  (SELECT count(*) FROM inserted_stages) AS stage_count,
  (SELECT id FROM write_event LIMIT 1) AS event_id,
  'NOTICE'::text AS current_stage_code,
  'Turn added to board.'::text AS formSubmittedText
FROM inserted_turn it;`;

const formatIntakeCode = `return items.map(item => ({ json: {
  accepted: true,
  outcome: 'turn_intake',
  turn_id: Number(item.json.turn_id),
  unit_label: item.json.unit_label,
  property_address: item.json.property_address,
  target_ready_date: item.json.target_ready_date,
  stage_count: Number(item.json.stage_count),
  current_stage_code: item.json.current_stage_code,
  event_id: Number(item.json.event_id),
  formSubmittedText: item.json.formsubmittedtext || item.json.formSubmittedText || 'Turn added to board.'
} }));`;

const matcherLoadQuery = `WITH input AS (
  SELECT
    '{{ String($json.channel || "generic").replace(/'/g, "''") }}'::text AS channel,
    '{{ String($json.sender_ref || "").replace(/'/g, "''") }}'::text AS sender_ref,
    '{{ String($json.text || "").replace(/'/g, "''") }}'::text AS text,
    {{ Number($json.vendor_id || 0) }}::int AS vendor_id,
    '{{ String($json.vendor_name || "").replace(/'/g, "''") }}'::text AS vendor_name,
    '{{ String($json.vendor_trade || "").replace(/'/g, "''") }}'::text AS vendor_trade,
    {{ $json.known_vendor ? 'true' : 'false' }}::boolean AS known_vendor,
    {{ $json.duplicate_like ? 'true' : 'false' }}::boolean AS duplicate_like,
    '{{ JSON.stringify($json.media || null).replace(/'/g, "''") }}'::jsonb AS media,
    '{{ String($json.received_at || new Date().toISOString()).replace(/'/g, "''") }}'::timestamptz AS received_at
), active_stage AS (
  SELECT DISTINCT ON (turn_id) *
  FROM turn_stage
  WHERE status = 'active'
  ORDER BY turn_id, seq
)
SELECT
  input.channel,
  input.sender_ref,
  input.text,
  input.vendor_id,
  input.vendor_name,
  input.vendor_trade,
  input.known_vendor,
  input.duplicate_like,
  input.media,
  input.received_at,
  t.id AS turn_id,
  t.unit_label,
  t.property_address,
  ast.id AS stage_id,
  ast.stage_code,
  ast.stage_name,
  ast.vendor_id AS active_vendor_id,
  v.name AS active_vendor_name
FROM input
CROSS JOIN "turn" t
JOIN active_stage ast ON ast.turn_id = t.id
LEFT JOIN vendor v ON v.id = ast.vendor_id
WHERE t.status = 'active'
ORDER BY t.unit_label;`;

const matcherCode = `const rows = items.map(item => item.json);
const first = rows[0] || {};
function compact(value) {
  return String(value || '').toLowerCase().normalize('NFKD').replace(/[\\u0300-\\u036f]/g, '').replace(/[^a-z0-9]+/g, '');
}
function normalizedTokens(value) {
  return String(value || '').toLowerCase().normalize('NFKD').replace(/[\\u0300-\\u036f]/g, '').replace(/[^a-z0-9]+/g, ' ').trim().split(/\\s+/).filter(Boolean);
}
function streetToken(address) {
  const tokens = normalizedTokens(address).filter(token => !/^\\d+$/.test(token));
  const suffixes = new Set(['st', 'street', 'ave', 'avenue', 'ct', 'court', 'rd', 'road', 'dr', 'drive', 'ln', 'lane', 'blvd', 'way', 'pl', 'place']);
  return tokens.find(token => !suffixes.has(token)) || '';
}
const text = first.text || '';
const tokens = normalizedTokens(text);
const tokenSet = new Set(tokens);
const media = typeof first.media === 'string' && first.media ? JSON.parse(first.media) : first.media || null;
const base = {
  envelope: {
    channel: first.channel || 'generic',
    sender_ref: first.sender_ref || '',
    text,
    media,
    received_at: first.received_at || new Date().toISOString()
  },
  vendor: {
    known: Boolean(first.known_vendor),
    id: first.vendor_id ? Number(first.vendor_id) : null,
    name: first.vendor_name || null,
    trade: first.vendor_trade || null
  },
  duplicate_like: Boolean(first.duplicate_like),
  classification: { status: 'deferred_stage_5', intent: null, confidence: null }
};
const candidates = rows.filter(row => row.turn_id).map(row => {
  let score = 0;
  const reasons = [];
  const unit = String(row.unit_label || '');
  const unitCompact = compact(unit);
  const numericPart = (unitCompact.match(/\\d+/) || [''])[0];
  if (unitCompact && tokenSet.has(unitCompact)) {
    score = 100;
    reasons.push('exact_unit_label');
  } else if (numericPart && tokenSet.has(numericPart)) {
    score = 90;
    reasons.push('unit_token');
  }
  const street = streetToken(row.property_address);
  if (street && tokenSet.has(street) && score < 70) {
    score = 70;
    reasons.push('street_name');
  }
  return {
    turn_id: Number(row.turn_id),
    stage_id: Number(row.stage_id),
    unit_label: row.unit_label,
    property_address: row.property_address,
    stage_code: row.stage_code,
    stage_name: row.stage_name,
    assigned_vendor_id: row.active_vendor_id ? Number(row.active_vendor_id) : null,
    score,
    reasons
  };
});
const hasExplicitHint = candidates.some(candidate => candidate.score >= 70);
if (!hasExplicitHint && base.vendor.known && base.vendor.id) {
  const assigned = candidates.filter(candidate => candidate.assigned_vendor_id === base.vendor.id);
  if (assigned.length === 1 && assigned[0].score < 60) {
    assigned[0].score = 60;
    assigned[0].reasons.push('single_open_stage_for_vendor');
  }
}
const scored = candidates.filter(candidate => candidate.score > 0).sort((a, b) => (b.score - a.score) || a.unit_label.localeCompare(b.unit_label));
const top = scored[0] || null;
const tiedTop = top ? scored.filter(candidate => candidate.score === top.score) : [];
const selected = top && top.score >= 70 && tiedTop.length === 1 ? top : null;
const match = {
  selected,
  score: selected ? selected.score : (top ? top.score : 0),
  needs_manager: !selected,
  candidates: selected ? [selected] : scored.slice(0, 6)
};
return [{ json: { ...base, match } }];`;

const normalizeVendorApiCode = `const headers = $json.headers || {};
const query = $json.query || {};
const body = $json.body || {};
const configuredToken = 'local-stage-4-vendor-in-token';
const suppliedToken = query.token || headers['x-vendor-in-token'] || headers['X-Vendor-In-Token'] || headers['x-demo-token'] || headers['X-Demo-Token'] || body.token || '';
const text = String(body.text || query.text || '').trim();
const senderRef = String(body.sender_ref || query.sender_ref || '').trim();
const mediaType = String(body.media_type || query.media_type || '').trim();
const mediaFileId = String(body.media_file_id || query.media_file_id || '').trim();
let receivedAt = String(body.received_at || query.received_at || new Date().toISOString()).trim();
if (Number.isNaN(new Date(receivedAt).getTime())) receivedAt = new Date().toISOString();
return [{ json: {
  authorized: Boolean(configuredToken) && String(suppliedToken) === String(configuredToken),
  valid: Boolean(senderRef && text),
  error: senderRef ? 'text is required.' : 'sender_ref is required.',
  envelope: {
    channel: 'generic',
    sender_ref: senderRef,
    text,
    media: mediaType ? { type: mediaType, file_id: mediaFileId || null } : null,
    received_at: receivedAt
  },
  cors_origin: 'http://localhost:8080'
} }];`;

const unauthorizedCode = `return [{ json: {
  accepted: false,
  outcome: 'unauthorized',
  error: 'unauthorized',
  message: 'Missing or invalid demo token.',
  cors_origin: 'http://localhost:8080'
} }];`;

const malformedCode = `return [{ json: {
  accepted: false,
  outcome: 'malformed',
  error: $json.error || 'sender_ref and text are required.',
  envelope: $json.envelope || null,
  cors_origin: 'http://localhost:8080'
} }];`;

const unwrapEnvelopeCode = `const envelope = $json.envelope || {};
return [{ json: {
  channel: envelope.channel,
  sender_ref: envelope.sender_ref,
  text: envelope.text,
  media: envelope.media || null,
  received_at: envelope.received_at
} }];`;

const normalizeTelegramCode = `const message = $json.message || $json.edited_message || {};
const from = message.from || {};
const chat = message.chat || {};
const photos = Array.isArray(message.photo) ? message.photo : [];
const photo = photos.length ? photos[photos.length - 1] : null;
const text = String(message.text || message.caption || '').trim();
const senderRef = String(chat.id || from.id || '').trim();
return [{ json: {
  channel: 'telegram',
  sender_ref: senderRef,
  text,
  media: photo ? { type: 'photo', file_id: photo.file_id || null } : null,
  received_at: message.date ? new Date(Number(message.date) * 1000).toISOString() : new Date().toISOString()
} }];`;

const vendorLookupQuery = `WITH input AS (
  SELECT
    '{{ String($json.channel || "generic").replace(/'/g, "''") }}'::text AS channel,
    '{{ String($json.sender_ref || "").replace(/'/g, "''") }}'::text AS sender_ref,
    '{{ String($json.text || "").replace(/'/g, "''") }}'::text AS text,
    '{{ JSON.stringify($json.media || null).replace(/'/g, "''") }}'::jsonb AS media,
    '{{ String($json.received_at || new Date().toISOString()).replace(/'/g, "''") }}'::timestamptz AS received_at
)
SELECT
  input.channel,
  input.sender_ref,
  input.text,
  input.media,
  input.received_at,
  v.id AS vendor_id,
  v.name AS vendor_name,
  v.trade AS vendor_trade,
  (v.id IS NOT NULL) AS known_vendor,
  EXISTS (
    SELECT 1
    FROM event_log e
    WHERE e.actor_type = 'vendor'
      AND e.actor_id = input.sender_ref
      AND e.channel = input.channel
      AND e.raw_text = input.text
      AND e.event_type IN ('vendor_inbound', 'manager_match_needed', 'duplicate_inbound')
      AND e.created_at > now() - interval '60 seconds'
  ) AS duplicate_like
FROM input
LEFT JOIN vendor v
  ON v.active = true
 AND (v.telegram_chat_id = input.sender_ref OR v.phone_e164 = input.sender_ref)
ORDER BY v.id
LIMIT 1;`;

const prepareUnknownCode = `const media = typeof $json.media === 'string' && $json.media ? JSON.parse($json.media) : $json.media || null;
const envelope = {
  channel: $json.channel || 'generic',
  sender_ref: $json.sender_ref || '',
  text: $json.text || '',
  media,
  received_at: $json.received_at || new Date().toISOString()
};
const classification = { status: 'deferred_stage_5', intent: null, confidence: null };
return [{ json: {
  accepted: true,
  outcome: 'unknown_sender',
  event_type: 'unknown_sender',
  envelope,
  vendor: { known: false },
  match: null,
  classification,
  duplicate_like: Boolean($json.duplicate_like),
  needs_manager: true,
  should_notify_manager: true,
  manager_chat_id: 'stage4-manager-chat-id-missing',
  manager_notice_text: 'Unknown vendor message from ' + envelope.sender_ref + ': "' + envelope.text + '"',
  cors_origin: 'http://localhost:8080'
} }];`;

const prepareKnownCode = `const envelope = $json.envelope || {};
const match = $json.match || { needs_manager: true, candidates: [], selected: null, score: 0 };
const mediaOnly = envelope.media && !String(envelope.text || '').trim();
let eventType = 'vendor_inbound';
let outcome = 'matched_logged';
let shouldNotify = false;
if ($json.duplicate_like) {
  eventType = 'duplicate_inbound';
  outcome = 'duplicate_like';
  shouldNotify = true;
} else if (mediaOnly) {
  eventType = 'manager_match_needed';
  outcome = 'media_needs_manager';
  shouldNotify = true;
} else if (match.needs_manager) {
  eventType = 'manager_match_needed';
  outcome = 'manager_match_needed';
  shouldNotify = true;
}
const vendorName = $json.vendor && $json.vendor.name ? $json.vendor.name : 'Known vendor';
const candidateText = (match.candidates || []).map(candidate => candidate.unit_label + ' ' + candidate.stage_name + ' (' + candidate.score + ')').join(', ');
const notice = outcome === 'duplicate_like'
  ? 'Duplicate-like vendor message from ' + vendorName + ': "' + envelope.text + '"'
  : 'Vendor message needs manager match: ' + vendorName + ': "' + envelope.text + '"' + (candidateText ? ' Candidates: ' + candidateText : '');
return [{ json: {
  accepted: true,
  outcome,
  event_type: eventType,
  envelope,
  vendor: $json.vendor,
  match,
  classification: $json.classification || { status: 'deferred_stage_5', intent: null, confidence: null },
  duplicate_like: Boolean($json.duplicate_like),
  needs_manager: Boolean(shouldNotify),
  should_notify_manager: Boolean(shouldNotify),
  manager_chat_id: 'stage4-manager-chat-id-missing',
  manager_notice_text: notice,
  cors_origin: 'http://localhost:8080'
} }];`;

const logRouterEventQuery = `WITH input AS (
  SELECT
    '{{ String($json.event_type || "vendor_inbound").replace(/'/g, "''") }}'::text AS event_type,
    '{{ String($json.outcome || "matched_logged").replace(/'/g, "''") }}'::text AS outcome,
    '{{ JSON.stringify($json.envelope || {}).replace(/'/g, "''") }}'::jsonb AS envelope,
    '{{ JSON.stringify($json.vendor || {}).replace(/'/g, "''") }}'::jsonb AS vendor,
    '{{ JSON.stringify($json.match || null).replace(/'/g, "''") }}'::jsonb AS match,
    '{{ JSON.stringify($json.classification || { status: "deferred_stage_5" }).replace(/'/g, "''") }}'::jsonb AS classification,
    {{ $json.duplicate_like ? 'true' : 'false' }}::boolean AS duplicate_like,
    {{ $json.needs_manager ? 'true' : 'false' }}::boolean AS needs_manager,
    {{ $json.should_notify_manager ? 'true' : 'false' }}::boolean AS should_notify_manager,
    '{{ String($json.manager_chat_id || "").replace(/'/g, "''") }}'::text AS manager_chat_id,
    '{{ String($json.manager_notice_text || "").replace(/'/g, "''") }}'::text AS manager_notice_text,
    '{{ String(($json.envelope || {}).channel || "generic").replace(/'/g, "''") }}'::text AS channel,
    '{{ String(($json.envelope || {}).sender_ref || "").replace(/'/g, "''") }}'::text AS sender_ref,
    '{{ String(($json.envelope || {}).text || "").replace(/'/g, "''") }}'::text AS raw_text,
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
    jsonb_build_object(
      'envelope', envelope,
      'vendor', vendor,
      'match', match,
      'classification', classification,
      'duplicate_like', duplicate_like,
      'needs_manager', needs_manager,
      'stage_state_mutated', false
    )
  FROM input
  RETURNING id
)
SELECT
  true AS accepted,
  inserted.id AS event_id,
  input.outcome,
  input.event_type,
  input.envelope,
  input.vendor,
  input.match,
  input.classification,
  input.duplicate_like,
  input.needs_manager,
  (input.should_notify_manager AND input.manager_chat_id <> '' AND input.manager_chat_id <> 'stage4-manager-chat-id-missing') AS should_notify_manager,
  NULLIF(input.manager_chat_id, 'stage4-manager-chat-id-missing') AS manager_chat_id,
  input.manager_notice_text,
  false AS stage_state_mutated,
  'http://localhost:8080'::text AS cors_origin
FROM input
CROSS JOIN inserted;`;

const returnAfterNoticeCode = `const source = $('Log Vendor Router Event').first().json;
return [{ json: source }];`;

const workflowFiles = [];

workflowFiles.push([
  "wf-4-turn-intake.json",
  wf(
    "wf4-turn-intake",
    "WF-4 Turn Intake",
    [
      {
        id: "turn-intake-form",
        name: "Turn Intake Form",
        type: "n8n-nodes-base.formTrigger",
        typeVersion: 2.5,
        position: [0, 0],
        webhookId: "wf4-turn-intake",
        parameters: {
          authentication: "none",
          path: "turn-intake",
          formTitle: "Make-ready turn intake",
          formDescription: "Add a turn to the local demo board.",
          formFields: { values: formFields },
          responseMode: "onReceived",
          options: {
            path: "turn-intake",
            buttonLabel: "Add turn",
            appendAttribution: false,
            useWorkflowTimezone: true,
            respondWithOptions: {
              values: {
                respondWith: "text",
                formSubmittedText: "Turn added to board.",
              },
            },
          },
        },
      },
      codeNode("normalize-intake-submission", "Normalize Intake Submission", 280, 0, normalizeIntakeCode),
      pgNode("insert-intake-turn-and-stages", "Insert Intake Turn And Stages", 560, 0, intakeInsertQuery),
      codeNode("format-intake-result", "Format Intake Result", 840, 0, formatIntakeCode),
    ],
    {
      "Turn Intake Form": {
        main: [[{ node: "Normalize Intake Submission", type: "main", index: 0 }]],
      },
      "Normalize Intake Submission": {
        main: [[{ node: "Insert Intake Turn And Stages", type: "main", index: 0 }]],
      },
      "Insert Intake Turn And Stages": {
        main: [[{ node: "Format Intake Result", type: "main", index: 0 }]],
      },
    },
    false,
  ),
]);

workflowFiles.push([
  "wf-4-unit-matcher.json",
  wf(
    "wf4-unit-matcher",
    "WF-4 Unit Matcher",
    [
      {
        id: "trigger",
        name: "Receive Match Request",
        type: "n8n-nodes-base.executeWorkflowTrigger",
        typeVersion: 1.2,
        position: [0, 0],
        parameters: { inputSource: "passthrough" },
      },
      pgNode("load-active-match-candidates", "Load Active Match Candidates", 280, 0, matcherLoadQuery),
      codeNode("score-unit-candidates", "Score Unit Candidates", 560, 0, matcherCode),
    ],
    {
      "Receive Match Request": {
        main: [[{ node: "Load Active Match Candidates", type: "main", index: 0 }]],
      },
      "Load Active Match Candidates": {
        main: [[{ node: "Score Unit Candidates", type: "main", index: 0 }]],
      },
    },
    false,
  ),
]);

workflowFiles.push([
  "wf-4-vendor-router.json",
  wf(
    "wf4-vendor-router",
    "WF-4 Vendor Router",
    [
      {
        id: "trigger",
        name: "Receive Vendor Envelope",
        type: "n8n-nodes-base.executeWorkflowTrigger",
        typeVersion: 1.2,
        position: [0, 0],
        parameters: { inputSource: "passthrough" },
      },
      pgNode("load-vendor-context", "Load Vendor Context", 280, 0, vendorLookupQuery),
      ifNode("known-vendor", "Known Vendor?", 560, 0, "={{ $json.known_vendor }}"),
      executeNode("call-unit-matcher", "Call Unit Matcher", 840, -140, "wf4-unit-matcher"),
      codeNode("prepare-known-event", "Prepare Known Event", 1120, -140, prepareKnownCode),
      codeNode("prepare-unknown-event", "Prepare Unknown Event", 840, 140, prepareUnknownCode),
      pgNode("log-vendor-router-event", "Log Vendor Router Event", 1400, 0, logRouterEventQuery),
      ifNode("notify-manager", "Notify Manager?", 1680, 0, "={{ $json.should_notify_manager }}"),
      telegramSendNode("send-manager-notice", "Send Manager Notice", 1960, -120, "={{ $json.manager_notice_text }}"),
      codeNode("return-after-manager-notice", "Return After Manager Notice", 2240, -120, returnAfterNoticeCode),
      codeNode("return-router-result", "Return Router Result", 1960, 120, "return items;"),
    ],
    {
      "Receive Vendor Envelope": {
        main: [[{ node: "Load Vendor Context", type: "main", index: 0 }]],
      },
      "Load Vendor Context": {
        main: [[{ node: "Known Vendor?", type: "main", index: 0 }]],
      },
      "Known Vendor?": {
        main: [
          [{ node: "Call Unit Matcher", type: "main", index: 0 }],
          [{ node: "Prepare Unknown Event", type: "main", index: 0 }],
        ],
      },
      "Call Unit Matcher": {
        main: [[{ node: "Prepare Known Event", type: "main", index: 0 }]],
      },
      "Prepare Known Event": {
        main: [[{ node: "Log Vendor Router Event", type: "main", index: 0 }]],
      },
      "Prepare Unknown Event": {
        main: [[{ node: "Log Vendor Router Event", type: "main", index: 0 }]],
      },
      "Log Vendor Router Event": {
        main: [[{ node: "Notify Manager?", type: "main", index: 0 }]],
      },
      "Notify Manager?": {
        main: [
          [{ node: "Send Manager Notice", type: "main", index: 0 }],
          [{ node: "Return Router Result", type: "main", index: 0 }],
        ],
      },
      "Send Manager Notice": {
        main: [[{ node: "Return After Manager Notice", type: "main", index: 0 }]],
      },
    },
    false,
  ),
]);

workflowFiles.push([
  "wf-4-vendor-in-api.json",
  wf(
    "wf4-vendor-in-api",
    "WF-4 Vendor In API",
    [
      {
        id: "vendor-in-webhook",
        name: "POST Vendor In Webhook",
        type: "n8n-nodes-base.webhook",
        typeVersion: 2.1,
        position: [0, 0],
        webhookId: "wf4-vendor-in-api",
        parameters: {
          httpMethod: "POST",
          path: "vendor-in",
          authentication: "none",
          responseMode: "responseNode",
          options: { allowedOrigins: "http://localhost:8080" },
        },
      },
      codeNode("normalize-vendor-in-request", "Normalize Vendor In Request", 280, 0, normalizeVendorApiCode),
      ifNode("vendor-in-authorized", "Vendor In Authorized?", 560, 0, "={{ $json.authorized }}"),
      ifNode("vendor-in-valid", "Vendor In Valid?", 840, -140, "={{ $json.valid }}"),
      codeNode("unwrap-vendor-envelope", "Unwrap Vendor Envelope", 1120, -260, unwrapEnvelopeCode),
      executeNode("call-vendor-router", "Call Vendor Router", 1400, -260, "wf4-vendor-router"),
      respondNode("respond-vendor-in-ok", "Respond Vendor In 200", 1680, -260, 200),
      codeNode("format-vendor-in-malformed", "Format Vendor In Malformed", 1120, -20, malformedCode),
      respondNode("respond-vendor-in-400", "Respond Vendor In 400", 1400, -20, 400),
      codeNode("format-vendor-in-unauthorized", "Format Vendor In Unauthorized", 840, 160, unauthorizedCode),
      respondNode("respond-vendor-in-401", "Respond Vendor In 401", 1120, 160, 401),
    ],
    {
      "POST Vendor In Webhook": {
        main: [[{ node: "Normalize Vendor In Request", type: "main", index: 0 }]],
      },
      "Normalize Vendor In Request": {
        main: [[{ node: "Vendor In Authorized?", type: "main", index: 0 }]],
      },
      "Vendor In Authorized?": {
        main: [
          [{ node: "Vendor In Valid?", type: "main", index: 0 }],
          [{ node: "Format Vendor In Unauthorized", type: "main", index: 0 }],
        ],
      },
      "Vendor In Valid?": {
        main: [
          [{ node: "Unwrap Vendor Envelope", type: "main", index: 0 }],
          [{ node: "Format Vendor In Malformed", type: "main", index: 0 }],
        ],
      },
      "Unwrap Vendor Envelope": {
        main: [[{ node: "Call Vendor Router", type: "main", index: 0 }]],
      },
      "Call Vendor Router": {
        main: [[{ node: "Respond Vendor In 200", type: "main", index: 0 }]],
      },
      "Format Vendor In Malformed": {
        main: [[{ node: "Respond Vendor In 400", type: "main", index: 0 }]],
      },
      "Format Vendor In Unauthorized": {
        main: [[{ node: "Respond Vendor In 401", type: "main", index: 0 }]],
      },
    },
    false,
  ),
]);

workflowFiles.push([
  "wf-4-vendor-telegram-ingest.json",
  wf(
    "wf4-vendor-telegram-ingest",
    "WF-4 Vendor Telegram Ingest",
    [
      {
        id: "vendor-telegram-trigger",
        name: "VendorTelegramTrigger",
        type: "n8n-nodes-base.telegramTrigger",
        typeVersion: 1.3,
        position: [0, 0],
        parameters: { updates: ["message"], additionalFields: {} },
        credentials: { telegramApi: vendorTgCred },
      },
      codeNode("normalize-vendor-telegram-message", "Normalize Vendor Telegram Message", 280, 0, normalizeTelegramCode),
      executeNode("call-vendor-router-from-telegram", "Call Vendor Router From Telegram", 560, 0, "wf4-vendor-router"),
    ],
    {
      VendorTelegramTrigger: {
        main: [[{ node: "Normalize Vendor Telegram Message", type: "main", index: 0 }]],
      },
      "Normalize Vendor Telegram Message": {
        main: [[{ node: "Call Vendor Router From Telegram", type: "main", index: 0 }]],
      },
    },
    false,
  ),
]);

for (const [file, data] of workflowFiles) {
  fs.writeFileSync(path.join(outDir, file), JSON.stringify(data, null, 2) + "\n", "utf8");
}
