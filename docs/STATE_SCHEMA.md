---
title: STATE_SCHEMA
version: 2
status: active
---

# STATE_SCHEMA

## Purpose

This document defines the machine-readable workflow state used by the harness.

Canonical path:
- `.claude/state/<feature-slug>.json`

Related workflow artifacts live under:
- `.claude/workflow/<feature-slug>/`

## Directory behavior

On a fresh or empty project, these directories may not exist yet:
- `.claude/`
- `.claude/state/`
- `.claude/workflow/`

This is not a blocker.
Create them when first persistence is needed.

## State authority

Use this authority order:
1. current state file
2. latest valid workflow artifact control block
3. persisted policy-resolution input
4. persisted read-ledger input
5. grounded project inspection
6. prose

## Required top-level fields

- `schema_version`
- `feature_slug`
- `active_project_root`
- `workflow_state`
- `last_completed_stage`
- `status`
- `verdict`
- `next_allowed`
- `blocker_present`
- `blocker_reason`
- `human_input_required`
- `scope_fingerprint`
- `stale`
- `stale_reason`
- `policy_resolution`
- `artifacts`
- `review_inputs`
- `last_review_evidence`
- `last_validation_summary`
- `last_transition`
- `updated_at`

## Field constraints

### `schema_version`
Initial value:
- `state@2`

### `workflow_state`
Allowed values:
- `planning_pending`
- `plan_ready_for_review`
- `plan_approved`
- `implementation_design_pending`
- `implementation_design_ready_for_review`
- `implementation_pending`
- `final_review_pending`
- `completed`
- `blocked`
- `approval_stale`
- `human_gate_required`

### `last_completed_stage`
Allowed values or `null`:
- `planning`
- `reviewing`
- `implementation_design`
- `implementation_review`
- `implementing`
- `final_review`
- `worklog_update`

### `status`
Allowed values:
- `pending`
- `completed`
- `blocked`
- `stale`

### `verdict`
Allowed values:
- `none`
- `approved`
- `approved_with_revisions`
- `not_approved`

### `next_allowed`
Array of step names.
Allowed values:
- `planning`
- `reviewing`
- `implementation_design`
- `implementation_review`
- `implementing`
- `final_review`
- `worklog_update`
- `none`

### `policy_resolution`
Required keys:
- `ref`
- `required_docs`
- `consistent`

`required_docs` must include:
- `HARNESS_SCOPE.md`
- `HARNESS_PRINCIPLES.md`
- `CONTROL_CONTRACT.md`
- `WORKFLOW_STATE_MACHINE.md`
- `STATE_SCHEMA.md`

Each required doc entry must contain:
- `resolved_from` (`project_local|global_fallback|missing`)
- `resolved_path`
- `local_exists`
- `global_exists`

If any required doc resolves to `missing`, `consistent` must be `false`.

### `artifacts`
Required keys:
- `plan`
- `review_plan`
- `implementation_design`
- `review_implementation`
- `implementation`
- `review_final`

Each value is either a relative path string or `null`.

### `review_inputs`
Required keys:
- `reviewing`
- `implementation_review`
- `final_review`

Each value is either `null` or an object with:
- `ref`
- `artifact_under_review`
- `required_read_targets`
- `allowed_direct_reads`

This stores the latest persisted read ledger for that review stage.

### `last_review_evidence`
Use `null` when no review has happened yet.

Otherwise required keys:
- `stage`
- `artifact_under_review`
- `read_ledger_ref`
- `required_read_targets`
- `allowed_direct_reads`
- `direct_reads_used`
- `missing_read_targets`
- `evidence_gate`

### `last_validation_summary`
Use `null` when implementation validation has not happened yet.

Otherwise required keys:
- `commands_requested`
- `commands_executed`
- `result`
- `evidence_refs`

### `last_transition`
Required keys:
- `from_state`
- `to_state`
- `trigger`
- `artifact_path`
- `timestamp`

## Fresh-start example

```json
{
  "schema_version": "state@2",
  "feature_slug": "example-feature",
  "active_project_root": "C:/path/to/project",
  "workflow_state": "planning_pending",
  "last_completed_stage": null,
  "status": "pending",
  "verdict": "none",
  "next_allowed": ["planning"],
  "blocker_present": false,
  "blocker_reason": "",
  "human_input_required": false,
  "scope_fingerprint": null,
  "stale": false,
  "stale_reason": "",
  "policy_resolution": {
    "ref": null,
    "required_docs": {
      "HARNESS_SCOPE.md": {
        "resolved_from": "missing",
        "resolved_path": null,
        "local_exists": false,
        "global_exists": false
      },
      "HARNESS_PRINCIPLES.md": {
        "resolved_from": "missing",
        "resolved_path": null,
        "local_exists": false,
        "global_exists": false
      },
      "CONTROL_CONTRACT.md": {
        "resolved_from": "missing",
        "resolved_path": null,
        "local_exists": false,
        "global_exists": false
      },
      "WORKFLOW_STATE_MACHINE.md": {
        "resolved_from": "missing",
        "resolved_path": null,
        "local_exists": false,
        "global_exists": false
      },
      "STATE_SCHEMA.md": {
        "resolved_from": "missing",
        "resolved_path": null,
        "local_exists": false,
        "global_exists": false
      }
    },
    "consistent": false
  },
  "artifacts": {
    "plan": null,
    "review_plan": null,
    "implementation_design": null,
    "review_implementation": null,
    "implementation": null,
    "review_final": null
  },
  "review_inputs": {
    "reviewing": null,
    "implementation_review": null,
    "final_review": null
  },
  "last_review_evidence": null,
  "last_validation_summary": null,
  "last_transition": {
    "from_state": null,
    "to_state": "planning_pending",
    "trigger": "state_initialized",
    "artifact_path": null,
    "timestamp": "2026-01-01T00:00:00Z"
  },
  "updated_at": "2026-01-01T00:00:00Z"
}
```

## Update rule

After each completed stage:
1. persist policy-resolution input
2. if the next stage is a review stage, persist its read-ledger input
3. save the workflow artifact
4. extract the control block
5. normalize the resulting workflow state
6. update the state file
7. only then re-run controller state determination

## Review-state update rule

When the current artifact is a review artifact:
- copy `artifact_under_review`
- copy `read_ledger_ref`
- copy `required_read_targets`
- copy `allowed_direct_reads`
- copy `direct_reads_used`
- copy `missing_read_targets`
- copy `evidence_gate`

If `direct_reads_used` exceeds `allowed_direct_reads`, the review is invalid.
If `missing_read_targets` is non-empty, the review is non-advancing.

## Validation-state update rule

When the current artifact is an implementation artifact:
- copy requested validation commands
- copy executed validation commands
- copy exact result
- copy evidence refs for later final review

## Summary

The state file is the machine-readable current truth for one feature workflow.

It must capture:
- position
- policy-resolution input
- review-stage read inputs
- review evidence
- validation evidence