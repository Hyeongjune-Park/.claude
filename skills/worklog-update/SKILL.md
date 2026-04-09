---
name: worklog-update
description: 완료된 workflow artifact를 바탕으로 사람용 worklog를 작성하거나 갱신하는 선택적 persistence skill.
---

# Worklog Update

이 skill은 사람용 worklog entry를 작성한다.

## 규칙

- 완료된 workflow artifact를 source로 사용한다.
- machine-readable state를 쓰지 않는다.
- workflow artifact를 대체하지 않는다.
- main workflow를 스스로 전진시키지 않는다.
- entry는 factual하고 feature-scoped하게 유지한다.

## 필수 출력

- active feature
- source artifacts used
- worklog path written
- summary of the entry
