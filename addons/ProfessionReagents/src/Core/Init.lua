local addonName, addon = ...

local initialized = false

function addon.Print(message)
    print("|cffffd200Profession Reagents|r " .. message)
end

function addon.PrintStatus()
    local strings = addon.strings
    local settings = addon.settings
    local unknown = strings.unknown
    local client, build, _, interface
    if type(GetBuildInfo) == "function" then
        client, build, _, interface = GetBuildInfo()
    end
    local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version")

    addon.Print(strings.statusAddon:format(version or unknown, settings.enabled and strings.on or strings.off))
    addon.Print(strings.statusClient:format(client or unknown, build or unknown, interface or unknown))
    if addon.lookup then
        local source = addon.data.source
        local stats = addon.data.stats
        addon.Print(strings.statusData:format(source.version, source.name, source.build))
        addon.Print(
            strings.statusCounts:format(stats.indexedRecipes, stats.recipes, stats.materials, stats.professions)
        )
    else
        addon.Print(strings.dataUnavailable)
    end
    addon.Print(strings.statusHook:format(addon.hookMethod or strings.hookUnavailable))
    if settings.debug then
        addon.Print(
            strings.debugSettings:format(
                settings.icons and strings.on or strings.off,
                settings.compact and strings.on or strings.off
            )
        )
    end
end

function addon.Initialize()
    if initialized then
        return
    end
    initialized = true

    local locale = type(GetLocale) == "function" and GetLocale()
    if not addon.locales[locale] then
        locale = "enUS"
    end
    addon.strings = addon.locales[locale]
    addon.settings = addon.LoadSettings(ProfessionReagentsDB)
    ProfessionReagentsDB = addon.settings
    addon.lookup = addon.PrepareLookup(addon.data, locale, addon.strings)
    if addon.lookup then
        addon.hookMethod = addon.RegisterTooltip()
    end
    addon.RegisterOptions()
    addon.RegisterCommands()

    if addon.settings.debug then
        addon.PrintStatus()
    end
end

if type(CreateFrame) == "function" then
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(self, _, name)
        if name == addonName then
            self:UnregisterEvent("ADDON_LOADED")
            self:SetScript("OnEvent", nil)
            addon.Initialize()
        end
    end)
end
