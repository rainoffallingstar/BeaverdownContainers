FROM fallingstar10/beavermake:latest

# 配置 pacman 并行下载
RUN sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# ===== 阶段 1: 官方仓库包安装 =====
RUN pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed \
        r \
        wget \
        mariadb \
        mariadb-clients \
        imagemagick \
        poppler \
        libxtst \
        python-pandas \
        python-numpy \
        python-scipy && \
    pacman -Sc --noconfirm

# ===== 阶段 2: AUR 包安装(分批 + 重试机制) =====
# 批次 1: 基础工具
RUN set -ex && \
    for i in {1..3}; do \
        sudo -u builduser yay -Sy --noconfirm && \
        sudo -u builduser yay -S --noconfirm --needed \
            miniconda3 \
            rustup \
            aliyunpan-go && \
        break || sleep 10; \
    done && \
    sudo -u builduser yay -Sc --noconfirm

# 批次 2: 核心生信库(htslib, samtools, bedtools)
RUN set -ex && \
    for i in {1..3}; do \
        sudo -u builduser yay -S --noconfirm --needed \
            samtools \
            htslib \
            bedtools && \
        break || sleep 10; \
    done && \
    sudo -u builduser yay -Sc --noconfirm

# 批次 3: 质控和处理工具
RUN set -ex && \
    for i in {1..3}; do \
        sudo -u builduser yay -S --noconfirm --needed \
            fastqc \
            trim_galore \
            cutadapt \
            seqkit \
            seqtk && \
        break || sleep 10; \
    done && \
    sudo -u builduser yay -Sc --noconfirm

# 批次 4: 比对工具
RUN set -ex && \
    for i in {1..3}; do \
        sudo -u builduser yay -S --noconfirm --needed \
            bowtie2-bin \
            bwa \
            sambamba \
            gatk-bin \
            tabix && \
        break || sleep 10; \
    done && \
    sudo -u builduser yay -Sc --noconfirm && \
    rm -rf /home/builduser/.cache/*

# ===== 阶段 3: Rust 工具链安装 =====
RUN sudo -u builduser bash -c '\
    rustup default stable && \
    cargo install ggetrs' && \
    rm -rf /home/builduser/.cargo/registry /home/builduser/.cargo/git

# ===== 阶段 4: 工具下载与配置 =====
RUN set -ex && \
    # Qualimap
    mkdir -p /opt/qualimap && \
    wget -qO /tmp/qualimap.zip https://bitbucket.org/kokonech/qualimap/downloads/qualimap_v2.3.zip && \
    unzip -q -d /opt/qualimap /tmp/qualimap.zip && \
    rm /tmp/qualimap.zip && \
    sed -i 's/-XX:MaxPermSize/-XX:MaxMetaspaceSize/g' /opt/qualimap/qualimap_v2.3/qualimap && \
    # Picard
    mkdir -p /opt/picard && \
    wget -qO /opt/picard/picard.jar \
        https://github.com/broadinstitute/picard/releases/download/3.2.0/picard.jar

# ===== 阶段 5: Git 仓库克隆与编译 =====
RUN set -ex && \
    cd /opt && \
    # wgbs_tools
    git clone --depth=1 https://github.com/nloyfer/wgbs_tools.git && \
    cd wgbs_tools && python setup.py && cd .. && \
    rm -rf wgbs_tools/.git && \
    # UXM_deconv
    git clone --depth=1 https://github.com/nloyfer/UXM_deconv.git && \
    rm -rf UXM_deconv/.git && \
    # Bismark
    git clone --depth=1 https://github.com/FelixKrueger/Bismark && \
    rm -rf Bismark/.git && \
    # mHapTools 编译
    git clone --depth=1 https://github.com/butyuhao/mHapTools.git && \
    cd mHapTools/htslib-1.10.2 && \
    ./configure --prefix=/opt/mHapTools/htslib-1.10.2 && \
    make -j$(nproc) && make install && \
    cd .. && \
    g++ -o mhaptools haptk.cpp convert.cpp mhap.cpp merge.cpp beta.cpp \
        summary.cpp utils.cpp \
        -I./htslib-1.10.2/htslib -I./include \
        -L./htslib-1.10.2/ -lhts -std=c++11 -O3 && \
    strip mhaptools && \
    cd htslib-1.10.2 && make clean && cd ../.. && \
    rm -rf mHapTools/.git && \
    # 清理临时文件
    rm -rf /tmp/*

# ===== 阶段 6: Conda 环境配置 =====
RUN set -ex && \
    . /opt/miniconda3/etc/profile.d/conda.sh && \
    conda activate && \
    export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 && \
    # 接受 Anaconda TOS
    conda config --set channel_priority strict && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    # 配置频道
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    # 安装 mamba 加速
    conda install -n base mamba -y && \
    # 创建各个环境
    mamba create -n py27 python=2.7 -y && \
    mamba create -n pyfastx pyfastx -y && \
    mamba create -n clubcpg python=3.10 -y && \
    mamba run -n clubcpg pip install clubcpg && \
    mamba create -n multiqc multiqc python=3.12.3 numpy=1.26.4 -y && \
    mamba create -n star star -y && \
    mamba create -n htseq htseq -y && \
    mamba create -n rmats rmats -y && \
    mamba create -n bwtool -c pwwang -c bioconda bwtool -y && \
    ln -sf /opt/miniconda3/envs/bwtool/lib/libcrypto.so.1.1 \
           /opt/miniconda3/envs/bwtool/lib/libcrypto.so.1.0.0 && \
    mamba create -n scanpy scanpy python-igraph leidenalg -y && \
    # 清理缓存
    conda clean --all -y && \
    rm -rf /opt/miniconda3/pkgs/*

# ===== 阶段 7: R 包安装 =====
RUN set -ex && \
    # 配置清华 CRAN 镜像
    R -e "options(repos = c(CRAN = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/'))" && \
    # 安装 pak 包管理器
    R -e "install.packages('pak', repos = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/')" && \
    # 安装图形库依赖
    R -e "pak::pak('r-lib/ragg')" && \
    # 批量安装核心包
    R -e "pak::pkg_install(c( \
        'DT', 'shinyWidgets', 'shiny', 'bslib', 'optparse', 'openxlsx', \
        'NOISeq', 'XML', 'Repitools', 'Rsamtools', 'rtracklayer', 'R6', \
        'reticulate', 'GSVA', 'graphite', 'igraph', 'ggraph', 'TCGAbiolinks', \
        'SummarizedExperiment', 'doParallel', 'yaml', 'tinytex', 'KEGGgraph', \
        'plotly', 'pROC', 'sva', 'glue', 'fs', 'png', 'reshape2', 'readxl', \
        'sampling', 'pdftools', 'umap', 'gridExtra', 'ggpubr', 'GenomicRanges', \
        'data.table', 'clusterProfiler', 'org.Hs.eg.db', 'msigdbr', 'xlsx', \
        'KEGGREST', 'GenomicDataCommons', 'foreach', 'doMC', 'Seurat', 'dbplyr', \
        'RColorBrewer', 'rjson', 'tidyverse', 'mlr3verse', 'limma', 'BSgenome', \
        'BSgenome.Hsapiens.UCSC.hg19', 'bsseq' \
    ), upgrade = TRUE, ask = FALSE, dependencies = NA)" && \
    # 安装 mlr3 扩展
    R -e "pak::pkg_install('mlr-org/mlr3extralearners@*release', \
        upgrade = TRUE, ask = FALSE, dependencies = NA)" && \
    # 安装开发工具和 GitHub 包
    R -e "pak::pak('devtools')" && \
    R -e "pak::pak('NKI-GCF/XenofilteR')" && \
    R -e "pak::pak('CompEpigen/scMethrix')" && \
    R -e "pak::pak('CompEpigen/methrix')" && \
    R -e "pak::pak('blastula')" && \
    R -e "devtools::install_github('mlr-org/mlr3proba')" && \
    # 安装 tinytex 并配置镜像
    R -e "tinytex::install_tinytex(force = TRUE)" && \
    R -e "tinytex::tlmgr_repo('http://mirrors.tuna.tsinghua.edu.cn/CTAN/')" && \
    # 清理缓存
    R -e "pak::cache_clean()" && \
    rm -rf /tmp/* /root/.cache/*

# ===== 阶段 8: 最终清理 =====
RUN pacman -Sc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/* \
           /home/builduser/.cache/* \
           /tmp/*

# ===== 环境变量配置 =====
ENV PATH=/opt/wgbs_tools:/opt/UXM_deconv:/opt/mHapTools:/opt/qualimap/qualimap_v2.3:/opt/miniconda3/bin:/opt/Bismark:/root/.cargo/bin:/home/builduser/.cargo/bin:$PATH \
    CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 \
    JAVA_OPTS="-Djava.awt.headless=true" \
    R_PROGRESSR_ENABLE=TRUE

# ===== Bash 配置 =====
SHELL ["/bin/bash", "-c"]
RUN echo "source /opt/miniconda3/etc/profile.d/conda.sh && conda activate" >> /root/.bashrc && \
    echo "source /opt/miniconda3/etc/profile.d/conda.sh && conda activate" >> /home/builduser/.bashrc

# ===== 容器入口 =====
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/bin/bash", "-il"]
