# herdr 终端复用（独立单元，引入即开启）
{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    herdr
  ];

  # ── herdr 配置 ────────────────────────────────────────────────
  xdg.configFile."herdr/config.toml".text = ''
    [keys]
    # 前缀键：Alt+s
    prefix = "alt+s"

    [terminal]
    # 新窗口/面板默认打开 nushell
    default_shell = "nu"

    [ui]
    # tmux 风格：面板间共享分隔线，无独立边框和外框
    pane_borders = false
    pane_outer_borders = false
    pane_gaps = false

    # workspace 只有一个标签页时隐藏顶栏
    hide_tab_bar_when_single_tab = true
  '';

  # ── Ghostty 默认启动 herdr ────────────────────────────────────
  programs.ghostty.settings.command = "${pkgs.herdr}/bin/herdr";
}
