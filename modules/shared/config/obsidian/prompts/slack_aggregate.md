# Generate Slack Summary for Daily Log

Process slack-cli output and generate a comprehensive Slack summary for the daily log.

## Input

- **TARGET DATE**: The date to process (YYYY-MM-DD format)
- **SLACK_DATA_DIR**: Directory containing slack-cli output or pre-processed summaries
- **DAILY_LOG**: Path to the daily log file to update

**FIRST**: Read INSTRUCTIONS.md from SLACK_DATA_DIR to understand data structure and processing strategy

## Instructions

1. Check if summaries directory exists - if yes, read `*.txt` files from it; otherwise read from `channels/*/messages*.txt`
2. Filter for messages from the current user only (username will be in the data)
3. For direct messages, parse this format:
   ```
   [MESSAGE N]
   [USER: @username]
   [TIME: ISO8601]
   [PERMALINK: url]
   
   Message content
   
   ---
   ```
4. For summaries, extract information directly from the text
5. Analyze thread context for each message to understand impact
6. Categorize activity by topic/theme
7. Update the daily log with a new section called `Slack Summary` at the first level (`#`)
8. If the section doesn't exist, create it just above the footer

## Process Requirements

- Take time to systematically review ALL messages - do not rush or summarize too quickly
- Ensure ALL channels/rooms with messages are addressed - none should be missed
- Review the complete message set multiple times to ensure comprehensive coverage

## Format Requirements

### Structure
- Start with total message count immediately after section header (e.g., "*69 messages across multiple channels*")
- Organize by Slack channel/room using h2 headers (##) with markdown hyperlinks: `## [channel-name](https://amzn-aws.slack.com/archives/CHANNEL_ID)`
- Within each channel, organize content by relevant categories using h2 headers (##): Cross-Team Coordination, Technical Decisions, Action Items, Process Improvements, Tool Sharing, etc.
- For direct messages, use this EXACT hierarchy:
  - Level 1: `## Direct Messages`
  - Level 2: `## With [Person Name](https://amzn-aws.slack.com/archives/DM_CHANNEL_ID)` (h2 with ## and link to DM conversation)
  - Level 3: `### [Category]` (h3 with ### - NOT h2!)
  - Categories include: Customer Feedback, Code Reviews, Action Items, Strategic Discussions, Project Management, Technical Discussions, etc.
- CRITICAL: 
  - Direct message categories MUST be h3 (###), never h2 (##)
  - Person names are h2 (##) WITH markdown links to the DM conversation
  - Categories under person names are h3 (###)
  - DM links should use format: `## With [Person Name](https://amzn-aws.slack.com/archives/DM_CHANNEL_ID)`
  - CRITICAL: You MUST resolve user IDs to actual person names (first and last name) in ALL conversation links
  - For multi-person DM conversations (MPDMs), list all participant names: `## With [Person1], [Person2], [Person3]`
  - NEVER use user IDs (like U03UQFA064R) in headers - always resolve to real names
  - NEVER use placeholder text like '[Person](link)' - always use actual names like '[Jane Smith](link)'

### Content Detail Requirements
- Include ALL specific details: full URLs, code references, @mentions, file names, ticket numbers, document references, repository links
- Preserve ALL symlinks from source material as inline markdown links with proper syntax: `[link text](url)`
- Extract detailed business-relevant information with specific context and outcomes
- Include direct quotes or paraphrases of key technical discussions
- Preserve technical terminology and specific implementation details
- Use bullet points with detailed descriptions, not just brief summaries
- Include context around decisions (what was being discussed, why decisions were made)
- Reference specific tools, technologies, and processes mentioned

### Tone and Style
- Present facts only - no editorial commentary, subjective assessments, or opinions about importance/value
- Avoid unnecessary adverbs like "significant", "comprehensive", "important", "key" unless they appear in the original messages
- Maintain objective, factual reporting throughout

## Business-Relevant Content Includes

- Technical decisions and architectural choices with specific implementation details
- Action items and deliverables with context and outcomes
- Cross-team coordination and planning discussions
- Code reviews and technical contributions with repository links and specific changes
- Security findings and compliance issues with detailed analysis
- Tool sharing and recommendations with specific use cases
- Strategic discussions and process improvements with context
- Customer feedback sessions with detailed notes and requirements
- Project management discussions with document references
- Specific technical problems and their solutions
- Repository links, schema references, and technical documentation
- Meeting outcomes and follow-up actions

## Validation (MANDATORY)

- Double check your analysis work twice to ensure that critical information is preserved correctly
- Ensure that all Format Requirements have been met properly
- Did you ensure that you put the user comments into context with the surrounding thread properly?
- Verify ALL names are resolved correctly (never use user IDs in output)
- Verify ALL conversation links use actual person names, not placeholders like '[Person](link)'
- Confirm direct message hierarchy is correct (h2 for person names, h3 for categories)

## MANDATORY NAME VALIDATION (CRITICAL)

**YOU MUST PERFORM TWO-PASS VALIDATION ON ALL NAMES:**

1. **First Pass**: Extract all names and usernames from source data
   - Copy names EXACTLY as they appear in the source
   - Do NOT modify, infer, or "correct" any names
   - If a name appears as "Jane Smith", write "Jane Smith" - NOT "Jane Smythe" or any variation
   - Never substitute similar-sounding names

2. **Second Pass**: Before finalizing output, verify EVERY name against source data
   - Check each name character-by-character against the original
   - Confirm usernames match the source exactly
   - Cross-reference full names with their usernames
   - If uncertain about ANY name, use only the username (@handle)

**CRITICAL**: Consider ALL information carefully. Name hallucinations are unacceptable. Validate your assessment twice with a critical eye.

**CONVERSATION LINK VALIDATION**: Before finalizing, verify that ALL direct message conversation links use actual person names (e.g., `[Jane Smith](link)`) and NOT generic placeholders (e.g., `[Person](link)`). If you cannot determine the actual name, use the username instead.

