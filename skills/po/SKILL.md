---
name: po
description: standalone 직접 호출용 PO skill. execution_mode(lean/strict)에 맞춰 planning/build를 수행한다.
---

# PO

이 skill은 standalone 직접 호출용이다.

## 중요

- `control-flow` 내부 specialist 호출에는 이 Skill을 사용하지 않는다.
- control-flow 내부 planning/build는 `Agent(subagent_type="po")`를 사용한다.

## 필수 입력

- `mode` (`plan` 또는 `build`)
- `execution_mode` (`lean` 또는 `strict`)
- `active_project_root`
- bounded retry일 때:
  - `parent_review_ref`
  - `required_revisions`
  - `forbidden_changes`
  - `revision_attempt`

## 규칙

- `active_project_root`만 읽는다.
- sibling project를 참고하지 않는다.
- plan mode에서는 코드를 구현하지 않는다.
- review를 수행하지 않는다.
- bounded retry면 `required_revisions`만 반영한다.

## mode별 기대 출력

- `mode: plan`
  - lean: `plan.md` 필수, `next_allowed: build`
  - strict: `plan.md` + `acceptance.md` 필수, `next_allowed: plan_review`
- `mode: build`
  - lean: `build-summary.md`, `next_allowed: review`
  - strict: `build-summary.md`, `next_allowed: result_review`

## 반환 형식

반드시 아래 두 블록만 반환한다.

[ARTIFACT_METADATA_JSON]
```json
{ ... }
```
[ARTIFACT_BODY_MD]
```md
# ...
...
```
