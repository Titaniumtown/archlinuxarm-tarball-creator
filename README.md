# Arch Linux Arm Raspberry Pi 4 Tarball creator
This repo contains scripts to create tarballs that use my Arch Linux Arm repo (that contains [updated Raspberry Pi 4 kernel packages](https://github.com/Titaniumtown/raspi4_pkgbuilds), and ZFS packages, among other things). This also gets you running with a fully functioning system very quickly, with everything installed, networking, time, ssh, and more working out of the box and requiring no extra setup.

You can get builds at: https://www.gardling.com/arch-raspi4-tarballs

This project is based off of the work I did for: [InstantOS-arm](https://github.com/instantOS/instantOS-arm)

## What you should know:
- Default root password: `root`
- Default username: `arch`
- Default password: `arch`

## Xmrig tarballs:
While this feature is still in development, this option aims to allow people to get up and running on [MoneroOcean](https://moneroocean.stream) and mining the most profitable crypto for their Raspberry Pi 4! Please do note that you do need a good cooler on your Raspberry Pi as using a tarball with xmrig integrated into it will **overclock to 2.0ghz**, and alongside the cpu being under high usage, this will create a lot of heat that may **damage your Pi** if you don't have **adequate cooling**.

You can also monitor your temperatures, via the `temps` command (a script I made) located in `~/bin/fish` but should be included in your `PATH` by default.

In order to get mining once you have the tarball installed, you need to open `~/.xmrig.json`, and change `WALLET_ADDR` to your Monero wallet, and change `WORKER_NAME` to whatever you want to call the machine you're mining on.

## TODO:
- write more detailed guide on how to get this set up
- package xmrig instead of the system that is being used right now