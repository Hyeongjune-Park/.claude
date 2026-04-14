---
name: implementation-review
description: standalone 직접 호출용 implementation-review skill. control-flow 내부 specialist 호출에는 사용하지 않는다.
---

# Implementation Review

이 skill은 standalone 직접 호출용이다.

## 중요

- `control-flow` 내부 implementation_review 단계에는 이 Skill을 사용하지 않는다.
- control-flow 내부 implementation_review 단계는 반드시 `Agent(subagent_type="reviewer")`를 사용한다.
- 이 Skill은 사용자가 `/implementation-review`를 독립적으로 직접 호출할 때만 사용한다.

## 필수 입력

caller는 아래를 제공해야 한다.
- `artifact_under_review`
- `read_ledger_ref`
- `required_read_targets`
- `allowed_direct_reads`
- `policy_resolution_ref`