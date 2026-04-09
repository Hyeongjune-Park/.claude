`control-flow`를 기본 진입점으로 사용한다. 복잡한 작업은 직접 단계 점프하지 말고, 먼저 현재 state를 판정한 뒤 합법 전이를 진행한다.

`controller`는 control plane의 판정기다.
- 현재 state 판정
- 다음 합법 단계 1개 결정
- stop 여부 결정

`control-flow`는 orchestration layer다.
- `controller` 판정 사용
- specialist stage 호출
- 사람용 artifact 본문 저장
- artifact sidecar metadata(`.meta.json`) 저장 및 검증
- machine-readable state 갱신
- review 단계의 `read ledger`와 `read trace` 저장
- 각 전이 후 `controller` 재판정
- stop 또는 completed 상태까지 반복

전문 stage는 work plane만 담당한다.
- `planning`, `reviewing`, `implementation-design`, `implementation-review`, `implementing`, `final-review`
- 사람용 본문 작성
- 메타데이터 JSON 작성
- 검토 또는 구현 결과 보고

세 가지를 섞지 않는다.
- 사람용 문서: `docs/`, `worklog/`
- workflow run 산출물: `.claude/workflow/<feature-slug>/`
- machine-readable state: `.claude/state/<feature-slug>.json`

workflow run 산출물은 아래처럼 분리한다.
- `artifacts/` → 사람이 읽는 `.md`와 대응 `.meta.json`
- `contracts/` → `policy-resolution`, `read-ledger`
- `evidence/` → `validation-summary`, `read-trace`, warning 기록

사람용 문서를 workflow authority로 쓰지 않는다.
state 파일과 artifact sidecar metadata가 있을 때 자유 서술로 state를 대신하지 않는다.
현재 승인 없이 다음 gate를 넘기지 않는다.
root, feature, scope, policy 중 하나라도 애매하면 stop한다.

중요:
- 한 번의 합법 전이는 specialist stage 1회 호출만 뜻하지 않는다.
- 한 번의 합법 전이는 아래가 모두 끝나야 완료다.
  1. specialist stage 호출
  2. artifact body 저장
  3. artifact sidecar metadata 저장
  4. sidecar metadata 검증
  5. state 파일 갱신
  6. review 단계면 `read trace` 저장
  7. 갱신된 state로 `controller` 재판정
- artifact body만 저장되고 state가 이전 pending 상태에 남아 있으면 전이는 완료가 아니다.

현재 read 정책은 `warning` 모드다.
- read 관련 이상 징후는 우선 `evidence/`와 state에 warning으로 기록한다.
- warning만으로는 workflow를 자동 차단하지 않는다.
- 자동 차단은 malformed artifact, 필수 contract 누락, stale approval, human gate, 명시적 blocked, `evidence_status: failed`에 한정한다.