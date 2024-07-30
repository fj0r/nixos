export def main [] {
    let cfg = $in
    print ($cfg | table -e)

    for i in (partitions -cf) {
        print $"sudo ($i)"
    }

    print (components -kcdv | table -e)
}

def components [
    --kde (-k)
    --container (-c)
    --dev (-d)
    --vpn (-v)
    --lang (-l): list<string> = []
] {
    let manifest = [
        [ name,                     requires ];
        [ base,                     [ core ] ],
        [ base-devel,               [ core, dev ] ],
        [ linux,                    [ core ] ],
        [ linux-zen,                [ core, x ] ],
        [ linux-firmware,           [ core, dev ] ],
        [ btrfs-progs,              [ core ] ],
        [ grub,                     [ core ] ],
        [ efibootmgr,               [ core ] ],
        [ snapper,                  [ core ] ],
        [ grub-btrfs,               [ core ] ],
        [ reflector,                [ core ] ],
        [ mtools,                   [ core ] ],
        [ os-prober,                [ core ] ],
        [ dosfstools,               [ core ] ],
        [ pipewire,                 [ audio ] ],
        [ pipewire-alsa,            [ audio ] ],
        [ pipewire-pulse,           [ audio ] ],
        [ pipewire-jack,            [ audio ] ],
        [ wireplumber,              [ audio ] ],
        [ networkmanager,           [ network ] ],
        [ resolvconf,               [ network ] ],
        [ dhcpcd,                   [ network ] ],
        [ iwctl,                    [ network ] ],
        [ wireguard-tools,          [ network, vpn ] ],
        [ sudo,                     [ sys ] ],
        [ fakeroot,                 [ sys ] ],
        [ debugedit,                [ sys ] ],
        [ xdg-user-dirs,            [ sys ] ],
        [ curl,                     [ base ] ],
        [ jq,                       [ base ] ],
        [ openssh,                  [ base ] ],
        [ rsync,                    [ base ] ],
        [ tree,                     [ base ] ],
        [ net-tools,                [ base ] ],
        [ htop,                     [ base ] ],
        [ git,                      [ dev ] ],
        [ neovim,                   [ dev ] ],
        [ nushell,                  [ dev ] ],
        [ sqlite,                   [ dev ] ],
        [ ripgrep,                  [ dev ] ],
        [ fd,                       [ dev ] ],
        [ dust,                     [ dev ] ],
        [ bottom,                   [ dev ] ],
        [ alacritty,                [ dev, x ] ],
        [ neovide,                  [ dev, x ] ],
        [ podman,                   [ container ] ],
        [ buildah,                  [ container ] ],
        [ skopeo,                   [ container ] ],
        [ kubectl,                  [ kubernetes ] ],
        [ helm,                     [ kubernetes ] ],
        [ amd-ucode,                [ hardware ] ],
        [ bluez,                    [ hardware ] ],
        [ bluez-utils,              [ hardware ] ],
        [ blueman,                  [ hardware ] ],
        [ tlp,                      [ hardware ] ],
        [ tlp-rdw,                  [ hardware ] ],
        [ acpi,                     [ hardware ] ],
        [ acpi_call,                [ hardware ] ],
        [ noto-fonts,               [ font ] ],
        [ noto-fonts-emoji,         [ font ] ],
        [ ttf-ubuntu-font-family,   [ font ] ],
        [ ttf-dejavu,               [ font ] ],
        [ ttf-freefont,             [ font ] ],
        [ ttf-liberation,           [ font ] ],
        [ ttf-droid,                [ font ] ],
        [ ttf-roboto,               [ font ] ],
        [ terminus-font,            [ font ] ],
        [ xdotool,                  [ x ] ],
        [ xclip,                    [ x ] ],
        [ vivaldi,                  [ x ] ],
        [ chromium,                 [ x ] ],
        [ gparted,                  [ x ] ],
        [ nm-connection-editor,     [ x ] ],
        [ networkmanager-openvpn,   [ x, vpn ] ],
        [ plasma-desktop,           [ kde ] ],
        [ plasma-pa,                [ kde ] ],
        [ plasma-nm,                [ kde ] ],
        [ plasma-systemmonitor,     [ kde ] ],
        [ kscreen,                  [ kde ] ],
        [ kvantum,                  [ kde ] ],
        [ powerdevil,               [ kde ] ],
        [ kdeplasma-addons,         [ kde ] ],
        [ kde-gtk-config,           [ kde ] ],
        [ breeze-gtk,               [ kde ] ],
        [ dolphin,                  [ kde ] ],
        [ okular,                   [ kde ] ],
        [ gwenview,                 [ kde ] ],
        [ ark,                      [ kde ] ],
        [ mpv,                      [ kde ] ]
    ]
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
    $manifest | filter {|x| $x.requires | all {|y| $y in $r } } | get name
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
