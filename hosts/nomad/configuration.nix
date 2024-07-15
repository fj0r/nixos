# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ inputs, outputs, lib, config, pkgs, ... }:

{

  imports =
    [
      ../../modules/base.nix
      ../../modules/dev.nix
      ../../modules/x/kde.nix
      ../../modules/container.nix
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];


  # Use the GRUB 2 boot loader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 1;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "nodev"; # or "nodev" for efi only


  networking.hostName = "nomad"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://172.178.5.21:7890/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";


  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = false;
  hardware.pulseaudio.enable = false;

  services.power-profiles-daemon = {
    enable = true;
  };
  security.polkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    root.hashedPassword = "!";

    agent = {
      initialPassword = "agent";
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "systemd-journal"]; # Enable ‘sudo’ for the user.
      shell = pkgs.nushell;
      packages = with pkgs; [
        #tree
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK2Q46WeaBZ9aBkS3TF2n9laj1spUkpux/zObmliHUOI"
      ];
    };
  };
  services.displayManager.autoLogin.user = "agent";

  services.wstunnel.enable = true;
  services.wstunnel.clients.link = {
    enable = true;
    autoStart = true;
    remoteToLocal = [
      "tcp://7788:localhost:2222"
    ];
    connectTo = "ws://10.0.2.2:7787";
  };

  #home-manager.users = {
  #  agent = { pkgs, ... }: {
  #    home.packages = [ ];
  #    programs.neovim.enable = true;
  #  };
  #};


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:


  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
