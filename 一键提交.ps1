# 一键提交并推送
# 用法：双击 一键提交.bat，或在终端执行  .\一键提交.ps1 "完成洛谷B2005"

param([string]$Message)

Set-Location -LiteralPath $PSScriptRoot

function Info($t) { Write-Host $t -ForegroundColor Cyan }
function Warn($t) { Write-Host $t -ForegroundColor Yellow }
function Fail($t) { Write-Host $t -ForegroundColor Red }
function Ok($t)   { Write-Host $t -ForegroundColor Green }

function Test-LocalPort($Port) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $iar = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
        if ($iar.AsyncWaitHandle.WaitOne(500)) { $client.EndConnect($iar); return $true }
        return $false
    } catch { return $false } finally { $client.Close() }
}

if (-not $Message) { $Message = Read-Host "请输入提交说明（直接回车 = 用更新时间）" }
if (-not $Message) { $Message = "更新代码 $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }

Info "==> 收集改动（.gitignore 里的文件会自动跳过）"
git add -A
if ($LASTEXITCODE -ne 0) { Fail "git add 失败，已中止。"; exit 1 }

$staged = @(git diff --cached --name-only)
if ($staged.Count -eq 0) {
    Warn "没有需要提交的改动。"
    git status --short --branch
    exit 0
}
Info "将要提交的文件："
$staged | ForEach-Object { Write-Host "    $_" }

Info "==> 提交"
git commit -m $Message
if ($LASTEXITCODE -ne 0) { Fail "提交失败，已中止。"; exit 1 }
Ok "提交成功：$Message"

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if (-not (Test-LocalPort 10808)) {
    Warn "提醒：本地代理 127.0.0.1:10808 没在监听，v2rayN 可能没开，推送大概率会失败。"
}

Info "==> 推送到 origin/$branch"
$sw = [Diagnostics.Stopwatch]::StartNew()
git push origin $branch
$sw.Stop()
$secs = [math]::Round($sw.Elapsed.TotalSeconds, 1)

if ($LASTEXITCODE -ne 0) {
    Fail "推送失败（用时 $secs 秒）。常见原因："
    Warn "  1) v2rayN 没开，或系统代理没开"
    Warn "  2) 网络断了"
    Warn "  3) 远程有新提交：先 git pull --rebase origin $branch 再推送"
    Warn "  4) 需要重新登录 GitHub（按提示登录一次即可）"
    exit 1
}
Ok "推送成功，用时 $secs 秒。"

Info "最近提交："
git log --oneline -3
Info "当前状态："
git status --short --branch
Ok "全部完成。"