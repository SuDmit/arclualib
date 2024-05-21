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
    local overheat = {}
    overheat.doOverheat = true
    if not node:first_attribute("maxShots") then error("overheat tag requires a maxShots!") end
    overheat.maxShots = tonumber(node:first_attribute("maxShots"):value())

    if not node:first_attribute("cooldown") then error("overheat tag requires a cooldown!") end
    overheat.cooldown = tonumber(node:first_attribute("cooldown"):value())

    return overheat
end

-----------
-- LOGIC --
-----------
local function logic()
	script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
	    local overheat = weaponInfo[projectile.extend.name]["overheat"]
	    if overheat.doOverheat then
	        local cooldown = weapon.cooldown
	        local oHTable = userdata_table(weapon, "mods.overheatweapons.shots")
	        if oHTable.oHShots then
	            oHTable.oHShots = math.max(oHTable.oHShots - 1, 0)
	        else
	            userdata_table(weapon, "mods.overheatweapons.shots").oHShots = overheat.maxShots
	        end
	    end
	end)

	script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
	    for weapon in vter(shipManager:GetWeaponList()) do
	        local overheat = weaponInfo[weapon.blueprint.name]["overheat"]
	    	if overheat.doOverheat then
	            local oHTable = userdata_table(weapon, "mods.overheatweapons.shots")
	            if oHTable.disabled then 
	            	weapon.cooldown.first = 0
	            end

	            if oHTable.oHShots then
	            	local commandGui = Hyperspace.Global.GetInstance():GetCApp().gui
                	if not commandGui.bPaused then 
                		if not weapon.powered or oHTable.disabled or (weapon.cooldown.first == weapon.cooldown.second and weapon.fireWhenReady == false) then
                			if oHTable.disabled then
                				oHTable.oHShots = math.min(overheat.maxShots, oHTable.oHShots + ((Hyperspace.FPS.SpeedFactor/16) * (overheat.maxShots/(overheat.cooldown * 2))))
                			else
	                			oHTable.oHShots = math.min(overheat.maxShots, oHTable.oHShots + ((Hyperspace.FPS.SpeedFactor/16) * (overheat.maxShots/overheat.cooldown)))
	                		end
                			if oHTable.oHShots == overheat.maxShots then
                				oHTable.disabled = nil
                			end
                		elseif oHTable.oHShots == 0 then
                			oHTable.disabled = true 
            				weapon.boostLevel = 1
                		end
                	end
	            end
	        end
	    end
	end)

	script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
	    for weapon in vter(shipManager:GetWeaponList()) do
	        local overheat = weaponInfo[projectile.extend.name]["overheat"]
	        if overheat.doOverheat then
	            local oHTable = userdata_table(weapon, "mods.overheatweapons.shots")
	            if oHTable.oHShots then
	                oHTable.oHShots = nil
	            end
	        end
	    end
	end)

	local overheat_image = {}
	overheat_image[0] = Hyperspace.Resources:CreateImagePrimitiveString("statusUI/rad_overheat_0.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
	overheat_image[1] = Hyperspace.Resources:CreateImagePrimitiveString("statusUI/rad_overheat_1.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
	overheat_image[2] = Hyperspace.Resources:CreateImagePrimitiveString("statusUI/rad_overheat_2.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
	overheat_image[3] = Hyperspace.Resources:CreateImagePrimitiveString("statusUI/rad_overheat_3.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
	overheat_image[4] = Hyperspace.Resources:CreateImagePrimitiveString("statusUI/rad_overheat_4.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
	overheat_image[5] = Hyperspace.Resources:CreateImagePrimitiveString("statusUI/rad_overheat_5.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
	overheat_image[6] = Hyperspace.Resources:CreateImagePrimitiveString("statusUI/rad_overheat_6.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
	overheat_image[7] = Hyperspace.Resources:CreateImagePrimitiveString("statusUI/rad_overheat_7.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
	overheat_image[8] = Hyperspace.Resources:CreateImagePrimitiveString("statusUI/rad_overheat_8.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
	overheat_image[9] = Hyperspace.Resources:CreateImagePrimitiveString("statusUI/rad_overheat_9.png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1.0, false)

	script.on_render_event(Defines.RenderEvents.MOUSE_CONTROL, function()
		if Hyperspace.Global.GetInstance():GetCApp().world.bStartedGame then
		    local slot1X = 106
		    local slotY = 623
		    local shipManager = Hyperspace.Global.GetInstance():GetShipManager(0)
		    local weaponlist = {}
		    if shipManager then
		        weaponlist = shipManager:GetWeaponList()
		        for system in vter(shipManager.vSystemList) do
		            if (system.iSystemType == 0 or system.iSystemType == 1 or system.iSystemType == 2 or system.iSystemType == 5 or system.iSystemType == 13 or system.iSystemType == 11) then
		                slot1X = slot1X + 36
		            elseif (system.iSystemType == 9 or system.iSystemType == 10 or system.iSystemType == 14 or system.iSystemType == 20) then
		                slot1X = slot1X + 54
		            elseif system.iSystemType >= 15 then
		            	slot1X = slot1X + 19
		            end
		        end
		    end
		    local slot2X = slot1X+97
		    local slot3X = slot2X+97
		    local slot4X = slot3X+97

		    local weaponCounter = 0
		    for weapon in vter(shipManager:GetWeaponList()) do
		    	local overheat = weaponInfo[weapon.blueprint.name]["overheat"]
		    	if overheat.doOverheat then
		    		local oHTable = userdata_table(weapon, "mods.overheatweapons.shots")
		    		if oHTable.oHShots then
		    			local shots = oHTable.oHShots
		    			local pOverheat = (shots/overheat.maxShots) * 10
		    			local renderString = "statusUI/rad_overheat_"..tostring(math.floor(pOverheat))..".png"
	    				Graphics.CSurface.GL_PushMatrix()
		    			if oHTable.disabled or (not weapon.powered) then
		    				Graphics.CSurface.GL_SetColor(Graphics.GL_Color(0, 1, 1, 1))
		    			end
        				Graphics.CSurface.GL_Translate(slot1X+(97*weaponCounter),slotY,0)
	    				Graphics.CSurface.GL_RenderPrimitive(overheat_image[math.floor(pOverheat)])
	    				Graphics.CSurface.GL_PopMatrix()
		    		end
		    	end
		    end
		end
	end, function() end)

end

tag_add_weapons("overheat", parser, logic)