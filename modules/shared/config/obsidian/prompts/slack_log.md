# Slack Summary

Find the daily log for the provided date under Main/Daily_Notes. The log will be named `<YYYY>-<MM>-<DD>.md`.

For this date, find ALL Slack messages sent by the current user. For each
message, ensure that you understand the impact by examining the thread. If you
encounter an API failure, retry up to 3 times with an exponential delay between
each try.

Update the daily log with a section called `Slack Summary` at the first level (`#`). If necessary, create a new section for it just above the footer.

## Process Requirements:
- Take time to systematically review ALL messages - do not rush or summarize too quickly
- Ensure ALL channels/rooms with messages are addressed - none should be missed
- Use working memory to create interstitial artifacts for analysis (message categorization, channel lists, etc.)
- Review the complete message set multiple times to ensure comprehensive coverage

# Format Requirements

## Structure
- Start with total message count immediately after section header (e.g., "*69 messages across multiple channels*")
- Organize by Slack channel/room using h2 headers (##) with markdown hyperlinks to actual Slack URLs: `## [channel-name](https://amzn-aws.slack.com/archives/CHANNEL_ID)`
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
  - IMPORTANT: You MUST resolve user IDs to actual person names (first and last name)
  - For multi-person DM conversations (MPDMs), list all participant names: `## With [Person1], [Person2], [Person3]`
  - NEVER use user IDs (like U03UQFA064R) in headers - always resolve to real names

## Content Detail Requirements
- Include ALL specific details: full URLs, code references, @mentions, file names, ticket numbers, document references, repository links
- Preserve ALL symlinks from source material as inline markdown links with proper syntax: `[link text](url)`
- Extract detailed business-relevant information with specific context and outcomes
- Include direct quotes or paraphrases of key technical discussions
- Preserve technical terminology and specific implementation details
- Use bullet points with detailed descriptions, not just brief summaries
- Include context around decisions (what was being discussed, why decisions were made)
- Reference specific tools, technologies, and processes mentioned

## Tone and Style
- Present facts only - no editorial commentary, subjective assessments, or opinions about importance/value
- Avoid unnecessary adverbs like "significant", "comprehensive", "important", "key" unless they appear in the original messages
- Maintain objective, factual reporting throughout

# Business-Relevant Content Includes:
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

# Validation (MANDATORY)

- Double check your analysis work twice to ensure that critical information is preserved correctly
- Ensure that all Format Requirements have been met properly
- Did you ensure that you put the user comments into context with the surrounding thread properly?
- Did you do a good job?

