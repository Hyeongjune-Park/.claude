Use control-flow as the primary entry point for non-trivial workflow execution.

Keep the control plane and the work plane separate.
- controller and control-flow decide state and next step
- specialist skills produce planning, review, design, implementation, or worklog artifacts
- specialist skills do not own workflow state

Treat people-facing docs, workflow artifacts, and machine-readable state as different things.
- people-facing docs live under `docs/`
- governing workflow artifacts live under `.claude/workflow/<feature>/`
- current workflow state lives under `.claude/state/<feature>.json`

Do not use `docs/` as the source of truth for workflow progression.
Do not hide workflow state in freeform prose when a artifact metadata block or state file exists.
Do not continue past a required gate without current approval.
If root, feature, scope, or policy is ambiguous, stop and surface it.
