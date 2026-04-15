#!/usr/bin/env bash
# worktree-guard.sh — 병렬/격리 작업 시 worktree 존재 여부 확인
#
# severity: block
#
# 감지 대상:
#   - 병렬 또는 격리 작업인데 git worktree가 없음
#   - 메인 브랜치에서 직접 격리 작업 시작
#
# Claude Code settings.json 등록 예시:
#   "hooks": {
#     "PreToolUse": [{ "matcher": "Edit|Write|Bash", "hooks": [{ "type": "command", "command": "bash /path/to/hooks/worktree-guard.sh" }] }]
#   }
#
# 입력: 환경 변수 또는 stdin (Claude Code hook 규격에 따름)

set -euo pipefail

PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-$(pwd)}"
TASK_SLUG="${CLAUDE_TASK_SLUG:-}"

# worktree 목록 확인
WORKTREES="$(git -C "$PROJECT_ROOT" worktree list 2>/dev/null || echo "")"
WORKTREE_COUNT="$(echo "$WORKTREES" | grep -c "^\S" || true)"

# 현재 브랜치
CURRENT_BRANCH="$(git -C "$PROJECT_ROOT" branch --show-current 2>/dev/null || echo "unknown")"
MAIN_BRANCHES=("main" "master" "develop")

IS_MAIN_BRANCH=false
for branch in "${MAIN_BRANCHES[@]}"; do
  if [[ "$CURRENT_BRANCH" == "$branch" ]]; then
    IS_MAIN_BRANCH=true
    break
  fi
done

# --- 판정 ---

# worktree가 1개뿐(= 현재 디렉터리만)이고 메인 브랜치에서 작업 중이면 경고
if [[ "$WORKTREE_COUNT" -le 1 ]] && [[ "$IS_MAIN_BRANCH" == "true" ]]; then
  echo ""
  echo "[VIOLATION] WORKTREE_MISSING"
  echo "  설명    : 격리된 feature 작업에 git worktree가 없습니다."
  echo "            현재 브랜치: $CURRENT_BRANCH"
  echo "  수정 경로: git worktree add ../<task-slug> -b feature/<task-slug>"
  if [[ -n "$TASK_SLUG" ]]; then
    echo "  권장 명령: git worktree add ../$TASK_SLUG -b feature/$TASK_SLUG"
  fi
  echo "  로그 ref : .claude/logs/${TASK_SLUG:-unknown}/events.ndjson"
  # severity: warn (메인에서 작업한다고 반드시 차단하지는 않음, 기록만)
  # 차단하려면 exit 1로 변경
  exit 0
fi

exit 0
