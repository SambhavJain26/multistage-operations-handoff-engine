const fs = require("fs");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const outDir = path.join(repoRoot, "n8n-workflows");
fs.mkdirSync(outDir, { recursive: true });

const pgCred = { id: "cred_make_ready_pg", name: "Make-Ready Postgres" };
const managerTgCred = { id: "jASZWMlrfp3v2tWH", name: "Make-Ready Manager Telegram Bot" };
const openAiCred = { id: "cred_make_ready_openai", name: "Make-Ready OpenAI" };

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
    parameters: {
      source: "database",
      workflowId,
      options: { waitForSubWorkflow: true },
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
          {
            row: {
              buttons: [
                {
                  text: "Send",
                  additionalFields: { callback_data: "={{ 'SEND:' + $json.queue_id }}" },
                },
              ],
            },
          },
          {
            row: {
              buttons: [
                {
                  text: "Edit",
                  additionalFields: { callback_data: "={{ 'EDIT:' + $json.queue_id }}" },
                },
              ],
            },
          },
          {
            row: {
              buttons: [
                {
                  text: "Hold",
                  additionalFields: { callback_data: "={{ 'HOLD:' + $json.queue_id }}" },
                },
              ],
            },
          },
        ],
      },
      additionalFields: { disable_web_page_preview: true, appendAttribution: false },
    },
    credentials: { telegramApi: managerTgCred },
  };
}

function httpOpenAiNode(id, name, x, y) {
  return {
    id,
    name,
    type: "n8n-nodes-base.httpRequest",
    typeVersion: 4.2,
    position: [x, y],
    parameters: {
      method: "POST",
      url: "https://api.openai.com/v1/responses",
      authentication: "predefinedCredentialType",
      nodeCredentialType: "openAiApi",
      sendBody: true,
      specifyBody: "json",
      jsonBody: "={{ JSON.stringify($json.openai_request) }}",
      options: { timeout: 12000 },
    },
    credentials: { openAiApi: openAiCred },
    continueOnFail: true,
  };
}

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
      AND e.event_type IN ('vendor_inbound', 'manager_match_needed', 'duplicate_inbound', 'stage_complete')
      AND e.created_at > now() - interval '60 seconds'
  ) AS duplicate_like
FROM input
LEFT JOIN vendor v
  ON v.active = true
 AND (v.telegram_chat_id = input.sender_ref OR v.phone_e164 = input.sender_ref)
ORDER BY v.id
LIMIT 1;`;

const prepareUnknownCode = `const media = typeof $json.media === 'string' && $json.media ? JSON.parse($json.media) : $json.media || null;
const envelope = { channel: $json.channel || 'generic', sender_ref: $json.sender_ref || '', text: $json.text || '', media, received_at: $json.received_at || new Date().toISOString() };
return [{ json: {
  accepted: true,
  outcome: 'unknown_sender',
  event_type: 'unknown_sender',
  envelope,
  vendor: { known: false },
  match: null,
  classification: { status: 'not_run_unknown_sender', intent: null, confidence: null },
  duplicate_like: Boolean($json.duplicate_like),
  needs_manager: true,
  should_notify_manager: true,
  manager_chat_id: 'stage5-manager-chat-id-missing',
  manager_notice_text: 'Unknown vendor message from ' + envelope.sender_ref + ': "' + envelope.text + '"',
  cors_origin: 'http://localhost:8080'
} }];`;

const buildClassifierCode = `const media = typeof $json.media === 'string' && $json.media ? JSON.parse($json.media) : $json.media || null;
const text = String($json.text || '');
const openStages = {
  vendor_id: $json.vendor_id ? Number($json.vendor_id) : null,
  vendor_name: $json.vendor_name || null,
  vendor_trade: $json.vendor_trade || null
};
const schema = {
  type: 'object',
  additionalProperties: false,
  required: ['intent', 'unit_hint', 'stage_hint', 'eta_text', 'confidence'],
  properties: {
    intent: { type: 'string', enum: ['stage_complete', 'stage_started', 'delay_notice', 'question', 'not_my_unit', 'unclear'] },
    unit_hint: { type: ['string', 'null'] },
    stage_hint: { type: ['string', 'null'] },
    eta_text: { type: ['string', 'null'] },
    confidence: { type: 'number' }
  }
};
return [{ json: {
  channel: $json.channel || 'generic',
  sender_ref: $json.sender_ref || '',
  text,
  media,
  received_at: $json.received_at || new Date().toISOString(),
  vendor_id: openStages.vendor_id,
  vendor_name: openStages.vendor_name,
  vendor_trade: openStages.vendor_trade,
  known_vendor: Boolean($json.known_vendor),
  duplicate_like: Boolean($json.duplicate_like),
  openai_request: {
    model: 'gpt-5.6-luna',
    temperature: 0,
    max_output_tokens: 150,
    input: [
      { role: 'system', content: 'You classify short text messages sent by trade contractors about vacant rental unit work. Return only the strict JSON object. Never assess damage, tenant responsibility, deposits, wear and tear, or cost; if raised, intent is question.' },
      { role: 'user', content: 'Vendor text: ' + text + '\\\\nVendor trade: ' + ($json.vendor_trade || '') }
    ],
    text: { format: { type: 'json_schema', name: 'vendor_reply', schema, strict: true } }
  }
} }];`;

const parseClassifierCode = `const source = $('Build OpenAI Classification Request').first().json;
const raw = $json || {};
function deterministic(text) {
  const lower = String(text || '').toLowerCase();
  if (/deposit|tenant charge|tenant\\s+trashing|wear and tear|wear\\s+and\\s+tear/.test(lower)) {
    return { intent: 'question', unit_hint: null, stage_hint: null, eta_text: null, confidence: 0.9 };
  }
  if (/\\?|water|lockbox|access|gate|key|code/.test(lower)) {
    return { intent: 'question', unit_hint: null, stage_hint: null, eta_text: null, confidence: 0.78 };
  }
  if (/can't|cant|cannot|won't|wont|late|thursday|tomorrow|delay|need one more|not until/.test(lower)) {
    return { intent: 'delay_notice', unit_hint: null, stage_hint: null, eta_text: String(text || ''), confidence: 0.76 };
  }
  if (/wrong unit|not my|not ours|not mine/.test(lower)) {
    return { intent: 'not_my_unit', unit_hint: null, stage_hint: null, eta_text: null, confidence: 0.82 };
  }
  if (/started|on the way|materials arrived|patched|working on/.test(lower)) {
    return { intent: 'stage_started', unit_hint: null, stage_hint: null, eta_text: null, confidence: 0.72 };
  }
  if (/done|finished|finishd|finshed|complete|completed|all set|cleaned|painted/.test(lower)) {
    return { intent: 'stage_complete', unit_hint: null, stage_hint: null, eta_text: null, confidence: 0.84 };
  }
  return { intent: 'unclear', unit_hint: null, stage_hint: null, eta_text: null, confidence: 0.35 };
}
let parsed = null;
try {
  const text = raw.output_text || (Array.isArray(raw.output) && raw.output[0] && raw.output[0].content && raw.output[0].content[0] && raw.output[0].content[0].text);
  if (text) parsed = JSON.parse(text);
} catch (error) {
  parsed = null;
}
const fallback = deterministic(source.text);
const classification = parsed && parsed.intent
  ? { status: 'openai', model: 'gpt-5.6-luna', ...parsed }
  : { status: 'fallback_deterministic', model: 'gpt-5.6-luna', ...fallback };
return [{ json: {
  channel: source.channel,
  sender_ref: source.sender_ref,
  text: source.text,
  media: source.media,
  received_at: source.received_at,
  vendor_id: source.vendor_id,
  vendor_name: source.vendor_name,
  vendor_trade: source.vendor_trade,
  known_vendor: source.known_vendor,
  duplicate_like: source.duplicate_like,
  classification
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
const mediaOnly = envelope.media && !String(envelope.text || '').trim();
let eventType = 'vendor_inbound';
let outcome = 'logged_no_action';
let shouldNotify = false;
let shouldComplete = false;
if ($json.duplicate_like) {
  eventType = 'duplicate_inbound';
  outcome = 'duplicate_like';
  shouldNotify = true;
} else if (mediaOnly) {
  eventType = 'manager_match_needed';
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
const notice = outcome === 'duplicate_like'
  ? 'Duplicate-like vendor message from ' + (vendor.name || 'Known vendor') + ': "' + envelope.text + '"'
  : 'Vendor message needs manager review: ' + (vendor.name || 'Known vendor') + ': "' + envelope.text + '"' + (candidateText ? ' Candidates: ' + candidateText : '');
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
      completed_by = input.actor_id
  FROM input, requested
  WHERE ts.id = requested.id
    AND ts.status = 'active'
  RETURNING ts.id, ts.turn_id, ts.seq, ts.stage_code, ts.stage_name, ts.completed_at
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
  INSERT INTO outbound_queue (
    turn_id,
    stage_id,
    source_stage_id,
    vendor_id,
    channel,
    draft_text,
    approved_text,
    deterministic_text,
    status,
    draft_model,
    draft_fallback_used,
    approval_context
  )
  SELECT
    ds.turn_id,
    ds.stage_id,
    (SELECT id FROM mark_complete LIMIT 1),
    ds.vendor_id,
    'telegram',
    left(ds.deterministic_text, 320),
    left(ds.deterministic_text, 320),
    left(ds.deterministic_text, 320),
    'awaiting_approval',
    'gpt-5.6-luna',
    true,
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
  SELECT
    mc.turn_id,
    mc.id,
    'vendor',
    input.actor_id,
    input.channel,
    'stage_complete',
    input.raw_text,
    jsonb_build_object('classification', input.classification, 'match', input.match, 'stage_state_mutated', true)
  FROM mark_complete mc
  CROSS JOIN input
  RETURNING id
), write_draft AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT
    ds.turn_id,
    ds.stage_id,
    'system',
    'stage-5',
    'system',
    'msg_drafted',
    ds.deterministic_text,
    jsonb_build_object('queue_id', iq.id, 'source_stage_id', (SELECT id FROM mark_complete LIMIT 1), 'draft_fallback_used', true)
  FROM draft_source ds
  JOIN inserted_queue iq ON iq.stage_id = ds.stage_id
  RETURNING id
), write_await AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT
    av.turn_id,
    av.id,
    'system',
    'stage-5',
    'system',
    'stage_awaiting_approval',
    'next stage awaiting manager approval',
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
  'http://localhost:8080'::text AS cors_origin
FROM requested;`;

const blockLogQuery = `WITH input AS (
  SELECT
    {{ Number($json.stage_id || 0) }}::int AS stage_id,
    {{ Number($json.turn_id || 0) }}::int AS turn_id,
    '{{ String($json.actor_id || "vendor").replace(/'/g, "''") }}'::text AS actor_id,
    '{{ String($json.channel || "generic").replace(/'/g, "''") }}'::text AS channel,
    '{{ String($json.reason || "Sequence guard blocked the completion.").replace(/'/g, "''") }}'::text AS reason,
    '{{ JSON.stringify($json.blocked_by || []).replace(/'/g, "''") }}'::jsonb AS blocked_by,
    '{{ String($json.override_token || "").replace(/'/g, "''") }}'::text AS override_token
), inserted AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT NULLIF(turn_id, 0), NULLIF(stage_id, 0), 'vendor', actor_id, channel, 'guard_blocked', reason,
    jsonb_build_object('blocked_by', blocked_by, 'override_token', override_token)
  FROM input
  RETURNING id
)
SELECT
  true AS accepted,
  'guard_blocked'::text AS outcome,
  false AS stage_state_mutated,
  input.reason,
  input.override_token,
  inserted.id AS event_id,
  'http://localhost:8080'::text AS cors_origin
FROM input
CROSS JOIN inserted;`;

const normalizeCompletionCandidateCode = `const selected = $json.match && $json.match.selected ? $json.match.selected : {};
const envelope = $json.envelope || {};
return [{ json: {
  ...$json,
  stage_id: Number(selected.stage_id || $json.stage_id || 0),
  actor_id: String(envelope.sender_ref || $json.actor_id || 'vendor'),
  channel: String(envelope.channel || $json.channel || 'generic')
} }];`;

const formatCompletionNotificationCode = `const q = typeof $json.outbound_queue === 'string' && $json.outbound_queue ? JSON.parse($json.outbound_queue) : $json.outbound_queue;
const next = typeof $json.next_stage === 'string' && $json.next_stage ? JSON.parse($json.next_stage) : $json.next_stage;
const queueId = q && q.id ? Number(q.id) : 0;
const draft = q && (q.approved_text || q.draft_text) ? (q.approved_text || q.draft_text) : '';
const approvalText = queueId
  ? $json.unit_label + ' - ' + $json.completed_stage_name + ' completed by vendor.\\nNext: ' + (next ? next.stage_name : 'None') + '.\\n\\nDraft to approve:\\n' + draft + '\\n\\nNothing has gone out yet.'
  : $json.unit_label + ' - ' + $json.completed_stage_name + ' completed by vendor.';
const managerChatId = 'stage5-manager-chat-id-missing';
return [{ json: {
  ...$json,
  outbound_queue: q || null,
  next_stage: next || null,
  queue_id: queueId,
  manager_chat_id: managerChatId,
  should_send_manager_approval: queueId > 0 && managerChatId !== '' && !managerChatId.includes('missing'),
  manager_approval_text: approvalText
} }];`;

const managerActionQuery = `WITH input AS (
  SELECT
    upper('{{ String($json.action || "").replace(/'/g, "''") }}')::text AS action,
    {{ Number($json.queue_id || 0) }}::int AS queue_id,
    {{ Number($json.stage_id || 0) }}::int AS stage_id,
    {{ Number($json.turn_id || 0) }}::int AS turn_id,
    '{{ String($json.actor_id || "manager").replace(/'/g, "''") }}'::text AS actor_id,
    '{{ String($json.channel || "board").replace(/'/g, "''") }}'::text AS channel,
    '{{ String($json.edited_text || "").replace(/'/g, "''") }}'::text AS edited_text
), queue_row AS (
  SELECT oq.*, v.name AS vendor_name, v.telegram_chat_id, v.phone_e164
  FROM outbound_queue oq
  LEFT JOIN vendor v ON v.id = oq.vendor_id
  JOIN input i ON i.queue_id = oq.id
  FOR UPDATE OF oq
), mark_sent AS (
  UPDATE outbound_queue oq
  SET status = 'sent',
      approved_text = COALESCE(NULLIF(input.edited_text, ''), oq.approved_text, oq.draft_text),
      decision_by = input.actor_id,
      decided_at = now(),
      sent_at = now(),
      sent_to_sender_ref = COALESCE(queue_row.telegram_chat_id, queue_row.phone_e164)
  FROM input, queue_row
  WHERE input.action = 'SEND'
    AND oq.id = queue_row.id
    AND oq.status = 'awaiting_approval'
  RETURNING oq.*
), activate_sent_stage AS (
  UPDATE turn_stage ts
  SET status = 'active',
      activated_at = now()
  FROM mark_sent ms
  WHERE ts.id = ms.stage_id
    AND ts.status = 'awaiting_approval'
  RETURNING ts.id, ts.turn_id, ts.stage_code, ts.stage_name
), mark_hold AS (
  UPDATE outbound_queue oq
  SET status = 'held',
      decision_by = input.actor_id,
      decided_at = now()
  FROM input, queue_row
  WHERE input.action = 'HOLD'
    AND oq.id = queue_row.id
    AND oq.status IN ('awaiting_approval', 'editing')
  RETURNING oq.*
), mark_edit AS (
  UPDATE outbound_queue oq
  SET status = CASE WHEN input.edited_text <> '' THEN 'awaiting_approval' ELSE 'editing' END,
      draft_text = CASE WHEN input.edited_text <> '' THEN input.edited_text ELSE oq.draft_text END,
      approved_text = CASE WHEN input.edited_text <> '' THEN input.edited_text ELSE oq.approved_text END,
      edit_prompted_at = now(),
      decision_by = input.actor_id
  FROM input, queue_row
  WHERE input.action = 'EDIT'
    AND oq.id = queue_row.id
    AND oq.status IN ('awaiting_approval', 'editing')
  RETURNING oq.*
), skip_stage AS (
  UPDATE turn_stage ts
  SET status = 'skipped',
      completed_at = now(),
      completed_via = 'skip',
      completed_by = input.actor_id
  FROM input
  WHERE input.action = 'SKIP'
    AND ts.id = input.stage_id
    AND ts.status IN ('pending', 'active', 'awaiting_approval', 'blocked')
  RETURNING ts.id, ts.turn_id, ts.stage_code, ts.stage_name
), snooze_stage AS (
  UPDATE turn_stage ts
  SET snooze_until = now() + interval '24 hours'
  FROM input
  WHERE input.action = 'SNOOZE'
    AND ts.id = input.stage_id
  RETURNING ts.id, ts.turn_id, ts.stage_code, ts.stage_name, ts.snooze_until
), cancel_turn AS (
  UPDATE "turn" t
  SET status = 'cancelled'
  FROM input
  WHERE input.action = 'CANCEL'
    AND t.id = input.turn_id
    AND t.status = 'active'
  RETURNING t.id, t.unit_label
), cancel_stages AS (
  UPDATE turn_stage ts
  SET status = 'cancelled'
  FROM cancel_turn ct
  WHERE ts.turn_id = ct.id
    AND ts.status IN ('pending', 'active', 'awaiting_approval', 'blocked')
  RETURNING ts.id
), cancel_queues AS (
  UPDATE outbound_queue oq
  SET status = 'cancelled',
      decision_by = (SELECT actor_id FROM input),
      decided_at = now()
  FROM cancel_turn ct
  WHERE oq.turn_id = ct.id
    AND oq.status IN ('awaiting_approval', 'editing')
  RETURNING oq.id
), action_event AS (
  INSERT INTO event_log (turn_id, stage_id, actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT
    COALESCE((SELECT turn_id FROM activate_sent_stage LIMIT 1), (SELECT turn_id FROM skip_stage LIMIT 1), (SELECT turn_id FROM snooze_stage LIMIT 1), (SELECT id FROM cancel_turn LIMIT 1), (SELECT turn_id FROM queue_row LIMIT 1)),
    COALESCE((SELECT id FROM activate_sent_stage LIMIT 1), (SELECT id FROM skip_stage LIMIT 1), (SELECT id FROM snooze_stage LIMIT 1), (SELECT stage_id FROM queue_row LIMIT 1)),
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
      ELSE 'msg_rejected'
    END,
    input.action,
    jsonb_build_object('queue_id', input.queue_id, 'stage_id', input.stage_id, 'turn_id', input.turn_id, 'edited', input.edited_text <> '')
  FROM input
  WHERE input.action IN ('SEND', 'HOLD', 'EDIT', 'SKIP', 'SNOOZE', 'CANCEL')
  RETURNING id
)
SELECT
  input.action,
  input.queue_id,
  input.stage_id,
  input.turn_id,
  CASE
    WHEN (SELECT count(*) FROM mark_sent) > 0 THEN 'sent'
    WHEN (SELECT count(*) FROM mark_hold) > 0 THEN 'held'
    WHEN (SELECT count(*) FROM mark_edit) > 0 AND input.edited_text = '' THEN 'editing'
    WHEN (SELECT count(*) FROM mark_edit) > 0 THEN 'awaiting_approval'
    WHEN (SELECT count(*) FROM skip_stage) > 0 THEN 'skipped'
    WHEN (SELECT count(*) FROM snooze_stage) > 0 THEN 'snoozed'
    WHEN (SELECT count(*) FROM cancel_turn) > 0 THEN 'cancelled'
    ELSE 'no_change'
  END AS outcome,
  (SELECT approved_text FROM mark_sent LIMIT 1) AS approved_text,
  (SELECT sent_to_sender_ref FROM mark_sent LIMIT 1) AS sent_to_sender_ref,
  (SELECT row_to_json(activate_sent_stage) FROM activate_sent_stage LIMIT 1) AS activated_stage,
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
  cors_origin: 'http://localhost:8080'
} }];`;

const unauthorizedCode = `return [{ json: { accepted: false, outcome: 'unauthorized', error: 'unauthorized', cors_origin: 'http://localhost:8080' } }];`;

const parseManagerCallbackCode = `const callback = $json.callback_query;
if (!callback) return [{ json: { handled: false, action: 'ignored', reason: 'No callback query.' } }];
const data = String(callback.data || '');
const chatId = callback.message && callback.message.chat ? callback.message.chat.id : '';
const fromId = callback.from ? callback.from.id : 'manager-telegram';
const parts = data.split(':');
const action = parts[0] || 'NOOP';
if (action === 'DONE') {
  return [{ json: { handled: true, route: 'complete', action: 'DONE', stage_id: Number(parts[1] || 0), actor_id: String(fromId), channel: 'digest', telegram_callback_query_id: callback.id, telegram_chat_id: chatId } }];
}
if (['SEND', 'HOLD', 'EDIT'].includes(action)) {
  return [{ json: { handled: true, route: 'action', action, queue_id: Number(parts[1] || 0), actor_id: String(fromId), channel: 'telegram', telegram_callback_query_id: callback.id, telegram_chat_id: chatId } }];
}
if (['SKIP', 'SNOOZE'].includes(action)) {
  return [{ json: { handled: true, route: 'action', action, stage_id: Number(parts[1] || 0), actor_id: String(fromId), channel: 'telegram', telegram_callback_query_id: callback.id, telegram_chat_id: chatId } }];
}
if (action === 'CANCEL') {
  return [{ json: { handled: true, route: 'action', action, turn_id: Number(parts[1] || 0), actor_id: String(fromId), channel: 'telegram', telegram_callback_query_id: callback.id, telegram_chat_id: chatId } }];
}
return [{ json: { handled: false, action: 'noop', telegram_callback_query_id: callback.id, telegram_chat_id: chatId, reason: 'No action taken.' } }];`;

const routeDoneCode = `return [{ json: { route_done: $json.route === 'complete', ...$json } }];`;
const routeActionCode = `return [{ json: { route_action: $json.route === 'action', ...$json } }];`;

const workflowFiles = [];

workflowFiles.push([
  "wf-5-vendor-completion-handler.json",
  wf(
    "wf5-vendor-completion-handler",
    "WF-5 Vendor Completion Handler",
    [
      { id: "trigger", name: "Receive Completion Candidate", type: "n8n-nodes-base.executeWorkflowTrigger", typeVersion: 1.2, position: [0, 0], parameters: { inputSource: "passthrough" } },
      codeNode("normalize-completion-candidate", "Normalize Completion Candidate", 260, 0, normalizeCompletionCandidateCode),
      executeNode("call-sequence-guard", "Call Sequence Guard", 520, 0, "wf3-sequence-guard"),
      ifNode("guard-passed", "Guard Passed?", 780, 0, "={{ $json.allowed }}"),
      pgNode("complete-and-queue-next", "Complete Stage And Queue Next", 1040, -120, completionQuery),
      codeNode("format-completion-notification", "Format Completion Notification", 1300, -120, formatCompletionNotificationCode),
      ifNode("send-manager-approval", "Send Manager Approval?", 1560, -120, "={{ $json.should_send_manager_approval }}"),
      telegramApprovalNode("send-manager-approval-card", "Send Manager Approval Card", 1820, -240),
      codeNode("return-after-approval-card", "Return After Approval Card", 2080, -240, "return [$('Format Completion Notification').first()];"),
      codeNode("return-completion-without-approval-card", "Return Completion Without Approval Card", 1820, 0, "return items;"),
      pgNode("log-vendor-guard-block", "Log Vendor Guard Block", 1040, 120, blockLogQuery),
    ],
    {
      "Receive Completion Candidate": { main: [[{ node: "Normalize Completion Candidate", type: "main", index: 0 }]] },
      "Normalize Completion Candidate": { main: [[{ node: "Call Sequence Guard", type: "main", index: 0 }]] },
      "Call Sequence Guard": { main: [[{ node: "Guard Passed?", type: "main", index: 0 }]] },
      "Guard Passed?": {
        main: [
          [{ node: "Complete Stage And Queue Next", type: "main", index: 0 }],
          [{ node: "Log Vendor Guard Block", type: "main", index: 0 }],
        ],
      },
      "Complete Stage And Queue Next": { main: [[{ node: "Format Completion Notification", type: "main", index: 0 }]] },
      "Format Completion Notification": { main: [[{ node: "Send Manager Approval?", type: "main", index: 0 }]] },
      "Send Manager Approval?": {
        main: [
          [{ node: "Send Manager Approval Card", type: "main", index: 0 }],
          [{ node: "Return Completion Without Approval Card", type: "main", index: 0 }],
        ],
      },
      "Send Manager Approval Card": { main: [[{ node: "Return After Approval Card", type: "main", index: 0 }]] },
    },
    false,
  ),
]);

workflowFiles.push([
  "wf-5-manager-action-core.json",
  wf(
    "wf5-manager-action-core",
    "WF-5 Manager Action Core",
    [
      { id: "trigger", name: "Receive Manager Action", type: "n8n-nodes-base.executeWorkflowTrigger", typeVersion: 1.2, position: [0, 0], parameters: { inputSource: "passthrough" } },
      pgNode("apply-manager-action", "Apply Manager Action", 280, 0, managerActionQuery),
    ],
    { "Receive Manager Action": { main: [[{ node: "Apply Manager Action", type: "main", index: 0 }]] } },
    false,
  ),
]);

workflowFiles.push([
  "wf-5-manager-action-api.json",
  wf(
    "wf5-manager-action-api",
    "WF-5 Manager Action API",
    [
      { id: "webhook-manager-action", name: "POST Manager Action Webhook", type: "n8n-nodes-base.webhook", typeVersion: 2.1, position: [0, 0], webhookId: "wf5-manager-action-api", parameters: { httpMethod: "POST", path: "manager-action", authentication: "none", responseMode: "responseNode", options: { allowedOrigins: "http://localhost:8080" } } },
      codeNode("normalize-manager-action", "Normalize Manager Action", 280, 0, normalizeManagerActionCode),
      ifNode("manager-action-authorized", "Manager Action Authorized?", 560, 0, "={{ $json.authorized }}"),
      executeNode("call-manager-action-core", "Call Manager Action Core", 840, -120, "wf5-manager-action-core"),
      respondNode("respond-manager-action-ok", "Respond Manager Action 200", 1120, -120, 200),
      codeNode("format-manager-action-unauthorized", "Format Manager Action Unauthorized", 840, 120, unauthorizedCode),
      respondNode("respond-manager-action-unauthorized", "Respond Manager Action 401", 1120, 120, 401),
    ],
    {
      "POST Manager Action Webhook": { main: [[{ node: "Normalize Manager Action", type: "main", index: 0 }]] },
      "Normalize Manager Action": { main: [[{ node: "Manager Action Authorized?", type: "main", index: 0 }]] },
      "Manager Action Authorized?": {
        main: [
          [{ node: "Call Manager Action Core", type: "main", index: 0 }],
          [{ node: "Format Manager Action Unauthorized", type: "main", index: 0 }],
        ],
      },
      "Call Manager Action Core": { main: [[{ node: "Respond Manager Action 200", type: "main", index: 0 }]] },
      "Format Manager Action Unauthorized": { main: [[{ node: "Respond Manager Action 401", type: "main", index: 0 }]] },
    },
    true,
  ),
]);

workflowFiles.push([
  "wf-4-vendor-router.json",
  wf(
    "wf4-vendor-router",
    "WF-4 Vendor Router",
    [
      { id: "trigger", name: "Receive Vendor Envelope", type: "n8n-nodes-base.executeWorkflowTrigger", typeVersion: 1.2, position: [0, 0], parameters: { inputSource: "passthrough" } },
      pgNode("load-vendor-context", "Load Vendor Context", 280, 0, vendorLookupQuery),
      ifNode("known-vendor", "Known Vendor?", 560, 0, "={{ $json.known_vendor }}"),
      codeNode("build-openai-classification-request", "Build OpenAI Classification Request", 840, -180, buildClassifierCode),
      httpOpenAiNode("classify-vendor-message-openai", "Classify Vendor Message With OpenAI", 1120, -180),
      codeNode("parse-classification-or-fallback", "Parse Classification Or Fallback", 1400, -180, parseClassifierCode),
      executeNode("call-unit-matcher", "Call Unit Matcher", 1680, -180, "wf4-unit-matcher"),
      codeNode("prepare-known-route", "Prepare Known Route", 1960, -180, prepareKnownRouteCode),
      ifNode("should-complete-stage", "Should Complete Stage?", 2240, -180, "={{ $json.should_complete }}"),
      executeNode("call-vendor-completion-handler", "Call Vendor Completion Handler", 2520, -300, "wf5-vendor-completion-handler"),
      pgNode("log-vendor-router-event", "Log Vendor Router Event", 2520, -60, logRouterEventQuery),
      ifNode("notify-manager", "Notify Manager?", 2800, -60, "={{ $json.should_notify_manager }}"),
      telegramSendNode("send-manager-notice", "Send Manager Notice", 3080, -180, "={{ $json.manager_notice_text }}"),
      codeNode("return-after-manager-notice", "Return After Manager Notice", 3360, -180, "return [$('Log Vendor Router Event').first()];"),
      codeNode("return-router-result", "Return Router Result", 3080, 60, "return items;"),
      codeNode("prepare-unknown-event", "Prepare Unknown Event", 840, 180, prepareUnknownCode),
    ],
    {
      "Receive Vendor Envelope": { main: [[{ node: "Load Vendor Context", type: "main", index: 0 }]] },
      "Load Vendor Context": { main: [[{ node: "Known Vendor?", type: "main", index: 0 }]] },
      "Known Vendor?": {
        main: [
          [{ node: "Build OpenAI Classification Request", type: "main", index: 0 }],
          [{ node: "Prepare Unknown Event", type: "main", index: 0 }],
        ],
      },
      "Build OpenAI Classification Request": { main: [[{ node: "Classify Vendor Message With OpenAI", type: "main", index: 0 }]] },
      "Classify Vendor Message With OpenAI": { main: [[{ node: "Parse Classification Or Fallback", type: "main", index: 0 }]] },
      "Parse Classification Or Fallback": { main: [[{ node: "Call Unit Matcher", type: "main", index: 0 }]] },
      "Call Unit Matcher": { main: [[{ node: "Prepare Known Route", type: "main", index: 0 }]] },
      "Prepare Known Route": { main: [[{ node: "Should Complete Stage?", type: "main", index: 0 }]] },
      "Should Complete Stage?": {
        main: [
          [{ node: "Call Vendor Completion Handler", type: "main", index: 0 }],
          [{ node: "Log Vendor Router Event", type: "main", index: 0 }],
        ],
      },
      "Prepare Unknown Event": { main: [[{ node: "Log Vendor Router Event", type: "main", index: 0 }]] },
      "Log Vendor Router Event": { main: [[{ node: "Notify Manager?", type: "main", index: 0 }]] },
      "Notify Manager?": {
        main: [
          [{ node: "Send Manager Notice", type: "main", index: 0 }],
          [{ node: "Return Router Result", type: "main", index: 0 }],
        ],
      },
      "Send Manager Notice": { main: [[{ node: "Return After Manager Notice", type: "main", index: 0 }]] },
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
      { id: "manager-trigger", name: "ManagerTelegramTrigger", type: "n8n-nodes-base.telegramTrigger", typeVersion: 1.3, position: [0, 0], parameters: { updates: ["callback_query"], additionalFields: {} }, credentials: { telegramApi: managerTgCred } },
      codeNode("parse-manager-callback", "Parse Manager Callback", 240, 0, parseManagerCallbackCode),
      ifNode("callback-handled", "Callback Handled?", 480, 0, "={{ $json.handled }}"),
      codeNode("route-done-callback", "Route Done Callback", 720, -180, routeDoneCode),
      ifNode("is-done-callback", "Is Done Callback?", 960, -180, "={{ $json.route_done }}"),
      executeNode("call-completion-core-from-digest", "Call Completion Core From Digest", 1240, -300, "wf3-stage-complete-core"),
      codeNode("route-action-callback", "Route Action Callback", 1240, -80, routeActionCode),
      ifNode("is-action-callback", "Is Action Callback?", 1520, -80, "={{ $json.route_action }}"),
      executeNode("call-manager-action-core", "Call Manager Action Core", 1800, -180, "wf5-manager-action-core"),
      { id: "answer-callback", name: "Answer Manager Callback", type: "n8n-nodes-base.telegram", typeVersion: 1.2, position: [2080, -180], parameters: { resource: "callback", operation: "answerQuery", queryId: "={{ $json.telegram_callback_query_id }}", additionalFields: { text: '={{ $json.outcome || $json.manager_response_text || $json.reason || $json.message || "Done" }}', show_alert: false } }, credentials: { telegramApi: managerTgCred } },
      { id: "answer-noop", name: "Answer Ignored Callback", type: "n8n-nodes-base.telegram", typeVersion: 1.2, position: [720, 160], parameters: { resource: "callback", operation: "answerQuery", queryId: "={{ $json.telegram_callback_query_id }}", additionalFields: { text: "No action taken.", show_alert: false } }, credentials: { telegramApi: managerTgCred } },
    ],
    {
      ManagerTelegramTrigger: { main: [[{ node: "Parse Manager Callback", type: "main", index: 0 }]] },
      "Parse Manager Callback": { main: [[{ node: "Callback Handled?", type: "main", index: 0 }]] },
      "Callback Handled?": {
        main: [
          [{ node: "Route Done Callback", type: "main", index: 0 }],
          [{ node: "Answer Ignored Callback", type: "main", index: 0 }],
        ],
      },
      "Route Done Callback": { main: [[{ node: "Is Done Callback?", type: "main", index: 0 }]] },
      "Is Done Callback?": {
        main: [
          [{ node: "Call Completion Core From Digest", type: "main", index: 0 }],
          [{ node: "Route Action Callback", type: "main", index: 0 }],
        ],
      },
      "Call Completion Core From Digest": { main: [[{ node: "Answer Manager Callback", type: "main", index: 0 }]] },
      "Route Action Callback": { main: [[{ node: "Is Action Callback?", type: "main", index: 0 }]] },
      "Is Action Callback?": {
        main: [
          [{ node: "Call Manager Action Core", type: "main", index: 0 }],
          [{ node: "Answer Ignored Callback", type: "main", index: 0 }],
        ],
      },
      "Call Manager Action Core": { main: [[{ node: "Answer Manager Callback", type: "main", index: 0 }]] },
    },
    false,
  ),
]);

for (const [file, data] of workflowFiles) {
  fs.writeFileSync(path.join(outDir, file), JSON.stringify(data, null, 2) + "\n", "utf8");
}
