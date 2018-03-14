#!/bin/bash

# Arch Linux installation script.
# Edit readonly variables below before run this script.
# Should be run after mount root partition to $ROOT.

# Directories and files
readonly ROOT='/mnt'
readonly INSTALL_ENVIRONMENT='./install-environment'
readonly PRE_PACKAGE_INSTALL='./pre-package-install'
readonly POST_PACKAGE_INSTALL='./post-package-install'
readonly CHROOT_SCRIPT='chroot-install.sh'
readonly PRIVATE_BACKUP='private-backup.tar.7z'

# Variables for new system
readonly NEW_HOSTNAME=''
readonly NEW_TIMEZONE='Asia/Seoul'
readonly NEW_LANG='en_US.UTF-8'

# Packages install flags
readonly USE_LINUX_LTS='true'; export USE_LINUX_LTS # true to use linux-lts, false to use linux
readonly USE_BTRFS='true'; export USE_BTRFS
readonly USE_NTFS='true'; export USE_NTFS

# Variables for user
readonly USER_NAME=''; export USER_NAME
readonly USER_SHELL='/usr/bin/fish'; export USER_SHELL

function main() {
    check_partitions_mounted
    check_required_tools
    install_arch
    pre_package_install_configure
    run_chroot_script
    post_package_install_configure
    restore_private_backup
}

function die() {
    echo "$1"
    exit 1
}

function check_partitions_mounted() {
    if ! mountpoint -q "$ROOT"; then
        die "Root partition is not mounted."
    elif ! mountpoint -q "$ROOT/boot"; then
        die "Boot partition is not mounted."
    fi
}

function check_required_tools() {
    if ! which 7z; then
        die "7z is not installed."
    fi
}

function install_arch() {
    if ! install -o root -g root -m 644 -T "$INSTALL_ENVIRONMENT/mirrorlist" '/etc/pacman.d/mirrorlist'; then
        die "Copying mirrorlist failed."
    elif ! pacstrap "$ROOT" base; then
        die "Arch linux install failed."
    elif ! genfstab -U "$ROOT" >> "$ROOT/etc/fstab"; then
        die "Writing fstab failed."
    fi
}

function pre_package_install_configure() {
    if ! ln -sf "/usr/share/zoneinfo/$NEW_TIMEZONE" "$ROOT/etc/localtime"; then
        die "Timezone configure failed."
    elif ! echo "LANG=$NEW_LANG" > "$ROOT/etc/locale.conf"; then
        die "Locale configure failed."
    elif ! echo "$NEW_HOSTNAME" > "$ROOT/etc/hostname"; then
        die "Hostname setting failed."
    fi

    restore_files "$PRE_PACKAGE_INSTALL"
}

function run_chroot_script() {
    arch-chroot "$ROOT" < "$CHROOT_SCRIPT"
}

function post_package_install_configure() {
    restore_files "$POST_PACKAGE_INSTALL"
}

function restore_private_backup() {
    local password

    if [ -f "$PRIVATE_BACKUP" ]; then
        while true; do
            read -sp "Password: " password
            7z e -so "-p$password" "$PRIVATE_BACKUP" | tar -x --preserve-permissions --same-owner --absolute-names --directory "$ROOT"
            if [ $? -eq 0 ]; then
                break
            fi
        done
    else
        echo "Backup file doesn't exist."
    fi
}

function restore_files() {
    local backup_directory="$1"
    local new_filename

    find "$backup_directory" | while read file; do
        new_filename="$ROOT/${file#$backup_directory/}"

        if [ -f "$file" ]; then
            if ! install -o root -g root -m 644 -T "$file" "$new_filename"; then
                die "Failed to copy configure file $file"
            fi
        elif [ -d "$file" ]; then
            if [ ! -d "$new_filename" ]; then
                if ! mkdir "$new_filename"; then
                    die "Making directory $new_filename failed."
                fi
            fi
        else
            echo "File type error : $file"
        fi
    done

    if [ $? -ne 0 ]; then
        exit 1
    fi
}

main
