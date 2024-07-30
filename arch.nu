# [] | nu -c 'use arch.nu; cat | arch'
export def main [] {
    let cfg = $in
    print ($cfg | table -e)

    for i in (partitions -cf) {
        print $i
    }
}


def partitions [
    disk='/dev/sda'
    mnt='/mnt'
    boot='/mnt/efi'
    --label (-l) = 'arch'
    --swapsize=8
    --with-format (-f)
    --with-create (-c)
] {
    let dev_boot = $"($disk)1"
    let dev = $"($disk)2"
    let sv = [[vol dir mnt ];
        [home      home       [zstd]]
        [var       var        [zstd noatime]]
        [snapshots .snapshots [zstd noatime]]
        [swap      swap       []]
    ]
    let ms = {
        root: [
            $"mount -o compress=zstd,subvol=@ ($dev) ($mnt)"
        ]
        boot: [
            $"mount ($dev_boot) ($boot)"
        ]
        sub: ($sv | each {|x|
            let opt = $x.mnt
            | each {|y|
                match $y {
                    zstd => 'compress=zstd'
                    _ => $y
                }
            }
            | append $"subvol=@($x.vol)"
            | str join ','
            $"mount -o ($opt) ($dev) ($mnt)/($x.dir)"
        })
        swap: [
            $"swapon ($mnt)/swap/swapfile"
        ]
    }
    let create_cmd = if $with_create {
        [
            $"parted ($disk) -- mklabel gpt"
            $"parted ($disk) -- mkpart ESP fat32 1MB 512MB"
            $"parted ($disk) -- set 1 esp on"
            $"parted ($disk) -- mkpart primary 512MB 100%"
            $"mkfs.fat -F 32 -n boot ($dev_boot)"
            $"mkfs.btrfs -f -L ($label) ($dev)"
        ]
    } else {
        []
    }
    let mount_cmd = if $with_format {
        [
            $"mount ($dev) ($mnt)"
            $"btrfs subvolume create ($mnt)/@"
            ...($sv | each {
                $"btrfs subvolume create ($mnt)/@($in.vol)"
            })

            $"umount ($mnt)"
            ...$ms.root
            $"mkdir ($mnt)/{efi,etc,($sv | get dir | str join ',')}"
            ...$ms.boot
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
            ...$ms.boot
            ...$ms.sub
            ...$ms.swap
        ]
    }
    [...$create_cmd ...$mount_cmd]
}
