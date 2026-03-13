---
name: plan-save
description: Convert planning, review, worklog, or implementation outputs into a save-ready document mapping. Use when the current session has produced durable information that should be organized into persistent document buckets such as context, plan, tasks, decisions, or risks.
---

Use this skill to prepare a save-ready document plan from the current session's durable outputs.

This skill is for save planning only.
Do not implement code.
Do not generate patches.
Do not claim that files were created, updated, or persisted unless that actually happened in the current session.

## When to use this skill

Use this skill when:
- planning produced a reusable implementation plan
- reviewing produced durable revision guidance or approval state
- worklog-update produced a stable handoff summary
- implementation or debugging established facts that should be preserved
- the user wants to organize current outputs into persistent document buckets
- the user asks for:
  - save plan
  - document mapping
  - save-ready summary
  - 어떤 문서에 저장할지 정리
  - 문서 구조로 나눠줘
  - 저장 가능한 형태로 정리해줘
  - plan/context/tasks로 나눠줘

Do not use this skill for:
- trivial one-line summaries
- direct implementation requests
- automatic file-writing workflows
- pretending that unresolved or unapproved work is ready to be stored as settled decisions

## Goal

Produce a save-ready document plan that:
- identifies which session outputs are durable enough to preserve
- maps them into persistent buckets such as context, plan, tasks, decisions, and risks
- excludes low-value or unstable material
- respects approval state, evidence strength, and current scope
- gives the next session a clear, manual save path

## Required workflow

Follow this sequence:

1. Identify the source material to be considered for saving:
   - planning result
   - reviewing result
   - worklog update
   - implementation findings
   - debugging findings
   - explicit user decisions

2. Read project-level guidance first when present:
   - root `CLAUDE.md`
   - existing context, plan, tasks, decisions, risks, or worklog documents
   - relevant planning, review, or worklog outputs in the conversation

3. Inspect only the minimum relevant files or documents needed to decide:
   - what should be saved
   - where it should be saved
   - what should not be saved

4. Classify candidate information into:
   - confirmed durable fact
   - approved or explicitly accepted decision
   - provisional plan detail
   - open task
   - accepted or unresolved risk
   - unstable or low-value material

5. Map durable information into document buckets.

6. Produce a save-ready draft without claiming that any save actually happened.

## Save rules

- Save only information with durable future value.
- Do not save every detail from the conversation.
- Do not save inferred intent as a settled decision.
- Do not save reviewer-blocked plan details as accepted decisions.
- Prefer append or merge guidance over destructive replacement guidance unless replacement is clearly necessary.
- If existing docs were not inspected, do not pretend a safe merge strategy is known.
- If review status is `Not approved`, do not save implementation plan details into `plan` unless they are explicitly marked as provisional and minimal.
- If review status is `Not approved`, keep unresolved design details out of `decisions`.
- If review status is `Approved with revisions`, save unresolved items primarily into `tasks` and `risks`, not as settled decisions.
- If review status is `Approved with revisions`, keep design details in `plan` unless they were explicitly accepted by the user or clearly marked as settled by review.
- Do not promote provisional implementation details into `decisions` merely because they were not challenged.
- Prefer storing unresolved implementation content in `tasks` and `risks` instead.


## Bucket rules

Use these buckets when relevant:

- `context`
  - current project state
  - important constraints
  - confirmed architecture or workflow facts

- `plan`
  - active implementation plan
  - ordered steps still intended for execution
  - scoped change strategy
  - If the current plan is not approved, store only a minimal placeholder plan or skip the bucket entirely.

- `tasks`
  - next actions
  - blockers
  - open implementation items
  - required follow-ups

- `decisions`
  - explicitly accepted design decisions
  - approved choices
  - intentionally rejected alternatives when that matters later

- `risks`
  - accepted risks
  - unresolved risks
  - known technical weaknesses
  - deferred issues

## Exclusion rules

Exclude:
- repeated conversation wording
- long narrative recap
- low-confidence speculation
- unresolved debate that has not been narrowed
- implementation detail that is not durable
- unapproved design details presented only as proposals
- material that duplicates a stronger existing statement without adding value
- Do not introduce broader redesign options or new solution branches that were not part of the current approved scope.

## Output requirements

Return a save-ready draft, not code.

Use exactly the following section structure and headings:

# Save Plan Draft

## Save Scope
State what outputs are being considered for saving and why.

## Source Inputs
List the relevant source material used for this save plan.

When helpful, distinguish between:
- inspected directly
- taken from conversation outputs
- listed but not inspected

## Save Decisions
State the high-level save decisions, including:
- what should be saved
- what should not be saved
- what is too unstable to save yet

## Target Buckets
For each relevant bucket, list:
- whether it should be updated now
- why it belongs there
- whether the content is confirmed, accepted, provisional, or unresolved

Use only relevant buckets.

## Excluded From Save
List material that should not be saved yet.

For each item, explain why:
- low value
- unstable
- duplicated
- not approved
- not verified
- out of scope

## Recommended Save Order
State the best manual save order.

Prefer a small number of steps.

## Save-Ready Content
Provide concise save-ready content grouped by bucket.

Use this structure:

### context
Only if relevant.

### plan
Only if relevant.

### tasks
Only if relevant.

### decisions
Only if relevant.

### risks
Only if relevant.

Within each bucket:
- keep it concise
- keep it durable
- do not repeat the same point across buckets unless necessary

## Style rules

- Be concrete
- Be skeptical
- Be selective
- Optimize for later persistence and reuse
- Prefer durable facts over narrative recap
- Keep confidence proportional to evidence
- Keep section headings exactly as specified
- Match the user's language when practical
- If the user is writing in Korean, prefer answering in Korean

## Notes

This skill prepares information for persistence.
It does not perform persistence itself.

It should be used after planning, reviewing, worklog-update, implementation, or debugging when the session has produced information worth preserving.

This skill should remain separate from any future file-writing or hook-based automation.