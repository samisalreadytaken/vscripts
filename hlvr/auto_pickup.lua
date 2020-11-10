-------------------------------------------------------------------------
--------------------- Copyright (c) samisalreadytaken -------------------
--                       github.com/samisalreadytaken
-------------------------------------------------------------------------

if not IsServer() then
	return
end

local VS = require "vs_library-012"

if g_iAutoPickupEventRelease then
	StopListeningToGameEvent(g_iAutoPickupEventRelease)
	g_iAutoPickupEventRelease = nil
end

if g_iAutoPickupEventLockOnStart then
	StopListeningToGameEvent(g_iAutoPickupEventLockOnStart)
	StopListeningToGameEvent(g_iAutoPickupEventLockOnStop)
	g_iAutoPickupEventLockOnStart = nil
	g_iAutoPickupEventLockOnStop = nil
end

local m_hPlayer, m_hHand0, m_hHand1, m_hBackpack
local m_iPrimaryHand
local OnRelease, OnLockOnStart, OnLockOnStop
local flFrameTime = FrameTime()

local m_bEnabled = true
local m_bModeLockOn = false

do
	local Entities,Convars,Warning = Entities,Convars,Warning
	local IsResource =
	{
		item_hlvr_clip_generic_pistol = true,
		item_hlvr_clip_generic_pistol_multiple = true,
		item_hlvr_clip_energygun = true,
		item_hlvr_clip_energygun_multiple = true,
		item_hlvr_clip_rapidfire = true,
		item_hlvr_clip_shotgun_single = true,
		item_hlvr_clip_shotgun_shellgroup = true,
		item_hlvr_clip_shotgun_shells_pair = true,
		item_hlvr_clip_shotgun_multiple = true,
		item_hlvr_crafting_currency_small = true,
		item_hlvr_crafting_currency_large = true
	}

	local bFrame0 = false
	local m_vecPrevOrigin

	local FadeAndPickup = function(self)

		local a = self:GetRenderAlpha()

		if a > 32 then
			self:SetRenderAlpha(a - 32)
			return flFrameTime
		else
			if bFrame0 then
				m_vecPrevOrigin = self:GetOrigin()
				self:SetOrigin(m_hBackpack:GetCenter())
				bFrame0 = false
				return flFrameTime
			else
				self:SetRenderAlpha(255)
				self:SetOrigin(m_vecPrevOrigin)
				self:EmitSound("JunctionBox.Clunk")

				local cv = Convars:GetInt("hlvr_left_hand_primary")

				if cv ~= m_iPrimaryHand then
					m_iPrimaryHand = cv
					m_hHand0,m_hHand1 = m_hHand1,m_hHand0
					Warning("auto_pickup: primary hand was changed\n")
				end

				Warning("auto_pickup: failed to pickup item\n")
			end
		end
	end

	OnRelease = function(data)

		local item = data.item

		if IsResource[item] then

			local vecSpot

			if data.vr_tip_attachment == 1 then
				vecSpot = m_hHand0:GetAttachmentOrigin(3)
			else
				vecSpot = m_hHand1:GetAttachmentOrigin(3)
			end

			local ent = Entities:FindByClassnameNearest(item,vecSpot,8.0)

			if not ent then
				return Warning("auto_pickup: could not find item in hand, aborting\n")
			end

			if item == "item_hlvr_crafting_currency_large" then
				-- Vector(5.5,5.0,3.0)
				-- Vector(1.435570,1.437361,5.0)
				if Entities:FindByClassnameWithin(nil,"trigger_crafting_station_object_placement",ent:GetOrigin(),16.0) then
					return
				end
			end

			bFrame0 = true
			ent:SetContextThink("AP_FadeAndPickup",FadeAndPickup,flFrameTime)
		end
	end
end

do
	local EntIndexToHScript,Convars,SendToServerConsole,StartSoundEventFromPosition,FireGameEvent,tostring =
	      EntIndexToHScript,Convars,SendToServerConsole,StartSoundEventFromPosition,FireGameEvent,tostring
	local event_data = { userid = 1 }

	local FadeAndKill = function(self)

		local a = self:GetRenderAlpha()

		if a > 32 then
			self:SetRenderAlpha(a - 32)
			return flFrameTime
		else
			self:Kill()
		end
	end

	local AddResourceAmmo = function(ent,pistol,rapidfire,shotgun,ammotype)
		SendToServerConsole("hlvr_addresources "..tostring(pistol).." "..tostring(rapidfire).." "..tostring(shotgun).." 0")
		ent:EmitSound("Inventory.DepositItem")
		event_data.ammotype = ammotype
		FireGameEvent("player_drop_ammo_in_backpack",event_data)
		event_data.ammotype = nil

		-- FireGameEvent("item_pickup",event_data)
		ent:FireOutput("OnPlayerPickup",m_hPlayer,ent,nil,0)

		ent:SetContextThink("AP_FadeAndKill",FadeAndKill,flFrameTime)
	end

	local AddResourceResin = function(ent,amt)
		SendToServerConsole("hlvr_addresources 0 0 0 "..tostring(amt))
		ent:EmitSound("Inventory.BackpackGrabItemResin")
		FireGameEvent("player_drop_resin_in_backpack",event_data)

		-- FireGameEvent("item_pickup",event_data)
		ent:FireOutput("OnPlayerPickup",m_hPlayer,ent,nil,0)
		ent:FireOutput("OnPutInInventory",m_hPlayer,ent,nil,0)

		ent:SetContextThink("AP_FadeAndKill",FadeAndKill,flFrameTime)
	end

	local AddResource =
	{
		-- item_hlvr_clip_generic_pistol
		-- item_hlvr_clip_generic_pistol_multiple
		item_hlvr_clip_energygun = function(ent)
			return AddResourceAmmo(ent,Convars:GetInt("vr_energygun_ammo_per_clip"),0,0,"Pistol")
		end,
		item_hlvr_clip_energygun_multiple = function(ent)
			return AddResourceAmmo(ent,Convars:GetInt("vr_energygun_ammo_per_large_clip"),0,0,"Pistol")
		end,
		item_hlvr_clip_rapidfire = function(ent)
			return AddResourceAmmo(ent,0,Convars:GetInt("vr_rapidfire_ammo_per_capsule"),0,"SMG1")
		end,
		item_hlvr_clip_shotgun_single = function(ent)
			return AddResourceAmmo(ent,0,0,1,"Buckshot")
		end,
		item_hlvr_clip_shotgun_shellgroup = function(ent)
			return AddResourceAmmo(ent,0,0,2,"Buckshot")
		end,
		item_hlvr_clip_shotgun_shells_pair = function(ent)
			return AddResourceAmmo(ent,0,0,2,"Buckshot")
		end,
		item_hlvr_clip_shotgun_multiple = function(ent)
			return AddResourceAmmo(ent,0,0,5,"Buckshot")
		end,
		item_hlvr_crafting_currency_small = function(ent)
			return AddResourceResin(ent,1)
		end,
		item_hlvr_crafting_currency_large = function(ent)
			return AddResourceResin(ent,5)
		end
	}

	local entindex

	OnLockOnStart = function(data)
		entindex = data.entindex
	end

	OnLockOnStop = function()

		local ent = EntIndexToHScript(entindex)

		if ent then

			local AddResource = AddResource[ent:GetClassname()]

			if AddResource then
				AddResource(ent)
			end

		end
	end
end

local function ListenToEventRelease(i)

	if i then

		if not g_iAutoPickupEventRelease then

			g_iAutoPickupEventRelease = ListenToGameEvent("item_released", OnRelease, nil)

		end

	else

		if g_iAutoPickupEventRelease then

			StopListeningToGameEvent(g_iAutoPickupEventRelease)
			g_iAutoPickupEventRelease = nil

		end

	end
end

local function ListenToEventLockOn(i)

	if i then

		if not g_iAutoPickupEventLockOnStart then

			g_iAutoPickupEventLockOnStart = ListenToGameEvent("grabbity_glove_locked_on_start", OnLockOnStart,nil)
			g_iAutoPickupEventLockOnStop  = ListenToGameEvent("grabbity_glove_locked_on_stop",  OnLockOnStop, nil)

		end

	else

		if g_iAutoPickupEventLockOnStart then

			StopListeningToGameEvent(g_iAutoPickupEventLockOnStart)
			StopListeningToGameEvent(g_iAutoPickupEventLockOnStop)
			g_iAutoPickupEventLockOnStart = nil
			g_iAutoPickupEventLockOnStop = nil

		end

	end
end

local function Init(bLoadFile)

	m_hPlayer = Entities:GetLocalPlayer()

	if m_hPlayer then

		local HMDAvatar = m_hPlayer:GetHMDAvatar()

		if HMDAvatar then

			m_iPrimaryHand = Convars:GetInt("hlvr_left_hand_primary")

			if m_iPrimaryHand == 0 then
				m_hHand0 = HMDAvatar:GetVRHand(1)
				m_hHand1 = HMDAvatar:GetVRHand(0)
			else
				m_hHand0 = HMDAvatar:GetVRHand(0)
				m_hHand1 = HMDAvatar:GetVRHand(1)
			end

			-- thumb
			-- m_iHand0Idx = 11 - m_hHand0:GetHandID()
			-- m_iHand1Idx = 11 - m_hHand1:GetHandID()

			m_hBackpack = Entities:FindByClassname(nil,"player_backpack")

			if not m_hBackpack then
				Warning("auto_pickup: could not find backpack!")
				-- return false
			end

			if m_bEnabled then

				ListenToEventRelease(true)

				if bLoadFile then
					Msg("auto_pickup: activated\n")
				end

			end

			if bLoadFile then
				SendToConsole("execifexists auto_pickup")
			end

			return true

		end

	end

	return false
end

Convars:RegisterCommand("auto_pickup_mode", function(cmd,input)

	if not input then
		return Msg(cmd.." = "..vlua.select(m_bModeLockOn,"1\n","0\n"))
	end

	if not Init() then
		return Warning("auto_pickup: no player\n")
	end

	input = tonumber(input)

	if input == 0 then
		m_bModeLockOn = false
	else
		m_bModeLockOn = true
	end

	if not m_bEnabled then
		return
	end

	if m_bModeLockOn then

		if g_iAutoPickupEventLockOnStart then
			return Msg(cmd.." = 1\n")
		end

		ListenToEventLockOn(true)

		Msg("Enabled auto pickup by locking on\n")

	else

		if not g_iAutoPickupEventLockOnStart then
			return Msg(cmd.." = 0\n")
		end

		ListenToEventLockOn(false)

		Msg("Disabled auto pickup by locking on\n")

	end
end, "Set auto pickup lock on mode", FCVAR_NONE)

Convars:RegisterCommand("auto_pickup_enable", function(cmd,input)

	if not input then
		return Msg(cmd.." = "..vlua.select(m_bEnabled,"1\n","0\n"))
	end

	if not Init() then
		return Warning("auto_pickup: no player\n")
	end

	input = tonumber(input)

	if input == 0 then

		if not m_bEnabled then
			return Msg(cmd.." = 0\n")
		end

		m_bEnabled = false

	else

		if m_bEnabled then
			return Msg(cmd.." = 1\n")
		end

		m_bEnabled = true

	end

	if m_bEnabled then

		ListenToEventRelease(true)

		if m_bModeLockOn then
			ListenToEventLockOn(true)
		end

	else

		ListenToEventRelease(false)
		ListenToEventLockOn(false)

	end
end, "Enable auto pickup", FCVAR_NONE)

if not VS.OnPlayerSpawn( Init, "auto_pickup: could not find player, aborting", true ) then
	Init()
end
