#!/bin/bash

# Monthly Summary Generator
# Usage: ./monthly_summary_generator.sh [YYYY-MM]
# Example: ./monthly_summary_generator.sh 2025-10

# Source common functions
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common_summary_functions.sh"

# Initialize environment
init_script_env
setup_paths

DAILY_NOTES_PATH="$( realpath "${SCRIPT_DIR}"/../Main/Daily_Notes/ )"

# Determine target month
if [[ -z "$1" ]]; then
    # Find previous month without monthly_summary.md
    for month_dir in $( find "${DAILY_NOTES_PATH}" -maxdepth 2 -type d -name "20[0-9][0-9]-[0-9][0-9]" | sort -r ); do
        if [[ ! -f "${month_dir}/monthly_summary.md" ]]; then
            TARGET_MONTH=$( basename "$month_dir" )
            break
        fi
    done
    
    if [[ -z "$TARGET_MONTH" ]]; then
        echo "Error: All months already have monthly summaries" >&2
        exit 1
    fi
else
    TARGET_MONTH="$1"
fi

# Validate month format
if ! [[ "$TARGET_MONTH" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
    echo "Error: Invalid month format. Use YYYY-MM" >&2
    exit 1
fi

# Extract year from month
YEAR="${TARGET_MONTH%-*}"

# Verify month directory exists
MONTH_DIR="${DAILY_NOTES_PATH}/${YEAR}/${TARGET_MONTH}"
if [[ ! -d "$MONTH_DIR" ]]; then
    echo "Error: Month directory does not exist: $MONTH_DIR" >&2
    exit 1
fi

# Check if summary already exists
if [[ -f "${MONTH_DIR}/monthly_summary.md" ]]; then
    echo "Error: Monthly summary already exists for $TARGET_MONTH" >&2
    exit 1
fi

WORK_DIR=$(create_work_dir "monthly_summary" "$TARGET_MONTH")

echo "Generating monthly summary for $TARGET_MONTH..."

# Collect all daily notes for the month
DAILY_NOTES=$( find "${MONTH_DIR}" -maxdepth 1 -type f -name "${TARGET_MONTH}-*.md" | sort )

if [[ -z "$DAILY_NOTES" ]]; then
    echo "Error: No daily notes found for $TARGET_MONTH" >&2
    exit 1
fi

# Read the prompt
PROMPT_FILE="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../prompts/monthly_summary_prompt.md"
if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Error: Prompt file not found: $PROMPT_FILE" >&2
    exit 1
fi

# Aggregate daily notes content
DAILY_NOTES_CONTENT=""
while IFS= read -r note_file; do
    DAILY_NOTES_CONTENT+="## $(basename "$note_file" .md)"$'\n'
    DAILY_NOTES_CONTENT+="$(cat "$note_file")"$'\n\n'
done <<< "$DAILY_NOTES"

# Save aggregated notes for debugging
echo "$DAILY_NOTES_CONTENT" > "$WORK_DIR/aggregated_daily_notes.md"

# Create the combined prompt and data
{
    echo "Run the following prompt for $TARGET_MONTH. Save the output to '${MONTH_DIR}/monthly_summary.md'"
    echo ""
    cat "$PROMPT_FILE"
    echo ""
    echo "## Daily Notes for $TARGET_MONTH below:"
    echo ""
    echo "$DAILY_NOTES_CONTENT"
} | claude --print --allowedTools "Read,Write,Edit,Bash"

