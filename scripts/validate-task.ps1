# validate-task.ps1 — task 완료 전 필수 검증 (Windows)
# 사용법: .\scripts\validate-task.ps1 -TaskSlug <task-slug> [-ProjectRoot <path>]
#
# 역할:
#   - state 파일 존재 및 정합성 확인
#   - 필수 artifact 존재 확인 (plan, review-plan, acceptance, build-summary, review-result)
#   - acceptance.md 존재 확인 (validation은 acceptance 기준으로만 판정)
#   - 위반 시 상세 피드백 출력
#
# 종료 코드:
#   0 — 검증 통과 (PASS 또는 PASS with WARN)
#   1 — 필수 조건 미충족 (FAIL)

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskSlug,

    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ClaudeDir   = Join-Path $ProjectRoot ".claude"
$StateFile   = Join-Path $ClaudeDir "state\$TaskSlug.json"
$WorkflowDir = Join-Path $ClaudeDir "workflow\$TaskSlug"
$LogsDir     = Join-Path $ClaudeDir "logs\$TaskSlug"

$Errors   = 0
$Warnings = 0

function Write-Violation($Code, $Desc, $Fix) {
    Write-Host ""
    Write-Host "[VIOLATION] $Code"
    Write-Host "  설명    : $Desc"
    Write-Host "  수정 경로: $Fix"
    Write-Host "  로그 ref : $LogsDir\events.ndjson"
    $script:Errors++
}

function Write-Warn($Code, $Desc) {
    Write-Host "[WARN] ${Code}: $Desc"
    $script:Warnings++
}

Write-Host "[validate-task] task: $TaskSlug"
Write-Host "[validate-task] root: $ProjectRoot"
Write-Host ""

# --- 1. state 파일 ---

if (-not (Test-Path $StateFile)) {
    Write-Violation "STATE_MISSING" `
        "state 파일이 없습니다: $StateFile" `
        ".\scripts\start-task.ps1 -TaskSlug $TaskSlug -ProjectRoot '$ProjectRoot' 로 초기화 후 /control-flow 재실행"
} else {
    Write-Host "[OK] state 파일 존재: $StateFile"
    $StateContent = Get-Content $StateFile -Raw
    if ($StateContent -match '"workflow_state"\s*:\s*"([^"]+)"') {
        $WorkflowState = $Matches[1]
        Write-Host "[OK] workflow_state: $WorkflowState"
        if ($WorkflowState -ne "completed" -and $WorkflowState -ne "validation_pending" -and $WorkflowState -ne "final_review_pending") {
            Write-Warn "STATE_NOT_READY" "workflow_state가 예상 단계가 아닙니다: $WorkflowState"
        }
    }
}

# --- 2. workflow 디렉터리 ---

if (-not (Test-Path $WorkflowDir -PathType Container)) {
    Write-Violation "WORKFLOW_DIR_MISSING" `
        "workflow 디렉터리가 없습니다: $WorkflowDir" `
        ".\scripts\start-task.ps1 -TaskSlug $TaskSlug 로 초기화"
} else {
    Write-Host "[OK] workflow 디렉터리 존재"
}

# --- 3. 필수 artifact ---

$RequiredArtifacts = @(
    "artifacts\plan.md",
    "artifacts\review-plan.md",
    "artifacts\acceptance.md",
    "artifacts\build-summary.md",
    "artifacts\review-result.md"
)

foreach ($artifact in $RequiredArtifacts) {
    $ArtifactPath = Join-Path $WorkflowDir $artifact
    if (-not (Test-Path $ArtifactPath)) {
        Write-Violation "ARTIFACT_MISSING:$artifact" `
            "필수 artifact가 없습니다: $artifact" `
            "/control-flow 를 실행해 해당 단계까지 워크플로를 진행하세요"
    } else {
        Write-Host "[OK] artifact: $artifact"
    }
}

# --- 4. logs 디렉터리 ---

if (-not (Test-Path $LogsDir -PathType Container)) {
    Write-Warn "LOGS_DIR_MISSING" "logs 디렉터리가 없습니다: $LogsDir"
} else {
    Write-Host "[OK] logs 디렉터리 존재"
}

# --- 결과 요약 ---

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "[validate-task] 결과 요약"
Write-Host "  오류  : $Errors"
Write-Host "  경고  : $Warnings"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

$Result = if ($Errors -gt 0) { "fail" } elseif ($Warnings -gt 0) { "pass_with_warn" } else { "pass" }

# --- machine-readable summary (stdout JSON) ---
# control-flow는 이 JSON 줄을 파싱해 evidence/validation-summary-<timestamp>.json을 작성한다.

$GeneratedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$ArtifactList = ($RequiredArtifacts | ForEach-Object { '"' + $_.Replace('\','/') + '"' }) -join ","

$WorkflowStateVal = if ($StateContent -match '"workflow_state"\s*:\s*"([^"]+)"') { $Matches[1] } else { "unknown" }

Write-Host ""
Write-Host "VALIDATION_SUMMARY_JSON"
Write-Host "{`"result`":`"$Result`",`"errors`":$Errors,`"warnings`":$Warnings,`"checked_artifacts`":[$ArtifactList],`"workflow_state`":`"$WorkflowStateVal`",`"task_slug`":`"$TaskSlug`",`"generated_at`":`"$GeneratedAt`"}"

if ($Errors -gt 0) {
    Write-Host "[FAIL] 필수 조건 미충족. 위 오류를 해결 후 재시도하세요."
    exit 1
} elseif ($Warnings -gt 0) {
    Write-Host "[PASS with WARN] 검증 통과 (경고 있음)."
    exit 0
} else {
    Write-Host "[PASS] 모든 검증 통과."
    exit 0
}
