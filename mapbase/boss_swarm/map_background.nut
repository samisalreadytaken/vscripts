//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

local viewHeight = 512.0;
local viewPos = Vector( 0, 160, viewHeight );
local playerPos = Vector( 0, viewPos.y-210, 0 );
local playerAng = Vector( 90, 0, 0 );

if ( SERVER_DLL )
{
	PrecacheModel( "swarm/player2.vmt" );

	local pawn;

	local Init = function()
	{
		for ( local p; p = Entities.FindByName( p, ".shadow" ); )
		{
			p.SetRenderMode( 2 );
			p.SetRenderAlpha( 100 );
		}

		local view = Entities.CreateByClassname( "point_viewcontrol" );
		view.AddSpawnFlags( 8 | 128 );
		view.SetFov( 70, 0 );
		view.SetAbsAngles( Vector( 90, 90, 0 ) );
		view.SetAbsOrigin( viewPos );
		view.AcceptInput( "Enable", "", player, null );

		local logo = Entities.FindByName( null, "logo" );
		logo.SetSolid( 2 );
		logo.RemoveSolidFlags( FSOLID_NOT_SOLID );

		pawn = Entities.CreateByClassname( "env_sprite" );
		pawn.SetModel( "swarm/player2.vmt" );
		pawn.__KeyValueFromFloat( "scale", 0.15 );
		DispatchSpawn( pawn );
		pawn.SetLocalOrigin( playerPos );
		pawn.SetLocalAngles( playerAng );

		// block the view
		Entities.FindByName( null, ".aperture" ).SetLocalOrigin( viewPos - Vector( 0, 32, 8 ) );
	}

	// player_spawn on client fires while worldent is null..
	// Add artificial delay...
	ListenToGameEvent( "player_spawn", function( event )
	{
		Init();
		Entities.First().SetContextThink( "SwarmBG", function(_)
		{
			NetMsg.Start( "SwarmBG" );
				NetMsg.WriteEntity( pawn );
			NetMsg.Send( player, true );

			Entities.First().SetContextThink( "SwarmBG1", function(_)
			{
				StopListeningToAllGameEvents("SwarmBG");
			}, 0.0 );
		}, 0.5 );
	}, "SwarmBG" );

	NetMsg.Receive( "Swarm.EE", function( basePlayer )
	{
		local t = { rainbow = 1 }
		SaveTable( "Swarm.EE", t );
	} );

	NetMsg.Receive( "ClientCommand", function( basePlayer )
	{
		SendToConsole( NetMsg.ReadString() );
	} );
}

if ( CLIENT_DLL )
{
	IncludeScript( "boss_swarm/vs_math" );

	local m_flFadeStartTime = 0.0;
	local m_pAperture, m_pEntity;
	local m_flFadeFadeTime = 0.0;
	local m_bFadeIn = 0.0;
	local m_fnFadeCallback;
	local hover = false;
	local click = false;

	local function ApertureFadeThink(_)
	{
		local curtime = Time();
		local t = ( curtime - m_flFadeStartTime ) / m_flFadeFadeTime;

		if ( m_bFadeIn )
		{
			t = 1.0 - t;
			if ( t < 0.0 )
			{
				if ( m_fnFadeCallback )
				{
					m_fnFadeCallback();
					m_fnFadeCallback = null;
				}
				return -1;
			}
		}
		else
		{
			if ( t >= 1.0 )
			{
				m_pAperture.SetLocalOrigin( Vector(0,0,768) );
				if ( m_fnFadeCallback )
				{
					m_fnFadeCallback();
					m_fnFadeCallback = null;
				}
				return -1;
			}
		}

		local viewOrigin = CurrentViewOrigin();
		local pos = m_pEntity.GetLocalOrigin()
			.Subtract( viewOrigin ).Multiply( Bias( t, 0.2 ) ).Add( viewOrigin );
		m_pAperture.SetLocalOrigin( pos );
		return 0.0;
	}

	local function ApertureFade( dir, time, delay, callback )
	{
		m_flFadeStartTime = Time() + delay;
		m_flFadeFadeTime = time;
		m_bFadeIn = dir;
		m_fnFadeCallback = callback;

		if ( RandomFloat( 0.0, 1.0 ) < 0.1 )
		{
			m_pAperture = Entities.FindByName( null, ".aperture2" );
		}
		else
		{
			m_pAperture = Entities.FindByName( null, ".aperture" );
		}

		return Entities.First().SetContextThink( "Swarm.Fade", ApertureFadeThink, delay );
	}

	local function DoClick()
	{
		NetMsg.Start( "Swarm.EE" );
		NetMsg.Send();

		SendToConsole( "fadeout 1.5" );
		ApertureFade( false, 1.5, 0.0, function()
		{
			SendToConsole( "map boss_swarm_a" );
		} );
	}

	local function ClientThink(_)
	{
		local x = input.GetAnalogValue( AnalogCode.MOUSE_X );
		local y = input.GetAnalogValue( AnalogCode.MOUSE_Y );
		playerPos = m_pEntity.GetLocalOrigin();

		local ray = ScreenToRay( x, y );
		local t = VS.IntersectRayWithPlane( viewPos, ray, Vector(0,0,1), playerPos.z );
		ray.Multiply( t ).Add( viewPos );
		local dt = ray - playerPos;
		playerAng.y = VS.VecToYaw( dt );
		m_pEntity.SetLocalAngles( playerAng );

		if ( click )
		{
			local t = clock() * 16.0;
			local r = sin( t ) * 127 + 128;
			local g = sin( t + PI * 0.5 ) * 127 + 128;
			local b = sin( t + PI ) * 127 + 128;
			m_pEntity.SetRenderColor( r, g, b );
			return 0.0;
		}

		// GameTrace doesn't hit for whatever reason...
		local mouseover = VS.IsRayIntersectingSphere( viewPos, ray.Subtract( viewPos ), playerPos, 20.0, 0.0 );
		local mouseclick = input.IsButtonDown( ButtonCode.MOUSE_LEFT );

		if ( mouseover )
		{
			if ( !click && hover && mouseclick )
			{
				click = true;
				DoClick();
				return 0.0;
			}
			else if ( !hover && !mouseclick )
			{
				hover = true;
				local dir = playerPos - viewPos;
				dir.Norm();
				dir.Multiply( -96.0 );
				m_pEntity.SetLocalOrigin( playerPos + dir );
			}
			else if ( hover )
			{
				local t = clock() * 16.0;
				local r = sin( t ) * 127 + 128;
				local g = sin( t + PI * 0.5 ) * 127 + 128;
				local b = sin( t + PI ) * 127 + 128;
				m_pEntity.SetRenderColor( r, g, b );
			}
		}
		else if ( hover )
		{
			hover = false;
			local dir = playerPos - viewPos;
			dir.Norm();
			dir.Multiply( 96.0 );
			m_pEntity.SetLocalOrigin( playerPos + dir );
			m_pEntity.SetRenderColor( 255, 255, 255 );
		}

		return 0.0;
	}

	NetMsg.Receive( "SwarmBG", function()
	{
		m_pEntity = NetMsg.ReadEntity();

		// Net message can be received before entities have spawned.
		// The artifical delay on server tries to hack this away.
		if ( !Entities.First() )
			printf( "no world @%.4f [%d]\n", Time(), GetFrameCount() );

		ApertureFade( true, 2.0, 0.0, null );

		Entities.First().SetContextThink( "SwarmBG", ClientThink, 0.0 );
	} );

	function SendToConsole( str )
	{
		NetMsg.Start( "ClientCommand" );
			NetMsg.WriteString( str );
		return NetMsg.Send();
	}
}
