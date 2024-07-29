# [] | nu -c 'use arch.nu; cat | arch'
export def main [] {
    let cfg = $in
    print ($cfg | table -e)

    for i in (partitions) {
        print $i
    }
}


def partitions [dev='/dev/disk/by-label/arch' mnt='/mnt' --swapsize=8 --with-create (-c)] {
    let sv = [home var swap snapshots]
    let ms = {
        root: [
            $"mount -o compress=zstd,subvol=@ ($dev) ($mnt)"
        ]
        sub: [
            $"mount -o compress=zstd,subvol=@home ($dev) ($mnt)/home"
            $"mount -o compress=zstd,noatime,subvol=@var ($dev) ($mnt)/var"
            $"mount -o compress=zstd,noatime,subvol=@snapshots ($dev) ($mnt)/.snapshots"
            $"mount -o subvol=@swap ($dev) ($mnt)/swap"
        ]
        swap: [
            $"swapon ($mnt)/swap/swapfile"
        ]
    }
    let cmd = if $with_create {
        [
            $"mount ($dev) ($mnt)"
            $"btrfs subvolume create ($mnt)/@"
            ...($sv | each {
                $"btrfs subvolume create ($mnt)/@($in)"
            })

            $"umount ($mnt)"
            ...$ms.root
            $"mkdir ($mnt)/{efi,etc,($sv | str join ',')}"
            ...$ms.sub
            $"touch ($mnt)/swap/swapfile"
            # Disable COW for this file
            $"chattr +C ($mnt)/swap/swapfile"
            $"chmod 600 ($mnt)/swap/swapfile"
            $"dd if=/dev/zero of=($mnt)/swap/swapfile bs=1G count=($swapsize)"
            $"mkswap -L swap ($mnt)/swap/swapfile"
            ...$ms.swap
        ]
    } else {
        [
            ...$ms.root
            ...$ms.sub
            ...$ms.swap
        ]
    }
    return $cmd
}
