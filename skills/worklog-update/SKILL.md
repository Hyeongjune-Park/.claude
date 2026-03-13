---
name: worklog-update
description: Capture the current work state as a handoff-ready worklog update. Use after planning, review, implementation, debugging, or decision-making when the next session needs a reliable summary of confirmed state, open work, risks, and next action. Also use for Korean requests like "작업 인계 정리", "현재 상태 정리", "다음 세션용으로 정리", "작업 기록 남겨줘".
---

Use this skill to produce a structured worklog update that a later session can safely reuse.

This skill is for documentation and handoff only.
Do not implement code.
Do not generate patches.
Do not claim that files were saved, updated, or persisted unless that actually happened in the current session.

## When to use this skill

Use this skill when:
- the current task state should be recorded for a later session
- planning or reviewing produced useful outputs that should be preserved
- implementation or debugging changed the current understanding of the work
- the session has become long enough that context loss is likely
- the user asks for:
  - a worklog
  - a handoff summary
  - current status
  - progress summary
  - next-session context
  - "작업 인계 정리"
  - "현재 상태 정리"
  - "다음 세션용으로 정리"
  - "작업 기록 남겨줘"
  - "문서화해서 넘길 수 있게 정리해줘"

Do not use this skill for:
- trivial one-line status notes with no future reuse value
- direct implementation requests that should proceed immediately
- broad narrative recaps with no handoff value
- pretending to recover decision history that was never recorded

## Goal

Produce a worklog update that:
- states what is being recorded
- captures the currently confirmed state
- separates confirmed facts from inferred or unverified statements
- records completed work, explicitly accepted decisions, and strongly verified facts
- makes open work and risks explicit
- leaves one clear recommended next action
- can later be mapped into persistent documents such as context, plan, tasks, decisions, or risks

## Important limitation

This skill cannot reconstruct missing decision history that was never recorded.

If earlier sessions did not leave reliable records, this skill can only summarize:
- currently inspected code or documents
- currently visible outputs in the conversation
- clearly stated user instructions
- contradictions or gaps found during inspection

Do not present missing historical reasoning as if it were recovered fact.

## Required workflow

Follow this sequence:

1. Identify what is being recorded:
   - current task state
   - plan outcome
   - review outcome
   - implementation progress
   - debugging findings
   - session handoff state

2. Read project-level guidance first, if present:
   - root `CLAUDE.md`
   - relevant worklog, plan, context, tasks, or decision documents
   - relevant planning or review outputs available in the conversation

3. Inspect only the minimum relevant files needed to verify the recorded state.

4. Classify every important statement into one of these evidence levels:
   - **Inspected directly**: the file or output was actually opened/read in this session
   - **Listed but not inspected**: existence was seen in a listing, but contents were not read
   - **Inferred from context**: a reasonable interpretation based on inspected evidence or explicit user context, but not directly verified
   - **Not verified**: mentioned as a possibility, unresolved question, or missing confirmation

5. Distinguish clearly between:
   - confirmed current state
   - completed or established facts
   - open work and risks
   - unverified assumptions or gaps

6. Produce a structured worklog update that is useful for the next session or handoff.

## Project context rules

Before writing the worklog update:
- do not assume progress that is not supported by inspected files, visible conversation context, or explicit user statements
- prefer inspected facts over remembered impressions
- if documents and code disagree, record the disagreement explicitly
- do not turn partial work into a false completion claim
- inspect only the files needed to capture the current state safely
- do not expand the recording scope to adjacent projects, playgrounds, or related repos unless:
  - the user explicitly asks for them, or
  - they are required to verify a claim inside the requested scope
- if extra context is read, state explicitly why it was needed

## Recording rules

The worklog update must prioritize durable operational value over chronology.

Record:
- what is currently true
- what was established in this session
- what remains unresolved
- what the next session should do first

Do not record:
- every attempted idea
- long narrative history with no future execution value
- unsupported confidence
- rationale that was never actually captured
- inferred intent as confirmed fact

If planning or reviewing happened earlier in the workflow:
- preserve only the useful result
- do not paste the entire plan or review unless the user explicitly asks
- summarize only what the next step actually needs

## Evidence discipline rules

These rules are strict:

- Do not describe a file as inspected unless it was actually opened or read in this session.
- Do not describe a file's contents based only on a glob/listing result.
- If a file was only seen in a listing, say that it was **listed but not inspected**.
- Do not place inferred intent, inferred completeness, or inferred rationale in **Confirmed Current State** or **Completed / Established**.
- Put inferred or uncertain statements in **Unverified / Needs Confirmation**.
- If a statement depends on mixed evidence, say so explicitly.
- If the evidence is weak, the wording must stay weak.
- Do not include exact line numbers unless they were directly verified in the current session and are likely to remain stable.
- If exact line numbers were not verified, refer to the function, block, or file section instead.
- Do not use more precision than the evidence supports.
- Do not describe the same item as confirmed in one section and unverified in another.
- If a statement depends on mixed evidence, keep the wording consistent across sections.

## Output requirements

Return a worklog update draft, not code.

Use exactly the following section structure and headings, including markdown heading markers:

# Worklog Update Draft

## Update Scope
State what this update is capturing and why it matters.

## Confirmed Current State
List the current state that is actually supported by inspected files, visible conversation outputs, or explicit user instructions.

When helpful, label items like:
- Inspected directly
- Listed but not inspected

Do not include inferred intent or unresolved assumptions here.

## Completed / Established
List what has been completed, explicitly accepted, strongly verified, or stabilized so far.
Do not place provisional design choices, reviewer-blocked details, or unresolved plan items here.
If a plan is only approved with revisions, do not treat unconfirmed design details as established decisions.
Only include items that are supported strongly enough to treat as established for the next session.
If review status is `Not approved` or `Approved with revisions`, do not treat provisional plan details as established unless they were explicitly accepted.
Keep unapproved or unresolved design details in `Open Work / Risks` or `Unverified / Needs Confirmation`.

## Open Work / Risks
List remaining work, unresolved issues, contradictions, or risks that still matter.

For each meaningful item, state:
- what is still open or risky
- why it matters
- whether it should be handled now, next, or later

## Unverified / Needs Confirmation
List assumptions, suspected gaps, listed-but-unread items, inferred statements, or anything that should not be treated as confirmed.

If there are none, say `None.`

## Recommended Next Action
State the single best next step.

This should be specific enough that the next session can start from it immediately.
Do not silently choose between unresolved implementation or design options.
If a key decision remains open, the next action should be to resolve that decision or revise the plan.

## Suggested Persistence Targets
Map the most important information into likely future document buckets such as:
- context
- plan
- tasks
- decisions
- risks

Do not claim that any file was created or updated unless that happened.

## Style rules

- Be concrete
- Be skeptical
- Be structured
- Prefer durable facts over narrative recap
- Prefer handoff usefulness over exhaustiveness
- Keep section headings exactly as specified
- Match the user's language when practical
- If the user is writing in Korean, prefer answering in Korean
- Keep confidence proportional to evidence

## Notes

This skill is intended to sit after planning, reviewing, implementation, or debugging.
It is not a replacement for a planner or reviewer.
It is also not a substitute for persistent storage.

Its purpose is to preserve the current state in a form that a later session can continue without rebuilding everything from scratch.

This skill should be stable before introducing automated save hooks or file-writing workflows.

When no durable record exists from earlier sessions, treat the first worklog as a baseline state capture rather than a reconstruction of prior reasoning.s