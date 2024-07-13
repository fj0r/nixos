{ config, pkgs, ... }:

{
  programs.plasma = {
    enable = true;
    panels = [
      # Windows-like panel at the bottom
      {
        floating = true;
        hiding = "dodgewindows";
        alignment = "center";
        lengthMode = "fit";
        location = "left";
        widgets = [
          "org.kde.plasma.kickoff"
          #"org.kde.plasma.pager"
          "org.kde.plasma.icontasks"
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
          #"org.kde.plasma.showdesktop"
        ];
      }
      # Global menu at the top
      #{
      #  location = "top";
      #  height = 26;
      #  widgets = [
      #    "org.kde.plasma.appmenu"
      #  ];
      #}
    ];
  };
}
