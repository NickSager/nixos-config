#!/bin/bash

# Common Summary Functions
# Shared functionality for summary generation scripts

# Initialize script environment
init_script_env() {
    set -e
    shopt -s expand_aliases
    source "$HOME/.bash/aliases.conf"
}

# Setup common directory paths
setup_paths() {
    SCRIPT_DIR="$( dirname "$( realpath "${BASH_SOURCE[0]}" )" )"
    DAILY_NOTES_PATH="$( realpath ${SCRIPT_DIR}/../Main/Daily_Notes/ )"
}

# Process date argument and find previous date if needed
# Usage: process_date_arg "$1" "Summary Type"
process_date_arg() {
    local input_date="$1"
    local summary_type="$2"

    if [[ -z "$input_date" ]]; then
        echo "No date provided, fetching the previous date to process" >&2

        local current_date
        current_date=$(date +%Y-%m-%d)

        local found_date
        found_date=$( grep -rL "$summary_type" "${DAILY_NOTES_PATH}" | grep -oE '[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}' | grep -v "$current_date" | sort -rh | head -1 )

        if [[ -z "$found_date" ]]; then
            echo "Could not find a date to process...exiting" >&2
            exit 1
        fi

        echo "$found_date"
    else
        echo "$input_date"
    fi
}

# Validate daily log file exists
# Usage: validate_daily_log "$DATE"
validate_daily_log() {
    local date="$1"
    local daily_log

    daily_log="$( find "${DAILY_NOTES_PATH}" -type f -name "${date}.md" )"

    if [[ ! -f "$daily_log" ]]; then
        echo "Error: Daily log file does not exist: $daily_log" >&2
        exit 1
    fi

    echo "$daily_log"
}

# Create work directory
# Usage: create_work_dir "$cache_name" "$DATE"
create_work_dir() {
    local cache_name="$1"
    local date="$2"
    local work_dir="$HOME/.cache/${cache_name}/${date}"

    mkdir -p "$work_dir"
    echo "$work_dir"
}
