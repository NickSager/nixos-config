#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(git rev-parse --show-toplevel)}"
skill_root="$repo_root/modules/shared/config/skills/implement-tickets"
planner="$skill_root/scripts/plan.py"
importer="$skill_root/scripts/import.py"
skill="$skill_root/SKILL.md"
test_root="$(mktemp -d)"
fixture="$test_root/repo/fixture"
first="$test_root/first.json"
second="$test_root/second.json"
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$fixture/issues"
git -C "$test_root/repo" init -q
git -C "$test_root/repo" config user.name Test
git -C "$test_root/repo" config user.email test@example.invalid
printf '# Approved fixture specification\n' > "$fixture/spec.md"
cat > "$fixture/issues/01-first.md" <<'EOF'
# 01: First change

**What to build:** Build the first change.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] First acceptance criterion.
EOF
git -C "$test_root/repo" add fixture
git -C "$test_root/repo" commit -qm fixture
cat > "$fixture/issues/02-second.md" <<'EOF'
# 02: Second change

**What to build:** Build the second change.

**Blocked by:** 01: First change

**Status:** ready-for-agent

- [ ] Second acceptance criterion.
- [ ] Evidence is recorded.
EOF
cat > "$fixture/issues/03-third.md" <<'EOF'
# 03: Independent change

**What to build:** Build an independent change.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] Third acceptance criterion.
EOF

grep -Fq 'requires_toolsets: [kanban]' "$skill"
grep -Fq 'scripts/import.py' "$skill"
grep -Fq 'scripts/integrate-reviewed.py' "$skill"
python3 "$planner" "$fixture" --repo-root "$test_root/repo" > "$first"
python3 "$planner" "$fixture" --repo-root "$test_root/repo" > "$second"
cmp "$first" "$second"

python3 - "$first" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    plan = json.load(handle)
by_id = {ticket["id"]: ticket for ticket in plan["tickets"]}
assert plan["schema_version"] == 1
assert len(plan["tickets"]) == 3
assert by_id["01"]["blocked_by"] == []
assert by_id["02"]["blocked_by"] == ["01"]
assert by_id["03"]["blocked_by"] == []
assert by_id["02"]["idempotency_key"].startswith("fixture:02:implementation:")
assert "implementation_idempotency_key" not in by_id["02"]
assert len(by_id["02"]["content_fingerprint"]) == 12
assert by_id["02"]["integration_idempotency_prefix"].endswith(":integration:")
PY

cp "$first" "$test_root/original.json"
printf '\n- [ ] Added after approval.\n' >> "$fixture/issues/02-second.md"
python3 "$planner" "$fixture" --repo-root "$test_root/repo" > "$test_root/changed.json"
python3 - "$test_root/original.json" "$test_root/changed.json" <<'PY'
import json
import sys

def key(path):
    with open(path, encoding="utf-8") as handle:
        plan = json.load(handle)
    return next(ticket["idempotency_key"] for ticket in plan["tickets"] if ticket["id"] == "02")

assert key(sys.argv[1]) != key(sys.argv[2])
PY
sed -i.bak 's/\*\*Blocked by:\*\* None (can start immediately)/\*\*Blocked by:\*\* 02: Second change/' "$fixture/issues/01-first.md"
rm "$fixture/issues/01-first.md.bak"
if python3 "$planner" "$fixture" --repo-root "$test_root/repo" >/dev/null 2>&1; then
  printf 'accepted a dependency cycle\n' >&2
  exit 1
fi

if [ -n "${HERMES_BIN:-}" ]; then
  export HERMES_HOME="$test_root/hermes"
  "$HERMES_BIN" kanban init >/dev/null
  "$HERMES_BIN" project create --slug fixture --primary "$test_root/repo" Fixture >/dev/null
  program_parent="$("$HERMES_BIN" kanban create --json \
    --idempotency-key fixture:program 'Fixture program' |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')"
  import_args=("$first" --hermes "$HERMES_BIN" --profile personal --project fixture --program-parent "$program_parent" --check 'nix flake check' --check 'nix run .#build')
  python3 "$importer" "${import_args[@]}" > "$test_root/import-first.json"
  python3 "$importer" "${import_args[@]}" > "$test_root/import-second.json"
  cmp "$test_root/import-first.json" "$test_root/import-second.json"
  python3 "$importer" "$test_root/changed.json" \
    --hermes "$HERMES_BIN" \
    --profile personal \
    --project fixture \
    --program-parent "$program_parent" \
    --check 'nix flake check' \
    --check 'nix run .#build' > "$test_root/import-changed.json"

  python3 - "$test_root/import-first.json" "$HERMES_BIN" "$program_parent" <<'PY'
import json
import subprocess
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    imported = json.load(handle)
assert len(imported["tasks"]) == 3
ids = {entry["ticket"]: entry["task"] for entry in imported["tasks"]}
gate_id = imported["import_gate"]

def show(ticket):
    output = subprocess.check_output([sys.argv[2], "kanban", "show", "--json", ids[ticket]], text=True)
    return json.loads(output)

first = show("01")
second = show("02")
program = json.loads(
    subprocess.check_output(
        [sys.argv[2], "kanban", "show", "--json", sys.argv[3]], text=True
    )
)
gate = json.loads(
    subprocess.check_output(
        [sys.argv[2], "kanban", "show", "--json", gate_id], text=True
    )
)
assert program["task"]["status"] == "done"
assert gate["task"]["status"] == "done"
assert first["task"]["status"] == "ready"
assert first["task"]["assignee"] == "personal"
assert first["task"]["project_id"].startswith("p_")
assert first["task"]["workspace_kind"] == "worktree"
assert first["task"]["branch_name"].startswith("agent/fixture-01-")
assert first["events"][0]["payload"]["goal_mode"] is True
assert "poteto-mode" in first["task"]["skills"]
body = second["task"]["body"]
assert "fixture/issues/02-second.md" in body
assert "fixture/spec.md" in body
assert "Second acceptance criterion." in body
assert "`nix flake check`" in body
assert "`nix run .#build`" in body
assert "block the card with the exact question" in body
assert sorted(first["parents"]) == sorted([sys.argv[3], gate_id])
assert second["parents"] == [ids["01"]]
assert second["task"]["status"] == "todo"
assert sorted(show("03")["parents"]) == sorted([sys.argv[3], gate_id])
assert show("03")["task"]["status"] == "ready"
PY
  task_count="$("$HERMES_BIN" kanban list --json |
    python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')"
  [ "$task_count" -eq 9 ]
  python3 - "$test_root/import-first.json" "$test_root/import-changed.json" "$HERMES_BIN" <<'PY'
import json
import subprocess
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    first = json.load(handle)
with open(sys.argv[2], encoding="utf-8") as handle:
    changed = json.load(handle)
assert first["import_gate"] != changed["import_gate"]
assert {item["task"] for item in first["tasks"]}.isdisjoint(
    item["task"] for item in changed["tasks"]
)

def task_id(result, ticket):
    return next(item["task"] for item in result["tasks"] if item["ticket"] == ticket)

def show(task):
    return json.loads(
        subprocess.check_output([sys.argv[3], "kanban", "show", "--json", task], text=True)
    )

first_root = task_id(first, "01")
changed_root = task_id(changed, "01")
assert show(first_root)["task"]["branch_name"] != show(changed_root)["task"]["branch_name"]
first_workspace = subprocess.check_output(
    [sys.argv[3], "kanban", "claim", first_root], text=True
).strip()
changed_workspace = subprocess.check_output(
    [sys.argv[3], "kanban", "claim", changed_root], text=True
).strip()
assert first_workspace != changed_workspace
PY
fi

printf 'implement-tickets planner and importer: all checks passed\n'
