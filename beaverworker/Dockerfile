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
        openssh && \
    pacman -Sc --noconfirm

# ===== 阶段 2: JupyterLab 安装 =====
RUN pacman -S --noconfirm jupyterlab && pacman -Sc --noconfirm

# ===== 阶段 3: R 包安装 =====
# 配置 CRAN 镜像
RUN mkdir -p /root/.R && \
    echo "options(repos = c(CRAN = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/'))" > /root/.Rprofile && \
    echo "options(download.file.method = 'libcurl')" >> /root/.Rprofile && \
    echo "options(timeout = 600)" >> /root/.Rprofile

# 安装图形库依赖
RUN pacman -S --needed --noconfirm cairo pango freetype2 libpng libjpeg-turbo libtiff && \
    R -e "pak::pak('r-lib/ragg', ask = FALSE)"

# 批量安装 R 包
# 组1: Shiny 和数据处理包
RUN R -e "pak::pkg_install(c( \
    'DT', 'shinyWidgets', 'shiny', 'bslib', 'optparse', 'openxlsx', \
    'XML', 'R6', 'yaml', 'glue', 'fs', 'png', 'reshape2', 'readxl', \
    'RColorBrewer', 'rjson', 'data.table', 'dbplyr' \
), upgrade = TRUE, ask = FALSE, dependencies = NA)"

# 组2: 统计和可视化包
RUN R -e "pak::pkg_install(c( \
    'plotly', 'pROC', 'sva', 'sampling', 'pdftools', 'umap', \
    'gridExtra', 'ggpubr', 'tidyverse' \
), upgrade = TRUE, ask = FALSE, dependencies = NA)"

# 组3: 生物信息学核心包
RUN R -e "pak::pkg_install(c( \
    'Rsamtools', 'rtracklayer', 'GenomicRanges', \
    'SummarizedExperiment', 'BSgenome', 'BSgenome.Hsapiens.UCSC.hg19', \
    'bsseq', 'limma' \
), upgrade = TRUE, ask = FALSE, dependencies = NA)"

# 组4: 富集分析和通路包
RUN R -e "pak::pkg_install(c( \
    'clusterProfiler', 'org.Hs.eg.db', 'msigdbr', 'KEGGREST', \
    'GSVA', 'graphite', 'igraph', 'ggraph', 'KEGGgraph' \
), upgrade = TRUE, ask = FALSE, dependencies = NA)"

# 组5: 高级分析包
RUN R -e "pak::pkg_install(c( \
    'NOISeq', 'reticulate', 'TCGAbiolinks', 'GenomicDataCommons', \
    'doParallel', 'foreach', 'doMC', 'Seurat', 'xlsx' \
), upgrade = TRUE, ask = FALSE, dependencies = NA)"

# 组6: 机器学习包
RUN R -e "pak::pkg_install(c( \
    'mlr3verse' \
), upgrade = TRUE, ask = FALSE, dependencies = NA)"

# 安装 GitHub 包（带容错）
RUN R -e "tryCatch(pak::pak('NKI-GCF/XenofilteR', ask = FALSE), error = function(e) message('XenofilteR installation failed'))" && \
    R -e "tryCatch(pak::pak('CompEpigen/scMethrix', ask = FALSE), error = function(e) message('scMethrix installation failed'))" && \
    R -e "tryCatch(pak::pak('CompEpigen/methrix', ask = FALSE), error = function(e) message('methrix installation failed'))"

# 安装开发工具
RUN R -e "pak::pak('devtools', ask = FALSE)"

# 清理缓存
RUN R -e "pak::cache_clean()" && \
    rm -rf /tmp/* /root/.cache/* /root/.local/share/pak

# ===== 阶段 4: 创建 fallingstar10 用户 =====
RUN useradd -m -s /bin/bash fallingstar10 && \
    echo "fallingstar10:fallingstar10" | chpasswd && \
    echo "fallingstar10 ALL=(ALL) ALL" >> /etc/sudoers

# ===== 阶段 5: SSH 配置 =====
RUN mkdir -p /var/run/sshd && \
    mkdir -p /home/fallingstar10/.ssh && \
    chown -R fallingstar10:fallingstar10 /home/fallingstar10/.ssh && \
    chmod 700 /home/fallingstar10/.ssh

RUN cat > /etc/ssh/sshd_config <<'EOF'
Port 2222
Protocol 2
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

RUN cat > /home/fallingstar10/.ssh/authorized_keys <<'EOF'
# Add your SSH public keys here
# Format: ssh-rsa AAAAB3NzaC1yc2E... yourname@yourhost
EOF
RUN chown fallingstar10:fallingstar10 /home/fallingstar10/.ssh/authorized_keys && \
    chmod 600 /home/fallingstar10/.ssh/authorized_keys

# ===== 阶段 6: 全局安装 Claude Code =====
RUN npm install -g @anthropic-ai/claude-code && \
    npm cache clean --force

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
    echo "source /opt/micromamba/etc/profile.d/micromamba.sh" >> /root/.bashrc

# fallingstar10 配置（不自动初始化 Rust）
RUN echo "export PATH=/opt/micromamba/bin:\$HOME/.cargo/bin:\$HOME/.local/bin:\$HOME/go/bin:\$PATH" >> /home/fallingstar10/.bashrc && \
    echo "export GOPATH=\$HOME/go" >> /home/fallingstar10/.bashrc && \
    echo "source /opt/micromamba/etc/profile.d/micromamba.sh" >> /home/fallingstar10/.bashrc && \
    chown fallingstar10:fallingstar10 /home/fallingstar10/.bashrc

# ===== 阶段 8: 启动脚本 =====
RUN cat > /usr/local/bin/start-services.sh <<'EOF'
#!/bin/env bash
set -e

# 生成 SSH 主机密钥
for key in rsa ecdsa ed25519; do
    [ ! -f /etc/ssh/ssh_host_${key}_key ] && ssh-keygen -t $key -f /etc/ssh/ssh_host_${key}_key -N "" -q
done

echo "--- 启动 SSH 服务 ---"
/usr/sbin/sshd -D &
SSH_PID=$!

echo "--- 启动 JupyterLab ---"
su - fallingstar10 -c "jupyter-lab --no-browser --allow-root --ip=* --port=8889" &
JUPYTER_PID=$!

echo "--- 所有服务已启动 ---"
echo "SSH: ssh fallingstar10@localhost -p 2222 (密码: fallingstar10)"
echo "JupyterLab: http://localhost:8889"
echo "备用端口: 8080, 8787 (可用于其他服务)"
echo "Claude Code: claude-code (已全局安装)"
echo "Rust 环境: 使用时需手动运行 source ~/.cargo/env"

# 等待所有服务
trap 'kill -9 $SSH_PID $JUPYTER_PID 2>/dev/null' TERM INT QUIT
wait $SSH_PID $JUPYTER_PID
EOF

RUN chmod +x /usr/local/bin/start-services.sh

# ===== 阶段 9: 端口暴露 =====
EXPOSE 2222 8889 8080 8787

# ===== 容器入口 =====
ENTRYPOINT ["/usr/local/bin/start-services.sh"]
