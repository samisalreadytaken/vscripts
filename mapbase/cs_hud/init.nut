//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Counter-Strike: Global Offensive Panorama HUD
//
//-------------------------------------------------------------
// Resource files: [csgo]
//		"resources/stratum2bold.ttf"
//		"sound/ui/weapon/zoom.wav"
//		"materials/overlays/scope_lens"
//		"materials/sprites/scope_arc"
//		"materials/panorama/images/icons/ui/health" (32x32)
//		"materials/panorama/images/icons/ui/shield" (32x32)
//		"materials/panorama/images/hud/reticle/crosshair"
//			"/crosshairpip2.png"
//			"/reticlecircle.png"
//-------------------------------------------------------------

const CSGOHUD_VERSION = 23111300;

local Init = function(...)
{
	if ( CLIENT_DLL )
		IncludeScript( "cs_hud/fonts.nut" );

	if ( !("CSHud" in this) ) // Level transition (OnRestore)
		IncludeScript( "cs_hud/hud_cs.nut" );

	if ( SERVER_DLL )
	{
		CSHud.Init( vargv[0] );
	}
	else // CLIENT_DLL
	{
		NetMsg.Receive( "CSHud.Load", null );
		CSHud.Init();
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
		Entities.First().SetContextThink( "CSHud", function(_) { StopListeningToAllGameEvents( "CSHud" ); }, 0.01 );
	}
}, "CSHud" );

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
			Entities.First().SetContextThink( "CSHud", Init, 0.0 );
		}
	}

	Hooks.Add( this, "OnRestore", InitRestore, "CSHud" );

	// Handle loads on saves that were not saved with this HUD
	if ( SERVER_DLL )
	{
		local t = GetLoadType();
		if ( t == MapLoad.LoadGame || t == MapLoad.Transition )
		{
			Entities.First().SetContextThink( "CSHud.Load", function(_)
			{
				local player = Entities.GetLocalPlayer();

				// This is not well tested
				if ( "CSHud" in getroottable() )
				{
					local reload = 0;

					if ( "version" in CSHud )
					{
						// Save is more recent, don't reload
						if ( CSHud.version >= CSGOHUD_VERSION )
							return;

						reload = 1;
					}
					else
					{
						if ( "StatusUpdate2" in CSHud ) // StatusUpdate2 was added in the same update as cs_hud_reload
						{
							reload = 1;
						}
						else
						{
							// Do nothing, the added complexity to reload this version is not worth it.
							print( "This save file includes an ancient version of CSHud. Not updating.\n" );
							return;
						}
					}

					if ( reload )
					{
						if ( "version" in CSHud )
						{
							printf( "Updating CSHud to %i (from %i)\n", CSGOHUD_VERSION, CSHud.version );
						}
						else
						{
							printf( "Updating CSHud to %i\n", CSGOHUD_VERSION );
						}

						// Wait for player to spawn
						Entities.First().SetContextThink( "CSHud.Load2", function(_)
						{
							SendToConsole( "cs_hud_reload" );
						}, 0.25 );
					}

					// Let client handle the reload
					return;
				}
				else
				{
					print( "This save file does not include CSHud, loading...\n" );
				}

				Hooks.Add( this, "OnRestore", InitRestore, "CSHud" );

				Init( player );
				NetMsg.Start( "CSHud.Load" );
				NetMsg.Send( player, true );
			}, 0.1 );
		}
	}
	else // CLIENT_DLL
	{
		// Hooks are reset on save restore because hook functions are stored in the VM.
		// NetMsg functions are not reset because they are stored in C++.
		// Hence the need to re-register the hook but not the net messages.
		NetMsg.Receive( "CSHud.Load", function()
		{
			Hooks.Add( this, "OnRestore", InitRestore, "CSHud" );
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
