-------------
-- IMPORTS --
-------------
local weaponInfo = mods.arcdata.weaponInfo
local droneInfo = mods.arcdata.droneInfo
local customTagsAll = mods.arcdata.customTagsAll
local customTagsWeapons = mods.arcdata.customTagsWeapons
local customTagsDrones = mods.arcdata.customTagsDrones
local Children = mods.arcdata.Children
local parse_xml_bool = mods.arcdata.parse_xml_bool
local tag_add_all = mods.arcdata.tag_add_all
local tag_add_weapons = mods.arcdata.tag_add_weapons
local tag_add_drones = mods.arcdata.tag_add_drones

local userdata_table = mods.arcutil.userdata_table
local get_random_point_in_radius = mods.arcutil.get_random_point_in_radius
local get_point_local_offset = mods.arcutil.get_point_local_offset

local vter = mods.arcutil.vter
local get_room_at_location = mods.arcutil.get_room_at_location
local get_ship_crew_point = mods.arcutil.get_ship_crew_point
local get_ship_crew_room = mods.arcutil.get_ship_crew_room

local convertMousePositionToEnemyShipPosition = mods.arcutil.convertMousePositionToEnemyShipPosition

local get_adjacent_rooms = mods.arcutil.get_adjacent_rooms
local get_distance = mods.arcutil.get_distance

local table_copy_deep = mods.arcutil.table_copy_deep

local under_mind_system = mods.arcutil.under_mind_system
local resists_mind_control = mods.arcutil.resists_mind_control
local can_be_mind_controlled = mods.arcutil.can_be_mind_controlled

local is_first_shot = mods.arcutil.is_first_shot



------------
-- PARSER --
------------
local function parser(node)
    local ammo = {}
    ammo.doAmmo = true
    if not node:first_attribute("amount") then error("ammo tag requires a amount!") end
    ammo.amount = tonumber(node:first_attribute("amount"):value())

    return ammo
end

-----------
-- LOGIC --
-----------
local function logic()
    script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
        local rocketData = weaponInfo[projectile.extend.name]["ammo"]
        if rocketData.doAmmo then
            --print(weaponName)
            local rocketTable = userdata_table(weapon, "mods.gof.rocketPods")
            if rocketTable.rockets then
                rocketTable.rockets = rocketTable.rockets - 1
                --print("AMMO")
                --print(rocketTable.rockets)
                if rocketTable.rockets <= 0 then 
                    --print("NO AMMO")
                    weapon:SetCooldownModifier(-1)
                end
                weapon.boostLevel = rocketTable.rockets
            else
                --print("START AMMO")
                rocketTable.rockets = rocketData - 1
                weapon.boostLevel = rocketTable.rockets
            end
        end
    end)

    script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
        for weapon in vter(shipManager:GetWeaponList()) do
            local rocketData = weaponInfo[weapon.blueprint.name]["ammo"]
            if rocketData.doAmmo then
                weapon:SetCooldownModifier(1)
                userdata_table(weapon, "mods.gof.rocketPods").rockets = rocketData
                weapon.boostLevel = rocketData
            end
        end
    end)

    script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
        for weapon in vter(shipManager:GetWeaponList()) do
            local rocketData = weaponInfo[weapon.blueprint.name]["ammo"]
            if rocketData.doAmmo then
                local rocketTable = userdata_table(weapon, "mods.gof.rocketPods")
                if rocketTable.rockets then
                    weapon.boostLevel = rocketTable.rockets
                    if rocketTable.rockets <= 0 then
                        weapon.cooldown.first = 0
                    end
                end
            end
        end
    end)
end

tag_add_weapons("ammo", parser, logic)