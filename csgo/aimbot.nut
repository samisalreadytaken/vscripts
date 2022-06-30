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
// or toggling wh
//		script aimbot_wh()
//
// remember to set your aspect ratio if you're using wh type 2
//		script aimbot_aspect_ratio( 4, 3 )
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
	const AIMBOT_DEFAULT_ASPECT_RATIO = 1.777778;	// 16/9

	local VEC_PLAYER_MINS = Vector( -16.5,-16.5, -0.5 );
	local VEC_PLAYER_MAXS = Vector(  16.5, 16.5, 72.5 );
	local VEC_DRAW_MINS = Vector( 0, -16, 0  );
	local VEC_DRAW_MAXS = Vector( 0,  16, 72 );
	local VEC_DRAW_TARGET_MINS = Vector();
	local VEC_DRAW_TARGET_MAXS = Vector();

	::__AIMBOT <-
	{
		m_hThink = null,
		m_Player1List = null,	// perpetrators
		m_Player2List = null,	// victims
		UseCallback = null,
		m_nWH = 0,				// enable wallhack for all perpetrators
								// 0: off
								// 1: local player only, draw position on screen
								// 2: display enemy position indicator on screen,
								// works on any server,
								// requires player screen aspect ratio,
								// is cut off on non-4/3 resolutions because game_text

		m_GameTextPool = null,

		// local player controls
		m_flAutoShootInterval = 4 * FrameTime(),
		m_nAutoShoot = 0,
		m_bAttacked = false,
		m_cachedTarget = null,

		m_flFrameTime = FrameTime()
	}

	function __AIMBOT::Init()
	{
		m_Player1List = [];
		m_Player2List = [];

		if ( !m_hThink )
			m_hThink = VS.CreateTimer( 0, 0.0, null, null, null, 1 ).weakref();

		VS.OnTimer( m_hThink, Think );
		EntFireByHandle( m_hThink, "Enable" );

		Msg("[][] aimbot script loaded\n")
	}

	// kill and stop everything
	function __AIMBOT::Kill()
	{
		Msg("Terminating...\n")

		if ( m_hThink && m_hThink.IsValid() )
			m_hThink.Destroy();

		if ( m_GameTextPool )
		{
			foreach ( v in m_GameTextPool )
			{
				if ( v && v.IsValid() )
					v.Destroy();
			}
		}

		::__AIMBOT = null;
	}

	//
	// Add player 1
	//

	function __AIMBOT::AddPlayer1ByName( i )
	{
		if ( typeof i != "string" )
			return Msg("[][AddPlayer1ByName] Invalid input\n");

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
			return Msg("[][AddPlayer1ByIndex] Invalid input\n");

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

			if ( !v.IsValid() )
				m_Player1List.remove(i);

			if ( v == p )
			{
				VS.SetInputCallback( v, "+use", null, AIMBOT_CONTEXT );

				if ( UseCallback )
				{
					VS.SetInputCallback( p, "+use", UseCallback, AIMBOT_CONTEXT );
					UseCallback = null;
				}

				return;
			}
		}

		if ( UseCallback )
		{
			VS.SetInputCallback( p, "+use", UseCallback, AIMBOT_CONTEXT );
			UseCallback = null;
		}

		// each player can have different settings
		p.m_ScriptScope.m_nAimlock <- 0;
		p.m_ScriptScope.m_nLockSpeedLevel <- 0;
		p.m_ScriptScope.m_flFov <- 0.0;
		p.m_ScriptScope.m_nAimTarget <- 0;
		p.m_ScriptScope.m_flAspectRatio <- AIMBOT_DEFAULT_ASPECT_RATIO;

		// used for screen space enemy indicators
		local hGameText;
		{
			if ( !m_GameTextPool )
				m_GameTextPool = [];

			for ( local i = m_GameTextPool.len(); i--; )
			{
				local v = m_GameTextPool[i];

				if ( !v || !v.IsValid() )
				{
					m_GameTextPool.remove(i);
					continue;
				}

				if ( !v.GetOwner() || v.GetOwner() == p.self )
				{
					hGameText = v;
					break;
				}
			}

			if ( !hGameText )
			{
				hGameText = VS.CreateEntity( "game_text",
				{
					channel = 5,
					color = Vector(255,0,0),
					holdtime = 0.125,
				}, true );

				hGameText.SetOwner( p.self );
			}
		}

		p.m_ScriptScope.m_hGameText <- hGameText.weakref();

		m_Player1List.append( p );
	}

	//
	// Remove player 1
	//

	function __AIMBOT::RemovePlayer1ByName( i )
	{
		if ( typeof i != "string" )
			return Msg("[][RemovePlayer1ByName] Invalid input\n");

		foreach( p in VS.GetAllPlayers() )
		{
			local t = p.GetScriptScope();
			if ( t && ("name" in t) && (t.name == i) )
			{
				return RemovePlayer1ByHandle( p );
			}
		}
		return Msg("[][RemovePlayer1ByName] could not find player by name\n");
	}

	function __AIMBOT::RemovePlayer1ByIndex( i )
	{
		if ( typeof i != "integer" )
			return Msg("[][RemovePlayer1ByIndex] Invalid input\n");

		local p = VS.GetPlayerByIndex(i);
		if ( !p )
			return Msg("[][RemovePlayer1ByIndex] Invalid player id\n");

		return RemovePlayer1ByHandle( p );
	}

	function __AIMBOT::RemovePlayer1ByHandle( p )
	{
		if ( !(p = ToExtendedPlayer(p)) )
			return Msg("[][RemovePlayer1ByHandle] Invalid player handle\n");

		for ( local i = m_Player1List.len(); i--; )
		{
			local v = m_Player1List[i];

			if ( !v.IsValid() )
				m_Player1List.remove(i);

			if ( v == p )
			{
				m_Player1List.remove(i);
				VS.SetInputCallback( v, "+use", null, AIMBOT_CONTEXT );
				return;
			}
		}
	}

	//
	// Add player 2
	//

	function __AIMBOT::AddPlayer2ByName( i )
	{
		if ( typeof i != "string" )
			return Msg("[][AddPlayer2ByName] Invalid input\n");

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
			return Msg("[][AddPlayer2ByIndex] Invalid input\n");

		local p = VS.GetPlayerByIndex(i);
		if ( !p )
			return Msg("[][AddPlayer2ByIndex] Invalid player id\n");

		return AddPlayer2ByHandle( p );
	}

	function __AIMBOT::AddPlayer2ByHandle( p )
	{
		if ( !(p = ToExtendedPlayer(p)) )
			return Msg("[][AddPlayer2ByHandle] Invalid player handle\n");

		for ( local i = m_Player2List.len(); i--; )
		{
			local v = m_Player2List[i];

			if ( !v.self.IsValid() )
				m_Player2List.remove(i);

			if ( v.self == p )
				return;
		}

		local hTarget = Target_t();
		hTarget.self = p;

		m_Player2List.append( hTarget );
	}

	//
	// Remove player 2
	//

	function __AIMBOT::RemovePlayer2ByName( i )
	{
		if ( typeof i != "string" )
			return Msg("[][RemovePlayer2ByName] Invalid input\n");

		foreach( p in VS.GetAllPlayers() )
		{
			local t = p.GetScriptScope();
			if ( t && ("name" in t) && (t.name == i) )
			{
				return RemovePlayer2ByHandle( p );
			}
		}
		return Msg("[][RemovePlayer2ByName] could not find player by name\n");
	}

	function __AIMBOT::RemovePlayer2ByIndex( i )
	{
		if ( typeof i != "integer" )
			return Msg("[][RemovePlayer2ByIndex] Invalid input\n");

		local p = VS.GetPlayerByIndex(i);
		if ( !p )
			return Msg("[][RemovePlayer2ByIndex] Invalid player id\n");

		return RemovePlayer2ByHandle( p );
	}

	function __AIMBOT::RemovePlayer2ByHandle( p )
	{
		if ( !(p = ToExtendedPlayer(p)) )
			return Msg("[][RemovePlayer2ByHandle] Invalid player handle\n");

		for ( local i = m_Player2List.len(); i--; )
		{
			local v = m_Player2List[i];

			if ( !v.self.IsValid() )
				m_Player2List.remove(i);

			if ( v.self == p )
			{
				m_Player2List.remove(i);
				return;
			}
		}
	}

	function __AIMBOT::ClearPlayers()
	{
		ClearPlayers1();
		ClearPlayers2();
	}

	function __AIMBOT::ClearPlayers1()
	{
		foreach( p in m_Player1List )
			VS.SetInputCallback( p, "+use", null, AIMBOT_CONTEXT );

		m_Player1List.clear();
	}

	function __AIMBOT::ClearPlayers2()
	{
		m_Player2List.clear();
	}

	function __AIMBOT::SetPlayerFov( player, deg )
	{
		if ( !( player = ToExtendedPlayer( player ) ) )
			return;

		deg = deg.tofloat();

		local sc = player.m_ScriptScope;

		if ( deg == 0.0 )
		{
			sc.m_flFov = 0.0;
		}
		else
		{
			sc.m_flFov = cos( deg * DEG2RAD );
		}

		Msg("[]["+player.m_EntityIndex+"] fov " + deg + " degrees\n");
	}

	function __AIMBOT::SetPlayerAimTarget( player, i = null )
	{
		if ( !( player = ToExtendedPlayer( player ) ) )
			return;

		local sc = player.m_ScriptScope;

		if ( i == null )
			i = !sc.m_nAimTarget;

		sc.m_nAimTarget = (!!i).tointeger();

		Msg("[]["+player.m_EntityIndex+"] aim target " + (sc.m_nAimTarget ? "body\n" : "head\n"));
	}

	function __AIMBOT::SetPlayerAimLock( player, i )
	{
		if ( !( player = ToExtendedPlayer( player ) ) )
			return;

		local sc = player.m_ScriptScope;

		sc.m_nAimlock = i.tointeger();

		Msg("[]["+player.m_EntityIndex+"] aimlock " + sc.m_nAimlock + "\n");
	}

	function __AIMBOT::SetPlayerLockSpeed( player, i )
	{
		if ( !( player = ToExtendedPlayer( player ) ) )
			return;

		local sc = player.m_ScriptScope;

		sc.m_nLockSpeedLevel = clamp( i.tointeger(), 0, 4 );

		Msg("[]["+player.m_EntityIndex+"] lock speed " + sc.m_nLockSpeedLevel + "\n");
	}

	function __AIMBOT::SetWallhack( i )
	{
		VS.EventQueue.CancelEventsByInput( __ValidateWallhack );

		// toggle listen server WH
		if ( i == null )
		{
			m_nWH = (!m_nWH).tointeger();
		}
		else if ( i > 2 || i < 0 )
		{
			return Msg("[][] invalid WH type\n");
		}
		else
		{
			m_nWH = i;
		}

		Msg("[][] Wallhack " + m_nWH + "\n");
	}

	function __AIMBOT::__ValidateWallhack( i )
	{
		// ::aimbot_wh was called on a non-listen server.

		// wants to be toggled
		if ( i == "null" )
		{
			switch ( m_nWH )
			{
				case 0:
					i = 2;
					break;
				case 1:
				case 2:
					i = 0;
					break;
			}
		}

		SetWallhack(i);
	}

	function __AIMBOT::SetPlayerAspectRatio( player, width, height )
	{
		if ( !( player = ToExtendedPlayer( player ) ) )
			return;

		player.m_ScriptScope.m_flAspectRatio = width.tofloat() / height.tofloat();

		Msg("[]["+player.m_EntityIndex+"] Set aspect ratio to " + width + " / " + height + "\n");
	}

	function __AIMBOT::SetAutoShoot( i = 0 )
	{
		if ( i > 2 || i < 0 )
			return Msg("[][] invalid auto shoot type\n");

		m_nAutoShoot = i;
		m_cachedTarget = [null,null];

		Msg("[][] Auto shoot " + m_nAutoShoot + "\n");
	}

	function __AIMBOT::AutoShootSpeed( flSpeed = 16.0 )
	{
		m_flAutoShootInterval = flSpeed * m_flFrameTime;

		Msg("[][] Auto shoot speed " + m_flAutoShootInterval + "\n");
	}

	function __AIMBOT::__OnAttackFrame()
	{
		local p1 = m_cachedTarget[0];
		local p2 = m_cachedTarget[1];

		local targetPos;

		if ( !p1.m_ScriptScope.m_nAimTarget )
		{
			local iAttachment = p2.LookupAttachment("facemask");
			targetPos = p2.GetAttachmentOrigin(iAttachment) - p2.EyeForward() * 4.0;
		}
		else
		{
			targetPos = p2.EyePosition();
			targetPos.z -= 16.0;
		}

		local targetDir = VS.ApproachVector( targetPos - p1.EyePosition(), p1.EyeForward(), 16.0 * m_flFrameTime );
		p1.SetForwardVector( targetDir );
	}

	local attack_out = [null, "-attack"];
	local attack_out2 = [null, "weapon_accuracy_nospread 0;weapon_recoil_scale 2.0;-attack"];

	function __AIMBOT::__AutoShootEnd()
	{
		m_bAttacked = false;
	}

	function __AIMBOT::Attack() : ( attack_out, attack_out2 )
	{
		m_bAttacked = true;

		// This causes large amounts of lag since a newer game update,
		// and makes the rage mode useless...
		if ( m_nAutoShoot == 2 )
		{
			SendToConsole("weapon_accuracy_nospread 1;weapon_recoil_scale 0.0;+attack;script __AIMBOT.__OnAttackFrame()");
			VS.EventQueue.AddEvent( SendToConsole, m_flFrameTime * 3, attack_out2 );
		}
		else
		{
			SendToConsole("+attack;script __AIMBOT.__OnAttackFrame()");
			VS.EventQueue.AddEvent( SendToConsole, m_flFrameTime * 3, attack_out );
		}

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
		if ( !b.self.IsValid() || b.self.GetHealth() <= 0 )
			return -1;

		if ( !a.self.IsValid() || a.self.GetHealth() <= 0 )
			return 1;

		if ( b.priority > a.priority )
			return 1;

		return -1;
	}

	//
	// TODO: memory to keep tracking after target goes invisible?
	//
	function __AIMBOT::Think()
		: ( ts, TargetSort, VEC_PLAYER_MINS, VEC_PLAYER_MAXS,
			VEC_DRAW_MINS, VEC_DRAW_MAXS,
			VEC_DRAW_TARGET_MINS, VEC_DRAW_TARGET_MAXS )
	{
		if ( !(0 in m_Player2List) )
			return;

		foreach( ply1 in m_Player1List )
		{
			if ( !ply1.IsValid() || ply1.GetHealth() <= 0 )
				continue;

			local ply1_ScriptScope = ply1.m_ScriptScope;

			local eyeAng = ply1.EyeAngles();
			local eyePos = ply1.EyePosition();
			local eyeFwd = ply1.EyeForward();
			local eyeRay = eyeFwd * MAX_TRACE_LENGTH;

			foreach( p in m_Player2List ) // Target_t
			{
				local ply2 = p.self; // CExtendedPlayer

				if ( !ply2.IsValid() || ply2.GetHealth() <= 0 )
					continue;

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
				}

				p.targetPos = targetPos;

				local vecDelta = targetPos - eyePos;
				local distToPlayer = vecDelta.Norm();

				p.dot = eyeFwd.Dot( vecDelta );

				local targetEyeDir = ply2.EyeForward();

				// am I in danger?
				local isLookingAtPlayer = VS.IsLookingAt( ply2.EyePosition(), eyePos, targetEyeDir, 0.984808 ); // 10 deg

				local isVisible = ( VS.TraceLine( eyePos, targetPos, ply1.self, MASK_NPCWORLDSTATIC ).fraction > 0.97 );

				VEC_PLAYER_MAXS.z = VEC_DRAW_MAXS.z = ply2.GetBoundingMaxs().z;

				// see if MASK_SOLID can pass instead (it can be blocked by player AABBs)
				if ( !isVisible )
				{
					local tr = VS.TraceLine( eyePos, targetPos, ply1.self, MASK_SOLID );
					local org = ply2.GetOrigin();
					isVisible = VS.IsPointInBox( tr.GetPos(), org + VEC_PLAYER_MINS, org + VEC_PLAYER_MAXS );
				}

				// is player aiming directly at the target?
				if ( isVisible &&
					VS.IntersectInfiniteRayWithSphere( eyePos, eyeRay, targetPos, p.targetRadius, ts ) &&
					(ts[0] > 0.0) )
				{
					local hitpos = eyePos + eyeRay * ts[0];
					p.shotPos = hitpos;
				}
				else
				{
					p.shotPos = null;
				}

				p.isVisible = isVisible;

				local distFactor = 1024. / distToPlayer;
				distFactor = VS.RemapValClamped( distFactor * distFactor, 0., 4096., 0., 100. )

				// rudimentary priority system
				p.priority =

					// player is looking directly at the target with a clear LOS.
					// it makes little sense to look away since we're already here.
					(!!p.shotPos).tofloat() * 75. +

					// visible targets have priority over invisible targets
					isVisible.tofloat() * 250. +

					p.dot * 100. +

					distFactor +

					// threat to the player
					(isVisible && isLookingAtPlayer).tofloat() * 25.;

				// listen server host only
				if ( m_nWH == 1 )
				{
					local drawAng = eyeAng * 1;
					drawAng.x = 0.0;

					if ( isVisible )
					{
						DebugDrawBoxAngles( ply2.GetOrigin(), VEC_DRAW_MINS, VEC_DRAW_MAXS, drawAng, 25,255,25,4, -1 );
						// Glow.Set( ply2.self, "10 255 10", 0, 4096.0 );
					}
					else
					{
						local v = ply2.GetOrigin();
						VS.DrawBoxAngles( v, VEC_DRAW_MINS, VEC_DRAW_MAXS, drawAng, 0,255,255,true, -1 );
						DebugDrawBoxAngles( v, VEC_DRAW_MINS, VEC_DRAW_MAXS, drawAng, 255,25,25,127, -1 );
						// Glow.Set( ply2.self, "255 10 10", 0, 4096.0 );
					}
				}
			}

			m_Player2List.sort( TargetSort );

			local hTarget = m_Player2List[0];

			if ( hTarget.self.IsValid() && hTarget.self.GetHealth() > 0 )
			{
				local targetPos = hTarget.targetPos;
				local targetRadius = hTarget.targetRadius;
				local hitpos = hTarget.shotPos;
				local bLock;

				if ( m_nWH == 1 )
				{
					// listen server host only
					VEC_DRAW_TARGET_MINS.y = VEC_DRAW_TARGET_MINS.z = 1.0-targetRadius;
					VEC_DRAW_TARGET_MAXS.y = VEC_DRAW_TARGET_MAXS.z = targetRadius-1.0;
					DebugDrawBoxAngles( targetPos, VEC_DRAW_TARGET_MINS, VEC_DRAW_TARGET_MAXS, eyeAng, 255,255,0,255, -1 );
				}
				else if ( m_nWH == 2 )
				{
					local targetPos = hTarget.self.EyePosition();

					local worldToScreen = VMatrix();
					VS.WorldToScreenMatrix(
						worldToScreen,
						eyePos,
						eyeFwd,
						ply1.EyeRight(),
						ply1.EyeUp(),
						VS.CalcFovX( ply1.GetFOV(), ply1_ScriptScope.m_flAspectRatio * 0.75 ),
						ply1_ScriptScope.m_flAspectRatio,
						8.0,
						MAX_COORD_FLOAT );

					local screen = VS.WorldToScreen( targetPos, worldToScreen );

					local x = screen.x;
					local y = screen.y;

					// Target is off screen
					if ( x < 0.0 || x > 1.0 || y < 0.0 || y > 1.0 || screen.z > 1.0 )
					{
						local vecDelta = targetPos - eyePos;
						local dist = vecDelta.Norm();

						local radius = VS.RemapValClamped( dist, 0.0, 768.0, 0.02, 0.3 );

						// NOTE: using EyeForward displays enemy position relative to player direction,
						// using EyeUp displays enemy position relative to player aim.
						local up = ply1.EyeForward(); up.z = 0.0;
						local right = ply1.EyeRight()

						local yy = -vecDelta.Dot( up );
						local xx = -vecDelta.Dot( right );

						local ang = atan2( xx, yy ) + PI;

						x = 0.5 + sin( ang ) * radius * 0.75;
						y = 0.5 - cos( ang ) * radius;

						local ch = "⬤"; // BLACK LARGE CIRCLE

						// Arrows don't look good
					/*
						ang *= RAD2DEG;

						if ( ang > 360.-15. || ang < 0.+15. )
							ch = "↑"				// N
						else if ( ang < 90.-15. )
							ch = "↗"				// NE
						else if ( ang < 90.+15. )
							ch = "→"				// E
						else if ( ang < 180.-15. )
							ch = "↘"				// SE
						else if ( ang < 180.+15. )
							ch = "↓"				// S
						else if ( ang < 270.-15. )
							ch = "↙"				// SW
						else if ( ang < 270.+15. )
							ch = "←"				// W
						else
							ch = "↖";				// NW
					*/
						ply1_ScriptScope.m_hGameText.__KeyValueFromString( "message", ch );

						x -= 0.005;
						y -= 0.0175;
					}
					// Target is on screen
					else
					{
						// Just show a down pointing triangle above enemy's head because
						// game_text is not reliable enough to show hit position.
						ply1_ScriptScope.m_hGameText.__KeyValueFromString( "message", "⮟" );

						x -= 0.005;
						y -= 0.05;
					}

					x = clamp( x, 0.0, 1.0 );
					y = clamp( y, 0.0, 1.0 );

					ply1_ScriptScope.m_hGameText.__KeyValueFromFloat( "x", x );
					ply1_ScriptScope.m_hGameText.__KeyValueFromFloat( "y", y );
					EntFireByHandle( ply1_ScriptScope.m_hGameText, "Display", "", 0.0, ply1.self );
				}

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
							frac = 18.0 * m_flFrameTime; // fast
							break;
						case 2:
							frac = 9.71 * m_flFrameTime;
							break;
						case 3:
							frac = 1.04 * m_flFrameTime;
							break;
						case 4:
							frac = 0.336 * m_flFrameTime; // slow
							break;
					}

					local targetDir = targetPos - eyePos;
					targetDir.Norm();

					targetDir = VS.ApproachVector( targetDir, eyeFwd, frac );

					ply1.SetForwardVector( targetDir );
				}

				if ( hitpos )
				{
					// listen server host only
					if ( m_nAutoShoot && !m_bAttacked )
					{
						// set player angles on the attacking frame,
						// otherwise the shots miss when angles change too fast
						m_cachedTarget[0] = ply1;
						m_cachedTarget[1] = hTarget.self;

						Attack();
					}
				}
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
			Msg("[]["+p.m_EntityIndex+"] Noclip enabled\n");
		}
		else
		{
			p.SetMoveType( 2 );
			p.SetEffects( 0 );
			Msg("[]["+p.m_EntityIndex+"] Noclip disabled\n");
		}
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

	// remove player 1 (perpetrator)
	::aimbot_remove_p1 <- function(i)
	{
		switch (typeof i)
		{
		case "integer":
			return RemovePlayer1ByIndex(i);
		case "string":
			return RemovePlayer1ByName(i);
		case "instance":
			return RemovePlayer1ByHandle(i);
		}
	}.bindenv(__AIMBOT)

	// remove player 2 (victim)
	::aimbot_remove_p2 <- function(i)
	{
		switch (typeof i)
		{
		case "integer":
			return RemovePlayer2ByIndex(i);
		case "string":
			return RemovePlayer2ByName(i);
		case "instance":
			return RemovePlayer2ByHandle(i);
		}
	}.bindenv(__AIMBOT)

	// set wh
	::aimbot_wh <- function(i="null")
	{
		SendToConsole("script __AIMBOT.SetWallhack(" + i + ")");
		VS.EventQueue.AddEvent( __ValidateWallhack, 0.5, [this, i]);
	}.bindenv(__AIMBOT)

	// set trigger (listen server host only)
	::aimbot_trigger <- function(i="null") { return SendToConsole("script __AIMBOT.SetAutoShoot(" + i + ")") }
	::aimbot_trigger_speed <- __AIMBOT.AutoShootSpeed.bindenv(__AIMBOT);

	// set lock FOV in degrees
	::aimbot_fov <- function( deg )
	{
		foreach ( p in m_Player1List )
			SetPlayerFov( p, deg );
	}.bindenv(__AIMBOT);

	// set aim target - 0:head, 1:body
	::aimbot_target <- function( i )
	{
		foreach ( p in m_Player1List )
			SetPlayerAimTarget( p, i );
	}.bindenv(__AIMBOT);

	// set aimlock
	::aimbot_lock <- function( i )
	{
		foreach ( p in m_Player1List )
			SetPlayerAimLock( p, i );
	}.bindenv(__AIMBOT);

	// set aimlock speed level [0,4]
	::aimbot_lock_speed <- function( i )
	{
		foreach ( p in m_Player1List )
			SetPlayerLockSpeed( p, i );
	}.bindenv(__AIMBOT);

	// input player resolution for target indicator calculations
	// Set the local player (index 1) aspect ratio to 4/3: aimbot_aspect_ratio( 1, 4, 3 )
	// Set aspect ratio of all players to 16/9: aimbot_aspect_ratio( 16, 9 )
	::aimbot_aspect_ratio <- function( i, w, h = null )
	{
		if ( h == null )
		{
			// set for all players
			h = w;
			w = i;
			foreach( v in m_Player1List )
			{
				SetPlayerAspectRatio( v, w, h );
			}
			return;
		}

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
			throw "::aimbot_aspect_ratio invalid player input";
		}

		if ( !p || !(p = ToExtendedPlayer(p)) )
			return;

		return SetPlayerAspectRatio( p, w, h );
	}.bindenv(__AIMBOT);

	//
	// example +use callbacks
	//

	::aimbot_use_toggle_lock <- function()
	{
		__AIMBOT.UseCallback = function(self)
		{
			if ( self.m_ScriptScope.m_nAimlock == 0 )
			{
				self.m_ScriptScope.m_nAimlock = 3;
			}
			else
			{
				self.m_ScriptScope.m_nAimlock = 0;
			}

			printl("\t\taim lock : " + self.m_ScriptScope.m_nAimlock);
		}
	}

	// only toggles listen server WH setting
	::aimbot_use_toggle_wh <- function()
	{
		__AIMBOT.UseCallback = function(self)
		{
			__AIMBOT.m_nWH = (!__AIMBOT.m_nWH).tointeger();

			printl("\t\twh : " + __AIMBOT.m_nWH);
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
// Wallhack type 2 adds a marker on top of the enemy player. This works on all servers,
// but requires player resolution aspect ratio. Set it using aimbot_aspect_ratio()
// Change these values in the presets.
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
	aimbot_trigger( 1 );
}

// lock and trigger low fov headshot
::aimbot_preset_assist <- function()
{
	aimbot_clear();
	aimbot_use_toggle_lock();
	aimbot_1vEnemy( 1 );
	aimbot_wh( 2 );
	aimbot_aspect_ratio( 16, 9 );
	aimbot_target( 0 );
	aimbot_fov( 2.0 );
	aimbot_lock( 3 );
	aimbot_lock_speed( 2 );
	aimbot_trigger( 0 );
}

// just trigger
::aimbot_preset_trigger <- function()
{
	aimbot_clear();
	aimbot_use_toggle_wh();
	aimbot_1vEnemy( 1 );
	aimbot_aspect_ratio( 16, 9 );
	aimbot_wh( 2 );
	aimbot_target( 0 );
	aimbot_lock( 0 );
	aimbot_trigger( 1 );
}

// instant lock on all targets
// Auto trigger is broken since a game update.
::aimbot_preset_rage <- function()
{
	aimbot_clear();
	aimbot_1vEnemy( 1 );
	aimbot_wh( 1 );
	aimbot_target( 0 );
	aimbot_fov( 0.0 );
	aimbot_lock( 1 );
	aimbot_lock_speed( 0 );
	// aimbot_trigger( 2 );
}
