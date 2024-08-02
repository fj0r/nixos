export def main [] {
    let cfg = $in
    print ($cfg | table -e)

    for i in (partitions -cf) {
        print $"sudo ($i)"
    }

    for i in (components -kcdv --lang [c js py rs hs] | setup -h 'arch_wd') {
        print $i
    }
}


def setup [
    --mnt: string = /mnt
    --master (-m): string = master
    --password (-p): string
    --hostname (-h): string
] {
    let components = $in | group-by type
    let nl = char newline
    let tab = char tab
    mut cmds = []
    mut sys_pkg = $components.sys.name
    $cmds ++= $"pacstrap -K ($mnt) ($sys_pkg | str join ' ')"
    $cmds ++= $"genfstab -U ($mnt) >> '($mnt)/etc/fstab'"
    $cmds ++= [
        $"echo '### new fstab'"
        $"cat ($mnt)/etc/fstab"
    ]
    let pkgs = $components | items {|k, v|
        match $k {
            pip => {
                $"($tab)pip install --no-cache-dir --break-system-packages ($v.name | str join ' ')"
            }
            npm => {
                $"($tab)npm install --location=global ($v.name | str join ' ')"
            }
            cargo => {
                $"($tab)cargo install ($v.name | str join ' ')"
            }
            _ => ''
        }
    }
    | str join $nl
    let post = $components.sys
    | each {|x| if ($x.post? | is-empty) {[]} else {$x.post} }
    | flatten
    | str join $'($nl)($tab)'
    let chroot_cmd = $"
        ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
        hwclock --systohc
        locale-gen
        echo 'LANG=en_US.UTF-8' > /etc/locale.conf
        echo '($hostname)' > /etc/hostname
        echo 'lock root'
        passwd -l root

        grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
        grub-mkconfig -o /boot/grub/grub.cfg

        echo '%wheel ALL=\(ALL:ALL\) NOPASSWD: ALL' >> /etc/sudoers
        useradd -m -s /bin/nu -G wheel,storage,power,audio,video,docker master
        #usermod -a -G wheel,storage,power,audio,video,docker master
        echo 'set password of master'
        passwd ($master)
    "
    | $"($in)($nl)($tab)($post)"

    let teardown = $"
        mkinitcpio -p linux
        echo 'fuser -km ($mnt)'
        umount -R ($mnt)
    "

    $cmds ++= ([
        $"arch-chroot ($mnt) /bin/bash << EOF"
        $chroot_cmd
        $pkgs
        $teardown
        "EOF"
    ] | str join $nl)
    $cmds
}

def components [
    --kde (-k)
    --container (-c)
    --dev (-d)
    --vpn (-v)
    --lang (-l): list<string> = []
] {
    let manifest = open arch.yml
    mut r = [core network sys base hardware ...$lang]
    if $container {
        $r ++= [container kubernetes]
    }
    if $vpn {
        $r ++= [vpn]
    }
    if $kde {
        $r ++= [audio font x kde]
    }
    if $dev {
        $r ++= [dev]
    }
    let r = $r | uniq
    $manifest
    | filter {|x|
        $x.tags | all {|y| $y in $r }
    }
    | each {|x|
        if ($x.type? | is-empty) {
            { ...$x, type: sys }
        } else {
            $x
        }
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
