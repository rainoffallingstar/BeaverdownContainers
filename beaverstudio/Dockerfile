FROM fallingstar10/beaverworker:latest

# ============================================
# 阶段 1: 系统更新与基础依赖安装
# ============================================
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    boost-libs \
    pam \
    openssl \
    openssl-1.1 \
    sqlite \
    postgresql-libs \
    sudo \
    nodejs \
    npm \
    openssh

# ============================================
# 阶段 2: 使用 builduser 安装 RStudio Server
# ============================================
# 假设 builduser 已存在且配置了 sudo 和 yay
USER builduser
WORKDIR /home/builduser

# 安装 rstudio-server-bin（预编译版本，更快）
RUN yay -S --noconfirm rstudio-server-bin && yay -Scc --noconfirm

# ==========================================
# 阶段 3: 系统配置 (切换回 root)
# ==========================================
USER root

# 确保 rstudio-server 系统用户存在
RUN getent passwd rstudio-server || useradd -r -d /var/run/rstudio-server -s /bin/false rstudio-server

# 创建实际登录使用的用户 (fallingstar10)
RUN useradd -m -s /bin/bash fallingstar10 && \
    echo "fallingstar10:fallingstar10" | chpasswd && \
    echo "fallingstar10 ALL=(ALL) ALL" >> /etc/sudoers

# 安装 Node.js 全局工具
RUN npm install -g @anthropic-ai/claude-code @claude-cli/ccs && \
    npm cache clean --force

# [核心修复] 创建 RStudio 期望的 R 文档目录
RUN mkdir -p /usr/share/doc/R

# 配置 RStudio
RUN mkdir -p /etc/rstudio && \
    echo -e "www-port=8787\nwww-address=0.0.0.0\nrsession-which-r=/usr/bin/R" > /etc/rstudio/rserver.conf && \
    echo -e "[*]\nlog-level=info\nlogger-type=stderr" > /etc/rstudio/logging.conf

# 创建 RStudio 键盘绑定配置文件
RUN mkdir -p /etc/rstudio/keybindings && \
    echo '{}' > /etc/rstudio/keybindings/addins.json && \
    echo '{}' > /etc/rstudio/keybindings/editor_bindings.json && \
    echo '{}' > /etc/rstudio/keybindings/rstudio_bindings.json

# ==========================================
# SSH 配置
# ==========================================
RUN mkdir -p /var/run/sshd && \
    mkdir -p /home/fallingstar10/.ssh && \
    chown -R fallingstar10:fallingstar10 /home/fallingstar10/.ssh && \
    chmod 700 /home/fallingstar10/.ssh

# 配置 SSH
RUN cat > /etc/ssh/sshd_config <<'EOF'
Port 2222
Protocol 2
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
UsePAM yes
X11Forwarding no
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
UsePrivilegeSeparation yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# 为 fallingstar10 用户配置 SSH key
RUN cat > /home/fallingstar10/.ssh/authorized_keys <<'EOF'
# 在这里添加您的公钥
# 您可以在这个文件中添加您的 SSH 公钥
# 格式: ssh-rsa AAAAB3NzaC1yc2E... yourname@yourhost
EOF

RUN chown fallingstar10:fallingstar10 /home/fallingstar10/.ssh/authorized_keys && \
    chmod 600 /home/fallingstar10/.ssh/authorized_keys

# ==========================================
# 阶段 4: 启动脚本
# ==========================================
RUN cat > /usr/local/bin/start-services.sh <<'EOF'
#!/bin/bash
set -e

echo "--- 初始化环境 ---"
mkdir -p /var/run/rstudio-server /var/lib/rstudio-server
chown -R rstudio-server:rstudio-server /var/run/rstudio-server /var/lib/rstudio-server

# 清理旧数据库文件
rm -f /var/lib/rstudio-server/rstudio-os.sqlite
rm -f /var/lib/rstudio-server/secure-cookie-key

echo "--- 启动 SSH 服务 ---"
# 生成 SSH 主机密钥（如果不存在）
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N "" -q
fi
if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N "" -q
fi
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" -q
fi

# 启动 SSH 服务
/usr/sbin/sshd -D &
SSH_PID=$!
echo "SSH 服务已启动 (PID: $SSH_PID)"

echo "--- 检查依赖库 ---"
ldd /usr/lib/rstudio-server/bin/rserver | grep "not found" || echo "Library check passed."

echo "--- 启动 RStudio Server ---"
# 在后台启动 RStudio Server
/usr/lib/rstudio-server/bin/rserver --server-daemonize=0 --www-port=8787 &
RSTUDIO_PID=$!
echo "RStudio Server 已启动 (PID: $RSTUDIO_PID)"

echo "--- 所有服务已启动 ---"
echo "RStudio: http://localhost:8787 (用户: fallingstar10, 密码: fallingstar10)"
echo "SSH: ssh fallingstar10@localhost -p 2222 (密码: fallingstar10)"

# 等待所有服务
wait $SSH_PID $RSTUDIO_PID
EOF

RUN chmod +x /usr/local/bin/start-services.sh && \
    sed -i 's/\r$//' /usr/local/bin/start-services.sh

# ==========================================
# 阶段 5: 入口
# ==========================================
EXPOSE 8787
EXPOSE 8080
EXPOSE 2222
ENTRYPOINT ["/usr/local/bin/start-services.sh"]
