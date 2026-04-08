---
name: implementation-review
description: Critically review an implementation design using only the bound review inputs and return a grounded verdict before coding.
---

# Implementation Review

Review the implementation design only.

## Required inputs from orchestration

The caller must provide:
- the implementation-design artifact under review
- the read-ledger reference
- the required read targets
- the allowed direct reads
- the fixed policy-resolution reference

Do not expand these inputs on your own.

## Rules

- review the design, not imagined future code
- check scope fit, missing files, validation gaps, response-shape clarity, and risk
- separate blocking issues from non-blocking improvements
- do not rewrite the design into implementation
- do not claim direct inspection outside the allowed direct reads
- do not return approval if a required read target is missing

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
- required revisions
- verdict
- one valid implementation_review artifact metadata block

Normal approved next step is `implementing`.

## Control-block requirements

For this skill:
- `artifact_under_review` must be the implementation-design artifact
- `read_ledger_ref` must be present
- `direct_reads_used` must be a subset of `allowed_direct_reads`
- `required_read_targets` must include the implementation-design artifact
- `missing_read_targets` must be empty for `approved`
- `missing_read_targets` must be empty for `approved_with_revisions`
- `evidence_gate` must be `failed` when a required target is missing or when direct reads exceed the allowed set