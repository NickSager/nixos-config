import assert from 'node:assert/strict';
import { mkdtempSync, cpSync, symlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const source = process.argv[2];
assert.ok(source, 'Pass the pinned obsidian-mind source directory');
const repo = resolve(fileURLToPath(new URL('../../../', import.meta.url)));
const root = mkdtempSync(join(tmpdir(), 'qmd-unix-test-'));
cpSync(join(source, '.claude'), join(root, '.claude'), { recursive: true });
const args = ['collection', 'add', "/tmp/Nick's Notes", '--mask', '**/*.md'];
const pristine = await import(pathToFileURL(join(root, '.claude/scripts/lib/qmd.ts')));
assert.notDeepEqual(pristine.buildQmdCommand('/bin/qmd', args), { cmd: '/bin/qmd', args, shell: false });
console.log('RED: pristine launcher does not preserve the executable contract');
for (const relative of ['lib/qmd.ts', 'qmd-mcp.mjs', 'lib/main-guard.ts', 'lib/mcp-context.ts', 'tests/qmd.test.ts', 'tests/qmd-mcp.test.ts', 'tests/qmd-refresh.test.ts']) {
  const patch = join(repo, 'modules/shared/config/obsidian-mind/qmd-unix', relative.split('/').at(-1) + '.patch');
  for (let repeat = 0; repeat < 2; repeat++) {
    const result = spawnSync('bash', [join(repo, 'modules/shared/scripts/mind-agent-integration.sh'), 'apply-patch-if-needed', join(root, '.claude/scripts', relative), patch], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
  }
}
const qmd = await import(pathToFileURL(join(root, '.claude/scripts/lib/qmd.ts')) + '?patched');
const mcp = await import(pathToFileURL(join(root, '.claude/scripts/qmd-mcp.mjs')));
assert.deepEqual(qmd.buildQmdCommand('/bin/qmd', args), { cmd: '/bin/qmd', args, shell: false });
assert.deepEqual(qmd.buildQmdCommand(null, args), { cmd: 'qmd', args, shell: false });
assert.deepEqual(mcp.buildLaunchCommand('/bin/qmd', ["Nick's **/*.md"], 'notes'), { cmd: '/bin/qmd', args: ['--index', 'notes', 'mcp', "Nick's **/*.md"], shell: false });
const executable = qmd.resolveQmdEntry();
assert.ok(executable, 'Installed qmd must be on PATH');
assert.equal(mcp.resolveQmdEntry(), executable);
const version = spawnSync(executable, ['--version'], { encoding: 'utf8' });
assert.equal(version.status, 0, version.stderr);
const savedPath = process.env.PATH;
process.env.PATH = root;
assert.equal(qmd.resolveQmdEntry(), null);
assert.equal(mcp.resolveQmdEntry(), null);
process.env.PATH = savedPath;
const guardPath = join(root, '.claude/scripts/lib/main-guard.ts');
const alias = join(root, 'guard-alias.ts');
symlinkSync(guardPath, alias);
const guard = await import(pathToFileURL(guardPath));
const originalArg = process.argv[1];
process.argv[1] = alias;
assert.equal(guard.isMainModule(pathToFileURL(guardPath).href), true);
process.argv[1] = join(root, 'missing');
assert.equal(guard.isMainModule(pathToFileURL(guardPath).href), false);
process.argv[1] = originalArg;
console.log('GREEN: launcher, literal argv, missing executable, symlink entry and patch idempotency');
const context = await import(pathToFileURL(join(root, '.claude/scripts/lib/mcp-context.ts')));
const rootAlias = join(root, 'vault-alias');
symlinkSync(root, rootAlias);
assert.equal(context.resolveVaultRoot(pathToFileURL(guardPath).href, { OM_VAULT_PATH: rootAlias }), context.resolveVaultRoot(pathToFileURL(guardPath).href, { OM_VAULT_PATH: root }));
assert.equal(mcp.resolveVaultRoot(pathToFileURL(guardPath).href, { CLAUDE_PROJECT_DIR: rootAlias }), context.resolveVaultRoot(pathToFileURL(guardPath).href, { OM_VAULT_PATH: root }));
const upstream = spawnSync(process.execPath, ['--experimental-strip-types', '--test', ...['main-guard', 'mcp-context', 'qmd-bootstrap', 'qmd-refresh', 'qmd', 'qmd-mcp'].map(name => join(root, '.claude/scripts/tests', name + '.test.ts'))], { encoding: 'utf8' });
assert.equal(upstream.status, 0, upstream.stdout + upstream.stderr);
console.log(upstream.stdout);
console.log(version.stdout.trim());
console.log('Test copy retained at ' + root);
