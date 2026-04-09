---
title: WORKFLOW_STATE_MACHINE
version: 4
status: active
---

# WORKFLOW_STATE_MACHINE

## 목적

이 문서는 feature 단위 workflow의 상태, 전이, stop 조건을 정의한다.

## 상태 목록

- `planning_pending`
- `plan_ready_for_review`
- `plan_approved`
- `implementation_design_pending`
- `implementation_design_ready_for_review`
- `implementation_pending`
- `final_review_pending`
- `completed`
- `blocked`
- `approval_stale`
- `human_gate_required`

## 핵심 원칙

- specialist는 한 번에 한 stage만 수행한다.
- orchestration은 한 번의 전이마다 artifact body, artifact metadata, state를 함께 갱신한다.
- review 입력은 `read ledger`로 고정한다.
- 현재 read 정책은 `warning` 모드다.
- warning은 evidence로 기록하지만 기본 차단 사유로 쓰지 않는다.

## canonical 저장 위치

- artifact body → `.claude/workflow/<feature-slug>/artifacts/*.md`
- artifact metadata → `.claude/workflow/<feature-slug>/artifacts/*.meta.json`
- policy / read ledger → `.claude/workflow/<feature-slug>/contracts/*.json`
- validation / read trace → `.claude/workflow/<feature-slug>/evidence/*.json`
- latest state → `.claude/state/<feature-slug>.json`

## 상태별 정의

### `planning_pending`
- allowed next step: `planning`
- 성공 조건:
  - plan artifact가 canonical path에 저장됨
  - artifact metadata block이 유효함
  - state 파일이 plan artifact를 반영함
  - `artifacts.plan`이 plan artifact 경로를 가리킴
  - `last_completed_stage: planning`
  - `workflow_state: plan_ready_for_review`
  - `next_allowed: reviewing`
  - 갱신된 state로 `controller`가 다시 판정됨
- 다음 state: `plan_ready_for_review`

plan artifact만 저장되고 state가 `planning_pending`에 남아 있으면 성공 전이가 아니다.

### `plan_ready_for_review`
- allowed next step: `reviewing`
- 사전 조건:
  - `contracts/read-ledger-reviewing.json` 저장
- 성공 조건:
  - `artifacts/review-plan.md` 저장
  - `artifacts/review-plan.meta.json` 저장
  - `evidence/read-trace-reviewing.json` 저장
  - 승인 verdict면 `workflow_state: plan_approved`
  - 비승인 verdict면 `workflow_state: planning_pending`

### `plan_approved`
- allowed next step: `implementation_design`
- 성공 조건:
  - `artifacts/implementation-design.md` 저장
  - `artifacts/implementation-design.meta.json` 저장
  - `workflow_state: implementation_design_ready_for_review`

### `implementation_design_ready_for_review`
- allowed next step: `implementation_review`
- 사전 조건:
  - `contracts/read-ledger-implementation-review.json` 저장
- 성공 조건:
  - `artifacts/review-implementation.md` 저장
  - `artifacts/review-implementation.meta.json` 저장
  - `evidence/read-trace-implementation-review.json` 저장
  - 승인 verdict면 `workflow_state: implementation_pending`
  - 비승인 verdict면 `workflow_state: implementation_design_pending`

### `implementation_design_pending`
- allowed next step: `implementation_design`
- 의미:
  - implementation design을 수정해야 하는 상태

### `implementation_pending`
- allowed next step: `implementing`
- 성공 조건:
  - 실제 코드 반영
  - `artifacts/implementation.md` 저장
  - `artifacts/implementation.meta.json` 저장
  - 필요 시 `evidence/validation-summary.json` 저장
  - `workflow_state: final_review_pending`

### `final_review_pending`
- allowed next step: `final_review`
- 사전 조건:
  - `contracts/read-ledger-final-review.json` 저장
  - review 가능한 validation evidence 존재
- 성공 조건:
  - `artifacts/review-final.md` 저장
  - `artifacts/review-final.meta.json` 저장
  - `evidence/read-trace-final-review.json` 저장
  - 승인 verdict면 `workflow_state: completed`
  - 비승인 verdict면 `workflow_state: implementation_pending`

### `completed`
- allowed next step: `none`
- 의미:
  - main workflow 종료

### `blocked`
- allowed next step: `none`
- 의미:
  - blocker가 해결되기 전까지 자동 진행 금지

### `approval_stale`
- allowed next step: `none`
- 의미:
  - scope나 계약 변화로 이전 승인이 무효화됨

### `human_gate_required`
- allowed next step: `none`
- 의미:
  - 사람 입력 없이는 진행하지 않음

## warning 모드 규칙

아래는 우선 warning으로 기록한다.
- `required_read_targets` 누락 의심
- `allowed_direct_reads` 밖 읽기 의심
- self-report와 observed read trace 불일치

warning 기록 위치:
- `evidence/read-trace-<stage>.json`
- `state.last_review_evidence.warnings`

warning만으로는 아래 전이를 막지 않는다.
- `plan_ready_for_review` → `plan_approved`
- `implementation_design_ready_for_review` → `implementation_pending`
- `final_review_pending` → `completed`

자동 차단은 아래에 한정한다.
- malformed artifact
- 필수 contracts 누락
- human gate
- stale approval
- specialist가 명시적으로 `status: blocked`
- `evidence_status: failed`

## persistence invariant

전이는 아래를 모두 만족할 때만 유효하다.
1. stage output이 `.claude/workflow/<feature-slug>/` 아래에 저장됨
2. artifact에 유효한 metadata block이 있음
3. state 파일이 그 artifact를 반영함
4. 현재 stage에 대응하는 `artifacts.*` 항목이 해당 artifact 경로를 가리킴
5. `last_completed_stage`, `workflow_state`, `next_allowed`, `scope_fingerprint`, `last_transition`이 새 artifact 기준으로 갱신됨
6. controller가 갱신된 state를 기준으로 다시 판정함
7. review 단계라면 해당 `read ledger`가 실제로 존재하고 artifact와 맞음

artifact만 저장되고 state가 이전 값에 머물면 그 전이는 invalid다.
state는 갱신됐지만 controller 재판정이 없으면 그 전이도 아직 완료가 아니다.

## 요약

한 번에 한 단계만 전진한다는 말은 specialist stage를 한 번에 하나만 호출한다는 뜻이다.
그 말이 artifact 저장 후 멈춰도 된다는 뜻은 아니다.
한 번의 전이는 하나의 고정 입력 세트, 하나의 저장된 artifact, 그 artifact를 반영한 하나의 저장된 state, 그리고 그 state를 기준으로 한 하나의 새 controller 판정까지 포함해야 한다.
