# 프로젝트 Claude 설정
#
# 이 파일은 전역 하니스의 templates/CLAUDE.md에서 복사된 로컬 프로젝트용 템플릿이다.
# 프로젝트 특화 규칙은 아래 [프로젝트 설정] 섹션에 추가한다.
# 전역 하니스 정책 문서: <global-harness-root>/docs/

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
- immutable history 저장
- machine-readable state 갱신
- review 단계의 `read ledger`와 `read trace` 저장
- 각 전이 후 `controller` 재판정
- stop 또는 completed 상태까지 반복

전문 stage는 work plane만 담당한다.
- `planning`
- `reviewing`
- `implementation-design`
- `implementation-review`
- `implementing`
- `final-review`

세 가지를 섞지 않는다.
- 사람용 문서: `docs/`, `worklog/`
- workflow run 산출물: `.claude/workflow/<feature-slug>/`
- machine-readable state: `.claude/state/<feature-slug>.json`

workflow run 산출물은 아래처럼 분리한다.
- `artifacts/` → 사람이 읽는 `.md`와 대응 `.meta.json`
- `artifacts/history/` → immutable history
- `contracts/` → `policy-resolution`, `read-ledger`
- `evidence/` → `validation-summary`, `read-trace`, warning 기록

사람용 문서를 workflow authority로 쓰지 않는다.
state 파일과 artifact sidecar metadata가 있을 때 자유 서술로 state를 대신하지 않는다.
현재 승인 없이 다음 gate를 넘기지 않는다.
root, feature, scope, policy 중 하나라도 애매하면 stop한다.

중요:
- `/control-flow`가 호출되면, 현재 turn 안에서 `controller`가 `continue: false` 또는 `next_step: none`을 반환할 때까지 orchestration loop를 계속 수행한다.
- specialist가 반환한 `[ARTIFACT_METADATA_JSON]`, `[ARTIFACT_BODY_MD]`는 internal-only 산출물이다. 이 raw 블록을 사용자에게 그대로 보여주지 않는다.
- stage 하나를 수행한 뒤 사용자에게 중간 결과를 보고하고 멈추지 않는다. 중간 응답은 stop 조건이 성립했을 때만 허용한다.
- 한 번의 합법 전이는 아래가 모두 끝나야 완료다.
  1. specialist stage 호출
  2. raw 산출물 파싱
  3. artifact body 저장
  4. artifact sidecar metadata 저장
  5. immutable history 저장
  6. sidecar metadata 검증
  7. review 단계면 `read trace` 저장
  8. state 파일 갱신
  9. 갱신된 state로 `controller` 재판정
- artifact body만 저장되고 state가 이전 pending 상태에 남아 있으면 전이는 완료가 아니다.
- review-ready state에서 필요한 `read ledger`가 없으면 사용자에게 멈췄다고 보고하지 말고 `control-flow`가 즉시 생성한 뒤 재판정한다.
- control-flow 내부 specialist 호출은 반드시 Agent 도구를 사용한다.
- Skill 도구 사용은 standalone 직접 호출일 때만 허용한다.
- 사용자에게 응답하기 직전에는 아래 둘 중 하나여야 한다.
  - workflow가 `completed`, `blocked`, `approval_stale`, `human_gate_required` 중 하나다
  - 또는 `controller`가 명시적으로 `continue: false`를 반환했다
- 위 조건이 아니면 응답하지 말고 orchestration을 계속한다.

현재 read 정책은 `warning` 모드다.
- read 관련 이상 징후는 우선 `evidence/`와 state에 warning으로 기록한다.
- warning만으로는 workflow를 자동 차단하지 않는다.
- 자동 차단은 malformed artifact, 필수 contract 누락, stale approval, human gate, 명시적 blocked, `evidence_status: failed`에 한정한다.

---

## [프로젝트 설정]

<!-- 이 섹션에 프로젝트 특화 규칙을 추가한다. -->
<!-- 예: 특정 디렉터리 제한, 프레임워크 규칙, 금지 패턴 등 -->
<!-- 프로젝트 특화 정책 문서는 .claude/docs/ 에 추가한다. -->
