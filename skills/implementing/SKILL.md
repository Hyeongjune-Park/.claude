---
name: implementing
description: 승인된 `implementation_design`을 실제 코드로 옮기고 검증 결과를 review 가능한 형태로 남기는 skill.
---

# Implementing

이 skill은 승인된 `implementation_design`을 구현한다.

## 규칙

- 코딩 전 `implementation_review` 승인이 필요하다.
- `active project root` 안에서만 수정한다.
- 승인된 design scope를 벗어나지 않는다.
- sibling project 패턴을 가져오지 않는다.
- 가능한 경우 요청된 validation command를 순서대로 실행한다.
- command 출력과 pass/fail을 그대로 보고한다.
- 실행하지 않은 validation을 성공으로 적지 않는다.
- `final_review`가 읽을 수 있도록 validation evidence를 남긴다.
- 사람용 본문은 한국어를 기본으로 쓴다.

## 필수 출력

- goal
- files written
- files intentionally not changed
- validation commands requested
- validation commands executed
- exact validation results
- validation evidence refs 또는 raw excerpt
- issues encountered
- unresolved follow-up risks
- metadata JSON
- 사람용 Markdown 본문

정상 완료 시 `next_allowed: final_review`다.
`implementing` 단계에서 `next_allowed: reviewing`를 내보내지 않는다.

## 반환 형식

반드시 아래 두 블록만 반환한다.

````text
[ARTIFACT_METADATA_JSON]
```json
{ ... }
```
[ARTIFACT_BODY_MD]
```md
# Implementation Result
...
```
````

front matter를 붙이지 않는다.

## Validation evidence 규칙

`final_review`는 실제로 무슨 일이 있었는지 검증할 수 있어야 한다. 따라서 아래처럼 뭉뚱그린 문장은 금지한다.
- "tests passed"
- "build looked fine"

정확한 command와 evidence ref를 남긴다.
