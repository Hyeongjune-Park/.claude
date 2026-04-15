# 전역 하니스 통합 계획서 v3  
## Controller + PO + Reviewer 구조 재편안

## 1. 문서 목적

이 계획서는 현재 구축 중인 전역 하니스의 핵심 제어 구조를 유지하면서, 생산 계층을 더 단순하고 강한 형태로 재편하기 위한 계획서다.

기존 구조는 planning, implementation-design, implementing 등 생산 관련 역할이 여러 단계로 나뉘어 있었다. 이 구조는 통제에는 유리하지만, AI에게는 역할 간 handoff가 오히려 컨텍스트 손실과 정보 왜곡을 만들 수 있다.

따라서 v3의 목적은 다음과 같다.

- **상태기반 제어 코어는 유지**
- **생산 계층은 PO 중심으로 단순화**
- **리뷰는 독립 축으로 유지**
- **운영 셸은 계속 강화**
- **병렬 확장은 이 구조 위에서 준비**

이 문서는 하니스를 “많이 나뉜 specialist 집합”에서 “적게 나뉘되 더 강하게 통제되는 구조”로 재정의한다.

---

## 2. 핵심 결론

새 구조의 핵심은 다음 한 문장으로 정리된다.

**“하니스는 Controller + PO + Reviewer의 3축으로 재편하고, state-authoritative orchestration은 그대로 유지한다.”**

즉,

- `controller`는 계속 흐름만 제어한다
- `PO`는 planning, design, implementation, local adjustment를 한 축으로 담당한다
- `reviewer`는 plan과 result에 대해 독립적으로 비판한다

기존의 planner / implementation-designer / implementer를 각각 별도 specialist로 유지하지 않는다.  
대신 **PO가 하나의 긴 컨텍스트를 유지한 채 생산을 담당**한다.

이 구조의 장점은 다음과 같다.

- handoff 감소
- 맥락 보존 강화
- 산출물 책임 주체 명확화
- workflow specialist 과분화 완화
- UI/UX와 코드, 설계 판단의 단일 맥락 유지

단, 이 단순화는 **controller 제거를 의미하지 않는다.**  
하니스는 여전히 controller 중심의 상태기반 제어 시스템이다.

---

## 3. v3에서 유지할 핵심 가치

### 3-1. state-authoritative orchestration 유지

다음 단계 판정의 기준은 계속 state다.

- controller는 `.claude/state/*`를 canonical source로 사용
- logs는 보조 증거 계층일 뿐 state를 대체하지 않음
- artifacts는 state 판단을 보조하는 입력
- 자유서술은 최후 수단

### 3-2. evidence trail 유지

review는 단순 의견이 아니라,  
무엇을 읽고 어떤 근거로 판단했는지가 남아야 한다.

- read ledger
- read trace
- artifact ref
- validation summary ref

이 구조는 reviewer 신뢰성을 지키기 위한 핵심이다.

### 3-3. human gate 유지

다음은 계속 human gate 대상이다.

- scope ambiguity가 큰 경우
- architecture freeze가 필요한 경우
- stale approval 재사용 여부
- 병렬 적합성 승인
- merge 전 최종 통합 승인
- failure tolerance 정책 결정

### 3-4. bounded self-refactor 유지

자동 수정은 계속 제한적으로만 허용한다.

- 승인된 범위 안의 명확한 delta만 허용
- 최대 1회
- unrelated cleanup 금지
- scope expansion 감지 시 즉시 stop

### 3-5. delivery / persistence 분리 유지

코드 delivery와 docs persistence는 계속 별도 흐름으로 둔다.

- 구현 완료 ≠ docs save 자동 강제
- worklog / plan-save / save-docs는 정책 기반 선택 흐름
- persistence는 completion과 분리된 후속 단계

---

## 4. 새 역할 구조

## 4-1. Controller

### 역할
- 현재 state 판정
- 다음 합법 단계 선택
- stop / continue / stale / blocked 판정
- specialist 호출
- approval invalidation 처리
- logs / validation summary ref 연결
- persistence flow 진입 여부 판단

### 하지 말아야 할 일
- plan을 직접 생산하지 않음
- 설계를 대신 작성하지 않음
- 코드를 직접 구현하지 않음
- 리뷰 결론을 대신 꾸며내지 않음

### 핵심 원칙
**control-only**

---

## 4-2. PO

### 역할
PO는 기존의 아래 역할을 통합한다.

- planner
- implementation-designer
- implementer

### 책임 범위
- 요구사항 해석
- feature-level plan 작성
- spec / acceptance 초안 생성
- implementation design
- 실제 코드 및 문서 산출물 생산
- reviewer 피드백 반영
- local validation 대응
- 필요 시 bounded self-adjustment 수행

### 장점
- 처음부터 끝까지 동일 맥락 유지
- “왜 이 설계를 택했는가”가 중간에 끊기지 않음
- UI/UX 판단과 코드 판단이 분리되지 않음
- 작은/중간 규모 feature 작업에서 효율적

### 제한
- 다음 단계 승인 권한 없음
- 자기 plan을 self-approve하지 않음
- global complete를 주장하지 않음
- 병렬 상황에서는 lane 범위 밖 수정 금지

---

## 4-3. Reviewer

### 역할
Reviewer는 독립 검토 축이다.

### 검토 시점
1. **Plan Review**
   - PO가 만든 spec / plan / acceptance 초안 검토
   - scope drift, hidden assumption, missing acceptance, risk 체크

2. **Result Review**
   - PO가 만든 결과물 검토
   - 구현 정합성, UX 품질, evidence 충분성, validation completeness 체크

### 하지 말아야 할 일
- plan을 대신 작성하지 않음
- 구현을 대신 수행하지 않음
- state를 직접 변경하지 않음
- controller 역할을 대체하지 않음

### 필요 시 확장 가능
나중에 아래 역할은 reviewer 계층의 확장으로 붙일 수 있다.

- validator
- tester
- security reviewer

단, 이들은 controller와 동급이 아니라 reviewer 보조 또는 별도 validation specialist로 둔다.

---

## 5. 새 구조의 계층 설계

## 5-1. Entry Layer
- `AGENTS.md`
- `templates/CLAUDE.md`

역할:
- 정식 시작 경로 안내
- `start-task` 규칙 안내
- control-flow 우선 원칙 요약
- hook 위반 시 기대 동작 안내
- 빠른 참조 표 제공

---

## 5-2. Policy Layer
- `HARNESS_SCOPE.md`
- `HARNESS_PRINCIPLES.md`
- `CONTROL_CONTRACT.md`
- `WORKFLOW_STATE_MACHINE.md`
- `STATE_SCHEMA.md`
- `SELF_REFINE_POLICY.md`
- `HARNESS_EVALUATION_PLAN.md`
- `PERSISTENCE_POLICY.md`
- `HARNESS_CHANGE_POLICY.md`
- `HARNESS_VERSIONING.md`

역할:
- canonical control semantics 정의
- stop / gate / stale / retry / completion 규칙 고정
- controller, reviewer, hook이 참조할 기준 제공

---

## 5-3. Orchestration Layer
- `.claude/agents/controller.md`
- `.claude/skills/control-flow/SKILL.md`

역할:
- 현재 state 판정
- 다음 합법 단계 선택
- PO / reviewer 호출
- stop / continue / retry / reroute 판단
- artifact 저장 이후 state 갱신

---

## 5-4. Production Layer
- `.claude/agents/po.md`
- `.claude/skills/po/SKILL.md`

역할:
- spec / plan / acceptance / implementation / local fixes 생산
- feature 문맥 유지
- reviewer 피드백 반영

### PO 내부 하위 모드
PO 내부적으로는 아래 모드를 가질 수 있다.

- plan mode
- design mode
- implementation mode
- revise mode

하지만 외부적으로는 **하나의 PO role**로 보이게 한다.

즉, 과거의 `planning`, `implementation-design`, `implementing`을 별도 specialist로 노출하지 않는다.

---

## 5-5. Review Layer
- `.claude/agents/reviewer.md`
- `.claude/skills/reviewing/SKILL.md`

역할:
- PO 산출물 검토
- plan review / result review 수행
- verdict와 revision delta 제시
- evidence sufficiency 판단

---

## 5-6. Bootstrap / Enforcement Layer
- `scripts/start-task.sh`
- `scripts/start-task.ps1`
- `scripts/validate-task.sh`
- `scripts/validate-task.ps1`
- hooks

역할:
- task 초기화
- state / workflow / logs skeleton 생성
- 로컬 `CLAUDE.md` 템플릿 배치
- 정식 경로 우회 차단
- policy violation 감지
- validation gate 강제

---

## 5-7. Runtime Data Layer
- `.claude/state/`
- `.claude/workflow/`
- `.claude/logs/`

역할:
- 현재 상태 스냅샷
- artifact / evidence / trace 저장
- validation / hook / stop reason 로그 축적

---

## 6. 새 워크플로 구조

기존:
- planning
- reviewing
- implementation-design
- implementation-review
- implementing
- final-review

v3:
- planning_pending
- plan_ready_for_review
- build_pending
- build_ready_for_review
- validation_pending
- final_review_pending
- completed

단, 내부 의미는 다음처럼 재해석한다.

### 단계 1. planning_pending
- controller가 PO를 호출
- PO가 다음을 작성
  - `spec.md`
  - `plan.md`
  - `acceptance.md` 초안
  - 필요 시 `research.md`

### 단계 2. plan_ready_for_review
- reviewer가 plan review 수행
- verdict:
  - approved
  - rejected
  - approved_with_revisions

### 단계 3. build_pending
- 승인된 plan 기준으로 PO가 design + implementation 수행
- 필요 시 spec refinement는 가능하지만 scope_fingerprint 변경 금지
- scope가 바뀌면 stale 처리 후 stop

### 단계 4. build_ready_for_review
- reviewer가 result review 수행
- UI/UX / behavior / code / artifact completeness 검토
- 필요 시 bounded revision 요청

### 단계 5. validation_pending
- validation script 실행
- acceptance 기준 충족 여부 확인
- validation summary 저장
- controller가 completion 가능 여부 판정

### 단계 6. final_review_pending
- 최종 승인
- persistence flow 진입 여부 판단

### 단계 7. completed
- 코드 작업 완료
- 필요 시 persistence flow 별도 진행

---

## 7. Artifact 구조 재정의

feature 단위 기본 artifact는 다음으로 정리한다.

- `spec.md`
- `plan.md`
- `acceptance.md`
- `review-plan.md`
- `build-summary.md`
- `review-result.md`
- `validation-summary.json`

필요 시:
- `research.md`
- `worklog.md`
- `save-docs.md`

### 핵심 원칙
- spec와 acceptance는 plan 단계의 정식 artifact다
- result review는 build 결과를 기준으로 수행한다
- validation은 acceptance를 기준으로만 판정한다
- reviewer가 새로운 요구사항을 발명하면 안 된다

---

## 8. Acceptance와 Test RED 정책

v3에서는 Test RED를 무조건 먼저 두지 않는다.  
다음 순서를 따른다.

1. spec / plan / acceptance 초안 생성
2. reviewer가 acceptance 적절성 검토
3. acceptance freeze
4. 그 다음에만 test scaffold 또는 validation script 작성 허용

즉:

**acceptance 없는 test-first는 금지**  
**acceptance freeze 이후의 test-first는 허용**

초기에는 tester를 별도 agent로 두지 않고,
- `validate-task.*`
- validation summary schema
- acceptance linkage
를 먼저 구축한다.

tester 추가는 이후 단계에서 검토한다.

---

## 9. Skill / Agent 문서 구조 재편

### 유지 대상
- `controller`
- `po`
- `reviewer`
- `control-flow`
- `reviewing`
- `po`
- 필요 시 `worklog-update`, `plan-save`, `save-docs`

### 정리 대상
아래는 외부 specialist로서 폐기 또는 흡수한다.
- `planner`
- `implementation-designer`
- `implementer`

### 문서 구조 원칙
각 agent/skill 문서는 아래 5개 블록만 유지한다.

1. 목적
2. 해야 할 일
3. 하지 말아야 할 일
4. 출력 계약
5. 참조 문서

### 분리 원칙
다음은 전부 `docs/`로 이동한다.
- 상태기계 상세
- evidence 판정표
- stale invalidation 해설
- 예외 케이스 모음
- 평가 시나리오 본문

---

## 10. Hook / Enforcement 정책

우선순위 높은 hook은 아래처럼 재정의한다.

### 10-1. pre-po guard
차단 조건:
- bootstrap 없이 바로 생산 시작
- planning artifact 없이 build 단계 진입

### 10-2. pre-review guard
차단 조건:
- review 대상 artifact 없음
- read ledger / trace 누락
- stale scope에서 review 강행

### 10-3. pre-complete guard
차단 조건:
- validation summary 없음
- final review 없음
- required artifact 누락

### 10-4. policy guard
차단 조건:
- stale state 지속 사용
- human gate required 무시
- 금지 경로 직접 쓰기
- 로컬 `.claude/docs` 오염 시도

### feedback 원칙
모든 hook은 아래를 남긴다.
- 위반 코드
- 위반 설명
- 수정 경로
- 권장 재실행 명령
- log ref

---

## 11. State / Logs 연결 구조

### state
- 현재 단계
- 현재 feature slug
- scope_fingerprint
- latest accepted artifact ref
- pending review 여부
- stale 여부
- human gate 여부
- last validation summary ref
- last hook feedback ref

### logs
- `events.ndjson`
- `tool-usage.ndjson`
- `validation.json`
- `artifacts-manifest.json`
- `self-feedback.json`

### 원칙
- controller는 state만으로 다음 단계를 판정 가능해야 한다
- logs는 recovery / audit / debugging / evidence 보조용이다
- logs 기반 next-step 판정은 금지

---

## 12. 병렬 확장과의 관계

v3는 병렬 로드맵을 버리지 않는다.  
오히려 병렬 확장의 **lane 내부 실행 단위**를 더 단순하게 만든다.

### 병렬 확장 시 구조
- 중앙: `controller`
- lane 내부 생산: `PO`
- lane 내부 검토: `reviewer`

즉, 병렬화되더라도 각 lane는 별도 planner/designer/implementer를 두지 않고,  
**lane별 PO + reviewer** 구조로 굴린다.

중앙 세션 책임은 유지한다.

- 전역 범위 정의
- shared contract 확정
- work package 분해
- lane brief 생성
- 결과 통합
- 충돌 판정
- reroute / final decision

### 병렬 금지 조건
다음은 유지한다.
- 공통 계약 미확정
- 대부분의 세션이 같은 파일 수정
- 대규모 refactor
- global test 하나에만 의존
- 하나의 설계 선택에 전체가 종속

즉, PO 구조는 병렬성의 대체물이 아니라 **lane 내부 단순화 도구**다.

---

## 13. 단계별 추진 계획

## 마일스톤 1. Specialist 구조 재편
포함:
- `planner`, `implementation-designer`, `implementer` 역할 정리
- `po.md` 초안 작성
- `po/SKILL.md` 초안 작성
- 기존 production skill의 참조 경로 정리

완료 기준:
- 생산 계층이 `PO` 단일 role로 설명 가능
- controller / reviewer와 책임 경계가 명확
- 기존 문서 중 역할 중복이 제거됨

---

## 마일스톤 2. Workflow 재정의
포함:
- state machine 단계명 재정리
- `planning_pending → plan_ready_for_review → build_pending → build_ready_for_review → validation_pending → final_review_pending → completed`
- artifact naming 규칙 재정리
- acceptance artifact 정규화

완료 기준:
- controller가 새 state 구조로 단계 판정 가능
- reviewer가 plan review와 result review를 분리 수행 가능

---

## 마일스톤 3. Operational Shell 유지 및 보강
포함:
- `AGENTS.md`
- `templates/CLAUDE.md`
- bootstrap script
- hook 2~4개 도입
- logs 구조 유지

완료 기준:
- PO 구조로 바뀌어도 정식 진입 경로와 enforcement 계층이 유지됨
- bootstrap 우회와 validation 없는 completion이 차단됨

---

## 마일스톤 4. Validation Hardening
포함:
- `acceptance.md` 규격 강화
- `validate-task.*` 정리
- validation summary schema 확정
- acceptance freeze 규칙 문서화

완료 기준:
- 결과 완료 판정이 reviewer 의견만이 아니라 validation summary에도 연결됨
- test-first는 acceptance 이후만 허용됨

---

## 마일스톤 5. Evaluation Harness 업데이트
포함:
- PO 구조 기준 happy path
- plan rejection
- result rejection
- stale approval
- human gate
- bootstrap bypass
- validation missing
- bounded self-refine 1회 성공 / 실패

완료 기준:
- 기존 평가 체계가 새 역할 구조에서도 회귀 가능
- “전문 specialist 축소 후에도 통제력이 유지되는가”를 검증 가능

---

## 마일스톤 6. Parallel Readiness
포함:
- lane brief 템플릿 재정리
- lane 내부 역할을 PO + reviewer로 표준화
- integration controller 문서와 연결
- package state 확장 설계 반영

완료 기준:
- 병렬 세션에서도 역할 분해가 과도해지지 않음
- 중앙 controller와 lane-local 생산 구조의 경계가 명확

---

## 14. 도입 금지 항목

다음은 당분간 도입하지 않는다.

- controller 제거
- reviewer에게 state 판정 권한 부여
- PO self-approval 허용
- logs 기반 next-step 판정
- planner / designer / implementer 분할 복귀
- annotator 도입
- multi-platform abstraction
- full parallel worktree execution
- security specialist 조기 도입

---

## 15. 최종 판단

v3의 핵심은 단순하다.

**생산은 덜 쪼개고, 제어는 더 명확히 한다.**

즉,
- 사람 팀처럼 많은 역할로 나누는 방식은 생산 계층에서 줄인다
- 대신 controller가 다음 단계와 stop 조건을 더 강하게 잡는다
- reviewer는 독립된 비판 축으로 남긴다

이렇게 하면,
- handoff 비용은 줄고
- 맥락은 더 길게 유지되며
- 기존 하니스의 강점인 state machine, evidence trail, human gate는 그대로 남는다

이 구조는 현재 하니스의 control-first 철학과 충돌하지 않는다.  
오히려 그 철학을 유지한 채 생산 계층만 AI 친화적으로 단순화하는 방향이다.