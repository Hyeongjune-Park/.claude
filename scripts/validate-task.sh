#!/usr/bin/env bash
# validate-task.sh — task 완료 전 필수 검증
# 사용법: bash scripts/validate-task.sh <task-slug> [project-root]
#
# 역할:
#   - state 파일 존재 및 정합성 확인
#   - 필수 artifact 존재 확인
#   - final review artifact 존재 확인
#   - validation summary 확인
#   - 위반 시 상세 피드백 출력

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

# --- 1. state 파일 ---

if [[ ! -f "$STATE_FILE" ]]; then
  check_fail "STATE_MISSING" \
    "state 파일이 없습니다: $STATE_FILE" \
    "bash scripts/start-task.sh $TASK_SLUG $PROJECT_ROOT 로 초기화 후 /control-flow 재실행"
else
  echo "[OK] state 파일 존재: $STATE_FILE"

  # state에서 current_state 추출 (jq 없이 grep으로)
  CURRENT_STATE="$(grep -o '"current_state": *"[^"]*"' "$STATE_FILE" | head -1 | sed 's/.*: *"//' | tr -d '"')"
  echo "[OK] current_state: $CURRENT_STATE"

  if [[ "$CURRENT_STATE" != "completed" ]]; then
    check_warn "STATE_NOT_COMPLETED" "current_state가 completed가 아닙니다: $CURRENT_STATE"
  fi
fi

# --- 2. workflow 디렉터리 ---

if [[ ! -d "$WORKFLOW_DIR" ]]; then
  check_fail "WORKFLOW_DIR_MISSING" \
    "workflow 디렉터리가 없습니다: $WORKFLOW_DIR" \
    "bash scripts/start-task.sh $TASK_SLUG $PROJECT_ROOT 로 초기화"
else
  echo "[OK] workflow 디렉터리 존재"
fi

# --- 3. 필수 artifact ---

REQUIRED_ARTIFACTS=(
  "artifacts/plan.md"
  "artifacts/review-plan.md"
  "artifacts/implementation-design.md"
  "artifacts/review-implementation.md"
  "artifacts/implementation.md"
  "artifacts/review-final.md"
)

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

# --- 4. evidence / validation summary ---

VALIDATION_SUMMARY="$WORKFLOW_DIR/evidence/validation-summary.json"
if [[ ! -f "$VALIDATION_SUMMARY" ]]; then
  check_warn "VALIDATION_SUMMARY_MISSING" \
    "validation summary가 없습니다: $VALIDATION_SUMMARY"
else
  echo "[OK] validation summary 존재"
fi

# --- 5. logs 디렉터리 ---

if [[ ! -d "$LOGS_DIR" ]]; then
  check_warn "LOGS_DIR_MISSING" "logs 디렉터리가 없습니다: $LOGS_DIR"
else
  echo "[OK] logs 디렉터리 존재"
fi

# --- 결과 요약 ---

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[validate-task] 결과 요약"
echo "  오류  : $ERRORS"
echo "  경고  : $WARNINGS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $ERRORS -gt 0 ]]; then
  echo "[FAIL] 필수 조건 미충족. 위 오류를 해결 후 재시도하세요."
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  echo "[PASS with WARN] 검증 통과 (경고 있음)."
  exit 0
else
  echo "[PASS] 모든 검증 통과."
  exit 0
fi
