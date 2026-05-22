---
description: "Morning kickoff. Load today's context, review yesterday, surface open tasks, and identify priorities."
---

Run the morning standup:

1. Read `Home.md` for current dashboard state
2. Read `AI/brain/North Star.md` for current goals
3. Check `AI/work/Index.md` for active projects
4. Read yesterday's and today's daily notes if they exist
5. Check recent git activity: `git log --oneline --since="24 hours ago" --no-merges` across workspace packages
6. Check for any unlinked notes or inbox items needing processing
7. Check CR status from code.amazon.com:
   - Fetch CRs authored by user: `https://code.amazon.com/reviews/from-user/nsager`
   - Fetch CRs awaiting user's review: `https://code.amazon.com/reviews/to-user/nsager`
   - Use `mcp__builder-mcp__ReadInternalWebsites` for both (load via ToolSearch first)
   - Summarize each CR: ID, package, status (OPEN/SHIPPED/MERGED), approver if any
   - Suppression check: for each CR with a review note at `AI/work/reviews/CR-<ID>.md`, read the frontmatter. If `standup: suppress` is set, move that CR out of the main table into a collapsed `<details>` block at the end of the CR section, showing `standup_reason`. Re-surface automatically if the CR has a new revision since `standup_suppressed_on` (compare `Revision` column from the CR list against the date).
8. Read yesterday's `## Work` section. Identify unfinished items (unchecked `[]` tasks).
   - Cross-reference with project notes in `AI/work/active/` — items that belong to a project backlog should NOT be carried forward (they live in the project note).
   - Only carry forward items that are concrete today-intentions, not backlog.

Present a structured standup summary:
- **Yesterday**: What got done (from git log and daily note)
- **Active Work**: Current projects in AI/work/active/ with their status
- **Open Tasks**: Pending items from project notes relevant to this week
- **Open CRs**: Table of authored CRs (ID, package, status, approved by) + any CRs awaiting your review
- **North Star Alignment**: How active work maps to current goals
- **Suggested Focus**: 3-5 concrete items for today based on goals + open items + CR status

After presenting the standup, append the full standup output to the **bottom** of today's daily note (after all existing content). Find it at `Main/Daily_Notes/YYYY/YYYY-MM/YYYY-MM-DD.md`. If the daily note doesn't exist yet, create it from the template at `Main/Templates/Daily_Note.md` (create the year/month subdirectories as needed).

Keep it concise. This is a quick orientation, not a deep dive.
