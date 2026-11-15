local _, addon = ...

local displayed = setmetatable({}, { __mode = "k" })
local secret = type(issecretvalue) == "function" and issecretvalue
local accessibleTable = type(canaccesstable) == "function" and canaccesstable

local function isSecret(value)
    return secret and secret(value)
end

local function isReadableTable(value)
    return not isSecret(value) and type(value) == "table" and (not accessibleTable or accessibleTable(value))
end

local function itemIDFromLink(link)
    if isSecret(link) or type(link) ~= "string" then
        return
    end
    local id = link:match("^item:(%d+):")
        or link:match("^item:(%d+)$")
        or link:match("^|c%x%x%x%x%x%x%x%x|Hitem:(%d+)[:|]")
        or link:match("^|Hitem:(%d+)[:|]")
    local itemID = tonumber(id)
    if addon.IsID(itemID) then
        return itemID
    end
end

local function itemIDFromTooltip(tooltip)
    if type(tooltip.GetItem) == "function" then
        -- The Blizzard shim may inspect a GUID before it returns the link.
        local ok, _, link = pcall(tooltip.GetItem, tooltip)
        if ok then
            return itemIDFromLink(link)
        end
    end
end

local function hasScript(tooltip, script)
    return type(tooltip.HasScript) == "function"
        and type(tooltip.HookScript) == "function"
        and tooltip:HasScript(script)
end

local function canRender(tooltip)
    return addon.settings.enabled
        and isReadableTable(tooltip)
        and (type(tooltip.IsForbidden) ~= "function" or not tooltip:IsForbidden())
        and type(tooltip.AddLine) == "function"
        and not displayed[tooltip]
end

local function onCleared(tooltip)
    displayed[tooltip] = false
end

local function render(tooltip, itemID)
    local content = addon.lookup[itemID]
    if not content then
        return
    end
    if displayed[tooltip] == nil then
        if not hasScript(tooltip, "OnTooltipCleared") then
            return
        end
        tooltip:HookScript("OnTooltipCleared", onCleared)
    end
    displayed[tooltip] = true

    local settings = addon.settings
    local gold = NORMAL_FONT_COLOR
    tooltip:AddLine(" ")
    if settings.compact then
        local line
        if settings.icons then
            line = content.compactIcons
        else
            line = content.compactPlain
        end
        if line then
            tooltip:AddLine(line, 1, 1, 1, true)
            return
        end
    end

    tooltip:AddLine(addon.strings.heading, gold and gold.r or 1, gold and gold.g or 0.82, gold and gold.b or 0)
    for _, line in ipairs(settings.icons and content.icons or content.plain) do
        tooltip:AddLine(line, 1, 1, 1)
    end
end

local function onItemData(tooltip, data)
    if not canRender(tooltip) or not isReadableTable(data) then
        return
    end

    -- Appended item blocks must not describe a different item from the primary tooltip.
    if type(tooltip.GetPrimaryTooltipData) == "function" then
        local primary = tooltip:GetPrimaryTooltipData()
        if isSecret(primary) or (primary ~= nil and primary ~= data) then
            return
        end
    end

    local itemID = data.id
    if isSecret(itemID) then
        return
    end
    if not addon.IsID(itemID) then
        itemID = itemIDFromLink(data.hyperlink) or itemIDFromTooltip(tooltip)
    end
    render(tooltip, itemID)
end

local function onLegacyItem(tooltip)
    if canRender(tooltip) then
        render(tooltip, itemIDFromTooltip(tooltip))
    end
end

local hookMethod
function addon.RegisterTooltip()
    if hookMethod then
        return hookMethod
    end
    local itemType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
    if
        type(itemType) == "number"
        and TooltipDataProcessor
        and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    then
        TooltipDataProcessor.AddTooltipPostCall(itemType, onItemData)
        hookMethod = "TooltipDataProcessor.AddTooltipPostCall"
        return hookMethod
    end

    local seen = {}
    local frames = {
        GameTooltip = GameTooltip,
        ItemRefTooltip = ItemRefTooltip,
        ShoppingTooltip1 = ShoppingTooltip1,
        ShoppingTooltip2 = ShoppingTooltip2,
        ItemRefShoppingTooltip1 = ItemRefShoppingTooltip1,
        ItemRefShoppingTooltip2 = ItemRefShoppingTooltip2,
    }
    for _, tooltip in pairs(frames) do
        if
            not seen[tooltip]
            and type(tooltip.GetItem) == "function"
            and hasScript(tooltip, "OnTooltipSetItem")
            and hasScript(tooltip, "OnTooltipCleared")
        then
            tooltip:HookScript("OnTooltipSetItem", onLegacyItem)
            seen[tooltip] = true
            hookMethod = "OnTooltipSetItem"
        end
    end
    return hookMethod
end
