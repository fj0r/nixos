{  pkgs,  lib,  ...}:

{
  i18n.inputMethod = {
    enabled = "fcitx5";
    #type = "fcitx5";
    #enabled = true;
    fcitx5 = {
      #addons = with pkgs; [ fcitx5-rime ];
      plasma6Support = true;
      # TODO: default en
      settings = {
        inputMethod = {};
      };
    };
      #ibus.engines = with pkgs.ibus-engines; [ rime table-chinese ];
  };
}
