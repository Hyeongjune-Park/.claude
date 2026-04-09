---
name: plan-save
description: 승인되었거나 보존 가치가 있는 plan을 사람용 요약 문서로 저장하는 선택적 persistence skill.
---

# Plan Save

이 skill은 사람이 읽을 요약 plan을 저장할 때만 사용한다.

## 규칙

- source는 이미 존재하는 workflow artifact여야 한다.
- main workflow persistence로 사용하지 않는다.
- `.claude/state`를 쓰지 않는다.
- workflow를 전진시키지 않는다.

## 필수 출력

- active feature
- source plan artifact used
- target human-facing file written
- notes
