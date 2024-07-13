{  pkgs,  lib,  ...}:

{

  imports = [
    ./default.nix
    ./font.nix
    ./fcitx.nix
  ];

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  # sudo nix repl
  # :lf .
  # outputs.nixosConfigurations.nixos.pkgs.kdePackages.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    kontact
    kalarm
    kmag
    kate
    kwrited
    elisa
    oxygen
  ];
  programs.partition-manager.enable = true;

  environment.systemPackages = with pkgs; [
    firefox
  ];
}
