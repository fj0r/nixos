{  pkgs,  lib,  ...}:

{
  users.users = {
    root.hashedPassword = "!";

    agent = {
      initialPassword = "asdf";
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


  services.wstunnel.enable = true;
  services.wstunnel.clients.link = {
    enable = true;
    autoStart = true;
    remoteToLocal = [
      "tcp://7788:localhost:2222"
    ];
    connectTo = "ws://10.0.2.2:7787";
  };
}
