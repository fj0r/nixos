{ config, pkgs, ... }:

{

  programs.git = {
    enable = true;
    userName = "agent";
    userEmail = "fj0rd@qq.com";
  };
}