# 快速管理员重启脚本
# 检查管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "⚡ 需要管理员权限，正在重新启动..." -ForegroundColor Yellow
    Start-Process PowerShell -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "🔧 预测性维护系统 - 快速重启" -ForegroundColor Green
Write-Host ""

# 设置环境
$env:PATH = "C:\Program Files\nodejs;" + $env:PATH
Set-Location "C:\预测性维护系统"

# 1. 配置防火墙
Write-Host "🔥 配置防火墙..." -ForegroundColor Yellow
try {
    netsh advfirewall firewall delete rule name="Predictive Maintenance Backend" 2>$null
    netsh advfirewall firewall delete rule name="Predictive Maintenance Frontend" 2>$null
    netsh advfirewall firewall add rule name="Predictive Maintenance Backend" dir=in action=allow protocol=TCP localport=5219
    netsh advfirewall firewall add rule name="Predictive Maintenance Frontend" dir=in action=allow protocol=TCP localport=5173
    Write-Host "✅ 防火墙配置完成" -ForegroundColor Green
} catch {
    Write-Host "⚠️ 防火墙配置警告: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. 停止所有服务
Write-Host "🛑 停止现有服务..." -ForegroundColor Yellow
npx pm2 delete all 2>$null
npx pm2 kill 2>$null
taskkill /f /im dotnet.exe 2>$null
taskkill /f /im node.exe 2>$null

# 3. 启动服务
Write-Host "🚀 启动服务..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
& .\pm2-manager.ps1 start

# 4. 显示结果
Write-Host ""
Write-Host "🌐 访问地址:" -ForegroundColor Cyan
Write-Host "本地 - 前端: http://localhost:5173" -ForegroundColor White
Write-Host "本地 - 后端: http://localhost:5219" -ForegroundColor White
Write-Host "本地 - 文档: http://localhost:5219/swagger" -ForegroundColor White

# 获取IP地址
$ips = ipconfig | findstr IPv4 | ForEach-Object { ($_ -split ':')[1].Trim() } | Where-Object { $_ -ne "127.0.0.1" } | Select-Object -First 2
foreach ($ip in $ips) {
    Write-Host "网络 - 前端: http://$ip`:5173" -ForegroundColor White
    Write-Host "网络 - 后端: http://$ip`:5219" -ForegroundColor White
}

Write-Host ""
Write-Host "✅ 重启完成！" -ForegroundColor Green
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
