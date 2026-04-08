---
title: HARNESS_EVALUATION_PLAN
version: 1
status: draft
---

# HARNESS_EVALUATION_PLAN

## Purpose

This document defines the minimum regression scenarios required to evaluate the single-feature harness.

The goal is not "it seems to work".
The goal is to specify which scenarios must pass, which must fail, and why.

## Evaluation principles

- evaluate the harness as a control system, not just as a content generator
- check state transitions, not only artifact prose
- require persisted policy-resolution input for every run
- require persisted review-stage read ledgers for every review stage
- require review artifacts to stay inside their bound input sets
- treat failed evidence gates as hard failures for approval-valid continuation

## Required checks for every scenario

For each scenario, record:
- scenario id
- scenario name
- fixture/project shape
- initial state
- trigger action
- expected final state
- expected controller next step
- expected stop reason when applicable
- required artifacts
- required state fields
- forbidden outcomes

## Scenario 1. Happy path

### Goal
Verify the full legal sequence succeeds when policy resolution is consistent and each review stays inside its bound read ledger.

### Expected
- final state `completed`
- final review `approved`
- `next_allowed: ["none"]`
- no missing required policy docs
- no missing read targets in review stages
- every `direct_reads_used` is a subset of `allowed_direct_reads`

### Forbidden outcomes
- skipped stage
- stale approval
- approval with failed evidence gate
- review direct reads outside ledger

## Scenario 2. Review rejection

### Goal
Verify plan review can reject the plan and block continuation.

### Expected
- review verdict `not_approved`
- state becomes `blocked` or returns to `planning_pending`
- no transition to `implementation_design`

## Scenario 3. Implementation-review rejection

### Goal
Verify implementation design review can stop coding when the design is unsafe or incomplete.

### Expected
- implementation review verdict `not_approved`
- state becomes `blocked` or returns to `implementation_design_pending`
- no transition to `implementing`

## Scenario 4. Stale approval

### Goal
Verify approval cannot be reused after material scope or artifact change.

### Expected
- state becomes `approval_stale`
- `next_allowed: ["none"]`
- no automatic continuation until re-entry is created

## Scenario 5. Human gate required

### Goal
Verify the harness stops when a required human decision exists.

### Expected
- state becomes `human_gate_required`
- controller returns `continue: false`
- `next_allowed: ["none"]`

## Scenario 6. Bound-read violation

### Goal
Verify approval is blocked when a review claims direct inspection beyond its allowed direct-read set.

### Fixture
A review artifact whose `direct_reads_used` includes a target not present in `allowed_direct_reads`.

### Expected
- review is invalid
- workflow does not advance on that approval
- stop reason mentions bound-read or read-ledger mismatch

### Forbidden outcomes
- `approved`
- `approved_with_revisions`
- transition to the next implementation stage

## Scenario 7. Missing required read target

### Goal
Verify approval is blocked when a review omits a required read target.

### Fixture
A review artifact with non-empty `missing_read_targets`.

### Expected
- `evidence_gate: failed`
- no approval-valid transition
- workflow stops or remains non-advancing

## Scenario 8. Policy resolution mismatch

### Goal
Verify local/global policy resolution inconsistency causes a stop before specialist execution.

### Fixture
A run where:
- local policy doc exists
- but resolution claims global fallback
- or both local and global copies are treated as co-authoritative

### Expected
- normalized policy resolution marked inconsistent
- controller stops
- no specialist stage execution

## Scenario 9. Missing required policy doc

### Goal
Verify workflow does not continue when a required policy doc is unavailable.

### Expected
- stop before specialist stage
- no workflow continuation
- state policy resolution marks missing doc clearly

## Scenario 10. Final review without validation evidence

### Goal
Verify final review cannot approve code without reviewable validation evidence.

### Fixture
Implementation artifact exists, but validation evidence is absent, unread, or not bound into the final-review read ledger.

### Expected
- `missing_read_targets` includes validation evidence
- `evidence_gate: failed`
- no transition to `completed`

## Scenario 11. Wrong artifact bound to review stage

### Goal
Verify a review cannot approve the wrong artifact under a valid-looking ledger.

### Fixture
A review artifact whose `artifact_under_review` does not match the ledger's bound artifact.

### Expected
- review invalid
- no approval-valid transition
- stop reason mentions artifact-under-review mismatch

## Scenario 12. Windows path / quoting resilience

### Goal
Verify path handling does not corrupt policy resolution, read-ledger references, artifact references, or state updates in Windows-style environments.

### Expected
- persisted paths remain exact
- no false missing-artifact or missing-doc result due only to quoting mistakes

## Minimum pass bar

Before expanding to larger-scale workflow, the harness should pass at least:
- Scenario 1
- Scenario 2
- Scenario 3
- Scenario 4
- Scenario 5
- Scenario 6
- Scenario 7
- Scenario 8
- Scenario 10
- Scenario 11

## Summary

The harness is not ready for broader expansion until:
- approvals are bound to persisted read inputs
- policy resolution is normalized and fixed before specialist execution
- stale paths are enforced
- regression scenarios are explicit and repeatable