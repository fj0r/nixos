install
```
sudo -i

bash partitions.sh

nixos-generate-config --root /mnt

# , sync configuration.nix

nixos-install --root /mnt --flake /mnt/etc/nixos#server
    #--option substituters https://mirrors.ustc.edu.cn/nix-channels/store
    #--option substituters https://mirror.sjtu.edu.cn/nix-channels/store
#nixos-install
```

init
```
nix-channel --add https://mirrors.ustc.edu.cn/nix-channels/nixpkgs-unstable nixpkgs  # 订阅镜像仓库频道
nix-channel --add https://mirrors.ustc.edu.cn/nix-channels/nixos-24.05 nixos  # 请注意系统版本
nix-channel --list  # 列出频道，这一步是确认修改没有出错
nix-channel --update  # 更新并解包频道
nixos-rebuild --option substituters https://mirrors.ustc.edu.cn/nix-channels/store switch --upgrade  # 临时切换二进制缓存源，并更新生成

```


modify
```
nix flake update
nixos-rebuild switch --upgrade --flake .#server
nixos-rebuild switch --upgrade --option binary-caches "" --option substituters false
```

upgrade
```
nix flake update
nix-channel --update
nixos-rebuild switch --upgrade --flake .#nomad
```

search
```
nix-env -qaP '.*pip.*'
```

clean
```
nix-collect-garbage --delete-old
```

inspect
```
sudo nix repl -f '<nixpkgs>'
:?

sudo nix repl
:lf .
outputs.nixosConfigurations.nixos.pkgs.kdePackages.
```
