import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const script = fileURLToPath(new URL('../../codex/skills/candoitall-api-project-structure/scripts/update-task.mjs', import.meta.url));
const projectId = '66666666-6666-4666-8666-666666666666';
const taskId = 'custom:11111111111111111111111111111111';

async function run({ scheduled = false, capability = true, end = true } = {}) {
  const requests = [];
  let node = {
    id: taskId, title: 'Synthetic imported task', progressPercent: 0,
    startUtc: scheduled ? '2027-02-01T09:00:00Z' : null,
    endUtc: scheduled ? '2027-02-01T10:00:00Z' : null,
    durationSeconds: 3600,
    metadataJson: JSON.stringify({ workItem: { executionState: 'notStarted', expectedEffortUnit: 'hours' } }),
  };
  const server = createServer(async (request, response) => {
    const chunks = [];
    for await (const chunk of request) {
      chunks.push(chunk);
    }
    const raw = Buffer.concat(chunks).toString();
    const body = raw ? JSON.parse(raw) : null;
    requests.push({ method: request.method, path: request.url, body });
    response.setHeader('Content-Type', 'application/json');
    if (request.url === '/openapi/v1.json') {
      response.end(JSON.stringify({ components: { schemas: { ProjectStructureTaskUpdateAgentInput: { properties: capability ? { initialSchedule: {} } : {} } } } }));
    } else if (request.method === 'PUT') {
      const interval = body.initialSchedule ?? body.scheduleChange.affectedTasks[0];
      node = { ...node, startUtc: interval.proposedStartUtc ?? interval.proposedStart, endUtc: interval.proposedEndUtc ?? interval.proposedEnd };
      response.end(JSON.stringify({ affectedTaskIds: [{ value: taskId }] }));
    } else {
      response.end(JSON.stringify({ nodes: [node], expectedProjectAdmission: { projectId, lifetimeId: '22222222-2222-4222-8222-222222222222', databaseProfileId: '33333333-3333-4333-8333-333333333333' } }));
    }
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    const args = [script, '--base-url', `http://127.0.0.1:${server.address().port}`, '--project', projectId, '--task', taskId, '--start', '2027-02-05T09:00:00Z'];
    if (end) {
      args.push('--end', '2027-02-05T10:00:00Z');
    }
    const result = await new Promise((resolve, reject) => {
      const child = spawn(process.execPath, args, { env: { ...process.env, CANDOITALL_API_TOKEN: '' }, windowsHide: true });
      let stderr = '';
      child.stdout.resume();
      child.stderr.on('data', (data) => { stderr += data; });
      child.on('error', reject);
      child.on('close', (code) => resolve({ code, stderr }));
    });
    return { ...result, requests };
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('initial scheduling echoes null dates and the stored duration', async () => {
  const result = await run();
  assert.equal(result.code, 0, result.stderr);
  const update = result.requests.find((request) => request.method === 'PUT').body;
  assert.equal(update.scheduleChange, null);
  assert.deepEqual(update.initialSchedule, { currentStartUtc: null, currentEndUtc: null, currentDurationSeconds: 3600, proposedStartUtc: '2027-02-05T09:00:00Z', proposedEndUtc: '2027-02-05T10:00:00Z' });
});

test('persisted schedules retain the established move contract', async () => {
  const result = await run({ scheduled: true });
  assert.equal(result.code, 0, result.stderr);
  const update = result.requests.find((request) => request.method === 'PUT').body;
  assert.equal(update.initialSchedule, undefined);
  assert.equal(update.scheduleChange.affectedTasks[0].previousStart, '2027-02-01T09:00:00Z');
  assert.equal(result.requests.some((request) => request.path === '/openapi/v1.json'), false);
});

test('an older host is reported before writing substitute dates', async () => {
  const result = await run({ capability: false });
  assert.equal(result.code, 1);
  assert.match(result.stderr, /does not support initialSchedule/);
  assert.equal(result.requests.some((request) => request.method === 'PUT'), false);
});

test('initial scheduling requires both proposed dates', async () => {
  const result = await run({ end: false });
  assert.equal(result.code, 1);
  assert.match(result.stderr, /requires both --start and --end/);
  assert.equal(result.requests.some((request) => request.method === 'PUT'), false);
});
