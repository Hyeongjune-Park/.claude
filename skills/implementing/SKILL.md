---
name: implementing
description: standalone 직접 호출용 implementing skill. control-flow 내부 specialist 호출에는 사용하지 않는다.
---

# Implementing

이 skill은 standalone 직접 호출용이다.

## 중요

- `control-flow` 내부 implementing 단계에는 이 Skill을 사용하지 않는다.
- control-flow 내부 implementing 단계는 반드시 `Agent(subagent_type="implementer")`를 사용한다.
- 이 Skill은 사용자가 `/implementing`을 독립적으로 직접 호출할 때만 사용한다.

## 필수 입력

기본 입력:
- 승인된 `implementation_design`

bounded retry일 때 추가 입력:
- `parent_review_ref`
- `required_revisions`
- `forbidden_changes`
- `revision_attempt`