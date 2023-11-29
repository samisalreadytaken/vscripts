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

local NetMsg = NetMsg, NetProps = NetProps;

if ( SERVER_DLL )
{
	TFHud <-
	{
		version = TF2HUD_VERSION
	}

	function TFHud::Init( player )
	{
		if ( !player )
			return;

		player.SetContextThink( "TFHud.Armor", ArmorCheck, 0.0 );

		NetMsg.Receive( "TFHud.Reload", function( player )
		{
			print("SV: Reloading tf_hud...\n");

			player.SetContextThink( "TFHud.StatusUpdate", null, 0.0 );
			delete ::TFHud;

			IncludeScript( TF2HUD_PATH + "hud_tf.nut" );
			::TFHud.Init( player );
		} );
	}

	function TFHud::ArmorCheck( player )
	{
		local nArmor = player.GetArmor();

		NetMsg.Start( "TFHud.Armor" );
			NetMsg.WriteShort( nArmor );
		NetMsg.Send( player, false );

		return 0.1;
	}
}


if ( CLIENT_DLL )
{
	local XRES = XRES, YRES = YRES;

	TFHud <-
	{
		version = TF2HUD_VERSION

		player = null
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

		m_hWeapon = null

		m_hAnim = null
		m_hCrosshair = null
		m_Crosshairs = null
	}

	IncludeScript( TF2HUD_PATH + "hud_tf_playerstatus.nut", TFHud );
	IncludeScript( TF2HUD_PATH + "hud_tf_playerclass.nut", TFHud );
	IncludeScript( TF2HUD_PATH + "hud_tf_health.nut", TFHud );
	//IncludeScript( TF2HUD_PATH + "hud_tf_damageindicator.nut", TFHud );
	IncludeScript( TF2HUD_PATH + "hud_tf_ammo.nut", TFHud );
	IncludeScript( TF2HUD_PATH + "hud_tf_weaponselection.nut", TFHud );
	IncludeScript( TF2HUD_PATH + "hud_tf_flashlight.nut", TFHud );
	IncludeScript( TF2HUD_PATH + "hud_tf_suitpower.nut", TFHud );
	IncludeScript( TF2HUD_PATH + "hud_tf_scope.nut", TFHud );
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
			Entities.First().SetContextThink( "TFHud.Think", Think.bindenv(this), 0.0 );

			m_pWeaponSelection.RegisterCommands();
			m_pWeaponSelection.self.AddTickSignal( 25 );

			m_pPlayerHealth.self.SetVisible( state );
		}
		else
		{
			NetMsg.Receive( "TFHud.StatusUpdate", dummy );

			m_pWeaponSelection.UnregisterCommands();
			m_pWeaponSelection.self.RemoveTickSignal();

			m_pPlayerStatus.self.SetVisible( state );
			m_pWeaponAmmo.self.SetVisible( state );
			m_pWeaponAmmo.m_hSecondaryBG.SetVisible( state );
			m_pWeaponSelection.self.SetVisible( state );
			m_pFlashlight.self.SetVisible( state );
			m_pSuitPower.self.SetVisible( state );
			m_pScope.SetVisible( state );
			m_hCrosshair.SetVisible( state );
		}

		SetPlayerClass( m_nPlayerTeam, m_nPlayerClass, 1 );
	}

	function TFHud::Init()
	{
		if ( m_pPlayerHealth && (typeof m_pPlayerHealth.self == "instance") ) // for saverestore bug

		if ( m_pPlayerHealth && m_pPlayerHealth.self && m_pPlayerHealth.self.IsValid() )
			return;

		player = Entities.GetLocalPlayer();

		m_pPlayerStatus = CTFHudPlayerStatus();
		m_pPlayerClass = CTFHudPlayerClass();
		m_pPlayerHealth = CTFHudPlayerHealth();
		m_pWeaponAmmo = CTFHudWeaponAmmo();
		m_pWeaponSelection = CTFHudWeaponSelection( player );
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

		NetMsg.Receive( "TFHud.Armor", function()
		{
			m_pPlayerHealth.m_nArmor = NetMsg.ReadShort();
		}.bindenv(this) );

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
			IncludeScript( TF2HUD_PATH + "fonts.nut" );
			IncludeScript( TF2HUD_PATH + "hud_tf.nut" );
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
		m_hWeapon = weapon;

		if ( !weapon )
			return m_hCrosshair.SetVisible( false );

		if ( m_Crosshairs )
		{
			local classname = weapon.GetClassname();
			if ( classname in m_Crosshairs )
			{
				m_hCrosshair.SetImage( m_Crosshairs[classname], true );
			}
		}

		// Update key bindings and convars
		m_pWeaponSelection.m_iAttackButton = input.StringToButtonCode( input.LookupBinding( "+attack" ) );
		m_pWeaponSelection.m_iAttack2Button = input.StringToButtonCode( input.LookupBinding( "+attack2" ) );
		m_pWeaponSelection.hud_fastswitch = Convars.GetInt( "hud_fastswitch" );
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

	function TFHud::Think(_)
	{
		if ( NetProps.GetPropInt( player, "m_Local.m_bWearingSuit" ) )
		{
			local flFlashlight = NetProps.GetPropFloat( player, "m_HL2Local.m_flFlashBattery" ) * 0.01;
			m_pFlashlight.m_flFlashlight = flFlashlight;

			local flPower = NetProps.GetPropFloat( player, "m_HL2Local.m_flSuitPower" ) * 0.01;
			m_pSuitPower.m_flPower = flPower;

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

		{
			local weapon = player.GetActiveWeapon();
			if ( m_hWeapon != weapon )
			{
				// Update if weapon is changed
				OnSelectWeapon( weapon );
			}

			if ( !NetProps.GetPropInt( player, "m_HL2Local.m_bZooming" ) )
			{
				// If the player zooms in within the think interval, scope will stay visible. That's ok.
				local fov = NetProps.GetPropInt( player, "m_iFOV" );
				if ( !fov && m_pScope.m_bVisible )
				{
					m_pScope.SetVisible( false );
					m_hCrosshair.SetVisible( true );

					surface.PlaySound( "ui/weapon/zoom.wav" );
				}
				else
				{
					if ( weapon &&
							( weapon.GetClassname() == "weapon_crossbow" ) &&
							( weapon == NetProps.GetPropEntity( player, "m_hZoomOwner" ) ) )
					{
						if ( fov && !m_pScope.m_bVisible )
						{
							m_pScope.SetVisible( true );
							m_hCrosshair.SetVisible( false );

							surface.PlaySound( "ui/weapon/zoom.wav" );
						}
					}
				}
			} // !zooming
		} // !vehicle

		return 0.1;
	}
}
