---
title: WORKFLOW_STATE_MACHINE
version: 5
status: active
---

# WORKFLOW_STATE_MACHINE

## 목적

이 문서는 feature 단위 workflow의 상태, 전이, 자동 진행 조건, stop 조건을 정의한다.

## 상태 목록

- `planning_pending`
- `plan_ready_for_review`
- `implementation_design_pending`
- `implementation_design_ready_for_review`
- `implementation_pending`
- `final_review_pending`
- `completed`
- `blocked`
- `approval_stale`
- `human_gate_required`

## 핵심 원칙

- specialist는 한 번에 한 stage만 수행한다
- orchestration은 한 전이마다 artifact, metadata, state를 함께 갱신한다
- review verdict는 `approved`, `approved_with_revisions`, `not_approved`를 구분해서 처리한다
- `approved_with_revisions`만 bounded retry 후보다
- `not_approved`는 자동 재시도하지 않는다
- pending state라고 해서 항상 자동 진행하는 것은 아니다
- 현재 read 정책은 `warning` 모드다

## canonical 저장 위치

- artifact body → `.claude/workflow/<feature-slug>/artifacts/*.md`
- artifact metadata → `.claude/workflow/<feature-slug>/artifacts/*.meta.json`
- contracts → `.claude/workflow/<feature-slug>/contracts/*.json`
- evidence → `.claude/workflow/<feature-slug>/evidence/*.json`
- latest state → `.claude/state/<feature-slug>.json`

## 상태별 allowed next step

- `planning_pending` → `planning`
- `plan_ready_for_review` → `reviewing`
- `implementation_design_pending` → `implementation_design`
- `implementation_design_ready_for_review` → `implementation_review`
- `implementation_pending` → `implementing`
- `final_review_pending` → `final_review`
- `completed` → `none`
- `blocked` → `none`
- `approval_stale` → `none`
- `human_gate_required` → `none`

## 전이 규칙

### 1. planning 완료
- from: `planning_pending`
- by: `planning`
- to: `plan_ready_for_review`
- 조건:
  - `plan.md`와 `plan.meta.json` 저장
  - state 반영 완료
  - `pending_review.stage = reviewing`

### 2. plan review 승인
- from: `plan_ready_for_review`
- by: `reviewing`
- verdict: `approved`
- to: `implementation_design_pending`
- 조건:
  - `review-plan.md`와 `review-plan.meta.json` 저장
  - `accepted_artifacts.plan` 갱신
  - `revision_request` 초기화

### 3. plan review 수정 승인
- from: `plan_ready_for_review`
- by: `reviewing`
- verdict: `approved_with_revisions`
- to: `planning_pending`
- 조건:
  - `revision_class = bounded`
  - `revision_scope_preserved = true`
  - `auto_fix_allowed = true`
  - `revision_target_stage = planning`
  - `required_revisions`가 비어 있지 않음
  - `revision_request.active = true`

### 4. plan review 비승인
- from: `plan_ready_for_review`
- by: `reviewing`
- verdict: `not_approved`
- to: `planning_pending`
- 조건:
  - `revision_request.active = false`
  - 이 전이 후 자동 재시도하지 않고 stop

### 5. implementation design 완료
- from: `implementation_design_pending`
- by: `implementation_design`
- to: `implementation_design_ready_for_review`
- 조건:
  - `implementation-design.md`와 `implementation-design.meta.json` 저장
  - state 반영 완료
  - `pending_review.stage = implementation_review`

### 6. implementation review 승인
- from: `implementation_design_ready_for_review`
- by: `implementation_review`
- verdict: `approved`
- to: `implementation_pending`
- 조건:
  - `accepted_artifacts.implementation_design` 갱신
  - `revision_request` 초기화

### 7. implementation review 수정 승인
- from: `implementation_design_ready_for_review`
- by: `implementation_review`
- verdict: `approved_with_revisions`
- to: `implementation_design_pending`
- 조건:
  - `revision_class = bounded`
  - `revision_scope_preserved = true`
  - `auto_fix_allowed = true`
  - `revision_target_stage = implementation_design`
  - `required_revisions`가 비어 있지 않음
  - `revision_request.active = true`

### 8. implementation review 비승인
- from: `implementation_design_ready_for_review`
- by: `implementation_review`
- verdict: `not_approved`
- to: `implementation_design_pending`
- 조건:
  - `revision_request.active = false`
  - 이 전이 후 자동 재시도하지 않고 stop

### 9. implementation 완료
- from: `implementation_pending`
- by: `implementing`
- to: `final_review_pending`
- 조건:
  - `implementation.md`와 `implementation.meta.json` 저장
  - review 가능한 validation evidence 존재
  - `pending_review.stage = final_review`

### 10. final review 승인
- from: `final_review_pending`
- by: `final_review`
- verdict: `approved`
- to: `completed`
- 조건:
  - `accepted_artifacts.implementation` 갱신
  - `revision_request` 초기화

### 11. final review 수정 승인
- from: `final_review_pending`
- by: `final_review`
- verdict: `approved_with_revisions`
- to: `implementation_pending`
- 조건:
  - `revision_class = bounded`
  - `revision_scope_preserved = true`
  - `auto_fix_allowed = true`
  - `revision_target_stage = implementing`
  - `required_revisions`가 비어 있지 않음
  - `revision_request.active = true`

### 12. final review 비승인
- from: `final_review_pending`
- by: `final_review`
- verdict: `not_approved`
- to: `implementation_pending`
- 조건:
  - `revision_request.active = false`
  - 이 전이 후 자동 재시도하지 않고 stop

## 자동 진행 규칙

자동 진행은 아래 경우에만 허용한다.

1. fresh start
2. review 대기 state
3. review `approved` 후 다음 producer stage 진입
4. review `approved_with_revisions` 후 bounded retry 진입

자동 진행하지 않는 경우:
- review `not_approved` 후 pending state
- `blocked`
- `approval_stale`
- `human_gate_required`

## `approved_with_revisions` 규칙

`approved_with_revisions`는 승인과 동일하지 않다.

의미:
- 전체 방향은 유지된다
- 작은 수정이 선행되어야 한다
- 그 수정은 bounded retry 대상이다

따라서 `approved`처럼 바로 다음 단계로 넘기지 않는다.
항상 같은 producer stage로 되돌린 뒤 1회만 재수행한다.

## `not_approved` 규칙

`not_approved`는 bounded retry 대상이 아니다.

의미:
- 수정 범위가 넓거나
- 방향이 흔들리거나
- 사람 판단이 필요하거나
- 1회 자동 수정으로 닫히기 어렵다

따라서 target producer pending state로 되돌리되, 자동 재호출하지 않고 stop한다.

## stale 규칙

아래 경우는 `approval_stale`로 간다.
- 승인 후 `scope_fingerprint`가 바뀜
- 승인 기반 artifact와 현재 artifact가 같은 scope로 설명되지 않음
- accepted artifact를 전제로 한 계약이 뒤집힘

## warning 모드 규칙

아래는 우선 warning으로 기록한다.
- `required_read_targets` 누락 의심
- `allowed_direct_reads` 밖 읽기 의심
- self-report와 observed read trace 불일치

warning만으로는 아래 전이를 자동 차단하지 않는다.
- `plan_ready_for_review` → review 실행
- `implementation_design_ready_for_review` → review 실행
- `final_review_pending` → review 실행

자동 차단은 아래에 한정한다.
- malformed artifact
- 필수 contracts 누락
- `human_input_required: true`
- stale approval
- specialist가 `status: blocked`
- `evidence_status: failed`

## persistence invariant

전이는 아래를 모두 만족할 때만 유효하다.
1. artifact body가 canonical path에 저장됨
2. artifact metadata가 유효함
3. state 파일이 해당 artifact를 반영함
4. review 대기 state면 `pending_review`가 채워짐
5. bounded retry state면 `revision_request.active = true`
6. `controller` 재판정까지 끝남