#!/bin/bash

# Code Activity Summary Generator
# Usage: ./code_summary.sh YYYY-MM-DD
# Example: ./code_summary.sh 2025-12-07

# Source common functions
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common_summary_functions.sh"

# Initialize environment
init_script_env
setup_paths

# Process date and validate
DATE=$(process_date_arg "$1" "Code Summary")
DAILY_LOG=$(validate_daily_log "$DATE")

USERNAME="$USER"

echo "Processing Code summary for $DATE..."

# Calculate date range
END_DATE="$DATE"
START_DATE="$DATE"

# Build API URL
CODE_URL="https://code.amazon.com/api/asci/changes_for_user?from_date=${START_DATE}&to_date=${END_DATE}&user=${USERNAME}"

echo "Code activity URL: $CODE_URL"

# Fetch and summarize
{
  cat << PROMPT_EOF
Use ReadInternalWebsites tool to fetch $CODE_URL. Summarize the code activity and update "${DAILY_LOG}" with a Level 2 (##) "Code Summary" section containing a factual summary of development work. Use inline markdown links for relevant items. Ensure that the "Code Summary" section is placed before the footer.
PROMPT_EOF
} | kiro-cli chat --no-interactive --trust-tools="fs_read,fs_write,@builder-mcp/ReadInternalWebsites"

echo "Code summary complete. Check $DAILY_LOG"
