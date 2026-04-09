---
name: implementation-design
description: 승인된 plan을 구현 가능한 설계로 바꾸되 실제 코드 덤프 없이 파일·계약·검증 단위로 정리하는 skill.
---

# Implementation Design

`implementation-design`은 승인된 plan을 구현 직전 설계로 바꾼다.

## 규칙

- 승인된 plan review 또는 동등한 승인 artifact가 있어야 한다.
- 승인된 scope 안에 머문다.
- 코드를 구현하지 않는다.
- 필요할 때의 작은 예시 외에는 전체 파일 본문을 덤프하지 않는다.
- 파일 수준, contract 수준, validation 수준, 실행 순서를 설계한다.
- 사람용 본문은 한국어를 기본으로 쓴다.

## 필수 출력

- goal
- in scope / out of scope
- affected files
- file별 책임
- request/response와 validation 세부사항
- execution order
- validation plan
- risks 또는 open questions
- metadata JSON
- 사람용 Markdown 본문

## 반환 형식

반드시 아래 두 블록만 반환한다.

````text
[ARTIFACT_METADATA_JSON]
```json
{ ... }
```
[ARTIFACT_BODY_MD]
```md
# Implementation Design
...
```
````

front matter를 붙이지 않는다.

## 비목표

이 산출물은 code generation용 전체 소스가 아니다. 붙여넣기용 전체 파일 트리처럼 보이면 지나치게 상세한 것이다.
