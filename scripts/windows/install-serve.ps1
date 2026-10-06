# Dựng opencode serve trên Windows: Scheduled Task chạy khi đăng nhập.
# Chạy trong PowerShell:  .\install-serve.ps1 -Password "<mật khẩu tự sinh>" -WorkDir "C:\Users\<bạn>\Documents\projects"
param(
  [Parameter(Mandatory = $true)][string]$Password,
  [string]$WorkDir = "$env:USERPROFILE\Documents\projects",
  [int]$Port = 4096
)

$opencode = "$env:USERPROFILE\.opencode\bin\opencode.exe"
if (-not (Test-Path $opencode)) { throw "Không thấy $opencode — cài opencode trước." }

# Mật khẩu qua biến môi trường cấp user, task kế thừa khi chạy.
[Environment]::SetEnvironmentVariable("OPENCODE_SERVER_PASSWORD", $Password, "User")

$action = New-ScheduledTaskAction -Execute $opencode `
  -Argument "serve --hostname 127.0.0.1 --port $Port" -WorkingDirectory $WorkDir
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
Register-ScheduledTask -TaskName "OpenCode Serve" -Action $action -Trigger $trigger `
  -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName "OpenCode Serve"

Start-Sleep -Seconds 4
try {
  $code = (Invoke-WebRequest -Uri "http://127.0.0.1:$Port/" -UseBasicParsing -TimeoutSec 5).StatusCode
  Write-Host "OK: serve nghe 127.0.0.1:$Port (HTTP $code), thư mục làm việc $WorkDir"
} catch {
  throw "Serve chưa trả lời sau 4 giây — kiểm tra Task Scheduler."
}

Write-Host "Tiếp theo (trong terminal đã có tailscale): tailscale serve --bg http://127.0.0.1:$Port"
Write-Host "Giữ máy thức khi cắm điện: powercfg /change standby-timeout-ac 0"
