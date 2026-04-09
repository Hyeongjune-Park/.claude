---
name: control-flow
description: state-authoritative 방식으로 한 feature의 workflow를 제어하고, policy·artifact·state를 순서대로 고정하며 stop 또는 completed까지 합법 전이를 반복하는 skill.
---

# Control Flow

`control-flow`는 single-feature workflow의 orchestration layer다.

## 핵심 규칙

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

global fallback root:
- `~/.claude/docs/`

## policy-resolution 규칙

각 필수 문서마다 아래 순서로 정확히 하나만 확정한다.
1. project-local exact path 확인
2. 있으면 `project_local`로 기록하고 종료
3. 로컬에 없을 때만 global fallback 확인
4. 있으면 `global_fallback`으로 기록하고 종료
5. 둘 다 없으면 `missing`

로컬이 있으면 global을 authority로 쓰지 않는다.
정규화 결과는 아래 경로에 저장한다.
- `.claude/workflow/<feature-slug>/contracts/policy-resolution.json`

## 범위 규칙

- feature 작업은 `active project root` 안에서만 본다.
- sibling repository를 읽지 않는다.
- 시작부터 `**/*` 같은 광범위 스캔을 하지 않는다.
- exact path 확인과 필요한 좁은 읽기를 우선한다.

## 디렉터리 초기화

첫 persistence가 필요할 때 아래 순서로 만든다.
1. `.claude/`
2. `.claude/state/`
3. `.claude/workflow/`
4. `.claude/workflow/<feature-slug>/`
5. `.claude/workflow/<feature-slug>/artifacts/`
6. `.claude/workflow/<feature-slug>/contracts/`
7. `.claude/workflow/<feature-slug>/evidence/`

## review 입력 고정

review 단계 호출 전에는 반드시 persisted `read ledger`를 만든다.

canonical path:
- `reviewing` → `.claude/workflow/<feature-slug>/contracts/read-ledger-reviewing.json`
- `implementation_review` → `.claude/workflow/<feature-slug>/contracts/read-ledger-implementation-review.json`
- `final_review` → `.claude/workflow/<feature-slug>/contracts/read-ledger-final-review.json`

각 `read ledger` 필수 키:
- `stage`
- `artifact_under_review`
- `required_read_targets`
- `allowed_direct_reads`
- `provided_context_refs`
- `policy_resolution_ref`
- `created_at`

## review 단계별 binding

### `reviewing`
- plan artifact body와 sidecar metadata를 review 입력으로 묶는다.
- plan artifact body는 `required_read_targets`에 포함한다.

### `implementation_review`
- implementation-design artifact body와 sidecar metadata를 review 입력으로 묶는다.
- implementation-design artifact body는 `required_read_targets`에 포함한다.
- 필요하면 plan artifact body를 `allowed_direct_reads`에 포함할 수 있다.

### `final_review`
- implementation artifact body와 sidecar metadata를 review 입력으로 묶는다.
- validation evidence를 `required_read_targets`에 포함한다.
- 직접 확인을 허용할 source file만 `allowed_direct_reads`에 넣는다.
- review 가능한 validation evidence가 없으면 호출 전에 stop한다.

## 책임 범위

`control-flow`는 아래를 담당한다.
- policy 문서 해결
- `policy-resolution` 저장
- `controller` 호출
- review용 `read ledger` 생성
- 현재 전이에 필요한 specialist stage 1회 호출
- specialist 반환에서 `ARTIFACT_METADATA_JSON`과 `ARTIFACT_BODY_MD` 추출
- workflow artifact body 저장
- artifact sidecar metadata 저장
- sidecar metadata 검증
- review 단계의 observed `read trace` 수집 및 저장
- review artifact와 ledger 일치 여부 검증
- warning 계산 및 evidence 기록
- machine-readable state 갱신
- 각 전이 후 `controller` 재호출
- stop 또는 completed 상태까지 반복

## canonical artifact 경로

artifact body:
- `planning` → `.claude/workflow/<feature-slug>/artifacts/plan.md`
- `reviewing` → `.claude/workflow/<feature-slug>/artifacts/review-plan.md`
- `implementation_design` → `.claude/workflow/<feature-slug>/artifacts/implementation-design.md`
- `implementation_review` → `.claude/workflow/<feature-slug>/artifacts/review-implementation.md`
- `implementing` → `.claude/workflow/<feature-slug>/artifacts/implementation.md`
- `final_review` → `.claude/workflow/<feature-slug>/artifacts/review-final.md`

artifact sidecar metadata:
- `planning` → `.claude/workflow/<feature-slug>/artifacts/plan.meta.json`
- `reviewing` → `.claude/workflow/<feature-slug>/artifacts/review-plan.meta.json`
- `implementation_design` → `.claude/workflow/<feature-slug>/artifacts/implementation-design.meta.json`
- `implementation_review` → `.claude/workflow/<feature-slug>/artifacts/review-implementation.meta.json`
- `implementing` → `.claude/workflow/<feature-slug>/artifacts/implementation.meta.json`
- `final_review` → `.claude/workflow/<feature-slug>/artifacts/review-final.meta.json`

review trace / validation evidence:
- `reviewing` → `.claude/workflow/<feature-slug>/evidence/read-trace-reviewing.json`
- `implementation_review` → `.claude/workflow/<feature-slug>/evidence/read-trace-implementation-review.json`
- `final_review` → `.claude/workflow/<feature-slug>/evidence/read-trace-final-review.json`
- validation summary 권장 경로 → `.claude/workflow/<feature-slug>/evidence/validation-summary.json`

## canonical stage name과 실제 skill 호출 이름 매핑

state와 metadata는 canonical stage name을 사용한다.
실제 skill 호출 이름은 아래 매핑을 사용한다.

- `planning` → `planning`
- `reviewing` → `reviewing`
- `implementation_design` → `implementation-design`
- `implementation_review` → `implementation-review`
- `implementing` → `implementing`
- `final_review` → `final-review`
- `worklog_update` → `worklog-update`

## 전이 정의

한 번의 합법 전이는 아래를 모두 포함한다.
1. `controller`가 현재 state를 판정한다.
2. 현재 state에서 허용된 specialist stage 1개만 호출한다.
3. specialist가 반환한 artifact body와 metadata를 각각 canonical path에 즉시 저장한다.
4. artifact sidecar metadata를 검증한다.
5. review 단계라면 observed `read trace`를 저장한다.
6. warning 모드 기준으로 evidence를 계산한다.
7. state 파일이 새 artifact와 evidence를 반영하도록 즉시 갱신한다.
8. 갱신된 state로 `controller`를 다시 호출한다.

artifact body만 저장되고 metadata 또는 state가 이전 pending 상태에 남아 있으면 그 전이는 완료가 아니다.

## warning 모드 규칙

현재 read 정책은 `warning` 모드다.

다음은 우선 warning으로 기록한다.
- `required_read_targets` 누락 의심
- `allowed_direct_reads` 밖 읽기 의심
- self-reported `direct_reads_used`와 observed `read trace` 불일치

warning 기록 위치:
- `.claude/workflow/<feature-slug>/evidence/read-trace-<stage>.json`
- `state.last_review_evidence.warnings`
- review artifact sidecar metadata의 `evidence_warnings`

warning만으로는 workflow를 자동 차단하지 않는다.
자동 차단은 아래에 한정한다.
- malformed artifact body 또는 metadata
- 필수 contracts 누락
- human gate
- stale approval
- specialist가 명시적으로 `status: blocked`
- `evidence_status: failed`

## 실행 순서

초기 준비:
1. 필수 policy 문서 해결
2. `policy-resolution` 저장
3. state가 없으면 fresh-start state 초기화

반복 규칙:
1. 현재 state 기준으로 `controller` 호출
2. `controller`가 `continue: false` 또는 `next_step: none`이면 종료
3. 다음 단계가 review면 해당 `read ledger` 저장
4. 정확히 한 specialist stage 호출
5. specialist 반환에서 `ARTIFACT_METADATA_JSON`과 `ARTIFACT_BODY_MD`를 추출
6. artifact body를 canonical `.md`에 저장
7. artifact sidecar metadata를 canonical `.meta.json`에 저장
8. sidecar metadata 검증
9. review 단계면 observed `read trace` 저장
10. warning 계산 및 evidence 반영
11. state 파일 갱신
12. 갱신된 state로 `controller` 재호출
13. 계속 진행 가능하면 반복

저장되지 않은 출력은 완료로 간주하지 않는다.
state에 반영되지 않은 artifact도 완료로 간주하지 않는다.
재판정되지 않은 state도 다음 전이의 입력으로 쓰지 않는다.

## review stage 호출 시 전달할 입력

- `artifact_under_review`
- `read_ledger_ref`
- ledger의 `required_read_targets`
- ledger의 `allowed_direct_reads`
- 고정된 `policy_resolution_ref`

reviewer에게 이 입력을 스스로 정하게 두지 않는다.

## observed read trace

현재 환경에서는 read 추적이 완전하지 않을 수 있다.
그래도 orchestration layer는 가능한 범위에서 실제 read 흔적을 수집해 persisted `read trace`에 남긴다.

최소 기록 권장 키:
- `stage`
- `artifact_under_review`
- `read_ledger_ref`
- `required_read_targets`
- `allowed_direct_reads`
- `observed_direct_reads_used`
- `self_reported_direct_reads_used`
- `missing_required_reads_observed`
- `allowlist_outside_reads_observed`
- `evidence_status`
- `warnings`
- `captured_at`

observed trace가 불완전하더라도, 현재 warning 모드에서는 우선 warning으로만 반영한다.

## Stop 규칙

아래 상황에서는 멈춘다.
- 필수 policy 문서 누락
- inconsistent policy resolution
- artifact body 또는 sidecar metadata 누락 또는 malformed
- review 단계인데 `read ledger`가 없음
- 필수 contracts가 없음
- state와 artifact가 충돌함
- `human_input_required: true`
- approval stale
- specialist가 `status: blocked`
- `controller`가 stop 판정을 내림
- `evidence_status: failed`

## 보고 규칙

마지막에는 caller가 요청한 범위만 보고한다. blocked 상태라고 해서 follow-up 질문으로 흐름을 밀지 않는다.

## 요약

`control-flow`는 다음 한 stage만 호출하고 끝나는 skill이 아니다.
각 전이에서 specialist stage 호출은 1회만 허용되지만, workflow run 전체는 stop 또는 completed 상태가 될 때까지 이어질 수 있다.
현재는 read 관련 이상 징후를 warning으로 기록하면서 진행 가능성을 유지한다.
따라서 `planning` 결과가 저장되면 같은 run 안에서 state를 `plan_ready_for_review`로 갱신하고, 이어서 `reviewing` 가능 여부를 다시 판정해야 한다.