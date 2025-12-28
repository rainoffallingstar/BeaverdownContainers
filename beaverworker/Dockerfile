FROM fallingstar10/beavermake:latest

# 配置 pacman 并行下载
RUN sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# ===== 阶段 1: 基础依赖安装 =====
RUN pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed \
        wget \
        mariadb \
        mariadb-clients \
        imagemagick \
        poppler \
        libxtst \
        openssh \
        jdk-openjdk && \
    pacman -Sc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/* /tmp/*

# ===== 阶段 2: JupyterLab 安装 =====
RUN pacman -S --noconfirm jupyterlab && \
    pacman -Sc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/* /tmp/*

# ===== 阶段 2.5: 安装 Ark (Posit Dev) =====
RUN cd /tmp && \
    wget -q https://github.com/posit-dev/ark/releases/download/0.1.222/ark-0.1.222-linux-x64.zip && \
    unzip -q ark-0.1.222-linux-x64.zip && \
    mv ark /usr/bin/ && \
    chmod +x /usr/bin/ark && \
    ark --install && \
    rm -rf /tmp/ark*

# ===== 阶段 2.6: 安装 Air (Posit Dev) =====
RUN curl -LsSf https://github.com/posit-dev/air/releases/latest/download/air-installer.sh | sh && \
    rm -rf /tmp/*

# ===== 阶段 2.7: 复制用户管理脚本 =====
COPY add_user_interactive.sh /usr/local/bin/add-user
RUN chmod +x /usr/local/bin/add-user && rm -rf /tmp/*

# ===== 阶段 3: 简化的 R 包安装 =====
# 配置 CRAN 镜像
RUN mkdir -p /root/.R && \
    echo "options(repos = c(CRAN = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/'))" > /root/.Rprofile && \
    echo "options(download.file.method = 'libcurl')" >> /root/.Rprofile && \
    echo "options(timeout = 600)" >> /root/.Rprofile && \
    rm -rf /tmp/*

# 安装图形库依赖
RUN pacman -S --needed --noconfirm \
    cairo pango freetype2 libpng libjpeg-turbo libtiff && \
    pacman -Sc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/* /tmp/* && \
    R -e "pak::pak('r-lib/ragg', ask = FALSE)" && \
    rm -rf /tmp/Rtmp* /tmp/* /root/.cache/pak/* && \
    R -e "pak::cache_clean()"

# ===== 简化的 R 包：只保留组1、2、6 =====
# 组1: Shiny 和数据处理包
RUN R -e "pak::pkg_install(c( \
    'DT', 'shinyWidgets', 'shiny', 'bslib', 'optparse', 'openxlsx', \
    'XML', 'R6', 'yaml', 'glue', 'fs', 'png', 'reshape2', 'readxl', \
    'RColorBrewer', 'rjson', 'data.table', 'dbplyr' \
), upgrade = TRUE, ask = FALSE, dependencies = NA)" && \
    rm -rf /tmp/Rtmp* /tmp/* /root/.cache/pak/* && \
    R -e "pak::cache_clean()"

# 组2: 统计和可视化包
RUN R -e "pak::pkg_install(c( \
    'plotly', 'pROC', 'sva', 'sampling', 'pdftools', 'umap', \
    'gridExtra', 'ggpubr', 'tidyverse' \
), upgrade = TRUE, ask = FALSE, dependencies = NA)" && \
    rm -rf /tmp/Rtmp* /tmp/* /root/.cache/pak/* && \
    R -e "pak::cache_clean()"

# 组6: 机器学习包
RUN R -e "pak::pkg_install(c( \
    'mlr3verse' \
), upgrade = TRUE, ask = FALSE, dependencies = NA)" && \
    rm -rf /tmp/Rtmp* /tmp/* /root/.cache/pak/* && \
    R -e "pak::cache_clean()"

# 组7: R 语言服务器和代码质量工具
RUN R -e "pak::pkg_install(c( \
    'languageserver', \
    'lintr' \
), upgrade = TRUE, ask = FALSE, dependencies = NA)" && \
    rm -rf /tmp/Rtmp* /tmp/* /root/.cache/pak/* && \
    R -e "pak::cache_clean()"

# ===== 阶段 4: 创建 fallingstar10 用户 =====
RUN useradd -m -s /bin/bash fallingstar10 && \
    echo "fallingstar10:fallingstar10" | chpasswd && \
    echo "fallingstar10 ALL=(ALL) ALL" >> /etc/sudoers && \
    rm -rf /tmp/*

# ===== 阶段 5: SSH 配置 =====
RUN mkdir -p /var/run/sshd && \
    mkdir -p /home/fallingstar10/.ssh && \
    chown -R fallingstar10:fallingstar10 /home/fallingstar10/.ssh && \
    chmod 700 /home/fallingstar10/.ssh && \
    rm -rf /tmp/*

RUN cat > /etc/ssh/sshd_config <<'EOF' && rm -rf /tmp/*
Port 2222
Protocol 2
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

RUN cat > /home/fallingstar10/.ssh/authorized_keys <<'EOF' && rm -rf /tmp/*
# Add your SSH public keys here
# Format: ssh-rsa AAAAB3NzaC1yc2E... yourname@yourhost
EOF
RUN chown fallingstar10:fallingstar10 /home/fallingstar10/.ssh/authorized_keys && \
    chmod 600 /home/fallingstar10/.ssh/authorized_keys

# ===== 阶段 6: 全局安装 Claude Code =====
RUN npm install -g @anthropic-ai/claude-code && \
    npm cache clean --force && \
    rm -rf /tmp/* /root/.npm /root/.node_modules

# ===== 阶段 7: 环境变量配置 =====
ENV PATH=/opt/micromamba/bin:/home/fallingstar10/.cargo/bin:/home/fallingstar10/.local/bin:/home/fallingstar10/go/bin:/root/.cargo/bin:/root/.local/bin:/root/go/bin:$PATH \
    GOPATH=/home/fallingstar10/go \
    CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 \
    JAVA_OPTS="-Djava.awt.headless=true" \
    R_PROGRESSR_ENABLE=TRUE \
    LANG=C.UTF-8 \
    NODE_PATH=/home/fallingstar10/.local/lib/node_modules:/root/.local/lib/node_modules

# Bash 配置
# root 配置
RUN echo "export PATH=/opt/micromamba/bin:\$HOME/.cargo/bin:\$HOME/.local/bin:\$HOME/go/bin:\$PATH" >> /root/.bashrc && \
    echo "export GOPATH=\$HOME/go" >> /root/.bashrc && \
    echo "source /opt/micromamba/etc/profile.d/micromamba.sh" >> /root/.bashrc && \
    rm -rf /tmp/*

# fallingstar10 配置（不自动初始化 Rust）
RUN echo "export PATH=/opt/micromamba/bin:\$HOME/.cargo/bin:\$HOME/.local/bin:\$HOME/go/bin:\$PATH" >> /home/fallingstar10/.bashrc && \
    echo "export GOPATH=\$HOME/go" >> /home/fallingstar10/.bashrc && \
    echo "source /opt/micromamba/etc/profile.d/micromamba.sh" >> /home/fallingstar10/.bashrc && \
    chown fallingstar10:fallingstar10 /home/fallingstar10/.bashrc && \
    rm -rf /tmp/*

# ===== 阶段 8: 启动脚本 =====
RUN cat > /usr/local/bin/start-services.sh <<'EOF' && rm -rf /tmp/*
#!/bin/env bash
set -e

# 生成 SSH 主机密钥
for key in rsa ecdsa ed25519; do
    [ ! -f /etc/ssh/ssh_host_${key}_key ] && ssh-keygen -t $key -f /etc/ssh/ssh_host_${key}_key -N "" -q
done

echo "--- 启动 SSH 服务 ---"
/usr/sbin/sshd -D &
SSH_PID=$!

echo "--- 服务已启动 ---"
echo "SSH: ssh fallingstar10@localhost -p 2222 (密码: fallingstar10)"
echo ""
echo "JupyterLab 需要手动启动，使用以下命令："
echo "  su - fallingstar10 -c 'jupyter-lab --no-browser --allow-root --ip=* --port=8889 &'"
echo ""
echo "用户管理工具："
echo "  add-user          # 交互式创建新用户"
echo ""
echo "Claude Code: claude-code (已全局安装)"
echo "Rust 环境: 使用时需手动运行 source ~/.cargo/env"

# 等待 SSH 服务
trap 'kill -9 $SSH_PID 2>/dev/null' TERM INT QUIT
wait $SSH_PID
EOF

RUN chmod +x /usr/local/bin/start-services.sh

# ===== 阶段 9: 全局清理 =====
RUN pacman -Sc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/* \
           /home/builduser/.cache/* \
           /home/builduser/.cargo/registry/* \
           /tmp/* \
           /root/.cache/* \
           /root/.local/share/pak/* \
           /root/.local/share/pip/cache/*

# ===== 阶段 10: 环境暴露 =====
EXPOSE 2222 8889 8080 8787

# ===== 容器入口 =====
ENTRYPOINT ["/usr/local/bin/start-services.sh"]
