#!/usr/bin/env bash
# pre-implement-check.sh — 구현 단계 진입 전 사전 조건 검증
#
# severity: block
#
# 감지 대상:
#   - approved plan artifact 없이 build 단계 진입 시도
#   - state가 build_pending이 아닌데 구현 파일 직접 수정
#   - stale 또는 blocked state에서 강행 시도
#
# Claude Code settings.json 등록 예시:
#   "hooks": {
#     "PreToolUse": [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "bash /path/to/hooks/pre-implement-check.sh" }] }]
#   }

set -euo pipefail

PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-$(pwd)}"
TASK_SLUG="${CLAUDE_TASK_SLUG:-}"

if [[ -z "$TASK_SLUG" ]]; then
  # task slug 없으면 판정 불가 → 통과
  exit 0
fi

STATE_FILE="$PROJECT_ROOT/.claude/state/${TASK_SLUG}.json"
WORKFLOW_DIR="$PROJECT_ROOT/.claude/workflow/${TASK_SLUG}"

# --- state 파일 확인 ---

if [[ ! -f "$STATE_FILE" ]]; then
  echo ""
  echo "[VIOLATION] IMPLEMENT_WITHOUT_BOOTSTRAP"
  echo "  설명    : state 파일이 없습니다. start-task 없이 구현을 시도하고 있습니다."
  echo "  수정 경로: 먼저 start-task를 실행하고 /control-flow로 planning 단계를 완료하세요."
  echo "  권장 명령: bash scripts/start-task.sh $TASK_SLUG $PROJECT_ROOT"
  echo "  로그 ref : .claude/logs/${TASK_SLUG}/events.ndjson"
  exit 1
fi

# --- workflow_state 확인 ---

WORKFLOW_STATE="$(grep -o '"workflow_state": *"[^"]*"' "$STATE_FILE" | head -1 | sed 's/.*: *"//' | tr -d '"')"

ALLOWED_STATES=("build_pending")

STATE_ALLOWED=false
for allowed in "${ALLOWED_STATES[@]}"; do
  if [[ "$WORKFLOW_STATE" == "$allowed" ]]; then
    STATE_ALLOWED=true
    break
  fi
done

if [[ "$STATE_ALLOWED" == "false" ]]; then
  echo ""
  echo "[VIOLATION] IMPLEMENT_STATE_INVALID"
  echo "  설명    : 현재 state($WORKFLOW_STATE)에서 구현을 시작할 수 없습니다."
  echo "            구현은 build_pending 상태에서만 허용됩니다."
  echo "  수정 경로: /control-flow 를 실행해 합법 전이를 통해 build 단계에 진입하세요."
  echo "  권장 명령: /control-flow"
  echo "  로그 ref : .claude/logs/${TASK_SLUG}/events.ndjson"
  exit 1
fi

# --- approved plan 확인 ---

PLAN_ARTIFACT="$WORKFLOW_DIR/artifacts/plan.md"
REVIEW_ARTIFACT="$WORKFLOW_DIR/artifacts/review-plan.md"

if [[ ! -f "$PLAN_ARTIFACT" ]]; then
  echo ""
  echo "[VIOLATION] IMPLEMENT_WITHOUT_PLAN"
  echo "  설명    : approved plan artifact가 없습니다."
  echo "  수정 경로: /control-flow 로 planning → plan_review 단계를 먼저 완료하세요."
  echo "  권장 명령: /control-flow"
  echo "  로그 ref : .claude/logs/${TASK_SLUG}/events.ndjson"
  exit 1
fi

if [[ ! -f "$REVIEW_ARTIFACT" ]]; then
  echo ""
  echo "[VIOLATION] IMPLEMENT_WITHOUT_PLAN_REVIEW"
  echo "  설명    : plan review artifact가 없습니다. plan이 reviewer 승인을 받지 않았습니다."
  echo "  수정 경로: /control-flow 로 plan_review 단계를 완료하세요."
  echo "  권장 명령: /control-flow"
  echo "  로그 ref : .claude/logs/${TASK_SLUG}/events.ndjson"
  exit 1
fi

exit 0
