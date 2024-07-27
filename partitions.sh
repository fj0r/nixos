mount /dev/disk/by-label/arch /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/@snapshots
umount /mnt
mount -o compress=zstd,subvol=@ /dev/disk/by-label/arch /mnt
mkdir /mnt/{efi,etc,home,var,swap,.snapshots}
mount /dev/disk/by-label/boot /mnt/efi
mount -o compress=zstd,subvol=@home /dev/disk/by-label/arch /mnt/home
mount -o compress=zstd,noatime,subvol=@var /dev/disk/by-label/arch /mnt/var
mount -o compress=zstd,noatime,subvol=@snapshots /dev/disk/by-label/arch /mnt/.snapshots
mount -o subvol=@swap /dev/disk/by-label/arch /mnt/swap
touch /mnt/swap/swapfile
# Disable COW for this file.
chattr +C /mnt/swap/swapfile
chmod 600 /mnt/swap/swapfile
dd if=/dev/zero of=/mnt/swap/swapfile bs=1G count=8
mkswap -L swap /mnt/swap/swapfile
swapon /mnt/swap/swapfile
