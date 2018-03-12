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

tar -c --absolute-names --preserve-permissions --same-owner "${BACKUP_TARGETS[@]}" | 7z a -si -p -mhe=on "$PRIVATE_BACKUP"
