local _, addon = ...

local defaults = { enabled = true, icons = true, compact = false, debug = false }
local optionText = {
    enabled = { label = "enableLabel", tooltip = "enableTooltip" },
    icons = { label = "iconsLabel", tooltip = "iconsTooltip" },
    compact = { label = "compactLabel", tooltip = "compactTooltip" },
    debug = { label = "debugLabel", tooltip = "debugTooltip" },
}
local controls = {}

function addon.LoadSettings(saved)
    saved = type(saved) == "table" and saved or {}
    local settings = {}
    for key, default in pairs(defaults) do
        local value = saved[key]
        if type(value) == "boolean" then
            settings[key] = value
        else
            settings[key] = default
        end
    end
    return settings
end

function addon.RegisterOptions()
    if
        not Settings
        or type(Settings.RegisterVerticalLayoutCategory) ~= "function"
        or type(Settings.RegisterAddOnSetting) ~= "function"
        or type(Settings.CreateCheckbox) ~= "function"
        or type(Settings.RegisterAddOnCategory) ~= "function"
        or not (Settings.VarType and Settings.VarType.Boolean)
    then
        return
    end

    local category = Settings.RegisterVerticalLayoutCategory("Profession Reagents")
    local strings = addon.strings
    for _, key in ipairs({ "enabled", "icons", "compact", "debug" }) do
        local text = optionText[key]
        local setting = Settings.RegisterAddOnSetting(
            category,
            "ProfessionReagents_" .. key,
            key,
            addon.settings,
            Settings.VarType.Boolean,
            strings[text.label],
            defaults[key]
        )
        controls[key] = setting
        Settings.CreateCheckbox(category, setting, strings[text.tooltip])
    end
    Settings.RegisterAddOnCategory(category)
end

local function setOption(key, value)
    local setting = controls[key]
    if setting then
        -- Let the native setting notify any checkbox currently on screen.
        setting:SetValue(value, true)
    else
        addon.settings[key] = value
    end
end

function addon.RegisterCommands()
    if type(SlashCmdList) ~= "table" then
        return
    end

    local strings = addon.strings
    local function state(value)
        return value and strings.on or strings.off
    end
    local function printState(label, value)
        addon.Print(label .. " — " .. state(value))
    end

    SLASH_PROFESSIONREAGENTS1 = "/pr"
    SlashCmdList.PROFESSIONREAGENTS = function(message)
        local command = (message or ""):match("^%s*(.-)%s*$"):lower()
        local settings = addon.settings
        if command == "on" or command == "off" then
            setOption("enabled", command == "on")
            printState(strings.enableLabel, settings.enabled)
        elseif command ~= "enabled" and optionText[command] then
            setOption(command, not settings[command])
            printState(strings[optionText[command].label], settings[command])
            if command == "debug" and settings.debug then
                addon.PrintStatus()
            end
        elseif command == "status" then
            addon.PrintStatus()
        elseif command == "reset" then
            for key, default in pairs(defaults) do
                setOption(key, default)
            end
            addon.Print(strings.reset)
        else
            for _, line in ipairs(strings.help) do
                addon.Print(line)
            end
        end
    end
end
