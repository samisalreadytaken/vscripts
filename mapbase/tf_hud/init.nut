//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Team Fortress 2 HUD
//
//		TFHud.SetPlayerClass( enum TFTEAM nTeam, enum TFPlayerClass nClass )
//		TFHud.SetBleeding( bool state )
//		TFHud.SetCrosshairVisible( bool state )
//		TFHud.SetCrosshairImage( string imageFile, string weaponClassname = null )
//
//-------------------------------------------------------------
// Resource files: [tf]
//		"resources/tf2.ttf"
//		"resources/tf2build.ttf"
//		tf/materials
//-------------------------------------------------------------


enum TFTEAM
{
	NONE,
	RED,
	BLUE
}

enum TFPlayerClass
{
	NONE,
	SCOUT,
	SOLDIER,
	PYRO,
	DEMOMAN,
	HEAVY,
	ENGINEER,
	MEDIC,
	SNIPER,
	SPY
}

local Init = function(...)
{
	if ( CLIENT_DLL )
		IncludeScript( "tf_hud/fonts.nut" );

	if ( !("TFHud" in this) ) // Level transition (OnRestore)
		IncludeScript( "tf_hud/hud_tf.nut" );

	if ( SERVER_DLL )
	{
		TFHud.Init( vargv[0] );
	}
	else // CLIENT_DLL
	{
		NetMsg.Receive( "TFHud.Load", null );
		TFHud.Init();
	}
}

ListenToGameEvent( "player_spawn", function( event )
{
	if ( SERVER_DLL )
	{
		Init( GetPlayerByUserID( event.userid ) );
	}
	else // CLIENT_DLL
	{
		Init();
		Entities.First().SetContextThink( "TFHud", function(_) { StopListeningToAllGameEvents( "TFHud" ); }, 0.01 );
	}
}, "TFHud" );

// Save/restore
{
	local InitRestore = function(...)
	{
		if ( SERVER_DLL )
		{
			Init( Entities.GetLocalPlayer() );
		}
		else // CLIENT_DLL
		{
			// Level transition hack
			Entities.First().SetContextThink( "TFHud", Init, 0.0 );
		}
	}

	Hooks.Add( this, "OnRestore", InitRestore, "TFHud" );

	// Handle loads on saves that were not saved with this HUD
	if ( SERVER_DLL )
	{
		local t = GetLoadType();
		if ( t == MapLoad.LoadGame || t == MapLoad.Transition )
		{
			Entities.First().SetContextThink( "TFHud.Load", function(_)
			{
				if ( "TFHud" in getroottable() )
					return;

				print( "This save file does not include TFHud, loading...\n" );

				Hooks.Add( this, "OnRestore", InitRestore, "TFHud" );

				local player = Entities.GetLocalPlayer();
				Init( player );
				NetMsg.Start( "TFHud.Load" );
				NetMsg.Send( player, true );
			}, 0.1 );
		}
	}
	else // CLIENT_DLL
	{
		// Hooks are reset on save restore because hook functions are stored in the VM.
		// NetMsg functions are not reset because they are stored in C++.
		// Hence the need to re-register the hook but not the net messages.
		NetMsg.Receive( "TFHud.Load", function()
		{
			Hooks.Add( this, "OnRestore", InitRestore, "TFHud" );
			Init();
		} );
	}
}

if ( !("GetPlayerByUserID" in this) )
{
	function GetPlayerByUserID(i)
	{
		for ( local p; p = Entities.FindByClassname( p, "player" ); )
			if ( p.GetUserID() == i )
				return p;
	}
}
