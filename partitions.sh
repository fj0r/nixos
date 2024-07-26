parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MB 100%
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.btrfs -f -L nixos /dev/sda2
# sudo btrfs filesystem label <device> <newlabel>
mount /dev/disk/by-label/nixos /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@nix
umount /mnt
mount -o compress=zstd,subvol=@ /dev/disk/by-label/nixos /mnt
mkdir /mnt/{boot,etc,home,var,swap,.snapshots,nix}
mount /dev/disk/by-label/boot /mnt/boot
mount -o compress=zstd,subvol=@home /dev/disk/by-label/nixos /mnt/home
mount -o compress=zstd,noatime,subvol=@var /dev/disk/by-label/nixos /mnt/var
mount -o compress=zstd,noatime,subvol=@snapshots /dev/disk/by-label/nixos /mnt/.snapshots
mount -o compress=zstd,noatime,subvol=@nix /dev/disk/by-label/nixos /mnt/nix
mount -o subvol=@swap /dev/disk/by-label/nixos /mnt/swap
touch /mnt/swap/swapfile
# Disable COW for this file.
chattr +C /mnt/swap/swapfile
chmod 600 /mnt/swap/swapfile
dd if=/dev/zero of=/mnt/swap/swapfile bs=1G count=8
mkswap -L swap /mnt/swap/swapfile
swapon /mnt/swap/swapfile
