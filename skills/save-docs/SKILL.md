---
name: save-docs
description: Save human-facing project documentation derived from completed workflow artifacts. Optional persistence only.
---

# Save Docs

Use this skill to save human-facing docs after the main workflow has materially progressed or completed.

## Rules

- docs are not workflow checkpoints
- do not write `.claude/state`
- do not write `.claude/workflow`
- do not advance the main workflow
- derive docs from existing workflow artifacts and current state

## Allowed targets

Examples:
- `docs/`
- `worklog/`
- user-requested summary files

## Required output

Return:
- active feature
- source artifacts used
- target doc paths written
- notes
