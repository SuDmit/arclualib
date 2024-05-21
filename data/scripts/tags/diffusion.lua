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
    local diffusion = {}
    diffusion.doDiffuse = true

    if not node:first_attribute("number") then error("diffusion tag requires a number!") end
    diffusion.number = tonumber(node:first_attribute("number"):value())

    if node:first_attribute("image") then
        diffusion.image = node:first_attribute("image"):value()
    end

    return diffusion
end

-----------
-- LOGIC --
-----------
local function logic()
    script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(shipManager, projectile, damage, response) 
        local diffusion = weaponInfo[projectile.extend.name]["diffusion"]
        if diffusion.doDiffuse and shipManager.shieldSystem.shields.power.super.first <= 0 then
            local damage = projectile.damage
            local spaceManager = Hyperspace.Global.GetInstance():GetCApp().world.space
            local weaponBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(projectile.extend.name)
            local weaponType = weaponBlueprint.typeName
            local projCount = diffusion.number
            while projCount > 0 do
                if weaponType == "BURST" then
                    local proj = spaceManager:CreateBurstProjectile(
                        weaponBlueprint,
                        diffusion.image,
                        false,
                        projectile.position,
                        projectile.currentSpace,
                        projectile.ownerId,
                        get_random_point_in_radius(projectile.target, 10),
                        projectile.destinationSpace,
                        projectile.heading)
                elseif weaponType == "LASER" then 
                    local proj = spaceManager:CreateLaserBlast(
                        weaponBlueprint,
                        projectile.position,
                        projectile.currentSpace,
                        projectile.ownerId,
                        get_random_point_in_radius(projectile.target, 10),
                        projectile.destinationSpace,
                        projectile.heading)
                elseif weaponType == "MISSILES" then 
                    local proj = spaceManager:CreateMissile(
                        weaponBlueprint,
                        projectile.position,
                        projectile.currentSpace,
                        projectile.ownerId,
                        get_random_point_in_radius(projectile.target, 10),
                        projectile.destinationSpace,
                        projectile.heading)
                elseif weaponType == "BOMB" then 
                    local proj = spaceManager:CreateBomb(
                        weaponBlueprint,
                        projectile.ownerId,
                        get_random_point_in_radius(projectile.target, 10),
                        projectile.destinationSpace)
                elseif weaponType == "BEAM" then 
                    local proj = spaceManager:CreateBeam(
                        weaponBlueprint,
                        projectile.position,
                        projectile.currentSpace,
                        projectile.ownerId,
                        get_random_point_in_radius(projectile.target1, 10),
                        get_random_point_in_radius(projectile.target2, 10),
                        projectile.destinationSpace,
                        projectile.length,
                        projectile.heading)
                end

                proj:SetDamage(damage)
                projCount = projCount - 1
            end
        end
    end)
end

tag_add_weapons("diffusion", parser, logic)