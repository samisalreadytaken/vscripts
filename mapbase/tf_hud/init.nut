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

const TF2HUD_VERSION = 23111300;

// Automatically detect the subdirectory.
// Does not work if it was loaded with DoIncludeScript()
local TF2HUD_PATH = "tf_hud/";
local si = getstackinfos(3);
if ( si )
{
	foreach ( k, v in si.locals )
	{
		local i;
		if ( ( typeof v == "string" ) && ( ( i = v.find("init") ) != null ) )
		{
			TF2HUD_PATH = v.slice( 0, i );
			break;
		}
	}
}

local CONST = getconsttable();
CONST.TF2HUD_PATH <- TF2HUD_PATH;

local Init = function(...)
{
	if ( CLIENT_DLL )
		IncludeScript( TF2HUD_PATH + "fonts.nut" );

	if ( !("TFHud" in this) ) // Level transition (OnRestore)
		IncludeScript( TF2HUD_PATH + "hud_tf.nut" );

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
				// This is not well tested
				if ( "TFHud" in getroottable() )
				{
					local reload = 0;

					if ( "version" in TFHud )
					{
						// Save is more recent, don't reload
						if ( TFHud.version >= TF2HUD_VERSION )
							return;

						reload = 1;
					}
					else
					{
						if ( "StatusUpdate2" in TFHud ) // StatusUpdate2 was added in the same update as cs_hud_reload
						{
							reload = 1;
						}
						else
						{
							// Do nothing, the added complexity to reload this version is not worth it.
							print( "This save file includes an ancient version of TFHud. Not updating.\n" );
							return;
						}
					}

					if ( reload )
					{
						if ( "version" in TFHud )
						{
							printf( "Updating TFHud to %i (from %i)\n", TF2HUD_VERSION, TFHud.version );
						}
						else
						{
							printf( "Updating TFHud to %i\n", TF2HUD_VERSION );
						}

						// Wait for player to spawn
						Entities.First().SetContextThink( "TFHud.Load2", function(_)
						{
							SendToConsole( "tf_hud_reload" );
						}, 0.25 );
					}

					// Let client handle the reload
					return;
				}
				else
				{
					print( "This save file does not include TFHud, loading...\n" );
				}

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
