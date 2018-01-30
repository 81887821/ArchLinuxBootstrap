#!/bin/bash

# This script should be run in chroot environment.

readonly LINUX_LTS_PACKAGES='linux-lts linux-lts-headers'
readonly BTRFS_PACKAGES='btrfs-progs'
readonly NTFS_PACKAGES='ntfs-3g'
readonly GUI_PACKAGES='xorg-server xorg-xrandr xfce4 xfce4-goodies lightdm lightdm-gtk-greeter'
readonly NETWORK_PACKAGES='networkmanager network-manager-applet networkmanager-pptp wpa_supplicant'
readonly SOUND_PACKAGES='pavucontrol'
readonly INPUT_METHOD_PACKAGES='ibus ibus-hangul ibus-anthy'
readonly FONT_PACKAGES='adobe-source-han-sans-jp-fonts ttf-hanazono adobe-source-han-sans-kr-fonts'
readonly DEVELOPMENT_PACKAGES='base-devel git geany python3'
readonly UTILITY_PACKAGES='htop powertop cpupower virtualbox vim'
readonly EXTRA_PACKAGES='x11vnc openssh fish'

readonly OPTIONAL_DEPENDENCIES='vte geany-plugins virtualbox-guest-iso'

readonly SERVICES_TO_ENABLE='NetworkManager lightdm'

function main() {
    locale_generation
    install_packages
    enable_services
    create_user
}

function die() {
    echo "$1"
    exit 1
}

function locale_generation() {
    if ! locale-gen; then
        die "Locale-gen failed."
    fi
}

function install_packages() {
    local packages_to_install="$GUI_PACKAGES $NETWORK_PACKAGES $SOUND_PACKAGES $INPUT_METHOD_PACKAGES $FONT_PACKAGES $DEVELOPMENT_PACKAGES $UTILITY_PACKAGES $EXTRA_PACKAGES"

    if $USE_LINUX_LTS; then
        if ! pacman -R --noconfirm linux; then
            die "Removing linux package failed."
        fi
        packages_to_install="$packages_to_install $LINUX_LTS_PACKAGES nvidia-dkms"
    else
        packages_to_install="$packages_to_install nvidia"
    fi

    if $USE_BTRFS; then
        packages_to_install="$packages_to_install $BTRFS_PACKAGES"
    fi
    
    if $USE_NTFS; then
        packages_to_install="$packages_to_install $NTFS_PACKAGES"
    fi

    if $USE_LINUX_LTS; then
        packages_to_install="$packages_to_install nvidia-dkms"
    else
        packages_to_install="$packages_to_install nvidia"
    fi
    
    if ! pacman -S --noconfirm $packages_to_install; then
        die "Installing packages failed."
    elif ! pacman -S --noconfirm --asdeps $OPTIONAL_DEPENDENCIES; then
        die "Installing optional dependencies failed."
    fi
}

function enable_services() {
    if ! systemctl enable $SERVICES_TO_ENABLE; then
        die "Enabling services failed."
    fi
}

function create_user() {
    if ! useradd -m -G wheel -s "$USER_SHELL" "$USER_NAME"; then
        die "Creating new user failed."
    fi
}

main
