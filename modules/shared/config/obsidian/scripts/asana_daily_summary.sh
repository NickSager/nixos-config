#!/bin/bash

# Asana Daily Summary Generator
# Usage: ./asana_daily_summary.sh [YYYY-MM-DD]
# Example: ./asana_daily_summary.sh 2026-03-31

set -euo pipefail

# Source common functions
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common_summary_functions.sh"

# Check dependencies
for cmd in claude; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd is required but not installed" >&2; exit 1; }
done

# Initialize environment
init_script_env
setup_paths

# Process date and validate
DATE=$(process_date_arg "${1:-}" "Asana Summary")
DAILY_LOG=$(validate_daily_log "$DATE")
WORK_DIR=$(create_work_dir "asana_summary" "$DATE")

echo "Processing Asana summary for $DATE..."

# Prompt Claude with Asana MCP to fetch and summarize tasks
PROMPT="Fetch my Asana tasks that were updated on $DATE. Summarize them and update '$DAILY_LOG' with an '# Asana Summary' section before the footer. Include task names, status changes, and any comments I made. If no Asana MCP tools are available, note that in the output and skip."

claude --print --allowedTools "Read,Write,Edit,Bash" "$PROMPT"

echo "Asana summary complete. Check $DAILY_LOG"
echo "Working files saved in $WORK_DIR"
