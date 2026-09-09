#!/usr/bin/env python3
"""elephant 菜单 "herdr" 的数据源：herdr workspace 列表。

子命令：
  list <query>  输出 TAB 三列：workspace label <TAB> agent_status <TAB> workspace_id
                （value 列=workspace_id，供 Action 的 `herdr workspace focus` 用）
                当前激活的 workspace 标注 "* " 前缀排在末位。

elephant 常驻进程 env 无 shell alias，herdr 走 PATH 查找（store 路径稳定）。
仅用 Python 标准库（json/subprocess），外部依赖 herdr 命令。
"""
import json
import shutil
import subprocess
import sys


def list_workspaces(query):
    herdr = shutil.which("herdr")
    if not herdr:
        return
    out = subprocess.run([herdr, "workspace", "list"], capture_output=True, text=True)
    if out.returncode != 0:
        return
    try:
        data = json.loads(out.stdout)
    except json.JSONDecodeError:
        return
    workspaces = (data.get("result") or {}).get("workspaces") or []
    rows = []
    for ws in workspaces:
        status = ws.get("agent_status") or "unknown"
        mark = "* " if ws.get("focused") else ""
        rows.append((f"{mark}{ws['label']}", status, ws["workspace_id"]))
    if query:
        q = query.lower()
        rows = [r for r in rows if q in r[0].lower() or q in r[1].lower()]
    rows.sort(key=lambda r: r[0].startswith("* "))
    for text, subtext, value in rows:
        print(f"{text}\t{subtext}\t{value}")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    if cmd == "list":
        list_workspaces(sys.argv[2] if len(sys.argv) > 2 else "")
