# ADD_USER.sh - 完整功能用户管理脚本

## 概述

ADD_USER.sh 是一个完整的用户管理脚本，完全复制了 beaverstudio 容器中 `fallingstar10` 用户的所有配置。创建的用户将与 fallingstar10 在功能上完全相同。

## 核心功能

### ✅ 完全复制 fallingstar10 配置

1. **用户创建**: `useradd -m -s /bin/bash username`
2. **密码设置**: `echo "username:username" | chpasswd` (默认密码与用户名相同)
3. **Sudo 权限**: `username ALL=(ALL) ALL` 在 `/etc/sudoers.d/username`
4. **RStudio 组**: `usermod -a -G rstudio-server username`
5. **SSH 配置**: 完整的 `.ssh` 目录结构和权限
6. **主目录**: 基本目录结构和 `.bashrc` 配置

## 使用方法

### 命令行选项

```bash
./ADD_USER.sh [OPTIONS] <username>

选项:
    -c, --create         创建新用户（如果不存在）
    -p, --password PASS  设置密码（默认：与用户名相同）
    -s, --shell SHELL    设置shell（默认：/bin/bash）
    --no-sudo           不授予sudo访问权限
    --no-ssh            不配置SSH访问
    --no-home           不创建主目录结构
    -f, --force         覆盖现有配置
    -h, --help          显示帮助信息
```

### 使用示例

#### 1. 创建新用户（完整配置）
```bash
./ADD_USER.sh -c newuser
```
创建名为 `newuser` 的新用户，复制 fallingstar10 的所有配置。

#### 2. 为现有用户添加 RStudio 访问
```bash
./ADD_USER.sh existinguser
```
仅为现有用户添加 rstudio-server 组成员身份。

#### 3. 创建受限用户（无sudo权限）
```bash
./ADD_USER.sh -c --no-sudo limiteduser
```
创建用户但不授予 sudo 权限。

#### 4. 创建具有自定义密码的用户
```bash
./ADD_USER.sh -c -p MySecurePass123 secureuser
```
创建用户并设置自定义密码。

#### 5. 强制更新现有用户配置
```bash
./ADD_USER.sh -f username
```
强制覆盖现有的 SSH 和主目录配置。

## 配置详情

### 用户账户配置

| 配置项 | fallingstar10 模式 | ADD_USER.sh 实现 |
|--------|-------------------|------------------|
| 用户创建 | `useradd -m -s /bin/bash` | ✅ 完全相同 |
| 密码设置 | `echo "username:username" \| chpasswd` | ✅ 完全相同 |
| Shell | `/bin/bash` | ✅ 完全相同 |
| 主目录 | `/home/username` | ✅ 完全相同 |

### 权限和访问

| 配置项 | fallingstar10 模式 | ADD_USER.sh 实现 |
|--------|-------------------|------------------|
| Sudo 权限 | `username ALL=(ALL) ALL` | ✅ 完全相同 |
| RStudio 访问 | `rstudio-server` 组成员 | ✅ 完全相同 |
| SSH 目录 | `mkdir -p ~/.ssh` (700权限) | ✅ 完全相同 |
| authorized_keys | 模板文件 (600权限) | ✅ 完全相同 |

### SSH 配置

创建的 SSH 配置包括：
```
/home/username/.ssh/
├── authorized_keys (600权限)
└── . (700权限)
```

authorized_keys 文件包含与 fallingstar10 相同的中文注释模板：
```bash
# 在这里添加您的公钥
# 您可以在这个文件中添加您的 SSH 公钥
# 格式: ssh-rsa AAAAB3NzaC1yc2E... yourname@yourhost
```

### 主目录结构

创建的标准目录结构：
```
/home/username/
├── Documents/
├── Downloads/
├── Desktop/
└── .bashrc
```

.bashrc 文件包含：
- Conda 环境自动激活
- 自定义提示符
- 欢迎消息
- beaverworker 环境支持

## 验证功能

脚本包含全面的配置验证：

- ✅ 用户账户存在性检查
- ✅ 主目录存在性验证
- ✅ rstudio-server 组成员身份验证
- ✅ SSH 目录权限检查 (700)
- ✅ authorized_keys 权限检查 (600)
- ✅ Sudo 配置文件验证

## 输出示例

### 成功创建用户
```
=== Enhanced User Management for Beaverstudio ===
Creating user with identical configuration to fallingstar10

[INFO] Starting user configuration process...
[INFO] Validating environment...
[SUCCESS] Environment validation passed
[INFO] Creating user: newuser
[SUCCESS] User 'newuser' created successfully
[INFO] Setting password for user: newuser
[SUCCESS] Password set successfully
[INFO] Configuring sudo access for user: newuser
[SUCCESS] Sudo access configured successfully
[INFO] Adding user 'newuser' to rstudio-server group
[SUCCESS] User 'newuser' added to rstudio-server group successfully
[INFO] Configuring SSH access for user: newuser
[SUCCESS] SSH configuration completed
[INFO] Remember to add your SSH public keys to: /home/newuser/.ssh/authorized_keys
[INFO] Setting up home directory for user: newuser
[SUCCESS] Home directory setup completed
[INFO] Validating user configuration...
[SUCCESS] User account exists
[SUCCESS] Home directory exists
[SUCCESS] User in rstudio-server group
[SUCCESS] SSH directory permissions correct (700)
[SUCCESS] SSH authorized_keys permissions correct (600)
[SUCCESS] Sudo configuration valid
[SUCCESS] All validations passed successfully

=== User Configuration Summary ===

Username: newuser
Home Directory: /home/newuser
Shell: /bin/bash

Configuration Status:
✓ User creation: Completed
✓ Password setting: Completed
✓ Sudo access: Enabled
✓ RStudio access: Enabled
✓ SSH configuration: Enabled
✓ Home directory: Setup completed

Access Information:
- RStudio Server: http://localhost:8787
- SSH Access: ssh newuser@localhost -p 2222

Next Steps:
1. Add SSH public keys to: /home/newuser/.ssh/authorized_keys
2. Test RStudio access at: http://localhost:8787
3. Test SSH access: ssh newuser@localhost -p 2222

=== Configuration Complete ===

[SUCCESS] User configuration completed successfully!
```

## 错误处理

脚本包含全面的错误处理：

- ✅ 必须以 root 权限运行
- ✅ 验证 beaverstudio 环境 (rstudio-server 组存在)
- ✅ 用户名格式验证
- ✅ Shell 存在性检查
- ✅ 每个操作步骤的错误捕获
- ✅ 详细的错误消息和建议

## 安全特性

- **Sudo 验证**: 使用 `visudo -cf` 验证 sudoers 配置
- **权限强制**: 严格的 SSH 目录权限控制 (700/600)
- **用户验证**: 用户名格式和存在性检查
- **错误回滚**: 失败时清理部分配置

## 使用场景

### 开发环境
```bash
# 为开发者创建完整账户
./ADD_USER.sh -c developer
```

### 临时访问
```bash
# 为临时用户提供 RStudio 访问
./ADD_USER.sh -c --no-sudo tempuser
```

### 批量用户管理
```bash
# 脚本化批量创建
for user in alice bob charlie; do
    ./ADD_USER.sh -c $user
done
```

## 注意事项

1. **环境要求**: 必须在 beaverstudio 容器中运行
2. **权限要求**: 需要 root 权限执行
3. **用户唯一性**: 用户名不能重复
4. **密码策略**: 建议使用强密码
5. **SSH 密钥**: 创建后需要手动添加 SSH 公钥

## 完整性保证

使用 ADD_USER.sh 创建的用户与 fallingstar10 具有以下完全相同的特性：

- ✅ **相同的使用体验**: RStudio、SSH、终端访问
- ✅ **相同的权限级别**: Sudo、文件访问
- ✅ **相同的配置**: Shell、环境、路径
- ✅ **相同的安全性**: SSH 配置、权限设置

这确保了在 beaverstudio 容器中，通过脚本创建的用户与默认的 fallingstar10 用户在使用体验上完全一致。