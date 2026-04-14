---
title: CONTROL_CONTRACT
version: 6
status: active
---

# CONTROL_CONTRACT

## 목적

이 문서는 workflow artifact가 공통으로 따라야 하는 machine-readable metadata 형식과 저장 규칙을 정의한다.

사람이 읽는 artifact 본문은 `.md`로 저장한다.
기계가 읽는 metadata는 같은 artifact 이름의 `.meta.json`으로 저장한다.
사람용 `.md` 앞에 YAML front matter를 붙이지 않는다.

## 저장 구조

canonical root:
- `.claude/workflow/<feature-slug>/`

하위 디렉터리:
- `artifacts/`
- `contracts/`
- `evidence/`

artifact 저장 쌍:
- `artifacts/plan.md` + `artifacts/plan.meta.json`
- `artifacts/review-plan.md` + `artifacts/review-plan.meta.json`
- `artifacts/implementation-design.md` + `artifacts/implementation-design.meta.json`
- `artifacts/review-implementation.md` + `artifacts/review-implementation.meta.json`
- `artifacts/implementation.md` + `artifacts/implementation.meta.json`
- `artifacts/review-final.md` + `artifacts/review-final.meta.json`

## specialist 반환 형식

specialist stage는 아래 두 블록만 반환한다.

1. `ARTIFACT_METADATA_JSON`
2. `ARTIFACT_BODY_MD`

예시:

    [ARTIFACT_METADATA_JSON]
    ```json
    { ... }
    ```
    [ARTIFACT_BODY_MD]
    ```md
    # Title
    ...
    ```

orchestration layer는 첫 블록을 `.meta.json`에, 두 번째 블록을 `.md`에 저장한다.

## 공통 metadata 형식

```json
{
  "workflow_stage": "<planning|reviewing|implementation_design|implementation_review|implementing|final_review|worklog_update>",
  "feature_slug": "<feature-slug>",
  "artifact_type": "<plan|review_plan|implementation_design|review_implementation|implementation|review_final|worklog>",
  "scope_fingerprint": "<string-or-null>",
  "status": "<completed|incomplete|blocked>",
  "verdict": "<none|approved|approved_with_revisions|not_approved>",
  "next_allowed": "<planning|reviewing|implementation_design|implementation_review|implementing|final_review|worklog_update|none>",
  "blocker_present": false,
  "blocker_reason": "",
  "human_input_required": false,
  "stale_conditions": [],
  "revision_class": "<none|bounded|broad>",
  "revision_target_stage": "<planning|implementation_design|implementing|none>",
  "revision_scope_preserved": true,
  "auto_fix_allowed": false,
  "required_revisions": ["<bounded-change>"],
  "forbidden_changes": ["<forbidden-change>"],
  "parent_review_ref": null,
  "revision_attempt": 0,
  "max_revision_attempts": 1,
  "active_project_root": "<path>",
  "policy_resolution_ref": "<path-or-null>",
  "artifact_under_review": "<path-or-null>",
  "read_ledger_ref": "<path-or-null>",
  "required_read_targets": ["<path-or-target>"],
  "allowed_direct_reads": ["<path-or-target>"],
  "direct_reads_used": ["<path-or-target>"],
  "missing_read_targets": ["<path-or-target>"],
  "evidence_policy_mode": "warning",
  "evidence_status": "<not_applicable|passed|warning|failed>",
  "evidence_warnings": ["<warning-code-or-message>"]
}
```

## 필드 규칙

### `workflow_stage`
허용값:
- `planning`
- `reviewing`
- `implementation_design`
- `implementation_review`
- `implementing`
- `final_review`
- `worklog_update`

### `artifact_type`
허용값:
- `plan`
- `review_plan`
- `implementation_design`
- `review_implementation`
- `implementation`
- `review_final`
- `worklog`

### `status`
허용값:
- `completed`
- `incomplete`
- `blocked`

### `verdict`
허용값:
- `none`
- `approved`
- `approved_with_revisions`
- `not_approved`

review가 아닌 생산 단계는 `verdict: none`을 사용한다.

### `next_allowed`
허용값:
- `planning`
- `reviewing`
- `implementation_design`
- `implementation_review`
- `implementing`
- `final_review`
- `worklog_update`
- `none`

단일 단계명만 적는다.

### `revision_class`
허용값:
- `none`
- `bounded`
- `broad`

사용 규칙:
- 생산 단계는 항상 `none`
- review 단계에서 `approved`면 `none`
- review 단계에서 `approved_with_revisions`면 `bounded`
- review 단계에서 `not_approved`면 `broad`

### `revision_target_stage`
허용값:
- `planning`
- `implementation_design`
- `implementing`
- `none`

사용 규칙:
- 생산 단계는 `none`
- `reviewing`의 `approved_with_revisions` 또는 `not_approved`는 `planning`
- `implementation_review`의 `approved_with_revisions` 또는 `not_approved`는 `implementation_design`
- `final_review`의 `approved_with_revisions` 또는 `not_approved`는 `implementing`

### `revision_scope_preserved`
사용 규칙:
- 생산 단계는 `true`
- `approved_with_revisions`일 때는 기존 승인 범위가 유지되는 경우만 `true`
- scope가 흔들리면 `approved_with_revisions`를 쓰지 말고 `not_approved`를 써야 한다

### `auto_fix_allowed`
사용 규칙:
- 생산 단계는 `false`
- review 단계에서 `approved_with_revisions`이고 bounded retry가 가능한 경우만 `true`
- `approved`와 `not_approved`에서는 `false`

### `required_revisions`
사용 규칙:
- 생산 단계는 빈 배열
- `approved_with_revisions`일 때는 비어 있으면 안 된다
- 각 항목은 좁고 구체적이어야 한다

### `forbidden_changes`
사용 규칙:
- 생산 단계는 빈 배열
- `approved_with_revisions`일 때는 비어 있으면 안 된다
- bounded retry가 건드리면 안 되는 변경을 적는다

### `parent_review_ref`
사용 규칙:
- 일반 생산 단계는 `null`
- bounded retry로 다시 생성된 artifact는 자신을 재호출하게 만든 review artifact 경로를 적는다

### `revision_attempt`
사용 규칙:
- 일반 생산 단계는 `0`
- bounded retry로 다시 생성된 artifact는 `1`

### `max_revision_attempts`
기본값은 `1`이다.
stage별 자동 수정 한도를 뜻한다.

### `artifact_under_review`, `read_ledger_ref`
- review 단계에서는 둘 다 필수다
- review가 아닌 단계에서는 `null`이다

### `evidence_policy_mode`
현재 기본값은 `warning`이다.

### `evidence_status`
허용값:
- `not_applicable`
- `passed`
- `warning`
- `failed`

사용 규칙:
- non-review stage는 `not_applicable`
- review stage에서 read 관련 경고가 있으면 `warning`
- review 자체가 성립하지 않으면 `failed`

## stage별 최소 규칙

### `planning`
- `verdict: none`
- 정상 완료 시 `next_allowed: reviewing`
- `revision_class: none`
- `parent_review_ref`는 bounded retry가 아니면 `null`

### `reviewing`
- `verdict`는 `approved`, `approved_with_revisions`, `not_approved` 중 하나
- `approved`면 `next_allowed: implementation_design`
- `approved_with_revisions`면 `next_allowed: planning`
- `not_approved`면 `next_allowed: planning`
- `artifact_under_review`는 plan artifact 경로

### `implementation_design`
- `verdict: none`
- 정상 완료 시 `next_allowed: implementation_review`
- `revision_class: none`
- bounded retry라면 `parent_review_ref`와 `revision_attempt: 1`을 채운다

### `implementation_review`
- `verdict`는 `approved`, `approved_with_revisions`, `not_approved` 중 하나
- `approved`면 `next_allowed: implementing`ㅉ
- `approved_with_revisions`면 `next_allowed: implementation_design`
- `not_approved`면 `next_allowed: implementation_design`
- `artifact_under_review`는 implementation-design artifact 경로

### `implementing`
- `verdict: none`
- 정상 완료 시 `next_allowed: final_review`
- `revision_class: none`
- bounded retry라면 `parent_review_ref`와 `revision_attempt: 1`을 채운다

### `final_review`
- `verdict`는 `approved`, `approved_with_revisions`, `not_approved` 중 하나
- `approved`면 `next_allowed: none`
- `approved_with_revisions`면 `next_allowed: implementing`
- `not_approved`면 `next_allowed: implementing`
- `artifact_under_review`는 implementation artifact 경로

### `worklog_update`
- `verdict: none`
- `next_allowed: none`
- `revision_class: none`

## 사람용 본문 규칙

사람용 `.md` 본문은 한국어를 기본으로 쓴다.
아래 용어는 그대로 유지한다.
- status / verdict 값
- stage 이름
- skill / agent 이름
- path / key / field 이름