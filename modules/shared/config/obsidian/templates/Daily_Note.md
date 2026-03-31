---
tags:
---
# Tasks
> [!danger]+  Overdue
> ```tasks
> not done
> due before today and not due this week
> is not blocked
> short mode
> ```

> [!warning]+  Due This Week
> ```tasks
> not done
> due this week
> is not blocked
> short mode
> ```

> [!info]+  No Due Date
> ```tasks
> not done
>   scheduled after 4 weeks ago
> is not blocked
> short mode
> ```

# Day planner

## Work

### Ad-Hoc

### Meetings
```dataview
LIST
FROM "Main/Meeting_Notes"
WHERE date = this.file.name
SORT file.name ASC
```

## Issues

## Notes
