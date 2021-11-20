#!/bin/bash
pacman-key --init
pacman-key --populate archlinuxarm

#enable services
systemctl enable NetworkManager
systemctl enable systemd-timesyncd
systemctl enable sshd
systemctl enable ntpd

#create user
useradd -m arch
echo -e "arch\narch" | passwd arch

#set password to root user to root
echo -e "root\nroot" | passwd root

chsh -s /usr/bin/fish arch #set fish as the default shell

pacman -Scc --noconfirm #clean package cache
