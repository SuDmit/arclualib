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
    local fractionalDamage = {}
    fractionalDamage.doFractionalDamage = true

    local stringtoboolean={ ["true"]=true, ["false"]=false }

    if node:first_attribute("damage") then
        fractionalDamage.iDamage = tonumber(node:first_attribute("damage"):value())
    end

    if node:first_attribute("sysDamage") then
        fractionalDamage.iSystemDamage = tonumber(node:first_attribute("sysDamage"):value())
    end

    if node:first_attribute("ion") then
        fractionalDamage.iIonDamage = tonumber(node:first_attribute("ion"):value())
    end

    if node:first_attribute("persDamage") then
        fractionalDamage.iPersDamage = tonumber(node:first_attribute("persDamage"):value())
    end

    if node:first_attribute("affectShield") then
        fractionalDamage.affectShield = stringtoboolean[node:first_attribute("affectShield"):value()]
    end

    return fractionalDamage
end

-----------
-- LOGIC --
-----------
local function logic()
	local function damage_shields(shipManager, projectile)
		local shieldPower = nil
		if shipManager:HasSystem(0) then
			shieldPower = shipManager.shieldSystem.shields.power
		else
			shieldPower = shipManager:GetShieldPower()
		end
		if shieldPower.super.first > 0 then
	        if popData.countSuper > 0 then
	            shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
	            shieldPower.super.first = math.max(0, shieldPower.super.first - 1)
	        end
	    elseif shipManager:HasSystem(0) then
	        shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
	        shieldPower.first = math.max(0, shieldPower.first - 1)
	    end
	end

	local function ion_shields(shipManager, projectile)
		local shieldPower = nil
		if shipManager:HasSystem(0) then
			shieldPower = shipManager.shieldSystem.shields.power
		else
			shieldPower = shipManager:GetShieldPower()
		end
		if shieldPower.super.first > 0 then
	        if popData.countSuper > 0 then
	            shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
	            shieldPower.super.first = math.max(0, shieldPower.super.first - 1)
	        end
	    elseif shipManager:HasSystem(0) then
	        shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
	        roomPos = shipManager:GetRoomCenter(shipManager.shieldSystem.iRoomId)
	        local weaponName = projectile.extend.name
	        projectile.extend.name = ""
	        local damage = Hyperspace.Damage()
	        damage.iIonDamage = 1
	        shipManager:DamageArea(roomPos, damage, true)
	    end
	end

	script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(shipManager, projectile, damage, response)
		local fractionalDamage = weaponInfo[projectile.extend.name]["fractionalDamage"]
	    if fractionalDamage.doFractionalDamage then
			if not fractionalDamage.affectShield then return Defines.Chain.Continue end
			local damageTable = userdata_table(shipManager, "mods.arclua.shieldDamage")
			if damageTable.shieldDamage and fractionalDamage.iDamage then
				damageTable.shieldDamage = damageTable.shieldDamage + fractionalDamage.iDamage
				if damageTable.shieldDamage >= 1 then
					damageTable.shieldDamage = damageTable.shieldDamage - 1
					damage_shields(shipManager, projectile)
				end
			elseif fractionalDamage.iDamage then
				damageTable.shieldDamage = fractionalDamage.iDamage
			end
			if damageTable.shieldIon and fractionalDamage.iIonDamage then
				damageTable.shieldIon = damageTable.shieldIon + fractionalDamage.iIonDamage
				if damageTable.shieldIon >= 1 then
					damageTable.shieldIon = damageTable.shieldIon - 1
					ion_shields(shipManager, projectile)
				end
			elseif fractionalDamage.iIonDamage then
				damageTable.shieldIon = fractionalDamage.iIonDamage
			end
		end
	end)

	script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
		local fractionalDamage = weaponInfo[projectile.extend.name]["fractionalDamage"]
	    if fractionalDamage.doFractionalDamage then
	    	local hullTable = userdata_table(shipManager, "mods.arclua.hullDamage")
	    	local targetRoom = get_room_at_location(shipManager, location, true)
	    	if fractionalDamage.iDamage then
	    		if hullTable.hullDamage then
					hullTable.hullDamage = hullTable.hullDamage + fractionalDamage.iDamage
					if hullTable.hullDamage >= 1 then
						hullTable.hullDamage = hullTable.hullDamage - 1
						shipManager:DamageHull(1, true)
					end
				elseif fractionalDamage.iDamage then
					hullTable.hullDamage = fractionalDamage.iDamage
				end
	    	end
	    	if (fractionalDamage.iDamage + fractionalDamage.iSystemDamage or fractionalDamage.iIonDamage) and shipManager:GetSystemInRoom(targetRoom) then
	    		local system = shipManager:GetSystemInRoom(targetRoom)
	    		local sysTable = userdata_table(system, "mods.arclua.sysDamage")
	    		local fDamage = Hyperspace.Damage()
	    		local doesDamage = false

	    		if sysTable.sysDamage and fractionalDamage.iSystemDamage then
					sysTable.sysDamage = sysTable.sysDamage + fractionalDamage.iSystemDamage
					if sysTable.sysDamage >= 1 then
						sysTable.sysDamage = sysTable.sysDamage - 1
						fDamage.iSystemDamage = 1
						doesDamage = true
					end
				elseif fractionalDamage.iSystemDamage then
					sysTable.sysDamage = fractionalDamage.iSystemDamage
				end

	    		if sysTable.ionDamage and fractionalDamage.iIonDamage then
					sysTable.ionDamage = sysTable.ionDamage + fractionalDamage.iIonDamage
					if sysTable.ionDamage >= 1 then
						sysTable.ionDamage = sysTable.ionDamage - 1
						fDamage.iIonDamage = 1
						doesDamage = true
					end
				elseif fractionalDamage.iIonDamage then
					sysTable.ionDamage = fractionalDamage.iIonDamage
				end

				if doesDamage then
					shipManager:DamageArea(projectile.position, fDamage, true)
				end
	    	end
	    	if fractionalDamage.iPersDamage then
	    		local crewDamage = fractionalDamage.iPersDamage * -15
	    		for crewmem in vter(get_ship_crew_room(shipManager, targetRoom)) do
	    			crewmem:DirectModifyHealth(crewDamage)
	    		end
	    	end
	    end
	end)

	script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
		local hullTable = userdata_table(shipManager, "mods.arclua.hullDamage")
		if hullTable.hullDamage then
			hullTable.hullDamage = nil
		end
		for system in vter(shipManager.vSystemList) do
			local sysTable = userdata_table(system, "mods.arclua.sysDamage")
			if sysTable.sysDamage then
				sysTable.sysDamage = nil
			end
			if sysTable.ionDamage then
				sysTable.ionDamage = nil
			end
		end
	end)

	--[[script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
		if Hyperspace.Global.GetInstance():GetCApp().world.bStartedGame then
			local shipManager = Hyperspace.Global.GetInstance():GetShipManager(0)
	        local hullTable = userdata_table(shipManager, "mods.arclua.hullDamage")
	        local mousePos = Hyperspace.Mouse.Position
	        if hullTable.hullDamage then
	        	local hullHP = tostring(hullTable.hullDamage)
	        	
	        	if mousePos.x >= 62 and mousePos.y >= 38 and mousePos.x < 92 and mousePos.y < 60 then
	        		Hyperspace.Mouse.tooltip = "Sustained Fractional Damage: " .. hullHP
	        	end
	        end
	        local targetRoom = get_room_at_location(shipManager, mousePos, false)
	        if targetRoom then
	        	if shipManager:GetSystemInRoom(targetRoom) then
	        		local system = shipManager:GetSystemInRoom(targetRoom)
	        		local sysTable = userdata_table(system, "mods.arclua.sysDamage")
	        		local s = ""
	        		if sysTable.sysDamage then
						local sysHP = tostring(sysTable.sysDamage)
						s = "Sustained Fractional System Damage: ".. sysHP
					end
					if sysTable.ionDamage then
						local ionHP = tostring(sysTable.ionDamage)
						s = s .. "Sustained Fractional Ion Damage: ".. ionHP
					end
					if s then
						Hyperspace.Mouse.tooltip = s
					end
	        	end
	        end
	    end
	end)]]

	--[[script.on_render_event(Defines.RenderEvents.MOUSE_CONTROL, function()
	    if Hyperspace.Global.GetInstance():GetCApp().world.bStartedGame then
	        local shipManager = Hyperspace.Global.GetInstance():GetShipManager(0)
	        local hullTable = userdata_table(shipManager, "mods.arclua.hullDamage")
	        if hullTable.hullDamage then
	            local hullHP = tostring(math.Round(hullTable.hullDamage, 1))
	            local xPos = 92
	            local yPos = 35
	            local xText = 98
	            local yText = 44
	            local tempHpImage = Hyperspace.Resources:CreateImagePrimitiveString(
	                "statusUI/arc_fractionalHP.png",
	                xPos,
	                yPos,
	                0,
	                Graphics.GL_Color(1, 1, 1, 1),
	                1.0,
	                false)
	            Graphics.CSurface.GL_RenderPrimitive(tempHpImage)
	            local font = Graphics.freetype
	            print(font.font_data.font)

	            font.easy_print(0, xText, yText, string.sub(hullHP, 2))
	        end
	    end
	end, function() end)]]
end

tag_add_weapons("fractionalDamage", parser, logic)

