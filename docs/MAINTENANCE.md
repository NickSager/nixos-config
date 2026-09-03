# Maintenance

Run these updates manually. Activation must never fetch an unpinned skill set,
vault release, or QMD package.

## Update obsidian-mind

1. Read the upstream release notes and select a release.
2. Update the release in `flake.nix` if needed.
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

## Update Herdr

Herdr is pinned to a release tag in `flake.nix`. A plain `nix flake update`
only refreshes the revision for that tag; it does not select a newer Herdr
release.

1. Read the upstream release notes and select the latest stable release.
2. Update the tag in `herdr.url` in `flake.nix`.
3. Run `nix flake update herdr`.
4. Inspect the `flake.lock` change and confirm it resolves the selected tag.
5. Stage the intended files and run `nix run .#build`.
6. After activation, run `herdr --version` and confirm the selected version.

## Update pstack or Pocock skills

Update one source at a time:

```sh
nix flake update pstack
nix flake update pocock
```

For pstack, inspect changed directories under `pstack/skills` and
`pstack/agents`. For Pocock, inspect directories containing `SKILL.md` under
`skills/`. The activation keeps separate `.pstack-managed-files` and
`.pocock-managed-files` manifests. Pocock owns any shared skill names, so one
source cannot remove files owned by the other.

After either update, stage the lock file, run `nix run .#build`, and activate.
Confirm that one pstack skill and one Pocock skill resolve through each client:

```sh
test -f "$HOME/.claude/skills/unslop/SKILL.md"
test -f "$HOME/.claude/skills/ask-matt/SKILL.md"
test -f "$HOME/.agents/skills/unslop/SKILL.md"
test -f "$HOME/.agents/skills/ask-matt/SKILL.md"
```

Also confirm that Hermes lists the shared skill root in
`skills.external_dirs`. Record the new input revision and verification result
in the handoff or audit TSV.

## Update QMD

1. Choose the new `@tobilu/qmd` version and read its release notes.
2. In `modules/shared/qmd.nix`, update `version`.
3. Get the tarball integrity:

   ```sh
   npm view @tobilu/qmd@VERSION dist.integrity
   ```

4. Set `src.hash` to that integrity value.
5. Set `npmDeps.hash = lib.fakeHash`, stage the file, and run
   `nix run .#build`.
6. Replace the fake hash with the `got:` hash from the failed build.
7. Stage the file and run `nix run .#build` again.

Do not run `build-switch` merely to compute QMD hashes. Record the version,
source hash, dependency hash, and build result in the handoff or audit TSV.
