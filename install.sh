#!/bin/bash

# Arch Linux installation script.
# Edit readonly variables below before run this script.
# Should be run after mount root partition to $ROOT.

# Directories and files
readonly ROOT='/mnt'
readonly BACKUP='./backup'
readonly CHROOT_SCRIPT='chroot-install.sh'

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
    install_arch
    system_configure
    run_chroot_script
    restore_user_home
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

function install_arch() {
    if ! install -o root -g root -m 644 -T "$BACKUP/etc/pacman.d/mirrorlist" '/etc/pacman.d/mirrorlist'; then
        die "Copying mirrorlist failed."
    elif ! pacstrap "$ROOT" base; then
        die "Arch linux install failed."
    elif ! genfsatb -U "$ROOT" >> "$ROOT/etc/fstab"; then
        die "Writing fstab failed."
    fi
}

function system_configure() {
    if ! ln -sf "/usr/share/zoneinfo/$NEW_TIMEZONE" "$ROOT/etc/localtime"; then
        die "Timezone configure failed."
    elif ! echo "$NEW_LANG" > "$ROOT/etc/locale.conf"; then
        die "Locale configure failed."
    elif ! echo "$NEW_HOSTNAME" > "$ROOT/etc/hostname"; then
        die "Hostname setting failed."
    fi

    local new_filename

    find "$BACKUP/etc" | while read file; do
        new_filename="$ROOT/${file#$BACKUP/}"

        if [ -f "$file" ]; then
            if ! install -o root -g root -m 644 -T "$file" "$new_filename"; then
                die "Failed to copy configure file $file"
            fi
        elif [ -d "$file" ]; then
            if ! mkdir "$new_filename"; then
                die "Making directory $new_filename failed."
            fi
        else
            echo "File type error : $file"
        fi
    done

    system_configure_fix_mode
}

function system_configure_fix_mode() {
    if chmod 440 "$ROOT/etc/sudoers"; then
        die "Mode setting failed for sudoers."
    fi
}

function run_chroot_script() {
    arch-chroot "$ROOT" < "$CHROOT_SCRIPT"
}

function restore_user_home() {
    if [ -d "$BACKUP/home/$USER_NAME" ]; then
        if ! cp -r -p "$BACKUP/home/$USER_NAME" "$ROOT/home/$USER_NAME"; then
            die "Copying user home directory failed."
        elif ! chown -R 1000:1000 "$ROOT/home/$USER_NAME"; then
            die "Change ownership of user home directory failed."
        fi
    fi
}

main
