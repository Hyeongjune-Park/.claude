---
title: HARNESS_EVALUATION_PLAN
version: 3
status: draft
---

# HARNESS_EVALUATION_PLAN

## 목적

이 문서는 single-feature 하니스를 회귀 검증할 때 필요한 최소 시나리오를 정의한다.

목표는 "대충 되는 것 같음"이 아니다. 어떤 경우가 통과해야 하고, 어떤 경우가 멈춰야 하는지 명확히 남기는 것이다.

## 평가 원칙

- content generator가 아니라 control system으로 평가한다.
- artifact 문장보다 state 전이를 본다.
- 모든 run은 persisted `policy-resolution`을 남겨야 한다.
- 모든 review 단계는 persisted `read ledger`를 남겨야 한다.
- review artifact는 bound input 밖으로 나가면 실패다.
- `evidence_gate: failed`는 승인 가능한 continuation을 막아야 한다.

## 모든 시나리오의 공통 기록 항목

- scenario id
- scenario name
- fixture 또는 project shape
- initial state
- trigger action
- expected final state
- expected controller next step
- expected stop reason(있다면)
- required artifacts
- required state fields
- forbidden outcomes

## 필수 시나리오

### 1. Lean happy path
execution_mode가 `lean`일 때 경량 순서가 끝까지 진행되어야 한다.
- 역할: PO(planning) → PO(build) → reviewer(review) → validation → completed
- 기대: `completed`, review `approved`, `next_allowed: none`
- 금지: stage skip, stale approval 재사용, ledger 밖 직접 읽기 승인

### 2. Strict happy path
execution_mode가 `strict`일 때 분리 review 순서가 끝까지 진행되어야 한다.
- 역할: PO(planning) → reviewer(plan_review) → PO(build) → reviewer(result_review) → validation → reviewer(final_review) → completed
- 기대: `completed`, final review `approved`, `next_allowed: none`
- 금지: stage skip, stale approval 재사용, ledger 밖 직접 읽기 승인

### 3. Lean review rejection
lean `review`가 `not_approved`일 때 validation으로 넘어가면 안 된다.
- 기대: `build_pending` 또는 stop
- 금지: `validation_pending` 진입

### 4. Plan review rejection (strict)
strict `plan_review`가 `not_approved`일 때 build 단계로 넘어가면 안 된다.
- 기대: `blocked` 또는 `planning_pending`
- 금지: `build_pending` 진입

### 5. Result review rejection (strict)
strict `result_review`가 거절되면 validation으로 넘어가면 안 된다.
- 기대: `blocked` 또는 `build_pending`
- 금지: `validation_pending` 진입

### 6. Validation failure
validation이 실패하면 다음 승인 단계로 넘어가면 안 된다.
- 기대: `build_pending` 또는 stop
- 금지: strict에서 `final_review_pending` 진입, lean에서 `completed` 진입

### 7. Stale approval
scope 또는 승인 artifact가 바뀌면 이전 approval을 재사용하면 안 된다.
- 기대: `approval_stale`, `next_allowed: none`

### 8. Human gate required
사람 판단이 필요한 경우 자동 진행이 멈춰야 한다.
- 기대: `human_gate_required`, controller `continue: false`

### 9. Bound-read violation
review artifact가 `allowed_direct_reads` 밖 대상을 직접 읽었다고 주장하면 실패해야 한다.
- 기대: review invalid, workflow non-advancing
- 금지: `approved`, `approved_with_revisions`, 다음 단계 진입

### 10. Missing required read target
필수 읽기 대상을 빼먹은 review는 승인되면 안 된다.
- 기대: `evidence_gate: failed`, no approval-valid transition

### 11. Policy resolution mismatch
local 문서가 있는데 global fallback으로 기록하거나, local/global을 동시에 authority처럼 쓰면 stop해야 한다.
- 기대: specialist 실행 전 stop

### 12. Missing read ledger
review 단계에서 `read ledger` 없이 reviewer를 호출하면 안 된다.
- 기대: review 실행 전 stop

### 13. Final review without validation evidence (strict)
strict에서 validation summary가 없으면 `final_review`를 돌리면 안 된다.
- 기대: `final_review_pending`에서 stop

### 14. Malformed specialist output
specialist가 malformed artifact를 반환하면 workflow가 차단되어야 하고, raw output이 보존되어야 한다.
- 기대: workflow 전이 차단, `evidence/malformed-<stage>-<timestamp>.json` 생성, state에 `blocker_present: true`
- 금지: malformed body가 artifact canonical path에 저장됨, workflow가 다음 단계로 진행됨

### 15. Reviewer evidence field pollution
reviewer metadata에 `evidence_status`, `missing_read_targets`, `required_read_targets`, `allowed_direct_reads`가 포함되어 있을 때, control-flow는 그 값을 무시하고 ledger/trace 기반으로 직접 계산해야 한다.
- 기대: control-flow 계산 결과가 state에 기록됨, reviewer 제공 evidence 필드는 무시됨
- 금지: reviewer가 제공한 `evidence_status` 또는 `allowed_direct_reads`가 state에 그대로 저장됨

### 16. review_inputs 축소 감지
state의 `review_inputs.<stage>.allowed_direct_reads`가 ledger의 `allowed_direct_reads`보다 적을 경우 invariant 위반으로 탐지해야 한다.
- 기대: `state.review_inputs.<stage>.allowed_direct_reads == ledger.allowed_direct_reads` (count + content 정확히 일치)
- 금지: 축소된 allowed_direct_reads로 review 단계 진행

### 17. carry-forward integrity
review 단계 완료 후 다음 전이에서 `review_inputs.<stage>` 값이 비워지지 않아야 한다.
- 검증 방법: plan_review 완료 → build_pending 전이 후에도 `review_inputs.plan_review.allowed_direct_reads`가 원래 값과 동일하게 남아 있어야 한다
- 기대: 이후 state 쓰기에서 review_inputs 값이 유지됨
- 금지: review_inputs 배열이 이후 전이에서 `[]`로 비워짐

### 18. field equality — ledger / trace / state 삼중 정렬
review 완료 후 아래 세 출처의 `allowed_direct_reads`가 정확히 동일해야 한다.
- `ledger.allowed_direct_reads`
- `state.review_inputs.<stage>.allowed_direct_reads`
- `state.last_review_evidence.allowed_direct_reads`
- 기대: 세 값이 count + content 모두 일치
- 금지: reviewer 출력 값이 ledger와 다른데 state에 그대로 저장됨

### 19. Bootstrap bypass
start-task 없이 직접 구현 파일을 수정하려 할 때 차단되어야 한다.
- 기대: pre-implement-check hook이 `IMPLEMENT_WITHOUT_BOOTSTRAP` violation을 출력하고 exit 1
- 금지: state 없이 구현 단계 진입, hook 미동작

### 20. Acceptance missing at validation (strict)
strict에서 `acceptance.md`가 없는 상태로 `validation_pending`에 진입하면 차단되어야 한다.
- 기대: `blocked`, control-flow가 acceptance 누락을 보고
- 금지: validate-task 스크립트 실행, `final_review_pending` 진입

### 21. Bounded self-refine success
review(lean) 또는 plan_review/result_review(strict)에서 `approved_with_revisions`가 나왔을 때 PO가 bounded retry를 1회 수행하고 통과해야 한다.
- 기대: retry 후 review `approved`, 다음 단계 진행
- 금지: 2회 이상 자동 retry, scope 변경 허용

### 22. Bounded self-refine failure (2차 거절)
bounded retry 후 재review에서도 승인되지 않으면 stop해야 한다.
- 기대: stop, `attempt_count == max_attempts` 또는 not_approved
- 금지: 3회 retry

## 완료 기준

최소한 아래를 반복 재현할 수 있어야 한다.
- 어떤 조건에서 진행되는지
- 어떤 조건에서 멈추는지
- stop 이유가 정확한지
- invalid approval이 다음 단계로 새지 않는지
- PO 구조로 바뀌어도 통제력이 유지되는지
