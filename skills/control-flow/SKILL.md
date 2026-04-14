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
- `planning` → `Agent(subagent_type="planner")`
- `reviewing` → `Agent(subagent_type="reviewer")`
- `implementation_design` → `Agent(subagent_type="implementation-designer")`
- `implementation_review` → `Agent(subagent_type="reviewer")`
- `implementing` → `Agent(subagent_type="implementer")`
- `final_review` → `Agent(subagent_type="reviewer")`

`controller`도 Agent 도구로 호출한다.

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
- current schema와 맞지 않는 기존 state를 발견하면, controller 호출 전에 current schema로 정규화한 뒤 저장한다.
- state 정규화 없이 workflow를 진행하지 않는다.

## review 입력 고정

review 단계 호출 전에는 반드시 persisted `read ledger`를 만든다.

canonical path:
- `reviewing` → `.claude/workflow/<feature-slug>/contracts/read-ledger-reviewing.json`
- `implementation_review` → `.claude/workflow/<feature-slug>/contracts/read-ledger-implementation-review.json`
- `final_review` → `.claude/workflow/<feature-slug>/contracts/read-ledger-final-review.json`

각 ledger 필수 키:
- `stage`
- `artifact_under_review`
- `required_read_targets`
- `allowed_direct_reads`
- `provided_context_refs`
- `policy_resolution_ref`
- `created_at`

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
- specialist agent 1회 호출
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
- `reviewing` → `.claude/workflow/<feature-slug>/artifacts/review-plan.md`
- `implementation_design` → `.claude/workflow/<feature-slug>/artifacts/implementation-design.md`
- `implementation_review` → `.claude/workflow/<feature-slug>/artifacts/review-implementation.md`
- `implementing` → `.claude/workflow/<feature-slug>/artifacts/implementation.md`
- `final_review` → `.claude/workflow/<feature-slug>/artifacts/review-final.md`

latest artifact metadata:
- `planning` → `.claude/workflow/<feature-slug>/artifacts/plan.meta.json`
- `reviewing` → `.claude/workflow/<feature-slug>/artifacts/review-plan.meta.json`
- `implementation_design` → `.claude/workflow/<feature-slug>/artifacts/implementation-design.meta.json`
- `implementation_review` → `.claude/workflow/<feature-slug>/artifacts/review-implementation.meta.json`
- `implementing` → `.claude/workflow/<feature-slug>/artifacts/implementation.meta.json`
- `final_review` → `.claude/workflow/<feature-slug>/artifacts/review-final.meta.json`

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
- 다음 producer pending state로 이동한다
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

## state 갱신 핵심 규칙

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
- final review 승인 전에는 `accepted_artifacts.implementation`을 갱신하지 않는다

## evidence 계산 규칙

`missing_read_targets`는 아래로 계산한다.

`required_read_targets - observed_direct_reads_used`

필수 target이 하나라도 빠지면:
- `missing_read_targets`에 남긴다
- `evidence_status`는 최소 `warning`
- review body에도 누락을 적는다

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
4. 정확히 한 specialist **agent** 호출
5. specialist 반환에서 `ARTIFACT_METADATA_JSON`과 `ARTIFACT_BODY_MD`를 추출
6. latest artifact body 저장
7. latest artifact metadata 저장
8. immutable history 저장
9. metadata 검증
10. review 단계면 observed `read trace` 저장
11. evidence 계산 및 반영
12. state 파일 갱신
13. 갱신된 state로 `controller` 재호출
14. 계속 진행 가능하면 반복

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
- bounded retry 1회 후에도 다시 승인되지 않음
- `controller`가 stop 판정을 내림