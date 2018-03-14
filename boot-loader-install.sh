#!/bin/bash

# This script should be run in chroot environment.

function die() {
    echo "$@" 1>&2
    exit 1
}

if ! grub-install --target=x86_64-efi --bootloader-id=grub --efi-directory=/boot --recheck; then
    die "Installing grub failed."
elif ! grub-mkconfig -o '/boot/grub/grub.cfg'; then
    die "Making grub config file failed."
fi
