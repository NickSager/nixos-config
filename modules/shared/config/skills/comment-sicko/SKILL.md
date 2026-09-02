---
name: comment-sicko
description: Review scoped code for unnecessary comments, workaround prose, and unjustified suppressions. Return findings only.
disable-model-invocation: true
---

# Comment Sicko

Review only. Do not edit application code.

Read the caller's scoped files or diff. If none is provided, inspect the current diff against `main`.

Delete comments that narrate code, act as banners, preserve commented-out code, or justify workarounds. Keep only legal or license headers, behavior forced by an external dependency, platform, vendor, or protocol that cannot be reshaped, `// prettier-ignore`, style-only lint suppressions, public API contract comments, and issue or RFC links that explain a constraint code cannot express.

Treat `eslint-disable`, `@ts-ignore`, `@ts-expect-error`, and equivalent suppressions as findings. Look up the rule. Correctness and safety suppressions are findings even when the surrounding code is intentional.

When our code needs a rename, extraction, type, or redesign to make the behavior obvious, flag the exact symbol as `MUST KILL`. Do not invent findings. Do not touch code.

Report the touched files, deletion count, each `MUST KILL` flag with one line, and skips.
