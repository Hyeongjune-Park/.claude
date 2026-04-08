---
name: control-flow
description: Orchestrate one feature workflow using state-authoritative control. Resolve policy docs first, bind fixed inputs for each stage, run exactly one legal specialist stage at a time, persist workflow artifacts under .claude/workflow, persist machine-readable state under .claude/state, and re-run controller after each persisted transition.
---

# Control Flow

This skill is the orchestration layer for a single feature.

## Primary rule

The main workflow is driven by:
- persisted policy-resolution input
- persisted review-stage read ledgers
- workflow artifacts under `.claude/workflow/<feature-slug>/`
- machine-readable state under `.claude/state/<feature-slug>.json`

Human-facing docs are not workflow checkpoints.

## Required policy docs

Required docs:
- `.claude/docs/HARNESS_SCOPE.md`
- `.claude/docs/HARNESS_PRINCIPLES.md`
- `.claude/docs/CONTROL_CONTRACT.md`
- `.claude/docs/WORKFLOW_STATE_MACHINE.md`
- `.claude/docs/STATE_SCHEMA.md`

Global fallback root:
- `~/.claude/docs/`

## Policy-resolution algorithm

For each required doc:
1. check exact project-local path
2. if found, record:
   - `resolved_from: project_local`
   - exact resolved path
   - `local_exists: true`
   - `global_exists: true|false`
   then stop
3. only if missing locally, check exact global fallback path
4. if found, record:
   - `resolved_from: global_fallback`
   - exact resolved path
   - `local_exists: false`
   - `global_exists: true`
   then stop
5. otherwise record:
   - `resolved_from: missing`
   - `resolved_path: null`
   - `local_exists: false`
   - `global_exists: false`

Do not read both local and global copies when local exists.
Do not report `Read` before resolution is complete.

Persist the normalized result to:
- `.claude/workflow/<feature-slug>/policy-resolution.json`

This file becomes fixed input for the current run.

## Scope rules

- stay inside the active project root for feature work
- do not inspect sibling repos
- do not start with broad scans like `**/*` or `**/*.md`
- use exact path checks first
- use narrow file reads only when needed for the current stage

## Directory initialization

When first persistence is needed, create missing directories in this order:
1. `.claude/`
2. `.claude/state/`
3. `.claude/workflow/`
4. `.claude/workflow/<feature-slug>/`

## Review-input binding

Before invoking any review stage, create a persisted read ledger.

Canonical paths:
- reviewing → `.claude/workflow/<feature-slug>/read-ledger-reviewing.json`
- implementation_review → `.claude/workflow/<feature-slug>/read-ledger-implementation-review.json`
- final_review → `.claude/workflow/<feature-slug>/read-ledger-final-review.json`

Each read ledger must contain:
- `stage`
- `artifact_under_review`
- `required_read_targets`
- `allowed_direct_reads`
- `provided_context_refs`
- `policy_resolution_ref`
- `created_at`

## Review-stage binding rules

### reviewing
The read ledger must bind:
- the plan artifact as `artifact_under_review`
- the plan artifact as a required read target
- any additional directly inspected project files only if they were actually read for this review and are safe to claim directly

### implementation_review
The read ledger must bind:
- the implementation-design artifact as `artifact_under_review`
- the implementation-design artifact as a required read target
- any additional directly inspected files only if they were actually read for this review and are safe to claim directly

### final_review
The read ledger must bind:
- the implementation artifact as `artifact_under_review`
- the implementation artifact as a required read target
- every validation evidence target required for final review
- every source file the orchestration layer intentionally allowed final review to claim as directly inspected

If validation evidence does not exist in reviewable form, stop before final-review invocation.

## Responsibilities

This skill is responsible for:
- resolving policy docs
- persisting policy-resolution input
- calling controller
- creating read ledgers for review stages
- invoking exactly one legal specialist stage at a time
- saving workflow artifacts
- extracting control blocks
- verifying control-block consistency
- verifying review artifacts against their bound ledgers
- updating machine-readable state
- re-running controller after each persisted transition
- stopping cleanly when blocked or complete

## Stage mapping

- `planning` → `.claude/workflow/<feature-slug>/plan.md`
- `reviewing` → `.claude/workflow/<feature-slug>/review-plan.md`
- `implementation_design` → `.claude/workflow/<feature-slug>/implementation-design.md`
- `implementation_review` → `.claude/workflow/<feature-slug>/review-implementation.md`
- `implementing` → `.claude/workflow/<feature-slug>/implementation.md`
- `final_review` → `.claude/workflow/<feature-slug>/review-final.md`

## Orchestration loop

Repeat until stop or completion:
1. resolve required policy docs
2. persist normalized policy resolution
3. stop if required docs are missing or policy resolution is inconsistent
4. call controller with resolved policy status and current state/artifact inputs
5. if controller says stop, stop
6. if the next step is a review stage, create and persist the read ledger for that stage
7. invoke exactly one specialist stage matching `next_step`
8. save the stage artifact
9. extract the control block
10. verify control-block consistency
11. if the stage is a review stage, verify:
    - `artifact_under_review` matches the read ledger
    - `read_ledger_ref` matches the persisted ledger
    - `direct_reads_used` is a subset of `allowed_direct_reads`
    - `missing_read_targets` is accurate
    - `evidence_gate` is consistent with the ledger and missing-read set
12. update `.claude/state/<feature-slug>.json`
13. re-run controller

Do not skip step 12.

## Specialist input rules

When invoking a review stage, provide:
- the artifact under review
- the read-ledger path
- the required read targets from that ledger
- the allowed direct reads from that ledger
- the fixed policy-resolution reference

Do not ask the reviewer to decide these inputs on its own.

## Stop rules

Stop when:
- required policy docs are missing
- policy resolution is inconsistent
- control block is missing or malformed
- a review stage lacks a read ledger
- a review artifact exceeds its allowed direct-read set
- a review artifact has non-empty missing read targets for an approval-valid verdict
- state and artifact disagree
- human input is required
- approval is stale
- controller says stop

## Reporting

At the end, report only what the caller asked for.
Do not ask follow-up questions during stop output.