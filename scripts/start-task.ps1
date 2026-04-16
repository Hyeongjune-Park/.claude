# start-task.ps1 - task bootstrap script (Windows)
# Usage:
#   .\scripts\start-task.ps1 -TaskSlug <task-slug> [-ProjectRoot <path>] [-ExecutionMode <lean|strict>]

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskSlug,

    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = (Get-Location).Path,

    [Parameter(Mandatory=$false)]
    [ValidateSet("lean", "strict")]
    [string]$ExecutionMode = "lean"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($TaskSlug -notmatch '^[a-z0-9][a-z0-9\-]*[a-z0-9]$') {
    Write-Error "[ERROR] task-slug allows lowercase letters, digits, and hyphens only (example: user-auth-refactor)."
    exit 1
}

if (-not (Test-Path $ProjectRoot -PathType Container)) {
    Write-Error "[ERROR] project-root does not exist: $ProjectRoot"
    exit 1
}

$ClaudeDir   = Join-Path $ProjectRoot ".claude"
$StateFile   = Join-Path $ClaudeDir "state\$TaskSlug.json"
$WorkflowDir = Join-Path $ClaudeDir "workflow\$TaskSlug"
$LogsDir     = Join-Path $ClaudeDir "logs\$TaskSlug"

Write-Host "[start-task] task: $TaskSlug"
Write-Host "[start-task] root: $ProjectRoot"
Write-Host "[start-task] mode: $ExecutionMode"

if (Test-Path $StateFile) {
    Write-Warning "[WARN] state file already exists: $StateFile"
    Write-Warning "       existing state is preserved; only directories are ensured."
}

$dirs = @(
    (Join-Path $ClaudeDir "state"),
    (Join-Path $WorkflowDir "artifacts\history"),
    (Join-Path $WorkflowDir "contracts"),
    (Join-Path $WorkflowDir "evidence"),
    $LogsDir
)
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}
Write-Host "[start-task] directory bootstrap completed"

if (-not (Test-Path $StateFile)) {
    $CreatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $StateObject = [ordered]@{
        schema_version = "state@8"
        feature_slug = $TaskSlug
        active_project_root = $ProjectRoot
        workflow_state = "planning_pending"
        execution_mode = $ExecutionMode
        last_completed_stage = $null
        status = "pending"
        verdict = "none"
        next_allowed = "planning"
        blocker_present = $false
        blocker_reason = ""
        human_input_required = $false
        scope_fingerprint = $null
        stale = $false
        stale_reason = ""
        evidence_policy_mode = "warning"
        policy_resolution = [ordered]@{
            ref = $null
            required_docs = @()
            consistent = $false
        }
        artifacts = [ordered]@{
            plan = $null
            review = $null
            review_plan = $null
            acceptance = $null
            build_summary = $null
            review_result = $null
            review_final = $null
        }
        accepted_artifacts = [ordered]@{
            plan = $null
            build_summary = $null
        }
        pending_review = [ordered]@{
            stage = $null
            artifact_ref = $null
            ledger_ref = $null
        }
        review_inputs = [ordered]@{
            review = $null
            plan_review = $null
            result_review = $null
            final_review = $null
        }
        revision_request = [ordered]@{
            active = $false
            source_review_stage = $null
            source_review_ref = $null
            target_stage = $null
            allowed_delta = @()
            forbidden_changes = @()
            scope_preserved = $true
            auto_fix_allowed = $false
            attempt_count = 0
            max_attempts = 1
        }
        last_review_evidence = $null
        last_validation_summary = $null
        state_classification = "fresh_start"
        last_transition = [ordered]@{
            from_state = $null
            to_state = "planning_pending"
            trigger = "state_initialized"
            artifact_path = $null
            timestamp = $CreatedAt
        }
        updated_at = $CreatedAt
        logs_ref = ".claude/logs/$TaskSlug"
    }
    $StateJson = $StateObject | ConvertTo-Json -Depth 10
    Set-Content -Path $StateFile -Value $StateJson -Encoding UTF8
    Write-Host "[start-task] state skeleton created: $StateFile"
} else {
    Write-Host "[start-task] existing state kept: $StateFile"
}

$LocalClaude = Join-Path $ProjectRoot "CLAUDE.md"
$HarnessRoot = Split-Path $PSScriptRoot -Parent
$Template = Join-Path $HarnessRoot "templates\CLAUDE.md"

if (-not (Test-Path $LocalClaude) -and (Test-Path $Template)) {
    Copy-Item $Template $LocalClaude
    Write-Host "[start-task] template copied: $LocalClaude"
} elseif (Test-Path $LocalClaude) {
    Write-Host "[start-task] existing CLAUDE.md kept: $LocalClaude"
} else {
    Write-Warning "[WARN] template not found: $Template"
}

Write-Host ""
Write-Host "[start-task] done."
Write-Host "  state   : $StateFile"
Write-Host "  workflow: $WorkflowDir\"
Write-Host "  logs    : $LogsDir\"
Write-Host ""
Write-Host "next step: /control-flow"
