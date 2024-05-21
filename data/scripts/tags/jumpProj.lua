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
    local jumpProj = {}
    jumpProj.doJumpProj = true
    
    if not node:first_attribute("delay") then error("jumpProj tag requires a duration!") end
    jumpProj.delay = tonumber(node:first_attribute("delay"):value())

    if not node:first_attribute("distance") then error("jumpProj tag requires a duration!") end
    jumpProj.distance = tonumber(node:first_attribute("distance"):value())

    if node:first_attribute("sound") then
        jumpProj.sound = node:first_attribute("sound"):value()
    end

    return jumpProj
end

-----------
-- LOGIC --
-----------
local function logic()
    script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
        local spaceManager = Hyperspace.Global.GetInstance():GetCApp().world.space
        for projectile in vter(spaceManager.projectiles) do
            local jumpProj = weaponInfo[projectile.extend.name]["jumpProj"]
            if jumpProj.doJumpProj then
                local projectileTable = userdata_table(projectile, "mods.arc.jumpProj")
                local commandGui = Hyperspace.Global.GetInstance():GetCApp().gui
                if projectileTable.delay and (not commandGui.bPaused) then
                    projectileTable.delay = math.max(projectileTable.delay - Hyperspace.FPS.SpeedFactor/16, 0)
                    if projectileTable.delay == 0 then
                        projectileTable.delay = jumpProj.delay
                        if get_distance(projectile.position, projectile.target) <= jumpProj.distance then return end
                        if jumpProj.sound then
                            Hyperspace.Sounds:PlaySoundMix(jumpProj.sound, -1, true)
                        end

                        if projectile.currentSpace == 1 then
                            projectile.position = Hyperspace.Pointf(projectile.position.x + jumpProj.distance, projectile.position.y)
                        else
                            projectile.position = get_point_local_offset(projectile.position, projectile.target, jumpProj.distance, 0)
                        end
                    end
                else
                    projectileTable.delay = jumpProj.delay
                end
            end
        end
    end)
end

tag_add_weapons("jumpProj", parser, logic)