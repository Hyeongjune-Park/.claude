---
name: implementing
description: Execute an approved implementation plan in code with scoped edits, targeted validation, and review-ready reporting. Use when the user wants actual code changes based on an approved plan or implementation-design. Also use for Korean requests like "구현해줘", "이 설계대로 코드 반영해줘", "실제로 수정해줘", "이제 코딩 진행해줘", "승인된 계획대로 구현해줘".
---

# Implementing

## Purpose

Execute an approved implementation plan in the current codebase.

This skill is for implementation only.
It is the code-writing step in the workflow.

The goal is to:
- apply an already-approved implementation plan
- keep edits scoped
- validate the changed behavior
- produce a review-ready implementation result

## When to Use

Use this skill when:
- implementation-design already exists and the work is ready to code
- implementation-review already approved the design
- the user wants the approved design applied to the repository
- the user wants actual code changes instead of more planning
- a feature, fix, or small scoped refactor is ready for execution

Do not use this skill when:
- the work still needs high-level planning
- implementation-design does not exist yet for non-trivial work
- implementation-review has not approved the design
- the request is primarily for critique, planning, or document writing
- the active task is still ambiguous enough that coding would force behavior-level guessing

## Required Inputs

Prefer to work from:
1. the approved implementation-design result
2. the latest implementation-review result
3. the relevant current codebase
4. any plan, spec, or docs that define the approved behavior
5. known scope limits and non-goals

If required inputs are missing, state the blocker instead of silently inventing the missing decisions.

## Approval Gate Rules

Before implementation, confirm the latest applicable implementation-review status.

Proceed only if the latest relevant implementation-review result is:
- **Approved**

Do not proceed if it is:
- **Approved with revisions**
- **Not approved**

For trivial tasks that genuinely do not require implementation-review, state explicitly why implementation may proceed without that gate.

Do not treat vague confidence or informal approval as equivalent to an explicit approved review result.

Likewise, do not treat successful code edits or automated test success alone as a substitute for honest validation reporting.

## Core Responsibilities

Produce an implementation result that:
- applies the approved design to the actual codebase
- keeps the change inside the approved scope
- identifies the actual changed files
- records the validation that was run
- states unresolved issues honestly
- leaves a clear completion gate for review or follow-up

## Required Workflow

Follow this sequence:

1. Identify the active implementation target.
   - what feature or fix is being implemented
   - which approved implementation-design result applies
   - which implementation-review result authorized coding

2. Inspect project-level guidance when relevant:
   - project root `CLAUDE.md`
   - relevant plan, spec, worklog, or feature docs
   - only then the code files needed for implementation

3. Check the approval gate.
   - if implementation-review is not explicitly **Approved**, stop
   - if the design and latest review do not refer to the same feature, stop
   - if the approval is stale because the design changed materially afterward, stop

4. Define the active scope before editing.
   - in-scope behavior
   - out-of-scope behavior
   - likely changed files
   - required validation

5. Inspect only the code needed to implement safely.
   - relevant modules
   - likely affected callers
   - relevant tests
   - config or schema surfaces if they materially affect the change

6. Call the `implementer` subagent with:
   - the active scope
   - the approved implementation-design
   - the approved implementation-review result
   - only the source details actually inspected
   - any required validation expectations

7. If the result clearly shows a narrow, fixable omission, you may do one follow-up implementation pass.
   Examples:
   - one missed in-scope test update
   - one clearly in-scope wiring omission
   - one validation command that should obviously be rerun after a small fix

8. Do not use the follow-up pass to absorb unrelated cleanup or documentation maintenance.
   - implementation may note doc drift
   - but doc cleanup should remain a follow-up unless it was explicitly in scope

9. Do not loop indefinitely.
   - no more than one follow-up implementation pass
   - if the work is still not review-ready, return the result honestly

10. Return a structured implementation result.
   - the result must distinguish:
     - implemented code
     - validation actually run
     - remaining follow-up

## Scope discipline rules

- Do not quietly widen scope during implementation.
- Do not mix unrelated cleanup into the change.
- If an unrelated defect is discovered, record it under open issues unless it blocks the approved implementation.
- If the approved plan becomes unsafe because of newly inspected code, stop and state the blocker clearly.
- Preserve explicitly unchanged behavior.

## Validation discipline rules

- Validation is required for any non-trivial implementation claim.
- Prefer the narrowest useful checks first.
- If broader project validation is appropriate, include it only when it materially increases confidence for the changed behavior.
- If a check was not run, say so explicitly.
- If a command failed, say so explicitly.
- Do not hide validation gaps behind optimistic wording.

## Verification reporting rules

Keep validation reporting split into three buckets whenever relevant:
- automated checks
- runtime manual checks
- not run / not confirmed

Do not summarize partial runtime verification as if the whole runtime behavior was confirmed.

If runtime checks were affected by shell quoting, request tooling, or OS-specific command behavior, report that as an environment-specific verification limitation.

For Windows PowerShell, prefer PowerShell-native request examples such as `Invoke-RestMethod` when raw `curl.exe` payload quoting may distort JSON bodies.

## Stop Conditions

Stop and return a blocker instead of forcing implementation when:
- approval gate is not satisfied
- the approved design conflicts with the actual code in a behavior-shaping way
- safe implementation would require unapproved scope expansion
- required validation cannot be identified with reasonable confidence
- the task has turned back into planning rather than implementation

## Output Requirements

Use exactly the following section structure and headings:

# Implementation Result

## Implementation Target
State what was implemented or attempted.

## Preconditions Checked
State:
- which implementation-design result was used
- which implementation-review result was used
- whether the approval gate was satisfied

## Source Inputs
List the code files, docs, plans, and review outputs actually inspected in this session.

If relevant, distinguish between:
- inspected directly
- provided by caller

## Active Scope
### In Scope
Bullet list

### Out of Scope
Bullet list

## Applied Changes
State what actually changed.

For each changed file, briefly explain:
- what changed
- why it changed
- any important contract, validation, or control-flow implication

If no files changed, say so explicitly.

## Validation
List only the checks actually performed.

Group them under these labels when relevant:
- Automated checks
- Runtime manual checks
- Not run / not confirmed

For each check, include:
- command or method used
- what it was intended to validate
- pass / fail / not run
- any limitation that affects confidence

If runtime verification was affected by shell quoting, request tooling, or environment-specific behavior, say so explicitly instead of implying application failure.

## Open Issues
List unresolved issues, deferred follow-ups, documentation drift, review-noted caveats, and verification gaps that remain after implementation.

Do not omit:
- non-blocking doc fixes
- runtime checks still not manually confirmed
- environment-specific request/validation caveats
- reviewer-identified follow-up that was not addressed in the implementation step

If there are none, say "None." only when code, docs, and meaningful validation are all aligned for the implemented scope.

## Completion Gate
Choose exactly one:
- Ready for review
- Needs follow-up before review
- Stopped due to blocker

The choice must match the evidence above.

## Recommended Next Action
State the single best next workflow step.

Prefer:
- `/reviewing` after a review-ready implementation result
- `/worklog-update` after review or when implementation findings should be persisted
- a concrete blocker-resolution action when the completion gate is blocked

Avoid generic next steps such as:
- archive or zip the project
- move to the next feature
- continue generally
unless that is truly the immediate safe next action.

## Style rules

- Be direct
- Be concrete
- Keep scope boundaries visible
- Prefer facts over reassurance
- Keep confidence proportional to inspected evidence and validation
- Do not hide blockers or failed validation
- Do not rewrite the workflow into a new plan
- Keep section headings exactly as specified