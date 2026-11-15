local path = arg[1] or "addons/ProfessionReagents/src"
local name = "ProfessionReagents"
local passed, failed = 0, 0

local function equal(actual, expected)
    assert(actual == expected, ("expected %s, got %s"):format(tostring(expected), tostring(actual)))
end

local function test(label, run)
    local ok, reason = pcall(run)
    if ok then
        passed = passed + 1
        print("ok - " .. label)
    else
        failed = failed + 1
        io.stderr:write("FAIL - " .. label .. ": " .. reason .. "\n")
    end
end

local function makeTooltip(supportedScripts)
    local tooltip = { lines = {}, scripts = {}, counts = {} }
    function tooltip:AddLine(text, r, g, b, wrap)
        self.lines[#self.lines + 1] = { text = text, r = r, g = g, b = b, wrap = wrap }
    end
    function tooltip.HasScript(_, script)
        return supportedScripts[script] == true
    end
    function tooltip:HookScript(script, handler)
        assert(self:HasScript(script))
        self.counts[script] = (self.counts[script] or 0) + 1
        self.scripts[script] = handler
    end
    function tooltip:Clear()
        self.lines = {}
        if self.scripts.OnTooltipCleared then
            self.scripts.OnTooltipCleared(self)
        end
    end
    function tooltip:GetItem()
        return nil, self.link
    end
    return tooltip
end

local function loadAddon(api)
    local addon = {}
    local env = setmetatable(api or {}, { __index = _G })
    for line in io.lines(path .. "/" .. name .. ".toc") do
        if line:match("%.lua$") then
            local chunk = assert(loadfile(path .. "/" .. line:gsub("\\", "/")))
            setfenv(chunk, env)(name, addon)
        end
    end
    return addon, env
end

local function boot(locale, options)
    local callbacks, messages = {}, {}
    local api = {
        GetLocale = locale and function()
            return locale
        end,
        GetBuildInfo = function()
            return "1.60.1", "70938", "", 16001
        end,
        C_AddOns = {
            GetAddOnMetadata = function()
                return "1.0.0"
            end,
        },
        Enum = { TooltipDataType = { Item = 0 } },
        TooltipDataProcessor = {
            AddTooltipPostCall = function(itemType, callback)
                equal(itemType, 0)
                callbacks[#callbacks + 1] = callback
            end,
        },
        NORMAL_FONT_COLOR = { r = 1, g = 0.82, b = 0 },
        SlashCmdList = {},
        print = function(message)
            messages[#messages + 1] = message
        end,
    }
    for key, value in pairs(options or {}) do
        api[key] = value
    end
    local addon, env = loadAddon(api)
    if not env.CreateFrame then
        addon.Initialize()
    end
    return addon, callbacks, env, messages
end

local function recipeIterator(rows)
    local index = 0
    return function()
        index = index + 1
        return unpack(rows[index] or {})
    end
end

test("build an index and deduplicate repeated profession use", function()
    local addon = loadAddon()
    local items, stats = addon.BuildReagentIndex(recipeIterator({
        { 171, 1, { [101] = 4, [102] = 1 } },
        { 171, 2, { [101] = 2 } },
        { 202, 3, { [102] = 1 } },
        { 197, 4 },
        { 197, 5, {} },
    }))
    equal(items[101][171], true)
    equal(items[101][202], nil)
    equal(items[102][171], true)
    equal(items[102][202], true)
    equal(items[103], nil)
    equal(stats.recipes, 5)
    equal(stats.indexedRecipes, 3)
    equal(stats.materials, 2)
    equal(stats.professions, 2)
end)

test("invalid IDs and incomplete recipe records", function()
    local addon = loadAddon()
    for _, id in ipairs({ -1, 0, 0.5, 0 / 0, math.huge, "123", false, {} }) do
        equal(addon.IsID(id), false)
    end
    local items, stats = addon.BuildReagentIndex(recipeIterator({
        { 171, 1, { [101] = 1, [0] = 1, [102] = 0, ["103"] = 1 } },
        { 171, 2, "invalid" },
        { 171, false, { [104] = 1 } },
        { 202, 3 },
    }))
    equal(items[101][171], true)
    equal(stats.invalid, 5)
    equal(stats.materials, 1)
end)

test("the shipped TOC targets Forever and loads the correct saved variables and dataset", function()
    local lines = {}
    for line in io.lines(path .. "/" .. name .. ".toc") do
        lines[line] = true
    end
    for _, line in ipairs({
        "## Interface: 16001",
        "## AllowLoadGameType: camelot",
        "## SavedVariables: ProfessionReagentsDB",
        "Database\\Forever.lua",
    }) do
        assert(lines[line], "missing TOC line: " .. line)
    end
end)

test("the checked-in Forever dataset prepares successfully", function()
    local addon = boot("enUS")
    equal(addon.data.source.version, "1.10.0")
    equal(addon.data.source.build, "1.60.1.70938")
    equal(addon.data.stats.recipes, 2517)
    equal(addon.data.stats.indexedRecipes, 2485)
    equal(addon.data.stats.materials, 588)
    equal(addon.data.stats.professions, 12)
    local expected = {
        [2589] = "Blacksmithing, Engineering, First Aid, Tailoring",
        [2592] = "Engineering, First Aid, Tailoring",
        [2318] = "Blacksmithing, Engineering, Leatherworking, Skinning, Tailoring",
        [2840] = "Blacksmithing, Engineering, Leatherworking, Mining",
        [2770] = "Mining",
        [2447] = "Alchemy, Cooking, First Aid, Herbalism",
        [765] = "Alchemy, Herbalism",
        [10940] = "Blacksmithing, Enchanting, Leatherworking",
        [769] = "Cooking",
        [6291] = "Cooking, Fishing",
        [6289] = "Cooking",
        [774] = "Blacksmithing, Engineering",
        [4357] = "Engineering",
        [14044] = "Leatherworking",
    }
    for id, names in pairs(expected) do
        equal(table.concat(addon.lookup[id].plain, ", "), names)
    end
    equal(addon.lookup[999999999], nil)
end)

test("missing and malformed data degrade safely", function()
    local addon = boot()
    equal(addon.PrepareLookup(nil, "enUS", addon.strings), nil)
    equal(addon.PrepareLookup({}, "enUS", addon.strings), nil)
    local data = addon.data
    data.items[2589] = { 999999 }
    equal(addon.PrepareLookup(data, "enUS", addon.strings), nil)
end)

test("localization and localized ordering", function()
    local en = boot("enUS")
    local gb = boot("enGB")
    local es = boot("esES")
    local mx = boot("esMX")
    local fallback = boot("jaJP")
    equal(en.strings.heading, gb.strings.heading)
    equal(en.strings.heading, fallback.strings.heading)
    equal(es.strings.heading, "Utilizado en:")
    equal(mx.strings.heading, es.strings.heading)
    equal(en.lookup[2589].plain[1], "Blacksmithing")
    equal(es.lookup[2589].plain[1], "Costura")
    equal(mx.lookup[2589].plain[#mx.lookup[2589].plain], "Sastrería")
end)

test("each client locale renders its heading and profession names in both layouts", function()
    local expected = {
        deDE = { "Verwendet in:", "Bergbau" },
        enUS = { "Used in:", "Mining" },
        enGB = { "Used in:", "Mining" },
        esES = { "Utilizado en:", "Minería" },
        esMX = { "Utilizado en:", "Minería" },
        frFR = { "Utilisé en :", "Minage" },
        itIT = { "Usato in:", "Estrazione" },
        koKR = { "사용처:", "채광" },
        ptBR = { "Usado em:", "Mineração" },
        ruRU = { "Используется в:", "Горное дело" },
        zhCN = { "用于：", "采矿" },
        zhTW = { "用於：", "採礦" },
    }
    for locale, labels in pairs(expected) do
        local addon, callbacks, api = boot(locale, { ProfessionReagentsDB = { icons = false } })
        local tip = makeTooltip({ OnTooltipCleared = true })
        callbacks[1](tip, { id = 2770 })
        equal(tip.lines[2].text, labels[1])
        equal(tip.lines[3].text, labels[2])

        addon.settings.compact = true
        tip:Clear()
        callbacks[1](tip, { id = 2770 })
        equal(tip.lines[2].text, "|cffffd200" .. labels[1] .. "|r " .. labels[2])
        equal(#tip.lines, 2)

        for _, key in ipairs({ "enableTooltip", "iconsTooltip", "compactTooltip", "debugTooltip" }) do
            local tooltip = addon.strings[key]
            assert(type(tooltip) == "string" and tooltip ~= "", locale .. " is missing " .. key)
        end
        api.SlashCmdList.PROFESSIONREAGENTS("debug")
    end
end)

test("uses the client collation for localized sorting", function()
    local mockKeys = { ["工程學"] = "a", ["急救"] = "b", ["裁縫"] = "c" }
    local addon = boot("zhTW", {
        Enum = { TooltipDataType = { Item = 0 }, CollationStrength = { Secondary = 1 } },
        C_Intl = {
            GetSortKey = function(professionName, strength)
                equal(strength, 1)
                return mockKeys[professionName] or "z" .. professionName
            end,
        },
    })
    equal(addon.lookup[2592].compactPlain, "|cffffd200用於：|r 工程學、急救、裁縫")
end)

test("missing icon renders the profession name", function()
    local addon = boot("enUS")
    local professions = addon.data.professions
    professions[186].icon = 0
    local lookup = addon.PrepareLookup(addon.data, "enUS", addon.strings)
    equal(lookup[2770].icons[1], lookup[2770].plain[1])
end)

test("structured ItemID takes priority and draws gold and white lines", function()
    local _, callbacks = boot("enUS")
    local tip = makeTooltip({ OnTooltipCleared = true })
    callbacks[1](tip, { id = 2770, hyperlink = "item:2589:0" })
    equal(tip.lines[1].text, " ")
    equal(tip.lines[2].text, "Used in:")
    equal(tip.lines[2].g, 0.82)
    equal(tip.lines[3].text, "|T136248:14:14:0:0|t Mining")
    equal(tip.lines[3].g, 1)
end)

test("native options and slash commands share persistent toggles", function()
    local category = {}
    local controls, checkboxes = {}, {}
    local registered = 0
    local addon, callbacks, api = boot("esES", {
        Settings = {
            VarType = { Boolean = "boolean" },
            RegisterVerticalLayoutCategory = function(title)
                equal(title, "Profession Reagents")
                return category
            end,
            RegisterAddOnSetting = function(parent, variable, key, saved, kind, title, default)
                equal(parent, category)
                equal(variable, "ProfessionReagents_" .. key)
                equal(kind, "boolean")
                local setting = { default = default, title = title }
                function setting:SetValue(value, immediate)
                    self.immediate = immediate
                    saved[key] = value
                end
                controls[key] = setting
                return setting
            end,
            CreateCheckbox = function(parent, setting, tooltip)
                equal(parent, category)
                setting.tooltip = tooltip
                checkboxes[#checkboxes + 1] = setting
            end,
            RegisterAddOnCategory = function(parent)
                equal(parent, category)
                registered = registered + 1
            end,
        },
    })
    addon.Initialize()
    equal(registered, 1)
    equal(#checkboxes, 4)
    equal(controls.enabled.title, "Visible")
    equal(controls.icons.title, "Iconos")
    equal(controls.enabled.tooltip, addon.strings.enableTooltip)
    equal(controls.icons.tooltip, addon.strings.iconsTooltip)
    equal(controls.compact.tooltip, addon.strings.compactTooltip)
    equal(controls.debug.tooltip, addon.strings.debugTooltip)
    equal(controls.debug.default, false)

    local tip = makeTooltip({ OnTooltipCleared = true })
    controls.enabled:SetValue(false)
    callbacks[1](tip, { id = 2770 })
    equal(#tip.lines, 0)
    equal(api.ProfessionReagentsDB.enabled, false)

    local command = api.SlashCmdList.PROFESSIONREAGENTS
    command("on")
    equal(controls.enabled.immediate, true)
    controls.compact:SetValue(true)
    command("icons")
    callbacks[1](tip, { id = 2770 })
    equal(tip.lines[2].text, "|cffffd200Utilizado en:|r Minería")

    command("reset")
    equal(api.ProfessionReagentsDB.enabled, true)
    equal(api.ProfessionReagentsDB.icons, true)
    equal(api.ProfessionReagentsDB.compact, false)
    equal(api.ProfessionReagentsDB.debug, false)
    equal(controls.compact.immediate, true)
end)

test("nothing added for a non-reagent, an invalid or an absent ItemID", function()
    local _, callbacks = boot("enUS")
    local tip = makeTooltip({ OnTooltipCleared = true })
    for _, id in ipairs({ 999999999, 25, false, {}, "2589", 0 }) do
        callbacks[1](tip, { id = id })
    end
    callbacks[1](tip, {})
    callbacks[1](tip, nil)
    callbacks[1](nil, { id = 2589 })
    callbacks[1](tip, { hyperlink = "|Hspell:2589|h[Spell]|h" })
    equal(#tip.lines, 0)
    equal(tip.counts.OnTooltipCleared, nil)
end)

test("a pending tooltip can render after the next native update", function()
    local _, callbacks = boot()
    local tip = makeTooltip({ OnTooltipCleared = true })
    callbacks[1](tip, {})
    equal(#tip.lines, 0)
    tip:Clear()
    callbacks[1](tip, { hyperlink = "|cffffffff|Hitem:2770|h[Copper Ore]|h|r" })
    equal(#tip.lines, 3)
end)

test("refresh and clear add once per tooltip lifecycle", function()
    local _, callbacks = boot()
    local tip = makeTooltip({ OnTooltipCleared = true })
    callbacks[1](tip, { id = 2770 })
    callbacks[1](tip, { id = 2770 })
    equal(#tip.lines, 3)
    tip:Clear()
    callbacks[1](tip, { id = 2770 })
    equal(#tip.lines, 3)
    equal(tip.counts.OnTooltipCleared, 1)
end)

test("appended item blocks use the primary data's identity", function()
    local _, callbacks = boot()
    local tip = makeTooltip({ OnTooltipCleared = true })
    local primary = { id = 2770 }
    function tip.GetPrimaryTooltipData()
        return primary
    end
    callbacks[1](tip, { id = 2589 })
    equal(#tip.lines, 0)
    callbacks[1](tip, primary)
    equal(#tip.lines, 3)
end)

test("secrets, forbidden frames and missing methods are skipped", function()
    local secret = {}
    local blocked = setmetatable({}, {
        __index = function()
            error("tried to index an inaccessible table")
        end,
    })
    local _, callbacks = boot("enUS", {
        issecretvalue = function(value)
            return value == secret
        end,
        canaccesstable = function(value)
            return value ~= blocked
        end,
    })
    local tip = makeTooltip({ OnTooltipCleared = true })
    callbacks[1](tip, secret)
    callbacks[1](tip, blocked)
    callbacks[1](tip, { id = secret, hyperlink = "item:2589" })
    callbacks[1](tip, { hyperlink = secret })
    tip.IsForbidden = function()
        return true
    end
    callbacks[1](tip, { id = 2589 })
    callbacks[1]({}, { id = 2589 })
    callbacks[1](makeTooltip({}), { id = 2589 })
    equal(#tip.lines, 0)
end)

test("compact mode, icon preference and long lists", function()
    local addon, callbacks, api = boot("enUS", { ProfessionReagentsDB = { compact = true } })
    local tip = makeTooltip({ OnTooltipCleared = true })
    callbacks[1](tip, { id = 2770 })
    equal(#tip.lines, 2)
    equal(tip.lines[2].text, "|cffffd200Used in:|r |T136248:14:14:0:0|t Mining")
    equal(tip.lines[2].wrap, true)
    api.SlashCmdList.PROFESSIONREAGENTS("icons")
    tip:Clear()
    callbacks[1](tip, { id = 2770 })
    equal(tip.lines[2].text, "|cffffd200Used in:|r Mining")
    addon.settings.icons = true
    for id, content in pairs(addon.lookup) do
        if not content.compactIcons then
            tip:Clear()
            callbacks[1](tip, { id = id })
            equal(#tip.lines, #content.icons + 2)
            return
        end
    end
    error("no long entry in the shipped data")
end)

test("slash commands, status, reset and SavedVariables", function()
    local addon, callbacks, api, messages = boot("esES", {
        ProfessionReagentsDB = { enabled = false, icons = "invalid", compact = true },
    })
    local tip = makeTooltip({ OnTooltipCleared = true })
    local command = api.SlashCmdList.PROFESSIONREAGENTS
    equal(api.SLASH_PROFESSIONREAGENTS1, "/pr")
    equal(addon.settings.enabled, false)
    equal(addon.settings.icons, true)
    callbacks[1](tip, { id = 2770 })
    equal(#tip.lines, 0)
    command(" ON ")
    callbacks[1](tip, { id = 2770 })
    equal(#tip.lines, 2)
    command("off")
    equal(api.ProfessionReagentsDB.enabled, false)
    command("debug")
    local status = table.concat(messages, "\n")
    for _, value in ipairs({ "1.0.0", "16001", "1.60.1.70938", "LibProfessionDB", addon.hookMethod }) do
        assert(status:find(value, 1, true), "missing status field " .. value)
    end
    command("reset")
    equal(api.ProfessionReagentsDB.compact, false)
    equal(api.ProfessionReagentsDB.enabled, true)
    equal(api.ProfessionReagentsDB.debug, false)
    command("")
    assert(messages[#messages]:find("/pr reset", 1, true))
end)

test("ADDON_LOADED initializes once for this addon", function()
    local frame = {}
    function frame:RegisterEvent(event)
        self.event = event
    end
    function frame:UnregisterEvent(event)
        equal(event, self.event)
        self.event = nil
    end
    function frame:SetScript(script, callback)
        equal(script, "OnEvent")
        self.handler = callback
    end
    local addon, callbacks = boot("enUS", {
        CreateFrame = function()
            return frame
        end,
    })
    frame:handler("ADDON_LOADED", "OtherAddon")
    equal(#callbacks, 0)
    frame:handler("ADDON_LOADED", name)
    equal(frame.event, nil)
    equal(frame.handler, nil)
    local lookup = addon.lookup
    addon.Initialize()
    addon.RegisterTooltip()
    equal(addon.lookup, lookup)
    equal(#callbacks, 1)
end)

test("feature-detected legacy path and missing optional APIs", function()
    local tip = makeTooltip({ OnTooltipCleared = true, OnTooltipSetItem = true })
    tip.link = "item:2770:0"
    local addon = boot(nil, { TooltipDataProcessor = false, GameTooltip = tip })
    equal(addon.hookMethod, "OnTooltipSetItem")
    tip.scripts.OnTooltipSetItem(tip)
    equal(tip.lines[3].text, "|T136248:14:14:0:0|t Mining")
    equal(tip.counts.OnTooltipSetItem, 1)
    local unsupported = boot(nil, { Enum = false, SlashCmdList = false, GameTooltip = makeTooltip({}) })
    equal(unsupported.hookMethod, nil)
    equal(unsupported.strings.heading, "Used in:")
end)

print(("%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
