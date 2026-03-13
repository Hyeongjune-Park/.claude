---
name: planning
description: Run a structured planning workflow for non-trivial work. Use when the task is risky, spans multiple files, changes behavior, adds config or validation, or needs a reviewable implementation plan before coding. Also use for Korean requests like "계획", "구현 전 계획", "설계안", "작업 전에 정리", "플랜 짜줘".
---

Use this skill to produce a reviewable planning result before implementation.

This skill is for planning only.
Do not implement code.
Do not generate patches.
Do not claim that the plan is approved unless the reviewer result explicitly supports that.

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
5. Call the `planner` subagent with:
   - the task
   - the requested scope
   - only evidence that was actually verified
   - any inferred statements clearly labeled as inferred
6. If the task is review-worthy, call the `reviewer` subagent on the planner draft.
7. Return the result in a separated structure:
   - planner draft
   - reviewer result, if used
   - gate
   - recommended next action

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
- Under `Planner Draft` and `Reviewer Result`, paste the subagent outputs verbatim.
- Do not rewrite, compress, reformat, or reinterpret those subagent outputs.
- If wrapper-level interpretation is needed, put it only in `Gate` and `Recommended Next Action`.
- If reviewer status is `Not approved`, the gate must also be `Not approved for implementation`.
- If reviewer status is `Approved with revisions`, the gate must reflect that implementation should wait for revision unless the reviewer clearly allows immediate execution.
- Preserve the planner's and reviewer's exact headings in their own sections.
- If `Planner Draft` or `Reviewer Result` is not pasted verbatim from the subagent output, do not claim it is "as-is", "verbatim", or "원문 그대로".
- Do not restate evidence status inside `Planner Draft` or `Reviewer Result` differently from the wrapper's `Evidence Summary`.
- If exact subagent output cannot be preserved, say so explicitly instead of silently rewriting it.
- Wrapper-authored interpretation belongs only in `Gate` and `Recommended Next Action`.
- Do not silently upgrade provisional plan details into settled decisions.

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

## Planner Draft
Paste the planner output as-is.

If the planner output is unavailable, say so explicitly.

## Reviewer Result
Paste the reviewer output as-is if reviewer was used.

If reviewer was not used, say `Reviewer not used.`

## Gate
Choose exactly one:
- Approved for implementation
- Revise plan before implementation
- More evidence needed before implementation

Gate selection rules:
- If reviewer status is `Approved`, use `Approved for implementation`
- If reviewer status is `Approved with revisions`, normally use `Revise plan before implementation`
- If reviewer status is `Not approved`, use `Revise plan before implementation`
- If reviewer was not used and the evidence is incomplete, use `More evidence needed before implementation`

## Recommended Next Action
State the single best next step.

This should depend on the gate.
Examples:
- revise the plan
- inspect a missing file
- resolve one blocking decision
- start implementation

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