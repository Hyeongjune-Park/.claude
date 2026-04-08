---
title: CONTROL_CONTRACT
version: 3
status: active
---

# CONTROL_CONTRACT

## Purpose

This document defines the required YAML control block used by workflow artifacts.

Every specialist-stage artifact that advances or blocks the workflow must end with exactly one YAML control block.

## Required shape

```yaml
control:
  workflow_stage: <stage>
  feature_slug: <feature-slug>
  scope_fingerprint: <scope-fingerprint-or-null>
  status: <completed|incomplete|blocked>
  verdict: <none|approved|approved_with_revisions|not_approved>
  next_allowed:
    - <step-name-or-none>
  blocker_present: <true|false>
  blocker_reason: ""
  human_input_required: <true|false>
  stale_conditions:
    - <condition>
  active_project_root: <root-path>
  policy_resolution_ref: <path-or-null>
  artifact_under_review: <path-or-null>
  read_ledger_ref: <path-or-null>
  required_read_targets:
    - <path-or-target-name>
  allowed_direct_reads:
    - <path-or-target-name>
  direct_reads_used:
    - <path-or-target-name>
  missing_read_targets:
    - <path-or-target-name>
  evidence_gate: <not_applicable|passed|failed>
```

## Field rules

### `workflow_stage`
Allowed values:
- `planning`
- `reviewing`
- `implementation_design`
- `implementation_review`
- `implementing`
- `final_review`
- `worklog_update`

### `feature_slug`
Must match the active feature for the run.

### `scope_fingerprint`
A stable identifier for the approved feature scope.
It must not change casually between stages.

### `status`
Allowed values:
- `completed`
- `incomplete`
- `blocked`

### `verdict`
Allowed values:
- `none`
- `approved`
- `approved_with_revisions`
- `not_approved`

Use `verdict: none` for non-review production stages.

### `next_allowed`
Allowed step names:
- `planning`
- `reviewing`
- `implementation_design`
- `implementation_review`
- `implementing`
- `final_review`
- `worklog_update`
- `none`

Use exactly the next legal workflow step, or `none` when terminal or blocked.

### `blocker_present`
Boolean.
Must be consistent with `status` and `blocker_reason`.

### `blocker_reason`
Required string field.
Use empty string only when no blocker exists.

### `human_input_required`
Boolean.
When true, the workflow must stop.

### `stale_conditions`
Array of conditions that would invalidate the current approval or output.

### `active_project_root`
Must match the active project root used for the stage.

### `policy_resolution_ref`
Path to the persisted policy-resolution input used for this artifact.

Required for all workflow stages except fresh-start planning that has no persistence yet.
Once persistence exists, do not omit it.

### `artifact_under_review`
Required for review stages.
Use `null` for non-review stages.

### `read_ledger_ref`
Required for review stages.
Use `null` for non-review stages.

### `required_read_targets`
The minimum targets that had to be read for the artifact to make its claims safely.

Examples:
- the artifact under review
- validation evidence referenced by final review
- any source file claimed as directly inspected

### `allowed_direct_reads`
The direct-read set authorized by the orchestration layer for this stage.

For review stages, all `direct_reads_used` must be a subset of this list.

### `direct_reads_used`
The files or targets the stage actually used as direct inspection.

For review stages:
- do not list anything outside `allowed_direct_reads`
- do not omit a directly inspected target from this field

### `missing_read_targets`
Targets that should have been read but were not.

If this field is non-empty, then:
- `evidence_gate` must be `failed`
- `verdict` must not be `approved`
- `verdict` must not be `approved_with_revisions`

### `evidence_gate`
Allowed values:
- `not_applicable`
- `passed`
- `failed`

Use:
- `not_applicable` for non-review stages
- `passed` only when all are true:
  - `read_ledger_ref` exists
  - `artifact_under_review` exists
  - `missing_read_targets` is empty
  - `direct_reads_used` is a subset of `allowed_direct_reads`
- `failed` otherwise

## Stage-specific expectations

### planning
- `verdict: none`
- normal success `next_allowed: [reviewing]`
- `artifact_under_review: null`
- `read_ledger_ref: null`
- `evidence_gate: not_applicable`

### reviewing
This stage is for plan review only.
- `verdict` must be one of `approved`, `approved_with_revisions`, `not_approved`
- normal success `next_allowed: [implementation_design]`
- `artifact_under_review` must be the planning artifact path
- `read_ledger_ref` must be present
- `required_read_targets` must include the plan artifact
- `approved` and `approved_with_revisions` require:
  - `evidence_gate: passed`
  - `missing_read_targets: []`
  - `direct_reads_used` subset of `allowed_direct_reads`

### implementation_design
- `verdict: none`
- normal success `next_allowed: [implementation_review]`
- `artifact_under_review: null`
- `read_ledger_ref: null`
- `evidence_gate: not_applicable`

### implementation_review
- `verdict` must be one of `approved`, `approved_with_revisions`, `not_approved`
- normal success `next_allowed: [implementing]`
- `artifact_under_review` must be the implementation-design artifact path
- `read_ledger_ref` must be present
- `required_read_targets` must include the implementation-design artifact
- `approved` and `approved_with_revisions` require:
  - `evidence_gate: passed`
  - `missing_read_targets: []`
  - `direct_reads_used` subset of `allowed_direct_reads`

### implementing
- `verdict: none`
- normal success `next_allowed: [final_review]`
- `artifact_under_review: null`
- `read_ledger_ref: null`
- `evidence_gate: not_applicable`

### final_review
- `verdict` must be one of `approved`, `approved_with_revisions`, `not_approved`
- normal success `next_allowed: [none]`
- `artifact_under_review` must be the implementation artifact path
- `read_ledger_ref` must be present
- `required_read_targets` must include:
  - the implementation artifact
  - the recorded validation evidence referenced by final review
  - every source file claimed as directly inspected
- `approved` and `approved_with_revisions` require:
  - `evidence_gate: passed`
  - `missing_read_targets: []`
  - `direct_reads_used` subset of `allowed_direct_reads`

### worklog_update
- `verdict: none`
- does not advance the main workflow by itself
- `artifact_under_review: null`
- `read_ledger_ref: null`
- `evidence_gate: not_applicable`

## Artifact-body requirement

Review artifacts must contain a human-readable slot-based evidence section that matches the control block.

Required slots:
- artifact under review
- read ledger ref
- required read targets
- allowed direct reads
- direct reads used
- missing read targets
- evidence gate
- verdict

## Artifact mapping

Use these canonical workflow artifact paths:
- planning → `.claude/workflow/<feature-slug>/plan.md`
- reviewing → `.claude/workflow/<feature-slug>/review-plan.md`
- implementation_design → `.claude/workflow/<feature-slug>/implementation-design.md`
- implementation_review → `.claude/workflow/<feature-slug>/review-implementation.md`
- implementing → `.claude/workflow/<feature-slug>/implementation.md`
- final_review → `.claude/workflow/<feature-slug>/review-final.md`

## Consistency rule

A control block must be internally consistent.

Examples of invalid combinations:
- `status: completed` with `blocker_present: true`
- `workflow_stage: implementing` with `next_allowed: [reviewing]`
- `workflow_stage: final_review` with `verdict: none`
- `missing_read_targets` non-empty with `evidence_gate: passed`
- `evidence_gate: failed` with `verdict: approved`
- `direct_reads_used` containing paths not present in `allowed_direct_reads`
- review stage with `read_ledger_ref: null`
- review stage with `artifact_under_review: null`

## Summary

The control block is the structured handoff between workflow stages.

For review stages, it is not enough to state a verdict.
The artifact must show that the review stayed within its bound inputs.