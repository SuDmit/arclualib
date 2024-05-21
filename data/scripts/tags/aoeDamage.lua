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
    local aoeDamage = {}
    aoeDamage.doAoeDamage = true
    aoeDamage.damage = Hyperspace.Damage()

    local stringtoboolean={ ["true"]=true, ["false"]=false }

    if node:first_attribute("damage") then 
    	aoeDamage.damage.iDamage = tonumber(node:first_attribute("damage"):value())
    end

    if node:first_attribute("sp") then 
    	aoeDamage.damage.iShieldPiercing = tonumber(node:first_attribute("sp"):value())
    end

    if node:first_attribute("fireChance") then 
    	aoeDamage.damage.fireChance = tonumber(node:first_attribute("fireChance"):value())
    end

    if node:first_attribute("breachChance") then 
    	aoeDamage.damage.breachChance = tonumber(node:first_attribute("breachChance"):value())
    end

    if node:first_attribute("stunChance") then 
    	aoeDamage.damage.stunChance = tonumber(node:first_attribute("stunChance"):value())
    end

    if node:first_attribute("ion") then 
    	aoeDamage.damage.iIonDamage = tonumber(node:first_attribute("ion"):value())
    end

    if node:first_attribute("sysDamage") then 
    	aoeDamage.damage.iSystemDamage = tonumber(node:first_attribute("sysDamage"):value())
    end

    if node:first_attribute("persDamage") then 
    	aoeDamage.damage.iPersDamage = tonumber(node:first_attribute("persDamage"):value())
    end

    if node:first_attribute("hullBust") then 
    	aoeDamage.damage.bHullBust = stringtoboolean[node:first_attribute("hullBust"):value()]
    end

    if node:first_attribute("lockdown") then 
    	aoeDamage.damage.bLockdown = stringtoboolean[node:first_attribute("lockdown"):value()]
    end

    return aoeDamage
end

-----------
-- LOGIC --
-----------
local function logic()
	script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
	    local aoeDamage = weaponInfo[projectile.extend.name]["aoeDamage"]
	    if aoeDamage.doAoeDamage and aoeDamage.damage then
	    	local weaponName = projectile.extend.name
	        projectile.extend.name = ""
	        for roomId, roomPos in pairs(get_adjacent_rooms(shipManager.iShipId, get_room_at_location(shipManager, location, false), false)) do
	            shipManager:DamageArea(roomPos, aoeDamage.damage, true)
	        end
	        projectile.extend.name = weaponName
	    end
	end)
end

tag_add_weapons("aoeDamage", parser, logic)