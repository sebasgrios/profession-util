local _, addon = ...

function addon.IsID(value)
    return type(value) == "number" and value > 0 and value < math.huge and value % 1 == 0
end

-- Used by the generator and the tests. The game loads the generated result directly.
function addon.BuildReagentIndex(recipes)
    local items, usedProfessions = {}, {}
    local stats = { recipes = 0, indexedRecipes = 0, materials = 0, professions = 0, invalid = 0 }

    for professionID, recipeID, reagents in recipes do
        if not addon.IsID(professionID) or not addon.IsID(recipeID) then
            stats.invalid = stats.invalid + 1
        else
            stats.recipes = stats.recipes + 1
            if type(reagents) == "table" then
                local hasReagent = false
                for itemID, quantity in pairs(reagents) do
                    if addon.IsID(itemID) and addon.IsID(quantity) then
                        if not items[itemID] then
                            items[itemID] = {}
                            stats.materials = stats.materials + 1
                        end
                        items[itemID][professionID] = true
                        hasReagent = true
                    else
                        stats.invalid = stats.invalid + 1
                    end
                end
                if hasReagent then
                    stats.indexedRecipes = stats.indexedRecipes + 1
                    usedProfessions[professionID] = true
                end
            elseif reagents ~= nil then
                stats.invalid = stats.invalid + 1
            end
        end
    end

    for _ in pairs(usedProfessions) do
        stats.professions = stats.professions + 1
    end
    return items, stats
end
