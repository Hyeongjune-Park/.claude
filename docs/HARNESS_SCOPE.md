---
title: HARNESS_SCOPE
version: 2
status: active
---

# HARNESS_SCOPE

## Purpose

This document defines what the harness may automate, what it must not infer, and when it must stop.

## Intended use

This harness is optimized for:
- single-feature work
- small to medium backend or full-stack tasks
- greenfield or lightly populated project roots
- workflows that benefit from planning, review, implementation design, implementation review, implementation, and final review

## In scope

The harness may automate:
- feature-scoped planning
- plan review
- implementation design
- implementation design review
- implementation
- final review
- machine-readable workflow state persistence
- workflow artifact persistence under `.claude/workflow/`
- optional human-facing docs or worklog persistence only after the main workflow has materially progressed

## Out of scope

The harness must not autonomously do any of the following unless the user explicitly asks for it:
- borrow patterns from sibling projects
- infer architecture from neighboring repositories
- expand the task into cross-feature or cross-package work
- change shared contracts beyond the approved feature scope
- treat human-facing docs as workflow authority
- perform parallel lane orchestration
- rewrite harness policy while also applying a feature workflow in the same run

## Root discipline

The active project root is authoritative for project inspection.

Allowed exception:
- required harness policy docs may be resolved from the global fallback under `~/.claude/docs/` when the project-local copy is missing

Not allowed:
- reading sibling repositories for implementation guidance
- reading parent project source files as default context
- importing toolchain assumptions from unrelated projects

## Fresh-start rule

A fresh project may have none of the following:
- `.claude/state/`
- `.claude/workflow/`
- source files
- package manifest
- config files

This is normal.
Fresh-start is not a blocker.

## Human gate rule

The harness must stop and require explicit human input when:
- feature scope is ambiguous
- the active project root is ambiguous
- a required policy document is missing
- a required prior approval is stale
- the requested change would expand or replace a shared contract not already approved
- the workflow would need to choose between materially different designs that are not equivalent in user impact

## Persistence rule

Main workflow persistence uses:
- `.claude/workflow/<feature-slug>/...`
- `.claude/state/<feature-slug>.json`

Human-facing docs are optional and separate.

## Validation rule

When an implementation stage claims validation was run, it must report the exact commands and outcomes.
Do not claim validation that was not actually run.

## Summary

The harness is allowed to automate one scoped feature at a time.
It must prefer strict root discipline, structured control data, and explicit stops over convenient inference.
