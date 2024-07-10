{  pkgs,  lib,  ...}:

{
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [ fcitx5-rime ];
      plasma6Support = true;
    };
    #ibus.engines = with pkgs.ibus-engines; [ rime table-chinese ];
  };
}
