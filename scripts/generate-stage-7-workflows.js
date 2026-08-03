const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const repoRoot = path.resolve(__dirname, "..");
const outDir = path.join(repoRoot, "n8n-workflows");

const pgCred = { id: "cred_make_ready_pg", name: "Make-Ready Postgres" };
const managerTgCred = { id: "jASZWMlrfp3v2tWH", name: "Make-Ready Manager Telegram Bot" };

const stageGenerators = [
  "generate-stage-3-workflows.js",
  "generate-stage-4-workflows.js",
  "generate-stage-5-workflows.js",
  "generate-stage-6-workflows.js",
];

const managedWorkflowFiles = [
  "wf-3-sequence-guard.json",
  "wf-3-stage-complete-core.json",
  "wf-3-board-api.json",
  "wf-3-stage-complete-api.json",
  "wf-3-daily-digest.json",
  "wf-3-manager-router.json",
  "wf-4-turn-intake.json",
  "wf-4-unit-matcher.json",
  "wf-4-vendor-router.json",
  "wf-4-vendor-in-api.json",
  "wf-4-vendor-telegram-ingest.json",
  "wf-5-vendor-completion-handler.json",
  "wf-5-manager-action-core.json",
  "wf-5-manager-action-api.json",
  "wf-6-health-core.json",
  "wf-6-health-api.json",
  "wf-6-stall-watchdog.json",
  "wf-6-weekly-digest.json",
  "wf-7-error-smoke.json",
];

const demoWorkflowNames = {
  "wf3-sequence-guard": "Sequence Guard",
  "wf3-stage-complete-core": "Stage Complete Core",
  "wf3-board-api": "Board API",
  "wf3-stage-complete-api": "Stage Complete API",
  "wf3-daily-digest": "Manager Daily Digest",
  "wf3-manager-router": "Manager Telegram Router",
  "wf4-turn-intake": "Turn Intake Form",
  "wf4-unit-matcher": "Unit Matcher",
  "wf4-vendor-router": "Vendor Message Router",
  "wf4-vendor-in-api": "Vendor Inbound API",
  "wf4-vendor-telegram-ingest": "Vendor Telegram Ingest",
  "wf5-vendor-completion-handler": "Vendor Completion Handler",
  "wf5-manager-action-core": "Manager Action Core",
  "wf5-manager-action-api": "Manager Action API",
  "wf6-health-core": "Health Core",
  "wf6-health-api": "Health API",
  "wf6-stall-watchdog": "Stall Watchdog",
  "wf6-weekly-digest": "Weekly Metrics Digest",
  "wf7-error-handler": "Builder Error Handler",
  "wf7-error-smoke": "Error Smoke",
};

function runGenerator(script) {
  const result = spawnSync(process.execPath, [path.join(__dirname, script)], { stdio: "inherit" });
  if (result.status !== 0) {
    throw new Error(`${script} failed with exit code ${result.status}`);
  }
}

function wf(id, name, nodes, connections, active = false, settings = {}) {
  return {
    id,
    name,
    active,
    nodes,
    connections,
    settings: { executionOrder: "v1", ...settings },
    staticData: null,
    pinData: {},
    versionId: `${id}-v1`,
    triggerCount: 0,
    tags: [],
  };
}

function save(file, data) {
  fs.writeFileSync(path.join(outDir, file), JSON.stringify(data, null, 2) + "\n", "utf8");
}

function load(file) {
  return JSON.parse(fs.readFileSync(path.join(outDir, file), "utf8"));
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

function telegramSendNode(id, name, x, y, chatIdExpression, textExpression) {
  return {
    id,
    name,
    type: "n8n-nodes-base.telegram",
    typeVersion: 1.2,
    position: [x, y],
    parameters: {
      resource: "message",
      operation: "sendMessage",
      chatId: chatIdExpression,
      text: textExpression,
      additionalFields: { disable_web_page_preview: true, appendAttribution: false },
    },
    credentials: { telegramApi: managerTgCred },
  };
}

const normalizeErrorCode = `const execution = $json.execution || {};
const trigger = $json.trigger || {};
const workflow = $json.workflow || {};
const error = execution.error || trigger.error || {};
let message = String(error.message || error.description || '');
if (!message) {
  try { message = JSON.stringify(error); } catch { message = 'Unknown workflow error'; }
}
if (!message || message === '{}') message = 'Unknown workflow error';
const lastNode = String(execution.lastNodeExecuted || '');
const workflowName = String(workflow.name || workflow.id || 'Unknown workflow');
const executionUrl = String(execution.url || '');
const shortMessage = message.slice(0, 280);
const notice = [
  'Make-ready demo workflow error',
  workflowName,
  lastNode ? 'Node: ' + lastNode : null,
  shortMessage,
  executionUrl || null
].filter(Boolean).join('\\n');
return [{ json: {
  workflow_id: String(workflow.id || ''),
  workflow_name: workflowName,
  execution_id: String(execution.id || ''),
  execution_url: executionUrl,
  last_node: lastNode,
  mode: String(execution.mode || trigger.mode || ''),
  error_message: message.slice(0, 1000),
  builder_chat_id: 'stage7-builder-chat-id-missing',
  builder_notice_text: notice,
  error_payload: { workflow, execution, trigger }
} }];`;

const logErrorQuery = `WITH input AS (
  SELECT
    '{{ String($json.workflow_id || "").replace(/'/g, "''") }}'::text AS workflow_id,
    '{{ String($json.workflow_name || "").replace(/'/g, "''") }}'::text AS workflow_name,
    '{{ String($json.execution_id || "").replace(/'/g, "''") }}'::text AS execution_id,
    '{{ String($json.execution_url || "").replace(/'/g, "''") }}'::text AS execution_url,
    '{{ String($json.last_node || "").replace(/'/g, "''") }}'::text AS last_node,
    '{{ String($json.mode || "").replace(/'/g, "''") }}'::text AS mode,
    '{{ String($json.error_message || "Unknown workflow error").replace(/'/g, "''") }}'::text AS error_message,
    '{{ String($json.builder_chat_id || "").replace(/'/g, "''") }}'::text AS builder_chat_id,
    '{{ String($json.builder_notice_text || "Make-ready demo workflow error").replace(/'/g, "''") }}'::text AS builder_notice_text,
    '{{ JSON.stringify($json.error_payload || {}).replace(/'/g, "''") }}'::jsonb AS error_payload
), inserted AS (
  INSERT INTO event_log (actor_type, actor_id, channel, event_type, raw_text, parsed_json)
  SELECT
    'system',
    'wf7-error-handler',
    'system',
    'workflow_error',
    error_message,
    jsonb_build_object(
      'workflow_id', workflow_id,
      'workflow_name', workflow_name,
      'execution_id', execution_id,
      'execution_url', execution_url,
      'last_node', last_node,
      'mode', mode,
      'error_payload', error_payload
    )
  FROM input
  RETURNING id
)
SELECT
  inserted.id AS event_id,
  input.workflow_id,
  input.workflow_name,
  input.execution_id,
  input.execution_url,
  input.last_node,
  input.mode,
  input.error_message,
  input.builder_notice_text,
  CASE WHEN input.builder_chat_id LIKE 'stage7-%-missing' THEN NULL ELSE NULLIF(input.builder_chat_id, '') END AS builder_chat_id,
  (input.builder_chat_id <> '' AND input.builder_chat_id NOT LIKE 'stage7-%-missing') AS should_notify_builder
FROM input
CROSS JOIN inserted;`;

function writeErrorHandler() {
  save(
    "wf-7-error-handler.json",
    wf(
      "wf7-error-handler",
      "WF-7 Builder Error Handler",
      [
        { id: "error-trigger", name: "Error Trigger", type: "n8n-nodes-base.errorTrigger", typeVersion: 1, position: [0, 0], parameters: {} },
        codeNode("normalize-error-payload", "Normalize Error Payload", 280, 0, normalizeErrorCode),
        pgNode("log-workflow-error", "Log Workflow Error", 560, 0, logErrorQuery),
        ifNode("builder-chat-configured", "Builder Chat Configured?", 840, 0, "={{ $json.should_notify_builder }}"),
        telegramSendNode("send-builder-error-alert", "Send Builder Error Alert", 1120, -120, "={{ $json.builder_chat_id }}", "={{ $json.builder_notice_text }}"),
        codeNode("return-error-log-summary", "Return Error Log Summary", 1120, 120, "return items;"),
      ],
      {
        "Error Trigger": { main: [[{ node: "Normalize Error Payload", type: "main", index: 0 }]] },
        "Normalize Error Payload": { main: [[{ node: "Log Workflow Error", type: "main", index: 0 }]] },
        "Log Workflow Error": { main: [[{ node: "Builder Chat Configured?", type: "main", index: 0 }]] },
        "Builder Chat Configured?": {
          main: [
            [{ node: "Send Builder Error Alert", type: "main", index: 0 }],
            [{ node: "Return Error Log Summary", type: "main", index: 0 }],
          ],
        },
      },
      true,
    ),
  );
}

const smokeNormalizeCode = `const headers = $json.headers || {};
const query = $json.query || {};
const body = $json.body || {};
const configuredToken = 'local-stage-3-demo-token';
const suppliedToken = query.token || headers['x-demo-token'] || headers['X-Demo-Token'] || body.token || '';
return [{ json: {
  authorized: Boolean(configuredToken) && String(suppliedToken) === String(configuredToken),
  message: 'Stage 7 error smoke intentionally failed.',
  cors_origin: 'http://localhost:8080'
} }];`;

function writeErrorSmoke() {
  save(
    "wf-7-error-smoke.json",
    wf(
      "wf7-error-smoke",
      "WF-7 Error Smoke",
      [
        { id: "webhook-error-smoke", name: "POST Error Smoke Webhook", type: "n8n-nodes-base.webhook", typeVersion: 2.1, position: [0, 0], webhookId: "wf7-error-smoke", parameters: { httpMethod: "POST", path: "stage-7-error-smoke", authentication: "none", responseMode: "responseNode", options: { allowedOrigins: "http://localhost:8080" } } },
        codeNode("normalize-error-smoke-request", "Normalize Error Smoke Request", 280, 0, smokeNormalizeCode),
        ifNode("error-smoke-authorized", "Error Smoke Authorized?", 560, 0, "={{ $json.authorized }}"),
        codeNode("throw-intentional-error", "Throw Intentional Error", 840, -120, "throw new Error($json.message || 'Stage 7 error smoke intentionally failed.');"),
        codeNode("format-error-smoke-unauthorized", "Format Error Smoke Unauthorized", 840, 120, "return [{ json: { accepted: false, outcome: 'unauthorized', error: 'unauthorized', cors_origin: 'http://localhost:8080' } }];"),
        respondNode("respond-error-smoke-unauthorized", "Respond Error Smoke 401", 1120, 120, 401),
      ],
      {
        "POST Error Smoke Webhook": { main: [[{ node: "Normalize Error Smoke Request", type: "main", index: 0 }]] },
        "Normalize Error Smoke Request": { main: [[{ node: "Error Smoke Authorized?", type: "main", index: 0 }]] },
        "Error Smoke Authorized?": {
          main: [
            [{ node: "Throw Intentional Error", type: "main", index: 0 }],
            [{ node: "Format Error Smoke Unauthorized", type: "main", index: 0 }],
          ],
        },
        "Format Error Smoke Unauthorized": { main: [[{ node: "Respond Error Smoke 401", type: "main", index: 0 }]] },
      },
      true,
      { errorWorkflow: "wf7-error-handler" },
    ),
  );
}

function applyErrorWorkflowSettings() {
  for (const file of managedWorkflowFiles) {
    const workflow = load(file);
    workflow.settings = workflow.settings || {};
    workflow.settings.executionOrder = workflow.settings.executionOrder || "v1";
    workflow.settings.errorWorkflow = "wf7-error-handler";
    save(file, workflow);
  }
}

function applyDemoWorkflowDisplayNames() {
  for (const file of [...managedWorkflowFiles, "wf-7-error-handler.json"]) {
    const workflow = load(file);
    if (demoWorkflowNames[workflow.id]) {
      workflow.name = demoWorkflowNames[workflow.id];
    }
    save(file, workflow);
  }
}

for (const script of stageGenerators) {
  runGenerator(script);
}
writeErrorHandler();
writeErrorSmoke();
applyErrorWorkflowSettings();
applyDemoWorkflowDisplayNames();
