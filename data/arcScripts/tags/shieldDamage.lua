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
    local shieldDamage = {}
    shieldDamage.doShieldDamage = true

    if not node:first_attribute("damage") then error("shieldDamage tag requires a damage!") end
    shieldDamage.count = tonumber(node:first_attribute("damage"):value())

    if node:first_attribute("superDamage") then 
    	shieldDamage.countSuper = tonumber(node:first_attribute("superDamage"):value())
    else
    	shieldDamage.countSuper = shieldDamage.count
    end
    return shieldDamage
end

-----------
-- LOGIC --
-----------
local function logic()
    script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(shipManager, projectile, damage, response)
	    local shieldPower = shipManager.shieldSystem.shields.power
	    local shieldDamage = weaponInfo[projectile.extend.name]["shieldDamage"]
	    if shieldDamage.doShieldDamage then
	        if shieldPower.super.first > 0 then
	            if shieldDamage.countSuper > 0 then
	                shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
	                shieldPower.super.first = math.max(0, shieldPower.super.first - shieldDamage.countSuper)
	                --[[if shieldDamage.delete == true then
	                    projectile:Kill()
	                end]]
	            end
	        else
	            shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
	            shieldPower.first = math.max(0, shieldPower.first - shieldDamage.count)
	            --[[if shieldDamage.delete == true then
	                projectile:Kill()
	            end]]
	        end
	    end
	end)
end

tag_add_weapons("shieldDamage", parser, logic)