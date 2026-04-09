---
name: save-docs
description: 완료된 workflow artifact를 바탕으로 사람용 project 문서를 저장하는 선택적 persistence skill.
---

# Save Docs

이 skill은 main workflow가 충분히 진행되었거나 끝난 뒤 사람용 문서를 저장할 때 사용한다.

## 규칙

- 사람용 문서는 workflow checkpoint가 아니다.
- `.claude/state`를 쓰지 않는다.
- `.claude/workflow`를 쓰지 않는다.
- main workflow를 전진시키지 않는다.
- 기존 workflow artifact와 현재 state를 바탕으로 문서를 만든다.

## 허용 대상 예시

- `docs/`
- `worklog/`
- 사용자가 요청한 요약 파일

## 필수 출력

- active feature
- source artifacts used
- target doc paths written
- notes
