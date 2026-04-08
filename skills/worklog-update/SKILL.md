---
name: worklog-update
description: Write or update a human-facing worklog entry based on completed workflow artifacts. Optional persistence only.
---

# Worklog Update

This skill writes human-facing worklog entries.

## Rules

- use completed workflow artifacts as source
- do not write machine-readable state
- do not replace workflow artifacts
- do not advance the main workflow by itself
- keep entries factual and feature-scoped

## Required output

Return:
- active feature
- source artifacts used
- worklog path written
- summary of the entry
