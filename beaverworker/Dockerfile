FROM fallingstar10/beavermake:latest

# ===== 阶段 1: 系统工具安装 =====
RUN yay -Sy --noconfirm && \
    # 生信核心工具(单次安装)
    yay -S --noconfirm \
        r miniconda3 fastqc samtools trim_galore cutadapt \
        sambamba htslib bowtie2-bin tabix seqkit bedtools \
        imagemagick gatk-bin bwa poppler libxtst seqtk \
        aliyunpan-go rustup mariadb mariadb-clients wget && \
    # Rust 环境配置
    rustup default stable && \
    cargo install ggetrs && \
    # 清理缓存
    yay -Sc --noconfirm && \
    rm -rf /home/builduser/.cache/* /tmp/*

# ===== 阶段 2: 工具安装与配置 =====
RUN set -ex && \
    # Qualimap
    wget -qO- https://bitbucket.org/kokonech/qualimap/downloads/qualimap_v2.3.zip | \
        busybox unzip -d /opt - && \
    sed -i 's/-XX:MaxPermSize/-XX:MaxMetaspaceSize/g' /opt/qualimap_v2.3/qualimap && \
    # Picard
    mkdir -p /opt/picard && \
    wget -qO /opt/picard/picard.jar \
        https://github.com/broadinstitute/picard/releases/download/3.2.0/picard.jar && \
    # wgbs_tools + UXM + Bismark + mHapTools(浅克隆)
    cd /opt && \
    git clone --depth=1 https://github.com/nloyfer/wgbs_tools.git && \
    git clone --depth=1 https://github.com/nloyfer/UXM_deconv.git && \
    git clone --depth=1 https://github.com/FelixKrueger/Bismark && \
    git clone --depth=1 https://github.com/butyuhao/mHapTools.git && \
    # 编译 mHapTools
    cd mHapTools/htslib-1.10.2 && \
    ./configure --prefix=/opt/mHapTools/htslib-1.10.2 && \
    make -j$(nproc) && make install && \
    cd .. && \
    g++ -o mhaptools haptk.cpp convert.cpp mhap.cpp merge.cpp beta.cpp \
        summary.cpp utils.cpp -I./htslib-1.10.2/htslib -I./include \
        -L./htslib-1.10.2/ -lhts -std=c++11 -O3 && \
    strip mhaptools && \
    # 清理编译临时文件
    cd htslib-1.10.2 && make clean && \
    rm -rf /opt/mHapTools/.git /opt/wgbs_tools/.git /opt/UXM_deconv/.git /opt/Bismark/.git

# ===== 阶段 3: Conda 环境(合并安装) =====
RUN set -ex && \
    . /opt/miniconda3/etc/profile.d/conda.sh && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda config --set channel_priority strict && \
    # 批量创建环境(利用 mamba 加速)
    conda install -n base mamba -y && \
    mamba create -n py27 python=2.7 -y && \
    mamba create -n pyfastx pyfastx -y && \
    mamba create -n clubcpg python=3.10 clubcpg -y && \
    mamba create -n multiqc multiqc python=3.12.3 numpy=1.26.4 -y && \
    mamba create -n star star -y && \
    mamba create -n htseq htseq -y && \
    mamba create -n rmats rmats -y && \
    mamba create -n bwtool bwtool -y && \
    mamba create -n scanpy scanpy python-igraph leidenalg -y && \
    # bwtool 特殊处理
    ln -sf /opt/miniconda3/envs/bwtool/lib/libcrypto.so.1.1 \
           /opt/miniconda3/envs/bwtool/lib/libcrypto.so.1.0.0 && \
    # 清理
    conda clean --all -y && \
    rm -rf /opt/miniconda3/pkgs/*

# ===== 阶段 4: R 包安装(镜像+批量) =====
RUN set -ex && \
    # 配置清华镜像
    R -e "options(repos = c(CRAN = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/'))" && \
    R -e "install.packages('pak', repos = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/')" && \
    # 核心包批量安装
    R -e "pak::pkg_install(c( \
        'r-lib/ragg', 'DT', 'shinyWidgets', 'shiny', 'bslib', 'optparse', \
        'openxlsx', 'NOISeq', 'XML', 'Repitools', 'Rsamtools', 'rtracklayer', \
        'R6', 'reticulate', 'GSVA', 'graphite', 'igraph', 'ggraph', \
        'TCGAbiolinks', 'SummarizedExperiment', 'doParallel', 'yaml', \
        'tinytex', 'KEGGgraph', 'plotly', 'pROC', 'sva', 'glue', 'fs', 'png', \
        'reshape2', 'readxl', 'sampling', 'pdftools', 'umap', 'gridExtra', \
        'ggpubr', 'GenomicRanges', 'data.table', 'clusterProfiler', \
        'org.Hs.eg.db', 'msigdbr', 'xlsx', 'KEGGREST', 'GenomicDataCommons', \
        'foreach', 'doMC', 'Seurat', 'dbplyr', 'RColorBrewer', 'rjson', \
        'tidyverse', 'mlr3verse', 'limma', 'BSgenome', \
        'BSgenome.Hsapiens.UCSC.hg19', 'bsseq', \
        'mlr-org/mlr3extralearners@*release', 'devtools', \
        'NKI-GCF/XenofilteR', 'CompEpigen/scMethrix', 'CompEpigen/methrix', \
        'blastula'), upgrade = TRUE, ask = FALSE, dependencies = NA)" && \
    R -e "devtools::install_github('mlr-org/mlr3proba')" && \
    R -e "tinytex::install_tinytex(force = TRUE)" && \
    R -e "tinytex::tlmgr_repo('http://mirrors.tuna.tsinghua.edu.cn/CTAN/')" && \
    # 清理缓存
    R -e "pak::cache_clean()" && \
    rm -rf /tmp/* /root/.cache/*

# ===== 环境变量配置 =====
ENV PATH=/opt/wgbs_tools:/opt/UXM_deconv:/opt/mHapTools:/opt/qualimap_v2.3:/opt/miniconda3/bin:/opt/Bismark:/root/.cargo/bin:$PATH \
    CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 \
    JAVA_OPTS="-Djava.awt.headless=true" \
    R_PROGRESSR_ENABLE=TRUE

# 默认激活 conda base 环境
SHELL ["/bin/bash", "-c"]
RUN echo "source /opt/miniconda3/etc/profile.d/conda.sh && conda activate" >> /root/.bashrc

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/bin/bash", "-il"]
