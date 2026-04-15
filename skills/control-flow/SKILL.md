---
name: control-flow
description: state-authoritative 방식으로 single-feature workflow를 제어하고, persisted artifact·state·revision 규칙에 따라 stop 또는 completed까지 합법 전이를 수행하는 skill.
---

# Control Flow

`control-flow`는 single-feature workflow의 orchestration layer다.

## main authority

main workflow authority는 아래 다섯 가지다.
- persisted `policy-resolution`
- persisted review-stage `read ledger`
- persisted review-stage `read trace`
- `.claude/workflow/<feature-slug>/` 아래 workflow artifact와 sidecar metadata
- `.claude/state/<feature-slug>.json`

사람용 문서는 workflow checkpoint가 아니다.

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

Skill 도구로 specialist를 호출하면 안 된다.
Skill은 standalone 직접 호출용이다.

stage별 매핑:
- `planning` → `Agent(subagent_type="po")`
- `plan_review` → `Agent(subagent_type="reviewer")`
- `build` → `Agent(subagent_type="po")`
- `result_review` → `Agent(subagent_type="reviewer")`
- `final_review` → `Agent(subagent_type="reviewer")`
- `validation` → validate-task 스크립트 직접 실행 (specialist agent 호출 아님, 아래 참조)

`controller`도 Agent 도구로 호출한다.

## validation 단계 처리 규칙

`next_step: validation`이면 specialist agent를 호출하지 않고 아래를 직접 수행한다.

0. `artifacts/acceptance.md` 존재 확인 — 없으면 즉시 `blocked` 처리하고 stop
1. `validate-task.sh` (Unix) 또는 `validate-task.ps1` (Windows) 실행
2. 실행 결과(exit code, output)를 수집한다
3. validation summary를 `evidence/validation-summary-<timestamp>.json`에 저장한다
4. `last_validation_summary`를 갱신한다
5. result `passed`면 `final_review_pending`으로 state 전이
6. result `failed`면 `build_pending`으로 state 전이 후 stop
7. state 갱신 후 `controller` 재판정

validate-task 스크립트가 없으면: stop하고 사용자에게 보고한다.

## raw specialist output 규칙

- specialist가 반환한 `[ARTIFACT_METADATA_JSON]`, `[ARTIFACT_BODY_MD]`는 internal-only다.
- 이 raw 블록을 사용자에게 그대로 출력하지 않는다.
- raw 반환을 받으면 즉시:
  1. 파싱
  2. latest artifact 저장
  3. immutable history 저장
  4. metadata 검증
  5. state 갱신
  6. controller 재판정
  순으로 처리한다.
- 이 과정이 끝나기 전에는 사용자에게 응답하지 않는다.

## state shape 강제 규칙

- state 파일은 반드시 `STATE_SCHEMA.md`의 current schema를 따른다.
- abbreviated state shape를 쓰지 않는다.
- 아래 축약 키는 current authority가 아니다.
  - `current_stage`
  - `in_progress`
  - `pending_planning`
  - `pending_reviewing`
  - `pending_implementing`
  - `implementation_design_pending`
  - `implementation_pending`
- current schema와 맞지 않는 기존 state를 발견하면, controller 호출 전에 current schema로 정규화한 뒤 저장한다.
- state 정규화 없이 workflow를 진행하지 않는다.

## review 입력 고정

review 단계 호출 전에는 반드시 persisted `read ledger`를 만든다.

canonical path:
- `plan_review` → `.claude/workflow/<feature-slug>/contracts/read-ledger-plan-review.json`
- `result_review` → `.claude/workflow/<feature-slug>/contracts/read-ledger-result-review.json`
- `final_review` → `.claude/workflow/<feature-slug>/contracts/read-ledger-final-review.json`

각 ledger 필수 키:
- `stage`
- `artifact_under_review`
- `required_read_targets`
- `allowed_direct_reads`
- `provided_context_refs`
- `policy_resolution_ref`
- `created_at`

ledger `allowed_direct_reads` 필수 포함 항목:
- ledger 파일 자신의 경로 (false-positive bound violation 방지)

## internal auto-heal 규칙

아래는 user-visible stop이 아니라 internal repair 대상이다.
- review-ready state인데 read ledger가 없음
- state가 current schema와 다름
- latest artifact만 있고 history 저장이 없음
- raw specialist output은 받았지만 아직 저장되지 않음

이 경우:
1. 먼저 복구한다
2. state / artifact를 다시 맞춘다
3. controller를 재판정한다
4. 그래도 stop이면 그때만 사용자에게 보고한다

## 책임 범위

`control-flow`는 아래를 담당한다.
- policy 문서 해결
- `policy-resolution` 저장
- state 초기화
- state 정규화
- `controller` 호출
- review용 `read ledger` 생성
- specialist agent 1회 호출 (validation 제외)
- validation 단계 직접 실행
- specialist 반환에서 `ARTIFACT_METADATA_JSON`과 `ARTIFACT_BODY_MD` 추출
- latest artifact body 저장
- latest artifact sidecar metadata 저장
- immutable history 저장
- sidecar metadata 검증
- review 단계의 observed `read trace` 수집 및 저장
- warning 계산 및 evidence 기록
- machine-readable state 갱신
- bounded revision request 생성 및 소진 처리
- 각 전이 후 `controller` 재호출
- stop 또는 completed 상태까지 반복

## canonical artifact 경로

latest artifact body:
- `planning` → `.claude/workflow/<feature-slug>/artifacts/plan.md`
- `plan_review` → `.claude/workflow/<feature-slug>/artifacts/review-plan.md`
- `build` → `.claude/workflow/<feature-slug>/artifacts/build-summary.md`
- `result_review` → `.claude/workflow/<feature-slug>/artifacts/review-result.md`
- `final_review` → `.claude/workflow/<feature-slug>/artifacts/review-final.md`

latest artifact metadata:
- `planning` → `.claude/workflow/<feature-slug>/artifacts/plan.meta.json`
- `plan_review` → `.claude/workflow/<feature-slug>/artifacts/review-plan.meta.json`
- `build` → `.claude/workflow/<feature-slug>/artifacts/build-summary.meta.json`
- `result_review` → `.claude/workflow/<feature-slug>/artifacts/review-result.meta.json`
- `final_review` → `.claude/workflow/<feature-slug>/artifacts/review-final.meta.json`

정식 co-artifact (PO가 plan mode에서 저장, body만 추적):
- `artifacts/acceptance.md` ← validation의 판정 기준; 없으면 planning 완료 불가

supplementary artifact (추적 없음):
- `artifacts/spec.md`

## artifact body integrity check

artifact body 저장 전 아래를 확인한다.
- 본문이 비어 있지 않다
- 최소 제목 line이 존재한다
- code fence가 열렸으면 닫혀 있다

실패 시 malformed artifact로 본다.

## review verdict 처리 규칙

### `approved`
- 해당 producer artifact를 `accepted_artifacts`에 반영한다
- `revision_request`를 초기화한다
- 다음 state로 이동한다 (plan_review → build_pending, result_review → validation_pending, final_review → completed)
- 계속 진행 가능하다

### `approved_with_revisions`
아래를 모두 만족할 때만 bounded retry를 허용한다.
- `revision_class == bounded`
- `revision_scope_preserved == true`
- `auto_fix_allowed == true`
- `required_revisions`가 비어 있지 않다
- `forbidden_changes`가 비어 있지 않다
- `revision_target_stage`가 stage 규칙과 일치한다

허용되면:
- `revision_request`를 state에 기록한다
- `attempt_count`는 올리지 않는다
- target producer pending state로 이동한다
- 같은 run 안에서 target stage를 1회만 재호출한다

하나라도 만족하지 못하면:
- malformed review contract로 보고 stop한다

### `not_approved`
- `revision_request`를 초기화한다
- target producer pending state로 이동한다
- state는 저장한다
- 자동 재호출하지 않고 stop한다

## bounded retry 입력 규칙

producer stage를 bounded retry로 재호출할 때는 아래 입력을 함께 넘긴다.
- `parent_review_ref`
- `required_revisions`
- `forbidden_changes`
- `revision_attempt`

producer는 이 입력 밖으로 수정 범위를 넓히지 않는다.

## specialist 반환 검증 규칙

specialist가 반환한 metadata에서 아래를 검증한다.

### 타입 교정

- 문자열 `"null"` → JSON `null`로 교정한다
- 타입 교정 발생 시 `evidence_warnings`에 기록한다

### reviewer evidence 필드 격리

reviewer metadata에 아래 필드가 있어도 무시한다.
- `required_read_targets`
- `allowed_direct_reads`
- `missing_read_targets`
- `evidence_status`
- `evidence_warnings`

이 필드들은 control-flow가 ledger와 read trace에서 직접 계산한다.

### malformed artifact 처리

아래 중 하나라도 해당하면 malformed로 판정한다.
- `ARTIFACT_BODY_MD` 본문이 비어 있다
- 최소 제목 line이 없다
- code fence가 열렸지만 닫히지 않았다
- `ARTIFACT_METADATA_JSON` 파싱 실패

malformed 처리:
1. workflow 전이를 차단한다
2. raw specialist output을 `evidence/malformed-<stage>-<timestamp>.json`에 보존한다
3. state에 `blocker_present: true`를 기록한다

## reviewer 출력 제약

reviewer specialist가 반환하는 metadata에서 control-flow가 사용하는 필드:
- `verdict`
- `self_reported_reads` (또는 `direct_reads_used`)
- `revision_class`
- `revision_scope_preserved`
- `auto_fix_allowed`
- `required_revisions`
- `forbidden_changes`
- `revision_target_stage`

아래 필드는 reviewer가 제공해도 무시하고 control-flow가 직접 계산한다.
- `required_read_targets`
- `allowed_direct_reads`
- `missing_read_targets`
- `evidence_status`
- `evidence_warnings`

## state 갱신 핵심 규칙

### carry-forward 원칙

state 파일을 쓸 때는 반드시:
1. 현재 state.json을 먼저 읽는다
2. 변경된 필드만 덮어쓴다
3. 바뀌지 않은 필드는 그대로 유지한다

state를 처음부터 재구성하면 carry-forward 원칙 위반이다.

### 생산 단계 완료 후
- latest artifact 저장
- latest metadata 저장
- immutable history 저장
- state 반영
- review 대기 state면 `pending_review` 채움
- bounded retry producer 결과라면 이 시점에만 `attempt_count += 1`

### review 완료 후
- latest review artifact 저장
- immutable history 저장
- `read trace` 저장
- evidence 반영
- review verdict에 따라:
  - 승인 → 해당 producer artifact만 `accepted_artifacts`에 반영
  - 수정 승인 → `accepted_artifacts`는 유지하고 `revision_request` 생성
  - 비승인 → `accepted_artifacts`는 유지하고 stop-ready pending state 기록
- final review 승인 전에는 `accepted_artifacts.build_summary`를 최종 확정하지 않는다

### review_inputs 소스 매핑 규칙

`review_inputs.<stage>`는 아래 출처에서만 채운다.
- `ref`: ledger 파일 canonical path
- `artifact_under_review`: ledger의 `artifact_under_review`
- `required_read_targets`: ledger 파일을 직접 읽어 복사
- `allowed_direct_reads`: ledger 파일을 직접 읽어 복사 (축소 금지, 정확히 동일한 배열)

reviewer 출력에서 이 필드를 가져오지 않는다.
carry-forward 원칙에 따라 이후 전이에서 이 값을 비우거나 덮어쓰지 않는다.

### last_review_evidence 소스 매핑 규칙

`last_review_evidence`를 채울 때:
- `allowed_direct_reads`: ledger 파일을 직접 읽어 복사
- `required_read_targets`: ledger 파일을 직접 읽어 복사
- `observed_direct_reads_used`: read trace 파일에서 가져옴
- `self_reported_direct_reads_used`: reviewer metadata의 `direct_reads_used`
- `missing_read_targets`, `evidence_status`, `evidence_warnings`: control-flow가 Q1/Q2/Q3 규칙으로 계산

reviewer가 제공한 evidence 관련 필드는 이 계산에 사용하지 않는다.

## evidence 계산 규칙

evidence 필드는 control-flow가 계산한다. reviewer가 제공한 evidence 관련 필드는 무시한다.

### 계산 순서

1. ledger를 읽어 `required_read_targets`와 `allowed_direct_reads`를 가져온다
2. read trace에서 `observed_direct_reads_used`를 확인한다
3. 아래 세 조건을 순서대로 평가한다

### Q1: missing required targets

`missing_read_targets = required_read_targets - observed_direct_reads_used`

비어 있지 않으면:
- `evidence_status: failed`
- `missing_read_targets`에 기록
- workflow 전이를 차단한다

### Q2: bound violation

`observed_direct_reads_used - allowed_direct_reads`에 항목이 있으면:
- `evidence_status: failed`
- `evidence_warnings`에 violation 항목 기록
- workflow 전이를 차단한다

### Q3: self-report vs observed 불일치

`self_reported_direct_reads_used != observed_direct_reads_used`이면:
- `evidence_status`는 최소 `warning` (Q1/Q2 failed가 아닌 경우)
- `evidence_warnings`에 불일치 항목 기록
- workflow 전이를 차단하지 않는다

### 최종 evidence_status

- Q1 또는 Q2 해당 → `failed` (차단)
- Q3만 해당 → `warning` (계속 가능)
- 해당 없음 → `passed`

## 실행 순서

초기 준비:
1. 필수 policy 문서 해결
2. `policy-resolution` 저장
3. state가 없으면 fresh-start state 초기화
4. state가 current schema가 아니면 정규화

반복 규칙:
1. 현재 state 기준으로 `controller` 호출
2. `controller`가 `continue: false` 또는 `next_step: none`이면 종료
3. 다음 단계가 review면 필요한 read ledger 존재를 보장한다. 없으면 즉시 생성한다
4. `next_step: validation`이면 validate-task 스크립트 직접 실행 (specialist agent 미호출)
5. 그 외 단계면 정확히 한 specialist **agent** 호출
6. specialist 반환에서 `ARTIFACT_METADATA_JSON`과 `ARTIFACT_BODY_MD`를 추출
7. latest artifact body 저장
8. latest artifact metadata 저장
9. immutable history 저장
10. metadata 검증
11. review 단계면 observed `read trace` 저장
12. evidence 계산 및 반영
13. state 파일 갱신
14. 갱신된 state로 `controller` 재호출
15. 계속 진행 가능하면 반복

## 응답 직전 final check

사용자에게 응답하기 직전에는 반드시 아래를 확인한다.

1. 최신 state 파일이 존재한다
2. 최신 artifact와 state가 서로 일치한다
3. immutable history도 저장되어 있다
4. `controller`를 마지막으로 한 번 더 호출했다
5. `controller.continue == false` 또는 `controller.next_step == none` 이다

위 다섯 조건 중 하나라도 만족하지 못하면 사용자에게 응답하지 말고 orchestration을 계속한다.

## stop 규칙

아래에서는 멈춘다.
- 필수 policy 문서 누락
- inconsistent policy resolution
- artifact body 또는 metadata 누락 또는 malformed
- state와 artifact가 충돌함
- `approval_stale`
- `human_gate_required`
- review `not_approved`
- validation `failed`
- bounded retry 1회 후에도 다시 승인되지 않음
- `controller`가 stop 판정을 내림
- `evidence_status: failed` (Q1: missing required targets 또는 Q2: bound violation)
