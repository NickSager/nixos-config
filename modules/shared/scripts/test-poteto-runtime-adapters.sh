#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(git rev-parse --show-toplevel)}"
addon="$repo_root/modules/shared/config/skills/poteto-mode-addon.md"
runtimes="$repo_root/modules/shared/config/skills/poteto-runtimes"
skills_nix="$repo_root/modules/shared/skills.nix"

operations=(delegate wait ask continue review verify author clean branches publish session)
adapters=(cursor claude codex hermes generic)

for adapter in "${adapters[@]}"; do
  file="$runtimes/$adapter.md"
  test -f "$file"
  grep -Fq '## Operations' "$file"
  grep -Fq '## Unsupported operations' "$file"
  grep -Fq "references/runtimes/$adapter.md" "$addon"

  for operation in "${operations[@]}"; do
    grep -Fq "| \`$operation\` |" "$file"
  done
done

for adapter in claude codex hermes generic; do
  file="$runtimes/$adapter.md"
  if grep -Eqi "cursor-team-kit|\.cursor/|Cursor's /loop|environment: .*cloud|Graphite" "$file"; then
    printf 'Found a Cursor-only requirement in %s\n' "$file" >&2
    exit 1
  fi
done

for requirement in '/loop' 'cloud-agent state' 'Graphite' 'cursor-team-kit' 'Cursor transcripts' 'create-skill' 'deslop'; do
  grep -Fq "$requirement" "$runtimes/cursor.md"
done

grep -Fq 'Select exactly one runtime' "$addon" || grep -Fq 'select exactly one runtime' "$addon"
grep -Fq 'BLOCKED_RUNTIME' "$addon"
grep -Fq 'potetoRuntimeAdapters = ./config/skills/poteto-runtimes;' "$skills_nix"
grep -Fq 'cp ${potetoRuntimeAdapters}/*.md "$out/references/runtimes/"' "$skills_nix"

printf 'poteto runtime adapters: all checks passed\n'
