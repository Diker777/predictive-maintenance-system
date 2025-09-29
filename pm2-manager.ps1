# 预测性维护系统 PM2 完整管理脚本
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "restart", "status", "logs", "monit", "delete")]
    [string]$Action = "start"
)

# 设置Node.js环境变量
$env:PATH = "C:\Program Files\nodejs;" + $env:PATH

# 切换到项目根目录
Set-Location "C:\预测性维护系统"

Write-Host "=== PM2 预测性维护系统管理器 ===" -ForegroundColor Green
Write-Host "操作: $Action" -ForegroundColor Yellow
Write-Host "模式: 后台运行 (无CMD窗口)" -ForegroundColor Magenta

switch ($Action) {
    "start" {
        Write-Host "`n🚀 启动所有服务..." -ForegroundColor Green
        
        # 确保logs目录存在
        if (!(Test-Path "logs")) {
            New-Item -ItemType Directory -Force -Path "logs" | Out-Null
        }
        
        # 启动PM2服务
        npx pm2 start pm2.ecosystem.config.js
        
        Write-Host "`n⏳ 等待服务启动..." -ForegroundColor Cyan
        Start-Sleep 15
        
        Write-Host "`n📊 检查服务状态..." -ForegroundColor Cyan
        npx pm2 status
        
        Write-Host "`n🌐 检查端口监听..." -ForegroundColor Cyan
        $backend_port = netstat -an | findstr ":5219"
        $frontend_port = netstat -an | findstr ":5173"
        
        if ($backend_port) {
            Write-Host "✅ 后端端口 5219 正在监听" -ForegroundColor Green
        } else {
            Write-Host "❌ 后端端口 5219 未监听" -ForegroundColor Red
        }
        
        if ($frontend_port) {
            Write-Host "✅ 前端端口 5173 正在监听" -ForegroundColor Green
        } else {
            Write-Host "❌ 前端端口 5173 未监听" -ForegroundColor Red
        }
        
        Write-Host "`n🎉 启动完成!" -ForegroundColor Green
        Write-Host "前端: http://localhost:5173" -ForegroundColor White
        Write-Host "后端: http://localhost:5219" -ForegroundColor White
    }
    
    "stop" {
        Write-Host "`n🛑 停止所有服务..." -ForegroundColor Red
        npx pm2 stop all
        Write-Host "`n✅ 所有服务已停止!" -ForegroundColor Green
    }
    
    "restart" {
        Write-Host "`n🔄 重启所有服务..." -ForegroundColor Yellow
        npx pm2 restart all
        Write-Host "`n✅ 所有服务已重启!" -ForegroundColor Green
    }
    
    "status" {
        Write-Host "`n📊 服务状态:" -ForegroundColor Cyan
        npx pm2 status
        
        Write-Host "`n🌐 端口状态:" -ForegroundColor Cyan
        Write-Host "后端端口 5219:" -ForegroundColor White
        netstat -an | findstr ":5219" | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }
        Write-Host "前端端口 5173:" -ForegroundColor White
        netstat -an | findstr ":5173" | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }
    }
    
    "logs" {
        Write-Host "`n📋 实时日志 (Ctrl+C 退出):" -ForegroundColor Cyan
        npx pm2 logs
    }
    
    "monit" {
        Write-Host "`n📈 启动监控界面..." -ForegroundColor Cyan
        npx pm2 monit
    }
    
    "delete" {
        Write-Host "`n🗑️ 删除所有PM2服务..." -ForegroundColor Red
        npx pm2 delete all
        Write-Host "`n✅ 所有PM2服务已删除!" -ForegroundColor Green
    }
}

Write-Host "`n=== 可用命令 ===" -ForegroundColor Yellow
Write-Host ".\pm2-manager.ps1 start    - 启动所有服务"
Write-Host ".\pm2-manager.ps1 stop     - 停止所有服务"
Write-Host ".\pm2-manager.ps1 restart  - 重启所有服务"
Write-Host ".\pm2-manager.ps1 status   - 查看状态和端口"
Write-Host ".\pm2-manager.ps1 logs     - 查看实时日志"
Write-Host ".\pm2-manager.ps1 monit    - 打开监控界面"
Write-Host ".\pm2-manager.ps1 delete   - 删除所有服务"