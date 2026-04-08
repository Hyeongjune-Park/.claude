---
name: planning
description: Produce a review-ready plan for one feature using only the active project root and the provided requirements.
---

# Planning

Use this skill to create a planning artifact.

## Rules

- inspect only the active project root
- do not borrow structure or toolchain from sibling projects
- do not implement code
- do not perform review
- if the root is empty, say it is empty; do not fill gaps with neighboring project assumptions

## Required output

Return a planning artifact that includes:
- goal
- scope
- affected files or file classes
- key decisions
- risks
- validation plan
- evidence summary
- one valid planning control block

## Artifact metadata format rule

Return the planning result as one complete artifact body.

That artifact must begin with exactly one YAML front-matter metadata block that matches `CONTROL_CONTRACT.md`.

Use the current canonical form:
- YAML front-matter at the top of the artifact
- current field names from `CONTROL_CONTRACT.md`

Do not use:
- a trailing `control:` block
- `CONTROL_BLOCK`
- `END_CONTROL_BLOCK`
- standalone JSON control objects
- alternate field names that are not in the current contract

## Scope discipline

If the caller says a note has minimum fields, treat that as a minimum unless a stricter contract is explicitly proposed as a reviewable decision.

## Evidence discipline

Use:
- `Inspected directly`
- `Provided by caller`
- `Inferred`

Do not claim direct inspection for files not read.
