-- elephant 菜单：herdr workspace（别名，供 】 前缀直达）
-- walker 的 providers.prefixes merge 按 provider 键控：一个 provider 只能持一个 prefix，
-- spaces 菜单一个 provider 即可（本文件），win+space 分给了 agents（herdr.lua）。
Name = "herdr2"
NamePretty = "Hermes 工作区"
Icon = "layout-tab"
Description = "herdr workspace 切换（回车 focus），副标题显示 agent 状态 × git 状态"
SearchName = true
FixedOrder = true
Keywords = { "herdr", "workspace", "工作区", "切换" }

-- 默认 action：先 niri 聚焦 Ghostty 窗口，再 herdr focus 该 workspace
Action = "python3 ~/.config/elephant/scripts/herdr-focus.py workspace %VALUE%"

function GetEntries(query)
    local script = (os.getenv("HOME") or "~") .. "/.config/elephant/scripts/herdr.py"
    local handle = io.popen("python3 " .. script .. " spaces " .. tostring(query or ""))
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
