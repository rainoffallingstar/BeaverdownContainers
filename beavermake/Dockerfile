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
RUN git clone --depth=1 https://aur.archlinux.org/yay-bin.git && \
    cd yay-bin && makepkg -si --noconfirm && \
    cd .. && rm -rf yay-bin
WORKDIR /
USER root

# 安装 Python、R、Node.js、Go
RUN pacman -S --noconfirm python python-pip r nodejs npm go && \
    pacman -Scc --noconfirm

# 安装 R pak 包管理器
RUN mkdir -p /root/.R && \
    echo "options(repos = c(CRAN = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/'))" > /root/.Rprofile && \
    R -e "install.packages('pak', repos = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/')"

# 安装 micromamba（使用 yay）
USER builduser
WORKDIR /tmp
RUN yay -S --noconfirm micromamba && yay -Scc --noconfirm
WORKDIR /
USER root

# 安装 Rust
RUN pacman -S --noconfirm rustup && \
    rustup default stable

# 配置环境变量
ENV GOPATH=/root/go
ENV PATH=/opt/micromamba/bin:/root/.cargo/bin:/root/.local/bin:/root/go/bin:$PATH

# 为 builduser 配置环境
RUN echo 'export PATH=/opt/micromamba/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH' >> /home/builduser/.bashrc && \
    echo 'export GOPATH=$HOME/go' >> /home/builduser/.bashrc

# 验证安装
RUN python --version && R --version && node --version && npm --version && \
    /opt/micromamba/bin/micromamba --version && rustc --version && cargo --version && go version

CMD ["/bin/bash"]
