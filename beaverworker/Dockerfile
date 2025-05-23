FROM fallingstar10/beavermake:latest
RUN yay -Sy --noconfirm &&\
    yay -S --noconfirm r &&\
    yay -S --noconfirm miniconda3 &&\
    yay -S --noconfirm fastqc &&\
    yay -S --noconfirm samtools &&\
    yay -S --noconfirm trim_galore &&\
    yay -S --noconfirm cutadapt &&\
    yay -S --noconfirm sambamba &&\
    yay -S --noconfirm htslib &&\
    yay -S --noconfirm bowtie2-bin &&\
    yay -S --noconfirm tabix &&\
    yay -S --noconfirm seqkit &&\
    yay -S --noconfirm bedtools &&\
    yay -S --noconfirm imagemagick &&\
    yay -S --noconfirm gatk-bin &&\
    yay -S --noconfirm bwa &&\
    yay -S --noconfirm poppler &&\
    yay -S libxtst --noconfirm &&\
    yay -S seqtk --noconfirm &&\
    yay -S aliyunpan-go --noconfirm &&\
    yay -S --noconfirm rustup && rustup default stable && cargo install ggetrs &&\
    pacman -S mariadb mariadb-clients --noconfirm && \
    pacman -S wget --noconfirm &&\
    mkdir -p qualimap && \
    wget -O "qualimap/qualimap_v2.3.zip" https://bitbucket.org/kokonech/qualimap/downloads/qualimap_v2.3.zip &&\
    unzip -d qualimap qualimap/qualimap_v2.3.zip &&\
    rm qualimap/qualimap_v2.3.zip &&\
    sed -i 's/-XX:MaxPermSize/-XX:MaxMetaspaceSize/g' /qualimap/qualimap_v2.3/qualimap &&\
    # wgbstools 设置环境变量
    pacman -S python-pandas python-numpy python-scipy  --noconfirm &&\
    git clone https://github.com/nloyfer/wgbs_tools.git &&\
    cd wgbs_tools &&\
    python setup.py &&\
    cd .. &&\
    git clone https://github.com/nloyfer/UXM_deconv.git &&\
    git clone https://github.com/FelixKrueger/Bismark &&\
    git clone https://github.com/butyuhao/mHapTools.git &&\
    cd mHapTools &&\
    cd htslib-1.10.2 &&\
    ./configure --prefix=`pwd` &&\
    make &&\
    make install &&\
    cd .. &&\
    g++ -o mhaptools  haptk.cpp convert.cpp mhap.cpp merge.cpp beta.cpp summary.cpp utils.cpp -I ./htslib-1.10.2/htslib -I ./include  -L ./htslib-1.10.2/ -lhts -std=c++11 &&\
    cd .. &&\
    source /opt/miniconda3/etc/profile.d/conda.sh && conda activate &&\
    echo "source /opt/miniconda3/etc/profile.d/conda.sh && conda activate" > /home/builduser/.bashrc &&\
    export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 &&\
    conda config --add channels bioconda &&\
    conda config --add channels conda-forge &&\
    conda config --set channel_priority strict &&\
    #conda create -n methyldackel -c bioconda methyldackel -y  &&\
    #conda create -n bsmap -c bioconda bsmap -y &&\
    conda create -n py27 python=2.7 &&\
    conda create -n pyfastx -c bioconda pyfastx -y &&\
    conda create -n clubcpg python=3.10 &&\
    conda create -n multiqc  -c bioconda multiqc -y &&\
    conda install -n multiqc python=3.12.3 -y &&\
    conda install -n multiqc numpy=1.26.4 -y &&\
    conda create -n star -c bioconda star -y &&\
    conda create -n htseq -c bioconda htseq -y &&\
    conda create -n rmats rmats -y && \
    conda create -n bwtool -c pwwang -c bioconda bwtool -y &&\
    ln -s /opt/miniconda3/envs/bwtool/lib/libcrypto.so.1.1 /opt/miniconda3/envs/bwtool/lib/libcrypto.so.1.0.0 &&\
    conda create -n scanpy -c conda-forge scanpy python-igraph leidenalg -y &&\
    conda run -n clubcpg pip install clubcpg &&\
    mkdir picard &&\
    wget -O "picard/picard.jar" https://github.com/broadinstitute/picard/releases/download/3.2.0/picard.jar &&\
    yay -Sc --noconfirm &&\
    conda clean --all &&\
    R -e "options ('repos' = c(CRAN ='https://mirrors.tuna.tsinghua.edu.cn/CRAN/'))" &&\
    R -e "install.packages('pak',repos = c(CRAN ='https://mirrors.tuna.tsinghua.edu.cn/CRAN/'))" &&\
    R -e "pak::pak('r-lib/ragg')" &&\
    R -e "pak::pkg_install(c('DT','shinyWidgets','shiny','bslib','optparse','openxlsx','NOISeq','XML','Repitools','Rsamtools','rtracklayer','R6','reticulate', 'GSVA','graphite','igraph','ggraph','TCGAbiolinks','SummarizedExperiment','doParallel','yaml','tinytex','KEGGgraph', 'plotly','pROC','sva','glue','fs','png','reshape2','readxl','sampling','pdftools','umap','gridExtra','ggpubr','GenomicRanges','data.table','clusterProfiler','org.Hs.eg.db','msigdbr','xlsx','KEGGREST','GenomicDataCommons','foreach','doMC','Seurat', 'dbplyr', 'RColorBrewer','rjson','tidyverse','mlr3verse','limma','BSgenome','BSgenome.Hsapiens.UCSC.hg19','bsseq'),upgrade = TRUE,ask= FALSE, dependencies = NA)"  &&\
    R -e "pak::pkg_install(c('mlr-org/mlr3extralearners@*release'),upgrade = TRUE,ask= FALSE, dependencies = NA)" &&\
    R -e "pak::pak('devtools')" &&\
    R -e "pak::pak('NKI-GCF/XenofilteR')" &&\
    R -e "pak::pak('CompEpigen/scMethrix')" &&\
    R -e "pak::pak('CompEpigen/methrix')" &&\
    R -e "pak::pak('blastula')" &&\
    R -e "devtools::install_github('mlr-org/mlr3proba')" &&\
    R -e "tinytex::install_tinytex(force = TRUE)" &&\
    R -e "tinytex::tlmgr_repo('http://mirrors.tuna.tsinghua.edu.cn/CTAN/')" &&\
    R -e "pak::cache_clean()"  && \
    rm -rf /tmp/* &&\
    pacman -Sc --noconfirm
ENV PATH=/wgbs_tools:$PATH
ENV PATH=/UXM_deconv:$PATH
ENV CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
# add root install cargo tools
ENV PATH=/root/.cargo/bin:$PATH
ENV PATH=/home/builduser/.cargo/bin:$PATH
#remove mHap ENV,note: set it alone when using it.
#ENV LD_LIBRARY_PATH=/mHapTools/htslib-1.10.2/lib
ENV PATH=/mHapTools:$PATH
ENV PATH=/qualimap/qualimap_v2.3:$PATH
ENV PATH=/opt/miniconda3/bin:$PATH
ENV PATH=/Bismark:$PATH
# 设置java 以无GUI形式运行jar文件
ENV JAVA_OPTS="-Djava.awt.headless=true"
# 设置bash输出R进度条
ENV R_PROGRESSR_ENABLE=TRUE
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/bin/bash -il"]


