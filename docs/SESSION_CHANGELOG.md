# SESSION_CHANGELOG

## 2026-04-16 세션 변경 정리

### 1) 세션 목표
- 하니스를 `lean` 기본 모드로 재배치해 토큰 사용량을 줄이면서, `strict` 모드의 안전 장치를 유지한다.
- 용어 통일성과 단계 연결성을 맞춰 문서-스크립트-에이전트 간 불일치를 줄인다.

### 2) 반영 커밋
1. `4a6adb1` - Add lean execution mode baseline and mode-aware validation
2. `463e27a` - Add lean/strict branching to controller and control-flow guidance
3. `7cd12b0` - Align lean/strict docs and enforce strict completed final review gate

### 3) 핵심 변경사항

### 실행 모드 구조
- `lean`을 기본 실행 모드로 명시하고 `strict`는 고위험 작업 중심의 선택 경로로 정리했다.
- 모드 누락 또는 비정상 값은 안전하게 `strict` fallback 하도록 유지했다.
- 모드 정책 문서를 신설/보강해 진입 기준, 최소 artifact, warning/block 기준을 명시했다.

### 상태/스키마 정합성
- `STATE_SCHEMA`에 `artifacts.review`를 필수 키로 반영했다.
- 구형 state 정규화 규칙에 `artifacts.review` 누락 시 `null` 보정 규칙을 추가했다.
- `start-task`가 생성하는 초기 state를 schema v8 요구 필드에 맞게 확장했다.

### 워크플로우/단계 연결성
- lean 경로의 review 단계를 문서/역할 정의에 반영했다.
- `SELF_REFINE_POLICY`에 lean `review` 단계의 `approved_with_revisions -> build` 재수행 규칙을 추가했다.
- 평가 시나리오를 lean/strict 기준으로 분리해 happy path와 rejection path를 명확히 했다.

### validation 게이트
- `validate-task`를 모드 인식 방식으로 정리했다.
- strict 모드에서 `validation_pending`/`final_review_pending`에는 `review-final.md`를 요구하지 않도록 했다.
- strict 모드에서 `completed` 상태일 때는 `review-final.md`를 필수로 요구하도록 보강했다.

### 에이전트/스킬 정렬
- controller와 control-flow에서 lean/strict 분기 규칙을 명시했다.
- reviewer 역할 정의에 lean 단일 review를 포함해 용어 충돌을 해소했다.
- PO/reviewer/control-flow 스킬 문구를 lean 기본 흐름에 맞게 정렬했다.

### 4) 변경 파일 범위
- 문서: `AGENTS.md`, `docs/CONTROL_CONTRACT.md`, `docs/HARNESS_EVALUATION_PLAN.md`, `docs/HARNESS_EXECUTION_MODES.md`, `docs/HARNESS_PRINCIPLES.md`, `docs/HARNESS_SCOPE.md`, `docs/SELF_REFINE_POLICY.md`, `docs/STATE_SCHEMA.md`, `docs/WORKFLOW_STATE_MACHINE.md`
- 에이전트/스킬: `agents/controller.md`, `agents/po.md`, `agents/reviewer.md`, `skills/control-flow/SKILL.md`, `skills/po/SKILL.md`, `skills/reviewing/SKILL.md`
- 스크립트: `scripts/start-task.ps1`, `scripts/start-task.sh`, `scripts/validate-task.ps1`, `scripts/validate-task.sh`

### 5) 검증 결과
- PowerShell 스모크 기준:
1. lean `completed` 검증 통과
2. strict `final_review_pending` 검증 통과
3. strict `completed` + `review-final.md` 누락 시 검증 실패 확인
4. strict `completed` + `review-final.md` 존재 시 검증 통과
- 참고: 현재 실행 환경에서 `bash` 바이너리가 없어 `.sh` 런타임 검증은 수행하지 못했다.

### 6) 현재 상태
- 작업 브랜치: `develop`
- 원격 반영: `origin/develop` 푸시 완료
- 세션 산출물은 lean 기본 운영을 중심으로 문서/제어/검증 경로를 일치시키는 데 초점을 맞췄다.
