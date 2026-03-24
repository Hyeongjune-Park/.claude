---
name: implementation-review
description: Critically review a file-level implementation plan before coding. Use when the user asks to review a patch plan, critique a code change plan, find missing files or validation steps, check whether an implementation plan is too broad or too narrow, or verify that a code plan matches the approved plan. Also use for Korean requests like "구현 계획 검토", "코드 적용안 리뷰", "빠진 파일 찾기", "리스크 점검", "이 구현안 문제점 봐줘".
---

# Implementation Review

## Purpose

Critically review an implementation plan before code is written.

This skill is for review only.  
Do not implement code.

The goal is to catch:
- missing file impacts
- broken sequencing
- validation gaps
- hidden scope expansion
- mismatch between approved plan and proposed edits
- risky assumptions presented as certainty

## When to Use

Use this skill when:
- an implementation-design result needs a second-pass critique
- the user asks whether a patch plan is safe or complete
- the user asks for missing files, edge cases, or validation gaps
- the user wants to verify that the implementation plan matches the approved plan
- the change affects contracts, schema, state, config, or control flow
- the implementation plan spans multiple files

Do not use this skill when:
- there is no implementation plan yet
- the user needs a high-level product or architecture plan first
- the user is asking to review already-written code rather than a pre-code plan
- the task is trivial and the implementation path is obvious

## Review Goals

Evaluate whether the implementation plan is:
- correctly scoped
- grounded in the current codebase
- aligned with the approved plan
- complete enough to implement safely
- explicit about validation
- honest about uncertainty

## Review Checklist

Review the plan across these dimensions:

### 1. Scope Alignment
- Does the implementation plan actually match the approved plan?
- Has scope quietly expanded or narrowed?
- Are optional ideas being mixed into required work?

### 2. File Coverage
- Are any likely affected files missing?
- Are any included files unjustified?
- Are interfaces, callers, tests, config, docs, and migration surfaces considered where relevant?

### 3. Change Logic
- Is the proposed edit strategy coherent?
- Do the proposed changes fit the current code structure?
- Does the sequence make sense?

### 4. Contract / Schema / State Risk
Where relevant:
- API shapes
- validation logic
- persistence schema
- state transitions
- config and environment assumptions
- backward compatibility

### 5. Validation Coverage
- Are tests or checks specified clearly?
- Are regression risks acknowledged?
- Is there a way to detect partial success vs true completion?

### 6. Assumption Discipline
- Are inferences clearly marked?
- Are unresolved decisions still marked unresolved?
- Is uncertain reasoning being overstated?

## Output Requirements

Structure the review using these sections:

### 1. Verdict
Use one of:
- Approved
- Approved with revisions
- Not approved

### 2. What Looks Sound
- grounded strengths in the plan

### 3. Gaps / Risks / Missing Coverage
- concrete issues
- why they matter
- likely consequence if ignored

### 4. Required Revisions
- what must change before coding

### 5. Optional Improvements
- useful but non-blocking refinements

### 6. Confidence Notes
- what is well supported
- what remains assumption-based

## Verdict rules

These verdict labels must match the reviewer and planning workflow exactly.

- **Approved**
  - no blocking issue remains
  - the implementation plan is safe enough to start coding
  - remaining concerns, if any, are non-blocking and can be handled during implementation

- **Approved with revisions**
  - the implementation plan is fundamentally usable
  - but one or more revisions must still be made before coding because otherwise implementation would likely:
    - miss a required validation path
    - implement the wrong contract
    - misread file ownership or responsibility
    - introduce a preventable behavior-level mistake

- **Not approved**
  - blocking issues remain, or
  - the implementation plan is too incomplete or too risky to code safely

Do not use `Approved with revisions` for:
- optional cleanup
- wording preference
- extra non-blocking test ideas
- section-order preference
- issues already handled correctly elsewhere in the plan

## Working Rules

- Be critical, not flattering.
- Prefer concrete objections over vague discomfort.
- Point to missing file categories explicitly.
- Distinguish blocking issues from optional improvements.
- Do not rewrite the whole plan unless necessary.
- Do not approve based on plausibility alone.

## Evidence discipline

Before marking something as missing, verify that the implementation plan does not already specify it in another section.

Distinguish between:
- actually missing
- present but brief
- present but not where you expected it

Only the first case should be treated as confirmed missing coverage.

If a criticism depends on exact contract examples, expected JSON, response codes, or nullability handling, inspect the exact relevant subsection before raising it as a confirmed issue.

Do not treat an already-specified requirement as missing merely because it appears under a different heading or is phrased more tersely than you would prefer.

## Hard Constraints

Do not:
- implement code
- silently redesign the feature
- treat lack of evidence as proof of safety
- approve a plan that lacks validation
- collapse unresolved risks into settled conclusions

## Quality Bar

A good implementation review:
- catches missing impacts
- calls out shaky assumptions
- separates blocking vs non-blocking issues
- helps the next implementation step start safely
- stays tied to the actual codebase and actual plan