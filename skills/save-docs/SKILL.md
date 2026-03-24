---
name: save-docs
description: Write save-ready content into project-local documentation files. Use after plan-save when the session has already identified what should be persisted into context, plan, tasks, decisions, or risks, and the user wants the documents actually written inside the current project.
---

Use this skill to write or update project documentation files from save-ready content.

This skill performs actual document writing.
Do not implement code.
Do not generate patches unrelated to documentation.
Do not write outside the active project root.

## When to use this skill

Use this skill when:
- the current session already produced save-ready content
- plan-save has identified what belongs in context, plan, tasks, decisions, or risks
- the user explicitly wants documents written or updated
- the user asks for:
  - save these docs
  - write the documents
  - update the project docs
  - 문서로 저장해줘
  - 실제 파일로 작성해줘
  - docs에 반영해줘
  - plan/context/tasks 문서 만들어줘
  - 기존 문서 갱신해줘

Do not use this skill for:
- deciding what should be saved before that decision has been made
- broad narrative summarization
- writing outside the current project
- creating global shared files in the harness root
- storing unresolved or unapproved design details as settled decisions

## Goal

Write project-local documentation safely by:
- resolving the active project root
- mapping save buckets to project-local file paths
- reading existing target files when needed
- deciding whether to create, replace, append, or section-update
- writing only durable, approved, or explicitly requested content
- refusing unsafe or ambiguous write targets

## Required workflow

Follow this sequence:

1. Identify the source material to write:
   - plan-save output
   - worklog-update output
   - planning result
   - reviewing result
   - explicit user instructions

2. Resolve the active project root.
   Prefer this order:
   - the root implied by the user's requested project path
   - the nearest project directory containing project files being discussed
   - the nearest project `CLAUDE.md`
   - the nearest git root

3. If the active project root cannot be determined safely, do not write anything.
   Ask for clarification or stop with a refusal to write.

4. Determine document mapping.
   Prefer this order:
   - explicit target files named in the current session or in the plan-save output
   - project-specific mapping from project `CLAUDE.md` or project-local docs rules
   - existing feature-specific docs that clearly match the current feature or scoped change
   - existing shared project docs that clearly match the buckets
   - default project-local paths:
     - for feature-scoped saves, prefer:
       - `docs/plan-<feature-slug>.md`
       - `docs/decisions-<feature-slug>.md`
       - `docs/tasks-<feature-slug>.md` only if needed
       - `docs/risks-<feature-slug>.md` only if needed
     - for project-wide saves, prefer:
       - `docs/context.md`
       - `docs/plan.md`
       - `docs/tasks.md`
       - `docs/decisions.md`
       - `docs/risks.md`

5. Normalize every target path and verify it stays inside the active project root.

6. Read existing target files before updating them, unless the file does not exist.

7. Decide write mode per file:
   - create
   - replace whole file
   - replace matching section
   - append section
   - leave unchanged

8. Write the files.

9. Return a concise write result summary.

## Project-root safety rules

These rules are strict:

- All write targets must resolve inside the active project root.
- Never use the global harness directory as a default write target.
- Never write to a parent directory of the active project root.
- Never use `..` traversal, normalized escape paths, or absolute paths outside the active project root.
- If a target path resolves outside the active project root, refuse the write.
- If the user asks to write into the global harness root, refuse unless they explicitly and unambiguously ask to modify the harness itself.

## Mapping rules

Use project-specific mapping when available.

If the current save is clearly feature-scoped, prefer feature-specific docs before shared docs.

Examples for feature-scoped saves:
- `plan -> docs/plan-<feature-slug>.md`
- `decisions -> docs/decisions-<feature-slug>.md`
- `tasks -> docs/tasks-<feature-slug>.md` when task content needs its own file
- `risks -> docs/risks-<feature-slug>.md` when risk content needs its own file

Examples for project-wide saves:
- `context -> docs/context.md`
- `plan -> docs/plan.md`
- `tasks -> docs/tasks.md`
- `decisions -> docs/decisions.md`
- `risks -> docs/risks.md`

If explicit target files were already established earlier in the session, reuse them unless they are unsafe or clearly inconsistent with project guidance.

## Content rules

- Write only content that is save-ready.
- Do not promote `Not approved` or unresolved design details into `decisions`.
- If review status is `Approved with revisions`, keep provisional design details in `plan` or `tasks` unless they were explicitly accepted.
- Do not overwrite stronger existing content with weaker inferred content.
- Prefer section replacement over whole-file replacement when only one section is changing.
- Preserve useful existing content that is still valid.
- Remove or update stale content only when the current session has enough evidence to justify it.
- If evidence is insufficient to safely rewrite a section, leave it unchanged and report that.

## Existing document rules

When target files already exist:
- read them first
- preserve still-valid sections
- update only the sections justified by the current evidence
- avoid duplicating content already present
- avoid rewriting the whole file unless the file is clearly small, stale, and fully superseded

If a file already exists but the current session cannot safely merge changes, do not guess.
Prefer:
- appending a clearly labeled update section, or
- leaving the file unchanged and reporting the merge uncertainty

If a feature-specific doc already exists for the same change, update that file instead of creating a second near-duplicate filename.
Prefer one canonical file per bucket for a given feature.
If both shared and feature-specific docs exist, prefer the file lineage established by the current session unless project guidance clearly overrides it.

## Output requirements

Return exactly the following structure and headings after attempting the write:

# Save Docs Result

## Active Project Root
State the resolved project root used for writes.

## Source Inputs
List the source materials used to write the docs.

## Target Mapping
List the bucket-to-file mapping used.

## Write Actions
For each target file, state one of:
- created
- updated
- unchanged
- skipped
- refused

Also state briefly why.

## Notes
List any important cautions, merge uncertainties, or intentionally skipped writes.

## Style rules

- Be concrete
- Be conservative
- Prefer safe writes over aggressive rewrites
- Keep confidence proportional to evidence
- Do not claim a file was updated if it was not
- Keep section headings exactly as specified
- Match the user's language when practical
- If the user is writing in Korean, prefer answering in Korean

## Notes

This skill is the persistence layer that follows plan-save.
It should be used only after the save mapping is clear enough to write safely.

This skill writes project-local documents.
It must never treat the global harness root as a normal output location.