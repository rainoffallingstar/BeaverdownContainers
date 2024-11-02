useradd -m -d /home/username username
passwd username
printf 'username ALL=(ALL) ALL\n' | tee -a /etc/sudoers