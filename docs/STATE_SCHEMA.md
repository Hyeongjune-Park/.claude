---
title: STATE_SCHEMA
version: 4
status: active
---

# STATE_SCHEMA

## 목적

이 문서는 하니스가 사용하는 machine-readable workflow state 형식을 정의한다.

canonical path:
- `.claude/state/<feature-slug>.json`

관련 workflow run root:
- `.claude/workflow/<feature-slug>/`

## 디렉터리 규칙

새 프로젝트에서는 아래 디렉터리가 없을 수 있다.
- `.claude/`
- `.claude/state/`
- `.claude/workflow/`

이 자체는 blocker가 아니다. 첫 persistence 시점에 생성한다.

workflow run 내부는 아래처럼 분리한다.
- `artifacts/`
- `contracts/`
- `evidence/`

## authority 순서

state 판정 우선순위:
1. 현재 state 파일
2. 최신 유효 artifact sidecar metadata
3. persisted `policy-resolution`
4. persisted `read ledger`
5. persisted `read trace`
6. 직접 확인한 근거
7. 자유 서술

## 필수 top-level 필드

- `schema_version`
- `feature_slug`
- `active_project_root`
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
- `review_inputs`
- `last_review_evidence`
- `last_validation_summary`
- `last_transition`
- `updated_at`

## 값 규칙

### `schema_version`
초기값: `state@4`

### `workflow_state`
허용값:
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

### `last_completed_stage`
허용값 또는 `null`:
- `planning`
- `reviewing`
- `implementation_design`
- `implementation_review`
- `implementing`
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
단일 단계명이다.
허용값:
- `planning`
- `reviewing`
- `implementation_design`
- `implementation_review`
- `implementing`
- `final_review`
- `worklog_update`
- `none`

### `evidence_policy_mode`
현재 기본값은 `warning`이다.
read 정책 위반 의심은 우선 warning으로 기록한다.

### `policy_resolution`
필수 키:
- `ref`
- `required_docs`
- `consistent`

`ref`는 canonical path를 가리킨다.
- `.claude/workflow/<feature-slug>/contracts/policy-resolution.json`

### `artifacts`
필수 키:
- `plan`
- `review_plan`
- `implementation_design`
- `review_implementation`
- `implementation`
- `review_final`

각 값은 `null` 또는 아래 키를 가진 객체다.
- `body_ref`
- `meta_ref`

예시:
```json
{
  "plan": {
    "body_ref": ".claude/workflow/example/artifacts/plan.md",
    "meta_ref": ".claude/workflow/example/artifacts/plan.meta.json"
  }
}
```

### `review_inputs`
필수 키:
- `reviewing`
- `implementation_review`
- `final_review`

값은 `null` 또는 아래 키를 가진 객체다.
- `ref`
- `artifact_under_review`
- `required_read_targets`
- `allowed_direct_reads`

각 `ref`는 아래 canonical path 중 하나다.
- `.claude/workflow/<feature-slug>/contracts/read-ledger-reviewing.json`
- `.claude/workflow/<feature-slug>/contracts/read-ledger-implementation-review.json`
- `.claude/workflow/<feature-slug>/contracts/read-ledger-final-review.json`

### `last_review_evidence`
review가 아직 없으면 `null`.
그 외에는 아래 키가 필요하다.
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

`read_trace_ref`의 canonical path:
- `.claude/workflow/<feature-slug>/evidence/read-trace-<stage>.json`

### `last_validation_summary`
구현 validation이 아직 없으면 `null`.
그 외에는 아래 키가 필요하다.
- `ref`
- `commands_requested`
- `commands_executed`
- `result`
- `evidence_refs`

권장 canonical path:
- `.claude/workflow/<feature-slug>/evidence/validation-summary.json`

### `last_transition`
필수 키:
- `from_state`
- `to_state`
- `trigger`
- `artifact_path`
- `timestamp`

## Fresh-start 예시

```json
{
  "schema_version": "state@4",
  "feature_slug": "example-feature",
  "active_project_root": "C:/path/to/project",
  "workflow_state": "planning_pending",
  "last_completed_stage": null,
  "status": "pending",
  "verdict": "none",
  "next_allowed": "planning",
  "blocker_present": false,
  "blocker_reason": "",
  "human_input_required": false,
  "scope_fingerprint": null,
  "stale": false,
  "stale_reason": "",
  "evidence_policy_mode": "warning",
  "policy_resolution": {
    "ref": null,
    "required_docs": {},
    "consistent": false
  },
  "artifacts": {
    "plan": null,
    "review_plan": null,
    "implementation_design": null,
    "review_implementation": null,
    "implementation": null,
    "review_final": null
  },
  "review_inputs": {
    "reviewing": null,
    "implementation_review": null,
    "final_review": null
  },
  "last_review_evidence": null,
  "last_validation_summary": null,
  "last_transition": {
    "from_state": null,
    "to_state": "planning_pending",
    "trigger": "state_initialized",
    "artifact_path": null,
    "timestamp": "2026-04-09T00:00:00Z"
  },
  "updated_at": "2026-04-09T00:00:00Z"
}
```

## 갱신 규칙

각 전이 완료 후 순서는 아래와 같다.
1. `policy-resolution` 저장
2. 다음 단계가 review라면 해당 `read ledger` 저장
3. workflow artifact 저장
4. artifact metadata block 추출 및 검증
5. 현재 artifact를 기준으로 `workflow_state`, `last_completed_stage`, `next_allowed`, `scope_fingerprint`를 정규화
6. 현재 stage에 대응하는 `artifacts.*` 항목을 artifact 경로로 갱신
7. `last_transition`과 `updated_at` 갱신
8. state 파일 저장
9. 갱신된 state를 기준으로 `controller` 재판정

artifact가 저장되었는데 `artifacts.*`가 여전히 `null`이면 state 갱신 실패다.
artifact가 저장되었는데 `workflow_state`가 이전 pending 값에 남아 있으면 전이 실패다.
state 저장 후 `controller` 재판정이 없으면 그 전이는 아직 완료가 아니다.
