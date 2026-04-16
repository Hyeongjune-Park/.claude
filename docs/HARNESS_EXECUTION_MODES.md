---
title: HARNESS_EXECUTION_MODES
version: 1
status: active
---

# HARNESS_EXECUTION_MODES

## 목적

이 문서는 하니스 실행 모드(`lean`, `strict`)의 기본 정책, 단계 흐름, 최소 산출물, 차단 기준을 정의한다.

## 기본값

- 기본 모드는 `lean`이다.
- `execution_mode`가 state에 없거나 유효하지 않으면 안전하게 `strict`로 fallback한다.
- high-risk 작업은 명시적으로 `strict`로 승격한다.

## 모드별 흐름

### lean

- 권장 흐름: `planning → build → review → validation → completed`
- review는 1회 기본 호출
- warning은 로그에 남기고 진행 가능

### strict

- 흐름: `planning → plan_review → build → result_review → validation → final_review → completed`
- review 분리(최소 3회)와 evidence discipline을 유지
- acceptance/read ledger/read trace/history를 강하게 요구

## strict 승격 조건

아래 중 하나면 `strict`를 기본으로 사용한다.

- API 계약 변경
- DB migration
- 대형 리팩터 또는 아키텍처 결정 포함
- 하니스 자체 문서/정책/스크립트 수정
- 사용자가 엄격 검증을 명시 요청

## 모드별 최소 artifact

### lean 최소셋

- `artifacts/plan.md`
- `artifacts/build-summary.md`
- review artifact 1개 (`artifacts/review.md` 또는 `artifacts/review-result.md` 또는 `artifacts/review-plan.md`)
- `evidence/validation-summary-<timestamp>.json`
- `.claude/state/<feature-slug>.json`

### strict 최소셋

- `artifacts/plan.md`
- `artifacts/review-plan.md`
- `artifacts/acceptance.md`
- `artifacts/build-summary.md`
- `artifacts/review-result.md`
- `artifacts/review-final.md`
- `evidence/validation-summary-<timestamp>.json`
- `.claude/state/<feature-slug>.json`

strict gate rule:
- `validation_pending` / `final_review_pending` validation gates do not require `artifacts/review-final.md`.
- `completed` validation gate requires `artifacts/review-final.md`.

## warning / block 기준

### block (즉시 stop)

- state 파싱 불가 또는 controller가 next step 판정 불가
- stale approval 재사용 시도
- human gate required 상태의 자동 확정 시도
- active project root 밖 수정 시도
- validation result `fail`
- strict 모드 필수 artifact 누락

### warning (기록 후 진행 가능)

- execution_mode 누락(자동 strict fallback)
- read trace 상세 부족
- logs 일부 누락
- jq 등 보조 도구 부재
- wording drift

warning은 최소 한 곳에 반드시 남긴다.

- `evidence/validation-summary-<timestamp>.json`
- `artifacts/build-summary.md`
- `.claude/logs/<feature-slug>/events.ndjson`
