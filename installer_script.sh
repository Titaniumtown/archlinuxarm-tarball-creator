#!/bin/bash

(( $(id -u) == 0 )) || { echo >&2 "Must be root to run script"; exit 1; }
rm /tmp/raspiinstaller > /dev/null 2>&1

drives=$(lsblk -n | awk '!/─/' | awk '{ print $1 }')

for item in $drives;
do
		echo $item $(lsblk -dn /dev/sda | awk '{ print $4 }') $(cat /sys/block/$item/device/model) >> /tmp/raspiinstaller
done

drive=$(cat /tmp/raspiinstaller | fzf)

echo Are you sure this is the right drive: $drive?

read right
rm /tmp/raspiinstaller > /dev/null 2>&1

