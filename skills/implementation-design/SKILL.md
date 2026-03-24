---
name: implementation-design
description: Convert an approved or review-ready project plan into a concrete code change plan. Use when the user asks how to apply a plan to the current codebase, which files to change, how to sequence edits, how to translate a plan into implementation steps, or how to prepare a patch plan before coding. Also use for Korean requests like "코드 적용 계획", "구현 계획", "어느 파일을 바꿔야 할지", "계획을 코드 단계로 쪼개줘", "코딩 전에 파일별 수정안 정리".
---

# Implementation Design

## Purpose

Turn an existing plan into a concrete implementation plan tied to the current codebase.

This skill is for code-change design only.  
Do not implement code.

The goal is to bridge the gap between:
- high-level plan
- current repository structure
- file-level change plan
- validation approach

## When to Use

Use this skill when:
- a plan already exists and needs to be translated into code changes
- the user asks which files should be edited
- the user asks how to apply a design or plan to the current codebase
- the user wants a patch plan before implementation
- the user wants a minimal-change implementation path
- the user wants sequencing for multi-file changes
- a feature, fix, refactor, or behavior change must be mapped to actual modules/files

Do not use this skill when:
- the main problem is still choosing the overall approach
- the work is still at discovery or product-planning stage
- there is no meaningful codebase or file structure yet
- the task is trivial enough to implement directly without ambiguity
- the user is asking for code review of already-written code rather than a pre-code change plan

## Required Inputs

Prefer to work from:
1. an approved or review-ready plan
2. the relevant current codebase
3. known constraints or non-goals
4. existing contracts, schema, config, or docs if relevant

If some inputs are missing, state the missing assumptions explicitly instead of silently inventing them.

## Core Responsibilities

Produce a concrete implementation plan that:
- maps the plan to specific files or modules
- explains why each file must change
- separates modify vs create vs delete
- identifies dependencies between edits
- proposes an order of operations
- defines validation steps
- highlights open questions without upgrading them into settled decisions

## Output Requirements

Structure the result using these sections where applicable:

### 1. Scope Summary
- what this implementation plan covers
- what it intentionally does not cover

### 2. Relevant Codebase Areas
- relevant files, folders, modules, or entry points
- each item's current role in the system

### 3. Proposed File-Level Changes
For each file:
- path
- current role
- proposed change
- reason for change
- risk or dependency if any

### 4. Change Sequence
- recommended order of edits
- why that order reduces risk

### 5. Validation Plan
- unit/integration/manual checks
- contract/schema/config verification
- regression checks if applicable

### 6. Open Questions / Assumptions
- unresolved points
- assumptions made because of missing evidence
- things that need explicit review before coding

## Working Rules

- Stay grounded in the current codebase.
- Prefer minimal viable changes over speculative cleanup.
- Do not quietly expand scope.
- Distinguish inspected facts from inferences.
- If the codebase and docs disagree, note the discrepancy.
- If a plan depends on unsettled decisions, keep them marked as unsettled.
- Do not turn inferred architecture into approved architecture.

## Hard Constraints

Do not:
- write code
- propose unrelated cleanup as part of the plan
- merge multiple possible approaches into one without saying so
- present assumptions as confirmed facts
- treat proposed or revised decisions as settled
- hide file-impact uncertainty

## Quality Bar

A good implementation design:
- is specific enough that coding can start from it
- stays within scope
- names concrete files/modules
- includes validation
- exposes risk and uncertainty early
- avoids vague advice like "update logic as needed"

## Anti-Patterns

Avoid:
- "Modify backend logic and frontend accordingly"
- "Update related files"
- "Refactor for consistency"
- "Probably change X"
- "Tests if needed"

Replace with explicit file-level intent and explicit validation.

## Expected Outcome

By the end, the user should have:
- a concrete code change map
- a safe edit order
- known risks and assumptions
- a plan ready for implementation review or direct coding