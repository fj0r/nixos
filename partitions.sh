parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MB 100%
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.btrfs -f -L nixos /dev/sda2
mount /dev/disk/by-label/nixos /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@swap
umount /mnt
mount -o compress=zstd,subvol=@root /dev/disk/by-label/nixos /mnt
mkdir /mnt/{home,nix,boot,swap}
mount /dev/disk/by-label/boot /mnt/boot
mount -o compress=zstd,subvol=@home /dev/disk/by-label/nixos /mnt/home
mount -o compress=zstd,noatime,subvol=@nix /dev/disk/by-label/nixos /mnt/nix
mount -o subvol=@swap /dev/disk/by-label/nixos /mnt/swap
touch /mnt/swap/swapfile
chmod 600 /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile
dd if=/dev/zero of=/mnt/swap/swapfile bs=1G count=1
mkswap -L swap /mnt/swap/swapfile
swapon /mnt/swap/swapfile
