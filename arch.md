
```
mount /dev/sda2 /mnt
cp -r /mnt/@home/master/Downloads/wstunnel .
umount /mnt
cd wstunnel
passwd
bash conn.sh
```

``` bash
mount -o compress=zstd,subvol=@ /dev/disk/by-label/arch_wd /mnt
#mkdir /mnt/{efi,etc,home,var,swap,.snapshots}
mount /dev/disk/by-label/boot_wd /mnt/efi
mount -o compress=zstd,subvol=@home /dev/disk/by-label/arch_wd /mnt/home
mount -o compress=zstd,noatime,subvol=@var /dev/disk/by-label/arch_wd /mnt/var
mount -o compress=zstd,noatime,subvol=@snapshots /dev/disk/by-label/arch_wd /mnt/.snapshots
mount -o subvol=@swap /dev/disk/by-label/arch_wd /mnt/swap
swapon /mnt/swap/swapfile
#pacman -Sy pacman-mirrorlist
echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' \
    > /etc/pacman.d/mirrorlist

pacstrap -K /mnt base base-devel \
    linux linux-zen linux-firmware \
    btrfs-progs grub efibootmgr \
    snapper grub-btrfs \
    reflector mtools net-tools os-prober dosfstools \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
    networkmanager resolvconf dhcpcd iwctl \
    #network-manager-applet \
    sudo fakeroot debugedit xdg-user-dirs \
    git neovim nushell sqlite \
    ripgrep fd dust bottom htop \
    podman buildah skopeo kubectl helm\
    wireguard-tools \
    curl jq openssh rsync tree

genfstab -U /mnt >> /mnt/etc/fstab
echo "### new fstab"
cat /mnt/etc/fstab

arch-chroot /mnt /bin/bash << EOF
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc
    locale-gen
    echo 'LANG=en_US.UTF-8' > /etc/locale.conf
    echo 'arch_wd' > /etc/hostname
    passwd
    # mkinitcpio -P
    pacman -S amd-ucode # intel-ucode
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg

    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
    useradd -m -s /bin/nu -G wheel,storage,power,audio,video,docker master
    #usermod -a -G wheel,storage,power,audio,video,docker master
    echo 'set password of master'
    passwd master
    echo 'lock root'
    passwd -l root

    systemctl enable sshd
    systemctl enable dhcpcd
    systemctl enable NetworkManager
    systemctl enable systemd-resolved

    
    timedatectl set-ntp true
    # nmcli device wifi connect <SSID> password <password>
    pacman -S xdotool xclip \
        plasma-desktop plasma-pa plasma-nm plasma-systemmonitor \
        gparted nm-connection-editor networkmanager-openvpn \
        kscreen kvantum powerdevil kdeplasma-addons kde-gtk-config \
        breeze-gtk dolphin okular gwenview ark mpv gimp \
        alacritty neovide firefox vivaldi
    systemctl enable sddm

    # SSD TRIM
    systemctl enable fstrim.timer

    # bluetooth
    pacman -S bluez bluez-utils blueman
    systemctl enable bluetooth

    # Impreove battary usage:
    pacman -S tlp tlp-rdw acpi acpi_call
    systemctl enable tlp
    systemctl mask systemd-rfkill.service
    systemctl mask systemd-rfkill.socket

    # fonts
    pacman -S noto-fonts noto-fonts-emoji ttf-ubuntu-font-family ttf-dejavu ttf-freefont
    pacman -S ttf-liberation ttf-droid ttf-roboto terminus-font

    # pacman
    reflector --country chinese --fastest 10 --threads `nproc` --save /etc/pacman.d/mirrorlist

    mkinitcpio -p linux

    umount -R /mnt # fuser -km /mnt
EOF

# reboot
sudo ip link set enp0s3 up
./paru -S paru-bin duckdb-bin
alais pa = paru --needed --bottomup
pa -S duckdb-bin


```


devtools
```
# General
sudo pacman -S neovim tree-sitter tree-sitter-cli stow sqlite3 tldr \
               jq tmux openvpn wireguard-tools zip unzip virtualbox \
               nmap masscan pgcli redis ripgrep gitui lazygit \
               gpick apache rclone websocat ansible sshpass meld

sudo setcap 'cap_net_raw+epi' /usr/bin/masscan

# Devops
sudo pacman -S docker docker-compose kubectl helm aws-cli-v2 terraform etcdctl
sudo systemctl enable docker
sudo usermod -a -G docker max
newgrp docker

# Python
sudo pacman -S python-pip python-poetry

# C, C++ and Low Level Tools
sudo pacman -S gcc gdb cmake ninja clang cuda
sudo pacman -S nasm cdrtools qemu-full

# Lua
sudo pacman -S lua

# Golang
sudo pacman -S go
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

# Javascript
sudo pacman -S nodejs npm yarn

# Java
sudo pacman -S jdk20-openjdk

# Rust
sudo pacman -S rust

# Virtualbox
sudo pacman -S linux-headers
sudo pacman -S virtualbox-host-dkms
sudo pacman -S virtualbox

# Architecture
sudo pacman -S plantuml
yay -S gaphor

# Network emulation
yay -S gns3-server gns3-gui

# Hugo
sudo pacman -S hugo dart-sass
```
