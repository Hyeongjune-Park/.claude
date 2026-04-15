#!/usr/bin/env bash
# start-task.sh — task bootstrap script
# 사용법: bash scripts/start-task.sh <task-slug> [project-root]
#
# 역할:
#   - task slug 유효성 검사
#   - .claude/state/<slug>.json skeleton 초기화
#   - .claude/workflow/<slug>/ 디렉터리 구조 생성
#   - .claude/logs/<slug>/ 디렉터리 구조 생성
#   - 로컬 CLAUDE.md 템플릿 배치 (없을 때만)

set -euo pipefail

TASK_SLUG="${1:-}"
PROJECT_ROOT="${2:-$(pwd)}"

# --- 입력 검증 ---

if [[ -z "$TASK_SLUG" ]]; then
  echo "[ERROR] task-slug가 필요합니다."
  echo "사용법: bash scripts/start-task.sh <task-slug> [project-root]"
  exit 1
fi

if [[ ! "$TASK_SLUG" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
  echo "[ERROR] task-slug는 소문자, 숫자, 하이픈만 허용합니다. (예: user-auth-refactor)"
  exit 1
fi

if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "[ERROR] project-root가 존재하지 않습니다: $PROJECT_ROOT"
  exit 1
fi

CLAUDE_DIR="$PROJECT_ROOT/.claude"
STATE_FILE="$CLAUDE_DIR/state/${TASK_SLUG}.json"
WORKFLOW_DIR="$CLAUDE_DIR/workflow/${TASK_SLUG}"
LOGS_DIR="$CLAUDE_DIR/logs/${TASK_SLUG}"

echo "[start-task] task: $TASK_SLUG"
echo "[start-task] root: $PROJECT_ROOT"

# --- 이미 존재하면 경고 ---

if [[ -f "$STATE_FILE" ]]; then
  echo "[WARN] state 파일이 이미 존재합니다: $STATE_FILE"
  echo "       기존 state를 유지하고 디렉터리 구조만 보완합니다."
fi

# --- 디렉터리 생성 ---

mkdir -p \
  "$CLAUDE_DIR/state" \
  "$WORKFLOW_DIR/artifacts/history" \
  "$WORKFLOW_DIR/contracts" \
  "$WORKFLOW_DIR/evidence" \
  "$LOGS_DIR"

echo "[start-task] 디렉터리 생성 완료"

# --- state skeleton 초기화 (없을 때만) ---

if [[ ! -f "$STATE_FILE" ]]; then
  CREATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  cat > "$STATE_FILE" <<EOF
{
  "feature_slug": "$TASK_SLUG",
  "current_state": "planning_pending",
  "state_classification": "fresh_start",
  "last_transition": {
    "trigger": "state_initialized",
    "at": "$CREATED_AT"
  },
  "accepted_artifacts": {},
  "revision_request": null,
  "blocker_present": false,
  "logs_ref": ".claude/logs/$TASK_SLUG"
}
EOF
  echo "[start-task] state skeleton 생성: $STATE_FILE"
else
  echo "[start-task] 기존 state 유지: $STATE_FILE"
fi

# --- 로컬 CLAUDE.md 템플릿 배치 (없을 때만) ---

LOCAL_CLAUDE="$PROJECT_ROOT/CLAUDE.md"
HARNESS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$HARNESS_ROOT/templates/CLAUDE.md"

if [[ ! -f "$LOCAL_CLAUDE" ]] && [[ -f "$TEMPLATE" ]]; then
  cp "$TEMPLATE" "$LOCAL_CLAUDE"
  echo "[start-task] CLAUDE.md 템플릿 배치: $LOCAL_CLAUDE"
elif [[ -f "$LOCAL_CLAUDE" ]]; then
  echo "[start-task] 기존 CLAUDE.md 유지: $LOCAL_CLAUDE"
else
  echo "[WARN] 템플릿을 찾을 수 없습니다: $TEMPLATE"
fi

# --- 완료 ---

echo ""
echo "[start-task] 완료."
echo "  state : $STATE_FILE"
echo "  workflow: $WORKFLOW_DIR/"
echo "  logs  : $LOGS_DIR/"
echo ""
echo "다음 단계: /control-flow 호출"
