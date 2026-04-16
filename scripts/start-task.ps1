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
        feature_slug = $TaskSlug
        workflow_state = "planning_pending"
        execution_mode = $ExecutionMode
        state_classification = "fresh_start"
        last_transition = [ordered]@{
            trigger = "state_initialized"
            at = $CreatedAt
        }
        accepted_artifacts = [ordered]@{}
        revision_request = $null
        blocker_present = $false
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
