FROM fallingstar10/beaverworker:latest

ENV R_HOME="/usr/lib64/R"
ENV TZ="Etc/UTC"
ENV LANG=en_US.UTF-8
ENV S6_VERSION="v2.1.0.2"
ENV DEFAULT_USER="builduser"
RUN mkdir rocker_scripts
COPY install_rstudio.sh /rocker_scripts/install_rstudio.sh
COPY default_user.sh /rocker_scripts/default_user.sh
COPY init_set_env.sh /rocker_scripts/init_set_env.sh
COPY init_userconf.sh /rocker_scripts/init_userconf.sh
COPY pam-helper.sh /rocker_scripts/pam-helper.sh
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-x86.tar.gz  /tmp
#https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.2/s6-overlay-amd64.tar.gz
RUN tar hzxf /tmp/s6-overlay-x86.tar.gz  -C / --exclude=usr/bin/execlineb &&\
    tar hzxf /tmp/s6-overlay-x86.tar.gz  -C /usr ./bin/execlineb &&\
    echo "$S6_VERSION" >/rocker_scripts/.s6_version &&\
    rm -rf /tmp/s6-overlay-x86.tar.gz  &&\
    yay -S --noconfirm rstudio-server-bin &&\
    R -e "print(list.files('rocker_scripts'))" &&\
    R -e "print(list.files('etc/rstudio'))"

RUN DEFAULT_USER=${DEFAULT_USER:-"builduser"} &&\
    ln -fs /usr/lib/rstudio-server/bin/rstudio-server /usr/local/bin &&\
    ln -fs /usr/lib/rstudio-server/bin/rserver /usr/local/bin &&\
    rm -f /var/lib/rstudio-server/secure-cookie-key &&\
    mkdir -p /etc/R &&\
    R_BIN="$(which R)" &&\
    echo "rsession-which-r=${R_BIN}" >/etc/rstudio/rserver.conf &&\
    echo "lock-type=advisory" >/etc/rstudio/file-locks &&\
    cp /etc/rstudio/rserver.conf /etc/rstudio/disable_auth_rserver.conf &&\
    echo "auth-none=1" >>/etc/rstudio/disable_auth_rserver.conf &&\
    mkdir -p /etc/services.d/rstudio &&\ 
    echo "#!/usr/bin/with-contenv bash" > /etc/services.d/rstudio/run &&\
    echo "" >> /etc/services.d/rstudio/run  &&\
    echo "## load /etc/environment vars first:" >> /etc/services.d/rstudio/run &&\
    echo "" >> /etc/services.d/rstudio/run &&\
    echo "for line in \$( cat /etc/environment ) ; do export \$line > /dev/null; done" >> /etc/services.d/rstudio/run &&\
    echo "" >> /etc/services.d/rstudio/run &&\
    echo "exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0" >> /etc/services.d/rstudio/run &&\
    echo "#!/bin/bash" > /etc/services.d/rstudio/finish &&\
    echo "" >> /etc/services.d/rstudio/finish &&\
    echo "/usr/lib/rstudio-server/bin/rstudio-server stop" >> /etc/services.d/rstudio/finish &&\
    echo "[*]" > /etc/rstudio/logging.conf &&\
    echo "log-level=warn" >> /etc/rstudio/logging.conf &&\
    echo "logger-type=syslog" >> /etc/rstudio/logging.conf &&\
    yay -Sc --noconfirm &&\
    cp /rocker_scripts/init_set_env.sh /etc/cont-init.d/01_set_env &&\
    cp /rocker_scripts/init_userconf.sh /etc/cont-init.d/02_userconf &&\
    cp /rocker_scripts/pam-helper.sh /usr/lib/rstudio-server/bin/pam-helper 

EXPOSE 8080
EXPOSE 8787
CMD ["/init"]

