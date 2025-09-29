# 预测性维护系统 - 管理员重启脚本
# 功能：完全重启项目 + 配置防火墙 + 网络访问支持

param(
    [switch]$SkipFirewall = $false
)

# 检查管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "🚀 启动管理员权限脚本..." -ForegroundColor Yellow
    Start-Process PowerShell -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "=======================================" -ForegroundColor Green
Write-Host "🔧 预测性维护系统 - 管理员重启脚本" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""

# 设置工作目录
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $projectRoot
Write-Host "📁 工作目录: $projectRoot" -ForegroundColor Cyan

try {
    # 步骤1: 完全停止所有服务
    Write-Host ""
    Write-Host "🛑 步骤1: 停止所有服务..." -ForegroundColor Yellow
    
    # 设置环境变量
    $env:PATH = "C:\Program Files\nodejs;" + $env:PATH
    
    # 停止PM2服务
    try {
        & npx pm2 delete all 2>$null
        & npx pm2 kill 2>$null
        Write-Host "   ✅ PM2服务已停止" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️ PM2停止时出现警告（正常）" -ForegroundColor Yellow
    }
    
    # 强制停止可能残留的进程
    try {
        Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Stop-Process -Force
        Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Host "   ✅ 残留进程已清理" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️ 进程清理完成" -ForegroundColor Yellow
    }
    
    # 步骤2: 配置防火墙
    if (-not $SkipFirewall) {
        Write-Host ""
        Write-Host "🔥 步骤2: 配置防火墙规则..." -ForegroundColor Yellow
        
        # 删除可能存在的旧规则
        try {
            netsh advfirewall firewall delete rule name="Predictive Maintenance Backend" 2>$null
            netsh advfirewall firewall delete rule name="Predictive Maintenance Frontend" 2>$null
        } catch { }
        
        # 添加新规则
        try {
            netsh advfirewall firewall add rule name="Predictive Maintenance Backend" dir=in action=allow protocol=TCP localport=5219 | Out-Null
            netsh advfirewall firewall add rule name="Predictive Maintenance Frontend" dir=in action=allow protocol=TCP localport=5173 | Out-Null
            Write-Host "   ✅ 防火墙规则配置完成" -ForegroundColor Green
            Write-Host "   📡 后端端口 5219 已开放" -ForegroundColor White
            Write-Host "   📡 前端端口 5173 已开放" -ForegroundColor White
        } catch {
            Write-Host "   ❌ 防火墙配置失败: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host ""
        Write-Host "⏭️ 步骤2: 跳过防火墙配置" -ForegroundColor Yellow
    }
    
    # 步骤3: 重新启动服务
    Write-Host ""
    Write-Host "🚀 步骤3: 启动所有服务..." -ForegroundColor Yellow
    
    # 等待一下确保端口释放
    Start-Sleep -Seconds 3
    
    # 启动PM2服务
    & .\pm2-manager.ps1 start
    
    # 步骤4: 验证服务状态
    Write-Host ""
    Write-Host "🔍 步骤4: 验证服务状态..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # 检查端口监听
    $backend = netstat -an | findstr "0.0.0.0:5219"
    $frontend = netstat -an | findstr "0.0.0.0:5173"
    
    if ($backend) {
        Write-Host "   ✅ 后端服务正常监听 (0.0.0.0:5219)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ 后端服务未正常启动" -ForegroundColor Red
    }
    
    if ($frontend) {
        Write-Host "   ✅ 前端服务正常监听 (0.0.0.0:5173)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ 前端服务未正常启动" -ForegroundColor Red
    }
    
    # 步骤5: 显示访问地址
    Write-Host ""
    Write-Host "🌐 步骤5: 获取访问地址..." -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host "🎉 重启完成！访问地址如下:" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Green
    
    # 本地访问
    Write-Host ""
    Write-Host "🏠 本地访问:" -ForegroundColor Cyan
    Write-Host "   前端界面: http://localhost:5173" -ForegroundColor White
    Write-Host "   后端API:  http://localhost:5219" -ForegroundColor White
    Write-Host "   API文档:  http://localhost:5219/swagger" -ForegroundColor White
    
    # 网络访问
    Write-Host ""
    Write-Host "🌐 网络访问 (局域网/外网):" -ForegroundColor Cyan
    
    # 获取IP地址
    $ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.InterfaceAlias -notlike "*Loopback*" -and 
        $_.InterfaceAlias -notlike "*Teredo*" -and
        $_.IPAddress -ne "127.0.0.1"
    } | Select-Object IPAddress -First 3
    
    foreach ($ip in $ips) {
        $ipAddr = $ip.IPAddress
        Write-Host "   前端: http://$ipAddr`:5173" -ForegroundColor White
        Write-Host "   后端: http://$ipAddr`:5219" -ForegroundColor White
        Write-Host "   文档: http://$ipAddr`:5219/swagger" -ForegroundColor White
        Write-Host ""
    }
    
    # 测试连接
    Write-Host "🔬 连接测试:" -ForegroundColor Cyan
    try {
        $testResult = Invoke-RestMethod -Uri "http://localhost:5219/api/devices" -TimeoutSec 5
        if ($testResult) {
            Write-Host "   ✅ API连接测试成功" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ⚠️ API连接测试失败，请稍等片刻再试" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host "📋 管理命令:" -ForegroundColor Yellow
    Write-Host "   .\pm2-manager.ps1 status   - 查看状态" -ForegroundColor White
    Write-Host "   .\pm2-manager.ps1 logs     - 查看日志" -ForegroundColor White
    Write-Host "   .\pm2-manager.ps1 restart  - 重启服务" -ForegroundColor White
    Write-Host "   .\pm2-manager.ps1 stop     - 停止服务" -ForegroundColor White
    Write-Host "=======================================" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "❌ 重启过程中出现错误:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 建议解决方案:" -ForegroundColor Yellow
    Write-Host "1. 检查Node.js和.NET是否正确安装" -ForegroundColor White
    Write-Host "2. 确认端口5173和5219未被其他程序占用" -ForegroundColor White
    Write-Host "3. 以管理员身份重新运行此脚本" -ForegroundColor White
    Write-Host "4. 查看详细日志: .\pm2-manager.ps1 logs" -ForegroundColor White
}

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
