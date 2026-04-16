---
title: HARNESS_SCOPE
version: 3
status: active
---

# HARNESS_SCOPE

## 목적

이 문서는 하니스가 자동화해도 되는 범위, 자동으로 추론하면 안 되는 범위, 그리고 반드시 stop해야 하는 상황을 정한다.

## 대상 범위

이 하니스는 기본적으로 아래 작업에 맞춘다.
- 단일 feature workflow
- small~medium 규모의 backend 또는 full-stack 작업
- 비어 있거나 파일 수가 많지 않은 project root
- 기본 `lean` 흐름: `planning → build → review → validation`
- 선택 `strict` 흐름: `planning → plan_review → build → result_review → validation → final_review`

## In scope

하니스가 자동화할 수 있는 것:
- feature 단위 `planning` (PO)
- `build` (PO: design + implementation)
- `review` (lean) 또는 `plan_review`/`result_review`/`final_review` (strict)
- `validation` (validate-task 스크립트 실행)
- `.claude/workflow/` 아래 workflow artifact 저장
- `.claude/state/` 아래 machine-readable state 저장
- main workflow가 충분히 진행된 뒤의 선택적 사람용 문서 저장

## Out of scope

사용자가 명시적으로 요구하지 않는 한 아래는 자동으로 하지 않는다.
- sibling repository에서 구현 패턴 차용
- 인접 저장소 구조를 보고 architecture 추론
- 작업을 cross-feature / cross-package 범위로 확장
- 승인되지 않은 shared contract 변경
- 사람용 문서를 workflow authority로 사용
- 병렬 lane orchestration
- 같은 run에서 harness policy 수정과 feature workflow 수행을 동시에 처리

## Root 규칙

project inspection의 기준은 항상 `active project root`다.

허용 예외:
- 필수 policy 문서가 로컬에 없을 때만 `~/.claude/docs/` global fallback 사용

허용하지 않음:
- sibling repository 탐색
- parent project source를 기본 context로 사용
- unrelated project에서 toolchain 가정 가져오기

## Fresh-start 규칙

새 프로젝트에는 아래가 모두 없을 수 있다.
- `.claude/state/`
- `.claude/workflow/`
- source file
- package manifest
- config file

이 자체는 blocker가 아니다. 첫 persistence가 필요할 때 생성하면 된다.

## Human gate 규칙

아래 상황에서는 자동 진행하지 않고 사람 입력을 요구한다.
- feature scope가 애매함
- active project root가 애매함
- 필수 policy 문서가 없음
- 필요한 이전 승인이 stale 상태임
- 승인되지 않은 shared contract 교체/확장이 필요함
- 사용자 영향이 다른 복수 설계안 중 하나를 선택해야 함

## Persistence 규칙

main workflow의 authoritative persistence는 아래 두 곳이다.
- `.claude/workflow/<feature-slug>/...`
- `.claude/state/<feature-slug>.json`

사람용 문서는 선택 사항이며 authority가 아니다.

## Validation 규칙

- validation은 execution mode 기준으로 판정한다.
- lean: `plan.md` + review + build 결과를 기준으로 최소 검증한다.
- strict: `acceptance.md`를 포함한 full artifact 기준으로 검증한다.
- reviewer가 승인 범위 밖의 새로운 요구사항을 발명해 validation 기준으로 삼으면 안 된다.
- `validate-task.*` 스크립트가 실행 command와 결과를 남겨야 한다. 실행하지 않은 validation을 성공으로 적지 않는다.
- strict 모드에서 `acceptance.md`가 없으면 validation_pending 단계에서 실패 처리한다.

## 요약

이 하니스는 한 번에 하나의 feature만 다룬다. 편한 추론보다 엄격한 root 규칙, 구조화된 control data, 명확한 stop을 우선한다.
