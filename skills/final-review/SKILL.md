---
name: final-review
description: standalone 직접 호출용 final-review skill. control-flow 내부 specialist 호출에는 사용하지 않는다.
---

# Final Review

이 skill은 standalone 직접 호출용이다.

## 중요

- `control-flow` 내부 final_review 단계에는 이 Skill을 사용하지 않는다.
- control-flow 내부 final_review 단계는 반드시 `Agent(subagent_type="reviewer")`를 사용한다.
- 이 Skill은 사용자가 `/final-review`를 독립적으로 직접 호출할 때만 사용한다.

## 검토 대상

`final_review`는 build-summary artifact와 기록된 validation evidence를 함께 검토한다.
acceptance 기준을 벗어난 새 요구사항을 verdict에 반영하지 않는다.

## 필수 입력

caller는 아래를 제공해야 한다.
- `artifact_under_review`
- `read_ledger_ref`
- `required_read_targets`
- `allowed_direct_reads`
- `policy_resolution_ref`

## 반환 필드 책임

reviewer가 반환하는 metadata에서 유효한 필드:
- `verdict` (approved / approved_with_revisions / not_approved)
- `direct_reads_used` (실제로 읽은 파일 목록 — self-report)
- `revision_class`, `revision_scope_preserved`, `auto_fix_allowed`
- `required_revisions`, `forbidden_changes`, `revision_target_stage`

아래 필드는 reviewer가 계산하거나 채우지 않는다. control-flow가 ledger/trace 기반으로 직접 계산한다.
- `required_read_targets`
- `allowed_direct_reads`
- `missing_read_targets`
- `evidence_status`
- `evidence_warnings`