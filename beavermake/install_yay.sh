#!/bin/sh
set -e
cd /tmp/yay-bin
makepkg -si --noconfirm
cd ~
