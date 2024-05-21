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
    local chainShot = {}
    chainShot.doChainShot = true

    if not node:first_attribute("maxShots") then error("chainShot tag requires a maxShots!") end
    chainShot.maxShots = tonumber(node:first_attribute("maxShots"):value())

    if node:first_attribute("sound") then
        chainShot.sound = node:first_attribute("sound"):value()
    end

    return chainShot
end

-----------
-- LOGIC --
-----------
local function logic()
    script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
        local chainShots = weaponInfo[projectile.extend.name]["chainShot"]
        if chainShots.doChainShot and weapon.boostLevel > 0 then
            --local pos = projectile.position
            userdata_table(weapon, "mods.gof.chainShots").chain = {0.4,weapon.boostLevel,projectile.position.x,projectile.position.y,projectile.currentSpace,projectile.target,projectile.destinationSpace,projectile.heading}      
            --print(pos.x)
        end
        if chainShots.doChainShot then
            if weapon.boostLevel < chainShots.maxShots then
                --print("AAAAA")
                weapon.boostLevel = weapon.boostLevel + 1
            end
        end
    end)


    script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
        for weapon in vter(shipManager:GetWeaponList()) do
            local chainTable = userdata_table(weapon, "mods.gof.chainShots")
            if chainTable.chain then
                chainTable.chain[1] = math.max(chainTable.chain[1] - Hyperspace.FPS.SpeedFactor/16, 0)
                if chainTable.chain[1] == 0 then
                    --print("FIRERERE")local chainShots = weaponInfo[projectile.extend.name]["chainShot"]
                    local soundName = "gofpulsefire1"
                    pcall(function() soundName = weaponInfo[projectile.extend.name]["chainShot"].sound end)
                    if not soundName then
                        soundName = "gofpulsefire1"
                    end
                    Hyperspace.Sounds:PlaySoundMix(soundName, -1, false)

                    local spaceManager = Hyperspace.Global.GetInstance():GetCApp().world.space
                    local laser = spaceManager:CreateLaserBlast(
                        weapon.blueprint,
                        Hyperspace.Pointf(chainTable.chain[3],chainTable.chain[4]),
                        chainTable.chain[5],
                        shipManager.iShipId,
                        chainTable.chain[6],
                        chainTable.chain[7],
                        chainTable.chain[8])
                    --weapon:Fire()
                    --weapon.boostLevel = chainTable.chain[3]
                    if chainTable.chain[2] <= 1 then
                        chainTable.chain = nil
                    else
                        chainTable.chain[1] = 0.4
                        chainTable.chain[2] = chainTable.chain[2] -1
                    end
                end
            end
        end
    end)
end

tag_add_weapons("chainShot", parser, logic)