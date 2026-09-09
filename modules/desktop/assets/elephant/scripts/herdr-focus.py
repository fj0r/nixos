#!/usr/bin/env python3
"""walker herdr 菜单的 focus 动作：先把 Ghostty 窗口带到前台（niri），再 herdr focus。

用法：
  herdr-focus agent <pane_id>       # herdr agent focus（agents 菜单）
  herdr-focus workspace <ws_id>     # herdr workspace focus（workspaces 菜单）

为什么需要 niri 前置：herdr focus 只切 herdr 内部 pane；若 Ghostty 窗口本身
不在前台，用户看到的还是别的窗口。先 `niri msg action focus-window` 把
Ghostty 提到前台，herdr 内部切换才有可见效果。
"""
import json
import shutil
import subprocess
import sys

GHOSTTY_APP_ID = "com.mitchellh.ghostty"  # niri windows 里 ghostty 的 app-id（实测）


def focus_ghostty_window():
    r = subprocess.run(["niri", "msg", "--json", "windows"], capture_output=True, text=True)
    if r.returncode != 0:
        return
    try:
        wins = json.loads(r.stdout)
    except json.JSONDecodeError:
        return
    for w in wins:
        if w.get("app_id") == GHOSTTY_APP_ID:
            subprocess.run(["niri", "msg", "action", "focus-window", "--id", str(w["id"])],
                           capture_output=True)
            return


def main():
    if len(sys.argv) < 3:
        sys.exit("usage: herdr-focus agent <pane_id> | herdr-focus workspace <ws_id>")
    kind, target = sys.argv[1], sys.argv[2]
    focus_ghostty_window()
    herdr = shutil.which("herdr")
    if not herdr:
        sys.exit("herdr not found in PATH")
    if kind == "agent":
        subprocess.run([herdr, "agent", "focus", target])
    elif kind == "workspace":
        subprocess.run([herdr, "workspace", "focus", target])
    else:
        sys.exit(f"unknown kind: {kind}")


if __name__ == "__main__":
    main()
