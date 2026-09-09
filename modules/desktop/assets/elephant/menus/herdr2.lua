-- elephant 菜单：herdr workspace（别名，供 】 前缀直达）
-- walker 的 providers.prefixes merge 按 provider 键控：一个 provider 只能持一个 prefix，
-- ] 与 】 两个前缀 → 两个 provider 别名指向同一数据（herdr.py）。
Name = "herdr2"
NamePretty = "Hermes 工作区"
Icon = "layout-tab"
Description = "herdr workspace 切换（回车 focus）"
SearchName = true
FixedOrder = true   -- 保留脚本顺序（当前激活的排末位）
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
