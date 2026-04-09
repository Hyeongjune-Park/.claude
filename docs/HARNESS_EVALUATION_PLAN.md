---
title: HARNESS_EVALUATION_PLAN
version: 2
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

### 1. Happy path
정상 입력에서 전체 합법 순서가 끝까지 진행되어야 한다.
- 기대: `completed`, final review `approved`, `next_allowed: none`
- 금지: stage skip, stale approval 재사용, ledger 밖 직접 읽기 승인

### 2. Review rejection
plan review가 `not_approved`일 때 구현 단계로 넘어가면 안 된다.
- 기대: `blocked` 또는 `planning_pending`
- 금지: `implementation_design` 진입

### 3. Implementation-review rejection
implementation design review가 거절되면 코딩으로 넘어가면 안 된다.
- 기대: `blocked` 또는 `implementation_design_pending`
- 금지: `implementing` 진입

### 4. Stale approval
scope 또는 승인 artifact가 바뀌면 이전 approval을 재사용하면 안 된다.
- 기대: `approval_stale`, `next_allowed: none`

### 5. Human gate required
사람 판단이 필요한 경우 자동 진행이 멈춰야 한다.
- 기대: `human_gate_required`, controller `continue: false`

### 6. Bound-read violation
review artifact가 `allowed_direct_reads` 밖 대상을 직접 읽었다고 주장하면 실패해야 한다.
- 기대: review invalid, workflow non-advancing
- 금지: `approved`, `approved_with_revisions`, 다음 구현 단계 진입

### 7. Missing required read target
필수 읽기 대상을 빼먹은 review는 승인되면 안 된다.
- 기대: `evidence_gate: failed`, no approval-valid transition

### 8. Policy resolution mismatch
local 문서가 있는데 global fallback으로 기록하거나, local/global을 동시에 authority처럼 쓰면 stop해야 한다.
- 기대: specialist 실행 전 stop

### 9. Missing read ledger
review 단계에서 `read ledger` 없이 reviewer를 호출하면 안 된다.
- 기대: review 실행 전 stop

### 10. Final review without validation evidence
implementation artifact는 있어도 review 가능한 validation evidence가 없으면 `final_review`를 돌리면 안 된다.
- 기대: `final_review_pending`에서 stop

## 완료 기준

최소한 아래를 반복 재현할 수 있어야 한다.
- 어떤 조건에서 진행되는지
- 어떤 조건에서 멈추는지
- stop 이유가 정확한지
- invalid approval이 다음 단계로 새지 않는지
