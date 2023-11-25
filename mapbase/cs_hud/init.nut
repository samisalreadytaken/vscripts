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
//		"materials/panorama/images/icons/ui/info" (32x32)
//		"materials/panorama/images/icons/ui/alert" (32x32)
//		"materials/panorama/images/masks/bottom-top-fade_additive"
//		"materials/panorama/images/hud/damageindicator/damage-segment_vert"
//		"materials/panorama/images/hud/damageindicator/damage-segment_horz"
//			"/damage-segment.png"
//		"materials/panorama/images/hud/reticle/crosshair"
//			"/crosshairpip2.png"
//			"/reticlecircle.png"
//		"materials/panorama/images/hud/reticle/reticlefriend_additive"
//-------------------------------------------------------------

const CSGOHUD_VERSION = 23120820;

// Automatically detect the subdirectory.
// Does not work if it was loaded with DoIncludeScript()
local CSGOHUD_PATH = "cs_hud/";
local si = getstackinfos(3);
if ( si )
{
	foreach ( k, v in si.locals )
	{
		local i;
		if ( ( typeof v == "string" ) && ( ( i = v.find("init") ) != null ) )
		{
			CSGOHUD_PATH = v.slice( 0, i );
			break;
		}
	}
}

const FLT_MAX			= 3.402823466e+38;
const PI				= 3.141592654;

local CONST = getconsttable();
CONST.CSGOHUD_PATH <- CSGOHUD_PATH;

if ( !( "vec3_invalid" in CONST ) )
{
	CONST.vec3_invalid <- Vector( FLT_MAX, FLT_MAX, FLT_MAX );
}

if ( !( "CSGOHUD_DMG_BITS" in CONST ) )
{
	const HIDEHUD_WEAPONSELECTION		= 1;		// Hide ammo count & weapon selection
	const HIDEHUD_FLASHLIGHT			= 2;
	const HIDEHUD_ALL					= 4;
	const HIDEHUD_HEALTH				= 8;		// Hide health & armor / suit battery
	const HIDEHUD_PLAYERDEAD			= 16;	// Hide when local player's dead
	const HIDEHUD_NEEDSUIT				= 32;	// Hide when the local player doesn't have the HEV suit
	const HIDEHUD_MISCSTATUS			= 64;	// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
	const HIDEHUD_CHAT					= 128;	// Hide all communication elements (saytext, voice icon, etc)
	const HIDEHUD_CROSSHAIR				= 256;	// Hide crosshairs
	const HIDEHUD_VEHICLE_CROSSHAIR		= 512;	// Hide vehicle crosshair
	const HIDEHUD_INVEHICLE				= 1024;
	const HIDEHUD_BONUS_PROGRESS		= 2048;

	CONST.CSGOHUD_HIDEHUD_CROSSHAIR <- ( HIDEHUD_ALL | HIDEHUD_PLAYERDEAD | HIDEHUD_CROSSHAIR | HIDEHUD_VEHICLE_CROSSHAIR );
	CONST.CSGOHUD_HIDEHUD_AMMO <- ( HIDEHUD_ALL | HIDEHUD_PLAYERDEAD | HIDEHUD_HEALTH | HIDEHUD_WEAPONSELECTION | HIDEHUD_NEEDSUIT );
	CONST.CSGOHUD_HIDEHUD_WEPSELECTION <- ( HIDEHUD_ALL | HIDEHUD_PLAYERDEAD | HIDEHUD_WEAPONSELECTION | HIDEHUD_NEEDSUIT | HIDEHUD_INVEHICLE );
	CONST.CSGOHUD_HIDEHUD_HEALTH <- ( HIDEHUD_ALL | HIDEHUD_PLAYERDEAD | HIDEHUD_HEALTH | HIDEHUD_NEEDSUIT );

	CONST.CSGOHUD_DMG_BITS <- ( DMG_CLUB | DMG_BULLET | DMG_BLAST | DMG_POISON | DMG_ACID | DMG_DROWN | DMG_BURN | DMG_SLOWBURN | DMG_NERVEGAS | DMG_RADIATION | DMG_SHOCK | DMG_SLASH );
	CONST.CSGOHUD_DMG_NO_ORIGIN <- ( DMG_POISON | DMG_ACID | DMG_DROWN | DMG_SLOWBURN | DMG_NERVEGAS | DMG_RADIATION );
	CONST.CSGOHUD_DMG_SCR_FX <- ( DMG_POISON | DMG_BURN | DMG_RADIATION );

	CONST.PROP_DRIVABLE_APC_CLASSNAME <- IsWindows() ? "class C_PropDrivableAPC" : "17C_PropDrivableAPC";
	CONST.PROP_AIRBOAT_CLASSNAME <- IsWindows() ? "class C_PropAirboat" : "13C_PropAirboat";
}

local Init = function(...)
{
	if ( CLIENT_DLL )
		IncludeScript( CSGOHUD_PATH + "fonts.nut" );

	if ( !("CSHud" in this) ) // Level transition (OnRestore)
		IncludeScript( CSGOHUD_PATH + "hud_cs.nut" );

	if ( SERVER_DLL )
	{
		CSHud.Init( vargv[0] );
	}
	else // CLIENT_DLL
	{
		NetMsg.Receive( "CSGOHud.Load", null );
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
		Entities.First().SetContextThink( "CSGOHud", function(_) { StopListeningToAllGameEvents( "CSGOHud" ); }, 0.01 );
	}
}, "CSGOHud" );

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
			Entities.First().SetContextThink( "CSGOHud", Init, 0.0 );
		}
	}

	Hooks.Add( this, "OnRestore", InitRestore, "CSGOHud" );

	// Handle loads on saves that were not saved with this HUD
	if ( SERVER_DLL )
	{
		local t = GetLoadType();
		if ( t == MapLoad.LoadGame || t == MapLoad.Transition )
		{
			Entities.First().SetContextThink( "CSGOHud.Load", function(_)
			{
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
							print( "This save file includes an ancient version of CSGOHud. Not updating.\n" );
							return;
						}
					}

					if ( reload )
					{
						if ( "version" in CSHud )
						{
							printf( "Updating CSGOHud to %i (from %i)\n", CSGOHUD_VERSION, CSHud.version );
						}
						else
						{
							printf( "Updating CSGOHud to %i\n", CSGOHUD_VERSION );
						}

						// Wait for player to spawn
						Entities.First().SetContextThink( "CSGOHud.Load2", function(_)
						{
							SendToConsole( "cs_hud_reload" );
						}, 0.25 );
					}

					// Let client handle the reload
					return;
				}
				else
				{
					print( "This save file does not include CSGOHud, loading...\n" );
				}

				Hooks.Add( this, "OnRestore", InitRestore, "CSGOHud" );

				local player = Entities.GetLocalPlayer();
				Init( player );
				NetMsg.Start( "CSGOHud.Load" );
				NetMsg.Send( player, true );
			}, 0.1 );
		}
	}
	else // CLIENT_DLL
	{
		// Hooks are reset on save restore because hook functions are stored in the VM.
		// NetMsg functions are not reset because they are stored in C++.
		// Hence the need to re-register the hook but not the net messages.
		NetMsg.Receive( "CSGOHud.Load", function()
		{
			Hooks.Add( this, "OnRestore", InitRestore, "CSGOHud" );
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

CSGOHud_Init <- Init;
