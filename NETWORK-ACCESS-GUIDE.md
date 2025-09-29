# 🌐 外网访问配置指南

## 📋 当前状态
✅ 服务已配置为监听所有网络接口 (0.0.0.0)
✅ 后端端口: 5219
✅ 前端端口: 5173

## 🔧 手动防火墙配置（管理员权限）

### 方法1：使用Windows Defender防火墙图形界面

1. **打开Windows Defender防火墙**
   - 按 `Win + R`，输入 `wf.msc`，回车
   - 或搜索"Windows Defender 防火墙高级安全"

2. **添加入站规则**
   - 点击左侧"入站规则"
   - 点击右侧"新建规则..."
   - 选择"端口" → 下一步
   - 选择"TCP" → 特定本地端口 → 输入 `5219`
   - 选择"允许连接" → 下一步
   - 选择所有配置文件 → 下一步
   - 名称输入：`Predictive Maintenance Backend`
   - 完成

3. **重复添加前端规则**
   - 重复上述步骤，端口改为 `5173`
   - 名称改为：`Predictive Maintenance Frontend`

### 方法2：使用命令行（以管理员身份运行PowerShell）

```powershell
# 添加后端端口规则
netsh advfirewall firewall add rule name="Predictive Maintenance Backend" dir=in action=allow protocol=TCP localport=5219

# 添加前端端口规则  
netsh advfirewall firewall add rule name="Predictive Maintenance Frontend" dir=in action=allow protocol=TCP localport=5173
```

### 方法3：运行自动配置脚本

```powershell
# 右键点击PowerShell图标，选择"以管理员身份运行"
cd C:\预测性维护系统
.\setup-firewall.ps1
```

## 🌍 访问地址

### 您的可用IP地址：
- **198.18.0.1**
- **10.222.222.1** 
- **172.31.96.1**
- **10.99.69.78**
- **192.168.8.1**

### 访问URL示例：
```
前端界面:
- http://198.18.0.1:5173
- http://10.99.69.78:5173
- http://192.168.8.1:5173

后端API:
- http://198.18.0.1:5219
- http://10.99.69.78:5219
- http://192.168.8.1:5219

API文档:
- http://198.18.0.1:5219/swagger
- http://10.99.69.78:5219/swagger
- http://192.168.8.1:5219/swagger
```

## 🏠 路由器配置（外网访问）

如需从互联网访问，需配置路由器端口转发：

### 端口转发设置
1. 登录路由器管理界面
2. 找到"端口转发"或"虚拟服务器"设置
3. 添加以下规则：

| 服务名称 | 外部端口 | 内部IP | 内部端口 | 协议 |
|----------|----------|--------|----------|------|
| 预测维护前端 | 5173 | 192.168.x.x | 5173 | TCP |
| 预测维护后端 | 5219 | 192.168.x.x | 5219 | TCP |

### 获取公网IP
访问 http://whatismyip.com 获取您的公网IP地址

### 外网访问URL
```
前端: http://您的公网IP:5173
后端: http://您的公网IP:5219
API文档: http://您的公网IP:5219/swagger
```

## 🛡️ 安全注意事项

### 生产环境建议：
1. **启用HTTPS** - 使用SSL证书加密传输
2. **身份验证** - 添加登录认证机制
3. **访问控制** - 限制IP白名单
4. **定期更新** - 保持系统和依赖包更新

### 开发环境注意：
1. **网络安全** - 确保在可信网络环境
2. **数据备份** - 重要数据及时备份
3. **监控日志** - 定期检查访问日志

## 📞 故障排除

### 无法访问？检查以下项目：
1. ✅ PM2服务状态：`.\pm2-manager.ps1 status`
2. ✅ 端口监听：`netstat -an | findstr ":5219"`
3. ✅ 防火墙规则：Windows Defender防火墙设置
4. ✅ 网络连通性：`ping 目标IP`
5. ✅ 路由器设置：端口转发配置

### 测试命令：
```powershell
# 测试本机访问
curl http://localhost:5219/api/devices
curl http://localhost:5173

# 测试局域网访问（替换为实际IP）
curl http://192.168.x.x:5219/api/devices
curl http://192.168.x.x:5173
```

---

**配置完成后，您的预测性维护系统将支持从任何网络位置访问！** 🌐
