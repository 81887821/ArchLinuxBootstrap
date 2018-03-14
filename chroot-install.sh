#!/bin/bash

# This script should be run in chroot environment.

readonly LINUX_PACKAGES='nvidia virtualbox-host-modules-arch' # assume linux is already installed.
readonly LINUX_LTS_PACKAGES='linux-lts linux-lts-headers nvidia-dkms virtualbox-host-dkms'
readonly BTRFS_PACKAGES='btrfs-progs'
readonly NTFS_PACKAGES='ntfs-3g'
readonly BOOTLOADER_PACKAGES='grub efibootmgr'
readonly GUI_PACKAGES='xorg-server xorg-xrandr xfce4 xfce4-goodies lightdm lightdm-gtk-greeter slock'
readonly NETWORK_PACKAGES='networkmanager network-manager-applet networkmanager-pptp wpa_supplicant'
readonly SOUND_PACKAGES='pulseaudio pulseaudio-alsa pavucontrol'
readonly INPUT_METHOD_PACKAGES='ibus ibus-hangul ibus-anthy'
readonly FONT_PACKAGES='ttf-dejavu adobe-source-han-sans-jp-fonts ttf-hanazono adobe-source-han-sans-kr-fonts'
readonly DEVELOPMENT_PACKAGES='base-devel git geany geany-plugins python3'
readonly UTILITY_PACKAGES='htop powertop cpupower vim p7zip'
readonly GUI_UTILITY_PACKAGES='virtualbox virtualbox-guest-iso xarchiver freerdp'
readonly EXTRA_PACKAGES='x11vnc openssh fish intel-ucode'

# These packages should be listed one of the package lists above.
readonly OPTIONAL_DEPENDENCIES='geany-plugins virtualbox-host-modules-arch virtualbox-host-dkms virtualbox-guest-iso pulseaudio-alsa'

readonly SERVICES_TO_ENABLE='NetworkManager lightdm sshd'

function main() {
    locale_generation
    install_packages
    enable_services
    create_user
}

function die() {
    echo "$@" 1>&2
    exit 1
}

function locale_generation() {
    if ! locale-gen; then
        die "Locale-gen failed."
    fi
}

function install_packages() {
    local packages_to_install="$BOOTLOADER_PACKAGES $GUI_PACKAGES $NETWORK_PACKAGES $SOUND_PACKAGES $INPUT_METHOD_PACKAGES $FONT_PACKAGES $DEVELOPMENT_PACKAGES $UTILITY_PACKAGES $GUI_UTILITY_PACKAGES $EXTRA_PACKAGES"

    if $USE_LINUX_LTS; then
        if ! pacman -R --noconfirm linux; then
            die "Removing linux package failed."
        fi
        packages_to_install="$packages_to_install $LINUX_LTS_PACKAGES"
    else
        packages_to_install="$packages_to_install $LINUX_PACKAGES"
    fi

    if $USE_BTRFS; then
        packages_to_install="$packages_to_install $BTRFS_PACKAGES"
    fi
    
    if $USE_NTFS; then
        packages_to_install="$packages_to_install $NTFS_PACKAGES"
    fi
    
    if ! pacman -S --noconfirm $packages_to_install; then
        die "Installing packages failed."
    fi

    # This command will return non-zero value since not all packages in OPTIONAL_DEPENDENCIES are installed.
    pacman -D --asdeps $OPTIONAL_DEPENDENCIES
}

function enable_services() {
    if ! systemctl enable $SERVICES_TO_ENABLE; then
        die "Enabling services failed."
    fi
}

function create_user() {
    local passwd_input="$user_password
$user_password"

    if ! useradd -m -G wheel -s "$USER_SHELL" "$USER_NAME"; then
        die "Creating new user failed."
    elif [ "$user_password" == "" ]; then
        echo "Warning : User password is not set." 1>&2
    elif ! passwd "$USER_NAME" <<< "$passwd_input"; then
        die "Setting user password failed."
    fi
}

main < /dev/null
