{ config, pkgs, ... }:

{
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons =
      let
        # 为了不使用默认的 rime-data，这里需要 override
        # 参考 https://github.com/NixOS/nixpkgs/blob/e4246ae1e7f78b7087dce9c9da10d28d3725025f/pkgs/tools/inputmethods/fcitx5/fcitx5-rime.nix
        config.packageOverrides = pkgs: {
          fcitx5-rime = pkgs.fcitx5-rime.override {
            rimeDataPkgs = [
              pkgs.rime-data ./rime-data-wubi
            ];
          };
        };
      in
      with pkgs; [
        fcitx5-rime
        fcitx5-configtool
        fcitx5-chinese-addons
      ];
  };
}
