const fs = require("fs");
const path = require("path");
const { randomUUID } = require("crypto");
const { spawnSync } = require("child_process");

const repoRoot = path.resolve(__dirname, "..");
const workflowDir = path.join(repoRoot, "n8n-workflows");
const sourceGenerator = path.join(__dirname, "generate-airtable-email-workflows.js");

const generated = spawnSync(process.execPath, [sourceGenerator], { stdio: "inherit" });
if (generated.status !== 0) throw new Error("generate-airtable-email-workflows.js failed.");

const sourceWorkflows = new Map();
for (const file of fs.readdirSync(workflowDir).filter((entry) => entry.endsWith(".json"))) {
  const workflow = JSON.parse(fs.readFileSync(path.join(workflowDir, file), "utf8"));
  sourceWorkflows.set(workflow.id, workflow);
}

function isTrigger(node) {
  return [
    "n8n-nodes-base.emailReadImap",
    "n8n-nodes-base.errorTrigger",
    "n8n-nodes-base.executeWorkflowTrigger",
    "n8n-nodes-base.manualTrigger",
    "n8n-nodes-base.scheduleTrigger",
    "n8n-nodes-base.telegramTrigger",
    "n8n-nodes-base.webhook",
  ].includes(String(node.type || ""));
}

function isWorkflowCall(node) {
  return node.type === "n8n-nodes-base.executeWorkflow";
}

function workflowCallId(node) {
  return String(node.parameters?.workflowId || node.parameters?.workflowInfo?.value || "");
}

function rewriteNodeReferences(value, nodeNames) {
  if (typeof value === "string") {
    let output = value;
    for (const [before, after] of nodeNames.entries()) {
      output = output.split(`$('${before}')`).join(`$('${after}')`);
      output = output.split(`$("${before}")`).join(`$("${after}")`);
    }
    return output;
  }
  if (Array.isArray(value)) return value.map((item) => rewriteNodeReferences(item, nodeNames));
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, rewriteNodeReferences(item, nodeNames)]));
  }
  return value;
}

function makeConnections() {
  return Object.create(null);
}

function appendConnection(connections, source, sourceType, sourceIndex, target, targetType, targetIndex) {
  if (!connections[source]) connections[source] = Object.create(null);
  if (!connections[source][sourceType]) connections[source][sourceType] = [];
  while (connections[source][sourceType].length <= sourceIndex) connections[source][sourceType].push([]);
  connections[source][sourceType][sourceIndex].push({ node: target, type: targetType, index: targetIndex });
}

function connectionEntries(workflow) {
  const edges = [];
  for (const [source, byType] of Object.entries(workflow.connections || {})) {
    for (const [sourceType, branches] of Object.entries(byType || {})) {
      (branches || []).forEach((targets, sourceIndex) => {
        for (const target of targets || []) {
          edges.push({ source, sourceType, sourceIndex, target: target.node, targetType: target.type || "main", targetIndex: Number(target.index || 0) });
        }
      });
    }
  }
  return edges;
}

function createAssembler(specification) {
  const nodes = [];
  const connections = makeConnections();
  let nodeCounter = 0;

  function copyWorkflow(workflowId, instanceName, preserveTriggers, inlineWorkflowIds, externalWorkflowIds) {
    const workflow = sourceWorkflows.get(workflowId);
    if (!workflow) throw new Error(`Missing source workflow ${workflowId}.`);

    const nodeMap = new Map();
    const nameMap = new Map();
    const logical = new Map();
    const sourceEdges = connectionEntries(workflow);
    const sourceNodes = new Map(workflow.nodes.map((node) => [node.name, node]));

    for (const node of workflow.nodes) {
      const calledId = isWorkflowCall(node) ? workflowCallId(node) : "";
      const hiddenTrigger = isTrigger(node) && !preserveTriggers;
      const inlineCall = isWorkflowCall(node) && inlineWorkflowIds.has(calledId);
      if (hiddenTrigger || inlineCall) continue;
      // n8n derives Telegram callback paths from the node name. Spaces register
      // but are not matched on delivery, so these names must be path-safe.
      const copiedName = node.type === "n8n-nodes-base.telegramTrigger"
        ? `${instanceName}-${node.name}`.replace(/\s+/g, "-").toLowerCase()
        : `${instanceName} ${node.name}`;
      nodeMap.set(node.name, copiedName);
      nameMap.set(node.name, copiedName);
    }

    for (const node of workflow.nodes) {
      if (!isWorkflowCall(node)) continue;
      const calledId = workflowCallId(node);
      if (!inlineWorkflowIds.has(calledId)) continue;
      const child = copyWorkflow(calledId, `${instanceName} ${node.name}`, false, inlineWorkflowIds, externalWorkflowIds);
      logical.set(node.name, { starts: child.entries, ends: child.exits });
      if (child.exits.length) nameMap.set(node.name, child.exits[0]);
    }

    for (const node of workflow.nodes) {
      if (!nodeMap.has(node.name)) continue;
      const copied = rewriteNodeReferences(JSON.parse(JSON.stringify(node)), nameMap);
      copied.id = `demo-node-${++nodeCounter}`;
      copied.name = nodeMap.get(node.name);
      if (isWorkflowCall(copied)) {
        const calledId = workflowCallId(node);
        if (externalWorkflowIds[calledId]) copied.parameters.workflowId = externalWorkflowIds[calledId];
      }
      nodes.push(copied);
      logical.set(node.name, { starts: [copied.name], ends: [copied.name] });
    }

    const entries = [];
    for (const edge of sourceEdges) {
      const sourceNode = sourceNodes.get(edge.source);
      const sourceLogical = logical.get(edge.source);
      const targetLogical = logical.get(edge.target);
      if (!targetLogical) continue;
      if (isTrigger(sourceNode) && !preserveTriggers) {
        entries.push(...targetLogical.starts);
        continue;
      }
      if (!sourceLogical) continue;
      for (const sourceName of sourceLogical.ends) {
        for (const targetName of targetLogical.starts) {
          appendConnection(connections, sourceName, edge.sourceType, edge.sourceIndex, targetName, edge.targetType, edge.targetIndex);
        }
      }
    }

    const outgoingSources = new Set(sourceEdges.map((edge) => edge.source));
    const exits = [];
    for (const node of workflow.nodes) {
      if (isTrigger(node)) continue;
      if (outgoingSources.has(node.name)) continue;
      const value = logical.get(node.name);
      if (value) exits.push(...value.ends);
    }
    return { entries: [...new Set(entries)], exits: [...new Set(exits)] };
  }

  for (const root of specification.roots) {
    copyWorkflow(root.workflowId, root.instance, true, new Set(root.inline || []), specification.external || {});
  }

  return {
    id: specification.id,
    name: specification.name,
    active: false,
    nodes,
    connections,
    settings: specification.id === "demo-builder-error-handler"
      ? { executionOrder: "v1" }
      : { executionOrder: "v1", errorWorkflow: "demo-builder-error-handler" },
    staticData: null,
    pinData: {},
    versionId: randomUUID(),
    triggerCount: nodes.filter(isTrigger).length,
    tags: [],
  };
}

const ids = {
  airtable: "demo-airtable-workspace",
  vendor: "demo-vendor-communications",
  stage: "demo-stage-update",
  manager: "demo-manager-operations",
  delivery: "demo-vendor-delivery",
  monitoring: "demo-monitoring",
  error: "demo-builder-error-handler",
};

const external = {
  "wf9-airtable-sync": ids.airtable,
  "wf3-stage-complete-core": ids.stage,
  "wf5-vendor-completion-handler": ids.stage,
  "wf9-vendor-delivery": ids.delivery,
};

const specifications = [
  {
    id: ids.airtable,
    name: "Airtable Workspace",
    external,
    roots: [
      { workflowId: "wf4-turn-intake", instance: "Intake", inline: ["wf9-airtable-sync"] },
      { workflowId: "wf9-airtable-sync", instance: "Sync" },
    ],
  },
  {
    id: ids.vendor,
    name: "Vendor Communications",
    external,
    roots: [
      { workflowId: "wf9-vendor-email-ingest", instance: "Email", inline: ["wf4-vendor-router", "wf9-ai-interpreter", "wf4-unit-matcher"] },
      { workflowId: "wf4-vendor-telegram-ingest", instance: "Telegram", inline: ["wf4-vendor-router", "wf9-ai-interpreter", "wf4-unit-matcher"] },
      { workflowId: "wf4-vendor-in-api", instance: "API", inline: ["wf4-vendor-router", "wf9-ai-interpreter", "wf4-unit-matcher"] },
    ],
  },
  {
    id: ids.stage,
    name: "Stage Update",
    external,
    roots: [
      { workflowId: "wf3-stage-complete-core", instance: "Stage", inline: ["wf5-vendor-completion-handler", "wf3-sequence-guard"] },
    ],
  },
  {
    id: ids.manager,
    name: "Manager Operations",
    external,
    roots: [
      { workflowId: "wf3-manager-router", instance: "Manager", inline: ["wf6-health-core", "wf5-manager-action-core"] },
      { workflowId: "wf3-daily-digest", instance: "Digest" },
    ],
  },
  {
    id: ids.delivery,
    name: "Vendor Delivery",
    external,
    roots: [{ workflowId: "wf9-vendor-delivery", instance: "Delivery" }],
  },
  {
    id: ids.monitoring,
    name: "Monitoring",
    external,
    roots: [
      { workflowId: "wf6-stall-watchdog", instance: "Stall" },
      { workflowId: "wf6-weekly-digest", instance: "Weekly", inline: ["wf6-health-core"] },
    ],
  },
  {
    id: ids.error,
    name: "Builder Error Handler",
    external,
    roots: [{ workflowId: "wf7-error-handler", instance: "Error" }],
  },
];

// Lay out nodes so the editor is readable.
//
// Consolidation inlines several source workflows into one and keeps each source's original
// coordinates, so three copies of the same router land on identical positions. Vendor
// Communications had 62 nodes sitting exactly on top of another node before this ran.
//
// Layered left-to-right layout:
//   x  comes from depth, the longest path from any entry node
//   y  comes from which entry node owns the branch, then a slot within that lane
// Lanes keep the Email, Telegram and API copies of the router in separate horizontal bands
// rather than interleaved.
function layoutWorkflow(workflow) {
  const nodes = workflow.nodes;
  const byName = new Map(nodes.map((n) => [n.name, n]));
  const outgoing = new Map(nodes.map((n) => [n.name, []]));
  const indegree = new Map(nodes.map((n) => [n.name, 0]));

  for (const [source, conn] of Object.entries(workflow.connections || {})) {
    for (const branch of conn.main || []) {
      for (const link of branch || []) {
        if (!byName.has(link.node) || !outgoing.has(source)) continue;
        outgoing.get(source).push(link.node);
        indegree.set(link.node, indegree.get(link.node) + 1);
      }
    }
  }

  // Entry nodes: anything nothing points at. Triggers first so lanes come out in a sane order.
  const isTrigger = (n) => /trigger/i.test(n.type) || n.type.endsWith(".webhook");
  const roots = nodes
    .filter((n) => indegree.get(n.name) === 0)
    .sort((a, b) => (isTrigger(b) ? 1 : 0) - (isTrigger(a) ? 1 : 0));
  if (roots.length === 0) roots.push(nodes[0]);

  // Depth by longest path, so a node always sits right of everything feeding it.
  const depth = new Map(nodes.map((n) => [n.name, 0]));
  const order = [];
  const pending = new Map(indegree);
  const queue = roots.map((n) => n.name);
  const queued = new Set(queue);
  while (queue.length) {
    const name = queue.shift();
    order.push(name);
    for (const next of outgoing.get(name) || []) {
      depth.set(next, Math.max(depth.get(next), depth.get(name) + 1));
      pending.set(next, pending.get(next) - 1);
      if (pending.get(next) <= 0 && !queued.has(next)) {
        queued.add(next);
        queue.push(next);
      }
    }
  }
  // Cycles or unreachable nodes keep depth 0; place them after their earliest predecessor.
  for (const n of nodes) {
    if (!queued.has(n.name) && !roots.includes(n)) {
      const preds = nodes.filter((p) => (outgoing.get(p.name) || []).includes(n.name));
      const best = preds.reduce((acc, p) => Math.max(acc, depth.get(p.name) + 1), 0);
      depth.set(n.name, best);
    }
  }

  // Lane ownership: first root to reach a node claims it.
  const lane = new Map();
  roots.forEach((root, index) => {
    const stack = [root.name];
    while (stack.length) {
      const name = stack.pop();
      if (lane.has(name)) continue;
      lane.set(name, index);
      for (const next of outgoing.get(name) || []) if (!lane.has(next)) stack.push(next);
    }
  });
  for (const n of nodes) if (!lane.has(n.name)) lane.set(n.name, roots.length);

  const COL = 320;
  const ROW = 130;
  const LANE_GAP = 90;

  // Slot nodes within (lane, depth), then stack lanes vertically with a gap between them.
  const laneIds = [...new Set(nodes.map((n) => lane.get(n.name)))].sort((a, b) => a - b);
  let laneTop = 0;
  for (const id of laneIds) {
    const members = nodes.filter((n) => lane.get(n.name) === id);
    const columns = new Map();
    for (const n of members) {
      const d = depth.get(n.name);
      if (!columns.has(d)) columns.set(d, []);
      columns.get(d).push(n);
    }
    let laneHeight = 0;
    for (const [d, column] of columns) {
      column.sort((a, b) => a.position[1] - b.position[1] || a.name.localeCompare(b.name));
      column.forEach((n, row) => {
        n.position = [d * COL, laneTop + row * ROW];
      });
      laneHeight = Math.max(laneHeight, column.length * ROW);
    }
    laneTop += laneHeight + LANE_GAP;
  }
  return workflow;
}

const consolidated = specifications.map(createAssembler);
consolidated.forEach(layoutWorkflow);
for (const file of fs.readdirSync(workflowDir).filter((entry) => entry.endsWith(".json"))) {
  fs.unlinkSync(path.join(workflowDir, file));
}
for (const workflow of consolidated) {
  fs.writeFileSync(path.join(workflowDir, `${workflow.id}.json`), `${JSON.stringify(workflow, null, 2)}\n`);
}

console.log(`Generated ${consolidated.length} consolidated demo workflows.`);
