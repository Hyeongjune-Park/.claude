---
name: implementation-design
description: Produce a file-level implementation design from an approved plan without dumping full source files as implementation.
---

# Implementation Design

Use this skill to turn an approved plan into an implementation-ready design.

## Rules

- require an approved plan review or equivalent approved plan artifact
- stay within the approved scope
- do not implement code
- do not dump full file bodies except tiny illustrative snippets when necessary
- design at file level, contract level, validation level, and execution-order level

## Required output

Return an implementation design that includes:
- goal
- in scope / out of scope
- affected files
- per-file responsibilities
- request/response and validation details
- execution order
- validation plan
- risks or open questions
- one valid implementation_design artifact metadata block

## Non-goal

This is not a code generation artifact.
If the output reads like a full source tree ready to paste, it is too detailed.
