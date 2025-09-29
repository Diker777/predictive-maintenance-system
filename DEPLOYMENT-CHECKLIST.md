# 部署清单

## 📋 必需文件清单

在部署到新机器时，请确保以下文件和目录完整：

### ✅ 核心项目文件

#### 后端项目
- [ ] `PredictiveMaintenance.Api/` - 主API项目
- [ ] `PredictiveMaintenance.Application/` - 应用层
- [ ] `PredictiveMaintenance.Domain/` - 域模型层  
- [ ] `PredictiveMaintenance.Infrastructure/` - 基础设施层
- [ ] `PredictiveMaintenance.sln` - 解决方案文件

#### 前端项目
- [ ] `frontend/src/` - 源代码目录
- [ ] `frontend/public/` - 静态资源
- [ ] `frontend/package.json` - 依赖配置
- [ ] `frontend/package-lock.json` - 锁定版本
- [ ] `frontend/vite.config.ts` - 构建配置
- [ ] `frontend/tsconfig.json` - TypeScript配置

### ✅ 部署配置文件

#### PM2管理
- [ ] `pm2.ecosystem.config.js` - PM2进程配置
- [ ] `pm2-manager.ps1` - 统一管理脚本

#### 启动脚本
- [ ] `scripts/start-backend.bat` - 后端启动脚本
- [ ] `scripts/start-frontend.bat` - 前端启动脚本

#### 部署工具
- [ ] `quick-deploy.ps1` - 自动部署脚本
- [ ] `DEPLOYMENT.md` - 详细部署文档
- [ ] `DEPLOYMENT-CHECKLIST.md` - 本清单文件

### ✅ 文档文件
- [ ] `README.md` - 项目说明

### ⚠️ 自动创建的目录
以下目录会在首次运行时自动创建，无需手动复制：
- `logs/` - 日志目录
- `frontend/node_modules/` - npm包目录
- `*/bin/`, `*/obj/` - .NET构建目录

### ❌ 不需要的文件
以下文件不应包含在部署包中：
- `frontend/node_modules/` - 将通过npm install重新安装
- `*/bin/`, `*/obj/` - 构建时重新生成
- `logs/` - 运行时创建
- `.vs/` - Visual Studio临时文件
- `.git/` - Git版本控制（如果需要）

## 🔧 部署前检查

### 目标机器要求
- [ ] Windows 10/11 或 Windows Server 2019/2022
- [ ] PowerShell 5.0+
- [ ] .NET 9.0 SDK已安装
- [ ] Node.js LTS版本已安装
- [ ] 端口5173和5219未被占用
- [ ] 具有管理员权限（用于安装PM2）

### 网络要求
- [ ] 可以访问npm registry (npmjs.com)
- [ ] 可以访问NuGet registry (nuget.org)
- [ ] 防火墙允许端口5173和5219

## 🚀 快速部署流程

### 1. 文件传输
将项目目录完整复制到目标机器，建议路径：
```
C:\预测性维护系统\
```

### 2. 运行部署脚本
```powershell
cd C:\预测性维护系统
.\quick-deploy.ps1
```

### 3. 启动服务
```powershell
.\pm2-manager.ps1 start
```

### 4. 验证部署
```powershell
.\pm2-manager.ps1 status
```

检查两个服务都显示为"online"状态。

### 5. 测试访问
- 前端：http://localhost:5173
- 后端：http://localhost:5219

## 🛠️ 故障排除

### 常见问题检查
- [ ] Node.js是否正确添加到PATH
- [ ] .NET SDK版本是否正确
- [ ] 端口是否被其他程序占用
- [ ] 防火墙设置是否正确
- [ ] npm包安装是否成功
- [ ] .NET项目构建是否成功

### 日志查看
```powershell
# PM2日志
.\pm2-manager.ps1 logs

# 系统日志
type logs\backend-error.log
type logs\frontend-error.log
```

## 📞 支持

如果部署过程中遇到问题：
1. 查看 `DEPLOYMENT.md` 详细文档
2. 检查日志文件中的错误信息
3. 确认所有依赖正确安装
4. 重新运行部署脚本
