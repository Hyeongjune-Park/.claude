# worktree-guard.ps1 — 병렬/격리 작업 시 worktree 존재 여부 확인 (Windows)
#
# severity: warn (기록 후 계속) / block으로 변경하려면 exit 1 사용

param()

$ProjectRoot  = if ($env:CLAUDE_PROJECT_ROOT) { $env:CLAUDE_PROJECT_ROOT } else { (Get-Location).Path }
$TaskSlug     = if ($env:CLAUDE_TASK_SLUG)    { $env:CLAUDE_TASK_SLUG }    else { "unknown" }

try {
    $Worktrees = & git -C $ProjectRoot worktree list 2>$null
    $WorktreeCount = ($Worktrees | Where-Object { $_ -match '^\S' }).Count
} catch {
    $WorktreeCount = 1
}

try {
    $CurrentBranch = (& git -C $ProjectRoot branch --show-current 2>$null).Trim()
} catch {
    $CurrentBranch = "unknown"
}

$MainBranches = @("main", "master", "develop")
$IsMainBranch = $MainBranches -contains $CurrentBranch

if ($WorktreeCount -le 1 -and $IsMainBranch) {
    Write-Host ""
    Write-Host "[VIOLATION] WORKTREE_MISSING"
    Write-Host "  설명    : 격리된 feature 작업에 git worktree가 없습니다."
    Write-Host "            현재 브랜치: $CurrentBranch"
    Write-Host "  수정 경로: git worktree add ..\<task-slug> -b feature\<task-slug>"
    if ($TaskSlug -ne "unknown") {
        Write-Host "  권장 명령: git worktree add ..\$TaskSlug -b feature/$TaskSlug"
    }
    Write-Host "  로그 ref : .claude\logs\$TaskSlug\events.ndjson"
    # severity: warn → exit 0, block → exit 1
    exit 0
}

exit 0
