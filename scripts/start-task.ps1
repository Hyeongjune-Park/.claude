# start-task.ps1 — task bootstrap script (Windows)
# 사용법: .\scripts\start-task.ps1 -TaskSlug <task-slug> [-ProjectRoot <path>]
#
# 역할:
#   - task slug 유효성 검사
#   - .claude/state/<slug>.json skeleton 초기화
#   - .claude/workflow/<slug>/ 디렉터리 구조 생성
#   - .claude/logs/<slug>/ 디렉터리 구조 생성
#   - 로컬 CLAUDE.md 템플릿 배치 (없을 때만)

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskSlug,

    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- 입력 검증 ---

if ($TaskSlug -notmatch '^[a-z0-9][a-z0-9\-]*[a-z0-9]$') {
    Write-Error "[ERROR] task-slug는 소문자, 숫자, 하이픈만 허용합니다. (예: user-auth-refactor)"
    exit 1
}

if (-not (Test-Path $ProjectRoot -PathType Container)) {
    Write-Error "[ERROR] project-root가 존재하지 않습니다: $ProjectRoot"
    exit 1
}

$ClaudeDir    = Join-Path $ProjectRoot ".claude"
$StateFile    = Join-Path $ClaudeDir "state\$TaskSlug.json"
$WorkflowDir  = Join-Path $ClaudeDir "workflow\$TaskSlug"
$LogsDir      = Join-Path $ClaudeDir "logs\$TaskSlug"

Write-Host "[start-task] task: $TaskSlug"
Write-Host "[start-task] root: $ProjectRoot"

# --- 이미 존재하면 경고 ---

if (Test-Path $StateFile) {
    Write-Warning "[WARN] state 파일이 이미 존재합니다: $StateFile"
    Write-Warning "       기존 state를 유지하고 디렉터리 구조만 보완합니다."
}

# --- 디렉터리 생성 ---

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
Write-Host "[start-task] 디렉터리 생성 완료"

# --- state skeleton 초기화 (없을 때만) ---

if (-not (Test-Path $StateFile)) {
    $CreatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $StateJson = @"
{
  "feature_slug": "$TaskSlug",
  "current_state": "planning_pending",
  "state_classification": "fresh_start",
  "last_transition": {
    "trigger": "state_initialized",
    "at": "$CreatedAt"
  },
  "accepted_artifacts": {},
  "revision_request": null,
  "blocker_present": false,
  "logs_ref": ".claude/logs/$TaskSlug"
}
"@
    Set-Content -Path $StateFile -Value $StateJson -Encoding UTF8
    Write-Host "[start-task] state skeleton 생성: $StateFile"
} else {
    Write-Host "[start-task] 기존 state 유지: $StateFile"
}

# --- 로컬 CLAUDE.md 템플릿 배치 (없을 때만) ---

$LocalClaude  = Join-Path $ProjectRoot "CLAUDE.md"
$HarnessRoot  = Split-Path $PSScriptRoot -Parent
$Template     = Join-Path $HarnessRoot "templates\CLAUDE.md"

if (-not (Test-Path $LocalClaude) -and (Test-Path $Template)) {
    Copy-Item $Template $LocalClaude
    Write-Host "[start-task] CLAUDE.md 템플릿 배치: $LocalClaude"
} elseif (Test-Path $LocalClaude) {
    Write-Host "[start-task] 기존 CLAUDE.md 유지: $LocalClaude"
} else {
    Write-Warning "[WARN] 템플릿을 찾을 수 없습니다: $Template"
}

# --- 완료 ---

Write-Host ""
Write-Host "[start-task] 완료."
Write-Host "  state   : $StateFile"
Write-Host "  workflow: $WorkflowDir\"
Write-Host "  logs    : $LogsDir\"
Write-Host ""
Write-Host "다음 단계: /control-flow 호출"
