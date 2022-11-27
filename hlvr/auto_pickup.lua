-------------------------------------------------------------------------
--------------------- Copyright (c) samisalreadytaken -------------------
--                       github.com/samisalreadytaken
-------------------------------------------------------------------------

if not SERVER_DLL then
	return
end

if g_iAutoPickupEventRelease then
	StopListeningToGameEvent( g_iAutoPickupEventRelease )
	StopListeningToGameEvent( g_iAutoPickupEventWepSwitch )
	g_iAutoPickupEventRelease = nil
	g_iAutoPickupEventWepSwitch = nil
end

if g_iAutoPickupEventLockOnStart then
	StopListeningToGameEvent( g_iAutoPickupEventLockOnStart )
	StopListeningToGameEvent( g_iAutoPickupEventLockOnStop )
	g_iAutoPickupEventLockOnStart = nil
	g_iAutoPickupEventLockOnStop = nil
end

local m_hPlayer, m_hHand0, m_hHand1, m_hBackpack
local m_iPrimaryHand, m_iHand0Idx, m_iHand1Idx
local FadeAndPickupExternalNoSound

local m_bEnabled = true
local m_bModeLockOn = false

local m_flInsDetectionRange = 7.5
local m_bReloadDebug = false

	local Entities,Time,FrameTime,Convars,Warning,Msg,next,append = Entities,Time,FrameTime,Convars,Warning,Msg,next,table.insert
	local IsResource =
	{
		item_hlvr_clip_generic_pistol          = true,
		item_hlvr_clip_generic_pistol_multiple = true,
		item_hlvr_clip_energygun               = true,
		item_hlvr_clip_energygun_multiple      = true,
		item_hlvr_clip_rapidfire               = true,
		item_hlvr_clip_shotgun_single          = true,
		item_hlvr_clip_shotgun_shellgroup      = true,
		item_hlvr_clip_shotgun_shells_pair     = true,
		item_hlvr_clip_shotgun_multiple        = true,
		item_hlvr_crafting_currency_small      = true,
		item_hlvr_crafting_currency_large      = true
	}

	local IsInsertable =
	{
		item_hlvr_clip_energygun          = "hlvr_weapon_energygun",
		item_hlvr_clip_rapidfire          = "hlvr_weapon_rapidfire",
		item_hlvr_clip_shotgun_single     = "hlvr_weapon_shotgun",
		item_hlvr_clip_shotgun_shellgroup = "hlvr_weapon_shotgun",
		item_hlvr_clip_generic_pistol     = "hlvr_weapon_generic_pistol"
	}

	local WeaponAttachment =
	{
		hlvr_weapon_energygun      = "vr_interact_clip", -- 3
		hlvr_weapon_rapidfire      = "reload_clip_attach_mag", -- 14
		hlvr_weapon_shotgun        = "hinge_attach", -- 9
		hlvr_weapon_generic_pistol = "vr_interact_clip" -- 3
	}

	local m_Frames = {}
	local m_vecPrevOrigins = {}
	local m_DeferredCleanup = {}
	local m_vecShellPos
	local m_szCurrWeapon
	local m_hWeapon

	local FadeAndPickup = function(self)

		-- local a = 255 * ( 1.0 - ( Time() - m_flReleaseTimes[self] ) / FADE_TIME )
		local a = self:GetRenderAlpha()

		if a > 31 then
			self:SetRenderAlpha( a - 31 )
			return 0.0
		end

		if m_Frames[self] then

			local pos = self:GetOrigin()

			-- final check
			if m_szCurrWeapon and ( m_szCurrWeapon == IsInsertable[self:GetClassname()] ) then

				if m_bReloadDebug then

					debugoverlay:Sphere( m_hWeapon:GetAttachmentOrigin( m_hWeapon:ScriptLookupAttachment( WeaponAttachment[m_szCurrWeapon] ) ), 0.25, 255, 0, 155, 255, true, 5.0 )
					debugoverlay:Sphere( pos, m_flInsDetectionRange, 255, 0, 0, 255, true, 5.0 )

				end

				if ( m_hWeapon:GetAttachmentOrigin( m_hWeapon:ScriptLookupAttachment( WeaponAttachment[m_szCurrWeapon] ) ) - pos ):Length() < m_flInsDetectionRange then
					self:SetRenderAlpha( 255 )
					m_Frames[self] = nil
					-- m_flReleaseTimes[self] = nil
					return -- Msg("auto_pickup: second weapon check passed, cancelling pickup\n")
				end
			end

			m_Frames[self] = nil
			m_vecPrevOrigins[self] = pos

			if m_hBackpack then
				self:SetOrigin( m_hBackpack:GetCenter() )
			else
				Warning("auto_pickup: no backpack\n")
				m_hBackpack = Entities:FindByClassname( nil, "player_backpack" )
			end

			return 0.0

		end

		self:SetRenderAlpha( 255 )
		self:SetOrigin( m_vecPrevOrigins[self] )
		self:EmitSound( "JunctionBox.Clunk" )

		-- m_flReleaseTimes[self] = nil
		m_vecPrevOrigins[self] = nil

		local cv = Convars:GetInt("hlvr_left_hand_primary")

		if cv ~= m_iPrimaryHand then
			m_iPrimaryHand = cv
			m_hHand0, m_hHand1 = m_hHand1, m_hHand0
			Warning("auto_pickup: primary hand was changed\n")
		end

		Warning("auto_pickup: failed to pickup item\n")

	end

	local PickupShellgroup = function()

		local h1 = Entities:FindByClassnameWithin( nil, "item_hlvr_clip_shotgun_single", m_vecShellPos, 7.5 )
		if h1 then

			h1:SetContextThink( "AP_FadeAndPickup", FadeAndPickupExternalNoSound, 0.0 )

			local h2 = Entities:FindByClassnameWithin( h1,  "item_hlvr_clip_shotgun_single", m_vecShellPos, 7.5 )
			if h2 then

				h2:SetContextThink( "AP_FadeAndPickup", FadeAndPickupExternalNoSound, 0.0 )

				-- shellgroup draws 3 shells from backpack when shotgun is upgraded
				if Entities:FindByModelWithin( nil, "models/weapons/vr_shotgun/shotgun_hopper.vmdl", m_hHand0:GetOrigin(), 6.0 ) then

					h2 = Entities:FindByClassnameWithin( h2,  "item_hlvr_clip_shotgun_single", m_vecShellPos, 7.5 )
					if h2 then
						h2:SetContextThink( "AP_FadeAndPickup", FadeAndPickupExternalNoSound, 0.0 )
					else
						Warning("auto_pickup: could not find the 3rd shell in shellgroup!\n")
					end
				end
			else
				Warning("auto_pickup: could not find the 2nd shell in shellgroup!\n")
			end
			h1:EmitSound( "Inventory.DepositItem" )
		else
			Warning("auto_pickup: could not find any shells in shellgroup!\n")
		end
	end

	local OnRelease = function(data)

		local item = data.item

		if IsResource[item] then

			local vecSpot
			local bIsHand0 = data.vr_tip_attachment == 1

			if bIsHand0 then
				vecSpot = m_hHand0:GetAttachmentOrigin(3)
			else
				vecSpot = m_hHand1:GetAttachmentOrigin(3)
			end

			local ent = Entities:FindByClassnameNearest( item, vecSpot, 8.0 )

			if not ent then
				-- could have been reloaded
				return Msg("auto_pickup: could not find item in hand, aborting\n")
			end

			local szInsertable = IsInsertable[item]

			if szInsertable then

				if szInsertable == m_szCurrWeapon then

					local hWep = Entities:FindByClassnameWithin( nil, m_szCurrWeapon, m_hHand0:GetOrigin(), 4.5 )

					if hWep then

						local vecEntPos

						-- shellgroup origin is displaced, use middle finger
						if item == "item_hlvr_clip_shotgun_shellgroup" then
							vecEntPos = m_hHand1:GetAttachmentOrigin( m_iHand1Idx )
						else
							vecEntPos = ent:GetOrigin()
						end

						m_hWeapon = hWep

						if m_bReloadDebug then

							debugoverlay:Sphere( hWep:GetAttachmentOrigin( m_hWeapon:ScriptLookupAttachment( WeaponAttachment[m_szCurrWeapon] ) ), 0.25, 155, 255, 155, 255, true, 5.0 )
							debugoverlay:Sphere( vecEntPos, m_flInsDetectionRange, 0, 255, 0, 255, true, 5.0 )

						end

						if ( hWep:GetAttachmentOrigin( m_hWeapon:ScriptLookupAttachment( WeaponAttachment[m_szCurrWeapon] ) ) - vecEntPos ):Length() < m_flInsDetectionRange then
							return -- Msg("auto_pickup: cancelled for ammo reload\n")
						end

					end

				end

				-- Entity is destroyed in the next frame
				if item == "item_hlvr_clip_shotgun_shellgroup" then

					if bIsHand0 then
						m_vecShellPos = m_hHand0:GetAttachmentOrigin( m_iHand0Idx )
					else
						m_vecShellPos = m_hHand1:GetAttachmentOrigin( m_iHand1Idx )
					end

					m_hHand0:SetContextThink( "AP_PickupShellgroup", PickupShellgroup, 0.0 )

					return -- Msg("auto_pickup: shellgroup pickup\n")

				end

			elseif item == "item_hlvr_crafting_currency_large" then

				if Entities:FindByClassnameWithin( nil, "trigger_crafting_station_object_placement", ent:GetOrigin(), 32.0 ) then
					return -- Msg("auto_pickup: cancelled for resin station\n")
				end

			end

			-- m_flReleaseTimes[ent] = Time() - FrameTime()
			m_Frames[ent] = true

			ent:SetContextThink( "AP_FadeAndPickup", FadeAndPickup, 0.0 )

			-- There shouldn't be more than 2 to 3 in this list, but defer deletion to be safe
			for k,v in next,m_vecPrevOrigins do
				if k and k:IsNull() then
					append( m_DeferredCleanup, k )
				end
			end
			local c = #m_DeferredCleanup
			for i = 1, c do
				m_vecPrevOrigins[ m_DeferredCleanup[i] ] = nil
				m_DeferredCleanup[i] = nil
			end

		end
	end

	local OnWeaponSwitch = function(ev)

		local item = ev.item

		if WeaponAttachment[item] then

			m_szCurrWeapon = item

		elseif m_szCurrWeapon then

			m_szCurrWeapon = nil

		end
	end

-----------------------------------------
-----------------------------------------

	local EntIndexToHScript,SendToServerConsole,FireGameEvent,Fmt =
		  EntIndexToHScript,SendToServerConsole,FireGameEvent,string.format
	local event_data = { userid = 1 }

	local AddResourceAmmo = function( ent, pistol, rapidfire, shotgun, ammotype, bSnd )

		SendToServerConsole(Fmt( "hlvr_addresources %d %d %d 0", pistol, rapidfire, shotgun ))
		event_data.ammotype = ammotype
		FireGameEvent( "player_drop_ammo_in_backpack", event_data )
		event_data.ammotype = nil

		-- FireGameEvent( "item_pickup", event_data )
		ent:FireOutput( "OnPlayerPickup", m_hPlayer, ent, nil, 0 )

		-- quick hack for shellgroup pickup
		if not bSnd then
			ent:EmitSound( "Inventory.DepositItem" )
		end
		ent:Kill()

	end

	local AddResourceResin = function( ent, amt )

		SendToServerConsole(Fmt( "hlvr_addresources 0 0 0 %d", amt ))
		FireGameEvent( "player_drop_resin_in_backpack", event_data )

		-- FireGameEvent( "item_pickup", event_data )
		ent:FireOutput( "OnPlayerPickup", m_hPlayer, ent, nil, 0 )
		ent:FireOutput( "OnPutInInventory", m_hPlayer, ent, nil, 0 )

		ent:EmitSound( "Inventory.BackpackGrabItemResin" )
		ent:Kill()

	end

	local AddResource =
	{
		-- item_hlvr_clip_generic_pistol
		-- item_hlvr_clip_generic_pistol_multiple
		item_hlvr_clip_energygun = function(ent)
			return AddResourceAmmo( ent, Convars:GetInt("vr_energygun_ammo_per_clip"), 0, 0, "Pistol" )
		end,
		item_hlvr_clip_energygun_multiple = function(ent)
			return AddResourceAmmo( ent, Convars:GetInt("vr_energygun_ammo_per_large_clip"), 0, 0, "Pistol" )
		end,
		item_hlvr_clip_rapidfire = function(ent)
			return AddResourceAmmo( ent, 0, Convars:GetInt("vr_rapidfire_ammo_per_capsule"), 0, "SMG1" )
		end,
		item_hlvr_clip_shotgun_single = function(ent, snd)
			return AddResourceAmmo( ent, 0, 0, 1, "Buckshot", snd )
		end,
		-- item_hlvr_clip_shotgun_shellgroup
		item_hlvr_clip_shotgun_shells_pair = function(ent)
			return AddResourceAmmo( ent, 0, 0, 2, "Buckshot" )
		end,
		item_hlvr_clip_shotgun_multiple = function(ent)
			return AddResourceAmmo( ent, 0, 0, 5, "Buckshot" )
		end,
		item_hlvr_crafting_currency_small = function(ent)
			return AddResourceResin( ent, 1 )
		end,
		item_hlvr_crafting_currency_large = function(ent)
			return AddResourceResin( ent, 5 )
		end
	}

	local FadeAndPickupExternal = function(self)

		local a = self:GetRenderAlpha()

		if a > 31 then
			self:SetRenderAlpha( a - 31 )
			return 0.0
		end

		AddResource[ self:GetClassname() ]( self )

	end

	FadeAndPickupExternalNoSound = function(self)

		local a = self:GetRenderAlpha()

		if a > 31 then
			self:SetRenderAlpha( a - 31 )
			return 0.0
		end

		-- final check
		if m_szCurrWeapon and ( m_szCurrWeapon == IsInsertable[self:GetClassname()] ) then

			local pos = self:GetOrigin()

			if m_bReloadDebug then
				debugoverlay:Sphere( m_hWeapon:GetAttachmentOrigin( m_hWeapon:ScriptLookupAttachment( WeaponAttachment[m_szCurrWeapon] ) ), 0.25, 255,0,255,255,true, 5.0 )
				debugoverlay:Sphere( pos, m_flInsDetectionRange, 255,0,0,255,true, 5.0 )
			end

			if ( m_hWeapon:GetAttachmentOrigin( m_hWeapon:ScriptLookupAttachment( WeaponAttachment[m_szCurrWeapon] ) ) - pos ):Length() < m_flInsDetectionRange then
				self:SetRenderAlpha( 255 )
				return -- Msg("auto_pickup: second weapon check passed, cancelling pickup\n")
			end
		end

		-- Only works for single shell; set up the second parameters in AddResource for other resources
		AddResource[ self:GetClassname() ]( self, true )

	end

	local entindex

	local OnLockOnStart = function(data)
		entindex = data.entindex
	end

	local OnLockOnStop = function()

		local ent = EntIndexToHScript(entindex)

		if ent then

			local szClass = ent:GetClassname()

			if IsResource[ szClass ] then

				if szClass == "item_hlvr_crafting_currency_large" then

					if Entities:FindByClassnameWithin( nil, "trigger_crafting_station_object_placement", ent:GetOrigin(), 32.0 ) then
						return -- Msg("auto_pickup: lock-on cancelled for resin station\n")
					end

				end

				ent:SetContextThink( "AP_FadeAndPickup", FadeAndPickupExternal, 0.0 )

			end
		end
	end

-----------------------------------------
-----------------------------------------

local function ListenToEventRelease(i)

	if i then
		if not g_iAutoPickupEventRelease then

			g_iAutoPickupEventRelease = ListenToGameEvent( "item_released", OnRelease, nil )
			g_iAutoPickupEventWepSwitch = ListenToGameEvent( "weapon_switch", OnWeaponSwitch, nil )

		end
	else
		if g_iAutoPickupEventRelease then

			StopListeningToGameEvent( g_iAutoPickupEventRelease )
			StopListeningToGameEvent( g_iAutoPickupEventWepSwitch )
			g_iAutoPickupEventRelease = nil
			g_iAutoPickupEventWepSwitch = nil

		end
	end
end

local function ListenToEventLockOn(i)

	if i then
		if not g_iAutoPickupEventLockOnStart then

			g_iAutoPickupEventLockOnStart = ListenToGameEvent( "grabbity_glove_locked_on_start", OnLockOnStart, nil )
			g_iAutoPickupEventLockOnStop = ListenToGameEvent( "grabbity_glove_locked_on_stop", OnLockOnStop,  nil )

		end
	else
		if g_iAutoPickupEventLockOnStart then

			StopListeningToGameEvent( g_iAutoPickupEventLockOnStart )
			StopListeningToGameEvent( g_iAutoPickupEventLockOnStop )
			g_iAutoPickupEventLockOnStart = nil
			g_iAutoPickupEventLockOnStop = nil

		end
	end
end

local function Init( bLoadFile )

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

			-- can hands be null?
			m_iHand0Idx = m_hHand0:ScriptLookupAttachment( "fingertip_middle" )
			m_iHand1Idx = m_hHand1:ScriptLookupAttachment( "fingertip_middle" )

			m_hBackpack = Entities:FindByClassname( nil, "player_backpack" )

			if not m_hBackpack then
				Warning("auto_pickup: could not find backpack!\n")

				-- look for it every 3 seconds
				m_hPlayer:SetContextThink( "AP_FindBackpack", function()
					m_hBackpack = Entities:FindByClassname( nil, "player_backpack" )
					if m_hBackpack then
						Msg("auto_pickup: found backpack")
						return -1
					end
					return 3
				end, 3 )
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

Convars:RegisterCommand("auto_pickup_ammo_insertion_range", function( cmd, input )

	if not input then
		return Msg( cmd.." = \""..tostring(m_flInsDetectionRange).."\"\n" )
	end

	input = tonumber(input)

	if input then
		m_flInsDetectionRange = input
	end

end, "", FCVAR_NONE)

Convars:RegisterCommand("auto_pickup_ammo_insertion_debug", function( cmd, input )

	if not input then
		return Msg( cmd..vlua.select( m_bReloadDebug, " = 1\n", " = 0\n" ) )
	end

	input = tonumber(input)

	if input == 0 then
		m_bReloadDebug = false
	else
		m_bReloadDebug = true
	end

end, "", FCVAR_NONE)

Convars:RegisterCommand("auto_pickup_mode", function( cmd, input )

	if not input then
		return Msg( cmd..vlua.select( m_bModeLockOn, " = 1\n", " = 0\n" ) )
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

Convars:RegisterCommand("auto_pickup_enable", function( cmd, input )

	if not input then
		return Msg( cmd..vlua.select( m_bEnabled, " = 1\n", " = 0\n" ) )
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

local VS = require "vs_library-014"

if not VS.OnPlayerSpawn( Init, "auto_pickup: could not find player, aborting", true ) then
	Init()
end
