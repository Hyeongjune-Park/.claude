---
name: final-review
description: bound review input만 사용해 실제 구현 파일과 validation evidence를 검토하고 최종 verdict를 반환하는 skill.
---

# Final Review

이 skill은 implementation 완료 후, review 가능한 validation evidence가 있을 때만 사용한다.

## 필수 입력

caller는 아래를 제공해야 한다.
- `artifact_under_review`인 implementation artifact
- `read_ledger_ref`
- `required_read_targets`
- `allowed_direct_reads`
- 고정된 `policy_resolution_ref`

입력을 임의로 확장하지 않는다.

## 규칙

- 실제 구현 파일과 기록된 validation output만 검토한다.
- plan이나 design으로 code review를 대체하지 않는다.
- 읽지 않은 파일을 직접 읽은 것으로 주장하지 않는다.
- `allowed_direct_reads` 밖 직접 읽기를 주장하지 않는다.
- 실제 source와 validation evidence로 요구사항 충족 여부를 확인한다.
- 필수 read target이 빠졌다고 판단되면 warning을 남긴다.
- 현재 정책은 `warning` 모드이므로, read 관련 의심은 우선 `evidence_status: warning`으로 기록한다.
- 사람용 본문은 한국어를 기본으로 쓴다.

## 최소 필수 읽기 대상

- implementation artifact
- review가 참조한 validation evidence
- 직접 확인했다고 주장한 모든 source file

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
- verdict
- metadata JSON
- 사람용 Markdown 본문

정상 승인 시 `next_allowed: none`이다.

## 반환 형식

반드시 아래 두 블록만 반환한다.

````text
[ARTIFACT_METADATA_JSON]
```json
{ ... }
```
[ARTIFACT_BODY_MD]
```md
# Final Review
...
```
````

front matter를 붙이지 않는다.
