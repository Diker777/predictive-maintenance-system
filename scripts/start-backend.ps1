# 后端启动脚本 - 隐藏窗口模式
# 设置错误处理
$ErrorActionPreference = "Stop"

try {
    # 设置.NET环境
    $env:PATH = "C:\Program Files\dotnet;" + $env:PATH
    
    # 切换到项目根目录
    $projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
    Set-Location $projectRoot
    
    Write-Host "启动后端服务..." -ForegroundColor Green
    Write-Host "项目目录: $projectRoot" -ForegroundColor Cyan
    Write-Host "时间: $(Get-Date)" -ForegroundColor Cyan
    
    # 启动.NET应用
    & dotnet run --project PredictiveMaintenance.Api --urls "http://localhost:5219"
    
} catch {
    Write-Error "后端启动失败: $($_.Exception.Message)"
    exit 1
}
