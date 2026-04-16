# validate-task.ps1 - task completion validation (mode-aware)
# Usage:
#   .\scripts\validate-task.ps1 -TaskSlug <task-slug> [-ProjectRoot <path>]

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
$WorkflowState = "unknown"
$ExecutionMode = "strict"
$SelectedReviewArtifact = $null
$RequiredArtifacts = @()

function Write-Violation($Code, $Desc, $Fix) {
    Write-Host ""
    Write-Host "[VIOLATION] $Code"
    Write-Host "  description: $Desc"
    Write-Host "  fix path   : $Fix"
    Write-Host "  logs ref   : $LogsDir\events.ndjson"
    $script:Errors++
}

function Write-Warn($Code, $Desc) {
    Write-Host "[WARN] ${Code}: $Desc"
    $script:Warnings++
}

Write-Host "[validate-task] task: $TaskSlug"
Write-Host "[validate-task] root: $ProjectRoot"
Write-Host ""

# --- 1) state file ---

if (-not (Test-Path $StateFile)) {
    Write-Violation "STATE_MISSING" `
        "state file is missing: $StateFile" `
        ".\scripts\start-task.ps1 -TaskSlug $TaskSlug -ProjectRoot '$ProjectRoot' then rerun /control-flow"
} else {
    Write-Host "[OK] state file: $StateFile"
    $StateContent = Get-Content $StateFile -Raw

    if ($StateContent -match '"workflow_state"\s*:\s*"([^"]+)"') {
        $WorkflowState = $Matches[1]
    } elseif ($StateContent -match '"current_state"\s*:\s*"([^"]+)"') {
        $WorkflowState = $Matches[1]
        Write-Warn "LEGACY_STATE_KEY" "workflow_state not found; current_state fallback was used."
    } else {
        Write-Warn "WORKFLOW_STATE_MISSING" "workflow_state not found in state file."
    }

    if ($StateContent -match '"execution_mode"\s*:\s*"([^"]+)"') {
        $ExecutionMode = $Matches[1]
    } else {
        $ExecutionMode = "strict"
        Write-Warn "EXECUTION_MODE_MISSING" "execution_mode not found; strict fallback was used."
    }

    if ($ExecutionMode -ne "lean" -and $ExecutionMode -ne "strict") {
        Write-Warn "EXECUTION_MODE_INVALID" "unknown execution_mode '$ExecutionMode'; strict fallback was used."
        $ExecutionMode = "strict"
    }

    Write-Host "[OK] workflow_state: $WorkflowState"
    Write-Host "[OK] execution_mode: $ExecutionMode"

    if ($WorkflowState -ne "completed" -and $WorkflowState -ne "validation_pending" -and $WorkflowState -ne "final_review_pending") {
        Write-Warn "STATE_NOT_READY" "workflow_state is not a typical completion gate: $WorkflowState"
    }
}

# --- 2) workflow directory ---

if (-not (Test-Path $WorkflowDir -PathType Container)) {
    Write-Violation "WORKFLOW_DIR_MISSING" `
        "workflow directory is missing: $WorkflowDir" `
        ".\scripts\start-task.ps1 -TaskSlug $TaskSlug -ProjectRoot '$ProjectRoot'"
} else {
    Write-Host "[OK] workflow directory exists"
}

# --- 3) mode-aware required artifacts ---

if ($ExecutionMode -eq "lean") {
    $RequiredArtifacts = @(
        "artifacts\plan.md",
        "artifacts\build-summary.md"
    )

    $ReviewCandidates = @(
        "artifacts\review.md",
        "artifacts\review-result.md",
        "artifacts\review-plan.md"
    )

    foreach ($candidate in $ReviewCandidates) {
        if (Test-Path (Join-Path $WorkflowDir $candidate)) {
            $SelectedReviewArtifact = $candidate
            break
        }
    }

    if ($null -eq $SelectedReviewArtifact) {
        Write-Violation "REVIEW_ARTIFACT_MISSING" `
            "lean mode requires one review artifact (review.md or review-result.md or review-plan.md)." `
            "run /control-flow and finish the review step"
    } else {
        Write-Host "[OK] review artifact: $SelectedReviewArtifact"
    }
} else {
    $RequiredArtifacts = @(
        "artifacts\plan.md",
        "artifacts\review-plan.md",
        "artifacts\acceptance.md",
        "artifacts\build-summary.md",
        "artifacts\review-result.md"
    )
}

foreach ($artifact in $RequiredArtifacts) {
    if (-not (Test-Path (Join-Path $WorkflowDir $artifact))) {
        Write-Violation "ARTIFACT_MISSING:$artifact" `
            "required artifact is missing: $artifact" `
            "run /control-flow until the required stage is completed"
    } else {
        Write-Host "[OK] artifact: $artifact"
    }
}

# --- 4) logs directory ---

if (-not (Test-Path $LogsDir -PathType Container)) {
    Write-Warn "LOGS_DIR_MISSING" "logs directory is missing: $LogsDir"
} else {
    Write-Host "[OK] logs directory exists"
}

# --- summary ---

Write-Host ""
Write-Host "===================================="
Write-Host "[validate-task] summary"
Write-Host "  errors  : $Errors"
Write-Host "  warnings: $Warnings"
Write-Host "===================================="

$Result = if ($Errors -gt 0) { "fail" } elseif ($Warnings -gt 0) { "pass_with_warn" } else { "pass" }
$GeneratedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$CheckedArtifacts = @($RequiredArtifacts | ForEach-Object { $_ -replace '\\','/' })
if ($null -ne $SelectedReviewArtifact) {
    $CheckedArtifacts += ($SelectedReviewArtifact -replace '\\','/')
}

$SummaryObject = [ordered]@{
    result = $Result
    errors = $Errors
    warnings = $Warnings
    checked_artifacts = $CheckedArtifacts
    workflow_state = $WorkflowState
    task_slug = $TaskSlug
    generated_at = $GeneratedAt
    execution_mode = $ExecutionMode
}

Write-Host ""
Write-Host "VALIDATION_SUMMARY_JSON"
Write-Host ($SummaryObject | ConvertTo-Json -Compress)

if ($Errors -gt 0) {
    Write-Host "[FAIL] required checks failed."
    exit 1
}

if ($Warnings -gt 0) {
    Write-Host "[PASS with WARN] validation passed with warnings."
    exit 0
}

Write-Host "[PASS] all checks passed."
exit 0
