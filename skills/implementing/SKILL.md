---
name: implementing
description: Implement the approved implementation design inside the active project root, run the requested validations, and persist a grounded implementation result that later final review can verify.
---

# Implementing

Use this skill to write code from an approved implementation design.

## Rules

- require approved implementation review before coding
- write only inside the active project root
- stay within the approved design scope
- do not pull patterns from sibling projects
- run the requested validation commands in order when possible
- report exact command outputs and pass/fail outcomes
- do not claim validation succeeded if it was not actually run
- make validation evidence reviewable for final review

## Required output

The implementation artifact must include:
- goal
- files written
- files intentionally not changed
- validation commands requested
- validation commands executed
- exact validation results
- validation evidence refs or inline raw excerpts
- issues encountered
- unresolved follow-up risks
- one valid implementing control block

Normal successful next step is `final_review`.
Do not emit `next_allowed: [reviewing]` from implementation.

## Validation evidence requirement

Final review must be able to verify what happened.

Therefore the implementation artifact must make validation evidence explicit enough that final review can bind it into its read ledger.
Do not collapse validation into vague prose such as:
- "tests passed"
- "build looked fine"

Instead list the exact commands and evidence refs.