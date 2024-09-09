FROM fallingstar10/beavermake:latest
RUN yay -Syu --noconfirm &&\
    yay -S --noconfirm r &&\
    yay -S --noconfirm miniconda3 &&\
    yay -S --noconfirm fastqc &&\
    yay -S --noconfirm samtools &&\
    yay -S --noconfirm trim_galore &&\
    yay -S --noconfirm cutadapt &&\
    yay -S --noconfirm sambamba &&\
    yay -S --noconfirm htslib &&\
    yay -S --noconfirm tabix &&\
    yay -S --noconfirm seqkit &&\
    yay -S --noconfirm bedtools &&\
    yay -S --noconfirm imagemagick &&\
    yay -S --noconfirm poppler &&\
    yay -S libxtst --noconfirm &&\
    pacman -S wget --noconfirm &&\
    mkdir -p qualimap && \
    wget -O "qualimap/qualimap_v2.3.zip" https://bitbucket.org/kokonech/qualimap/downloads/qualimap_v2.3.zip &&\
    unzip -d qualimap qualimap/qualimap_v2.3.zip &&\
    rm qualimap/qualimap_v2.3.zip &&\
    sed -i 's/-XX:MaxPermSize/-XX:MaxMetaspaceSize/g' /qualimap/qualimap_v2.3/qualimap &&\
    # wgbstools 设置环境变量
    pacman -S python-pandas python-numpy python-scipy --noconfirm &&\
    git clone https://github.com/nloyfer/wgbs_tools.git &&\
    cd wgbs_tools &&\
    python setup.py &&\
    cd .. &&\
    git clone https://github.com/nloyfer/UXM_deconv.git &&\
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
    conda create -n methyldackel -c bioconda methyldackel -y  &&\
    conda create -n bsmap -c bioconda bsmap -y &&\
    yay -Sc --noconfirm &&\
    conda clean --all &&\
    R -e "options ('repos' = c(CRAN ='https://mirrors.tuna.tsinghua.edu.cn/CRAN/'))" &&\
    R -e "install.packages('pak',repos = c(CRAN ='https://mirrors.tuna.tsinghua.edu.cn/CRAN/'))" &&\ 
    R -e "pak::pak('r-lib/ragg#171')" &&\
    R -e "pak::pkg_install(c('optparse','openxlsx','NOISeq','XML','Repitools','Rsamtools','rtracklayer','R6','reticulate', 'GSVA','graphite','igraph','ggraph','TCGAbiolinks','SummarizedExperiment','doParallel','yaml','tinytex','KEGGgraph', 'plotly','pROC','sva','glue','fs','png','reshape2','readxl','sampling','pdftools','umap','gridExtra','ggpubr','GenomicRanges','data.table','clusterProfiler','org.Hs.eg.db','msigdbr','xlsx','KEGGREST','GenomicDataCommons','foreach','doMC','Seurat', 'dbplyr', 'RColorBrewer','rjson','tidyverse','mlr3verse','limma'),upgrade = TRUE,ask= FALSE, dependencies = NA)"  &&\
    R -e "pak::pkg_install(c('mlr-org/mlr3extralearners@*release'),upgrade = TRUE,ask= FALSE, dependencies = NA)" &&\
    R -e "pak::pak('devtools')" &&\
    R -e "devtools::install_github('mlr-org/mlr3proba')" &&\
    R -e "tinytex::install_tinytex(force = TRUE)" &&\
    R -e "tinytex::tlmgr_repo('http://mirrors.tuna.tsinghua.edu.cn/CTAN/')" &&\
    R -e "pak::cache_clean()"  && \
    rm -rf /tmp/* 
ENV PATH=/wgbs_tools:$PATH
ENV PATH=/UXM_deconv:$PATH
ENV CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
ENV LD_LIBRARY_PATH=/mHapTools/htslib-1.10.2/lib
ENV PATH=/mHapTools:$PATH
ENV PATH=/qualimap/qualimap_v2.3:$PATH
ENV PATH=/opt/miniconda3/bin:$PATH
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["source /opt/miniconda3/etc/profile.d/conda.sh && conda activate && /bin/bash -il"]


