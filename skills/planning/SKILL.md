---
name: planning
description: Run a structured planning workflow for non-trivial work. Use when the task is risky, spans multiple files, changes behavior, adds config or validation, or needs a reviewable implementation plan before coding. Also use for Korean requests like "계획", "구현 전 계획", "설계안", "작업 전에 정리", "플랜 짜줘".
---

Use this skill to produce a reviewable planning result before implementation.

This skill is for planning only.
Do not implement code.
Do not generate patches.
Do not claim that the plan is approved unless the latest reviewer result explicitly supports that.
Do not present provisional or revised-but-unapproved details as settled decisions.

## When to use this skill

Use this skill when:
- the task is non-trivial
- the work spans multiple files
- the work changes behavior, contracts, control flow, config, validation, or data shape
- the user wants a plan before implementation
- the task is risky enough that implementation should not start from an informal answer
- the user asks for:
  - a plan
  - implementation planning
  - a design draft
  - pre-coding scoping
  - "계획 짜줘"
  - "구현 전에 정리해줘"
  - "설계안 써줘"
  - "작업 전에 플랜 만들어줘"

Do not use this skill for:
- trivial one-file edits with obvious scope
- direct implementation requests that do not need planning
- broad brainstorming with no implementation intent

## Goal

Produce a planning result that:
- captures the real goal and scope
- records what evidence was actually checked
- produces a reviewable planner draft
- runs reviewer when the task is review-worthy
- allows one planner revision pass and one second review pass when needed
- produces a final plan only when approval conditions are satisfied
- keeps planner output and reviewer output separate
- leaves a clear gate before implementation

## Required workflow

Follow this sequence:

1. Clarify the task operationally from the user's request.
2. Read project-level guidance first when present:
   - project root `CLAUDE.md`
   - relevant worklog, plan, context, or task documents
   - only then relevant source/config/docs
3. Inspect only the files needed to plan safely.
4. Before calling the planner, classify evidence into:
   - **Inspected directly**
   - **Listed but not inspected**
   - **Inferred from context**
5. Call the `planner` subagent for **Planner Draft (Round 1)** with:
   - the task
   - the requested scope
   - only evidence that was actually verified
   - any inferred statements clearly labeled as inferred
6. If the task is review-worthy, call the `reviewer` subagent on **Planner Draft (Round 1)**.
7. If **Reviewer Result (Round 1)** is `Approved`:
   - call the `planner` once more to produce **Final Plan**
   - the final plan must stay within the approved draft and reviewer-confirmed scope
   - stop the review loop
8. If **Reviewer Result (Round 1)** is `Approved with revisions` or `Not approved`:
   - call the `planner` again with the reviewer feedback to produce **Planner Draft (Round 2)**
   - this second planner pass must revise the plan rather than restart from scratch unless the reviewer explicitly requires a rewrite
9. Call the `reviewer` on **Planner Draft (Round 2)**.
10. If **Reviewer Result (Round 2)** is `Approved`:
   - call the `planner` once more to produce **Final Plan**
   - the final plan must reflect the approved revised draft
11. If **Reviewer Result (Round 2)** is still `Approved with revisions` or `Not approved`:
   - stop
   - do not issue a final approved plan
   - return the latest planner/reviewer results and a non-approval gate
12. If reviewer is not used because the task is clearly low-risk and tightly scoped:
   - Planner Draft (Round 1) may serve as the final plan
   - say explicitly that reviewer was not used

## Review-worthy tasks

You must run the reviewer when any of the following apply:
- multi-file change
- new config key or config behavior
- new validation rule
- control-flow ordering change
- data shape or message contract change
- return value or caller behavior change
- risky plan with meaningful assumptions
- user explicitly asks for critique or second-pass review

You may skip reviewer only when the task is clearly low-risk and tightly scoped.

## Review loop limits

These limits are strict:

- Maximum planner draft rounds: **2**
- Maximum reviewer rounds: **2**
- Maximum final-plan authoring step: **1**
- Do not run a third reviewer pass.
- Do not run a third planner draft pass inside this skill.
- Do not loop indefinitely.
- Do not treat `Approved with revisions` after Round 2 as implementation approval.

The longest allowed path is:

- Planner Draft (Round 1)
- Reviewer Result (Round 1)
- Planner Draft (Round 2)
- Reviewer Result (Round 2)
- Final Plan **only if** the latest reviewer result is `Approved`

## Round 2 reviewer anti-goalpost rules

Round 2 reviewer is not a fresh unrestricted reviewer.
Round 2 reviewer must primarily act as a verification pass on the revised draft.

### Round 2 reviewer must prioritize:
- whether Round 1 blocking issues were actually resolved
- whether the revised draft introduced new problems
- whether newly inspected evidence reveals a real blocking issue that could not have been raised earlier

### Round 2 reviewer may raise a new blocker only if at least one of the following is true:
- the revised planner draft introduced a new risk, contradiction, or scope problem
- new evidence was directly inspected after Round 1 and that evidence reveals a blocking issue
- Round 1 already pointed at the issue implicitly, and Round 2 is only making that blocker more explicit or precise

### Round 2 reviewer must not:
- introduce a new blocker that could reasonably have been raised in Round 1 but was simply missed
- upgrade optional improvements into required revisions
- expand scope beyond the requested task
- demand broad cleanup, refactor, or architecture polish outside planning scope
- keep moving the approval bar based on style preference or "could be cleaner" reasoning

## Round 2 planner non-regression rules

Round 2 planner is revising a draft, not generating a fresh plan from scratch.

### Round 2 planner must:
- preserve the accepted scope and overall plan structure unless reviewer feedback explicitly requires restructuring
- revise the draft to address reviewer-blocking issues directly
- keep previously stable decisions stable unless there is a valid reason to change them
- state clearly when a reviewer-requested fix requires a related adjustment elsewhere

### Round 2 planner must not:
- silently change previously stabilized design decisions
- replace a settled return shape, ownership boundary, naming choice, or control-flow contract without justification
- reopen decisions that reviewer did not challenge
- turn a revision pass into a new design exploration

### A Round 2 design change is allowed only if:
- the reviewer explicitly requested that change, or
- newly inspected evidence justifies the change

If Round 2 planner changes a previously stable design choice, it must say why the change is necessary.

## Evidence discipline rules

These rules are strict:

- Do not pass uninspected source details to the planner as confirmed facts.
- Do not label something "directly verified" unless it was actually opened or read in the current session.
- If something was only seen in a file listing, say **listed but not inspected**.
- If something is inferred from the request or surrounding context, label it as inferred.
- Do not invent exact line numbers.
- Do not broaden scope to adjacent projects, playgrounds, or repos unless required by the requested scope or needed to verify a claim.

## Wrapper behavior rules

- Do not merge planner and reviewer outputs into a single rewritten pseudo-result.
- Do not summarize away important disagreement between planner and reviewer.
- Do not restate reviewer-blocked details as established implementation decisions.
- Under planner/reviewer sections, paste the subagent outputs verbatim.
- Do not rewrite, compress, reformat, or reinterpret those subagent outputs.
- If wrapper-level interpretation is needed, put it only in `Gate` and `Recommended Next Action`.
- If reviewer status is `Not approved`, the gate must also be `Revise plan before implementation`.
- If reviewer status is `Approved with revisions`, the gate must reflect that implementation should wait for revision unless the reviewer clearly allows immediate execution.
- Preserve the planner's and reviewer's exact headings in their own sections.
- If a planner/reviewer section is not pasted verbatim from subagent output, do not claim it is "as-is", "verbatim", or "원문 그대로".
- Do not restate evidence status inside planner/reviewer sections differently from the wrapper's `Evidence Summary`.
- If exact subagent output cannot be preserved, say so explicitly instead of silently rewriting it.
- Wrapper-authored interpretation belongs only in `Gate` and `Recommended Next Action`.
- Do not silently upgrade provisional plan details into settled decisions.
- Do not treat `Approved with revisions` as equivalent to `Approved`.
- Do not treat reviewer feedback as a settled decision until a revised planner draft has absorbed it and the latest reviewer result approves it.
- If Round 2 reviewer is still not `Approved`, do not produce a falsely finalized plan.

## Final-plan rules

- `Final Plan` is allowed only when:
  - reviewer was skipped for a clearly low-risk task, or
  - the latest reviewer result is `Approved`
- `Final Plan` must not introduce new decisions outside the latest approved planner draft and reviewer-confirmed scope.
- `Final Plan` should be cleaner than the draft, but not broader.
- If no final plan is allowed, say so explicitly in the `Final Plan` section.

## Output requirements

Return the planning result using exactly the following structure and headings:

# Planning Result

## Task
State the task being planned.

## Scope
State the requested planning scope.

## Evidence Summary
List the evidence used for planning in three groups when relevant:
- Inspected directly
- Listed but not inspected
- Inferred from context

Do not include unverified source detail as inspected evidence.

## Planner Draft (Round 1)
Paste the planner output as-is.

If the planner output is unavailable, say so explicitly.

## Reviewer Result (Round 1)
Paste the reviewer output as-is if reviewer was used.

If reviewer was not used, say `Reviewer not used.`

## Planner Draft (Round 2)
Paste the second planner output as-is if a revision round was used.

If no second planner round was used, say `Second planner round not used.`

## Reviewer Result (Round 2)
Paste the second reviewer output as-is if a second review round was used.

If no second reviewer round was used, say `Second reviewer round not used.`

## Final Plan
- If final-plan rules allow it, provide the final plan here.
- If final-plan rules do not allow it, say exactly why no final plan was issued.

## Gate
Choose exactly one:
- Approved for implementation
- Revise plan before implementation
- More evidence needed before implementation

Gate selection rules:
- If reviewer was skipped and evidence is sufficient, use `Approved for implementation`
- If the latest reviewer status is `Approved`, use `Approved for implementation`
- If the latest reviewer status is `Approved with revisions`, use `Revise plan before implementation`
- If the latest reviewer status is `Not approved`, use `Revise plan before implementation`
- If reviewer was not used and the evidence is incomplete, use `More evidence needed before implementation`

## Recommended Next Action
State the single best next step.

This should depend on the gate.
Examples:
- revise the plan
- inspect a missing file
- resolve one blocking decision
- start implementation

If review Round 2 still did not approve the plan, prefer a revision-focused next action rather than implementation.

## Style rules

- Be concrete
- Be skeptical
- Keep confidence proportional to evidence
- Keep planner and reviewer outputs separate
- Prefer explicit gates over implied readiness
- Do not hide uncertainty
- Keep section headings exactly as specified
- Match the user's language when practical
- If the user is writing in Korean, prefer answering in Korean

## Notes

This skill is a workflow wrapper around the planner and reviewer.
It should standardize process, not overwrite the planner's or reviewer's findings.
Its job is to make planning safer, more reviewable, and easier to hand off.
Its review loop is limited: at most two reviewer passes, with one planner revision pass between them.
Round 2 review is a constrained re-check, not an unrestricted new review.