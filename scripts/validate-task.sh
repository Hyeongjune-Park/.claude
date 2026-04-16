#!/usr/bin/env bash
# validate-task.sh — task completion validation (mode-aware)
# usage: bash scripts/validate-task.sh <task-slug> [project-root]
#
# role:
#   - check state file existence and basic consistency
#   - check required artifacts for the active execution mode
#   - print machine-readable JSON summary for control-flow
#
# exit codes:
#   0 — pass / pass_with_warn
#   1 — fail

set -euo pipefail

TASK_SLUG="${1:-}"
PROJECT_ROOT="${2:-$(pwd)}"

if [[ -z "$TASK_SLUG" ]]; then
  echo "[ERROR] task-slug가 필요합니다."
  echo "사용법: bash scripts/validate-task.sh <task-slug> [project-root]"
  exit 1
fi

CLAUDE_DIR="$PROJECT_ROOT/.claude"
STATE_FILE="$CLAUDE_DIR/state/${TASK_SLUG}.json"
WORKFLOW_DIR="$CLAUDE_DIR/workflow/${TASK_SLUG}"
LOGS_DIR="$CLAUDE_DIR/logs/${TASK_SLUG}"

ERRORS=0
WARNINGS=0
WORKFLOW_STATE="unknown"
EXECUTION_MODE="strict"
SELECTED_REVIEW_ARTIFACT=""

check_fail() {
  local code="$1"
  local desc="$2"
  local fix="$3"
  echo ""
  echo "[VIOLATION] $code"
  echo "  설명    : $desc"
  echo "  수정 경로: $fix"
  echo "  로그 ref : $LOGS_DIR/events.ndjson"
  ERRORS=$((ERRORS + 1))
}

check_warn() {
  local code="$1"
  local desc="$2"
  echo "[WARN] $code: $desc"
  WARNINGS=$((WARNINGS + 1))
}

echo "[validate-task] task: $TASK_SLUG"
echo "[validate-task] root: $PROJECT_ROOT"
echo ""

# --- 1. state file ---

if [[ ! -f "$STATE_FILE" ]]; then
  check_fail "STATE_MISSING" \
    "state 파일이 없습니다: $STATE_FILE" \
    "bash scripts/start-task.sh $TASK_SLUG $PROJECT_ROOT 로 초기화 후 /control-flow 재실행"
else
  echo "[OK] state 파일 존재: $STATE_FILE"

  WORKFLOW_STATE="$(grep -o '"workflow_state": *"[^"]*"' "$STATE_FILE" | head -1 | sed 's/.*: *"//' | tr -d '"' || true)"
  if [[ -z "$WORKFLOW_STATE" ]]; then
    LEGACY_CURRENT_STATE="$(grep -o '"current_state": *"[^"]*"' "$STATE_FILE" | head -1 | sed 's/.*: *"//' | tr -d '"' || true)"
    if [[ -n "$LEGACY_CURRENT_STATE" ]]; then
      WORKFLOW_STATE="$LEGACY_CURRENT_STATE"
      check_warn "LEGACY_STATE_KEY" "workflow_state가 없어 current_state를 fallback으로 사용했습니다."
    fi
  fi
  if [[ -z "$WORKFLOW_STATE" ]]; then
    WORKFLOW_STATE="unknown"
    check_warn "WORKFLOW_STATE_MISSING" "state에서 workflow_state를 찾지 못했습니다."
  fi

  EXECUTION_MODE="$(grep -o '"execution_mode": *"[^"]*"' "$STATE_FILE" | head -1 | sed 's/.*: *"//' | tr -d '"' || true)"
  if [[ -z "$EXECUTION_MODE" ]]; then
    EXECUTION_MODE="strict"
    check_warn "EXECUTION_MODE_MISSING" "execution_mode가 없어 strict로 fallback했습니다."
  fi
  if [[ "$EXECUTION_MODE" != "lean" && "$EXECUTION_MODE" != "strict" ]]; then
    check_warn "EXECUTION_MODE_INVALID" "알 수 없는 execution_mode($EXECUTION_MODE)로 strict fallback 적용."
    EXECUTION_MODE="strict"
  fi

  echo "[OK] workflow_state: $WORKFLOW_STATE"
  echo "[OK] execution_mode: $EXECUTION_MODE"

  if [[ "$WORKFLOW_STATE" != "completed" && "$WORKFLOW_STATE" != "validation_pending" && "$WORKFLOW_STATE" != "final_review_pending" ]]; then
    check_warn "STATE_NOT_READY" "workflow_state가 예상 단계가 아닙니다: $WORKFLOW_STATE"
  fi
fi

# --- 2. workflow directory ---

if [[ ! -d "$WORKFLOW_DIR" ]]; then
  check_fail "WORKFLOW_DIR_MISSING" \
    "workflow 디렉터리가 없습니다: $WORKFLOW_DIR" \
    "bash scripts/start-task.sh $TASK_SLUG $PROJECT_ROOT 로 초기화"
else
  echo "[OK] workflow 디렉터리 존재"
fi

# --- 3. required artifacts by mode ---

if [[ "$EXECUTION_MODE" == "lean" ]]; then
  REQUIRED_ARTIFACTS=(
    "artifacts/plan.md"
    "artifacts/build-summary.md"
  )

  REVIEW_CANDIDATES=(
    "artifacts/review.md"
    "artifacts/review-result.md"
    "artifacts/review-plan.md"
  )

  for candidate in "${REVIEW_CANDIDATES[@]}"; do
    if [[ -f "$WORKFLOW_DIR/$candidate" ]]; then
      SELECTED_REVIEW_ARTIFACT="$candidate"
      break
    fi
  done
  if [[ -z "$SELECTED_REVIEW_ARTIFACT" ]]; then
    check_fail "REVIEW_ARTIFACT_MISSING" \
      "lean mode 필수 review artifact(review.md 또는 review-result.md 또는 review-plan.md)가 없습니다." \
      "/control-flow 를 실행해 review 단계를 완료하세요"
  else
    echo "[OK] review artifact: $SELECTED_REVIEW_ARTIFACT"
  fi
else
  REQUIRED_ARTIFACTS=(
    "artifacts/plan.md"
    "artifacts/review-plan.md"
    "artifacts/acceptance.md"
    "artifacts/build-summary.md"
    "artifacts/review-result.md"
  )

  if [[ "$WORKFLOW_STATE" == "completed" ]]; then
    REQUIRED_ARTIFACTS+=("artifacts/review-final.md")
  fi
fi

for artifact in "${REQUIRED_ARTIFACTS[@]}"; do
  ARTIFACT_PATH="$WORKFLOW_DIR/$artifact"
  if [[ ! -f "$ARTIFACT_PATH" ]]; then
    check_fail "ARTIFACT_MISSING:$artifact" \
      "필수 artifact가 없습니다: $artifact" \
      "/control-flow 를 실행해 해당 단계까지 워크플로를 진행하세요"
  else
    echo "[OK] artifact: $artifact"
  fi
done

# --- 4. logs directory ---

if [[ ! -d "$LOGS_DIR" ]]; then
  check_warn "LOGS_DIR_MISSING" "logs 디렉터리가 없습니다: $LOGS_DIR"
else
  echo "[OK] logs 디렉터리 존재"
fi

# --- summary ---

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[validate-task] 결과 요약"
echo "  오류  : $ERRORS"
echo "  경고  : $WARNINGS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $ERRORS -gt 0 ]]; then
  RESULT="fail"
elif [[ $WARNINGS -gt 0 ]]; then
  RESULT="pass_with_warn"
else
  RESULT="pass"
fi

CHECKED_ARTIFACTS=("${REQUIRED_ARTIFACTS[@]}")
if [[ -n "$SELECTED_REVIEW_ARTIFACT" ]]; then
  CHECKED_ARTIFACTS+=("$SELECTED_REVIEW_ARTIFACT")
fi

ARTIFACT_LIST_JSON="["
for artifact in "${CHECKED_ARTIFACTS[@]}"; do
  normalized="${artifact//\\//}"
  if [[ "$ARTIFACT_LIST_JSON" != "[" ]]; then
    ARTIFACT_LIST_JSON+=","
  fi
  ARTIFACT_LIST_JSON+="\"$normalized\""
done
ARTIFACT_LIST_JSON+="]"

GENERATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")"

echo ""
echo "VALIDATION_SUMMARY_JSON"
cat <<EOF
{"result":"$RESULT","errors":$ERRORS,"warnings":$WARNINGS,"checked_artifacts":$ARTIFACT_LIST_JSON,"workflow_state":"$WORKFLOW_STATE","task_slug":"$TASK_SLUG","generated_at":"$GENERATED_AT","execution_mode":"$EXECUTION_MODE"}
EOF

if [[ "$RESULT" == "fail" ]]; then
  echo "[FAIL] 필수 조건 미충족. 위 오류를 해결 후 재시도하세요."
  exit 1
elif [[ "$RESULT" == "pass_with_warn" ]]; then
  echo "[PASS with WARN] 검증 통과 (경고 있음)."
  exit 0
else
  echo "[PASS] 모든 검증 통과."
  exit 0
fi
