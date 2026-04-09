---
title: CONTROL_CONTRACT
version: 5
status: active
---

# CONTROL_CONTRACT

## 목적

이 문서는 workflow artifact가 공통으로 따라야 하는 기계용 metadata 형식과 저장 위치를 정의한다.

사람이 읽는 artifact 본문은 `.md`로 저장한다.
기계가 읽는 메타데이터는 같은 artifact 이름의 `.meta.json`으로 저장한다.
YAML front matter를 사람용 `.md` 앞에 붙이지 않는다.

## 저장 구조

canonical root:
- `.claude/workflow/<feature-slug>/`

하위 디렉터리:
- `artifacts/` → 사람이 읽는 `.md`
- `contracts/` → `policy-resolution`, `read-ledger`
- `evidence/` → `validation-summary`, `read-trace`, warning 기록

artifact별 저장 쌍:
- `artifacts/plan.md` + `artifacts/plan.meta.json`
- `artifacts/review-plan.md` + `artifacts/review-plan.meta.json`
- `artifacts/implementation-design.md` + `artifacts/implementation-design.meta.json`
- `artifacts/review-implementation.md` + `artifacts/review-implementation.meta.json`
- `artifacts/implementation.md` + `artifacts/implementation.meta.json`
- `artifacts/review-final.md` + `artifacts/review-final.meta.json`

## specialist 반환 형식

specialist stage는 저장용 파일을 직접 쓰는 것이 아니라 아래 두 블록을 반환한다.
추가 설명 문장은 넣지 않는다.

1. `ARTIFACT_METADATA_JSON`
2. `ARTIFACT_BODY_MD`

예시:

````text
[ARTIFACT_METADATA_JSON]
```json
{ ... }
```
[ARTIFACT_BODY_MD]
```md
# 제목
...
```
````

orchestration layer는 첫 블록을 `.meta.json`에, 두 번째 블록을 `.md`에 저장한다.

## artifact metadata 공통 형식

```json
{
  "workflow_stage": "<planning|reviewing|implementation_design|implementation_review|implementing|final_review|worklog_update>",
  "feature_slug": "<feature-slug>",
  "artifact_type": "<plan|review_plan|implementation_design|review_implementation|implementation|review_final|worklog>",
  "scope_fingerprint": "<string-or-null>",
  "status": "<completed|incomplete|blocked>",
  "verdict": "<none|approved|approved_with_revisions|not_approved>",
  "next_allowed": "<planning|reviewing|implementation_design|implementation_review|implementing|final_review|worklog_update|none>",
  "blocker_present": true,
  "blocker_reason": "<string>",
  "human_input_required": false,
  "stale_conditions": ["<condition>"],
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

### `feature_slug`
현재 run의 active feature와 일치해야 한다.

### `scope_fingerprint`
승인된 feature scope를 식별하는 안정적 값이다. stage 사이에서 가볍게 바꾸지 않는다.

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

단일 단계명만 적는다. blocked 또는 terminal이면 `none`이다.

### `artifact_under_review`, `read_ledger_ref`
- review 단계에서는 둘 다 필수다.
- review가 아닌 단계에서는 `null`이다.

### `required_read_targets`
해당 artifact가 안전하게 주장하려면 반드시 읽어야 했던 대상 목록이다.

### `allowed_direct_reads`
orchestration layer가 허용한 직접 읽기 집합이다.

### `direct_reads_used`
specialist가 자기보고한 직접 읽기 목록이다.
현재는 authoritative trace가 아니라 self-report다.
이 값은 이후 `read-trace`와 비교할 수 있다.

### `missing_read_targets`
specialist가 인지한 필수 읽기 누락 목록이다.
warning 모드에서는 이 값이 비어 있지 않아도 자동 차단 사유로 바로 승격하지 않는다.
다만 reviewer는 본문에서 불충분한 근거를 명시해야 한다.

### `evidence_policy_mode`
현재 기본값은 `warning`이다.
read 정책 위반 의심은 우선 warning으로 기록하고, 곧바로 workflow를 차단하지 않는다.

### `evidence_status`
허용값:
- `not_applicable`
- `passed`
- `warning`
- `failed`

사용 규칙:
- non-review stage는 `not_applicable`
- review stage에서 read 관련 경고가 있으면 `warning`
- 입력이 너무 부족해 review 자체가 성립하지 않으면 `failed`

### `evidence_warnings`
warning 모드에서 기록하는 코드 또는 문장 목록이다.
예시:
- `required_read_target_missing_reported`
- `direct_read_out_of_allowlist_reported`
- `self_report_observed_trace_mismatch`

## Stage별 최소 기대값

### `planning`
- `verdict: none`
- 정상 완료 시 `next_allowed: reviewing`
- `artifact_under_review: null`
- `read_ledger_ref: null`
- `evidence_status: not_applicable`

### `reviewing`
- `verdict`는 `approved`, `approved_with_revisions`, `not_approved` 중 하나
- 정상 승인 시 `next_allowed: implementation_design`
- `artifact_under_review`는 plan artifact 경로
- `required_read_targets`에는 plan artifact가 포함되어야 함
- read 관련 warning이 있으면 `evidence_status: warning`으로 기록 가능

### `implementation_design`
- `verdict: none`
- 정상 완료 시 `next_allowed: implementation_review`
- review 관련 필드는 `null`
- `evidence_status: not_applicable`

### `implementation_review`
- `verdict`는 `approved`, `approved_with_revisions`, `not_approved` 중 하나
- 정상 승인 시 `next_allowed: implementing`
- `artifact_under_review`는 implementation-design artifact 경로
- `required_read_targets`에는 implementation-design artifact가 포함되어야 함
- read 관련 warning이 있으면 `evidence_status: warning`으로 기록 가능

### `implementing`
- `verdict: none`
- 정상 완료 시 `next_allowed: final_review`
- review 관련 필드는 `null`
- `evidence_status: not_applicable`

### `final_review`
- `verdict`는 `approved`, `approved_with_revisions`, `not_approved` 중 하나
- 정상 승인 시 `next_allowed: none`
- `artifact_under_review`는 implementation artifact 경로
- `required_read_targets`에는 implementation artifact와 validation evidence가 포함되어야 함
- read 관련 warning이 있으면 `evidence_status: warning`으로 기록 가능

### `worklog_update`
- `verdict: none`
- main workflow를 전진시키지 않음
- `next_allowed: none`
- review 관련 필드는 `null`
- `evidence_status: not_applicable`

## 사람용 artifact 본문 규칙

사람용 `.md` 본문은 한국어를 기본으로 쓴다.
아래 용어만 그대로 유지한다.
- status / verdict 값
- stage 이름
- skill / agent 이름
- path / key / field 이름

artifact 본문은 기계용 front matter 없이 바로 제목과 본문으로 시작한다.
