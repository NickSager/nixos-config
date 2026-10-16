---
name: report-writing
description: "Use when writing a report, one-pager, readout, study write-up or Confluence page for readers outside the team. Nick's house style: structure, headings, bold, bullets, and what to cut."
---

# Report writing

Nick's house style for documents other people read: vault one-pagers, study write-ups, evaluation readouts, Confluence pages. Every rule here came from a correction. Apply them on the first draft, so the document doesn't need several rounds of fixes.

Also apply `unslop` for sentence-level AI tells. This skill covers documents, not chat replies.

## Structure

- **Summary first.** Open with one or two plain sentences on what was asked, then three or four findings. No background the audience already knows (don't explain the team's own domain to the team).
- **Explain the work first, recommend near the end.** Never open with "Do it". Recommendations come as a numbered list, cheapest or most important first, followed by Limits, then history (earlier pilots, what changed), then Cost and data.
- **Headings are short noun phrases, like a table of contents.** "Method", "Failure causes", "Production requirements". Never sentences, never questions, and never a bold sentence standing in for a subheading. If a section has several parts, give each a `###` noun heading.

## Bullets and bold

- **Parallel points go in a list.** Several paragraphs that each make one point read as bullets without bullets. Make them real bullets.
- **Bold is a balance, not a ban.** Bold the headline results and give each finding bullet a bold lead-in that names the finding. Don't bold whole paragraphs or every number, and don't strip all bold either. A wall of plain text was an over-correction.
- **Plain prose for narrative.** Limits and history can be short paragraphs.

## Every line adds information

- Under a table, keep only bullets that add something the table doesn't show: a mechanism, a breakdown, a caveat, a surprising consequence. Cut bullets that repeat a row, and cut non-findings ("house rules made no difference") unless a decision depends on them.
- Cut process detail readers don't need: ports, proxies, run IDs, internal names for conditions or runs. Describe each setup in plain words instead ("model X with an expert prompt, asked one question at a time").
- Ask of each bullet: does a reader learn something from it? If not, delete it.

## Explain the method concretely

- **Say how ground truth was made.** Name the tool, what it read and whether any AI model was involved, and say how errors were filtered out. "A script read every dimension" is not an explanation.
- **Say what a tool is and why we built it.** When we built something instead of using a vendor's version, give two or three sentences on what it does and why the vendor version didn't fit.
- **Pre-empt the obvious misreading.** If a result could suggest something impossible (such as "we had a higher-resolution document"), say plainly where the data came from.
- **Define every term the first time it appears,** and explain numbers in words ("within 5% of the true value", "95% confidence interval").

## Publishing

- The vault note is the source of truth. Publish the same text, vault wikilinks and frontmatter stripped, and a `confluence:` property added to the note.
- When fixing content later, change the note and the page in the same turn.
