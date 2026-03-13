---
name: reviewing
description: Run a structured critical review on a plan, proposal, implementation approach, or result. Use when the work is risky, changes behavior or contracts, spans multiple files, or needs a second-pass critique before implementation or handoff. Also use for Korean requests like "검토", "리뷰", "비판적으로 봐줘", "문제점 찾아줘", "구현 전 점검".
---

Use this skill to produce a structured review result.

This skill is for resview only.
Do not implement code.
Do not generate patches.
Do not rewrite the entire target unless the review target is fundamentally unusable.

## When to use this skill

Use this skill when:
- a plan draft needs a second-pass critique
- a proposed change affects behavior, return shapes, config, validation, or control flow
- a task spans multiple files
- a result should be checked before implementation or handoff
- the user asks for review, critique, validation, or a second opinion
- the user asks for:
  - "검토해줘"
  - "리뷰해줘"
  - "문제점 찾아줘"
  - "구현 전 점검해줘"
  - "비판적으로 봐줘"

Do not use this skill for:
- trivial edits with obvious scope and low risk
- direct implementation requests
- broad opinion-only commentary with no execution relevance

## Goal

Produce a review result that:
- checks the target critically
- distinguishes inspected evidence from inferred concerns
- separates blocking issues from non-blocking gaps
- produces a clear approval verdict
- leaves one clear next action

## Required workflow

Follow this sequence:

1. Identify what is being reviewed:
   - plan draft
   - proposed change
   - implementation approach
   - completed result
2. Read the review target carefully.
3. If the review includes source-specific claims, inspect the relevant files before issuing source-level criticism.
4. Classify evidence into:
   - **Inspected directly**
   - **Reviewed as provided text only**
   - **Inferred concern**
5. Call the `reviewer` subagent with:
   - the review target
   - the requested review focus
   - only source details that were actually verified
6. Return the reviewer result without rewriting away its evidence distinctions or verdict.

## Evidence discipline rules

These rules are strict:

- Do not present source-specific criticism as confirmed unless the relevant source was inspected in the current session.
- If the review is based only on text the user or planner provided, say so explicitly.
- If a concern is inferred rather than verified, keep it labeled as inferred.
- Do not invent exact line numbers.
- Do not choose between unresolved implementation options unless the target or inspected evidence clearly supports one option.
- Do not broaden the review scope to adjacent projects or unrelated code unless required by the user's request.

## Wrapper behavior rules

- Do not rewrite the reviewer output into a softer summary.
- Do not collapse blocking issues and non-blocking gaps into one list.
- Do not change the verdict wording.
- Preserve the reviewer's exact headings inside the reviewer section.
- If `Reviewer Draft` is not pasted verbatim from the subagent output, do not claim it is "as-is", "verbatim", or "원문 그대로".
- Do not restate evidence status inside `Reviewer Draft` differently from the wrapper's `Evidence Summary`.
- If the wrapper adds interpretation, keep it only in `Final Verdict` and `Recommended Next Action`.
- Do not repair or improve the reviewer's structure by silently rewriting its contents.
- Under `Reviewer Draft`, paste the reviewer output verbatim.
- Do not restate the reviewer's sections in wrapper-authored prose.
- Do not move confirmed facts into assumption sections or move assumptions into confirmed sections.
- Do not turn the next action into a silent design choice unless the reviewed target already supports that choice.
- If the review is text-only, do not imply that source verification happened.
- If additional source inspection was performed, state exactly which files were inspected.

## Output requirements

Return the review result using exactly the following structure and headings:

# Reviewing Result

## Review Scope
State what is being reviewed and what the review focuses on.

## Evidence Summary
List evidence in relevant groups:
- Inspected directly
- Reviewed as provided text only
- Inferred concerns

## Reviewer Draft
Paste the reviewer output as-is.

If reviewer output is unavailable, say so explicitly.

## Final Verdict
Repeat exactly one verdict from the reviewer:
- Approved
- Approved with revisions
- Not approved

Do not paraphrase.

## Recommended Next Action
State the single best next step.

This should follow the verdict.
Examples:
- implement now
- revise the plan
- inspect missing source first
- clarify one unresolved decision

## Style rules

- Be concrete
- Be skeptical
- Keep confidence proportional to evidence
- Preserve the reviewer verdict exactly
- Preserve inspected vs inferred distinctions
- Keep section headings exactly as specified
- Match the user's language when practical
- If the user is writing in Korean, prefer answering in Korean

## Notes

This skill is a workflow wrapper around the reviewer.
Its purpose is to standardize review flow and preserve review integrity, not to overwrite the reviewer with a blended summary.