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

## Update obsidian-mind

A new obsidian-mind release migrates the vault, so it stays manual. `update`
prints a notice when one is available.

1. Read the upstream release notes and select a release.
2. Update the release in `flake.nix`.
3. Run `nix flake update obsidian-mind`.
4. Inspect the lock-file change and the upstream managed paths.
5. Run the Mind integration test:

   ```sh
   mind_source="$(nix eval --impure --raw --expr \
     'let f = builtins.getFlake (toString ./.); in f.inputs.obsidian-mind.outPath')"
   nix shell nixpkgs#jq nixpkgs#yq-go -c env \
     MIND_SOURCE="$mind_source" JQ_BIN=jq YQ_BIN=yq \
     bash modules/shared/scripts/test-mind-agent-integration.sh
   ```

6. Stage the intended files and run `nix run .#build`.
7. After activation, inspect the managed-only upgrade commit in the vault.
