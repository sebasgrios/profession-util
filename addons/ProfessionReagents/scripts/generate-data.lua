local work, addonPath, version, release, clientVersion, build, interface, expected = unpack(arg, 1, 8)
local name = "ProfessionReagents"
local addon = {}
assert(work and addonPath and expected and arg[9], "Run scripts/update-data.ps1 to supply the pinned data inputs")
assert(loadfile(addonPath .. "/Database/ReagentIndex.lua"))(name, addon)
local professions = dofile(work .. "/professions.lua")

function GetBuildInfo()
    return clientVersion, build:match("%d+$"), "", tonumber(interface)
end

dofile(work .. "/LibStub.lua")
dofile(work .. "/LibProfessionDB-1.0.lua")
local db = LibStub("LibProfessionDB-1.0")
assert(db:GetGameVersion() == "Forever", "LibProfessionDB did not select Forever")
for i = 9, #arg do
    dofile(work .. "/" .. arg[i])
end
assert(db:IsReady() and db:Count() == tonumber(expected), "Unexpected number of recipes in Forever")

local function recipes()
    local nextRecipe = db:Iterate()
    return function()
        local professionID, recipeID = nextRecipe()
        if professionID then
            assert(professions[professionID], "Missing profession metadata")
            return professionID, recipeID, db:GetReagents(professionID, recipeID)
        end
    end
end

local function sortedKeys(map)
    local keys = {}
    for key in pairs(map) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

local items, stats = addon.BuildReagentIndex(recipes())
assert(stats.recipes == db:Count() and stats.invalid == 0 and stats.materials > 0, "Invalid Forever recipe data")
for _, professionID in ipairs(sortedKeys(professions)) do
    assert(db:HasProfession(professionID), "Profession absent from Forever recipes: " .. professionID)
end

-- Intern the profession arrays so items with the same set share one table.
local groups, indices, itemGroups = {}, {}, {}
local itemIDs = sortedKeys(items)
for _, itemID in ipairs(itemIDs) do
    local key = table.concat(sortedKeys(items[itemID]), ", ")
    if not indices[key] then
        groups[#groups + 1] = key
        indices[key] = #groups
    end
    itemGroups[itemID] = indices[key]
end

local output = assert(io.open(work .. "/Forever.lua", "wb"))
output:write("-- Generated from LibProfessionDB's Data/Forever/_core and the Forever SkillLine table.\n")
output:write("-- See docs/DATA.md. Regenerate with scripts/update-data.ps1.\n")
output:write("local _, addon = ...\n\nlocal groups = {\n")
for _, key in ipairs(groups) do
    output:write(("    { %s },\n"):format(key))
end
output:write('}\n\naddon.data = {\n    source = {\n        name = "LibProfessionDB",\n')
output:write(("        version = %q,\n        build = %q,\n        url = %q,\n"):format(version, build, release))
output:write("    },\n    stats = {\n")
for _, key in ipairs({ "recipes", "indexedRecipes", "materials", "professions" }) do
    output:write(("        %s = %d,\n"):format(key, stats[key]))
end
output:write("    },\n    professions = {\n")
for _, id in ipairs(sortedKeys(professions)) do
    local profession = professions[id]
    output:write(("        [%d] = {\n            icon = %d,\n"):format(id, profession.icon))
    for _, key in ipairs(sortedKeys(profession)) do
        if key ~= "icon" then
            output:write(("            %s = %q,\n"):format(key, profession[key]))
        end
    end
    output:write("        },\n")
end
output:write("    },\n    items = {\n")
for _, itemID in ipairs(itemIDs) do
    output:write(("        [%d] = groups[%d],\n"):format(itemID, itemGroups[itemID]))
end
output:write("    },\n}\n")
assert(output:close())
print(
    ("Forever %s: %d/%d recipes with reagents, %d materials, %d/%d professions, %d distinct sets"):format(
        build,
        stats.indexedRecipes,
        stats.recipes,
        stats.materials,
        stats.professions,
        #sortedKeys(professions),
        #groups
    )
)
