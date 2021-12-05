#!/bin/bash

set -e #exit script if any command fails

#Options:
silentPacstrap="False" #specifies whether or not pacstrap outputs anything to the terminal
xmrigEnabled="False"

#Print options:
echo "Config:"
echo "   Silenced pacstrap: ${silentPacstrap}"
echo "   Xmrig enabled: ${xmrigEnabled}"

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

if [[ "$xmrigEnabled" == "True" ]]; then 
    tarName="${tarName}-xmrig"
fi

packageList="base base-devel networkmanager ${kernel} ${kernel}-headers raspberrypi-firmware raspberrypi-bootloader openssh ntp fish yay nano"

if [[ $xmrigEnabled == "True" ]]; then 
    packageList="${packageList} screen clang llvm hwloc openssl cmake git screen bc lld"
fi

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
chmod +x chroot_things/internal_script.sh
cp -v "chroot_things/internal_script.sh" "${targetChroot}/internal_script.sh"
stop_spinner $?

echo "/dev/mmcblk0p1 /boot vfat defaults,rw 0 0" >> "${targetChroot}/etc/fstab" #add /boot to /etc/fstab
echo "arch ALL=(ALL) NOPASSWD: ALL" >> "${targetChroot}/etc/sudoers" #Add arch user to sudoers

if [[ $xmrigEnabled == "True" ]]; then 
    mkdir -p $targetChroot/home/arch
    cp -v "chroot_things/xmrig/xmrig.json" "${targetChroot}/home/arch/.xmrig.json"
    echo vm.nr_hugepages=1280 >> "${targetChroot}/etc/sysctl.conf"

    [ -z ${WALLET_ADDR} ] && echo "WALLET_ADDR not set" || sed -i "s/WALLET_ADDR/${WALLET_ADDR}/g" "${targetChroot}/home/arch/.xmrig.json"

    [ -z ${WORKER_NAME} ] && echo "WORKER_NAME not set" || sed -i "s/WORKER_NAME/${WORKER_NAME}/g" "${targetChroot}/home/arch/.xmrig.json"

    mkdir -p $targetChroot/home/arch/.config/fish
    touch $targetChroot/home/arch/.config/fish/config.fish
    echo 'set -gx PATH $PATH /home/arch/bin' > $targetChroot/home/arch/.config/fish/config.fish

    mkdir $targetChroot/home/arch/bin
    cp -v "chroot_things/xmrig/xmrig_build" $targetChroot/home/arch/bin/xmrig_build
    cp -v "chroot_things/xmrig/xmrig_run" $targetChroot/home/arch/bin/xmrig_run
    chmod +x $targetChroot/home/arch/bin/*

    cp -v "chroot_things/xmrig/xmrig.service" $targetChroot/etc/systemd/system/
    sed -i ' 1 s/.*/&mitigations=off default_hugepagesz=2M hugepagesz=1G hugepages=3/' $targetChroot/boot/cmdline.txt
    echo -e "#highly recommended for mining:\n#1.8ghz profile:\n#over_voltage=7\n#arm_freq=1800" >> $targetChroot/boot/config.txt

    cp -v chroot_things/xmrig/setcpugov.service $targetChroot/etc/systemd/system/setcpugov.service

    cp -v chroot_things/xmrig/temps $targetChroot/home/arch/bin/
fi 

mount --bind "${targetChroot}" "${targetChroot}" #Has to be like this or else pacstrap isn't happy
start_spinner 'Running internal script...'
echo "/dev/mmcblk0p1 /boot vfat defaults 0 0" >> "${targetChroot}/etc/fstab"
arch-chroot "${targetChroot}" "./internal_script.sh"
rm "${targetChroot}/internal_script.sh"
stop_spinner $?

if [[ $xmrigEnabled == "True" ]]; then 
    chmod +x chroot_things/xmrig/internal_script_xmrig.sh
    cp -v chroot_things/xmrig/internal_script_xmrig.sh "${targetChroot}/internal_script_xmrig.sh"
    arch-chroot "${targetChroot}" "./internal_script_xmrig.sh"
    rm "${targetChroot}/internal_script_xmrig.sh"
fi

start_spinner 'clearing pacman cache...'
rm -fr "${targetChroot}/var/cache/pacman/pkg/*"
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
