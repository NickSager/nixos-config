# Maintenance

## Routine updates

```sh
nix run .#update
git diff flake.lock flake.nix modules/shared
nix run .#build
```

`update` moves every source to its latest stable upstream release.

| Source | Pinned in | How `update` moves it |
|---|---|---|
| nixpkgs, home-manager, nix-darwin, Homebrew taps, other inputs | `flake.lock` | `nix flake update` |
| pstack and Pocock skills | `flake.lock`, default branch | `nix flake update` |
| Herdr | release tag in `flake.nix` | latest GitHub release, then `nix flake update` |
| oMLX | `modules/shared/pins.json` | latest GitHub release, hash prefetched |
| QMD | `modules/shared/pins.json` and `qmd-package-lock.json` | latest npm release, lock file regenerated, hash from `prefetch-npm-deps` |
| Obsidian plugins | `modules/shared/pins.json` | latest GitHub release, release files hashed |

Herdr stays a tagged flake input. nixpkgs lags its releases, and its default
branch carries unreleased work. oMLX, QMD, and the plugins need content hashes
that `nix flake update` cannot compute, so `update` writes them.

Activation never fetches anything unpinned. Every update lands as a reviewable
diff in `flake.lock`, `flake.nix`, or `modules/shared/`.

After a skill-set change, confirm that one pstack skill and one Pocock skill
resolve through each client:

```sh
test -f "$HOME/.claude/skills/unslop/SKILL.md"
test -f "$HOME/.claude/skills/ask-matt/SKILL.md"
test -f "$HOME/.agents/skills/unslop/SKILL.md"
test -f "$HOME/.agents/skills/ask-matt/SKILL.md"
```

Also confirm that Hermes lists the shared skill root in `skills.external_dirs`.
Pocock owns any shared skill names. The activation keeps separate
`.pstack-managed-files` and `.pocock-managed-files` manifests, so one source
cannot remove files owned by the other.

To add an Obsidian plugin, add an entry under `obsidianPlugins` in `pins.json`
keyed by its manifest ID, with a placeholder `hash`, and run `update`.

## obsidian-mind

`update` moves obsidian-mind within its current major version and only prints
a notice for a new major, because majors reshape the vault's instruction files.

`nix run .#build` never touches the vault. Only `build-switch` activation
writes there, and only to the upstream-managed paths listed in
`.obsidian-mind-managed-files`. Two build-time checks catch upstream drift:

- The local patches in `modules/shared/config/obsidian-mind/` are applied with
  `pkgs.applyPatches`, so a patch that no longer fits fails the build.
- An assertion fails evaluation when a file or directory in `mindFiles` or
  `mindDirs` (`modules/shared/obsidian.nix`) is missing upstream.

### Major upgrades

1. Read the upstream release notes for every skipped version.
2. Update the release in `flake.nix` and run `nix flake update obsidian-mind`.
3. Run `nix run .#build`. Fix the assertion by editing `mindFiles` and
   `mindDirs`, keeping removed paths in activation's cleanup `case` list so
   stale copies are deleted.
4. Port failing patches against a scratch copy of the new source, then
   regenerate each patch with
   `diff -u --label a/<path> --label b/<path> upstream/<path> ported/<path>`.
   Keep each patch's intent; its header comment in `obsidian.nix` says why it
   exists. Drop a patch once upstream carries the fix.
5. Verify, then build again:

   ```sh
   mind_source="$(nix eval --impure --raw --expr \
     'let f = builtins.getFlake (toString ./.); in f.inputs.obsidian-mind.outPath')"
   # Upstream's own suite on the ported tree; compare with unpatched upstream.
   (cd <ported>/.claude/scripts && node --test --experimental-strip-types tests/*.test.ts)
   # Patched-vs-unpatched qmd behaviour, idempotent re-application.
   node modules/shared/scripts/test-qmd-unix.mjs "$mind_source"
   nix shell nixpkgs#jq nixpkgs#yq-go -c env \
     MIND_SOURCE="$mind_source" JQ_BIN=jq YQ_BIN=yq \
     bash modules/shared/scripts/test-mind-agent-integration.sh
   ```

6. After activation, inspect the managed-only upgrade commit in the vault.
