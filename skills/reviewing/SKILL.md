---
name: reviewing
description: standalone 직접 호출용 reviewing skill. control-flow 내부 specialist 호출에는 사용하지 않는다.
---

# Reviewing

이 skill은 standalone 직접 호출용이다.

## 중요

- `control-flow` 내부 review stage에는 이 Skill을 사용하지 않는다.
- control-flow 내부 reviewing / implementation_review / final_review 단계는 반드시 `Agent(subagent_type="reviewer")`를 사용한다.
- 이 Skill은 사용자가 `/reviewing`을 독립적으로 직접 호출할 때만 사용한다.

## 필수 입력

caller는 아래를 제공해야 한다.
- `artifact_under_review`
- `read_ledger_ref`
- `required_read_targets`
- `allowed_direct_reads`
- `policy_resolution_ref`

## 규칙

- plan artifact만 검토한다.
- plan을 implementation으로 다시 쓰지 않는다.
- blocking issue와 non-blocking issue를 분리한다.
- 근거 없는 주장 없이 review한다.
- `allowed_direct_reads` 밖 직접 읽기를 주장하지 않는다.
- `approved_with_revisions`는 좁고 명확한 수정일 때만 사용한다.
- 수정 요구가 넓거나 방향이 흔들리면 `not_approved`를 사용한다.
- `missing_read_targets`는 실제 읽은 목록과 `required_read_targets` 차집합으로 계산한다.