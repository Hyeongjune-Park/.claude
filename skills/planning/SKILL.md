---
name: planning
description: standalone 직접 호출용 planning skill. control-flow 내부 specialist 호출에는 사용하지 않는다.
---

# Planning

이 skill은 standalone 직접 호출용이다.

## 중요

- `control-flow` 내부 specialist 호출에는 이 Skill을 사용하지 않는다.
- control-flow 내부 planning stage는 반드시 `Agent(subagent_type="planner")`를 사용한다.
- 이 Skill은 사용자가 `/planning`을 독립적으로 직접 호출할 때만 사용한다.

## 필수 입력

기본 입력:
- `active_project_root`
- 작업 요구사항

bounded retry일 때 추가 입력:
- `parent_review_ref`
- `required_revisions`
- `forbidden_changes`
- `revision_attempt`

## 규칙

- `active_project_root`만 읽는다.
- sibling project를 참고하지 않는다.
- 코드를 구현하지 않는다.
- review를 수행하지 않는다.
- root가 비어 있으면 비어 있다고 적는다.
- bounded retry면 `required_revisions`만 반영한다.
- bounded retry면 `forbidden_changes`를 건드리지 않는다.
- bounded retry면 scope를 다시 정의하지 않는다.
- 사람용 본문은 한국어를 기본으로 쓴다.
- 상태값, verdict 값, stage 이름, path, field 이름은 그대로 둔다.

## 반환 형식

반드시 아래 두 블록만 반환한다.

[ARTIFACT_METADATA_JSON]
```json
{ ... }
```
[ARTIFACT_BODY_MD]
```
# Plan
...
```