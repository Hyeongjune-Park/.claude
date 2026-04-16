---
title: HARNESS_PRINCIPLES
version: 5
status: active
---

# HARNESS_PRINCIPLES

## 목적

모든 하니스 문서, agent, skill이 따라야 하는 공통 운영 원칙이다.

## 1. control과 production을 분리한다

control이 결정하는 것:
- 현재 workflow state
- 다음 합법 단계
- continue / stop
- warning 기록 방식
- evidence status 판정

production이 만드는 것 (PO):
- spec / plan / acceptance
- build summary (design + implementation)
- local validation 결과

review가 만드는 것 (reviewer):
- lean: 단일 review verdict
- strict: plan review / result review / final review verdict

`controller`가 specialist work를 대신 만들면 안 되고, specialist가 workflow control을 대신 판단해도 안 된다.

## 2. 자유 서술보다 구조화된 데이터가 우선이다

workflow 판정 우선순위:
1. `.claude/state/<feature-slug>.json`
2. 유효한 artifact sidecar metadata (`artifacts/*.meta.json`)
3. persisted `policy-resolution`
4. persisted `read ledger`
5. persisted `read trace`
6. `WORKFLOW_STATE_MACHINE.md`
7. 직접 확인한 근거
8. 자유 서술

## 3. machine-readable state가 authority다

사람용 문서는 main workflow authority가 아니다. 사람용 문서는 저장용 산출물이다.
workflow 판정은 state와 artifact sidecar metadata를 우선한다.

## 4. 한 번에 한 단계만 전진한다

workflow는 항상 단일 합법 전이만 수행한다. 한 번의 판단으로 전체 workflow를 예약하지 않는다.

한 번의 합법 전이는 아래를 포함한다.
- specialist 1회 호출
- artifact body 저장
- artifact sidecar metadata 저장
- 필요 contract 저장
- state 갱신
- review 단계면 read trace 기록
- controller 재판정

## 5. specialist 실행 전에 고정 입력을 먼저 저장한다

specialist 실행 전에 orchestration layer는 아래 입력을 먼저 고정한다.
- 정규화된 `policy-resolution`
- review 단계용 `read ledger`
- 현재 authoritative state context

specialist가 policy를 다시 찾거나 직접 읽기 범위를 임의로 늘리게 두지 않는다.

## 6. root discipline을 지킨다

feature 작업은 `active project root` 안에서만 본다. sibling project의 구현 패턴, toolchain, source 구조를 가져오지 않는다.

허용 예외는 필수 policy 문서의 global fallback뿐이다.

## 7. evidence discipline은 bound input과 observed trace를 함께 본다

stage는 실제로 읽은 파일만 직접 근거로 주장할 수 있다.

review 단계에서 orchestration layer는 최소한 아래를 묶어 준다.
- `artifact_under_review`
- `required_read_targets`
- `allowed_direct_reads`

reviewer는 이 범위를 넘겨 직접 읽기를 주장하면 안 된다.

직접 확인하지 않은 내용은 아래 중 하나로 표시한다.
- `Provided by caller`
- `Inferred`
- `Unverified`

evidence 판정 정책:
- Q1(missing required targets)와 Q2(bound violation): `evidence_status: failed` — workflow 차단
- Q3(self-report vs observed trace 불일치): warning으로 기록하되 차단하지 않는다
- strict에서는 observed `read trace`를 반드시 남긴다
- lean에서는 핵심 직접 읽기 목록만 남겨도 된다 (warning 허용)
- evidence 필드(required_read_targets, allowed_direct_reads, missing_read_targets, evidence_status, evidence_warnings)는 control-flow가 ledger/trace 기반으로 계산한다. reviewer가 제공해도 무시한다.

## 8. policy resolution은 단일 출처여야 한다

필수 policy 문서마다 결과는 정확히 하나다.
- `project_local`
- `global_fallback`
- `missing`

로컬 사본이 있으면 그것이 우선이다. 같은 문서에 대해 local과 global을 동등한 authority로 취급하지 않는다.

## 9. review는 slot-based 형식을 유지한다

reviewer가 반환하는 metadata 필수 항목 (reviewer 책임):
- `artifact_under_review`
- `read_ledger_ref`
- `direct_reads_used` (self-report — 실제로 읽은 파일 목록)
- `verdict`
- `revision_class`, `revision_scope_preserved`, `auto_fix_allowed`
- `required_revisions`, `forbidden_changes`, `revision_target_stage`

control-flow가 계산하여 채우는 항목 (reviewer가 제공해도 무시):
- `required_read_targets`
- `allowed_direct_reads`
- `missing_read_targets`
- `evidence_status`
- `evidence_warnings`

사람용 review 본문은 verdict, direct_reads_used, 주요 판단 근거를 명시적으로 요약해야 한다.

## 10. false continuation보다 stop을 우선하되, warning 모드는 과잉 차단하지 않는다

아래 상황에서는 멈춘다.
- 필수 policy 문서 누락
- inconsistent policy resolution
- strict 필수 artifact 누락
- 필수 `read ledger` 누락
- state와 artifact 충돌
- stale approval
- human input 필요
- 다음 합법 단계를 안전하게 고를 수 없음
- specialist가 명시적으로 `status: blocked`
- `evidence_status: failed`
- Q1: `missing_read_targets`가 비어 있지 않음 (필수 읽기 대상 누락)
- Q2: review artifact가 `allowed_direct_reads` 밖 대상을 직접 읽었다고 주장함 (bound violation)

아래 상황은 현재 warning으로 기록한다.
- Q3: self-report와 observed trace 불일치

warning은 evidence와 state에 남기되, Q3만 해당하는 경우에는 자동 차단 사유로 승격하지 않는다.

## 11. lean을 기본으로 두고 strict는 조건부로 승격한다

- 기본 execution mode는 `lean`이다.
- `strict`는 high-risk 작업 또는 명시 요청에서만 기본 모드로 사용한다.
- mode 누락/오염 시에는 안전하게 `strict`로 fallback한다.
- mode별 상세 기준은 `HARNESS_EXECUTION_MODES.md`를 따른다.

## 12. specialist stage는 좁게 유지한다

- PO의 `planning` 모드는 구현하지 않는다.
- PO의 `build` 모드는 승인된 plan 범위를 넘어 scope를 확장하지 않는다.
- review 단계(plan_review / result_review / final_review)는 검토 대상 산출물을 다시 쓰지 않는다.
- 어느 단계도 전체 소스 덤프를 하지 않는다.

## 13. 공통 규칙은 공통 문서에 둔다

공유 규칙은 shared docs에 둔다. skill과 agent는 필요한 범위만 요약하고, 같은 정책을 여러 파일에 길게 중복하지 않는다.

## 요약

하니스는 아래 성질을 유지해야 한다.
- state-authoritative
- root-disciplined
- evidence-aware
- Q3-warning-tolerant (Q1/Q2는 차단, Q3만 경고 허용)
- policy-consistent
- stoppable
- role-separated
