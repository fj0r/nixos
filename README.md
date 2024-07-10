```
sudo -i


nix-channel --add https://mirrors.ustc.edu.cn/nix-channels/nixpkgs-unstable nixpkgs  # 订阅镜像仓库频道
nix-channel --add https://mirrors.ustc.edu.cn/nix-channels/nixos-24.05 nixos  # 请注意系统版本
nix-channel --list  # 列出频道，这一步是确认修改没有出错
nix-channel --update  # 更新并解包频道
nixos-rebuild --option substituters https://mirrors.ustc.edu.cn/nix-channels/store switch --upgrade  # 临时切换二进制缓存源，并更新生成

sh partitions.sh

nixos-generate-config --root /mnt

# , sync configuration.nix

nixos-install --option substituters https://mirrors.ustc.edu.cn/nix-channels/store
#nixos-install
#nixos-install --option substituters https://mirror.sjtu.edu.cn/nix-channels/store
```


modify
```
nixos-rebuild switch --upgrade --option binary-caches "" --option substituters false
```

upgrade
```
nixos-rebuild switch --upgrade
```

search
```
nix-env -qaP '.*pip.*'
```
