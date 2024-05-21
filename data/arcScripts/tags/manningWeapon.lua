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
    local manningWeapon = {}
    manningWeapon.doManWeapon = true
    manningWeapon.damage = Hyperspace.Damage()

    local stringtoboolean={ ["true"]=true, ["false"]=false }

    if node:first_attribute("damage") then 
        manningWeapon.damage.iDamage = tonumber(node:first_attribute("damage"):value())
    end

    if node:first_attribute("sp") then 
        manningWeapon.damage.iShieldPiercing = tonumber(node:first_attribute("sp"):value())
    end

    if node:first_attribute("fireChance") then 
        manningWeapon.damage.fireChance = tonumber(node:first_attribute("fireChance"):value())
    end

    if node:first_attribute("breachChance") then 
        manningWeapon.damage.breachChance = tonumber(node:first_attribute("breachChance"):value())
    end

    if node:first_attribute("stunChance") then 
        manningWeapon.damage.stunChance = tonumber(node:first_attribute("stunChance"):value())
    end

    if node:first_attribute("ion") then 
        manningWeapon.damage.iIonDamage = tonumber(node:first_attribute("ion"):value())
    end

    if node:first_attribute("sysDamage") then 
        manningWeapon.damage.iSystemDamage = tonumber(node:first_attribute("sysDamage"):value())
    end

    if node:first_attribute("persDamage") then 
        manningWeapon.damage.iPersDamage = tonumber(node:first_attribute("persDamage"):value())
    end

    if node:first_attribute("hullBust") then 
        manningWeapon.damage.bHullBust = stringtoboolean[node:first_attribute("hullBust"):value()]
    end

    if node:first_attribute("lockdown") then 
        manningWeapon.damage.bLockdown = stringtoboolean[node:first_attribute("lockdown"):value()]
    end

    return manningWeapon
end

-----------
-- LOGIC --
-----------
local function logic()
    script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
        local manningWeapon = weaponInfo[projectile.extend.name]["manningWeapon"]
        if manningWeapon.doManWeapon and projectile.ownerId == 0 then
            local shipManager = Hyperspace.ships.player
            --print(shipManager.weaponSystem.iActiveManned)
            if shipManager.weaponSystem.iActiveManned <= 0 then
                local roomPos = shipManager:GetRoomCenter(shipManager.weaponSystem.roomId)
                shipManager:DamageArea(roomPos, manningWeapon.damage, true)
            end
        end
    end)
end

tag_add_weapons("manningWeapon", parser, logic)