const s = {
    ssh: {
        port: 7788
        user: master
        host: localhost
        targetPort: 2222
    }
}

export-env {
    $env.s = {}

    $env.s.login = [
        -o StrictHostKeyChecking=no
        -o UserKnownHostsFile=/dev/null
        -p $s.ssh.port
        $"($s.ssh.user)@($s.ssh.host)"
    ]

    $env.s.sync = {
        args: [-avp --delete -e $'ssh -p ($s.ssh.port)']
        host: $"agent@localhost"
    }
}

export def 'ssh' [] {
    ^ssh ...$s.login
}

export def 'wstunnel' [] {
    for i in [
        'passwd'
        'curl http://file.s/wstunnel -O'
        'chmod +x wstunnel'
        $'./wstunnel client -R tcp://7788:localhost:($s.ssh.targetPort) ws://10.0.2.2:7787'
    ] { print $"(ansi grey)($i)(ansi reset)" }
    ^wstunnel server ws://0.0.0.0:7787
}

export def 'setup mount' [root?='/dev/disk/by-label/nixos' boot?='/dev/disk/by-label/boot'] {
    let cmd = [
        # 启用透明压缩参数挂载 root 子卷
        $"mount -o compress=zstd,subvol=@root ($root) /mnt"
        # 挂载 boot
        $"mount ($boot) /mnt/boot"
        # 启用透明压缩参数挂载 home 子卷
        $"mount -o compress=zstd,subvol=@home ($root) /mnt/home"
        # 启用透明压缩并不记录时间戳参数挂载 nix 子卷
        $"mount -o compress=zstd,noatime,subvol=@nix ($root) /mnt/nix"
        # swapfile
        $"mount -o subvol=@swap ($root) /mnt/swap"
        $"swapon /mnt/swap/swapfile"
    ]
    | str join (char newline)
    print $"(ansi grey)($cmd)(ansi reset)"
    if ([y n] | input list 'continue?') == 'y' {
        $cmd | ^ssh ...$s.login 'sudo bash'
    }
}

def cmpl-os [] {
    [nixos arch]
}
export def 'setup partitions' [label:string@cmpl-os disk?='/dev/sda'] {
    let stmt = if $label == 'nixos' {
        [
            [$"btrfs subvolume create /mnt/@nix"]
            $"mkdir /mnt/{boot,etc,home,var,swap,.snapshots,nix}"
            [
                "mkdir /mnt/boot/efi"
                $"mount /dev/disk/by-label/boot /mnt/boot/efi"
            ]
            [$"mount -o compress=zstd,noatime,subvol=@nix /dev/disk/by-label/($label) /mnt/nix"]
        ]
    } else {
        [
            []
            $"mkdir /mnt/{boot,etc,home,var,swap,.snapshots}"
            [$"mount /dev/disk/by-label/boot /mnt/boot"]
            []
        ]
    }
    let cmd = [
        "ls /sys/firmware/efi/efivars"
        $"parted ($disk) -- mklabel gpt"
        $"parted ($disk) -- mkpart ESP fat32 1MB 512MB"
        $"parted ($disk) -- set 1 esp on"
        $"parted ($disk) -- mkpart primary 512MB 100%"
        $"mkfs.fat -F 32 -n boot /dev/sda1"
        $"mkfs.btrfs -f -L ($label) /dev/sda2"
        "# sudo btrfs filesystem label <device> <newlabel>"
        $"mount /dev/disk/by-label/($label) /mnt"
        $"btrfs subvolume create /mnt/@"
        $"btrfs subvolume create /mnt/@home"
        $"btrfs subvolume create /mnt/@var"
        $"btrfs subvolume create /mnt/@swap"
        $"btrfs subvolume create /mnt/@snapshots"
        ...($stmt | get 0)
        $"umount /mnt"
        $"mount -o compress=zstd,subvol=@ /dev/disk/by-label/($label) /mnt"
        ($stmt | get 1)
        ...($stmt| get 2)
        $"mount -o compress=zstd,subvol=@home /dev/disk/by-label/($label) /mnt/home"
        $"mount -o compress=zstd,noatime,subvol=@var /dev/disk/by-label/($label) /mnt/var"
        $"mount -o compress=zstd,noatime,subvol=@snapshots /dev/disk/by-label/($label) /mnt/.snapshots"
        ...($stmt | get 3)
        $"mount -o subvol=@swap /dev/disk/by-label/($label) /mnt/swap"
        $"touch /mnt/swap/swapfile"
        "# Disable COW for this file."
        $"chattr +C /mnt/swap/swapfile"
        $"chmod 600 /mnt/swap/swapfile"
        $"dd if=/dev/zero of=/mnt/swap/swapfile bs=1G count=8"
        $"mkswap -L swap /mnt/swap/swapfile"
        $"swapon /mnt/swap/swapfile"
    ]
    | str join (char newline)
    print $"(ansi grey)($cmd)(ansi reset)"
    if ([y n] | input list 'continue?') == 'y' {
        $cmd | ^ssh ...$s.login 'sudo bash'
    }
}

def cmpl-mirror [] {
    [
        'mirrors.ustc.edu.cn'
        'mirror.sjtu.edu.cn'
    ]
}
export def 'setup channel' [host:string@cmpl-mirror] {
    let update = [
        # 订阅镜像仓库频道
        $"nix-channel --add https://($host)/nix-channels/nixpkgs-unstable nixpkgs"
        # 请注意系统版本
        $"nix-channel --add https://($host)/nix-channels/nixos-24.05 nixos"
        # 列出频道
        $"nix-channel --list"
        # 更新并解包频道
        $"nix-channel --update"
        # 临时切换二进制缓存源，并更新生成
        $"nixos-rebuild --option substituters https://($host)/nix-channels/store switch --upgrade"
    ]
    | str join (char newline)
    print $"(ansi grey)($update)(ansi reset)"
    if ([y n] | input list 'update') == 'y' {
        $update | ^ssh ...$s.login 'sudo bash'
    }
}


export def 'setup install' [host:string@cmpl-mirror] {
    let update = [
        $"nixos-generate-config --root /mnt"
    ]
    | str join (char newline)
    print $"(ansi grey)($update)(ansi reset)"
    if ([y n] | input list 'update') == 'y' {
        $update | ^ssh ...$s.login 'sudo bash'
    }

    let cfg = open etc/configuration.nix
    print $"(ansi grey)($cfg)(ansi reset)"
    if ([y n] | input list 'sync') == 'y' {
        $cfg | ^ssh ...[
            ...$s.login
            'sudo tee /mnt/etc/nixos/configuration.nix > /dev/null'
        ]
    }

    let install = [
        $"nixos-install --option substituters https://($host)/nix-channels/store"
    ]
    | str join (char newline)
    print $"(ansi grey)($install)(ansi reset)"
    if ([y n] | input list 'install') == 'y' {
        $install | ^ssh ...$s.login 'sudo bash'
    }
}

export def 'setup fetch' [] {
    rsync ...$s.sync.args $"($s.sync.host):/etc/nixos/" etc/
}

export def 'setup sync' [] {
    rsync ...$s.sync.args etc/ $"($s.sync.host):nixos/"
    ^ssh ...$s.login 'sudo rsync -avp /home/agent/nixos/ /etc/nixos/'
}
