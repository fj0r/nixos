#!/usr/bin/env python3
"""elephant 菜单 "herdr" 的数据源。

子命令：
  agents <query>  合并列表：agent 在前（herdr agent list），其后是未被任何
                  agent 占用的 workspace（herdr workspace list 按 workspace_id
                  去重）。TAB 四列：
                  <label> <TAB> <状态 × cwd短名/git状态> <TAB> <value> <TAB> <状态>
                  排序：blocked → done → working → 其余，组内 focused 的（"* " 前缀）排同组末位。
                  agent label = agent 名 + workspace label（如 hermes·nixos）；
                  agent 的 value = "agent:<pane_id>"，空 workspace 的 value = "workspace:<id>"。

Action 用 value 精确 focus（前缀区分 agent/workspace），避免同名 label 歧义。
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
    """短 git 状态：'分支 dirty+2' / '分支 clean' / ''（非 git 目录）。"""
    r = subprocess.run(["git", "-C", path, "status", "--porcelain"],
                       capture_output=True, text=True, timeout=5)
    if r.returncode != 0:
        return ""
    b = subprocess.run(["git", "-C", path, "branch", "--show-current"],
                       capture_output=True, text=True, timeout=5)
    branch = b.stdout.strip()
    lines = [l for l in r.stdout.splitlines() if l.strip()]
    state = "clean" if not lines else f"dirty+{len(lines)}"
    return f"{branch} {state}" if branch else state


# 状态分组：blocked 最前，其次 done，再次 working，其余在后
_STATUS_RANK = {"blocked": 0, "done": 1, "working": 2}


def list_agents(query):
    agent_data = _run_herdr("agent", "list")
    if agent_data is None:
        return
    agents = (agent_data.get("result") or {}).get("agents") or []
    occupied = {a.get("workspace_id") for a in agents if a.get("workspace_id")}
    rows = []
    for a in agents:
        cwd_short = (a.get("cwd") or "?").rstrip("/").split("/")[-1]
        sub = f"{a.get('agent_status') or 'unknown'} × {cwd_short}"
        mark = "* " if a.get("focused") else ""
        text = f"{mark}{a.get('agent')}·{cwd_short}"
        rows.append((text, sub, f"agent:{a.get('pane_id')}",
                     a.get("agent_status") or "unknown"))
    # 未被 agent 占用的 workspace（去重：agent 已占用的跳过）；
    # cwd 从 pane list 反查（无 agent 的 workspace 只有 pane）
    ws_data = _run_herdr("workspace", "list")
    panes = _pane_cwd_map()
    if ws_data is not None:
        for ws in (ws_data.get("result") or {}).get("workspaces") or []:
            if ws.get("workspace_id") in occupied:
                continue
            status = ws.get("agent_status") or "unknown"
            sub = [status]
            git = git_status(_ws_cwd(ws, panes))
            if git:
                sub.append(git)
            mark = "* " if ws.get("focused") else ""
            rows.append((f"{mark}{ws['label']}", " × ".join(sub),
                         f"workspace:{ws['workspace_id']}", status))
    _emit(rows, query)


def _pane_cwd_map():
    """workspace_id → 首个 pane 的 cwd（pane list 每项都有 cwd，覆盖无 agent 的 workspace）。"""
    data = _run_herdr("pane", "list")
    if data is None:
        return {}
    cwd_map = {}
    for p in (data.get("result") or {}).get("panes") or []:
        ws = p.get("workspace_id")
        cwd = p.get("cwd")
        if ws and cwd and ws not in cwd_map:
            cwd_map[ws] = cwd
    return cwd_map


def _ws_cwd(ws, cwd_map):
    """workspace → 代表性 cwd（pane 反查；失败退回 label）。"""
    return cwd_map.get(ws.get("workspace_id")) or ws.get("label")


def _emit(rows, query):
    if query:
        q = query.lower()
        rows = [r for r in rows if q in r[0].lower() or q in r[1].lower()]
    # 状态分组序（_STATUS_RANK，缺省兜底 3），组内 focused 排末位
    rows.sort(key=lambda r: (_STATUS_RANK.get(r[3], 3),
                             r[0].startswith("* ")))
    for text, subtext, value, _status in rows:
        print(f"{text}\t{subtext}\t{value}")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "agents"
    query = sys.argv[2] if len(sys.argv) > 2 else ""
    list_agents(query)
