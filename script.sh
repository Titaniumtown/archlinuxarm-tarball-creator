#!/bin/bash

set -e #exit script if any command fails

#Options:
silentPacstrap="False" #specifies whether or not pacstrap outputs anything to the terminal

#Print options:
echo "Config:"
echo "   Silenced pacstrap: ${silentPacstrap}"


source "$(pwd)/scripts/spinner.sh" #for spinners

targetChroot="target_root"

if [[ $(id -u) != 0 ]]; then echo >&2 "Must be root to run script"; exit 1; fi
arch=$(uname -m | tr -d '\n')
if [[ "$arch" != "aarch64" ]]; then echo >&2 "sorry, this script only supports aarch64 at the moment"; exit 1; fi
#Note: Run this script on a raspberry pi 4, to generate a functioning tarball

if [ -d "${targetChroot}" ]; then rm -rf "${targetChroot}"; fi

mkdir "${targetChroot}"
kernel="linux-raspberrypi4-5.15.y"

date=$(date +"%F" | tr -d '\n')
echo -e "date: ${date}\n"

tarName="archlinux-arm-raspi4-${date}"

packageList="base base-devel networkmanager ${kernel} ${kernel}-headers raspberrypi-firmware raspberrypi-bootloader openssh ntpd fish cmake yay"

if [[ "$silentPacstrap" == "False" ]]; then
    pacstrap -C "chroot_things/pacman.conf" "${targetChroot}" ${packageList}
elif [[ "$silentPacstrap" == "True" ]]; then
start_spinner 'Running pacstrap...'
    pacstrap -C "chroot_things/pacman.conf" "${targetChroot}" ${packageList} > /dev/null
    stop_spinner $?
else
    echo "ERROR: variable silentPacstrap is invalid"
    exit 1
fi


start_spinner 'Copying files...'
rm -fr "${targetChroot}/etc/pacman.conf" "${targetChroot}/etc/makepkg.conf"

cp -v "chroot_things/pacman.conf" "${targetChroot}/etc/pacman.conf"
cp -v "chroot_things/makepkg.conf" "${targetChroot}/etc/makepkg.conf"
#temp copy internal script to chroot:
cp "chroot_things/internal_script.sh" "${targetChroot}/internal_script.sh"
stop_spinner $?

echo "/dev/mmcblk0p1 /boot vfat defaults,rw 0 0" >> "${targetChroot}/etc/fstab" #add /boot to /etc/fstab
echo "arch ALL=(ALL) ALL" >> "${targetChroot}/etc/sudoers" #Add arch user to sudoers

mount --bind "${targetChroot}" "${targetChroot}" #Has to be like this or else pacstrap isn't happy
start_spinner 'Running internal script...'
echo "/dev/mmcblk0p1 /boot vfat defaults 0 0" >> "${targetChroot}/etc/fstab"
arch-chroot "${targetChroot}" "./internal_script.sh"
rm "${targetChroot}/internal_script.sh"
stop_spinner $?

#un-bind directory
umount "${targetChroot}"

start_spinner "Compressing final tarball..."
cd "${targetChroot}"
tar -I pzstd -cf "../${tarName}.tar.zst" .
cd ..
stop_spinner $?

start_spinner "Deleting ${targetChroot}..."
rm -fr $targetChroot
stop_spinner $?
