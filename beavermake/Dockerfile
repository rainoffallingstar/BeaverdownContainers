FROM manjarolinux/base:latest
# Use parallel compression
COPY makepkg.conf /etc/makepkg.conf
COPY install_yay.sh /usr/bin/install_yay.sh
## CREATE A NORMAL USER FOR YAY
# Delete the buildusers password
# Allow the builduser passwordless sudo
RUN pacman -Sy --noconfirm --debug gawk gnupg libgpg-error gnupg gpgme &&\
    pacman -Sy --noconfirm --debug archlinux-keyring manjaro-keyring &&\
    rm -fr /etc/pacman.d/gnupg &&\
    pacman-key --init &&\
    pacman-key --populate archlinux manjaro &&\
    pacman -Sc --noconfirm &&\
    pacman -Syu --noconfirm && pacman -Sc --noconfirm &&\
    pacman -S --needed \
    base-devel \
    binutils \
    fakeroot \
    gawk \
    gettext \
    gcc \
    git \
    make \
    nano \
    pigz \
    pbzip2 \
    openssh \
    sudo \
    which \
    gcc-fortran \
    cmake \
    fastfetch \
    --noconfirm && pacman -Sc --noconfirm &&\
    useradd builduser -m &&\
    passwd -d builduser &&\
    printf 'root ALL=(ALL) ALL\n' | tee -a /etc/sudoers &&\
    printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers &&\
    #cd /usr/lib/ && ln -s libalpm.so.14 libalpm.so.15 && cd .. && cd .. &&\
    cd tmp &&\
    git clone https://aur.archlinux.org/yay-bin.git &&\
    cd .. &&\
    chmod 777 /tmp/yay-bin/ &&\
    chmod +x /usr/sbin/install_yay.sh &&\
    sudo -u builduser install_yay.sh &&\
    rm -rf /tmp/yay/ &&\
    rm /usr/sbin/install_yay.sh &&\
    sudo -u builduser yay -Sc --noconfirm &&\
    mv /usr/bin/yay /usr/bin/yay-pure 
COPY yay /usr/bin/yay
COPY yay-install /usr/bin/yay-install
RUN chmod a+x /usr/sbin/yay &&\
    yay -Syu --noconfirm &&\
    pacman -S python python-uv python-pip python-datrie  python-docutils  python-markupsafe python-jinja python-traitlets \
    python-rpds-py python-referencing python-jsonschema-specifications \
    python-jsonschema python-jupyter-core \
    jupyter-nbformat python-psutil python-yaml --noconfirm &&\
    pip install yte --break-system-packages &&\
    pip install snakemake --break-system-packages &&\
    yay -Sc --noconfirm
CMD bash
