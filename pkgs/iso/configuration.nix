# images/base-config.nix
{ lib, pkgs, ...}:

{
  imports =
    [
      ../../modules/base.nix
      ../../modules/dev.nix
      ../../modules/container.nix
      ../../modules/x/kde.nix
    ];

  networking = {
    useDHCP = false;
    hostName = "my-nixos-live"; # default: "nixos"
    usePredictableInterfaceNames = false;
    interfaces.eth0.useDHCP = true;
    # interfaces.eth0.ipv4.addresses = [
    #   {
    #     address = "192.168.1.2";
    #     prefixLength = 24;
    #   }
    # ];
    # defaultGateway = "192.168.1.1";
    # nameservers = [ "192.168.1.1" "1.1.1.1" "8.8.8.8" ];
  };

  boot.supportedFilesystems = [ "zfs" "f2fs" "btrfs" ];
  # serial connection for apu
  boot.kernelParams = [ "console=ttyS0,115200n8" ];

  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK2Q46WeaBZ9aBkS3TF2n9laj1spUkpux/zObmliHUOI"
  ];
  users.users = {
    "agent" = {
      isNormalUser = true;
      password = "";
      uid = 1000;
      extraGroups = [ "wheel" "networkmanager" "systemd-journal"]; # Enable ‘sudo’ for the user.
      shell = pkgs.nushell;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK2Q46WeaBZ9aBkS3TF2n9laj1spUkpux/zObmliHUOI"
      ];
    };
  };
  services.displayManager.autoLogin.user = "agent";


  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.addresses = true;
    publish.domain = true;
    publish.enable = true;
    publish.userServices = true;
    publish.workstation = true;
  };

  # Turn on flakes.
  nix.package = pkgs.nixVersions.stable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # includes this flake in the live iso : "/etc/nixcfg"
  environment.etc.nixcfg.source =
    builtins.filterSource
      (path: type:
        baseNameOf path
        != ".git"
        && type != "symlink"
        && !(pkgs.lib.hasSuffix ".qcow2" path)
        && baseNameOf path != "secrets")
      ../.;


  ## FIX for running out of space / tmp, which is used for building
  fileSystems."/nix/.rw-store" = {
    fsType = "tmpfs";
    options = [ "mode=0755" "nosuid" "nodev" "relatime" "size=14G" ];
    neededForBoot = true;
  };


  # # Use a high-res font.
  # boot.loader.systemd-boot.consoleMode = "0";


  services.xserver = {
    enable = lib.mkDefault false; # but still here so we can copy the XKB config to TTYs
    autoRepeatDelay = 300;
    autoRepeatInterval = 35;
  } // lib.optionalAttrs false {
  };
}