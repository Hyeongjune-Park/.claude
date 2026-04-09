---
name: reviewing
description: bound review input만 사용해 `planning` artifact를 검토하고 `implementation_design` 전 verdict를 반환하는 skill.
---

# Reviewing

이 skill은 plan review 전용이다.
`implementation_review`, `final_review`는 각각 전용 skill을 사용한다.

## 필수 입력

caller는 아래를 제공해야 한다.
- `artifact_under_review`인 plan artifact
- `read_ledger_ref`
- `required_read_targets`
- `allowed_direct_reads`
- 고정된 `policy_resolution_ref`

입력을 임의로 확장하지 않는다.

## 규칙

- plan artifact만 검토한다.
- plan을 implementation 내용으로 다시 쓰지 않는다.
- blocking issue와 non-blocking issue를 분리한다.
- 근거 없는 주장 없이 review한다.
- `allowed_direct_reads` 밖 직접 읽기를 주장하지 않는다.
- 필수 read target이 빠졌다고 판단되면 본문과 metadata에 warning을 남긴다.
- 현재 정책은 `warning` 모드이므로, read 관련 의심은 우선 `evidence_status: warning`으로 기록한다.
- 사람용 본문은 한국어를 기본으로 쓴다.

## 필수 출력

- review scope
- artifact under review
- read ledger ref
- required read targets
- allowed direct reads
- direct reads used
- missing read targets
- evidence status
- evidence warnings
- evidence summary
- overall assessment
- blocking issues
- non-blocking issues
- required revisions
- verdict
- metadata JSON
- 사람용 Markdown 본문

정상 승인 시 `next_allowed: implementation_design`이다.

## 반환 형식

반드시 아래 두 블록만 반환한다.

````text
[ARTIFACT_METADATA_JSON]
```json
{ ... }
```
[ARTIFACT_BODY_MD]
```md
# Review Plan
...
```
````

front matter를 붙이지 않는다.
