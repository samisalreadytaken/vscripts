//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Counter-Strike: Global Offensive Panorama HUD
//
//		CSHud.SetCrosshairVisible( bool state )
//		CSHud.SetCrosshairImage( string imageFile, string weaponClassname = null )
//
//		fx <- COverlayEffect( "effects/combine_binocoverlay" );
//		CSHud.AddEffect( fx )
//		CSHud.RemoveEffect( fx )
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

	CSHud.Init();
}

local InitRestore = function(...)
{
	if ( SERVER_DLL )
	{
		Init();
	}

	if ( CLIENT_DLL )
	{
		// Level transition hack
		Entities.First().SetContextThink( "CSHud", Init, 0.0 );
	}
}

ListenToGameEvent( "player_spawn", Init, "CSHud" );
Hooks.Add( this, "OnRestore", InitRestore, "CSHud" );
