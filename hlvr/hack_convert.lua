-------------------------------------------------------------------------
--------------------- Copyright (c) samisalreadytaken -------------------
--                       github.com/samisalreadytaken
-------------------------------------------------------------------------

if not SERVER_DLL then
	return
end

if g_iHackConvertEventWepSwitch then
	StopListeningToGameEvent( g_iHackConvertEventWepSwitch )
	g_iHackConvertEventWepSwitch = nil
end

local Entities,DoEntFireByInstanceHandle,SpawnEntityFromTableSynchronous,UTIL_Remove,
	Vector,Msg,Warning,Fmt =
	Entities,DoEntFireByInstanceHandle,SpawnEntityFromTableSynchronous,UTIL_Remove,
	Vector,Msg,Warning,string.format

local HACK_TYPE = {}
HACK_TYPE[0] = "prop_hlvr_holo_hacking_sphere_trace"
HACK_TYPE[1] = "prop_hlvr_holo_hacking_point_search"
HACK_TYPE[2] = "prop_hlvr_holo_hacking_core_search"
HACK_TYPE[3] = "prop_hlvr_holo_hacking_rod_pull"
HACK_TYPE[4] = "prop_hlvr_holo_hacking_point_match"
HACK_TYPE[6] = "prop_hlvr_holo_hacking_point_drag"

local OUTPUTS =
{
	"OnKilled",
	"OnUser1",
	"OnUser2",
	"OnUser3",
	"OnUser4",
	"OnHackStarted",
	"OnHackStopped",
	"OnHackSuccess",
	"OnHackFailed",
	"OnHackSuccessAnimationComplete",
	"OnPuzzleCompleted",
	"OnPuzzleSuccess",
	"OnPuzzleFailed"
}

local m_hPlayer, m_HMDAvatar
local m_flThinkInterval = 2.0
local m_iConvertFrom,m_iConvertTo = 0,3
local m_szDifficultyName = "medium"
local m_iIntroVar = 0
local m_bEnabled = true

local m_KeyValues =
{
	origin             = nil,
	angles             = nil,
	scales             = nil,
	puzzletype         = nil,
	introvariation     = nil,
	hackdifficultyname = nil,
	puzzlespawntarget  = nil,
	starthacked        = 0
}

local function ConvertHack( hEnt, nType )

	do local sc = hEnt:GetPrivateScriptScope()
	if sc and sc.m_hHackConvertParent then
		Msg("hack_convert: converting a previously converted hack\n")
		hEnt:Kill()
		hEnt = sc.m_hHackConvertParent
	end end

	local ori = hEnt:GetAbsOrigin()
	--
	-- Check if an unexpected plug exists on the spot
	-- This will only happen if BeginHack input was manually fired to the disabled original plug.
	-- In an extreme case where the target and the original hack types are the same after conversion,
	-- and the BeginHack input is fired to the original plug, the replaced one will still be accessible
	-- This could be fixed by executing this code block at the (iFrom == m_iConvertTo) check in Think
	--
	do local ents = Entities:FindAllByClassnameWithin( "info_hlvr_holo_hacking_plug", ori, 0.1 )
	for i = 1, #ents do

		local p = ents[i]
		if p ~= hEnt then

			local sc = p:GetPrivateScriptScope()
			if sc and sc.m_hHackConvertParent then

				Warning("hack_convert: found an unexpected previously converted hack\n")
				p:Kill()
				return ConvertHack( hEnt, nType )

			else

				Msg("hack_convert: found a map placed hack too close to another one\n")

			end

		end

	end end

	local ang = hEnt:GetAngles()
	local szTarget, hTarget

	-- if nType == 0 or nType == 1 or nType == 2 or nType == 4 then
	if nType ~= 3 and nType ~= 5 and nType ~= 6 then
		szTarget = DoUniqueString("_target")
		local pos = m_HMDAvatar:GetOrigin()
		pos.z = pos.z - 12.0

		hTarget = SpawnEntityFromTableSynchronous("info_hlvr_holo_hacking_spawn_target",
		{
			targetname = szTarget,
			origin = ori + (pos - ori):Normalized() * 24.0,
			angles = ang,
			radius = 7.0
		})
	end

	local scale = hEnt:GetLocalScale()

		m_KeyValues.origin             = ori
		m_KeyValues.angles             = ang
		m_KeyValues.scales             = Vector(scale,scale,scale)
		m_KeyValues.puzzletype         = nType
		m_KeyValues.introvariation     = m_iIntroVar
		m_KeyValues.hackdifficultyname = m_szDifficultyName
		m_KeyValues.puzzlespawntarget  = szTarget

	local hPlug = SpawnEntityFromTableSynchronous( "info_hlvr_holo_hacking_plug", m_KeyValues )

	-- add to hierarchy
	-- NOTE: Parent to the old plug to cover all cases. Otherwise use parent attachment "hacking_point_attach"
	hPlug:SetParent( hEnt, "" )

	if hTarget then
		hTarget:SetOwner( hPlug )
		hTarget:SetParent( hPlug, "" )
	end

	local sc = hPlug:GetOrCreatePrivateScriptScope()
	sc.m_hHackConvertParent = hEnt

	-- don't try to convert me again
	hEnt:GetOrCreatePrivateScriptScope().m_bHackConverted = true

	for i = 1,13 do
		local v = OUTPUTS[i]
		sc[v] = function() hEnt:FireOutput( v, m_hPlayer, hEnt, nil, 0 ) end
		hPlug:RedirectOutput(v,v,hPlug)
	end
	--
	-- Type 5 only fires OnHackSuccess > OnHackSuccessAnimationComplete
	-- So, manually fire the missing outputs in this conversion
	--
	-- This also fixes tripmines, which listen to these two outputs:
	-- OnPuzzleSuccess > OnHackSuccessAnimationComplete
	--
	if nType == 5 then
		sc.OnHackSuccessAnimationComplete = function()
			hEnt:FireOutput( "OnHackStarted", m_hPlayer, hEnt, nil, 0 )
			hEnt:FireOutput( "OnPuzzleCompleted", m_hPlayer, hEnt, nil, 0 )
			hEnt:FireOutput( "OnPuzzleSuccess", m_hPlayer, hEnt, nil, 0 )
			hEnt:FireOutput( "OnHackStopped", m_hPlayer, hEnt, nil, 0 )
			hEnt:FireOutput( "OnHackSuccessAnimationComplete", m_hPlayer, hEnt, nil, 0 )
		end

		-- If it's simple activate, it can be automated.
		-- However simply firing BeginHack does not play the animations (projector_out, hacked), and
		-- they can't seem to be manually played either.
		-- DoEntFireByInstanceHandle( hPlug, "BeginHack", "", 0.0, m_hPlayer, nil )
	end

	-- the original is preserved for the outputs
	DoEntFireByInstanceHandle( hEnt, "Disable", "", 0, nil, nil )
	hEnt:AddEffects(32) -- EF_NODRAW

	Msg("hack_convert: success\n")
end

local function ThinkHackConvert()

	local holo
	local iFrom = m_iConvertFrom

	if iFrom == -1 then
		for i = 0,6 do
			holo = Entities:FindByClassname( nil, HACK_TYPE[i] )
			if holo then
				iFrom = i
				break
			end
		end
	else
		holo = Entities:FindByClassname( nil, HACK_TYPE[iFrom] )
	end

	if holo then

		if iFrom == m_iConvertTo then
			return m_flThinkInterval
		end

		local plug = holo:GetOwner()

		if plug then
--[[
			if plug:GetClassname() ~= "info_hlvr_holo_hacking_plug" then
				Warning("hack_convert: found unowned hacking holo\n")
				plug = Entities:FindByClassnameNearest("info_hlvr_holo_hacking_plug",holo:GetOrigin(),128)
				if not plug then
					return m_flThinkInterval
				end
			end
--]]
			UTIL_Remove( holo )

			if plug:GetOrCreatePrivateScriptScope().m_bHackConverted then
				-- a new holo was spawned, it's dead now
				return m_flThinkInterval
			end

			Msg(Fmt( "hack_convert: %d->%d\n", iFrom, m_iConvertTo ))
			ConvertHack( plug, m_iConvertTo )
			return m_flThinkInterval
		end

	end

	return m_flThinkInterval
end

local function OnWeaponSwitch(event)

	if event.item == "hlvr_multitool" then

		m_flThinkInterval = 0.15
		m_hPlayer:SetContextThink( "ThinkHackConvert", ThinkHackConvert, 0.0 )

	elseif m_flThinkInterval ~= 2.0 then

		m_flThinkInterval = 2.0

	end

end

local function Init( bLoadFile )

	m_hPlayer = Entities:GetLocalPlayer()

	if m_hPlayer then

		m_HMDAvatar = m_hPlayer:GetHMDAvatar()

		if m_HMDAvatar then

			if m_bEnabled then

				if Entities:FindByClassname( nil, "info_hlvr_holo_hacking_plug" ) then

					if not g_iHackConvertEventWepSwitch then
						g_iHackConvertEventWepSwitch = ListenToGameEvent( "weapon_switch", OnWeaponSwitch, nil )
					end

					m_hPlayer:SetContextThink( "ThinkHackConvert", ThinkHackConvert, 1.0 )

					if bLoadFile then
						Msg("hack_convert: activated\n")
					end

				else

					Warning("hack_convert::Init no hacking puzzles found in the map, disabling conversion\n")
					m_bEnabled = false

				end

			end

			if bLoadFile then
				SendToConsole("execifexists hack_convert")
			end

			return true

		end

	end

	return false
end

Convars:RegisterCommand("hack_convert", function( cmd, iFrom, iTo )

	iFrom = tonumber(iFrom)
	iTo = tonumber(iTo)

	if iFrom == iTo or iFrom == nil or iTo == nil then
		return Msg(Fmt( "%s = %d %d\n", cmd, m_iConvertFrom, m_iConvertTo ))
	end

	if iFrom < -1 or iFrom > 6 or iFrom == 5 or iTo < 0 or iTo > 6 then
		Msg(Fmt( "%s = %d %d\n", cmd, m_iConvertFrom, m_iConvertTo ))
		return Warning("Invalid puzzle type\n")
	end

	if not Init() then
		return Warning("hack_convert: no player\n")
	end

	m_iConvertFrom = iFrom
	m_iConvertTo = iTo

	if not Entities:FindByClassname( nil, "info_hlvr_holo_hacking_plug" ) then

		if m_bEnabled then
			Warning("No hacking puzzles found in the map (conversion is still enabled)\n")
		else
			Warning("No hacking puzzles found in the map\n")
		end

	end

	if not m_bEnabled then
		Msg("Hack conversion is currently disabled\n")
	end

end, "hack_convert <[-1,6]> <[0,6]>", FCVAR_NONE)

Convars:RegisterCommand("hack_convert_enable", function( cmd, input )

	if not input then
		return Msg( cmd..vlua.select( m_bEnabled, " = 1\n", " = 0\n" ) )
	end

	if not Init() then
		return Warning("hack_convert: no player\n")
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

		if not g_iHackConvertEventWepSwitch then
			g_iHackConvertEventWepSwitch = ListenToGameEvent( "weapon_switch", OnWeaponSwitch, nil )
		end

		m_flThinkInterval = 0.15
		m_hPlayer:SetContextThink( "ThinkHackConvert", ThinkHackConvert, 0.0 )

		if not Entities:FindByClassname( nil, "info_hlvr_holo_hacking_plug" ) then
			Warning("Enabled hack conversion, but no puzzles found in the map\n")
		end

	else

		if g_iHackConvertEventWepSwitch then
			StopListeningToGameEvent( g_iHackConvertEventWepSwitch )
			g_iHackConvertEventWepSwitch = nil
		end

		m_flThinkInterval = 2.0
		m_hPlayer:StopThink("ThinkHackConvert")

		if not Entities:FindByClassname( nil, "info_hlvr_holo_hacking_plug" ) then
			Warning("Disabled hack conversion, but no puzzles found in the map\n")
		end

	end

end, "Enable puzzle conversion", FCVAR_NONE)

Convars:RegisterCommand("hack_convert_difficulty", function( cmd, input )

	if not input then
		return Msg(Fmt( "%s = %s\n", cmd, m_szDifficultyName ))
	end

	m_szDifficultyName = input

	if not m_szDifficultyName then
		m_iIntroVar = "medium"
	end

end, "Puzzle difficulty (first|easy|medium|hard|veryhard)", FCVAR_NONE)

Convars:RegisterCommand("hack_convert_introvar", function( cmd, input )

	if not input then
		return Msg(Fmt( "%s = %d\n", cmd, m_iIntroVar ))
	end

	m_iIntroVar = tonumber(input)

	if not m_iIntroVar then
		m_iIntroVar = 0
	end

end, "Puzzle intro variation", FCVAR_NONE)

local VS = require "vs_library-014"

if not VS.OnPlayerSpawn( Init, "hack_convert: could not find player, aborting", true ) then
	Init()
end
