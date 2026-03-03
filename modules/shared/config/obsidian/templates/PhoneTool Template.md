---
name: "{{phonetool_name}}"
login: "{{phonetool_login}}@"
role: "{{phonetool_job_title}}"
level: "{{phonetool_job_level}}"
phone: "{{phonetool_mobile_number}}"
email: "{{phonetool_email}}"
manager_login: "{{phonetool_manager_login}}@"
location: "{{phonetool_building}}"
department: "{{phonetool_department_name}}"
hire_date: "{{phonetool_hire_date}}"
hire_date_iso: "{{phonetool_hire_date_iso}}"
aliases:
  - "{{phonetool_first_name}}"
  - "{{phonetool_name}}"
  - "{{phonetool_login}}"
  - "{{phonetool_login}}@"
created: <% tp.file.creation_date("") %>
type: people
---

> [!info]- Links for {{phonetool_name}} ({{phonetool_login}}@)
> - [PhoneTool](https://connect.amazon.com/users/{{phonetool_login}})
> - [Send Slack message](https://slack.com/app_redirect?channel=@{{phonetool_login}})
> - [Search LinkedIn](https://www.linkedin.com/search/results/people/?keywords=<% "{{phonetool_name}}".replace(/\s/,"+") %>+Amazon)
> - [Send email](mailto:{{phonetool_email}})
> - [SayMyName](https://saymyname.tools.amazon.dev/users/{{phonetool_login}})

```dataview
TABLE WITHOUT ID
 name as Name,
 role as Role,
 location as Location,
 hire_date as "Hire Date"
WHERE file.path = this.file.path
```

## Notes

## Background

## Meetings/Interactions
```dataview
TABLE file.cday as Created, summary AS "Summary"
FROM "Meeting Notes" where contains(file.outlinks, this.file.link)
SORT file.cday DESC
```

## Mentions
```dataview
TABLE file.cday as Created, summary AS "Summary"
FROM !"Meeting Notes" where contains(file.outlinks, this.file.link)
SORT file.cday DESC
```
