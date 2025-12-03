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
    sudo

# ============================================
# 阶段 2: 使用 builduser 安装 RStudio Server
# ============================================
# 假设 builduser 已存在且配置了 sudo 和 yay
USER builduser
WORKDIR /home/builduser

# 安装 rstudio-server-bin（预编译版本，更快）
RUN yay -S --noconfirm rstudio-server-bin && yay -Scc --noconfirm

# ==========================================
# 3. 系统配置 (切换回 root)
# ==========================================
USER root

# 确保 rstudio-server 系统用户存在
RUN getent passwd rstudio-server || useradd -r -d /var/run/rstudio-server -s /bin/false rstudio-server

# 创建实际登录使用的用户 (fallingstar10)
RUN useradd -m -s /bin/bash fallingstar10 && \
    echo "fallingstar10:fallingstar10" | chpasswd && \
    echo "fallingstar10 ALL=(ALL) ALL" >> /etc/sudoers

# [核心修复] 创建 RStudio 期望的 R 文档目录
RUN mkdir -p /usr/share/doc/R

# 配置 RStudio
RUN mkdir -p /etc/rstudio && \
    echo -e "www-port=8787\nwww-address=0.0.0.0\nrsession-which-r=/usr/bin/R" > /etc/rstudio/rserver.conf && \
    echo -e "[*]\nlog-level=info\nlogger-type=stderr" > /etc/rstudio/logging.conf

# ==========================================
# 4. 启动脚本
# ==========================================
RUN cat > /usr/local/bin/start-rstudio.sh <<'EOF'
#!/bin/bash
set -e

echo "--- 初始化环境 ---"
mkdir -p /var/run/rstudio-server /var/lib/rstudio-server
chown -R rstudio-server:rstudio-server /var/run/rstudio-server /var/lib/rstudio-server

# 清理旧数据库文件
rm -f /var/lib/rstudio-server/rstudio-os.sqlite
rm -f /var/lib/rstudio-server/secure-cookie-key

echo "--- 检查依赖库 ---"
ldd /usr/lib/rstudio-server/bin/rserver | grep "not found" || echo "Library check passed."

echo "--- 启动 RStudio Server ---"
exec /usr/lib/rstudio-server/bin/rserver --server-daemonize=0 --www-port=8787
EOF

RUN chmod +x /usr/local/bin/start-rstudio.sh && \
    sed -i 's/\r$//' /usr/local/bin/start-rstudio.sh

# ==========================================
# 5. 入口
# ==========================================
EXPOSE 8787
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/start-rstudio.sh"]