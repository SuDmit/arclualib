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
    local beamReplacement = {}
    beamReplacement.doReplaceBeam = true
    if not node:first_attribute("beam") then error("beamReplacement tag requires a beam!") end
    beamReplacement.beam = node:first_attribute("beam"):value()

    return beamReplacement
end

-----------
-- LOGIC --
-----------
local function logic()
    script.on_internal_event(Defines.InternalEvents.PROJECTILE_INITIALIZE, function(projectile, weaponBlueprint)
	    local beamReplacement = weaponInfo[projectile.extend.name]["beamReplacement"]
	    if beamReplacement.doReplaceBeam then
	    	local beamReplace = Hyperspace.Blueprints:GetWeaponBlueprint(beamReplacement.beam)
	        local spaceManager = Hyperspace.Global.GetInstance():GetCApp().world.space
	        local beam = spaceManager:CreateBeam(
	            beamReplace, 
	            projectile.position, 
	            projectile.currentSpace, 
	            projectile.ownerId,
	            projectile.target, 
	            Hyperspace.Pointf(projectile.target.x, projectile.target.y + 1),
	            projectile.destinationSpace, 
	            1, 
	            projectile.heading)
	        beam.sub_start.x = 500*math.cos(projectile.entryAngle)
	        beam.sub_start.y = 500*math.sin(projectile.entryAngle) 
	        projectile:Kill()
	    end
	end)
end

tag_add_weapons("beamReplacement", parser, logic)