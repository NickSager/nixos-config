# Rolling Summary for Multi-Part Slack Data

Process a single part of split Slack data and merge with previous summary.

## Input

- **SLACK_DATA_DIR**: Read INSTRUCTIONS.md from this directory first to understand data structure and processing strategy
- **Current Part File**: Path to messages_partN.txt or messages.txt
- **Previous Summary File**: Path to file containing accumulated summary (may be empty for first part)

## Instructions

1. Read the current part file
2. Read the previous summary file (if not empty)
3. Extract key information from current part:
   - Topics discussed
   - Participants involved
   - Important decisions or actions
   - Links and references
4. Merge with previous summary, preserving all important details
5. Write consolidated summary to the previous summary file path

## Output Format

Plain text summary (no markdown code blocks):

```
Channel: <channel-name>

Topics:
- Topic 1: Brief description, participants: @user1, @user2
- Topic 2: Brief description, participants: @user3

Key Points:
- Important decision or action
- Links: [description1](url1), [description2](url2)

Participants: @user1, @user2, @user3
```

## Rules

- Preserve all important details from previous summary
- Add new information from current part
- Deduplicate participants
- Keep concise but complete
- Output only plain text, no markdown formatting or code blocks
- **Links**: Use inline markdown format `[description](url)` instead of raw URLs for better readability

## MANDATORY VALIDATION (CRITICAL)

**YOU MUST PERFORM TWO-PASS VALIDATION ON ALL NAMES:**

1. **First Pass**: Extract all names and usernames from source data
   - Copy names EXACTLY as they appear in the source
   - Do NOT modify, infer, or "correct" any names
   - If a name appears as "Jane Smith", write "Jane Smith" - NOT "Jane Smythe" or any variation

2. **Second Pass**: Before finalizing output, verify EVERY name against source data
   - Check each name character-by-character against the original
   - Confirm usernames match the source exactly
   - If uncertain about ANY name, use only the username (@handle)

**CRITICAL**: Consider ALL information carefully. Name hallucinations are unacceptable. Validate your assessment twice with a critical eye.

