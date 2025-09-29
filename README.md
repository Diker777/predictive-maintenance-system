# 预测性维护系统（.NET 9 + Vue 3 + ECharts/DataV）

一个基于阈值的预警系统：针对设备气缸行程时间、轴扭矩、速度等指标进行阈值判断并实时告警（SignalR）。

## 架构
- 后端：C# .NET 9 Web API + EF Core（支持 SQL Server / MySQL），SignalR 实时告警
- 前端：Vite + Vue 3（TypeScript），ECharts 可视化，DataV 装饰组件，SignalR 前端客户端
- 数据库：默认连接 SQL Server（`appsettings.json` 可切换到 MySQL）

## 本地运行
### 1) 准备环境
- .NET SDK 9（或兼容版本）
- Node.js LTS（已验证 npm 11.x）
- 数据库：
  - SQL Server（默认连接字符串：`Server=localhost;Database=PredictiveMaintenance;Trusted_Connection=True;TrustServerCertificate=True;`）
  - 或 MySQL（修改 `appsettings.json`：`Database.Provider` 改为 `MySql`，配置对应连接字符串）

### 2) 后端
```bash
# 终端1（项目根目录）
dotnet build
# 生成初始迁移（如未生成）
# dotnet tool install --global dotnet-ef
# dotnet ef migrations add InitialCreate -p PredictiveMaintenance.Infrastructure -s PredictiveMaintenance.Api -o Migrations
# 应用迁移并启动
 dotnet ef database update -p PredictiveMaintenance.Infrastructure -s PredictiveMaintenance.Api
 dotnet run --project PredictiveMaintenance.Api --urls http://localhost:5157
```
- 首次启动会：
  - 自动迁移（`Program.cs` 中已包含 `DbInitializer`）
  - 种子数据：2 台示例设备、若干阈值和读数
- Swagger：开发环境下可用（访问 `http://localhost:5157/swagger`）

### 3) 前端
```bash
# 终端2（frontend 目录）
npm install
npm run dev -- --host
# 打开 http://localhost:5173/
```
- 默认前端指向 API 地址：`http://localhost:5157`（可在 `src/components/Dashboard.vue` 顶部的 `apiBase` 更改，或使用 `VITE_API_BASE` 环境变量）

## 业务模型
- 设备 Device：`Id`, `Name`, `Description`
- 指标 MetricType：1=气缸行程时间（CylinderStrokeTime），2=轴扭矩（ShaftTorque），3=速度（Speed）
- 阈值 ThresholdRule：`Operator` 支持 `GreaterThan`、`GreaterThanOrEqual`、`LessThan`、`LessThanOrEqual`、`Between`
- 读数 SensorReading：`DeviceId`, `Metric`, `Value`, `TimestampUtc`
- 告警 Alert：规则触发后写入并通过 SignalR 推送到前端

## API 速览（关键）
- 设备
  - GET `api/devices`
  - GET `api/devices/{id}`
  - POST `api/devices`
- 读数
  - GET `api/readings?deviceId=...&metric=...&fromUtc=...&toUtc=...`
  - POST `api/readings`（提交读数并进行阈值评估，触发则写入告警并通过 SignalR 推送）
- 阈值
  - GET `api/thresholds?deviceId=...`
  - POST `api/thresholds`
- 告警
  - GET `api/alerts?deviceId=...&acknowledged=...`
  - POST `api/alerts/ack/{id}`
- SignalR Hub：`/hubs/alerts`（客户端事件名：`alerts`）

### 示例：触发一次气缸行程时间超限告警
1. 查询设备：GET `http://localhost:5157/api/devices`
2. 取第一台设备的 `id`，POST 读数：
```json
{
  "deviceId": "<设备Id>",
  "metric": 1,
  "value": 1.25,
  "timestampUtc": "2025-01-01T00:00:00.000Z"
}
```
3. 前端实时弹出告警；或 GET `http://localhost:5157/api/alerts?deviceId=<设备Id>` 查看历史告警

## 前端说明
- `frontend/src/components/Dashboard.vue`
  - 顶部工具栏：API 地址、设备选择、指标切换、快速创建 Between 阈值按钮
  - 趋势图：ECharts 折线图（时间序列）
  - 阈值表格：展示已配置阈值
  - 实时告警：SignalR 订阅 `alerts` 事件，滚动显示最新告警

## 切换数据库
- 修改 `PredictiveMaintenance.Api/appsettings.json`：
```json
"Database": {
  "Provider": "SqlServer", // 或 "MySql"
  "ConnectionStrings": {
    "SqlServer": "...",
    "MySql": "..."
  }
}
```
- 运行迁移：
```bash
dotnet ef database update -p PredictiveMaintenance.Infrastructure -s PredictiveMaintenance.Api
```

---

## 🚀 全新机器部署指南

### 一键自动部署（推荐）
1. 确保安装了 .NET 9.0 SDK 和 Node.js
2. 运行自动部署脚本：
```powershell
.\quick-deploy.ps1
```
3. 启动所有服务：
```powershell
.\pm2-manager.ps1 start
```

### PM2服务管理
```powershell
.\pm2-manager.ps1 status   # 查看服务状态和端口
.\pm2-manager.ps1 logs     # 查看实时日志
.\pm2-manager.ps1 restart  # 重启所有服务
.\pm2-manager.ps1 stop     # 停止所有服务
.\pm2-manager.ps1 monit    # 打开监控界面
```

### 访问地址
- **前端界面**: http://localhost:5173
- **后端API**: http://localhost:5219  
- **API文档**: http://localhost:5219/swagger

### 详细部署说明
完整的部署文档请参考：[DEPLOYMENT.md](./DEPLOYMENT.md)

---

## 项目文件说明

### 核心配置文件
- `pm2.ecosystem.config.js` - PM2进程管理配置
- `pm2-manager.ps1` - 统一服务管理脚本
- `quick-deploy.ps1` - 自动部署脚本
- `DEPLOYMENT.md` - 详细部署文档

### 启动脚本
- `scripts/start-backend.bat` - 后端启动脚本
- `scripts/start-frontend.bat` - 前端启动脚本

### 企业级特性
- ✅ PM2进程管理（自动重启、监控、日志）
- ✅ 完整的错误处理和日志记录
- ✅ 一键部署和服务管理
- ✅ 生产环境就绪

---
如需扩展复杂规则（如多指标联合、滑动窗口、统计学判定等），可在 `IThresholdEvaluator` 基础上新增策略实现。
