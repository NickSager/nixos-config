#!/bin/bash

# Taskei Daily Summary Generator
# Usage: ./taskei_daily_summary.sh YYYY-MM-DD [TIMEZONE]
# Example: ./taskei_daily_summary.sh 2025-10-29 America/New_York

# Source common functions
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common_summary_functions.sh"

# Initialize environment
init_script_env
setup_paths

# Process date and validate
DATE=$(process_date_arg "$1" "Taskei Summary")
DAILY_LOG=$(validate_daily_log "$DATE")
WORK_DIR=$(create_work_dir "taskei_summary" "$DATE")

# Timezone (default to US Eastern)
TIMEZONE="${2:-America/New_York}"

# Validate timezone
if ! TZ="$TIMEZONE" date &>/dev/null; then
    echo "Error: Invalid timezone '$TIMEZONE'" >&2
    REGION="${TIMEZONE%%/*}"
    if [[ "$REGION" != "$TIMEZONE" ]]; then
        echo "Valid timezones for $REGION:" >&2
        find /usr/share/zoneinfo/"$REGION" -type f 2>/dev/null | sed "s|/usr/share/zoneinfo/||" | sort >&2
    fi
    exit 1
fi

# Taskei Room ID - Update this to your team's room ID
# Find your room ID with: taskei rooms list
ROOM_ID="9b1c22ee-b03e-4f59-875d-770483cc0d25"
USERNAME="$USER"

echo "Processing Taskei summary for $DATE (timezone: $TIMEZONE)..."

# Convert date to taskei query format with timezone offset
START_DATE=$(TZ="$TIMEZONE" date -d "${DATE} 00:00:00" -Iseconds)
END_DATE=$(TZ="$TIMEZONE" date -d "${DATE} 23:59:59" -Iseconds)

# Get task data and process it
TASK_DATA=$(taskei tasks list --refresh-cache -q "lastUpdatedDate:[${START_DATE} TO ${END_DATE}]" \
  --room ${ROOM_ID} --limit 1000 --show-comments --format json | \
  jq --arg username "$USERNAME" '
    # Preserve the total count
    {total,
     # Filter edges to only include tasks with comments from the specified user
     edges: [
       .edges[] |
       # Keep only tasks that have at least one comment from the user
       select(.node.comments | any(.author.username == $username))
     ]
    }
  ' | \
  jq --arg username "$USERNAME" '
    # Process each edge/node in the filtered results
    .edges[] | .node |
    # Create a focused object with only the needed fields
    {
      shortId,
      name,
      status,
      workflowAction,
      assignee,
      labels,
      # Filter custom attributes to only those with values
      owningRoomCustomAttributes: [
        .owningRoomCustomAttributes[] |
        select(has("value")) |
        {
          label: .attribute.label,
          value
        }
      ],
      # Extract key comment fields for reporting - filter by username
      comments: [
        .comments[] |
        select(.author.username == $username) |
        {
          author_username: .author.username,
          message_content: .message.content,
          lastUpdatedDateTime
        }
      ]
    }
  ')

# Save raw task data for debugging
echo "$TASK_DATA" > "$WORK_DIR/raw_tasks.json"

if [ -z "${TASK_DATA}" ]; then
  TASK_DATA="No Task Data Found for ${DATE}"
fi

# Create the combined prompt and data
{
  cat << PROMPT_EOF
# 📊 Task Analysis & Business Value Assessment

## 🎯 Objective

Analyze task data and create a factual summary focusing on business value items. Present only facts without assessments, recommendations, or subjective language.

## Constraints

- [ ] Do NOT create a tool for performing the processing.
- [ ] Ensure that inline markdown links are provided for each ticket identifier
- [ ] Ensure that all markdown is Commonmark compliant
- [ ] Update the daily log at DAILY_LOG_PATH with the Taskei Summary section

## 🔍 Analysis Process

### 1️⃣ Data Processing
- [ ] Read and parse the complete input data
- [ ] Count total tasks by status (open/closed)
- [ ] Categorize tasks by type and component
- [ ] Extract all comment content for detailed review

### 3️⃣ Comment Analysis
- [ ] Identify direct work updates vs summaries from other tickets
- [ ] Note actual work performed vs administrative task management
- [ ] Separate new development work from historical context updates
- [ ] Flag reference ticket numbers and cross-references

### 4️⃣ Self-Verification Process
- [ ] Argue with yourself about business value rankings
- [ ] Challenge initial assumptions about task importance
- [ ] Double-check work assuming you missed something important
- [ ] Verify comment content classification accuracy

## 📝 Output Structure

- [ ] The output must start with the header '# Taskei Summary - $USERNAME Updates'
- [ ] Organize by task
- [ ] Update "${DAILY_LOG}" with Taskei Summary section

## Task Data to Analyze:

PROMPT_EOF
  echo "$TASK_DATA"
} | q chat --no-interactive --trust-tools="@task-manager/TodoRead,@task-manager/TodoWrite,fs_read,fs_write"

echo "Taskei summary complete. Check $DAILY_LOG"
echo "Working files saved in $WORK_DIR"
