//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Counter-Strike: Global Offensive Panorama HUD
//
//		CSHud.SetCrosshairVisible( bool state )
//		CSHud.SetCrosshairImage( string imageFile, string weaponClassname = null )
//
//-------------------------------------------------------------
// Resource files: [csgo]
//		"resources/stratum2bold.ttf"
//		"sound/ui/weapon/zoom.wav"
//		"materials/overlays/scope_lens"
//		"materials/sprites/scope_arc"
//		"materials/panorama/images/hud/reticle/crosshair"
//			"/crosshairpip2.png"
//			"/reticlecircle.png"
//-------------------------------------------------------------


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
	else
	{
		CSHud.Init();
	}
}

local InitRestore = function(...)
{
	if ( SERVER_DLL )
	{
		Init( Entities.GetLocalPlayer() );
	}

	if ( CLIENT_DLL )
	{
		// Level transition hack
		Entities.First().SetContextThink( "CSHud", Init, 0.0 );
	}
}

ListenToGameEvent( "player_spawn", function( event )
{
	if ( SERVER_DLL )
	{
		Init( GetPlayerByUserID( event.userid ) );
	}
	else
	{
		Init();
		Entities.First().SetContextThink( "CSHud", function(_) { StopListeningToAllGameEvents( "CSHud" ); }, 0.01 );
	}
}, "CSHud" );

Hooks.Add( this, "OnRestore", InitRestore, "CSHud" );



if ( !("GetPlayerByUserID" in this) )
{
	function GetPlayerByUserID(i)
	{
		for ( local p; p = Entities.FindByClassname( p, "player" ); )
			if ( p.GetUserID() == i )
				return p;
	}
}
