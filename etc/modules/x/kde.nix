{  pkgs,  lib,  ...}:

{

  imports = [
    ./default.nix
    ./font.nix
    ./fcitx.nix
  ];

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    oxygen
  ];

}
