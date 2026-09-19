#!/usr/bin/env node
// Read-modify-write update of one canonical CanDoItAll task through the HTTP API, using only
// the JSON the host returns. Usage:
//   node update-task.mjs --base-url http://localhost:5032 --project <projectId> --task <taskId>
//     [--title "New title"] [--progress 40] [--start <ISO instant> --end <ISO instant>]
//   node update-task.mjs --base-url http://localhost:5032 --demo
// --demo creates a synthetic project and task first. Set CANDOITALL_API_TOKEN when the host
// requires bearer authorization; the token needs the `api` or `api.project-structure.write` scope.
// The proposed progress is --progress when given, otherwise the current value, or 0 for an
// untracked task (-1), so any update of an untracked task starts tracking its progress.
// Requires Node.js 18 or later (global fetch).

const EXECUTION_STATES = { unknown: 0, notStarted: 1, started: 2, completed: 3, cancelled: 4 };
const EFFORT_UNITS = { hours: 0, manDays: 1 };
const RESOURCE_KINDS = { person: 0, agent: 1, workflow: 2, process: 3 };
const COST_SOURCES = {
  unknown: 0,
  crmWorkforceRate: 1,
  agentRunHistory: 2,
  workflowRunHistory: 3,
  processRunHistory: 4,
};
const SET_INTERVAL = 3;
const CANONICAL_CURRENT = 2;

function parseArguments(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const name = argv[index];
    if (!name.startsWith('--')) {
      throw new Error(`Unexpected argument '${name}'.`);
    }
    if (name === '--demo') {
      options.demo = true;
      continue;
    }
    const value = argv[index + 1];
    if (value === undefined) {
      throw new Error(`Missing value for ${name}.`);
    }
    options[name.slice(2)] = value;
    index += 1;
  }
  return options;
}

async function call(baseUrl, method, path, body) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }
  if (process.env.CANDOITALL_API_TOKEN) {
    headers.Authorization = `Bearer ${process.env.CANDOITALL_API_TOKEN}`;
  }
  const response = await fetch(new URL(path, baseUrl), {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = null;
  }
  return { status: response.status, json, text };
}

function requireSuccess(result, action) {
  if (result.status < 200 || result.status > 299) {
    const code = result.json?.error?.errorCode ?? result.json?.errors?.[0]?.code ?? 'no error code';
    throw new Error(`${action} failed with HTTP ${result.status} (${code}): ${result.text}`);
  }
  return result.json;
}

async function readStructure(baseUrl, projectId) {
  return requireSuccess(
    await call(baseUrl, 'POST', `/api/project-structure/projects/${projectId}/structure/read`, {
      includeMetadata: true,
      source: CANONICAL_CURRENT,
    }),
    'Structure read',
  );
}

function readTask(structure, taskId) {
  const node = structure.nodes.find((candidate) => candidate.id === taskId);
  if (!node) {
    throw new Error(`Task '${taskId}' is not in the structure read.`);
  }
  const metadata = node.metadataJson ? JSON.parse(node.metadataJson) : {};
  const workItem = metadata.workItem ?? {};
  return { node, workItem, admission: structure.expectedProjectAdmission };
}

function costBasis(basis) {
  if (!basis) {
    return null;
  }
  return {
    resourceKind: RESOURCE_KINDS[basis.resourceKind],
    resourceId: basis.resourceId,
    resourceVersionId: basis.resourceVersionId ?? null,
    source: COST_SOURCES[basis.source],
    calculatedAtUtc: basis.calculatedAtUtc ?? null,
  };
}

function unchangedUpdate({ node, workItem, admission }) {
  const estimate = {
    expectedEffortHours: workItem.expectedEffortHours ?? null,
    expectedEffortUnit: EFFORT_UNITS[workItem.expectedEffortUnit ?? 'hours'],
    expectedCostAmount: workItem.expectedCostAmount ?? null,
    expectedCostCurrencyCode: workItem.expectedCostCurrencyCode ?? '',
  };
  const execution = {
    state: EXECUTION_STATES[workItem.executionState ?? 'unknown'],
    actualStartedAtUtc: workItem.actualStartedAtUtc ?? null,
    actualEndedAtUtc: workItem.actualEndedAtUtc ?? null,
  };
  return {
    taskId: node.id,
    currentTitle: node.title,
    proposedTitle: node.title,
    currentProgressPercent: node.progressPercent,
    proposedProgressPercent: Math.min(Math.max(node.progressPercent, 0), 100),
    currentEstimate: estimate,
    proposedEstimate: { ...estimate },
    scheduleChange: null,
    assigneeChanged: false,
    proposedAssignee: null,
    currentExecution: execution,
    proposedExecution: { ...execution },
    currentCostBasis: costBasis(workItem.expectedCostBasis),
    currentDirectAssignmentRevision: workItem.directAssignmentRevision ?? 0,
    expectedProjectAdmission: admission,
  };
}

async function createDemoTask(baseUrl) {
  const project = requireSuccess(
    await call(baseUrl, 'POST', '/api/project-structure/projects', {
      name: `Synthetic task update demo ${Date.now()}`,
      description: 'Synthetic project created by update-task.mjs.',
      objective: 'Demonstrate the documented task update workflow.',
      currentPhase: 'Demo',
      status: 1,
    }),
    'Project create',
  );
  const structure = await readStructure(baseUrl, project.id);
  const created = requireSuccess(
    await call(baseUrl, 'POST', `/api/project-structure/projects/${project.id}/tasks`, {
      title: 'Synthetic demo task',
      startUtc: '2026-08-10T09:00:00+00:00',
      endUtc: '2026-08-10T17:00:00+00:00',
      estimate: {
        expectedEffortHours: 8,
        expectedEffortUnit: EFFORT_UNITS.manDays,
        expectedCostAmount: 320,
        expectedCostCurrencyCode: 'EUR',
      },
      expectedProjectAdmission: structure.expectedProjectAdmission,
    }),
    'Task create',
  );
  return { projectId: project.id, taskId: created.taskNodeId };
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const baseUrl = options['base-url'] ?? 'http://localhost:5032';
  let { project: projectId, task: taskId } = options;
  if (options.demo) {
    ({ projectId, taskId } = await createDemoTask(baseUrl));
    options.title ??= 'Synthetic demo task, renamed';
    options.progress ??= '25';
    options.start ??= '2026-08-11T09:00:00+00:00';
    options.end ??= '2026-08-12T17:00:00+00:00';
  }
  if (!projectId || !taskId) {
    throw new Error('Pass --project and --task, or --demo.');
  }

  const before = readTask(await readStructure(baseUrl, projectId), taskId);
  const body = unchangedUpdate(before);
  if (options.title !== undefined) {
    body.proposedTitle = options.title;
  }
  if (options.progress !== undefined) {
    body.proposedProgressPercent = Number(options.progress);
  }
  if (options.start !== undefined || options.end !== undefined) {
    body.scheduleChange = {
      gesture: SET_INTERVAL,
      affectedTasks: [
        {
          taskId,
          previousStart: before.node.startUtc,
          previousEnd: before.node.endUtc,
          proposedStart: options.start ?? before.node.startUtc,
          proposedEnd: options.end ?? before.node.endUtc,
        },
      ],
    };
  }

  const update = await call(
    baseUrl,
    'PUT',
    `/api/project-structure/projects/${projectId}/tasks/${encodeURIComponent(taskId)}`,
    body,
  );
  const result = requireSuccess(update, 'Task update');
  const after = readTask(await readStructure(baseUrl, projectId), taskId);
  console.log(JSON.stringify({
    projectId,
    taskId,
    request: body,
    response: { status: update.status, body: result },
    readBack: {
      title: after.node.title,
      progressPercent: after.node.progressPercent,
      startUtc: after.node.startUtc,
      endUtc: after.node.endUtc,
      workItem: after.workItem,
    },
  }, null, 2));
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
