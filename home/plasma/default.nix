{ config, pkgs, ... }:

{
  programs.plasma = {
    enable = true;
    panels = [
      # Windows-like panel at the bottom
      {
        floating = false;
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
    spectacle.shortcuts = {
      launch = "Print";
      launchWithoutCapturing = "Meta+Print";
      captureActiveWindow = "Meta+Alt+S";
      captureEntireDesktop = "Meta+Shift+S";
      captureRectangularRegion = "Meta+S";
      captureWindowUnderCursor = "Meta+Ctrl+S";
      recordRegion = "Meta+Shift+R";
      recordScreen = "Meta+Alt+R";
      recordWindow = "Meta+Ctrl+R";
    };
    shortcuts = {
    };
  };
}
