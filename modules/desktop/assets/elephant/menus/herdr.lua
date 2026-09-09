-- elephant 菜单：herdr agent 列表
-- 数据来自 python herdr.py agents（agent 名·cwd 短名，状态×cwd 短名副标题，focused 排末位）
Name = "herdr"
NamePretty = "Hermes agents"
Icon = "user-avatars"
Description = "herdr agent 切换（回车 focus 该 agent 所在 pane）"
SearchName = true
FixedOrder = true
Keywords = { "herdr", "agent", "切换" }

-- 默认 action：先 niri 聚焦 Ghostty 窗口，再 herdr focus 该 agent
Action = "python3 ~/.config/elephant/scripts/herdr-focus.py agent %VALUE%"

function GetEntries(query)
    local script = (os.getenv("HOME") or "~") .. "/.config/elephant/scripts/herdr.py"
    local handle = io.popen("python3 " .. script .. " agents " .. tostring(query or ""))
    if not handle then return {} end
    local entries = {}
    for line in handle:lines() do
        local t = {}
        for f in (line .. "\t"):gmatch("(.-)\t") do t[#t + 1] = f end
        if #t >= 3 then
            table.insert(entries, { Text = t[1], Subtext = t[2], Value = t[3] })
        end
    end
    handle:close()
    return entries
end
