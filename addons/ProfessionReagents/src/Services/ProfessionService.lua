local _, addon = ...

local accents = {
    ["Á"] = "a",
    ["á"] = "a",
    ["É"] = "e",
    ["é"] = "e",
    ["Í"] = "i",
    ["í"] = "i",
    ["Ó"] = "o",
    ["ó"] = "o",
    ["Ú"] = "u",
    ["ú"] = "u",
    ["Ü"] = "u",
    ["ü"] = "u",
    ["Ñ"] = "n{",
    ["ñ"] = "n{",
}

local function sortKey(name)
    local strength = Enum and Enum.CollationStrength and Enum.CollationStrength.Secondary
    if strength and C_Intl and type(C_Intl.GetSortKey) == "function" then
        local key = C_Intl.GetSortKey(name, strength)
        if key then
            return key
        end
    end
    return name:lower():gsub("[\194-\244][\128-\191]+", accents)
end

local function prepareGroup(group, professions, strings)
    if type(group) ~= "table" then
        return
    end

    local ordered, seen = {}, {}
    for _, id in ipairs(group) do
        if not addon.IsID(id) or not professions[id] or seen[id] then
            return
        end
        seen[id] = true
        ordered[#ordered + 1] = professions[id]
    end
    if #ordered == 0 then
        return
    end

    table.sort(ordered, function(a, b)
        if a.key == b.key then
            return a.id < b.id
        end
        return a.key < b.key
    end)

    local plain, icons = {}, {}
    local iconCount = 0
    for i, profession in ipairs(ordered) do
        plain[i] = profession.name
        icons[i] = profession.name
        if profession.icon then
            icons[i] = ("|T%d:14:14:0:0|t %s"):format(profession.icon, profession.name)
            iconCount = iconCount + 1
        end
    end

    local compactPlain, compactIcons
    local separator = strings.listSeparator or ", "
    local joined = table.concat(plain, separator)
    local heading = "|cffffd200" .. strings.heading .. "|r "
    local _, characters = (strings.heading .. " " .. joined):gsub("[^\128-\191]", "")
    if characters <= 62 then
        compactPlain = heading .. joined
    end
    if characters + iconCount * 3 <= 62 then
        compactIcons = heading .. table.concat(icons, separator)
    end

    return { plain = plain, icons = icons, compactPlain = compactPlain, compactIcons = compactIcons }
end

function addon.PrepareLookup(data, locale, strings)
    if
        type(data) ~= "table"
        or type(data.source) ~= "table"
        or type(data.stats) ~= "table"
        or type(data.professions) ~= "table"
        or type(data.items) ~= "table"
    then
        return
    end
    local source, stats = data.source, data.stats
    if
        type(source.name) ~= "string"
        or type(source.version) ~= "string"
        or type(source.build) ~= "string"
        or not addon.IsID(stats.recipes)
        or not addon.IsID(stats.indexedRecipes)
        or stats.indexedRecipes > stats.recipes
        or not addon.IsID(stats.professions)
    then
        return
    end

    local professions = {}
    for id, record in pairs(data.professions) do
        if not addon.IsID(id) or type(record) ~= "table" or type(record.enUS) ~= "string" or record.enUS == "" then
            return
        end
        local name = record[locale]
        if type(name) ~= "string" or name == "" then
            name = record.enUS
        end
        professions[id] = { id = id, name = name, key = sortKey(name), icon = addon.IsID(record.icon) and record.icon }
    end

    local lookup, preparedGroups = {}, {}
    local materials = 0
    for itemID, group in pairs(data.items) do
        if not addon.IsID(itemID) or type(group) ~= "table" then
            return
        end
        local prepared = preparedGroups[group]
        if not prepared then
            prepared = prepareGroup(group, professions, strings)
            if not prepared then
                return
            end
            preparedGroups[group] = prepared
        end
        lookup[itemID] = prepared
        materials = materials + 1
    end
    if materials == 0 or materials ~= data.stats.materials then
        return
    end
    return lookup
end
