FROM archlinux:latest

# 并行编译配置
COPY makepkg.conf /etc/makepkg.conf

# 系统初始化
RUN pacman-key --init && pacman-key --populate archlinux && \
    pacman -Syu --noconfirm && \
    pacman -Scc --noconfirm

# 基础开发工具
RUN pacman -S --needed --noconfirm \
    base-devel git sudo nano openssh which wget curl \
    pigz pbzip2 cmake gcc-fortran fastfetch && \
    pacman -Scc --noconfirm

# 创建 builduser
RUN useradd -m builduser && \
    echo 'builduser ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/yay' > /etc/sudoers.d/builduser && \
    chmod 0440 /etc/sudoers.d/builduser

# 安装 yay
USER builduser
WORKDIR /tmp
RUN set -eux; \
    git config --global http.version HTTP/1.1; \
    for i in 1 2 3; do \
      if git clone --depth=1 https://aur.archlinux.org/yay-bin.git; then \
        break; \
      fi; \
      rm -rf yay-bin; \
      sleep "$((i * 2))"; \
    done; \
    if [ ! -d yay-bin ]; then \
      curl -fL --retry 5 --retry-delay 2 --connect-timeout 20 \
        -o yay-bin.tar.gz https://aur.archlinux.org/cgit/aur.git/snapshot/yay-bin.tar.gz; \
      tar -xzf yay-bin.tar.gz; \
    fi; \
    cd yay-bin; \
    makepkg -si --noconfirm; \
    cd /tmp; \
    rm -rf yay-bin yay-bin.tar.gz
WORKDIR /
USER root

# 安装 Python、R、Node.js、Go
RUN pacman -S --noconfirm python python-pip r nodejs npm go && \
    pacman -Sc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/* /tmp/* && \
    rm -rf /root/.cache/* /root/.local/share/pip/cache/*

# 安装 R pak 包管理器
RUN mkdir -p /root/.R && \
    echo "options(repos = c(CRAN = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/'))" > /root/.Rprofile && \
    R_LIBS=/usr/lib/R/library R -e "install.packages('pak', repos = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/')" && \
    rm -rf /tmp/Rtmp* /root/.R/pack/

# 配置 R：默认安装到用户目录，避免无权限写系统库
RUN RHOME="$(R RHOME)" && \
    mkdir -p /etc/R "$RHOME/etc" && \
    touch /etc/R/Renviron.site "$RHOME/etc/Renviron.site" && \
    grep -q '^R_LIBS_USER=' /etc/R/Renviron.site || \
      echo 'R_LIBS_USER=~/.local/share/R/%p-library/%V' >> /etc/R/Renviron.site && \
    grep -q '^R_LIBS_USER=' "$RHOME/etc/Renviron.site" || \
      echo 'R_LIBS_USER=~/.local/share/R/%p-library/%V' >> "$RHOME/etc/Renviron.site"

# 安装 micromamba（官方二进制，避免 AUR 网络抖动）
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64) mamba_arch='linux-64' ;; \
      aarch64|arm64) mamba_arch='linux-aarch64' ;; \
      *) echo "Unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fL --retry 5 --retry-delay 2 --connect-timeout 20 \
      "https://micro.mamba.pm/api/micromamba/${mamba_arch}/latest" -o /tmp/micromamba.tar.bz2; \
    mkdir -p /opt/micromamba/bin; \
    tar -xjf /tmp/micromamba.tar.bz2 -C /tmp bin/micromamba; \
    install -m 0755 /tmp/bin/micromamba /opt/micromamba/bin/micromamba; \
    rm -rf /tmp/micromamba.tar.bz2 /tmp/bin /root/.cache/* /tmp/*
# 验证 micromamba 安装
RUN /opt/micromamba/bin/micromamba --version

# 安装 Rust
RUN pacman -S --noconfirm rustup && \
    rustup default stable && \
    pacman -Sc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/* /tmp/*

# 配置环境变量
ENV GOPATH=/root/go
ENV PATH=/opt/micromamba/bin:/root/.cargo/bin:/root/.local/bin:/root/go/bin:$PATH

# 为 builduser 配置环境
RUN echo 'export PATH=/opt/micromamba/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH' >> /home/builduser/.bashrc && \
    echo 'export GOPATH=$HOME/go' >> /home/builduser/.bashrc

# 验证安装
RUN python --version && R --version && node --version && npm --version && \
    micromamba --version && rustc --version && cargo --version && go version

CMD ["/bin/bash"]
