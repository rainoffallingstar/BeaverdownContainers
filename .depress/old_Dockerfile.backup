FROM archlinux:latest

# 配置并行编译
COPY makepkg.conf /etc/makepkg.conf

# 系统初始化
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syu --noconfirm && \
    pacman -Scc --noconfirm

# 安装基础开发工具
RUN pacman -S --needed --noconfirm \
    base-devel git sudo nano openssh which \
    pigz pbzip2 cmake gcc-fortran fastfetch && \
    pacman -Scc --noconfirm

# 创建构建用户(最小权限)
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

# 安装 Python 和 pipx
RUN pacman -S --noconfirm python python-pipx && \
    pacman -Scc --noconfirm

# 使用 pipx 安装科学计算工具
RUN pipx install snakemake && \
    pipx install yte && \
    pipx ensurepath

# 设置全局 PATH
ENV PATH="/root/.local/bin:$PATH"

# 清理(可选:移除 builduser)
# RUN userdel -r builduser

# 验证安装
RUN snakemake --version && yay --version

CMD ["/bin/bash"]
