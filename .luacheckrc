std = "lua51"
max_line_length = 120
exclude_files = { ".cache/**", "dist/**", "addons/ProfessionReagents/src/Database/Forever.lua" }

read_globals = {
    "C_AddOns",
    "C_Intl",
    "CreateFrame",
    "Enum.CollationStrength.Secondary",
    "Enum.TooltipDataType.Item",
    "GameTooltip",
    "GetBuildInfo",
    "GetLocale",
    "ItemRefShoppingTooltip1",
    "ItemRefShoppingTooltip2",
    "ItemRefTooltip",
    "NORMAL_FONT_COLOR",
    "Settings",
    "ShoppingTooltip1",
    "ShoppingTooltip2",
    "SlashCmdList",
    "TooltipDataProcessor",
    "canaccesstable",
    "issecretvalue",
}

files["addons/ProfessionReagents/src/**/*.lua"].globals = {
    "ProfessionReagentsDB", "SLASH_PROFESSIONREAGENTS1", "SlashCmdList.PROFESSIONREAGENTS",
}
files["addons/ProfessionReagents/scripts/generate-data.lua"].globals = { "GetBuildInfo", "LibStub" }
