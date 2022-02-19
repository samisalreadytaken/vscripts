//
// Hud visibility manager
//
//		SetHUDHiddenBits( i )
//		ClearHUDHiddenBits( i )
//		GetHUDHiddenBits()
//

const HIDEHUD_WEAPONSELECTION		= 1		// Hide ammo count & weapon selection
const HIDEHUD_FLASHLIGHT			= 2
const HIDEHUD_ALL					= 4
const HIDEHUD_HEALTH				= 8		// Hide health & armor / suit battery
const HIDEHUD_PLAYERDEAD			= 16	// Hide when local player's dead
const HIDEHUD_NEEDSUIT				= 32	// Hide when the local player doesn't have the HEV suit
const HIDEHUD_MISCSTATUS			= 64	// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
const HIDEHUD_CHAT					= 128	// Hide all communication elements (saytext, voice icon, etc)
const HIDEHUD_CROSSHAIR				= 256	// Hide crosshairs
const HIDEHUD_VEHICLE_CROSSHAIR		= 512	// Hide vehicle crosshair
const HIDEHUD_INVEHICLE				= 1024
const HIDEHUD_BONUS_PROGRESS		= 2048

if ( CLIENT_DLL )
{
	local Convars = Convars;
	local m_iHideHud = 0;

	function SetHUDHiddenBits( i )
	{
		return Convars.SetInt( "hidehud", m_iHideHud = m_iHideHud | i );
	}

	function ClearHUDHiddenBits( i )
	{
		return Convars.SetInt( "hidehud", m_iHideHud = m_iHideHud & (~i) );
	}

	function GetHUDHiddenBits()
	{
		return m_iHideHud;
	}

	local Init = function(...)
	{
		Hooks.Add( Entities.GetLocalPlayer().GetOrCreatePrivateScriptScope(),
			"UpdateOnRemove",
			function() { return ClearHUDHiddenBits(-1) },
			"hud_override" );
	}
	ListenToGameEvent( "player_spawn", Init, "hud_override" );
	Hooks.Add( this, "OnRestore", Init, "hud_override" );
}
