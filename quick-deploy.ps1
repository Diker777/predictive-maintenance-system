# 预测性维护系统 - 快速部署脚本
# 此脚本用于在全新机器上快速部署系统

param(
    [switch]$SkipDependencyCheck = $false,
    [switch]$InstallPM2 = $true
)

Write-Host "=== 预测性维护系统快速部署脚本 ===" -ForegroundColor Green
Write-Host "开始在新机器上部署系统..." -ForegroundColor Yellow

# 设置错误处理
$ErrorActionPreference = "Stop"

try {
    # 1. 检查系统要求
    Write-Host "`n📋 步骤1: 检查系统要求..." -ForegroundColor Cyan
    
    if (-not $SkipDependencyCheck) {
        # 检查PowerShell版本
        $psVersion = $PSVersionTable.PSVersion.Major
        if ($psVersion -lt 5) {
            throw "需要PowerShell 5.0或更高版本，当前版本: $psVersion"
        }
        Write-Host "✅ PowerShell版本检查通过: $($PSVersionTable.PSVersion)" -ForegroundColor Green
        
        # 检查.NET SDK
        try {
            $dotnetVersion = & dotnet --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ .NET SDK已安装: $dotnetVersion" -ForegroundColor Green
            } else {
                throw ".NET SDK未安装"
            }
        } catch {
            Write-Host "❌ 需要安装.NET 9.0 SDK" -ForegroundColor Red
            Write-Host "请从以下地址下载: https://dotnet.microsoft.com/download/dotnet/9.0" -ForegroundColor Yellow
            exit 1
        }
        
        # 检查Node.js
        try {
            $nodeVersion = & node --version 2>$null
            $npmVersion = & npm --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Node.js已安装: $nodeVersion" -ForegroundColor Green
                Write-Host "✅ npm已安装: $npmVersion" -ForegroundColor Green
            } else {
                throw "Node.js未安装"
            }
        } catch {
            Write-Host "❌ 需要安装Node.js" -ForegroundColor Red
            Write-Host "请从以下地址下载: https://nodejs.org/" -ForegroundColor Yellow
            exit 1
        }
    }
    
    # 2. 设置环境变量
    Write-Host "`n🔧 步骤2: 配置环境变量..." -ForegroundColor Cyan
    $env:PATH = "C:\Program Files\nodejs;" + $env:PATH
    Write-Host "✅ Node.js路径已添加到PATH" -ForegroundColor Green
    
    # 3. 创建必要目录
    Write-Host "`n📁 步骤3: 创建目录结构..." -ForegroundColor Cyan
    if (!(Test-Path "logs")) {
        New-Item -ItemType Directory -Force -Path "logs" | Out-Null
        Write-Host "✅ 创建logs目录" -ForegroundColor Green
    }
    
    # 4. 安装后端依赖
    Write-Host "`n📦 步骤4: 安装后端依赖..." -ForegroundColor Cyan
    Write-Host "正在清理并恢复.NET包..." -ForegroundColor Yellow
    & dotnet clean --verbosity quiet
    & dotnet restore --verbosity quiet
    
    Write-Host "正在构建后端项目..." -ForegroundColor Yellow
    & dotnet build --verbosity quiet
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 后端依赖安装成功" -ForegroundColor Green
    } else {
        throw "后端构建失败"
    }
    
    # 5. 安装前端依赖
    Write-Host "`n📦 步骤5: 安装前端依赖..." -ForegroundColor Cyan
    Push-Location "frontend"
    try {
        Write-Host "正在安装npm包..." -ForegroundColor Yellow
        & npm install --silent
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 前端依赖安装成功" -ForegroundColor Green
        } else {
            throw "前端依赖安装失败"
        }
    } finally {
        Pop-Location
    }
    
    # 6. 安装PM2
    if ($InstallPM2) {
        Write-Host "`n🚀 步骤6: 安装PM2进程管理器..." -ForegroundColor Cyan
        Write-Host "正在全局安装PM2..." -ForegroundColor Yellow
        & npm install -g pm2 --silent
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ PM2安装成功" -ForegroundColor Green
        } else {
            Write-Host "⚠️ PM2安装可能失败，但可以继续部署" -ForegroundColor Yellow
        }
    }
    
    # 7. 验证安装
    Write-Host "`n🔍 步骤7: 验证安装..." -ForegroundColor Cyan
    
    # 测试后端启动脚本
    if (Test-Path "scripts\start-backend.bat") {
        Write-Host "✅ 后端启动脚本存在" -ForegroundColor Green
    } else {
        Write-Host "❌ 后端启动脚本缺失" -ForegroundColor Red
    }
    
    # 测试前端启动脚本
    if (Test-Path "scripts\start-frontend.bat") {
        Write-Host "✅ 前端启动脚本存在" -ForegroundColor Green
    } else {
        Write-Host "❌ 前端启动脚本缺失" -ForegroundColor Red
    }
    
    # 测试PM2配置
    if (Test-Path "pm2.ecosystem.config.js") {
        Write-Host "✅ PM2配置文件存在" -ForegroundColor Green
    } else {
        Write-Host "❌ PM2配置文件缺失" -ForegroundColor Red
    }
    
    # 测试PM2管理脚本
    if (Test-Path "pm2-manager.ps1") {
        Write-Host "✅ PM2管理脚本存在" -ForegroundColor Green
    } else {
        Write-Host "❌ PM2管理脚本缺失" -ForegroundColor Red
    }
    
    # 8. 完成部署
    Write-Host "`n🎉 部署完成!" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== 下一步操作 ===" -ForegroundColor Yellow
    Write-Host "1. 启动服务:"
    Write-Host "   .\pm2-manager.ps1 start" -ForegroundColor White
    Write-Host ""
    Write-Host "2. 检查状态:"
    Write-Host "   .\pm2-manager.ps1 status" -ForegroundColor White
    Write-Host ""
    Write-Host "3. 访问应用:"
    Write-Host "   前端: http://localhost:5173" -ForegroundColor White
    Write-Host "   后端: http://localhost:5219" -ForegroundColor White
    Write-Host ""
    Write-Host "=== 可选操作 ===" -ForegroundColor Yellow
    Write-Host "查看日志: .\pm2-manager.ps1 logs" -ForegroundColor White
    Write-Host "监控界面: .\pm2-manager.ps1 monit" -ForegroundColor White
    Write-Host "重启服务: .\pm2-manager.ps1 restart" -ForegroundColor White
    Write-Host ""
    Write-Host "如需帮助，请查看 DEPLOYMENT.md 文档" -ForegroundColor Cyan
    
} catch {
    Write-Host "`n❌ 部署失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "=== 故障排除建议 ===" -ForegroundColor Yellow
    Write-Host "1. 检查所有依赖是否正确安装"
    Write-Host "2. 确认防火墙和网络设置"
    Write-Host "3. 查看详细的部署文档: DEPLOYMENT.md"
    Write-Host "4. 重新运行部署脚本: .\quick-deploy.ps1"
    exit 1
}
