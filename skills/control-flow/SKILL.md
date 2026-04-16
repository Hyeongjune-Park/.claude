---
name: control-flow
description: state-authoritative 방식으로 single-feature workflow를 제어하고 execution_mode(lean/strict)에 맞춰 stop 또는 completed까지 합법 전이를 수행하는 skill.
---

# Control Flow

`control-flow`는 single-feature workflow의 orchestration layer다.

## main authority

main workflow authority는 아래 다섯 가지다.
- persisted `policy-resolution`
- persisted review-stage `read ledger` (strict 기본, lean 선택)
- persisted review-stage `read trace` (strict 기본, lean 선택)
- `.claude/workflow/<feature-slug>/` 아래 workflow artifact와 sidecar metadata
- `.claude/state/<feature-slug>.json`

사람용 문서는 workflow checkpoint가 아니다.

## execution mode

- 기본 모드: `lean`
- 모드 값은 state의 `execution_mode`를 따른다.
- 값이 없거나 유효하지 않으면 안전하게 `strict`로 fallback한다.
- 모드 상세 정책은 `docs/HARNESS_EXECUTION_MODES.md`를 따른다.

### lean 기본 흐름

- `planning → build → review → validation → completed`

### strict 흐름

- `planning → plan_review → build → result_review → validation → final_review → completed`

## 필수 policy 문서

- `.claude/docs/HARNESS_SCOPE.md`
- `.claude/docs/HARNESS_PRINCIPLES.md`
- `.claude/docs/CONTROL_CONTRACT.md`
- `.claude/docs/WORKFLOW_STATE_MACHINE.md`
- `.claude/docs/STATE_SCHEMA.md`
- `.claude/docs/SELF_REFINE_POLICY.md`

global fallback root:
- `~/.claude/docs/`

## policy-resolution 규칙

각 필수 문서마다 아래 순서로 정확히 하나만 확정한다.
1. project-local exact path 확인
2. 있으면 `project_local`로 기록
3. 없으면 global fallback 확인
4. 있으면 `global_fallback`으로 기록
5. 둘 다 없으면 `missing`

정규화 결과는 아래 경로에 저장한다.
- `.claude/workflow/<feature-slug>/contracts/policy-resolution.json`

## 범위 규칙

- feature 작업은 `active project root` 안에서만 본다
- sibling repository를 읽지 않는다
- 시작부터 광범위 스캔을 하지 않는다
- exact path 확인과 필요한 좁은 읽기를 우선한다

## 디렉터리 초기화

첫 persistence가 필요할 때 아래를 만든다.
1. `.claude/`
2. `.claude/state/`
3. `.claude/workflow/`
4. `.claude/workflow/<feature-slug>/`
5. `.claude/workflow/<feature-slug>/artifacts/`
6. `.claude/workflow/<feature-slug>/artifacts/history/`
7. `.claude/workflow/<feature-slug>/contracts/`
8. `.claude/workflow/<feature-slug>/evidence/`

## specialist 호출 규칙

control-flow 내부 specialist stage는 반드시 **Agent 도구**로 호출한다.

stage별 매핑:
- `planning` → `Agent(subagent_type="po")`
- `build` → `Agent(subagent_type="po")`
- `review` → `Agent(subagent_type="reviewer")` (lean)
- `plan_review` → `Agent(subagent_type="reviewer")` (strict)
- `result_review` → `Agent(subagent_type="reviewer")` (strict)
- `final_review` → `Agent(subagent_type="reviewer")` (strict)
- `validation` → validate-task 스크립트 직접 실행

`controller`도 Agent 도구로 호출한다.

## validation 단계 처리 규칙

`next_step: validation`이면 specialist agent를 호출하지 않고 아래를 직접 수행한다.

0. strict 모드에서만 `artifacts/acceptance.md` 존재 확인 (없으면 `blocked` 후 stop)
1. `validate-task.sh` (Unix) 또는 `validate-task.ps1` (Windows) 실행
2. 실행 결과(exit code, stdout)를 수집한다
3. stdout에서 `VALIDATION_SUMMARY_JSON` 마커 다음 줄 JSON을 파싱한다
4. JSON을 `evidence/validation-summary-<timestamp>.json`에 저장한다
5. `last_validation_summary`를 갱신한다 (`ref`, `result`, `generated_at`)
6. result가 `pass` 또는 `pass_with_warn`이면:
   - lean: `completed`
   - strict: `final_review_pending`
7. result가 `fail`이면 `build_pending`으로 state 전이 후 stop
8. state 갱신 후 `controller` 재판정

validate-task 스크립트가 없으면 stop하고 사용자에게 보고한다.

## raw specialist output 규칙

- specialist가 반환한 `[ARTIFACT_METADATA_JSON]`, `[ARTIFACT_BODY_MD]`는 internal-only다.
- raw 블록을 사용자에게 그대로 출력하지 않는다.
- raw 반환을 받으면 즉시 아래 순서로 처리한다.
  1. 파싱
  2. latest artifact 저장
  3. immutable history 저장
  4. metadata 검증
  5. state 갱신
  6. controller 재판정

## state shape 강제 규칙

- state 파일은 반드시 `STATE_SCHEMA.md`의 current schema를 따른다.
- `execution_mode`가 없으면 `strict`로 채우고 warning을 남긴다.
- state 정규화 없이 workflow를 진행하지 않는다.

## review 입력 고정

review 단계 호출 전 ledger를 준비한다.

canonical path:
- `review` → `.claude/workflow/<feature-slug>/contracts/read-ledger-review.json` (lean)
- `plan_review` → `.claude/workflow/<feature-slug>/contracts/read-ledger-plan-review.json` (strict)
- `result_review` → `.claude/workflow/<feature-slug>/contracts/read-ledger-result-review.json` (strict)
- `final_review` → `.claude/workflow/<feature-slug>/contracts/read-ledger-final-review.json` (strict)

필수 키:
- `stage`
- `artifact_under_review`
- `required_read_targets`
- `allowed_direct_reads`
- `provided_context_refs`
- `policy_resolution_ref`
- `created_at`

lean 모드에서는 read trace 생략 가능하다. 생략 시 warning을 남긴다.

## internal auto-heal 규칙

아래는 user-visible stop이 아니라 internal repair 대상이다.
- review-ready state인데 read ledger가 없음
- state가 current schema와 다름
- latest artifact만 있고 history 저장이 없음
- raw specialist output은 받았지만 아직 저장되지 않음

## 책임 범위

`control-flow`는 아래를 담당한다.
- policy 문서 해결 및 `policy-resolution` 저장
- state 초기화 / 정규화 / 갱신
- `controller` 호출
- review용 `read ledger` 생성
- specialist agent 1회 호출 (validation 제외)
- validation 단계 직접 실행
- artifact body / metadata / history 저장
- review evidence 계산 및 warning 기록
- stop 또는 completed 상태까지 반복

## canonical artifact 경로

latest artifact body:
- `planning` → `.claude/workflow/<feature-slug>/artifacts/plan.md`
- `build` → `.claude/workflow/<feature-slug>/artifacts/build-summary.md`
- `review` → `.claude/workflow/<feature-slug>/artifacts/review.md` (lean)
- `plan_review` → `.claude/workflow/<feature-slug>/artifacts/review-plan.md` (strict)
- `result_review` → `.claude/workflow/<feature-slug>/artifacts/review-result.md` (strict)
- `final_review` → `.claude/workflow/<feature-slug>/artifacts/review-final.md` (strict)

latest artifact metadata:
- `planning` → `.claude/workflow/<feature-slug>/artifacts/plan.meta.json`
- `build` → `.claude/workflow/<feature-slug>/artifacts/build-summary.meta.json`
- `review` → `.claude/workflow/<feature-slug>/artifacts/review.meta.json` (lean)
- `plan_review` → `.claude/workflow/<feature-slug>/artifacts/review-plan.meta.json` (strict)
- `result_review` → `.claude/workflow/<feature-slug>/artifacts/review-result.meta.json` (strict)
- `final_review` → `.claude/workflow/<feature-slug>/artifacts/review-final.meta.json` (strict)

co-artifact:
- `artifacts/acceptance.md` (strict planning에서 사용)

supplementary artifact:
- `artifacts/spec.md`

## artifact body integrity check

artifact body 저장 전 아래를 확인한다.
- 본문이 비어 있지 않다
- 최소 제목 line이 존재한다
- code fence가 열렸으면 닫혀 있다

실패 시 malformed artifact로 판정한다.

## review verdict 처리 규칙

### `approved`

- `revision_request`를 초기화한다
- mode/stage별 다음 상태로 이동한다
  - lean: `review` 승인 후 `validation_pending`
  - strict: `plan_review` 승인 후 `build_pending`
  - strict: `result_review` 승인 후 `validation_pending`
  - strict: `final_review` 승인 후 `completed`

### `approved_with_revisions`

아래를 모두 만족할 때만 bounded retry를 허용한다.
- `revision_class == bounded`
- `revision_scope_preserved == true`
- `auto_fix_allowed == true`
- `required_revisions` 비어 있지 않음
- `forbidden_changes` 비어 있지 않음
- `revision_target_stage`가 mode/stage 규칙과 일치

허용되면 target producer pending state로 이동한다.
- lean review → `build_pending`
- strict plan_review → `planning_pending`
- strict result_review/final_review → `build_pending`

### `not_approved`

- target producer pending state로 이동
- 자동 재호출 없이 stop

## evidence 계산 규칙

strict:
- Q1(missing required targets) 또는 Q2(bound violation) → `failed` (차단)
- Q3(self-report vs observed 불일치)만 해당 → `warning` (계속)

lean:
- 핵심 direct read self-report만 있으면 진행 가능
- read trace/ledger 상세가 부족하면 warning 기록
- 단, 명시적 bound violation은 여전히 `failed`

## 실행 순서

초기 준비:
1. 필수 policy 문서 해결
2. `policy-resolution` 저장
3. state가 없으면 fresh-start state 초기화 (`execution_mode: lean`)
4. state 정규화

반복 규칙:
1. 현재 state 기준으로 `controller` 호출
2. `continue: false` 또는 `next_step: none`이면 종료
3. 다음 단계가 review 계열이면 ledger 보장
4. `next_step: validation`이면 validate-task 실행
5. 그 외 단계는 specialist agent 1회 호출
6. artifact body / metadata / history 저장
7. metadata 검증
8. mode에 맞는 evidence 계산
9. state 갱신
10. controller 재판정

## 응답 직전 final check

사용자 응답 직전 아래를 확인한다.
1. 최신 state 파일 존재
2. 최신 artifact와 state 일치
3. immutable history 저장 완료
4. controller 재판정 완료
5. `continue == false` 또는 `next_step == none`

## stop 규칙

아래에서는 멈춘다.
- 필수 policy 문서 누락
- inconsistent policy resolution
- malformed artifact
- state와 artifact 충돌
- `approval_stale`
- `human_gate_required`
- validation result `fail`
- bounded retry 1회 후 재승인 실패
- controller stop 판정
- strict evidence Q1/Q2 실패
