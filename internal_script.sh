#!/bin/bash
pacman-key --init
pacman-key --populate archlinuxarm


sed -i 's/^#logind-check-graphical=.*/logind-check-graphical=true/' /etc/lightdm/lightdm.conf
sed -i 's/# %wheel/%wheel/g' /etc/sudoers

#enable services
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

#create user
useradd -m instantos
echo -e "instantos\ninstantos" | passwd instantos

echo "#!/bin/sh" > /home/instantos/.xserverrc
echo `exec /usr/bin/Xorg -nolisten tcp "$@" vt$XDG_VTNR` >> /home/instantos/.xserverrc

echo "instantxsession" > /home/instantos/.xinitrc

#add startx to bashrc
echo "if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then" > /home/instantos/.bash_profile
echo "  exec startx" >> /home/instantos/.bash_profile
echo "fi" >> /home/instantos/.bash_profile

# Add instantos user to sudoers
echo "instantos ALL=(ALL) ALL" >> /etc/sudoers