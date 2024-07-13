### {{{ base.nu
$env.comma_scope = {|_|{ created: '2024-07-06{6}09:51:58' }}
$env.comma = {|_|{}}
### }}}

### {{{ 01_env.nu
for e in [nuon toml yaml json] {
    if ($".env.($e)" |  path exists) {
        open $".env.($e)" | load-env
    }
}
### }}}

'ssh'
| comma val null {
    port: 7788
    user: agent
    host: localhost
    targetPort: 2222
}

'login'
| comma val computed {|a,s,m| [
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -p $s.ssh.port
    $"($s.ssh.user)@($s.ssh.host)"
] }

'sync'
| comma val computed {|a,s,m|
    {
        args: [-avp --delete -e $'ssh -p ($s.ssh.port)']
        host: $"agent@localhost"
    }
}

'ssh'
| comma fun {|a,s|
    ^ssh ...$s.login
}

'wstunnel'
| comma fun {|a,s|
    for i in [
        'passwd'
        'curl http://file.s/wstunnel -O'
        'chmod +x wstunnel'
        $'./wstunnel client -R tcp://7788:localhost:($s.ssh.targetPort) ws://10.0.2.2:7787'
    ] { print $"(ansi grey)($i)(ansi reset)" }
    wstunnel server ws://0.0.0.0:7787
}

'setup mount'
| comma fun {|a,s,_|
    let root = $a.0? | default '/dev/disk/by-label/nixos'
    let boot = $a.1? | default '/dev/disk/by-label/boot'
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
} {
    cmp: {|a,s| [
        '/dev/sda'
        ] }
}

'setup partitions'
| comma fun {|a,s,_|
    let disk = $a.0? | default '/dev/sda'
    let cmd = [
        "ls /sys/firmware/efi/efivars"
        $"parted ($disk) -- mklabel gpt"
        $"parted ($disk) -- mkpart ESP fat32 1MB 512MB"
        $"parted ($disk) -- set 1 esp on"
        $"parted ($disk) -- mkpart primary 512MB 100%"
        $"mkfs.fat -F 32 -n boot /dev/sda1"
        $"mkfs.btrfs -f -L nixos /dev/sda2"
        $"mount /dev/disk/by-label/nixos /mnt"
        $"btrfs subvolume create /mnt/@root"
        $"btrfs subvolume create /mnt/@home"
        $"btrfs subvolume create /mnt/@nix"
        $"btrfs subvolume create /mnt/@swap"
        $"umount /mnt"
        # 启用透明压缩参数挂载 root 子卷
        $"mount -o compress=zstd,subvol=@root /dev/disk/by-label/nixos /mnt"
        # 创建 home，nix，boot 目录
        $"mkdir /mnt/{home,nix,boot,swap}"
        # 挂载 boot
        $"mount /dev/disk/by-label/boot /mnt/boot"
        # 启用透明压缩参数挂载 home 子卷
        $"mount -o compress=zstd,subvol=@home /dev/disk/by-label/nixos /mnt/home"
        # 启用透明压缩并不记录时间戳参数挂载 nix 子卷
        $"mount -o compress=zstd,noatime,subvol=@nix /dev/disk/by-label/nixos /mnt/nix"
        # swapfile
        $"mount -o subvol=@swap /dev/disk/by-label/nixos /mnt/swap"
        $"touch /mnt/swap/swapfile"
        $"chmod 600 /mnt/swap/swapfile"
        # Disable COW for this file.
        $"chattr +C /mnt/swap/swapfile"
        $"dd if=/dev/zero of=/mnt/swap/swapfile bs=1G count=8"
        $"mkswap -L swap /mnt/swap/swapfile"
        $"swapon /mnt/swap/swapfile"
    ]
    | str join (char newline)
    print $"(ansi grey)($cmd)(ansi reset)"
    if ([y n] | input list 'continue?') == 'y' {
        $cmd | ^ssh ...$s.login 'sudo bash'
    }
} {
    cmp: {|a,s| [
        '/dev/sda'
        ] }
}

'setup channel'
| comma fun {|a,s,_|
    let host = $a.0? | default 'mirrors.ustc.edu.cn'
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
} {
    cmp: {|a,s| [
        'mirrors.ustc.edu.cn'
        'mirror.sjtu.edu.cn'
    ] }
}


'setup install'
| comma fun {|a,s,_|
    let host = $a.0? | default 'mirrors.ustc.edu.cn'
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
} {
    cmp: {|a,s| [
        'mirrors.ustc.edu.cn'
        'mirror.sjtu.edu.cn'
    ] }
}

'setup fetch'
| comma fun {|a,s,_|
    rsync ...$s.sync.args $"($s.sync.host):/etc/nixos/" etc/
}

'setup sync'
| comma fun {|a,s,_|
    rsync ...$s.sync.args etc/ $"($s.sync.host):nixos/" 
    ^ssh ...$s.login 'sudo rsync -avp /home/agent/nixos/ /etc/nixos/'

}
