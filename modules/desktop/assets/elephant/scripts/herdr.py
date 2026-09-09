#!/usr/bin/env python3
"""elephant 菜单 "herdr" / "herdr2" 的数据源。

子命令：
  agents <query>  agent 列表（herdr agent list），TAB 三列：
                  <label> <TAB> <agent_status × cwd短名> <TAB> <pane_id>
                  当前 focused 的 agent 标注 "* " 前缀排在末位。
                  label = agent 名 + workspace label（如 hermes·nixos）。
  spaces <query>  workspace 列表（herdr workspace list），TAB 三列：
                  <label> <TAB> <agent_status × git 状态> <TAB> <workspace_id>
                  当前 focused 的 workspace 标注 "* " 前缀排在末位。
                  git 状态：dirty 增删文件计数，clean，或空（非 git 目录）。

Action 用 workspace_id / pane_id 精确 focus，避免同名 label 歧义。
elephant 常驻进程 env 无 shell alias，herdr 走 PATH 查找。
仅用 Python 标准库（json/subprocess），外部依赖 herdr 命令。
"""
import json
import shutil
import subprocess
import sys


def _run_herdr(*args):
    herdr = shutil.which("herdr")
    if not herdr:
        return None
    out = subprocess.run([herdr, *args], capture_output=True, text=True)
    if out.returncode != 0:
        return None
    try:
        return json.loads(out.stdout)
    except json.JSONDecodeError:
        return None


def git_status(path):
    """短 git 状态：'dirty +2/-1' / 'clean' / ''（非 git）。"""
    r = subprocess.run(["git", "-C", path, "status", "--porcelain"],
                       capture_output=True, text=True, timeout=5)
    if r.returncode != 0:
        return ""
    lines = [l for l in r.stdout.splitlines() if l.strip()]
    if not lines:
        return "clean"
    return f"dirty +{len(lines)}"


def list_spaces(query):
    data = _run_herdr("workspace", "list")
    if data is None:
        return
    workspaces = (data.get("result") or {}).get("workspaces") or []
    rows = []
    for ws in workspaces:
        status = ws.get("agent_status") or "unknown"
        sub = [status]
        git = git_status(ws["label"] if False else _ws_cwd(ws))
        if git:
            sub.append(git)
        mark = "* " if ws.get("focused") else ""
        rows.append((f"{mark}{ws['label']}", " × ".join(sub), ws["workspace_id"]))
    _emit(rows, query)


def _ws_cwd(ws):
    """workspace → 代表性 cwd：取该 workspace 首个 agent 的 cwd（失败则退回 label）。"""
    data = _run_herdr("agent", "list")
    if data:
        for a in (data.get("result") or {}).get("agents") or []:
            if a.get("workspace_id") == ws.get("workspace_id"):
                return a.get("cwd") or ws.get("label")
    return ws.get("label")


def list_agents(query):
    data = _run_herdr("agent", "list")
    if data is None:
        return
    agents = (data.get("result") or {}).get("agents") or []
    rows = []
    for a in agents:
        cwd_short = (a.get("cwd") or "?").rstrip("/").split("/")[-1]
        sub = f"{a.get('agent_status') or 'unknown'} × {cwd_short}"
        mark = "* " if a.get("focused") else ""
        text = f"{mark}{a.get('agent')}·{cwd_short}"
        rows.append((text, sub, a.get("pane_id")))
    _emit(rows, query)


def _emit(rows, query):
    if query:
        q = query.lower()
        rows = [r for r in rows if q in r[0].lower() or q in r[1].lower()]
    rows.sort(key=lambda r: r[0].startswith("* "))
    for text, subtext, value in rows:
        print(f"{text}\t{subtext}\t{value}")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "spaces"
    query = sys.argv[2] if len(sys.argv) > 2 else ""
    if cmd == "agents":
        list_agents(query)
    elif cmd == "spaces":
        list_spaces(query)
