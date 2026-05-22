---
tags:
---
# Tasks
> [!danger]+ Overdue
> ```tasks
> not done
> due before today
> is not blocked
> sort by due
> group by function task.file.folder.replace("Projects/active/", "").replace("Projects/artifacts/", "").replace("AI/work/", "").replace(/\/$/, "")
> show due date
> show scheduled date
> show priority
> show backlink
> ```

> [!warning]+ Due / Scheduled Today
> ```tasks
> not done
> (due on today) OR (scheduled on today)
> is not blocked
> sort by priority, due
> group by function task.file.folder.replace("Projects/active/", "").replace("Projects/artifacts/", "").replace("AI/work/", "").replace(/\/$/, "")
> show due date
> show scheduled date
> show priority
> show backlink
> ```

> [!tip]- Due This Week (excl. today)
> ```tasks
> not done
> due after today
> due before in 8 days
> is not blocked
> sort by due
> group by function task.due?.format("ddd MMM D") ?? "No date"
> show due date
> show priority
> show backlink
> ```

> [!info]- Scheduled This Week (excl. today)
> ```tasks
> not done
> scheduled after today
> scheduled before in 8 days
> is not blocked
> sort by scheduled
> group by function task.scheduled?.format("ddd MMM D") ?? "No date"
> show scheduled date
> show priority
> show backlink
> ```

> [!warning]+ Task-note tracker (scheduled/due today or overdue)
> ```dataview
> TABLE WITHOUT ID
>   file.link AS "Task",
>   priority AS "P",
>   scheduled AS "Sched",
>   due AS "Due",
>   status AS "Status"
> FROM "Projects/artifacts"
> WHERE ((scheduled AND scheduled <= date(today))
>     OR (due AND due <= date(today)))
>   AND status != "done"
>   AND status != "cancelled"
> SORT due ASC, priority ASC
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

### Prompts for Today
