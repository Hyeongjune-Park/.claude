---
title: WORKFLOW_STATE_MACHINE
version: 3
status: active
---

# WORKFLOW_STATE_MACHINE

## Purpose

This document defines the legal workflow states and transitions for the single-feature harness.

## Canonical stage sequence

Normal main workflow:
1. `planning`
2. `reviewing`
3. `implementation_design`
4. `implementation_review`
5. `implementing`
6. `final_review`

Optional human-facing persistence may happen outside this chain.

## Workflow states

Allowed workflow states:
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

## Fresh-start rule

If neither state file nor workflow artifacts exist for the feature:
- classify as fresh-start
- set current state to `planning_pending`
- allow only `planning`

## Transition rules

### `planning_pending`
Allowed next step:
- `planning`

Successful transition:
- planning artifact saved
- state updated
- next state `plan_ready_for_review`

### `plan_ready_for_review`
Allowed next step:
- `reviewing`

Preconditions before review:
- policy resolution is consistent
- the planning artifact exists
- a read ledger for `reviewing` exists

Review outcomes:
- `approved` → `plan_approved`
- `approved_with_revisions` → `planning_pending`
- `not_approved` → `blocked` or `planning_pending`, depending on severity

Review validity requirements:
- `artifact_under_review` matches the planning artifact
- `direct_reads_used` is a subset of `allowed_direct_reads`
- `missing_read_targets` is empty for approval-valid outcomes
- `evidence_gate` is `passed` for approval-valid outcomes

If any validity requirement fails:
- do not transition to `plan_approved`

### `plan_approved`
Allowed next step:
- `implementation_design`

Successful transition:
- implementation design artifact saved
- state updated
- next state `implementation_design_ready_for_review`

### `implementation_design_ready_for_review`
Allowed next step:
- `implementation_review`

Preconditions before review:
- policy resolution is consistent
- the implementation-design artifact exists
- a read ledger for `implementation_review` exists

Review outcomes:
- `approved` → `implementation_pending`
- `approved_with_revisions` → `implementation_design_pending`
- `not_approved` → `blocked` or `implementation_design_pending`, depending on severity

Review validity requirements:
- `artifact_under_review` matches the implementation-design artifact
- `direct_reads_used` is a subset of `allowed_direct_reads`
- `missing_read_targets` is empty for approval-valid outcomes
- `evidence_gate` is `passed` for approval-valid outcomes

If any validity requirement fails:
- do not transition to `implementation_pending`

### `implementation_design_pending`
Allowed next step:
- `implementation_design`

### `implementation_pending`
Allowed next step:
- `implementing`

Successful transition:
- implementation artifact saved
- state updated
- next state `final_review_pending`

### `final_review_pending`
Allowed next step:
- `final_review`

Preconditions before review:
- policy resolution is consistent
- the implementation artifact exists
- a read ledger for `final_review` exists
- validation evidence exists in a reviewable form

Review outcomes:
- `approved` → `completed`
- `approved_with_revisions` → `implementation_pending`
- `not_approved` → `blocked` or `implementation_pending`, depending on severity

Review validity requirements:
- `artifact_under_review` matches the implementation artifact
- `direct_reads_used` is a subset of `allowed_direct_reads`
- `missing_read_targets` is empty for approval-valid outcomes
- `evidence_gate` is `passed` for approval-valid outcomes

If any validity requirement fails:
- do not transition to `completed`

## Blocked state

`blocked` allows no automatic continuation.
`next_allowed` must be `none` until a legal re-entry path is created.

## Human gate state

`human_gate_required` allows no automatic continuation.
`next_allowed` must be `none`.

## Approval stale state

Enter `approval_stale` when:
- scope fingerprint changed materially
- the approved artifact was replaced
- feature slug mismatched
- approved assumptions changed enough to invalidate prior approval

Default automatic continuation:
- none

## Policy-resolution stop rule

If policy resolution is inconsistent or any required policy doc is missing:
- do not advance
- do not call specialist stages
- stop before state continuation

## Read-ledger stop rule

If a review stage lacks its persisted read ledger:
- do not invoke the reviewer
- stop before specialist execution

If a review artifact claims direct reads outside its ledger:
- invalidate the review
- do not advance

## Required persistence invariant

A transition is valid only when all are true:
1. the stage output exists as a workflow artifact under `.claude/workflow/<feature-slug>/`
2. the artifact contains a valid control block
3. the current state reflects that artifact
4. the controller decision uses the updated state
5. for review stages, the referenced read ledger exists and matches the review artifact

## No aliasing rule

`final_review` is a distinct workflow stage.
Do not encode final review artifacts as `workflow_stage: reviewing`.

## Summary

Advance by one legal stage, one persisted input set, one persisted artifact, one persisted state update, and one new controller decision.

No review approval is valid when it exceeds its bound read ledger.