---
name: reviewing
description: standalone 직접 호출용 reviewer skill. lean `review`와 strict `plan_review`/`result_review`/`final_review`를 다룬다.
---

# Reviewing

이 skill은 standalone 직접 호출용이다.

## 중요

- `control-flow` 내부 review 단계에는 이 Skill을 사용하지 않는다.
- control-flow 내부 review 계열 단계(`review`, `plan_review`, `result_review`, `final_review`)는 `Agent(subagent_type="reviewer")`를 사용한다.
- 이 Skill은 사용자가 `/reviewing`을 독립적으로 직접 호출할 때만 사용한다.

## review 종류

| stage | 모드 | 검토 대상 |
|-------|------|-----------|
| `review` | lean | `build-summary.md` |
| `plan_review` | strict | `plan.md` (+ acceptance) |
| `result_review` | strict | `build-summary.md` |
| `final_review` | strict | build-summary + validation evidence |

## 필수 입력

- `stage` (`review` / `plan_review` / `result_review` / `final_review`)
- `artifact_under_review`
- `read_ledger_ref`
- `required_read_targets`
- `allowed_direct_reads`
- `policy_resolution_ref`

## 반환 필드 책임

reviewer가 반환하는 metadata에서 유효한 필드:
- `verdict` (approved / approved_with_revisions / not_approved)
- `direct_reads_used`
- `revision_class`, `revision_scope_preserved`, `auto_fix_allowed`
- `required_revisions`, `forbidden_changes`, `revision_target_stage`

아래 필드는 control-flow가 계산한다.
- `required_read_targets`
- `allowed_direct_reads`
- `missing_read_targets`
- `evidence_status`
- `evidence_warnings`
