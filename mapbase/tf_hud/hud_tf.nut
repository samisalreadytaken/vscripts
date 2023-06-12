//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//

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


if ( SERVER_DLL )
{
	TFHud <- {}

	function TFHud::Init( player )
	{
		if ( !player )
			return;

		player.SetContextThink( "TFHud.StatusUpdate", StatusUpdate, 0.0 );

		NetMsg.Receive( "TFHud.Reload", function( player )
		{
			print("SV: Reloading tf_hud...\n");

			player.SetContextThink( "TFHud.StatusUpdate", null, 0.0 );
			delete ::TFHud;

			IncludeScript( "tf_hud/hud_tf.nut" );
			::TFHud.Init( player );
		} );
	}

	function TFHud::StatusUpdate( player )
	{
		local suit = player.IsSuitEquipped();

		NetMsg.Start( "TFHud.StatusUpdate" );
			NetMsg.WriteShort( player.GetArmor() );
			NetMsg.WriteBool( suit );
			if ( suit )
			{
				NetMsg.WriteFloat( player.GetFlashlightBattery() * 0.01 );
				NetMsg.WriteFloat( player.GetAuxPower() * 0.01 );
			}
		NetMsg.Send( player, false );

		return 0.1;
	}
}


if ( CLIENT_DLL )
{
	local XRES = XRES, YRES = YRES;

	TFHud <-
	{
		m_bVisible = true

		m_pPlayerStatus = null
		m_pPlayerClass = null
		m_pPlayerHealth = null
		m_pWeaponAmmo = null
		m_pWeaponSelection = null
		m_pFlashlight = null
		m_pSuitPower = null
		m_pScope = null

		m_nPlayerTeam = TFTEAM.RED
		m_nPlayerClass = TFPlayerClass.ENGINEER

		m_hAnim = null
		m_hCrosshair = null
		m_Crosshairs = null
	}

	IncludeScript( "tf_hud/hud_tf_playerstatus.nut", TFHud );
	IncludeScript( "tf_hud/hud_tf_playerclass.nut", TFHud );
	IncludeScript( "tf_hud/hud_tf_health.nut", TFHud );
	IncludeScript( "tf_hud/hud_tf_ammo.nut", TFHud );
	IncludeScript( "tf_hud/hud_tf_weaponselection.nut", TFHud );
	IncludeScript( "tf_hud/hud_tf_flashlight.nut", TFHud );
	IncludeScript( "tf_hud/hud_tf_suitpower.nut", TFHud );
	IncludeScript( "tf_hud/hud_tf_scope.nut", TFHud );
/*
	//
	// Fullscreen overlay effect drawn over the HUD.
	// NOTE: Refract materials will override HUD render.
	//
	//		fx <- COverlayEffect( "effects/combine_binocoverlay" );
	//		TFHud.AddEffect( fx )
	//		TFHud.RemoveEffect( fx )
	//
	class COverlayEffect
	{
		m_iTexture = -1;

		constructor( img )
		{
			m_iTexture = surface.ValidateTexture( img, true );
		}

		function Render()
		{
			surface.SetColor( 255, 255, 255, 255 );
			surface.SetTexture( m_iTexture );
			surface.DrawTexturedRect( 0, 0, XRES(640), YRES(480) );
		}
	}

	function TFHud::AddEffect( effect )
	{
		if ( "Render" in effect )
		{
			if ( !m_Effects )
				m_Effects = [];

			m_Effects.append( effect );
			self.SetPostChildPaintEnabled( true );
		}
	}

	function TFHud::RemoveEffect( effect )
	{
		if ( m_Effects )
		{
			local i = m_Effects.find( effect );
			if ( i != null )
			{
				m_Effects.remove(i);
				if ( !m_Effects.len() )
					self.SetPostChildPaintEnabled( false );
			}
		}
	}

	function TFHud::RenderPanelEffects()
	{
		foreach( effect in m_Effects )
		{
			effect.Render();
		}
	}
*/
	function TFHud::GetRootPanel()
	{
		if ( !("GetHudViewport" in vgui) )
			return vgui.GetClientDLLRootPanel();
		return vgui.GetHudViewport();
	}

	function TFHud::SetVisible( state )
	{
		m_bVisible = state;

		local istate = !state;

		SetHudElementVisible( "CHUDQuickInfo", istate );
		SetHudElementVisible( "CHudWeaponSelection", istate );
		SetHudElementVisible( "CHudSuitPower", istate );
		SetHudElementVisible( "CHudHealth", istate );
		SetHudElementVisible( "CHudFlashlight", istate );
		SetHudElementVisible( "CHudBattery", istate );
		SetHudElementVisible( "CHudAmmo", istate );
		SetHudElementVisible( "CHudSecondaryAmmo", istate );
		SetHudElementVisible( "CHudWeapon", istate );
		SetHudElementVisible( "CHudCrosshair", istate );
		SetHudElementVisible( "CHudVehicle", istate );

		if ( state )
		{
			NetMsg.Receive( "TFHud.StatusUpdate", StatusUpdate.bindenv(this) );

			m_pWeaponSelection.RegisterCommands();
			m_pScope.RegisterCommands();

			m_pWeaponAmmo.AddTickSignal();

			local player = Entities.GetLocalPlayer();
			if ( player )
			{
				local weapon = player.GetActiveWeapon();
				if ( weapon )
					OnSelectWeapon( weapon );
			}
		}
		else
		{
			NetMsg.Receive( "TFHud.StatusUpdate", dummy );

			m_pWeaponSelection.UnregisterCommands();
			m_pScope.UnregisterCommands();

			m_pWeaponAmmo.RemoveTickSignal();

			m_pPlayerStatus.self.SetVisible( false );
			m_pWeaponAmmo.self.SetVisible( false );
			m_pWeaponAmmo.m_hSecondaryBG.SetVisible( false );
			m_pWeaponSelection.self.SetVisible( false );
			m_pFlashlight.self.SetVisible( false );
			m_pSuitPower.self.SetVisible( false );
			m_pScope.self.SetVisible( false );
			m_pScope.m_bVisible = false;
			m_hCrosshair.SetVisible( false );
		}

		SetPlayerClass( m_nPlayerTeam, m_nPlayerClass, 1 );
	}

	function TFHud::Init()
	{
		if ( m_pPlayerHealth && (typeof m_pPlayerHealth.self == "instance") ) // for saverestore bug

		if ( m_pPlayerHealth && m_pPlayerHealth.self && m_pPlayerHealth.self.IsValid() )
			return;

			m_pPlayerStatus = CTFHudPlayerStatus();
			m_pPlayerClass = CTFHudPlayerClass();
			m_pPlayerHealth = CTFHudPlayerHealth();
			m_pWeaponAmmo = CTFHudWeaponAmmo();
			m_pWeaponSelection = CTFHudWeaponSelection();
			m_pFlashlight = CTFHudFlashlight();
			m_pSuitPower = CTFHudSuitPower();
			m_pScope = CTFHudScope();

		m_pPlayerStatus.Init();
		m_pPlayerClass.Init();
		m_pPlayerHealth.Init();
		m_pWeaponAmmo.Init();
		m_pWeaponSelection.Init();
		m_pFlashlight.Init();
		m_pSuitPower.Init();
		m_pScope.Init();

		m_pPlayerHealth.m_flMaxHealth = 100.0;
		m_pPlayerHealth.m_nHealthWarningThreshold = 39;
		m_pPlayerHealth.m_bBleeding = false;

		m_hAnim = vgui.CreatePanel( "Panel", GetRootPanel(), "TFHudAnim" );
		m_hAnim.SetPaintEnabled( false );
		m_hAnim.SetPaintBackgroundEnabled( false );
		m_hAnim.SetCallback( "OnTick", AnimThink.bindenv(this) );
		m_hAnim.AddTickSignal( 25 );

		m_hCrosshair = vgui.CreatePanel( "ImagePanel", GetRootPanel(), "TFHudCrosshair" );
		m_hCrosshair.SetZPos( 1 );
		m_hCrosshair.SetVisible( true );
		m_hCrosshair.SetShouldScaleImage( true );
		m_hCrosshair.SetImage( "vgui/crosshairs/crosshair5", true );

		SetVisible( m_bVisible );

		Convars.RegisterCommand( "tf_hud_reload", Reload, "", 0 );

		// mapbase 7.1 hack, ignore
		if ( !("GetHudViewport" in vgui) )
			vgui.CreatePanel( "Panel", vgui.GetRootPanel(), "" ).Destroy();
	}

	// Purge and reload the HUD
	// To keep forward compatibility, this should always clean itself,
	// then run `hud_tf.nut` and `TFHud.Init()`
	//
	// BUGBUG: Overridden concommands stop working when TFHud.Reload() is called on some saves.
	// Saving and loading the game again in this state is fine.
	// TODO: After fixing this, auto-update the HUD on save files by comparing versions.
	function TFHud::Reload(...)
	{
		print("CL: Reloading tf_hud...\n");

		::TFHud.SetVisible( false );

		::TFHud.m_pPlayerStatus.self.Destroy();
		::TFHud.m_pWeaponAmmo.self.Destroy();
		::TFHud.m_pWeaponSelection.self.Destroy();
		::TFHud.m_pFlashlight.self.Destroy();
		::TFHud.m_pSuitPower.self.Destroy();
		::TFHud.m_pScope.self.Destroy();

		::TFHud.m_hAnim.Destroy();
		::TFHud.m_hCrosshair.Destroy();

		delete ::TFHud;

		Entities.First().SetContextThink( "TFHud.Reload", function(_)
		{
			IncludeScript( "tf_hud/fonts.nut" );
			IncludeScript( "tf_hud/hud_tf.nut" );
			::TFHud.Init();

			NetMsg.Start( "TFHud.Reload" );
			NetMsg.Send();
		}, 0.1 );
	}

	function TFHud::AnimThink()
	{
		return m_pPlayerHealth.AnimThink();
	}

	function TFHud::SetPlayerClass( nTeam, nClass, bForce = false )
	{
		local plTeam, plClass;

		switch ( nTeam )
		{
			case TFTEAM.RED:	plTeam = "red"; break;
			case TFTEAM.BLUE:	plTeam = "blue"; break;
			default: throw "invalid team"
		}

		switch ( nClass )
		{
			case TFPlayerClass.SCOUT:		plClass = "scout"; break;
			case TFPlayerClass.SOLDIER:		plClass = "soldier"; break;
			case TFPlayerClass.PYRO:		plClass = "pyro"; break;
			case TFPlayerClass.DEMOMAN:		plClass = "demo"; break;
			case TFPlayerClass.HEAVY:		plClass = "heavy"; break;
			case TFPlayerClass.ENGINEER:	plClass = "engi"; break;
			case TFPlayerClass.MEDIC:		plClass = "medic"; break;
			case TFPlayerClass.SNIPER:		plClass = "sniper"; break;
			case TFPlayerClass.SPY:			plClass = "spy"; break;
			default: throw "invalid class"
		}

		local bTeamChange = bForce || nTeam != m_nPlayerTeam;
		if ( bTeamChange || nClass != m_nPlayerClass )
		{
			m_nPlayerClass = nClass;

			m_pPlayerClass.m_hClassImage.SetImage( "hud/class_"+plClass+plTeam, true );
		}

		if ( bTeamChange )
		{
			m_nPlayerTeam = nTeam;

			m_pWeaponAmmo.m_hAmmoBG.SetImage( "hud/ammo_"+plTeam+"_bg", true );
			m_pWeaponAmmo.m_hSecondaryBG.SetImage( "hud/misc_ammo_area_horiz2_"+plTeam, true );
			m_pFlashlight.self.SetImage( "hud/misc_ammo_area_horiz1_"+plTeam, true );
			m_pPlayerClass.m_hClassImageBG.SetImage( "hud/character_"+plTeam+"_bg", true );
			m_pSuitPower.self.SetImage( "hud/misc_ammo_area_"+plTeam, true );
		}
	}

	function TFHud::SetBleeding( state )
	{
		m_pPlayerHealth.m_bBleeding = state;
		m_pPlayerHealth.m_hBleedImage.SetVisible( state );
	}

	function TFHud::OnSelectWeapon( weapon )
	{
		if ( m_Crosshairs )
		{
			local classname = weapon.GetClassname();
			if ( classname in m_Crosshairs )
			{
				return m_hCrosshair.SetImage( m_Crosshairs[classname], true );
			}
		}
	}

	function TFHud::SetCrosshairImage( img, classname = null )
	{
		if ( classname )
		{
			m_Crosshairs[classname] <- img;
		}
		else
		{
			m_hCrosshair.SetImage( img, true );
		}
	}

	function TFHud::SetCrosshairVisible( state )
	{
		return m_hCrosshair.SetVisible( state );
	}

	function TFHud::StatusUpdate()
	{
		m_pPlayerHealth.m_nArmor = NetMsg.ReadShort();

		if ( NetMsg.ReadBool() )
		{
			m_pFlashlight.m_flFlashlight = NetMsg.ReadFloat();
			m_pSuitPower.m_flPower = NetMsg.ReadFloat();

			if ( !m_pFlashlight.self.IsVisible() )
			{
				m_pFlashlight.self.SetVisible( true );
				m_pSuitPower.self.SetVisible( true );
			}
		}
		else
		{
			if ( m_pFlashlight.self.IsVisible() )
			{
				m_pFlashlight.self.SetVisible( false );
				m_pSuitPower.self.SetVisible( false );
			}
		}
	}
}
