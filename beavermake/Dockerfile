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
    --noconfirm && pacman -Sc --noconfirm &&\
    useradd builduser -m &&\
    passwd -d builduser &&\
    printf 'root ALL=(ALL) ALL\n' | tee -a /etc/sudoers &&\
    printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers &&\
    cd tmp &&\
    git clone https://aur.archlinux.org/yay.git &&\
    cd .. &&\
    chmod 777 /tmp/yay/ &&\
    chmod +x /usr/sbin/install_yay.sh &&\
    sudo -u builduser install_yay.sh &&\
    rm -rf /tmp/yay/ &&\
    rm /usr/sbin/install_yay.sh &&\
    sudo -u builduser yay -Sc --noconfirm &&\
    yay -Syu --noconfirm &&\
    yay -S --noconfirm snakemake 
CMD bash