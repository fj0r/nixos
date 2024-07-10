ls /sys/firmware/efi/efivars  # 列出 EFI 变量

parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MB -8GB
parted /dev/sda -- mkpart primary linux-swap -8GB 100%


mkfs.fat -F 32 -n boot /dev/sda1
#mkfs.xfs -f -L nixos /dev/sda1
mkfs.btrfs -f -L nixos /dev/sda2
mkswap -L swap /dev/sda3

mount /dev/disk/by-label/nixos /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
umount /mnt

mount -o compress=zstd,subvol=root /dev/disk/by-label/nixos /mnt  # 启用透明压缩参数挂载 root 子卷
mkdir /mnt/{home,nix,boot}  # 创建 home，nix，boot 目录
mount -o compress=zstd,subvol=home /dev/disk/by-label/nixos /mnt/home  # 启用透明压缩参数挂载 home 子卷
mount -o compress=zstd,noatime,subvol=nix /dev/disk/by-label/nixos /mnt/nix  # 启用透明压缩并不记录时间戳参数挂载 nix 子卷
mount /dev/disk/by-label/boot /mnt/boot  # 挂载 boot
swapon /dev/disk/by-label/swap  # 启用交换分区

#mkdir -p /mnt/boot
#mount /dev/disk/by-label/boot /mnt/boot
#swapon /dev/sda2
