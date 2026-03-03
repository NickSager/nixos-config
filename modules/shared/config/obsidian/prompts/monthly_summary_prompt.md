# Monthly Summary Generator Prompt

## Purpose
Generate a comprehensive monthly summary of daily logs while maintaining confidentiality and following established preferences.

## Required Sections
1. Major Projects & Initiatives
   - Link to relevant daily notes using Obsidian syntax [[YYYY-MM-DD]]
   - Focus on key developments and milestones
   - Maintain confidentiality of sensitive information

2. Key System Changes
   - System updates
   - Environment configurations
   - Tool installations and updates

3. Important Deliverables
   - Completed tasks and reviews
   - Major submissions
   - Key documentation

4. Recurring Meetings
   - List regular meeting types
   - Do not include daily breakdown

5. Action Items Carried Forward
   - Ongoing tasks
   - Pending reviews
   - Future commitments

6. Travel & Planning
   - Past and upcoming travel
   - Key planning activities

7. Tools & Infrastructure
   - List of tools used
   - Infrastructure changes
   - Development environment updates

8. Meeting Time Analysis
   - Total meeting time (hours and minutes)
   - Number of meetings
   - Average meeting length
   - Generated from the script output

9. Summary
   - Month's primary focus areas
   - Key accomplishments
   - Workload trends
   - Forward-looking statements

## Formatting Requirements
- Use clean markdown that can be copied and pasted
- Don't use markdown headers unless showing a multi-step answer
- Don't bold text
- Use bullet points for better readability
- Include relevant links using Obsidian syntax
- Maintain professional tone
- Be concise but comprehensive

## Content Guidelines
- This is for personal use
- Focus on actionable information
- Prioritize accuracy over verbosity
- Take your time and reason through the problem

## Process
1. Run the meeting analysis script first
   - Prefer shell commands over other methods
   - When extracting line numbers use `cat -n` to read files
2. Review all daily logs chronologically
3. Categorize information into required sections
4. Generate the summary maintaining all formatting requirements
5. Review for confidentiality and sensitive information
6. Ensure all links use proper Obsidian syntax
7. Make sure the summary section provides a comprehensive overview
8. Create the file in the target directory as 'monthly_summary.md'

## Script Usage
To run the meeting analysis script:
```bash
$HOME/Documents/Obsidian/bin/extract_meetings.sh
```

Update the DIR variable in the script to point to the correct month's directory before running.

