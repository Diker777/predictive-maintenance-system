# 预测性维护系统防火墙配置脚本
# 需要以管理员身份运行

Write-Host "=== 配置预测性维护系统防火墙规则 ===" -ForegroundColor Green

# 检查管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ 此脚本需要管理员权限!" -ForegroundColor Red
    Write-Host "请右键点击PowerShell，选择'以管理员身份运行'" -ForegroundColor Yellow
    Write-Host "然后执行: .\setup-firewall.ps1" -ForegroundColor Yellow
    exit 1
}

try {
    # 删除可能存在的旧规则
    Write-Host "🗑️ 清理旧的防火墙规则..." -ForegroundColor Yellow
    netsh advfirewall firewall delete rule name="Predictive Maintenance Backend" 2>$null
    netsh advfirewall firewall delete rule name="Predictive Maintenance Frontend" 2>$null
    
    # 添加后端端口规则
    Write-Host "🔧 添加后端端口5219防火墙规则..." -ForegroundColor Cyan
    netsh advfirewall firewall add rule name="Predictive Maintenance Backend" dir=in action=allow protocol=TCP localport=5219
    
    # 添加前端端口规则
    Write-Host "🔧 添加前端端口5173防火墙规则..." -ForegroundColor Cyan
    netsh advfirewall firewall add rule name="Predictive Maintenance Frontend" dir=in action=allow protocol=TCP localport=5173
    
    Write-Host "✅ 防火墙规则配置完成!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ 防火墙配置失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🌐 现在可以通过以下地址访问系统:" -ForegroundColor Green
Write-Host ""

# 获取本机IP地址
$ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.InterfaceAlias -notlike "*Teredo*" } | Select-Object IPAddress

foreach ($ip in $ips) {
    $ipAddr = $ip.IPAddress
    if ($ipAddr -ne "127.0.0.1") {
        Write-Host "前端: http://$ipAddr`:5173" -ForegroundColor White
        Write-Host "后端: http://$ipAddr`:5219" -ForegroundColor White
        Write-Host "API文档: http://$ipAddr`:5219/swagger" -ForegroundColor White
        Write-Host ""
    }
}

Write-Host "本地访问:" -ForegroundColor Yellow
Write-Host "前端: http://localhost:5173" -ForegroundColor White
Write-Host "后端: http://localhost:5219" -ForegroundColor White
Write-Host "API文档: http://localhost:5219/swagger" -ForegroundColor White
Write-Host ""
Write-Host "⚠️ 注意: 确保您的路由器和网络设置允许相应端口访问" -ForegroundColor Yellow
