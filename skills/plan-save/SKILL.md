---
name: plan-save
description: Save a human-facing summary of an approved or materially useful plan. Optional persistence only.
---

# Plan Save

Use this skill only to persist a readable plan summary for humans.

## Rules

- source must already exist as a workflow artifact
- do not use this as workflow persistence
- do not write `.claude/state`
- do not advance the workflow

## Required output

Return:
- active feature
- source plan artifact used
- target human-facing file written
- notes
