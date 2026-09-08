# herdr 终端复用（独立单元，引入即开启）
{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    herdr
  ];

  # ── herdr 配置 ────────────────────────────────────────────────
  xdg.configFile."herdr/config.toml".text = ''
    [keys]
    # 前缀键：Alt+s（保留作备份，高频动作走免 prefix 直接 chord）
    prefix = "alt+s"

    # Zellij 风格：高频动作免 prefix，ctrl+alt+单键直接触发
    goto = ["prefix+o", "ctrl+alt+o"]              # workspace picker
    focus_pane_left = ["prefix+h", "ctrl+alt+h"]
    focus_pane_down = ["prefix+j", "ctrl+alt+j"]
    focus_pane_up = ["prefix+k", "ctrl+alt+k"]
    focus_pane_right = ["prefix+l", "ctrl+alt+l"]
    split_vertical = ["prefix+0", "ctrl+alt+0"]
    split_horizontal = ["prefix+minus", "ctrl+alt+minus"]
    new_tab = ["prefix+c", "ctrl+alt+t"]
    next_tab = ["prefix+n", "ctrl+alt+n"]
    previous_tab = ["prefix+p", "ctrl+alt+p"]
    close_pane = ["prefix+x", "ctrl+alt+x"]
    zoom = ["prefix+z", "ctrl+alt+z"]
    edit_scrollback = ["prefix+e", "ctrl+alt+e"]
    copy_mode = ["prefix+[", "ctrl+alt+["]

    [terminal]
    # 新窗口/面板默认打开 nushell
    default_shell = "nu"

    # 新面板落点 = herdr 启动目录（如 ~/Configuration/nixos），非来源面板 cwd
    new_cwd = "current"

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
