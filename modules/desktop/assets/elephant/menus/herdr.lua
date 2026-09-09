-- elephant 菜单：herdr workspace 列表
-- 数据来自 python herdr.py（herdr workspace list，focused 置顶标 *）
Name = "herdr"
NamePretty = "Hermes 工作区"
Icon = "layout-tab"
Description = "herdr workspace 切换（回车 focus）"
SearchName = true
FixedOrder = true
Keywords = { "herdr", "workspace", "工作区", "切换" }

-- 默认 action：focus 该 workspace
Action = "herdr workspace focus %VALUE%"

function GetEntries(query)
    local script = (os.getenv("HOME") or "~") .. "/.config/elephant/scripts/herdr.py"
    local handle = io.popen("python3 " .. script .. " list " .. tostring(query or ""))
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
