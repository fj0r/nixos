{ config, pkgs, ... }:

{
  xdg.configFile = {
    "nvim" = {
        source = builtins.fetchGit {
          url = "https://github.com/fj0r/nvim-lua.git";
          rev = "87c00b618daeb16f5cd6e0e53a80eaec8d649182";
        };
      };
      "nushell" = {
        source = builtins.fetchGit {
          url = "https://github.com/fj0r/nushell.git";
          rev = "d782ad4fa03134b94e5f9adc5a6ee215bbb38a3a";
        };
      };
  };
}