# 预测性维护系统 - 完整部署指南

## 📋 目录
- [系统要求](#系统要求)
- [环境安装](#环境安装)
- [项目部署](#项目部署)
- [服务配置](#服务配置)
- [启动服务](#启动服务)
- [验证部署](#验证部署)
- [故障排除](#故障排除)

## 🔧 系统要求

### 操作系统
- Windows 10/11 或 Windows Server 2019/2022
- PowerShell 5.0 或更高版本

### 硬件要求
- CPU: 2核心以上
- 内存: 4GB以上
- 硬盘: 10GB可用空间
- 网络: 可访问互联网（用于包下载）

## 🚀 环境安装

### 1. 安装 .NET 9.0 SDK

1. 访问 [.NET官网](https://dotnet.microsoft.com/download/dotnet/9.0)
2. 下载并安装 .NET 9.0 SDK (x64)
3. 验证安装：
   ```powershell
   dotnet --version
   # 应该显示: 9.0.xxx
   ```

### 2. 安装 Node.js 和 npm

1. 访问 [Node.js官网](https://nodejs.org/)
2. 下载并安装 LTS 版本 (推荐 v20.x 或更高)
3. **重要**: 安装时确保选择 "Add to PATH" 选项
4. 验证安装：
   ```powershell
   node --version
   npm --version
   # 应该显示对应版本号
   ```

### 3. 安装 SQL Server (可选)

如果需要持久化数据存储：
1. 安装 SQL Server Express 或完整版
2. 或使用 SQL Server LocalDB
3. 确保 SQL Server 服务正在运行

## 📦 项目部署

### 1. 获取项目文件

将整个项目目录复制到目标机器，例如：
```
C:\预测性维护系统\
```

### 2. 设置目录结构

确保以下目录结构完整：
```
C:\预测性维护系统\
├── PredictiveMaintenance.Api/          # 后端API项目
├── PredictiveMaintenance.Application/  # 应用层
├── PredictiveMaintenance.Domain/       # 域模型
├── PredictiveMaintenance.Infrastructure/ # 基础设施层
├── frontend/                           # 前端Vue项目
├── scripts/                            # 启动脚本
│   ├── start-backend.bat
│   └── start-frontend.bat
├── pm2.ecosystem.config.js             # PM2配置文件
├── pm2-manager.ps1                     # PM2管理脚本
└── logs/                               # 日志目录（自动创建）
```

### 3. 安装依赖

#### 后端依赖
```powershell
cd C:\预测性维护系统
dotnet restore
dotnet build
```

#### 前端依赖
```powershell
cd C:\预测性维护系统\frontend
npm install
```

#### PM2进程管理器
```powershell
npm install -g pm2
```

## ⚙️ 服务配置

### 1. 数据库配置

编辑 `PredictiveMaintenance.Api\appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=(localdb)\\MSSQLLocalDB;Initial Catalog=PredictiveMaintenanceDb;Integrated Security=True"
  }
}
```

### 2. 网络配置

确认防火墙设置允许以下端口：
- **5219**: 后端API端口
- **5173**: 前端开发服务器端口

### 3. 环境变量配置

在PowerShell中设置Node.js路径（如果PATH未正确配置）：
```powershell
$env:PATH = "C:\Program Files\nodejs;" + $env:PATH
```

## 🎯 启动服务

### 使用PM2管理器（推荐）

项目提供了完整的PM2管理脚本，支持一键操作：

#### 启动所有服务
```powershell
cd C:\预测性维护系统
.\pm2-manager.ps1 start
```

#### 其他管理命令
```powershell
# 查看服务状态
.\pm2-manager.ps1 status

# 查看实时日志
.\pm2-manager.ps1 logs

# 重启所有服务
.\pm2-manager.ps1 restart

# 停止所有服务
.\pm2-manager.ps1 stop

# 删除所有服务
.\pm2-manager.ps1 delete

# 打开监控界面
.\pm2-manager.ps1 monit
```

### 手动启动（调试用）

如果需要手动启动进行调试：

#### 后端
```powershell
cd C:\预测性维护系统
dotnet run --project PredictiveMaintenance.Api
```

#### 前端
```powershell
cd C:\预测性维护系统\frontend
npm run dev
```

## ✅ 验证部署

### 1. 检查服务状态
```powershell
.\pm2-manager.ps1 status
```

应该看到两个服务都显示为 "online" 状态。

### 2. 检查端口监听
```powershell
netstat -an | findstr ":5219"  # 后端端口
netstat -an | findstr ":5173"  # 前端端口
```

### 3. 访问应用

- **前端界面**: http://localhost:5173
- **后端API**: http://localhost:5219
- **API文档**: http://localhost:5219/swagger

### 4. 测试API连接

在浏览器中访问：
```
http://localhost:5219/api/devices
```

应该返回JSON格式的设备列表。

## 🔧 故障排除

### 常见问题

#### 1. Node.js命令找不到
**错误**: `npm: The term 'npm' is not recognized`

**解决方案**:
```powershell
# 方法1: 重新设置PATH
$env:PATH = "C:\Program Files\nodejs;" + $env:PATH

# 方法2: 使用完整路径
& "C:\Program Files\nodejs\npm.cmd" --version
```

#### 2. .NET构建失败
**错误**: `"N/A"不是有效的版本字符串`

**解决方案**:
```powershell
dotnet clean
dotnet restore
dotnet build
```

#### 3. 端口被占用
**错误**: `EADDRINUSE: address already in use`

**解决方案**:
```powershell
# 查找占用端口的进程
netstat -ano | findstr :5219
netstat -ano | findstr :5173

# 结束占用进程（替换PID）
taskkill /f /pid <PID>
```

#### 4. PM2服务启动失败
**解决方案**:
```powershell
# 查看详细日志
.\pm2-manager.ps1 logs

# 重置PM2
npx pm2 kill
.\pm2-manager.ps1 start
```

### 日志查看

#### PM2日志
```powershell
# 实时日志
.\pm2-manager.ps1 logs

# 历史日志文件
type logs\backend-out.log
type logs\frontend-out.log
type logs\backend-error.log
type logs\frontend-error.log
```

#### 应用日志
- 后端日志：`logs/` 目录下的文件
- 前端日志：浏览器开发者工具控制台

### 性能优化

#### PM2配置调优
编辑 `pm2.ecosystem.config.js` 中的以下参数：
- `max_memory_restart`: 内存重启阈值
- `max_restarts`: 最大重启次数
- `min_uptime`: 最小运行时间

#### 系统资源监控
```powershell
# 打开PM2监控界面
.\pm2-manager.ps1 monit
```

## 🚀 生产环境部署

### 1. 构建生产版本

#### 前端
```powershell
cd frontend
npm run build
```

#### 后端
```powershell
dotnet publish -c Release -o ./publish
```

### 2. IIS部署（可选）

如果需要使用IIS作为反向代理：
1. 安装IIS和ASP.NET Core模块
2. 配置应用程序池
3. 设置反向代理规则

### 3. Windows服务部署（可选）

可以将应用注册为Windows服务以实现开机自启：
```powershell
# 使用PM2的启动配置
npx pm2 startup
npx pm2 save
```

## 📞 技术支持

如果在部署过程中遇到问题，请检查：
1. 所有依赖是否正确安装
2. 端口是否被占用
3. 防火墙设置是否正确
4. 日志文件中的错误信息

---

## 📄 附录

### 重要文件说明

- `pm2.ecosystem.config.js`: PM2进程管理配置
- `pm2-manager.ps1`: 统一服务管理脚本
- `scripts/start-backend.bat`: 后端启动脚本
- `scripts/start-frontend.bat`: 前端启动脚本
- `appsettings.json`: 后端配置文件
- `package.json`: 前端依赖配置

### 默认端口

- 前端开发服务器: 5173
- 后端API: 5219
- SignalR Hub: 5219/hubs/alerts

### 文件权限

确保以下目录具有写入权限：
- `logs/` 目录
- `frontend/node_modules/` 目录
- 临时文件目录
