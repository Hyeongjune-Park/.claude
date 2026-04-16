---
title: STATE_SCHEMA
version: 8
status: active
---

# STATE_SCHEMA

## 목적

이 문서는 하니스가 사용하는 machine-readable workflow state 형식을 정의한다.

canonical path:
- `.claude/state/<feature-slug>.json`

관련 workflow root:
- `.claude/workflow/<feature-slug>/`

## 디렉터리 규칙

새 프로젝트에서 아래 디렉터리가 없어도 blocker가 아니다.
- `.claude/`
- `.claude/state/`
- `.claude/workflow/`

첫 persistence 시점에 생성한다.

## authority 순서

state 판정 우선순위:
1. 현재 state 파일
2. 최신 유효 artifact sidecar metadata
3. persisted `policy-resolution`
4. persisted `read ledger`
5. persisted `read trace`
6. 직접 확인한 근거
7. 자유 서술

## backward-compat 정규화 규칙

current schema와 맞지 않는 구형 state를 발견하면, orchestration layer는 controller 호출 전에 current schema로 정규화해 다시 저장한다.

예:
- `current_stage` → `workflow_state`
- `in_progress` → `status: pending`
- `pending_planning` → `planning_pending`
- `implementation_design_pending` → `build_pending`
- `implementation_design_ready_for_review` → `build_ready_for_review`
- `implementation_pending` → `build_pending`
- 축약된 `accepted_artifacts` 문자열 값 → current object shape
- `artifacts.implementation_design` / `artifacts.review_implementation` / `artifacts.implementation` → `artifacts.build_summary` / `artifacts.review_result` (대응 관계 보존)
- `artifacts.acceptance` 키 누락 → `null`로 초기화 (v7 이전 state 정규화)

구형 shape를 그대로 authority로 사용하지 않는다.

## 필수 top-level 필드

- `schema_version`
- `feature_slug`
- `active_project_root`
- `execution_mode`
- `workflow_state`
- `last_completed_stage`
- `status`
- `verdict`
- `next_allowed`
- `blocker_present`
- `blocker_reason`
- `human_input_required`
- `scope_fingerprint`
- `stale`
- `stale_reason`
- `evidence_policy_mode`
- `policy_resolution`
- `artifacts`
- `accepted_artifacts`
- `pending_review`
- `review_inputs`
- `revision_request`
- `last_review_evidence`
- `last_validation_summary`
- `last_transition`
- `updated_at`

## 값 규칙

### `schema_version`
초기값: `state@8`

### `execution_mode`
허용값:
- `lean`
- `strict`

규칙:
- 기본값은 `lean`
- 값 누락 또는 오염 시 `strict`로 fallback한다.

### `workflow_state`
허용값:
- `planning_pending`
- `plan_ready_for_review`
- `build_pending`
- `build_ready_for_review`
- `validation_pending`
- `final_review_pending`
- `completed`
- `blocked`
- `approval_stale`
- `human_gate_required`

### `last_completed_stage`
허용값 또는 `null`:
- `planning`
- `review`
- `plan_review`
- `build`
- `result_review`
- `validation`
- `final_review`
- `worklog_update`

### `status`
허용값:
- `pending`
- `completed`
- `blocked`
- `stale`

### `verdict`
허용값:
- `none`
- `approved`
- `approved_with_revisions`
- `not_approved`

### `next_allowed`
허용값:
- `planning`
- `review`
- `plan_review`
- `build`
- `result_review`
- `validation`
- `final_review`
- `worklog_update`
- `none`

### `policy_resolution`
필수 키:
- `ref`
- `required_docs`
- `consistent`

### `artifacts`
필수 키:
- `plan`
- `review_plan`
- `acceptance`
- `build_summary`
- `review_result`
- `review_final`

`plan`, `review_plan`, `build_summary`, `review_result`, `review_final`의 값은 `null` 또는 아래 키를 가진 객체다.
- `body_ref`
- `meta_ref`
- `history_body_ref`
- `history_meta_ref`

`acceptance`의 값은 `null` 또는 아래 키를 가진 객체다. (metadata 없음, body만 추적)
- `body_ref`

의미:
- `acceptance`는 planning 단계에서 PO가 생성하는 정식 artifact다
- strict validation은 acceptance 기준을 포함해 판정한다
- strict 모드에서 `acceptance.md`가 없으면 `validation_pending` 진입 전 차단한다

### `accepted_artifacts`
필수 키:
- `plan`
- `build_summary`

각 값은 `null` 또는 아래 키를 가진 객체다.
- `body_ref`
- `meta_ref`
- `history_body_ref`
- `history_meta_ref`
- `accepted_by_review_ref`
- `scope_fingerprint`

의미:
- 현재 authoritative한 승인본만 기록한다
- 최신 생성본이 있어도 아직 승인되지 않았다면 여기를 덮어쓰지 않는다
- final review 승인 전에는 `build_summary`를 최종 확정하지 않는다

### `pending_review`
필수 키:
- `stage`
- `artifact_ref`
- `ledger_ref`

값 규칙:
- review 대기 상태가 아니면 모두 `null`
- review 대기 상태면 해당 review stage와 대상 artifact를 기록한다

### `review_inputs`
필수 키:
- `review`
- `plan_review`
- `result_review`
- `final_review`

각 값은 `null` 또는 아래 키를 가진 객체다.
- `ref`
- `artifact_under_review`
- `required_read_targets`
- `allowed_direct_reads`

### `revision_request`
필수 키:
- `active`
- `source_review_stage`
- `source_review_ref`
- `target_stage`
- `allowed_delta`
- `forbidden_changes`
- `scope_preserved`
- `auto_fix_allowed`
- `attempt_count`
- `max_attempts`

값 규칙:
- 활성 요청이 없으면 `active: false`
- bounded retry 중일 때만 `active: true`
- `max_attempts` 기본값은 `1`

### `revision_request.attempt_count`
의미:
- 허가된 retry 수가 아니다
- 실제로 **완료되어 저장된 bounded retry producer artifact 수**다

규칙:
- `approved_with_revisions` 직후에는 증가시키지 않는다
- bounded retry producer artifact가 저장되고 state가 review-ready state로 이동할 때 증가시킨다
- retry 실행 전에 `attempt_count == max_attempts`이면 malformed state다

### `last_review_evidence`
review가 아직 없으면 `null`
그 외에는 아래 키를 가진 객체다.
- `stage`
- `artifact_under_review`
- `read_ledger_ref`
- `read_trace_ref`
- `required_read_targets`
- `allowed_direct_reads`
- `self_reported_direct_reads_used`
- `observed_direct_reads_used`
- `missing_read_targets`
- `evidence_status`
- `warnings`

### `last_validation_summary`
validation이 아직 없으면 `null`
그 외에는 아래 키를 가진 객체다.
- `ref` — evidence 파일 경로 (`evidence/validation-summary-<timestamp>.json`)
- `result` — `pass` | `pass_with_warn` | `fail`
- `generated_at` — ISO 8601 timestamp

세부 정보(`errors`, `warnings`, `checked_artifacts` 등)는 `ref` 파일 안에 있으며 state 객체에 중복 저장하지 않는다.

### `last_transition`
필수 키:
- `from_state`
- `to_state`
- `trigger`
- `artifact_path`
- `timestamp`

권장 trigger:
- `state_initialized`
- `artifact_completed`
- `review_approved`
- `review_revision_requested`
- `review_not_approved`
- `validation_passed`
- `validation_failed`
- `approval_became_stale`
- `human_gate_set`

## 갱신 규칙

### 생산 단계 완료 시
- 현재 artifact를 `artifacts.*`에 기록한다
- immutable history ref도 같이 기록한다
- `last_completed_stage`를 해당 생산 stage로 갱신한다
- 다음 review 대기 state로 이동한다
- `pending_review`를 채운다
- bounded retry 실행 결과라면 이 시점에만 `revision_request.attempt_count += 1`
- `last_transition.trigger`는 `artifact_completed`

### review 승인 시
- `accepted_artifacts`의 해당 producer artifact를 갱신한다
- `revision_request`를 초기화한다
- `pending_review`를 비운다
- 다음 producer pending state 또는 validation_pending으로 이동한다
- `last_transition.trigger`는 `review_approved`

### `approved_with_revisions` 시
- `accepted_artifacts`는 유지한다
- `revision_request`를 활성화한다
- `attempt_count`는 증가시키지 않는다
- target producer pending state로 이동한다
- `pending_review`는 비운다
- `last_transition.trigger`는 `review_revision_requested`

### `not_approved` 시
- `accepted_artifacts`는 유지한다
- `revision_request`를 비활성화한다
- target producer pending state로 이동한다
- `pending_review`는 비운다
- `last_transition.trigger`는 `review_not_approved`

### validation 완료 시
- `last_validation_summary`를 갱신한다
- lean에서 validation result `pass` 또는 `pass_with_warn`이면 `completed`로 이동
- strict에서 validation result `pass` 또는 `pass_with_warn`이면 `final_review_pending`으로 이동
- validation result `fail`이면 `build_pending`으로 이동하고 stop
- `last_transition.trigger`는 `validation_passed` 또는 `validation_failed`

### stale 시
- `workflow_state: approval_stale`
- `status: stale`
- `next_allowed: none`
- `stale: true`

## invariant

아래를 모두 만족해야 state가 유효하다.
1. stage output이 canonical path와 history path 둘 다에 저장된다 (acceptance 제외 — body만 저장)
2. artifact metadata가 유효하다
3. state 파일이 최신 artifact를 반영한다
4. review 대기 state면 `pending_review`가 비어 있지 않다
5. bounded retry 중이면 `revision_request.active == true`
6. 승인되지 않은 최신 artifact가 생겨도 `accepted_artifacts`를 덮어쓰지 않는다
7. final review 승인 전에는 `accepted_artifacts.build_summary`가 최종 확정되지 않는다
8. `review_inputs.<stage>.allowed_direct_reads`는 해당 read ledger의 `allowed_direct_reads`와 정확히 일치한다 (count + content 모두)
9. state 파일은 carry-forward 방식으로만 갱신한다. 기존 필드를 비우거나 처음부터 재구성하지 않는다
10. `last_review_evidence.allowed_direct_reads`는 reviewer 출력이 아니라 read ledger에서 직접 가져온다
11. specialist 반환 metadata에서 타입 오류(예: 문자열 `"null"`)가 교정된 경우 교정 사실을 `evidence_warnings`에 기록한다
12. `review_inputs.<stage>.ref`가 null이 아니면 `required_read_targets`와 `allowed_direct_reads`는 빈 배열이어선 안 된다 (ref 있고 배열 비어있으면 invalid state)
