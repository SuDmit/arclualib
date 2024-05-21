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
    local scatter = {}
    scatter.doScatter = true

    if not node:first_attribute("name") then error("scatter tag requires a name!") end
    scatter.name = node:first_attribute("name"):value()

    return scatter
end

-----------
-- LOGIC --
-----------
local function logic()
    script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
        local scatter = weaponInfo[projectile.extend.name]["scatter"]
        if scatter.doScatter then
            local rooms = {}
            local tblSize = 0
            for roomId, roomPos in pairs(get_adjacent_rooms(shipManager.iShipId, get_room_at_location(shipManager, location, false), false)) do
                table.insert(rooms, roomPos)
                tblSize = tblSize + 1
            end

            if tblSize > 0 then
                
                local randomNumber = math.random(1, tblSize)
                local randomRoom = rooms[randomNumber]

                local spaceManager = Hyperspace.Global.GetInstance():GetCApp().world.space
                local projectile = spaceManager:CreateLaserBlast(
                    Hyperspace.Blueprints:GetWeaponBlueprint(scatter.name),
                    projectile.position,
                    projectile.currentSpace,
                    projectile.ownerId,
                    randomRoom,
                    projectile.destinationSpace,
                    projectile.heading)
                projectile:ComputeHeading()
            end
        end
    end)
end

tag_add_weapons("scatter", parser, logic)