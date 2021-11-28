-------------------------------------------------------------------------
-- github.com/samisalreadytaken
-- self euthanasia
-------------------------------------------------------------------------

if CLIENT_DLL then
	return
end

-- from vs_math
local IsBoxIntersectingRay = function( boxMin, boxMax, origin, vecDelta )

	local tmin, tmax, EPS = 1.175494351e-38, 3.402823466e+38, 1.e-8;

	if ( vecDelta.x < EPS and vecDelta.x > -EPS ) then
		if ( (origin.x < boxMin.x) or (origin.x > boxMax.x) ) then
			return false;
		end
	else
		local invDelta = 1.0 / vecDelta.x;
		local t1 = (boxMin.x - origin.x) * invDelta;
		local t2 = (boxMax.x - origin.x) * invDelta;
		if ( t1 > t2 ) then
			local tmp = t1;
			t1 = t2;
			t2 = tmp;
		end
		if (t1 > tmin) then
			tmin = t1;
		end
		if (t2 < tmax) then
			tmax = t2;
		end
		if (tmin > tmax) then
			return false;
		end
		if (tmax < 0.0) then
			return false;
		end
		if (tmin > 1.0) then
			return false;
		end
	end

	if ( vecDelta.y < EPS and vecDelta.y > -EPS ) then
		if ( (origin.y < boxMin.y) or (origin.y > boxMax.y) ) then
			return false;
		end
	else
		local invDelta = 1.0 / vecDelta.y;
		local t1 = (boxMin.y - origin.y) * invDelta;
		local t2 = (boxMax.y - origin.y) * invDelta;
		if ( t1 > t2 ) then
			local tmp = t1;
			t1 = t2;
			t2 = tmp;
		end
		if (t1 > tmin) then
			tmin = t1;
		end
		if (t2 < tmax) then
			tmax = t2;
		end
		if (tmin > tmax) then
			return false;
		end
		if (tmax < 0.0) then
			return false;
		end
		if (tmin > 1.0) then
			return false;
		end
	end

	if ( vecDelta.z < EPS and vecDelta.z > -EPS ) then
		if ( (origin.z < boxMin.z) or (origin.z > boxMax.z) ) then
			return false;
		end
	else
		local invDelta = 1.0 / vecDelta.z;
		local t1 = (boxMin.z - origin.z) * invDelta;
		local t2 = (boxMax.z - origin.z) * invDelta;
		if ( t1 > t2 ) then
			local tmp = t1;
			t1 = t2;
			t2 = tmp;
		end
		if (t1 > tmin) then
			tmin = t1;
		end
		if (t2 < tmax) then
			tmax = t2;
		end
		if (tmin > tmax) then
			return false;
		end
		if (tmax < 0.0) then
			return false;
		end
		if (tmin > 1.0) then
			return false;
		end
	end

	return true;
end

--------------------------------

if g_iSEFireEvent then
	StopListeningToGameEvent( g_iSEFireEvent )
	g_iSEFireEvent = nil
end

local Entities, CreateDamageInfo, DestroyDamageInfo = Entities, CreateDamageInfo, DestroyDamageInfo

local m_hPlayer, m_HMDAvatar
local m_vecAvatarMins, m_vecAvatarMaxs

g_iSEFireEvent = ListenToGameEvent( "player_shoot_weapon", function()

	local pos = m_hPlayer:ShootPosition( 0, 1 )
	local wep = Entities:FindByClassnameWithin( nil, "hlvr_weapon*", pos, 0.5 )
	if wep then

		local iAttachment = wep:ScriptLookupAttachment( "muzzle" )
		if iAttachment > -1 then

			local dt = wep:GetAttachmentForward( iAttachment ) * 128.0
			local org = m_HMDAvatar:GetOrigin()

			if IsBoxIntersectingRay( org + m_vecAvatarMins, org + m_vecAvatarMaxs, pos, dt ) then

				if wep:GetClassname() == "hlvr_weapon_rapidfire" then -- ???
					SendToConsole("kill")
				else
					local info = CreateDamageInfo( wep, m_hPlayer, dt, pos, 1.e+30, 2 )
					m_hPlayer:TakeDamage( info )
					DestroyDamageInfo( info )
				end

				print("bang")

			end

		end

	end

end, nil )

local Init = function()

	m_hPlayer = Entities:GetLocalPlayer()

	if m_hPlayer then

		m_HMDAvatar = m_hPlayer:GetHMDAvatar()

		if m_HMDAvatar then

			m_vecAvatarMins = m_HMDAvatar:GetBoundingMins()
			m_vecAvatarMaxs = m_HMDAvatar:GetBoundingMaxs()

			Msg("Loaded self_euthanasia\n")

			return true

		end

	end

	return false

end

local VS = require "vs_library-013"

if not VS.OnPlayerSpawn( Init, "self_euthanasia: could not find player" ) then
	Init()
end
