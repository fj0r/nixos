{  pkgs,  lib,  ...}:

{
  nix.settings = {
    # enable flakes globally
    experimental-features = ["nix-command" "flakes"];

    # Deduplicate and optimize nix store
    auto-optimise-store = true;

    substituters = [
      # cache mirror located in China
      # status: https://mirrors.ustc.edu.cn/status/
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      # status: https://mirror.sjtu.edu.cn/
      "https://mirror.sjtu.edu.cn/nix-channels/store"

      "https://cache.nixos.org"
    ];

    builders-use-substitutes = true;
  };

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      #outputs.overlays.additions
      #outputs.overlays.modifications
      #outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    options = "ctrl:swapcaps";
  };

  console = {
    #font = "Lat2-Terminus16";
    # keyMap = "us";
    useXkbConfig = true; # use xkbOptions in tty.
  };

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    #LC_ADDRESS = "zh_CN.UTF-8";
    #LC_IDENTIFICATION = "zh_CN.UTF-8";
    #LC_MEASUREMENT = "zh_CN.UTF-8";
    #LC_MONETARY = "zh_CN.UTF-8";
    #LC_NAME = "zh_CN.UTF-8";
    #LC_NUMERIC = "zh_CN.UTF-8";
    #LC_PAPER = "zh_CN.UTF-8";
    #LC_TELEPHONE = "zh_CN.UTF-8";
    #LC_TIME = "zh_CN.UTF-8";
  };

  # Enable CUPS to print documents.
  #services.printing.enable = true;

  #programs.dconf.enable = true;

  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  security.sudo = {
    wheelNeedsPassword = false;
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    ports = [2222];
    settings = {
      PermitRootLogin = lib.mkDefault "no";
      PasswordAuthentication = false;
      GatewayPorts = "yes";
    };
    openFirewall = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ripgrep
    fd
    jq
    delta
    socat
    nmap
    zstd
    gnupg
    rsync

    git
    neovim
    nushell
    helix
    curl wget
    sqlite

    wireguard-tools
    dust
    tree
    bottom
    htop
  ];

  environment.variables = {
    EDITOR = "nvim";
  };
}
