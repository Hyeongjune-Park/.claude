# 전역 하니스 통합 계획서 초안 v1

## 1. 문서 목적

이 계획서는 현재 구축 중인 전역 하니스의 핵심 구조를 유지하면서, 다른 전문가 하니스의 장점인 `AGENTS/CLAUDE 진입 문서`, `task bootstrap script`, `hook 기반 강제`, `운영 로그`를 흡수해 더 견고한 기본 하니스로 재구성하기 위한 초안이다.

현재 하니스의 핵심 목표는 planning → review → implementation-design → implementation-review → implementing → final review를 **제어 가능한 반자동 워크플로 시스템**으로 만드는 것이다. 또한 장기적으로는 병렬 세션까지 확장할 계획이므로, 새 구조는 단순 편의성보다 **예측 가능성, 역할 분리, 중지 가능성, 검증 가능성**을 강화해야 한다. 전역 하니스는 모든 프로젝트의 기본 골격을 제공하고, 프로젝트별 특수 정책은 이후 로컬 `.claude/docs`에서 덧붙이는 구조를 유지한다.

---

## 2. 핵심 결론

새 구조는 **통합**이 아니라 **계층화**로 간다.

즉,

- `planning`, `reviewing`, `implementation-design`, `implementation-review`, `implementing` 같은 **전문 스킬은 유지**
- `controller`와 `control-flow` 같은 **상태기반 orchestration 계층도 유지**
- 대신 그 위에
  - 얇은 진입 문서
  - task bootstrap script
  - hook 기반 위반 감지/피드백
  - append-only 로그 계층
  을 추가한다

이 방향이 맞는 이유는, 현재 로드맵이 이미 `controller`, `state schema`, `evaluation harness`를 별도 축으로 삼고 있고, 병렬 확장도 중앙 controller와 lane/package state를 전제로 하기 때문이다. 이 구조를 문서 하나로 접으면 장기 목표와 충돌한다. 반대로 강제력이 필요한 규칙은 문서보다 script/hook이 더 적합하다.

---

## 3. 이번 초안에서 채택하는 설계 원칙

### 원칙 1. 스킬/서브에이전트 지침은 짧고 강하게 유지한다

채택한다.

모든 skill과 subagent 지침은 **100줄 이내를 목표**로 한다.  
다만 이건 “무조건 100줄 미만” 같은 기계적 제한이 아니라, **핵심 책임·금지사항·출력 계약·참조 문서만 남기고 세부 규칙은 외부 정책 문서로 분리한다**는 설계 원칙이다.

이 원칙이 필요한 이유는 지침이 길어질수록 모델이 일부를 누락하거나, 여러 문서가 같은 규칙을 중복 서술하면서 드리프트가 생기기 쉽기 때문이다.

실행 규칙:
- skill/subagent 문서는 목적, 해야 할 일, 하지 말아야 할 일, 출력 형식, 참조 문서만 포함
- evidence source mapping, 상태기계 세부 규칙, 정책 예외, validation 기준은 `docs/*.md`로 이동
- 공통 계약은 skill마다 반복하지 않고 `CONTROL_CONTRACT.md`를 참조

### 원칙 2. 중요한 규칙은 hook이 감지하고 피드백해야 한다

강하게 채택한다.

중요한 규칙은 “지키라고 써두는 것”으로 끝내지 않는다. 위반이 감지되면 hook이 즉시 개입해야 한다.

적용 대상:
- bootstrap 없이 바로 구현 시작
- planning/approval 없이 구현 단계 진입
- worktree 없이 병렬/격리 작업 시작
- validation 없이 완료 처리
- 금지된 경로로 직접 문서/코드 작성

hook 동작 방식:
- 위반 감지
- 실패 또는 경고 판단
- 위반 로그 기록
- 정상 경로 안내
- 필요 시 자동 재시도 지시 또는 control-flow 재진입 유도

### 원칙 3. state와 별개의 로그 계층을 둔다

채택한다.  
하지만 **로그가 state를 대체해서는 안 된다.**

이건 가장 중요한 결정이다.

- **state**는 controller가 읽는 **정규화된 현재 상태 스냅샷**
- **logs**는 append-only **증거·과정·실패 원인 기록**

으로 분리한다.

로그만 보고 controller가 다음 단계를 정하도록 바꾸는 건 권하지 않는다. 이유는 로그는 누적 기록이어서 다음 단계 판정용으로는 비결정적이고, 정규화 비용이 크며, 오히려 지금까지 어렵게 만든 state/evidence 정합성 구조를 다시 흐리게 만들기 때문이다.

더 좋은 방향은 이렇다.

- controller는 계속 state를 canonical source로 사용
- logs는 evidence, self-feedback, audit, 디버깅, state 손상 시 복구 보조용으로 사용
- state는 logs의 요약 ref만 가진다
- hook과 self-refine는 logs를 보고 수정 판단을 보조한다

즉, **state = canonical snapshot**, **logs = immutable evidence trail** 구조로 간다.

### 원칙 4. 로컬 `.claude/docs`는 프로젝트 정책 전용으로 비워 둔다

강하게 채택한다.

전역 하니스는 모든 프로젝트의 기본 틀만 제공한다.  
프로젝트 특화 규칙은 나중에 로컬 `.claude/docs`에 들어갈 것이므로, 전역 하니스는 이 경로에 일반 workflow 문서나 운영 문서를 쓰지 않는다.

허용:
- 로컬 `.claude/docs` 읽기
- 로컬 `.claude/docs`를 override source로 사용

금지:
- 전역 하니스가 로컬 `.claude/docs`에 state/workflow/log/evidence 파일 생성
- 전역 하니스가 로컬 `.claude/docs`에 기본 정책 문서 자동 쓰기

대신 전역 하니스가 쓰는 런타임 파일은 아래 경로로 제한한다.
- `.claude/state/`
- `.claude/workflow/`
- `.claude/logs/`

### 원칙 5. 전역에는 실제 `CLAUDE.md`가 없어도 된다

채택한다.

전역 하니스의 canonical source는 실제 `CLAUDE.md`가 아니라
- `AGENTS.md`
- `templates/CLAUDE.md`

가 되어도 충분하다.

즉, 전역 하니스는 진입 문서의 **원본 템플릿**만 관리하고, 실제 프로젝트에서 쓰는 `CLAUDE.md`는 bootstrap 또는 init 과정에서 로컬 루트로 복사/동기화하는 구조가 더 낫다.

이 방식이 좋은 이유는:
- 전역과 로컬의 실제 사용 위치가 다르다는 현실과 맞고
- 전역에 사용되지 않는 `CLAUDE.md`를 억지로 둘 필요가 없고
- 템플릿/동기화 경로가 더 명확하기 때문이다

---

## 4. 새 구조의 핵심 설계

### 4-1. 계층 구조

#### A. Entry Layer
- `AGENTS.md`
- `templates/CLAUDE.md`

역할:
- 이 저장소에서의 정식 시작 경로 안내
- 필수 절차 요약
- 빠른 참조 표
- policy / script / hook 위치 안내

#### B. Policy Layer
- `docs/HARNESS_SCOPE.md`
- `docs/HARNESS_PRINCIPLES.md`
- `docs/CONTROL_CONTRACT.md`
- `docs/WORKFLOW_STATE_MACHINE.md`
- `docs/STATE_SCHEMA.md`
- `docs/SELF_REFINE_POLICY.md`
- `docs/HARNESS_EVALUATION_PLAN.md`
- 이후 `PERSISTENCE_POLICY.md`, `HARNESS_CHANGE_POLICY.md`, `HARNESS_VERSIONING.md`

역할:
- 전역 하니스 규칙 정의
- controller와 hook이 참고할 기준 제공

#### C. Orchestration Layer
- `.claude/agents/controller.md`
- `.claude/skills/control-flow/SKILL.md`

역할:
- 현재 state 판정
- 다음 합법 단계 선택
- specialist 호출
- stop / continue 판단
- revision/stale/evidence 처리

#### D. Specialist Layer
유지 대상:
- `.claude/skills/planning/`
- `.claude/skills/reviewing/`
- `.claude/skills/implementation-design/`
- `.claude/skills/implementation-review/`
- `.claude/skills/implementing/`
- 필요 시 `worklog-update`, `plan-save`, `save-docs`

보조 subagent:
- planner
- reviewer
- implementation-designer
- implementer

역할:
- 실제 산출물 생산

#### E. Bootstrap / Execution Layer
- `scripts/start-task.sh`
- `scripts/start-task.ps1`
- `scripts/validate-task.sh`
- `scripts/validate-task.ps1`
- 필요 시 `scripts/complete-task.*`

역할:
- task 초기화
- worktree 생성
- 로그 디렉터리 준비
- state/workflow/log skeleton 생성
- 로컬 `CLAUDE.md` 템플릿 배치

#### F. Guardrail Layer
- hooks

역할:
- 규칙 위반 감지
- 즉시 피드백
- 위반 로그 기록
- 정상 경로 재유도
- 필요 시 차단

#### G. Runtime Data Layer
- `.claude/state/`
- `.claude/workflow/`
- `.claude/logs/`

역할:
- 현재 상태
- artifacts/contracts/evidence
- append-only 과정 로그

### 4-2. 파일 배치 초안

    global-harness/
    ├─ AGENTS.md
    ├─ templates/
    │  └─ CLAUDE.md
    ├─ docs/
    │  ├─ HARNESS_SCOPE.md
    │  ├─ HARNESS_PRINCIPLES.md
    │  ├─ CONTROL_CONTRACT.md
    │  ├─ WORKFLOW_STATE_MACHINE.md
    │  ├─ STATE_SCHEMA.md
    │  ├─ SELF_REFINE_POLICY.md
    │  ├─ HARNESS_EVALUATION_PLAN.md
    │  ├─ PERSISTENCE_POLICY.md
    │  ├─ HARNESS_CHANGE_POLICY.md
    │  └─ HARNESS_VERSIONING.md
    ├─ scripts/
    │  ├─ start-task.sh
    │  ├─ start-task.ps1
    │  ├─ validate-task.sh
    │  └─ validate-task.ps1
    ├─ hooks/
    │  ├─ pre-implement-check.*
    │  ├─ pre-complete-check.*
    │  ├─ worktree-guard.*
    │  └─ policy-guard.*
    └─ .claude/
       ├─ agents/
       │  ├─ controller.md
       │  ├─ planner.md
       │  ├─ reviewer.md
       │  ├─ implementation-designer.md
       │  └─ implementer.md
       ├─ skills/
       │  ├─ control-flow/
       │  ├─ planning/
       │  ├─ reviewing/
       │  ├─ implementation-design/
       │  ├─ implementation-review/
       │  ├─ implementing/
       │  ├─ worklog-update/
       │  ├─ plan-save/
       │  └─ save-docs/
       ├─ state/
       ├─ workflow/
       └─ logs/

프로젝트 로컬에서는 다음만 사용한다.

    project-root/
    ├─ CLAUDE.md                  # 전역 템플릿에서 복사/동기화
    └─ .claude/
       ├─ docs/                   # 프로젝트별 정책 전용 (전역 하니스가 쓰지 않음)
       ├─ state/
       ├─ workflow/
       └─ logs/

---

## 5. AGENTS.md / CLAUDE.md 설계 원칙

이 문서는 **하니스 본체가 아니라 진입 문서**다.

반드시 포함할 것:
- 정식 시작 경로
- `start-task` 실행 규칙
- worktree 필요 조건
- control-flow 우선 원칙
- 빠른 참조 표
- 금지 행동 목록
- hook 위반 시 기대 동작

포함하지 않을 것:
- state schema 전체
- evidence source mapping 전체
- controller의 세부 전이 규칙 전체
- 각 skill의 긴 전문 지시

즉, `AGENTS.md`는 짧고 강해야 하며, “이 문서 하나로 모든 정책을 설명”하려고 하면 안 된다.

---

## 6. 스킬/서브에이전트 간결화 정책

### 목표
모든 skill/subagent 문서를 **100줄 이내 목표**로 압축한다.

### 표준 구조
각 skill/subagent는 아래 5개 블록만 유지한다.

1. 목적
2. 해야 할 일
3. 하지 말아야 할 일
4. 출력 계약
5. 참조 문서

### 분리 원칙
아래는 skill 내부에 길게 쓰지 않는다.
- 상태기계 상세
- evidence 판정표
- 예외 케이스 전체 목록
- 정책 충돌 해설
- 테스트 시나리오 본문

이런 내용은 `docs/`로 이동한다.

### 추가 제안
`POLICY_INDEX.md` 또는 `POLICY_INDEX.json`을 별도로 둔다.

역할:
- 정책 이름
- canonical 경로
- override 가능 여부
- global / local precedence
- consumer (`controller`, `hook`, `reviewer` 등)

이 파일이 있으면 각 skill이 “무슨 문서를 참조해야 하는지”를 길게 설명할 필요가 줄어든다.

---

## 7. hook 설계 원칙

### 7-1. hook의 역할
hook은 좋은 습관을 권고하는 문서가 아니라, **정식 경로 우회를 차단하는 enforcement 계층**이다.

### 7-2. 도입 대상
우선순위가 높은 hook은 다음이다.

#### worktree guard
- 병렬/격리 작업인데 worktree 없음
- task bootstrap 없이 바로 구현 시도

#### pre-implement guard
- approved plan / implementation-design 없이 구현 단계 진입

#### pre-complete guard
- validation summary 없음
- final review 없음
- required artifacts 없음

#### policy guard
- 필수 정책 문서 미해결
- stale state인데 계속 진행
- 금지 경로 우회

### 7-3. feedback 방식
hook은 단순 실패로 끝나지 않고 아래를 남긴다.
- 위반 코드
- 위반 설명
- 수정 경로
- 권장 재실행 명령
- 관련 log ref

### 7-4. severity 체계
- `warn`: 기록만 하고 진행 허용
- `block`: 즉시 차단
- `repairable`: 차단 후 정상 경로 안내
- `auto-retry`: 차단 후 control-flow 재진입 유도

---

## 8. 로그 계층 설계

### 8-1. 결론
로그는 도입한다.  
하지만 **state를 대체하지 않는다.**

### 이유
state는 현재 상태를 한 번에 읽을 수 있는 정규화 스냅샷이다.  
logs는 시간순 append-only 기록이다.  
controller가 logs만 보고 다음 단계를 판정하면:
- 비용이 크고
- 판정이 비결정적이고
- 중간 노이즈에 취약하고
- 현재까지 만든 state/evidence 구조를 약화시킨다

따라서:
- **controller는 state를 canonical source로 사용**
- **logs는 evidence / self-feedback / audit / recovery 보조로 사용**

이 구조가 더 낫다.

### 8-2. 로그 종류
`.claude/logs/<task>/` 아래에 다음을 둔다.

- `events.ndjson`  
  단계 진입/종료, hook 발화, retry, stop reason

- `tool-usage.ndjson`  
  주요 read/write/validation/tool 호출 요약

- `validation.json`  
  테스트/빌드/린트/검증 결과 요약

- `artifacts-manifest.json`  
  생성된 artifact, state, evidence, trace 경로 목록

- `self-feedback.json`  
  hook 또는 controller가 남긴 보정 피드백

- `screenshots/`  
  웹 UI 검증 시 캡처

- `db/`  
  DB schema diff, migration 상태, 쿼리 결과 스냅샷

### 조건부 생성 원칙
웹/DB 관련 로그는 항상 강제가 아니라, **관련 작업일 때만 생성**한다.  
전역 하니스는 capture capability를 제공하되, 모든 프로젝트에 무조건 적용하지 않는다.

### 8-3. state와 log 연결
state에는 로그 전체를 넣지 않고, 필요한 ref만 넣는다.  
예:
- `last_validation_summary.ref`
- `last_hook_feedback_ref`
- `last_execution_log_ref`

즉 state는 요약, logs는 원본이다.

### 8-4. 추가 제안: recovery mode
state가 없거나 손상된 경우에만 controller가 logs를 이용해 복구용 summary를 만들 수 있도록 한다.  
단, 이건 정상 경로가 아니라 **fallback recovery**로만 둔다.

---

## 9. 로컬/전역 경계 정책

이 항목은 매우 중요하다.

### 전역 하니스가 관리하는 것
- 전역 policy docs
- 전역 skills/subagents
- bootstrap scripts
- hooks
- 템플릿 `CLAUDE.md`
- state/workflow/log runtime 구조

### 로컬 프로젝트가 관리하는 것
- 프로젝트 특화 정책 문서
- stack-specific 추가 규칙
- UI/DB/배포/도메인 정책
- 프로젝트 전용 skills/docs

### 금지 규칙
전역 하니스는 로컬 `.claude/docs`에 기본 정책 파일이나 workflow 문서를 생성하지 않는다.

이 경로는 **오직 프로젝트 특화 정책**을 위해 남겨둔다.

### override 규칙
문서 해석 우선순위는 다음과 같이 둔다.

1. 로컬 `.claude/docs/*`
2. 전역 `docs/*`

이렇게 해야 전역 골격은 유지하면서도 프로젝트별 확장이 가능하다.

---

## 10. 실행 흐름 초안

### 1단계. bootstrap
`start-task.sh` 또는 `start-task.ps1` 실행

이 스크립트는:
- task slug 생성
- worktree 준비
- `.claude/state/<task>.json` 초기화
- `.claude/workflow/<task>/...` 디렉터리 생성
- `.claude/logs/<task>/...` 디렉터리 생성
- 로컬 루트 `CLAUDE.md` 템플릿 배치/동기화
- EXEC_PLAN 또는 equivalent starter artifact 생성

### 2단계. control-flow 진입
bootstrap 결과를 기반으로 `control-flow`가 현재 state를 읽고 다음 합법 단계를 고른다.

### 3단계. specialist 실행
- planning
- reviewing
- implementation-design
- implementation-review
- implementing
- 필요 시 docs/worklog

각 단계는 control-flow가 호출한다.

### 4단계. validation
검증 script와 evaluation 기준을 적용한다.

### 5단계. completion
final review 승인과 validation 완료 후에만 완료 처리한다.

### 6단계. persistence
docs/worklog/save-docs는 별도 persistence flow로 처리한다.

이 구조는 기존 로드맵의 delivery flow와 persistence flow 분리 원칙과 일치한다.

---

## 11. 향후 병렬 확장과의 연결

이 하이브리드 구조는 병렬 확장과도 충돌하지 않는다.  
오히려 병렬 구조의 기반이 된다.

병렬 확장 시:
- `start-task`는 `start-package` 또는 lane bootstrap으로 확장
- `controller`는 중앙 controller + lane-local controller로 분화
- `state`는 program/package/lane state로 확장
- `logs`는 lane별로 분리
- hook은 lane 범위 위반과 shared contract 위반 감지에 활용

병렬 확장 로드맵도 중앙 세션과 개별 세션의 책임 분리, 병렬 적합성 판정, lane state persistence, parallel evaluation harness를 요구하므로, 지금 구조를 얇은 진입 문서 + 강제 계층 + 상태기반 orchestration으로 정리하는 것이 선행 조건에 맞다.

---

## 12. 단계별 추진 계획

### 마일스톤 1. Entry / Enforcement Layer 도입
- `AGENTS.md` 작성
- `templates/CLAUDE.md` 작성
- `start-task.sh`, `start-task.ps1` 작성
- 최소 hook 2개 도입
- `.claude/logs/` 구조 도입

완료 기준:
- 모든 작업의 정식 시작 경로가 문서/스크립트로 보임
- 전역 하니스가 로컬 `.claude/docs`를 건드리지 않음
- worktree / bootstrap 없는 직접 구현 경로를 차단할 수 있음

### 마일스톤 2. Skill/Subagent Slimming
- planning/reviewing 등 기존 skill 정리
- 각 문서를 100줄 이내 목표로 압축
- 세부 규칙은 docs로 이동
- `POLICY_INDEX` 추가

완료 기준:
- skill/subagent 문서가 짧고 일관됨
- 중복 정책 서술이 줄어듦

### 마일스톤 3. State + Logs 연결
- controller가 state를 canonical source로 유지
- logs ref를 state에 연결
- hook feedback과 validation 결과를 logs에 남김
- recovery mode 초안 작성

완료 기준:
- state는 요약 스냅샷, logs는 과정 증거로 역할 분리
- self-feedback 기반 재진입이 가능

### 마일스톤 4. Evaluation 보강
- hook 위반, bootstrap 우회, worktree 위반, validation 누락 시나리오 추가
- 기존 happy path / Q1 / Q2 / Q3 검증 유지

완료 기준:
- 문서뿐 아니라 enforcement 계층도 회귀 검증 가능

### 마일스톤 5. 병렬 확장 준비
- 중앙/개별 세션 책임 분리 문서 초안
- lane bootstrap 규칙 초안
- package state/log 구조 초안

완료 기준:
- 단일 하니스 위에 병렬 확장 설계를 얹을 준비 완료

---

## 13. 최종 권고

이 초안의 핵심은 세 가지다.

1. **기존 orchestration 구조는 유지한다.**  
   `control-flow`, `controller`, `planning`, `reviewing`, `implementation-design`, `implementation-review`, `implementing`은 그대로 간다.

2. **전문가 하니스의 강점은 상단 계층으로 흡수한다.**  
   `AGENTS/CLAUDE 진입 문서`, `bootstrap script`, `hook enforcement`, `빠른 참조`, `append-only logs`를 추가한다.

3. **logs는 state를 대체하지 않는다.**  
   state는 canonical snapshot, logs는 evidence trail이다.

이 방향이 현재 로드맵의 controller/state/evaluation 목표를 훼손하지 않으면서, 다른 하니스의 운영 강제력과 사용성을 가장 현실적으로 흡수하는 방법이다.

이 초안은 Claude에게 전역 하니스 수정 지시를 내릴 때 바로 기준 문서로 써도 무방하다.