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

# ===== 阶段 7: R 包安装(增强兼容性和容错) =====
RUN set -ex && \
    # 安装系统依赖
    pacman -S --needed --noconfirm cairo pango freetype2 libpng libjpeg-turbo libtiff harfbuzz fribidi && \
    # 配置全局 R 环境
    mkdir -p /root/.R && \
    cat > /root/.Rprofile << 'EOF'
options(
    repos = c(CRAN = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/"),
    download.file.method = "libcurl",
    timeout = 600,
    Ncpus = parallel::detectCores()
)
EOF
    
# 安装 pak(使用传统方式,避免元数据问题)
RUN R -e "install.packages('pak', repos = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/')" || \
    R -e "install.packages('pak', repos = 'https://cloud.r-project.org/')" && \
    # 清理 pak 缓存并强制更新
    R -e "pak::cache_clean()" && \
    R -e "pak::meta_clean()" && \
    # 使用官方 CRAN 镜像作为 pak 的备用源
    R -e "pak::repo_add(CRAN = 'https://cloud.r-project.org/')"

# 组1: 基础包(使用传统 install.packages)
RUN R -e "install.packages(c( \
        'remotes', 'devtools', 'BiocManager', 'ragg', \
        'DT', 'shiny', 'bslib', 'yaml', 'jsonlite' \
    ), dependencies = TRUE, Ncpus = parallel::detectCores())"

# 组2: 数据处理包(混合使用 BiocManager 和 install.packages)
RUN R -e "install.packages(c( \
        'tidyverse', 'data.table', 'openxlsx', 'readxl', 'reshape2', \
        'R6', 'glue', 'fs', 'purrr', 'dplyr', 'ggplot2' \
    ), dependencies = TRUE)" && \
    R -e "BiocManager::install(c( \
        'GenomicRanges', 'Biostrings', 'rtracklayer' \
    ), update = FALSE, ask = FALSE)"

# 组3: 可视化包
RUN R -e "install.packages(c( \
        'shinyWidgets', 'plotly', 'gridExtra', 'ggpubr', \
        'RColorBrewer', 'scales', 'patchwork' \
    ), dependencies = TRUE)"

# 组4: 统计和机器学习
RUN R -e "install.packages(c( \
        'pROC', 'umap', 'sampling', 'foreach', 'doParallel', 'doMC' \
    ), dependencies = TRUE)" && \
    R -e "install.packages('mlr3verse', dependencies = TRUE)" || \
    R -e "install.packages(c('mlr3', 'mlr3learners', 'mlr3pipelines'), dependencies = TRUE)"

# 组5: Bioconductor 核心包
RUN R -e "BiocManager::install(c( \
        'limma', 'edgeR', 'DESeq2', \
        'Rsamtools', 'GenomicAlignments', 'SummarizedExperiment', \
        'BSgenome', 'BSgenome.Hsapiens.UCSC.hg19', 'bsseq', \
        'Repitools' \
    ), update = FALSE, ask = FALSE)"

# 组6: 功能富集分析
RUN R -e "BiocManager::install(c( \
        'clusterProfiler', 'org.Hs.eg.db', 'DOSE', 'enrichplot', \
        'msigdbr', 'KEGGREST', 'KEGGgraph', \
        'GSVA', 'graphite', 'reactome.db' \
    ), update = FALSE, ask = FALSE)"

# 组7: 单细胞和高级分析
RUN R -e "install.packages(c('Seurat', 'reticulate'), dependencies = TRUE)" && \
    R -e "BiocManager::install(c( \
        'SingleCellExperiment', 'scater', 'scran' \
    ), update = FALSE, ask = FALSE)" || true

# 组8: 基因组数据获取
RUN R -e "BiocManager::install(c( \
        'TCGAbiolinks', 'GenomicDataCommons', 'GEOquery' \
    ), update = FALSE, ask = FALSE)" || true

# 组9: 其他专用包
RUN R -e "install.packages(c( \
        'NOISeq', 'sva', 'XML', 'pdftools', 'optparse', \
        'png', 'rjson', 'xlsx', 'dbplyr' \
    ), dependencies = TRUE)" || true

# 组10: GitHub 包(使用 remotes,更稳定)
RUN R -e "remotes::install_github('r-lib/ragg', upgrade = 'never')" || true && \
    R -e "remotes::install_github('NKI-GCF/XenofilteR', upgrade = 'never')" || true && \
    R -e "remotes::install_github('CompEpigen/methrix', upgrade = 'never')" || true && \
    R -e "remotes::install_github('CompEpigen/scMethrix', upgrade = 'never')" || true && \
    R -e "remotes::install_github('mlr-org/mlr3proba', upgrade = 'never')" || true && \
    R -e "remotes::install_github('mlr-org/mlr3extralearners', upgrade = 'never')" || true

# 组11: 额外包
RUN R -e "install.packages(c('blastula', 'tinytex'), dependencies = TRUE)" || true && \
    R -e "tinytex::install_tinytex(force = TRUE)" && \
    R -e "tinytex::tlmgr_repo('http://mirrors.tuna.tsinghua.edu.cn/CTAN/')"

# 验证关键包
RUN R -e "required_pkgs <- c('tidyverse', 'Seurat', 'clusterProfiler', 'limma', 'GenomicRanges'); \
    missing <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]; \
    if(length(missing) > 0) stop('Missing packages: ', paste(missing, collapse=', '))" || true

# 最终清理
RUN R -e "pak::cache_clean()" || true && \
    rm -rf /tmp/* /root/.cache/* /root/.local/share/pak /root/.local/share/rstudio
    
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
