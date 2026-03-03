#!/bin/bash
#
# Slack Summary Generator using slack-cli
# Usage: ./slack_summary.sh YYYY-MM-DD

set -euo pipefail

# Source common functions
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common_summary_functions.sh"

# Check dependencies
for cmd in slack-cli jq date; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd is required but not installed" >&2; exit 1; }
done

# Initialize environment
init_script_env
setup_paths

# Process date and validate
DATE=$(process_date_arg "${1:-}" "Slack Summary")
DAILY_LOG=$(validate_daily_log "$DATE")
WORK_DIR=$(create_work_dir "slack_summary" "$DATE")

# Script-specific paths
PROMPT_FILE="${SCRIPT_DIR}/../prompts/slack_aggregate.md"
ROLLING_PROMPT="${SCRIPT_DIR}/../prompts/slack_rolling_summary_prompt.md"

echo "Processing Slack summary for $DATE..."

# Get username for Slack queries
SLACK_USERNAME="${SLACK_USERNAME:-$USER}"

# Fetch Slack data using slack-cli with --format llm
SLACK_DATA_DIR="$WORK_DIR/slack_data"
mkdir -p "$SLACK_DATA_DIR"

echo "Fetching messages from $SLACK_USERNAME for $DATE..."
MAX_RETRIES=3
RETRY_COUNT=0
RETRY_DELAY=2
SUCCESS=false

while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    if slack-cli search "from:@${SLACK_USERNAME} on:$DATE" --format llm --output-dir "$SLACK_DATA_DIR" --max-pages 20 2>&1 | grep -v "^-" || true; then
        SUCCESS=true
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; then
        echo "Warning: Slack API failure, retrying in ${RETRY_DELAY}s (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)..." >&2
        sleep "$RETRY_DELAY"
        RETRY_DELAY=$((RETRY_DELAY * 2))
    fi
done

if [[ "$SUCCESS" != "true" ]]; then
    echo "Error: Failed to fetch Slack data after $MAX_RETRIES attempts" >&2
    exit 1
fi

# Check if we have any data
if [[ ! -d "$SLACK_DATA_DIR/channels" ]] || [[ ! "$(ls -A "$SLACK_DATA_DIR/channels" 2>/dev/null)" ]]; then
    echo "No Slack messages found for $DATE"
    exit 0
fi

# Check for multi-part files and process with rolling summary if needed
SUMMARIES_DIR="$WORK_DIR/summaries"
NEEDS_ROLLING=false

for CHANNEL_DIR in "$SLACK_DATA_DIR/channels"/*; do
    [[ ! -d "$CHANNEL_DIR" ]] && continue
    if ls "$CHANNEL_DIR"/messages_part*.txt >/dev/null 2>&1; then
        NEEDS_ROLLING=true
        break
    fi
done

TRUSTED_TOOLS="fs_read,fs_write,execute_bash,@builder_mcp/WorkspaceSearch"

if [[ "$NEEDS_ROLLING" == "true" ]]; then
    echo "Multi-part files detected, using rolling summary..."
    mkdir -p "$SUMMARIES_DIR"
    
    for CHANNEL_DIR in "$SLACK_DATA_DIR/channels"/*; do
        [[ ! -d "$CHANNEL_DIR" ]] && continue
        CHANNEL_NAME=$(basename "$CHANNEL_DIR")
        SUMMARY_FILE="$WORK_DIR/summary_accumulator.txt"
        : > "$SUMMARY_FILE"
        
        for PART in "$CHANNEL_DIR"/messages*.txt; do
            [[ ! -f "$PART" ]] && continue
            echo "  Processing $(basename "$PART") for $CHANNEL_NAME..."
            
            PROMPT_FILE_TMP="$WORK_DIR/rolling_prompt.txt"
            cat > "$PROMPT_FILE_TMP" << EOF
Execute the instructions in '$ROLLING_PROMPT'.
Current part file: '$PART'
Previous summary file: '$SUMMARY_FILE'
Output only the summary text.
EOF
            
            OUTPUT_FILE="$WORK_DIR/q_output.txt"
            if q chat --no-interactive --trust-tools="$TRUSTED_TOOLS" "$(cat "$PROMPT_FILE_TMP")" > "$OUTPUT_FILE" 2>&1; then
                tail -1 "$OUTPUT_FILE" > "$SUMMARY_FILE"
            else
                echo "Warning: Failed to process $PART" >&2
                cat "$OUTPUT_FILE" >&2
            fi
        done
        
        cp "$SUMMARY_FILE" "$SUMMARIES_DIR/${CHANNEL_NAME}.txt"
    done
    
    if [[ ! "$(ls -A "$SUMMARIES_DIR" 2>/dev/null)" ]]; then
        echo "Error: No summaries generated" >&2
        exit 1
    fi
    
    # Use summaries for aggregate
    DATA_SOURCE="$SUMMARIES_DIR"
else
    # Use raw data for aggregate
    DATA_SOURCE="$SLACK_DATA_DIR"
fi

# Generate comprehensive summary and update daily log
echo "Generating summary and updating daily log..."
AGGREGATE_PROMPT="$WORK_DIR/aggregate_prompt.txt"
cat > "$AGGREGATE_PROMPT" << EOF
Execute the instructions in '$PROMPT_FILE'.
TARGET DATE: $DATE
Read Slack data from directory: '$DATA_SOURCE'
DAILY_LOG: $DAILY_LOG
Update the daily log with the Slack Summary section.
EOF

OUTPUT_FILE="$WORK_DIR/q_aggregate_output.txt"
if ! q chat --no-interactive --trust-tools="$TRUSTED_TOOLS" "$(cat "$AGGREGATE_PROMPT")" > "$OUTPUT_FILE" 2>&1; then
    echo "Error: Failed to generate summary" >&2
    cat "$OUTPUT_FILE" >&2
    exit 1
fi

echo "Slack summary complete. Check $DAILY_LOG"
echo "Working files saved in $WORK_DIR"

