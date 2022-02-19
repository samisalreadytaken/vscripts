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
//		fx <- COverlayEffect( "effects/combine_binocoverlay" );
//		TFHud.AddEffect( fx )
//		TFHud.RemoveEffect( fx )
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

	TFHud.Init();
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
		Entities.First().SetContextThink( "TFHud", Init, 0.0 );
	}
}

ListenToGameEvent( "player_spawn", Init, "TFHud" );
Hooks.Add( this, "OnRestore", InitRestore, "TFHud" );
