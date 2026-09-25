#!/usr/bin/env bash
# launch.sh KEY [CWD] [PROMPT]
# Creates (or reuses) Herdr workspace KEY with tabs Dev/Review/Agents, starts Hermes
# in Agents as agent KEY, and submits the ticket prompt. Never steals focus.
set -euo pipefail

KEY="${1:?usage: launch.sh KEY [CWD] [PROMPT]}"
AGENT=$(tr '[:upper:]' '[:lower:]' <<<"$KEY")
CWD="${2:-$HOME/Documents/next-gen}"
PROMPT="${3:-}"
PROMPTS_NOTE="$HOME/Documents/Notes/reference/Ticket Prompts.md"
JIRA_BASE="https://becn.atlassian.net/browse"

[ "${HERDR_ENV:-}" = 1 ] || { echo "not inside Herdr" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq required" >&2; exit 1; }

if [ -z "$PROMPT" ]; then
  PROMPT=$(awk '/^## 1\. Work the ticket/{s=1} s&&/^```$/{if(inb){exit} inb=1; next} s&&inb{print}' "$PROMPTS_NOTE")
  [ -n "$PROMPT" ] || { echo "could not read /goal block from $PROMPTS_NOTE" >&2; exit 1; }
  PROMPT="${PROMPT//<JIRA-URL>/$JIRA_BASE/$KEY}"
fi

WS=$(herdr workspace list | jq -r --arg l "$KEY" '.result.workspaces[] | select(.label==$l) | .workspace_id' | head -n1)
if [ -z "$WS" ]; then
  CREATED=$(herdr workspace create --cwd "$CWD" --label "$KEY" --no-focus)
  WS=$(jq -r '.result.workspace.workspace_id' <<<"$CREATED")
  DEV_TAB=$(jq -r '.result.tab.tab_id' <<<"$CREATED")
  herdr tab rename "$DEV_TAB" Dev >/dev/null
  herdr tab create --workspace "$WS" --cwd "$CWD" --label Review --no-focus >/dev/null
  AGENTS_PANE=$(herdr tab create --workspace "$WS" --cwd "$CWD" --label Agents --no-focus | jq -r '.result.root_pane.pane_id')
  echo "created workspace $WS ($KEY)"
else
  AGENTS_TAB=$(herdr tab list | jq -r --arg w "$WS" '.result.tabs[] | select(.workspace_id==$w and .label=="Agents") | .tab_id' | head -n1)
  AGENTS_PANE=$(herdr pane list --workspace "$WS" | jq -r --arg t "$AGENTS_TAB" '.result.panes[] | select(.tab_id==$t) | .pane_id' | head -n1)
  echo "reusing workspace $WS ($KEY)"
fi

if ! herdr agent list | jq -e --arg n "$AGENT" '.result.agents[] | select(.name==$n)' >/dev/null; then
  herdr agent start "$AGENT" --kind hermes --pane "$AGENTS_PANE" --timeout 120000 | jq -e '.result' >/dev/null
  echo "started hermes agent $AGENT in $AGENTS_PANE"
fi

herdr agent prompt "$AGENT" "$PROMPT" | jq -e '.result' >/dev/null
echo "prompt submitted to $AGENT"
