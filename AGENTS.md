# Global Harness — Agent Entry Point

## 정식 시작 경로

모든 작업은 아래 순서로 시작한다.

1. `start-task` 실행으로 task 환경 초기화
2. `/control-flow` 호출로 orchestration 진입

직접 planning/build에 들어가지 않는다.

---

## start-task 실행 규칙

```bash
# Unix/Mac
bash scripts/start-task.sh <task-slug> [project-root]

# Windows
scripts\start-task.ps1 -TaskSlug <task-slug> [-ProjectRoot <path>]
```

- `task-slug`: 소문자, 하이픈 구분 (예: `user-auth-refactor`)
- `project-root`: 생략 시 현재 디렉터리 사용
- 실행 후 `.claude/state/<slug>.json`, `.claude/workflow/<slug>/`, `.claude/logs/<slug>/` 생성됨

---

## control-flow 우선 원칙

- 작업 시작 후 다음 단계는 항상 `controller`가 결정한다.
- `controller`가 `continue: false`를 반환할 때까지 orchestration은 멈추지 않는다.
- human gate 또는 approval 없이 단계를 건너뛰지 않는다.

---

## 역할 구조

| 역할 | 파일 | 담당 |
|------|------|------|
| Controller | `agents/controller.md` | state 판정, 다음 단계 결정 |
| PO | `agents/po.md` | planning, build, bounded revision 생산 |
| Reviewer | `agents/reviewer.md` | plan review, result review, final review |

---

## worktree 필요 조건

아래 경우에는 반드시 git worktree를 먼저 생성한다.

- 병렬 또는 격리된 feature 작업
- 메인 브랜치에 영향을 줄 수 있는 구현

worktree 없이 격리 작업을 시작하면 `worktree-guard` hook이 차단한다.

---

## 빠른 참조

| 목적 | 위치 |
|------|------|
| 상태 기계 규칙 | `docs/WORKFLOW_STATE_MACHINE.md` |
| state schema | `docs/STATE_SCHEMA.md` |
| control contract | `docs/CONTROL_CONTRACT.md` |
| harness 원칙 | `docs/HARNESS_PRINCIPLES.md` |
| harness 범위 | `docs/HARNESS_SCOPE.md` |
| self-refine 정책 | `docs/SELF_REFINE_POLICY.md` |
| bootstrap 스크립트 | `scripts/` |
| guardrail hooks | `hooks/` |
| 로컬 프로젝트 템플릿 | `templates/CLAUDE.md` |

---

## 금지 행동

- `start-task` 없이 바로 `/control-flow` 호출 (state skeleton 없음)
- approved plan 없이 build 단계 진입
- final review 없이 완료 처리
- worktree 없이 격리 작업 시작
- 로컬 `.claude/docs/`에 전역 정책 문서 생성
- sibling repository 읽기
- 전역 하니스 skill/agent를 직접 수정해 로컬 정책 반영

---

## hook 위반 시 기대 동작

각 hook은 위반 시 아래를 출력한다.

```
[VIOLATION] <violation-code>
설명: <위반 설명>
수정 경로: <해결 방법>
권장 명령: <재실행 명령>
로그 ref: .claude/logs/<task>/events.ndjson
```

severity별 동작:
- `warn`: 기록 후 계속 허용
- `block`: 즉시 차단, 수정 경로 안내
- `repairable`: 차단 후 정상 경로 안내
- `auto-retry`: 차단 후 control-flow 재진입 유도

---

## 로컬 / 전역 경계

- 전역 하니스: `docs/`, `skills/`, `agents/`, `scripts/`, `hooks/` 관리
- 로컬 프로젝트: `.claude/docs/`에 프로젝트 특화 정책만 추가
- 전역 하니스는 로컬 `.claude/docs/`에 파일을 쓰지 않는다

override 우선순위:
1. 로컬 `.claude/docs/*`
2. 전역 `docs/*`
