---
title: HARNESS_PRINCIPLES
version: 3
status: active
---

# HARNESS_PRINCIPLES

## Purpose

These are the operating principles that all harness docs, agents, and skills must follow.

## Principle 1. Separate control from production

Control decides:
- current workflow state
- next legal step
- continue vs stop

Production creates:
- plans
- reviews
- implementation designs
- code changes
- validation reports

A controller must not produce specialist work.
A specialist must not replace workflow control.

## Principle 2. Prefer structured control data over prose

Workflow decisions must prefer:
1. `.claude/state/<feature-slug>.json`
2. valid workflow artifact control blocks
3. persisted policy-resolution input
4. persisted read-ledger input
5. workflow-state-machine rules
6. grounded inspection
7. freeform prose

## Principle 3. Machine-readable state is authoritative

The main workflow authority is not human-facing documentation.
Human-facing docs are optional persistence only.

## Principle 4. One legal step at a time

The harness advances in single legal transitions.
It must not pre-schedule the entire workflow in a single decision.

## Principle 5. Persist fixed inputs before specialist work

Before a specialist stage runs, the orchestration layer must persist the fixed inputs that stage is allowed to rely on.

These include:
- normalized policy resolution
- review-stage read ledgers
- current authoritative state context

Do not allow specialists to re-resolve policy docs or invent direct reads.

## Principle 6. Strict root discipline

For feature work, inspect only the active project root.
Do not borrow implementation patterns, toolchain assumptions, or source structure from sibling projects.

Allowed exception:
- global fallback resolution for required policy docs only

## Principle 7. Evidence discipline is enforced by input binding

A stage may only claim direct inspection for files it actually read.

For review stages, the orchestration layer must bind:
- the artifact under review
- the required read targets
- the allowed direct reads

The reviewer must not expand direct inspection beyond the allowed direct reads.

Anything not directly inspected must be labeled as:
- provided
- inferred
- unverified

Do not approve based on invented reads.

## Principle 8. Policy resolution must be single-source and fixed

For each required policy doc, the harness must produce exactly one resolved outcome:
- `project_local`
- `global_fallback`
- `missing`

If a local copy exists, it is authoritative.
Do not treat local and global copies as co-equal sources for the same required doc.

Once resolved for a run, policy resolution is fixed input.
Specialist stages must not reinterpret it.

## Principle 9. Review stages are slot-based, not freeform evidence claims

Review artifacts must explicitly include:
- artifact under review
- read ledger reference
- required read targets
- allowed direct reads
- direct reads used
- missing read targets
- evidence gate result
- verdict

A review artifact that claims direct inspection beyond its read ledger is invalid.

## Principle 10. Stop over false continuation

Stop when:
- required policy docs are missing
- policy resolution is inconsistent
- required artifacts are missing
- required read ledgers are missing
- state and artifact disagree
- approval is stale
- human input is required
- the next legal step cannot be determined safely
- a review artifact exceeds its bound direct-read set
- a review artifact has non-empty missing read targets
- a review artifact claims approval with failed evidence gate

## Principle 11. Keep specialist stages narrow

Planning should not implement.
Implementation design should not dump full file contents as if it were implementation.
Review stages should not rewrite the work they are reviewing.
Implementation should not broaden scope.

## Principle 12. Keep shared rules centralized

Shared workflow rules belong in the shared docs.
Skills and agents should reference them, not re-specify entire policy stacks unless necessary for safe behavior.

## Summary

The harness should be:
- state-authoritative
- root-disciplined
- evidence-bound
- policy-consistent
- stoppable
- role-separated