#!/bin/bash

readonly PRIVATE_BACKUP='private-backup.tar.7z'
readonly BACKUP_TARGETS=(
    '/home'
    '/root'
    '/etc/fstab'
    '/etc/crypttab'
    '/etc/sudoers'
    '/etc/default/grub'
    '/etc/grub.d/40_custom'
    '/etc/NetworkManager'
)

while true; do
    read -sp "Enter password: " password
    echo
    read -sp "Retype password: " password_recheck
    echo

    if [ "$password" != "$password_recheck" ]; then
        echo "Passwords are not same."
    else
        break
    fi
done

tar -c --preserve-permissions --same-owner "${BACKUP_TARGETS[@]}" | 7z a -si "-p$password" -mhe=on "$PRIVATE_BACKUP"
