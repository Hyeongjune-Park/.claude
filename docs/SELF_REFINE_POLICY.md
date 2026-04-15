---
title: SELF_REFINE_POLICY
version: 3
status: active
---

# SELF_REFINE_POLICY

## 목적

이 문서는 `approved_with_revisions`가 발생했을 때 허용되는 bounded self-refactor의 조건과 중단 규칙을 정의한다.

핵심은 자동 수정 허용이 아니라 자동 수정의 경계를 고정하는 것이다.

## 적용 범위

이 정책은 아래 review stage에 공통 적용한다.
- `plan_review`
- `result_review`
- `final_review`

## 기본 원칙

- `approved_with_revisions`는 승인과 동일하지 않다.
- 자동 수정은 review verdict가 명시적으로 허용한 경우에만 가능하다.
- 자동 수정은 같은 scope 안의 좁고 명확한 delta만 허용한다.
- 자동 수정은 stage별 최대 1회만 허용한다.
- 1회 수정 후에도 다시 `approved_with_revisions` 또는 `not_approved`가 나오면 자동 재시도하지 않는다.
- scope expansion, contract 변경, architecture 변경이 감지되면 즉시 stop한다.
- bounded retry lineage는 immutable history artifact 기준으로 추적한다.

## 자동 수정 허용 조건

아래를 모두 만족해야만 bounded self-refactor를 실행할 수 있다.

1. review verdict가 `approved_with_revisions`다.
2. review metadata의 `revision_class`가 `bounded`다.
3. review metadata의 `revision_scope_preserved`가 `true`다.
4. review metadata의 `auto_fix_allowed`가 `true`다.
5. review metadata의 `required_revisions`가 비어 있지 않다.
6. review metadata의 `forbidden_changes`가 비어 있지 않다.
7. 현재 state의 `revision_request.attempt_count < revision_request.max_attempts`다.
8. `source_review_ref`는 immutable history review artifact를 가리킨다.

하나라도 만족하지 못하면 자동 수정하지 않는다.

## 허용되는 수정

- 이미 승인된 방향 안에서 누락된 항목 보완
- 기존 scope 안에서의 파일 목록 보정
- 기존 validation 계획의 누락 보완
- wording 정리, 순서 정리, 명시성 보강
- build 단계에서는 기존 설계를 바꾸지 않는 작은 코드 수정
- final review에서 지적된 작은 검증 누락 또는 작은 버그 수정

## 금지되는 수정

- architecture 변경
- API contract 변경
- schema 변경
- dependency 추가 또는 교체
- unrelated cleanup
- 파일 범위 확대
- 새로운 요구사항 추가
- 대규모 rename 또는 refactor
- 기존 승인 범위를 다시 정의하는 수정

## stage별 target 규칙

- `plan_review`의 `approved_with_revisions` → `planning` 재수행
- `result_review`의 `approved_with_revisions` → `build` 재수행
- `final_review`의 `approved_with_revisions` → `build` 재수행

review metadata의 `revision_target_stage`는 위 규칙과 일치해야 한다.
일치하지 않으면 malformed review로 본다.

## 1회 제한 규칙

- stage별 `max_revision_attempts` 기본값은 `1`이다.
- 첫 bounded retry 후 다시 review한다.
- 재review 결과가 `approved`가 아니면 stop한다.
- 같은 stage에서 두 번째 자동 수정은 금지한다.

## attempt_count 규칙

`attempt_count`는 승인 횟수나 허가 횟수가 아니다.

의미:
- 실제로 완료되어 저장된 bounded retry producer artifact 수

규칙:
- `approved_with_revisions` 직후에는 증가시키지 않는다
- target producer artifact가 저장되고 state가 다음 review-ready state로 올라갈 때 증가시킨다
- retry 실행 전에 `attempt_count == max_attempts`이면 malformed state다

## stop 규칙

아래 중 하나라도 참이면 stop한다.
- `revision_class != bounded`
- `revision_scope_preserved != true`
- `auto_fix_allowed != true`
- `required_revisions`가 모호하거나 과도하게 넓다
- `forbidden_changes`가 비어 있다
- target stage가 정책과 다르다
- `attempt_count >= max_attempts`
- 수정 중 `scope_fingerprint`가 바뀌었다
- 사람이 판단해야 하는 open question이 생겼다
- review verdict가 `not_approved`다

## reviewer 규칙

reviewer는 `approved_with_revisions`를 쉽게 쓰면 안 된다.

아래를 모두 만족할 때만 사용한다.
- 전체 방향은 유지 가능하다
- 수정 범위가 좁다
- 수정 요구가 구체적이다
- 1회 수정으로 닫힐 가능성이 높다
- 수정 후 재review가 가능하다

그 외에는 `not_approved`를 사용한다.

## producer 규칙

bounded self-refactor로 다시 호출된 producer stage(PO)는 아래를 따른다.
- `required_revisions`만 반영한다
- `forbidden_changes`를 건드리지 않는다
- 새 요구사항을 끌어오지 않는다
- 기존 승인 범위를 다시 쓰지 않는다
- 적용한 수정과 의도적으로 건드리지 않은 항목을 본문에 남긴다
