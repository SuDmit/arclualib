mods.arcdata = {}

mods.arcdata.weaponInfo = {}
mods.arcdata.droneInfo = {}

mods.arcdata.customTagsAll = {}
mods.arcdata.customTagsWeapons = {}
mods.arcdata.customTagsDrones = {}

-- XML node iterator
do
    local function nodeIter(Parent, Child)
        if Child == "Start" then return Parent:first_node() end
        return Child:next_sibling()
    end

    mods.arcdata.Children = function(Parent)
        if not Parent then error("Invalid node to Children iterator!", 2) end
        return nodeIter, Parent, "Start"
    end
end

-- Same boolean parsing as used by hyperspace
function mods.arcdata.parse_xml_bool(s)
    return s == "true" or s == "True" or s == "TRUE"
end

-- Use these functions to add new tags
function mods.arcdata.tag_add_all(name, parserArg, logicArg)
    mods.arcdata.customTagsAll[name] = {
        parser = parserArg,
        logic = logicArg,
        hooked = false
    }
end
function mods.arcdata.tag_add_weapons(name, parserArg, logicArg)
    mods.arcdata.customTagsWeapons[name] = {
        parser = parserArg,
        logic = logicArg,
        hooked = false
    }
end
function mods.arcdata.tag_add_drones(name, parserArg, logicArg)
    mods.arcdata.customTagsDrones[name] = {
        parser = parserArg,
        logic = logicArg,
        hooked = false
    }
end