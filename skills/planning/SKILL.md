---
name: planning
description: active project root와 제공된 요구사항만 사용해 review-ready `planning` artifact를 만드는 skill.
---

# Planning

이 skill은 `planning` artifact를 작성한다.

## 규칙

- `active project root`만 읽는다.
- sibling project의 구조나 toolchain을 빌려오지 않는다.
- 코드를 구현하지 않는다.
- review를 수행하지 않는다.
- root가 비어 있으면 비어 있다고 적는다. 주변 프로젝트 가정으로 빈칸을 채우지 않는다.
- 사람용 본문은 한국어를 기본으로 쓴다.
- 상태값, verdict 값, stage 이름, path, field 이름은 그대로 둔다.

## 필수 출력

- goal
- scope
- affected files 또는 file classes
- key decisions
- risks
- validation plan
- evidence summary
- `CONTROL_CONTRACT.md`를 따르는 유효한 metadata JSON
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
# Plan: ...
...
```
````

사람용 본문 앞에 YAML front matter를 붙이지 않는다.
추가 설명 문장을 덧붙이지 않는다.

## Evidence 규칙

아래 버킷만 사용한다.
- `Inspected directly`
- `Provided by caller`
- `Inferred`

실제로 읽지 않은 파일을 직접 확인했다고 적지 않는다.
