---
name: final-review
description: Review the actual implemented files and recorded validation outputs using only the bound review inputs, then return a final grounded verdict.
---

# Final Review

Use this skill only after implementation has completed and reviewable validation evidence exists.

## Required inputs from orchestration

The caller must provide:
- the implementation artifact under review
- the read-ledger reference
- the required read targets
- the allowed direct reads
- the fixed policy-resolution reference

Do not expand these inputs on your own.

## Rules

- review actual files and recorded validation outputs
- do not review the plan or design instead of the code
- do not claim direct inspection for files not read
- do not claim direct inspection outside the allowed direct reads
- verify requirements against real source and validation evidence
- do not return approval if a required read target is missing

## Required read targets

At minimum, final review must read:
- the implementation artifact under review
- the recorded validation evidence used by the review
- every source file it claims to have inspected directly

## Evidence slots

Use these slots exactly:
- `Artifact under review`
- `Read ledger ref`
- `Required read targets`
- `Allowed direct reads`
- `Direct reads used`
- `Missing read targets`
- `Evidence gate`
- `Inspected directly`
- `Provided by caller`
- `Inferred`
- `Unverified`

## Required output

Return:
- review scope
- artifact under review
- read ledger ref
- required read targets
- allowed direct reads
- direct reads used
- missing read targets
- evidence gate
- evidence summary
- overall assessment
- blocking issues
- non-blocking issues
- verdict
- one valid final_review control block

Normal approved next step is `none`.
Use `workflow_stage: final_review`.

## Control-block requirements

For this skill:
- `artifact_under_review` must be the implementation artifact
- `read_ledger_ref` must be present
- `required_read_targets` must include the implementation artifact
- `required_read_targets` must include the validation evidence referenced by the review
- `direct_reads_used` must be a subset of `allowed_direct_reads`
- `missing_read_targets` must be empty for `approved`
- `missing_read_targets` must be empty for `approved_with_revisions`
- `evidence_gate` must be `failed` when a required target is missing or when direct reads exceed the allowed set