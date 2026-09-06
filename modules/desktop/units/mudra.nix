# mudra: chromium --app + CDP 外部可控浏览器模式
# https://github.com/orbsh/mudra
# 仓库部署到 ~/.config/mudra（developMode 二分，与 nvim/nushell 同架构）。
# 注意不能用 ~/.local/share/mudra——那是 mudrad 的运行时数据目录（DB/profiles）。
# `mudra` wrapper 供 niri spawn 使用，不写死绝对路径。
{
  config,
  pkgs,
  lib,
  mudraSrc,
  mudraLocalPath,
  user,
  ...
}: let
  developMode = config.programs.developMode;

  # 入口 wrapper：python 依赖（websockets、kdl-py）由系统 python 提供
  mudra = pkgs.writeShellScriptBin "mudra" ''
    exec python3 "$HOME/.config/mudra/mudra.py" "$@"
  '';
in {
  config.home-manager.users.${user} = {
    imports = [
      ({ config, lib, ... }: {
        home.packages = [ mudra ];

        home.file.".config/mudra" = if developMode then {
          # 工作站开发模式：单符号链接指向本地开发目录（out-of-store，改代码即生效）
          source = config.lib.file.mkOutOfStoreSymlink mudraLocalPath;
          force = true;
        } else {
          # 服务器/只读模式：从 flake input 部署（单个 symlink 指向 store）
          source = mudraSrc;
          force = true;
        };
      })
    ];
  };
}
