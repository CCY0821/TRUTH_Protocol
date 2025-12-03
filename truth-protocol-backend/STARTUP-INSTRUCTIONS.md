# 如何启动 TRUTH Protocol 后端

## 方法 1: 使用 PowerShell 脚本（推荐）

在 PowerShell 终端中运行：

```powershell
cd C:\Users\G512LV\TRUTH_Protocol\truth-protocol-backend
.\start-dev.ps1
```

**注意**: 保持这个终端窗口打开，服务器会在这里运行。

## 方法 2: 直接使用 Gradle

如果脚本不工作，可以直接使用 Gradle：

```powershell
cd C:\Users\G512LV\TRUTH_Protocol\truth-protocol-backend

# 设置环境变量
$env:SPRING_PROFILES_ACTIVE = "dev"
$env:DB_PASSWORD = "55662211@@@"
$env:JWT_SECRET = "WW91clN1cGVyU2VjcmV0S2V5Rm9yRGV2ZWxvcG1lbnRPbmx5Tm90Rm9yUHJvZHVjdGlvbjEyMzQ1Njc4OQ=="
$env:POLYGON_RPC_URL = "https://polygon-rpc.com"
$env:POLYGON_CHAIN_ID = "80001"

# 启动服务器
.\gradlew.bat bootRun
```

## 方法 3: 使用 IDE（IntelliJ IDEA / Eclipse）

1. 在 IDE 中打开项目
2. 找到 `TruthProtocolApplication.java`
3. 设置环境变量（Run Configuration）：
   - `SPRING_PROFILES_ACTIVE=dev`
   - `DB_PASSWORD=55662211@@@`
   - `JWT_SECRET=WW91clN1cGVyU2VjcmV0S2V5Rm9yRGV2ZWxvcG1lbnRPbmx5Tm90Rm9yUHJvZHVjdGlvbjEyMzQ1Njc4OQ==`
4. 运行主类

## 验证启动成功

打开新的 PowerShell 窗口，运行：

```powershell
# 检查健康状态
Invoke-RestMethod -Uri "http://localhost:8080/actuator/health"

# 或使用 curl
curl http://localhost:8080/actuator/health
```

应该看到：
```json
{
  "status": "UP"
}
```

## 启动后测试登录

在新的 PowerShell 窗口运行：

```powershell
cd C:\Users\G512LV\TRUTH_Protocol\truth-protocol-backend

# 1. 创建测试用户
.\diagnose-login.ps1

# 2. 测试登录
.\test-login.ps1
```

## 常见启动问题

### 问题 1: 端口 8080 已被占用

**错误信息**: `Port 8080 is already in use`

**解决方案**:
```powershell
# 查找占用端口的进程
netstat -ano | findstr :8080

# 终止进程（使用上面命令找到的 PID）
taskkill /PID <PID> /F
```

### 问题 2: 无法连接数据库

**错误信息**: `Connection refused` 或 `database "postgres" does not exist`

**解决方案**:
```powershell
# 检查 PostgreSQL 服务
Get-Service -Name postgresql*

# 如果未运行，启动它
Start-Service -Name postgresql-x64-*

# 测试连接
.\test-db-connection.ps1
```

### 问题 3: Gradle 构建失败

**错误信息**: `BUILD FAILED`

**解决方案**:
```powershell
# 清理并重新构建
.\gradlew.bat clean build

# 如果还是失败，删除缓存
Remove-Item -Recurse -Force .gradle
Remove-Item -Recurse -Force build
.\gradlew.bat build
```

## 查看日志

启动后，日志会在终端显示。注意以下关键信息：

✅ **成功启动的标志**:
```
Started TruthProtocolApplication in X.XXX seconds
Tomcat started on port 8080 (http)
```

❌ **失败的标志**:
```
Failed to configure a DataSource
Error creating bean with name 'entityManagerFactory'
Port 8080 is already in use
```

## 停止服务器

在运行服务器的终端窗口中：
- 按 `Ctrl + C` 停止服务器

## 开发模式特性

使用 `dev` profile 时，后端包含以下配置：

- 数据库: PostgreSQL @ localhost:5432
- 日志级别: DEBUG（更详细的日志）
- CORS: 允许所有来源（开发用）
- JWT Token: 24小时过期
- Actuator: 健康检查端点启用

## 下一步

服务器启动后：

1. ✅ 测试登录: `.\test-login.ps1`
2. 📱 测试 Flutter 应用连接
3. 🔍 查看 API 文档: http://localhost:8080/swagger-ui.html
4. ❤️ 检查健康状态: http://localhost:8080/actuator/health

---

**需要帮助?** 检查终端日志中的错误信息，或运行诊断脚本。
