# 前端启动脚本 - 隐藏窗口模式
# 设置错误处理
$ErrorActionPreference = "Stop"

try {
    # 设置Node.js环境
    $env:PATH = "C:\Program Files\nodejs;" + $env:PATH
    
    # 切换到前端目录
    $projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
    $frontendPath = Join-Path $projectRoot "frontend"
    Set-Location $frontendPath
    
    Write-Host "启动前端服务..." -ForegroundColor Green
    Write-Host "前端目录: $frontendPath" -ForegroundColor Cyan
    Write-Host "时间: $(Get-Date)" -ForegroundColor Cyan
    
    # 启动前端开发服务器
    & npm run dev
    
} catch {
    Write-Error "前端启动失败: $($_.Exception.Message)"
    exit 1
}
