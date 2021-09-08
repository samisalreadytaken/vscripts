//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// The server host can execute the script without sv_cheats enabled.
//
// Persistent through rounds, needs to be executed only once.
//
// To install it, place 'aimbot.nut' and 'vs_library.nut' in /csgo/scripts/vscripts/
//
// It can be embedded in maps.
//
// Run it locally with 'script_execute aimbot'
//
// For example executing a preset:
//		script aimbot_preset_assist()
//
// or toggling wh for the local player
//		script aimbot_wh()
//
//
// Player adding functions can take player names if the map is configured correctly.
// Otherwise they take player indices.
//
//

IncludeScript("vs_library");


const MASK_NPCWORLDSTATIC = 0x2000b;;
const MASK_SOLID = 0x200400b;;

if ( !("__AIMBOT" in getroottable()) || !::__AIMBOT )
{
	const AIMBOT_CONTEXT = "ScriptAimbot";;
	const AIMBOT_DEFAULT_FIRE_INTERVAL = 0.0625;
	local VEC_PLAYER_MINS = Vector( -16.5,-16.5, -0.5 );
	local VEC_PLAYER_MAXS = Vector(  16.5, 16.5, 72.5 );
	local VEC_DRAW_MINS = Vector( 0, -16, 0  );
	local VEC_DRAW_MAXS = Vector( 0,  16, 72 );
	local VEC_DRAW_TARGET_MINS = Vector();
	local VEC_DRAW_TARGET_MAXS = Vector();
	local flCmdDelay = FrameTime() * 3;

	::__AIMBOT <-
	{
		m_hThink = null,
		m_Player1List = null,	// perpetrators
		m_Player2List = null,	// victims
		UseCallback = null,

		// local player controls
		m_bWH = false,
		m_bDrawTarget = false,
		m_flAutoShootInterval = AIMBOT_DEFAULT_FIRE_INTERVAL,
		m_bAutoShoot = false,
		m_bAttacked = false,
		m_cachedTarget = null
	}

	function __AIMBOT::Init()
	{
		m_Player1List = [];
		m_Player2List = [];

		if ( !m_hThink )
		{
			m_hThink = VS.CreateTimer( 0, 0.0, null, null, null, 1 ).weakref();
		};

		VS.OnTimer( m_hThink, Think );
		EntFireByHandle( m_hThink, "Enable" );

		Msg("[][] aimbot script loaded\n")
	}

	// kill and stop everything
	function __AIMBOT::Kill()
	{
		Msg("Terminating...\n")

		if ( m_hThink )
			m_hThink.Destroy();

		::__AIMBOT = null;
	}

	function __AIMBOT::AddPlayer1ByName( i )
	{
		if ( typeof i != "string" )
			return Msg("[][AddPlayer1ByName] Invalid value\n");

		foreach( p in VS.GetAllPlayers() )
		{
			local t = p.GetScriptScope();
			if ( t && ("name" in t) && (t.name == i) )
			{
				return AddPlayer1ByHandle( p );
			}
		}
		return Msg("[][AddPlayer1ByName] could not find player by name\n");
	}

	function __AIMBOT::AddPlayer1ByIndex( i )
	{
		if ( typeof i != "integer" )
			return Msg("[][AddPlayer1ByIndex] Invalid value\n");

		local p = VS.GetPlayerByIndex(i);
		if ( !p )
			return Msg("[][AddPlayer1ByIndex] Invalid player id\n");

		return AddPlayer1ByHandle( p );
	}

	function __AIMBOT::AddPlayer1ByHandle( p )
	{
		if ( !(p = ToExtendedPlayer(p)) )
			return Msg("[][AddPlayer1ByHandle] Invalid player handle\n");

		for ( local i = m_Player1List.len(); i--; )
		{
			local v = m_Player1List[i];

			if ( !v.IsValid() || v == p )
				m_Player1List.remove(i);

			v.SetInputCallback( "+use", null, AIMBOT_CONTEXT );
		}

		if ( UseCallback )
			p.SetInputCallback( "+use", UseCallback, AIMBOT_CONTEXT );
		UseCallback = null;

		// each player can have different settings
		p.m_ScriptScope.m_nAimlock <- false;
		p.m_ScriptScope.m_nLockSpeedLevel <- 0;
		p.m_ScriptScope.m_bLockSmooth <- false;
		p.m_ScriptScope.m_flFov <- 0.0;
		p.m_ScriptScope.m_nAimTarget <- 0;

		m_Player1List.append( p );

		return p;
	}

	function __AIMBOT::AddPlayer2ByName( i )
	{
		if ( typeof i != "string" )
			return Msg("[][AddPlayer2ByName] Invalid value\n");

		foreach( p in VS.GetAllPlayers() )
		{
			local t = p.GetScriptScope();
			if ( t && ("name" in t) && (t.name == i) )
			{
				return AddPlayer2ByHandle( p );
			}
		}
		return Msg("[][AddPlayer2ByName] could not find player by name\n");
	}

	function __AIMBOT::AddPlayer2ByIndex( i )
	{
		if ( typeof i != "integer" )
			return Msg("[][AddPlayer2ByIndex] Invalid value\n");

		local p = VS.GetPlayerByIndex(i);
		if ( !p )
			return Msg("[][AddPlayer2ByIndex] Invalid player id\n");

		return AddPlayer2ByHandle( p );
	}

	function __AIMBOT::AddPlayer2ByHandle( p )
	{
		if ( !(p = ToExtendedPlayer(p)) )
			return Msg("[][AddPlayer1ByHandle] Invalid player handle\n");

		for ( local i = m_Player2List.len(); i--; )
		{
			local v = m_Player2List[i];

			if ( !v.IsValid() )
				m_Player2List.remove(i);

			if ( v == p )
				return p;
		}

		m_Player2List.append( p );

		return p;
	}

	function __AIMBOT::ClearPlayers()
	{
		foreach( p in m_Player1List )
			p.SetInputCallback( "+use", null, AIMBOT_CONTEXT );

		m_Player1List.clear();
		m_Player2List.clear();
	}

	function __AIMBOT::SetFov( deg )
	{
		foreach ( p in m_Player1List )
		{
			local sc = p.m_ScriptScope;

			if ( deg == 0.0 )
			{
				sc.m_flFov = 0.0;
			}
			else
			{
				sc.m_flFov = cos( deg.tofloat() * DEG2RAD );
			};

			Msg("[]["+p.m_EntityIndex+"] fov " + deg.tofloat() + " degrees\n");
		}
	}

	function __AIMBOT::SetAimTarget( b = null )
	{
		foreach ( p in m_Player1List )
		{
			local sc = p.m_ScriptScope;

			if ( b == null )
				b = !sc.m_nAimTarget;

			sc.m_nAimTarget = !!b;

			Msg("[]["+p.m_EntityIndex+"] aim target " + (sc.m_nAimTarget ? "body\n" : "head\n"));
		}
	}

	function __AIMBOT::SetAimLock( i )
	{
		foreach ( p in m_Player1List )
		{
			local sc = p.m_ScriptScope;

			sc.m_nAimlock = clamp( i.tointeger(), 0, 3 );

			Msg("[]["+p.m_EntityIndex+"] aimlock " + sc.m_nAimlock + "\n");
		}
	}

	function __AIMBOT::SetLockSpeed( i )
	{
		foreach ( p in m_Player1List )
		{
			local sc = p.m_ScriptScope;

			sc.m_nLockSpeedLevel = clamp( i.tointeger(), 0, 4 );

			Msg("[]["+p.m_EntityIndex+"] lock speed " + sc.m_nLockSpeedLevel + "\n");
		}
	}

	function __AIMBOT::SetLockSmoothing( i )
	{
		foreach ( p in m_Player1List )
		{
			local sc = p.m_ScriptScope;

			sc.m_bLockSmooth = !!i;

			Msg("[]["+p.m_EntityIndex+"] lock smoothing " + sc.m_bLockSmooth + "\n");
		}
	}

	function __AIMBOT::SetWallhack( b = null )
	{
		if ( b == null )
			b = !m_bWH;

		m_bWH = !!b;
		m_bDrawTarget = m_bWH;

		Msg("[][] Wallhack " + (m_bWH ? "enabled\n" : "disabled\n"));
	}

	function __AIMBOT::SetAutoShoot( b = null )
	{
		if ( b == null )
			b = !m_bAutoShoot;

		m_bAutoShoot = !!b;
		m_cachedTarget = [null,null];

		Msg("[][] Auto shoot " + (m_bAutoShoot ? "enabled\n" : "disabled\n"));
	}

	function __AIMBOT::AutoShootSpeed()
	{
		local out;

		if ( m_flAutoShootInterval == AIMBOT_DEFAULT_FIRE_INTERVAL )
		{
			m_flAutoShootInterval = AIMBOT_DEFAULT_FIRE_INTERVAL + 0.25;
			out = "slower";
		}
		else
		{
			m_flAutoShootInterval = AIMBOT_DEFAULT_FIRE_INTERVAL;
			out = "faster";
		};

		Msg("[][] Shooting speed is now " + out + "\n");
	}

	function __AIMBOT::__OnAttackFrame()
	{
		local p1 = m_cachedTarget[0];
		local p2 = m_cachedTarget[1];

		local targetPos;

		if ( !p1.m_ScriptScope.m_nAimTarget )
		{
			local iAttachment = ply2.LookupAttachment("facemask");
			targetPos = p2.GetAttachmentOrigin(iAttachment) - p2.EyeForward() * 4.0;
		}
		else
		{
			targetPos = p2.EyePosition();
			targetPos.z -= 16.0;
		};

		local targetDir = VS.ApproachVector
		(
			targetPos - p1.EyePosition(),
			p1.EyeForward(),
			0.25
		);
		p1.SetForwardVector( targetDir );
	}

	local attack_out = [null, "weapon_accuracy_nospread 0;weapon_recoil_scale 2.0;-attack"];

	local __AutoShootEnd = function()
	{
		m_bAttacked = false;
	}

	function __AIMBOT::Attack() : ( flCmdDelay, attack_out, __AutoShootEnd )
	{
		m_bAttacked = true;
		SendToConsole("weapon_accuracy_nospread 1;weapon_recoil_scale 0.0;+attack;script __AIMBOT.__OnAttackFrame()");
		VS.EventQueue.AddEvent( SendToConsole, flCmdDelay, attack_out );
		VS.EventQueue.AddEvent( __AutoShootEnd, m_flAutoShootInterval, this );
	}

	local ts = [0.0, 0.0];

	class __AIMBOT.Target_t
	{
		self = null;
		dot = null;
		targetPos = null;
		targetRadius = null;
		shotPos = null;
		isVisible = null;
		priority = 0;
	}

	local TargetSort = function( a, b )
	{
		local pa = a.priority;
		local pb = b.priority;

		if ( pa < pb )
			return 1;
		if ( pa > pb )
			return -1;
		return 0;
	}


	// TODO: memory to keep tracking after target goes invisible?

	function __AIMBOT::Think()
		: ( ts, TargetSort, VEC_PLAYER_MINS, VEC_PLAYER_MAXS,
			VEC_DRAW_MINS, VEC_DRAW_MAXS,
			VEC_DRAW_TARGET_MINS, VEC_DRAW_TARGET_MAXS )
	{
		foreach( ply1 in m_Player1List )
		{
			if ( !ply1.GetHealth() )
				continue;

			local ply1_ScriptScope = ply1.m_ScriptScope;

			local eyeAng = ply1.EyeAngles();
			local eyePos = ply1.EyePosition();
			local eyeDir = ply1.EyeForward();
			local eyeRay = eyeDir * MAX_TRACE_LENGTH;

			local targets = [];

			foreach( ply2 in m_Player2List )
			{
				if ( !ply2.GetHealth() )
					continue;

				local p = Target_t();
				targets.append( p );
				p.self = ply2;

				local targetPos;

				if ( !ply1_ScriptScope.m_nAimTarget )
				{
					// Since it is not possible to get the position of the head bone of a player,
					// this script calculates 4 units backwards from the front of the face (facemask attachment)
					local iAttachment = ply2.LookupAttachment("facemask");
					targetPos = ply2.GetAttachmentOrigin(iAttachment) - ply2.EyeForward() * 4.0;
					p.targetRadius = 4.0;
				}
				else
				{
					targetPos = ply2.EyePosition();
					targetPos.z -= 16.0;
					p.targetRadius = 8.0;
				};

				p.targetPos = targetPos;

				local vecDelta = targetPos - eyePos;
				local distToPlayer = vecDelta.Norm();

				p.dot = eyeDir.Dot( vecDelta );

				local targetEyeDir = ply2.EyeForward();

				// am I in danger?
				local isLookingAtPlayer = VS.IsLookingAt( ply2.EyePosition(), eyePos, targetEyeDir, 0.89 );

				local isVisible = ( VS.TraceLine( eyePos, targetPos, ply1.self, MASK_NPCWORLDSTATIC ).fraction > 0.97 );

				VEC_PLAYER_MAXS.z = VEC_DRAW_MAXS.z = ply2.GetBoundingMaxs().z;

				// see if MASK_SOLID can pass instead (it can be blocked by player AABBs)
				if ( !isVisible )
				{
					local tr = VS.TraceLine( eyePos, targetPos, ply1.self, MASK_SOLID );
					local org = ply2.GetOrigin();
					isVisible = VS.IsPointInBox( tr.GetPos(), org + VEC_PLAYER_MINS, org + VEC_PLAYER_MAXS );
				};

				// is player aiming directly at the target?
				if ( isVisible &&
					VS.IntersectInfiniteRayWithSphere( eyePos, eyeRay, targetPos, p.targetRadius, ts ) &&
					(ts[0] > 0.0) )
				{
					local hitpos = eyePos + eyeRay * ts[0];
					p.shotPos = hitpos;
				};

				p.isVisible = isVisible;

				// rudimentary priority system
				if ( p.shotPos )
					p.priority += 100;

				if ( !p.dot || p.dot >= ply1_ScriptScope.m_flFov )
					p.priority += 100;

				if ( !isVisible )
					p.priority -= 8;

				if ( distToPlayer < 256.0 )
					p.priority += 5;

				if ( isLookingAtPlayer )
					p.priority += 4;

				// listen server host only
				if ( m_bWH )
				{
					local drawAng = eyeAng * 1;
					drawAng.x = 0.0;

					if ( isVisible )
					{
						DebugDrawBoxAngles( ply2.GetOrigin(), VEC_DRAW_MINS, VEC_DRAW_MAXS, drawAng, 25,255,25,4, -1 );
						// Glow.Set( ply2.self, COLOR_GREEN, 0, 4096.0 );
					}
					else
					{
						local v = ply2.GetOrigin();
						VS.DrawBoxAngles( v, VEC_DRAW_MINS, VEC_DRAW_MAXS, drawAng, 0,255,255,true, -1 );
						DebugDrawBoxAngles( v, VEC_DRAW_MINS, VEC_DRAW_MAXS, drawAng, 255,25,25,127, -1 );
						// Glow.Set( ply2.self, COLOR_RED, 0, 4096.0 );
					};
				};
			}

			if ( !(0 in targets) )
				continue;
			targets.sort( TargetSort );

			local hTarget = targets[0];
			if ( hTarget )
			{
				local targetPos = hTarget.targetPos;
				local targetRadius = hTarget.targetRadius;
				local hitpos = hTarget.shotPos;
				local bLock;
				// local distToCrosshair = 8.0 / (eyeRay * ( eyeRay.Dot( targetPos - eyePos ) / 3.22122e+9 )).Length();

				if ( m_bDrawTarget )
				{
					VEC_DRAW_TARGET_MINS.y = VEC_DRAW_TARGET_MINS.z = 1.0-targetRadius;
					VEC_DRAW_TARGET_MAXS.y = VEC_DRAW_TARGET_MAXS.z = targetRadius-1.0;
					DebugDrawBoxAngles( targetPos, VEC_DRAW_TARGET_MINS, VEC_DRAW_TARGET_MAXS, eyeAng, 255,255,0,255, -1 );
				};

				switch ( ply1_ScriptScope.m_nAimlock )
				{
					// if visible
					case 1:
						bLock = hTarget.isVisible;
						break;
					// if aiming at
					case 2:
						bLock = !hTarget.dot || hTarget.dot >= ply1_ScriptScope.m_flFov;
						break;
					// if visible and aiming at
					case 3:
						bLock = hTarget.isVisible && (!hTarget.dot || hTarget.dot >= ply1_ScriptScope.m_flFov);
						break;
				}

				if ( bLock )
				{
					local frac;

					switch ( ply1_ScriptScope.m_nLockSpeedLevel )
					{
						case 0:
							frac = 1.0;
							break;
						case 1:
							frac = 0.28125; // fast
							break;
						case 2:
							frac = 0.15125;
							break;
						case 3:
							frac = 0.01625;
							break;
						case 4:
							frac = 0.00525; // slow
							break;
					}

					local targetDir = targetPos - eyePos;
					targetDir.Norm();

					if ( ply1_ScriptScope.m_bLockSmooth )
						targetDir = VS.VectorLerp( eyeDir, targetDir, frac );
					else
						targetDir = VS.ApproachVector( targetDir, eyeDir, frac );

					ply1.SetForwardVector( targetDir );
				};

				if ( hitpos )
				{
					// listen server host only
					if ( m_bAutoShoot &&
						!m_bAttacked )
					{
						// set player angles on the attacking frame,
						// otherwise the shots miss when angles change too fast
						m_cachedTarget[0] = ply1;
						m_cachedTarget[1] = hTarget.self;

						Attack();
					};
				};
			}
		}
	}

	// =============================
	// =============================

	// toggle noclip on player
	::noclip <- function( i = 1 )
	{
		local p;
		switch (typeof i)
		{
		case "integer":
			p = VS.GetPlayerByIndex(i); break;
		case "string":
			foreach( v in VS.GetAllPlayers() )
			{
				local t = v.GetScriptScope();
				if ( t && ("name" in t) && (t.name == i) )
				{
					p = v;
					break;
				}
			}
			break;
		case "instance":
			p = i; break;
		default:
			throw "::noclip invalid input";
		}

		if ( !p || !(p = ToExtendedPlayer(p)) )
			return;

		if ( !p.IsNoclipping() )
		{
			p.SetMoveType( 8 );
			p.SetEffects( 32 ); // EF_NODRAW
			Msg("[][] Noclip enabled\n");
		}
		else
		{
			p.SetMoveType( 2 );
			p.SetEffects( 0 );
			Msg("[][] Noclip disabled\n");
		};
	}

	// 1 versus enemy team
	::aimbot_1vEnemy <- function( i = 1 )
	{
		ClearPlayers();
		local p1 = ::aimbot_add_p1(i);
		if ( !p1 )
			return Msg("no p1 found\n");

		local t1 = p1.GetTeam();
		local c = 0;

		foreach( p in VS.GetAllPlayers() )
		{
			local t2 = p.GetTeam();

			if ( (t2 == 2 || t2 == 3) && (t2 != t1) )
			{
				AddPlayer2ByHandle(p);
				c++;
			}
		}

		Msg("[][] 1v"+c + "\n");

	}.bindenv(__AIMBOT);

	// clear all players
	::aimbot_clear <- __AIMBOT.ClearPlayers.bindenv(__AIMBOT);

	// add player 1 (perpetrator)
	::aimbot_add_p1 <- function(i)
	{
		switch (typeof i)
		{
		case "integer":
			return AddPlayer1ByIndex(i);
		case "string":
			return AddPlayer1ByName(i);
		case "instance":
			return AddPlayer1ByHandle(i);
		}
	}.bindenv(__AIMBOT)

	// add player 2 (victim)
	::aimbot_add_p2 <- function(i)
	{
		switch (typeof i)
		{
		case "integer":
			return AddPlayer2ByIndex(i);
		case "string":
			return AddPlayer2ByName(i);
		case "instance":
			return AddPlayer2ByHandle(i);
		}
	}.bindenv(__AIMBOT)

	// set wh (listen server host only)
	::aimbot_wh <- function(i="null") { return SendToConsole("script __AIMBOT.SetWallhack(" + i + ")") }

	// set trigger (listen server host only)
	::aimbot_trigger <- function(i="null") { return SendToConsole("script __AIMBOT.SetAutoShoot(" + i + ")") }
	::aimbot_trigger_speed <- __AIMBOT.AutoShootSpeed.bindenv(__AIMBOT);

	// set lock FOV in degrees
	::aimbot_fov <- __AIMBOT.SetFov.bindenv(__AIMBOT);

	// set aim target - head / body
	::aimbot_target <- __AIMBOT.SetAimTarget.bindenv(__AIMBOT);

	// set aimlock
	::aimbot_lock <- __AIMBOT.SetAimLock.bindenv(__AIMBOT);

	// set aimlock speed level [0,4]
	::aimbot_lock_speed <- __AIMBOT.SetLockSpeed.bindenv(__AIMBOT);

	// set aimlock smoothing
	::aimbot_lock_smooth <- __AIMBOT.SetLockSmoothing.bindenv(__AIMBOT);

	//
	// example +use callbacks
	//

	::aimbot_use_toggle_lock <- function()
	{
		__AIMBOT.UseCallback = function(self)
		{
			if ( self.m_ScriptScope.m_nAimlock == 0 )
			{
				self.m_ScriptScope.m_nAimlock = 2;
			}
			else
			{
				self.m_ScriptScope.m_nAimlock = 0;
			};

			printl("\t\taim lock : " + self.m_ScriptScope.m_nAimlock);
		}
	}

	::aimbot_use_toggle_wh <- function()
	{
		__AIMBOT.UseCallback = function(self)
		{
			__AIMBOT.m_bWH = !__AIMBOT.m_bWH;
			__AIMBOT.m_bDrawTarget = __AIMBOT.m_bWH;

			printl("\t\twh : " + __AIMBOT.m_bWH);
		}
	}

	__AIMBOT.Init();
}

//
// Some preset templates below. It is best to change these to your liking and gameplay.
// Local player index is always 1.
//
// +use callbacks need to be set before adding each player.
//

// press USE key to feel the closest enemy
::aimbot_preset_wide_lock <- function()
{
	aimbot_clear();
	aimbot_use_toggle_lock();
	aimbot_1vEnemy( 1 );
	aimbot_wh( 0 );
	aimbot_target( 0 );
	aimbot_fov( 25.0 );
	aimbot_lock( 0 );
	aimbot_lock_speed( 3 );
	aimbot_lock_smooth( 0 );
	aimbot_trigger( 0 );
}

// body target, large fov, trigger, use toggles lock
::aimbot_preset_awp <- function()
{
	aimbot_clear();
	aimbot_use_toggle_lock();
	aimbot_1vEnemy( 1 );
	aimbot_wh( 1 );
	aimbot_target( 1 );
	aimbot_fov( 25.0 );
	aimbot_lock( 0 );
	aimbot_lock_speed( 1 );
	aimbot_lock_smooth( 1 );
	aimbot_trigger( 1 );
}

// lock and trigger low fov headshot
::aimbot_preset_assist <- function()
{
	aimbot_clear();
	aimbot_use_toggle_lock();
	aimbot_1vEnemy( 1 );
	aimbot_wh( 1 );
	aimbot_target( 0 );
	aimbot_fov( 2.0 );
	aimbot_lock( 2 );
	aimbot_lock_speed( 2 );
	aimbot_lock_smooth( 0 );
	aimbot_trigger( 1 );
}

// just trigger
::aimbot_preset_trigger <- function()
{
	aimbot_clear();
	aimbot_use_toggle_wh();
	aimbot_1vEnemy( 1 );
	aimbot_wh( 0 );
	aimbot_target( 0 );
	aimbot_lock( 0 );
	aimbot_trigger( 1 );
}

// instant lock and trigger on all targets
::aimbot_preset_rage <- function()
{
	aimbot_clear();
	aimbot_1vEnemy( 1 );
	aimbot_wh( 1 );
	aimbot_target( 0 );
	aimbot_fov( 0.0 );
	aimbot_lock( 1 );
	aimbot_lock_speed( 0 );
	aimbot_lock_smooth( 0 );
	aimbot_trigger( 1 );
}

