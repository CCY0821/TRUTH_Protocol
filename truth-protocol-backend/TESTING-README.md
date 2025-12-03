# Testing Guide - TRUTH Protocol Backend

本指南提供了测试和诊断登录问题的完整流程。

## 快速开始

### 1. 创建测试用户

运行以下命令创建管理员测试账号：

```powershell
.\create-test-user.ps1
```

这将在数据库中创建一个测试账号：
- **Email**: `admin@truthprotocol.com`
- **Password**: `admin123`
- **Role**: `ADMIN`
- **Credits**: `1000.00`

### 2. 启动后端服务器

```powershell
.\start-dev.ps1
```

### 3. 测试登录

```powershell
.\test-login.ps1
```

## 可用的测试脚本

### create-test-user.ps1
创建测试管理员账号（直接写入数据库）

**特点**：
- 使用正确的 BCrypt 密码哈希
- 自动删除已存在的用户
- 提供清晰的错误信息

**使用场景**：
- 首次设置测试环境
- 重置测试账号密码

### create-test-user-via-api.ps1
通过注册API创建测试用户

**特点**：
- 使用后端的注册API
- 确保密码通过应用程序正确哈希
- 包含登录测试

**使用场景**：
- 测试注册API功能
- 验证密码哈希逻辑
- 需要后端服务器运行

### diagnose-login.ps1
诊断和修复登录问题

**特点**：
- 检查数据库中的密码哈希
- 自动修复密码哈希问题
- 提供详细的诊断信息

**使用场景**：
- 登录失败时的第一步诊断
- 验证密码哈希格式
- 重置测试账号

### test-login.ps1
测试登录功能

**特点**：
- 检查后端服务器状态
- 测试登录API
- 显示完整的JWT token
- 提供详细的错误诊断

**使用场景**：
- 验证登录功能
- 获取JWT token进行API测试
- 调试认证问题

### test-db-connection.ps1
测试数据库连接

**特点**：
- 验证PostgreSQL连接
- 显示数据库版本信息

**使用场景**：
- 验证数据库配置
- 排查连接问题

## 常见问题

### 问题1: 登录返回401 Unauthorized

**原因**：
- 密码哈希格式不正确
- 密码哈希算法不匹配
- 用户不存在

**解决方案**：
```powershell
# 运行诊断脚本
.\diagnose-login.ps1

# 或重新创建用户
.\create-test-user.ps1
```

### 问题2: 无法连接到后端

**原因**：
- 后端服务器未启动
- 端口8080被占用

**解决方案**：
```powershell
# 启动后端
.\start-dev.ps1

# 检查端口占用
netstat -ano | findstr :8080
```

### 问题3: 无法连接到数据库

**原因**：
- PostgreSQL未启动
- 数据库配置不正确
- 密码错误

**解决方案**：
```powershell
# 测试数据库连接
.\test-db-connection.ps1

# 检查PostgreSQL服务
Get-Service -Name postgresql*
```

### 问题4: BCrypt密码哈希问题

**说明**：
后端使用 `BCryptPasswordEncoder(10)` 来哈希和验证密码。

正确的 BCrypt 哈希格式：
```
$2a$10$N9qo8uLOickgx2ZMRZoMye/IY/lGhzzN7mIQGLJ9.OrVLWyJkzJVy
```

- `$2a$`: BCrypt算法版本
- `10$`: Cost factor (2^10 = 1024 rounds)
- 后续字符: Salt + Hash

**重要**:
- 绝不要在数据库中存储明文密码
- PowerShell脚本中需要转义 `$` 符号：使用 `` `$2a`$10... ``

## 技术细节

### 密码验证流程

1. **用户提交登录**:
   ```json
   POST /api/v1/auth/login
   {
     "email": "admin@truthprotocol.com",
     "password": "admin123"
   }
   ```

2. **AuthService.login()** 验证:
   ```java
   // AuthService.java:57
   if (!passwordEncoder.matches(rawPassword, user.getPasswordHash())) {
       throw new BadCredentialsException("Invalid credentials");
   }
   ```

3. **BCryptPasswordEncoder.matches()** 比对:
   - 从数据库哈希中提取salt
   - 使用相同salt哈希输入的密码
   - 比对两个哈希值

### 数据库Schema

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(60) NOT NULL,  -- BCrypt hash
    role VARCHAR(20) NOT NULL,
    kyc_status VARCHAR(20) NOT NULL,
    credits NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);
```

## 测试工作流程

### 完整测试流程

1. **设置环境**:
   ```powershell
   # 1. 测试数据库连接
   .\test-db-connection.ps1

   # 2. 创建测试用户
   .\create-test-user.ps1
   ```

2. **启动服务**:
   ```powershell
   # 启动后端
   .\start-dev.ps1
   ```

3. **测试登录**:
   ```powershell
   # 测试登录API
   .\test-login.ps1
   ```

4. **如果登录失败**:
   ```powershell
   # 诊断问题
   .\diagnose-login.ps1

   # 重新测试
   .\test-login.ps1
   ```

### API测试（使用JWT Token）

登录成功后，使用返回的token进行API调用：

```powershell
$token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# 示例: 获取用户信息
Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/me" `
    -Method Get `
    -Headers @{
        "Authorization" = "Bearer $token"
    }
```

## 支持

如果遇到其他问题，请检查：

1. **后端日志**: 查看 `truth-protocol-backend` 的控制台输出
2. **数据库日志**: 检查PostgreSQL日志
3. **网络**: 确保防火墙允许端口8080和5432

## 相关文件

- `AuthController.java` - 登录API控制器
- `AuthService.java` - 认证服务逻辑
- `SecurityConfig.java` - Spring Security配置
- `application.yml` - 应用配置
- `application-dev.yml` - 开发环境配置
