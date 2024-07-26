install
```
sudo -i

bash partitions.sh

nixos-generate-config --root /mnt

# sync configuration.nix

nixos-install --root /mnt --flake /mnt/etc/nixos#server
    #--option substituters https://mirrors.ustc.edu.cn/nix-channels/store
    #--option substituters https://mirror.sjtu.edu.cn/nix-channels/store
```

init
```
nix-channel --add https://mirrors.ustc.edu.cn/nix-channels/nixpkgs-unstable nixpkgs
nix-channel --add https://mirrors.ustc.edu.cn/nix-channels/nixos-24.05 nixos
nix-channel --list
nix-channel --update
# 临时切换二进制缓存源，并更新生成
nixos-rebuild --option substituters https://mirrors.ustc.edu.cn/nix-channels/store switch --upgrade
```


upgrade
```
sudo nix flake update
sudo nix-channel --update
sudo nixos-rebuild switch --upgrade --flake .#nomad
    # --option binary-caches "" --option substituters false
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
