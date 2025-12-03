#!/bin/bash
# 注意: 这是一个shell脚本，不是R脚本
# 功能: 在容器中添加用户并配置sudo权限
# 用法: 在容器中执行此脚本，或复制到容器中执行

useradd -m -d /home/username username
passwd username
printf 'username ALL=(ALL) ALL\n' | tee -a /etc/sudoers