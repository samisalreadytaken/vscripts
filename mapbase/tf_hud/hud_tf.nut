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

	function TFHud::Init()
	{
		player.SetContextThink( "TFHud.StatusUpdate", function( pl )
		{
			local suit = pl.IsSuitEquipped();

			NetMsg.Start( "TFHud.StatusUpdate" );
				NetMsg.WriteShort( pl.GetArmor() );
				NetMsg.WriteBool( suit );
				if ( suit )
				{
					NetMsg.WriteFloat( pl.GetFlashlightBattery() * 0.01 );
					NetMsg.WriteFloat( pl.GetAuxPower() * 0.01 );
				}
			NetMsg.Send( pl, false );

			return 0.1;
		}, 0.0 );
	}
}


if ( CLIENT_DLL )
{
	local XRES = XRES, YRES = YRES;

	TFHud <-
	{
		self = null
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
		m_Effects = null
	}

	IncludeScript( "tf_hud/hud_tf_playerstatus.nut" );
	IncludeScript( "tf_hud/hud_tf_playerclass.nut" );
	IncludeScript( "tf_hud/hud_tf_health.nut" );
	IncludeScript( "tf_hud/hud_tf_ammo.nut" );
	IncludeScript( "tf_hud/hud_tf_weaponselection.nut" );
	IncludeScript( "tf_hud/hud_tf_flashlight.nut" );
	IncludeScript( "tf_hud/hud_tf_suitpower.nut" );
	IncludeScript( "tf_hud/hud_tf_scope.nut" );

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

	function TFHud::GetRootPanel()
	{
		return self;
	}

	function TFHud::SetVisible( state )
	{
		if ( state )
		{
			m_pWeaponSelection.RegisterCommands();
			m_pScope.RegisterCommands();
		}
		else
		{
			m_pWeaponSelection.UnregisterCommands();
			m_pScope.UnregisterCommands();
		}

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

		m_bVisible = state;
		self.SetVisible( state );

		SetPlayerClass( m_nPlayerTeam, m_nPlayerClass, 1 );
	}

	function TFHud::Init()
	{
		self = vgui.CreatePanel( "Panel", vgui.GetClientDLLRootPanel(), "TF Hud Root" );
		self.SetPos( 0, 0 );
		self.SetSize( ScreenWidth(), ScreenHeight() );
		self.SetPaintEnabled( false );
		self.SetPaintBackgroundEnabled( false );
		self.SetPostChildPaintEnabled( false );
		self.SetCallback( "PostChildPaint", RenderPanelEffects.bindenv(this) );
		self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );

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
		m_hAnim.SetCallback( "OnTick", AnimThink.bindenv(this) );
		m_hAnim.AddTickSignal( 25 );

		m_hCrosshair = vgui.CreatePanel( "ImagePanel", GetRootPanel(), "TFHudCrosshair" );
		m_hCrosshair.SetZPos( 1 );
		m_hCrosshair.SetVisible( true );
		m_hCrosshair.SetShouldScaleImage( true );
		m_hCrosshair.SetImage( "vgui/crosshairs/crosshair5", true );

		SetVisible( m_bVisible );

		Convars.RegisterConvar( "tf_hud_enabled", m_bVisible.tointeger().tostring(), "", FCVAR_CLIENTDLL | FCVAR_ARCHIVE );
		Convars.SetChangeCallback( "tf_hud_enabled", function(...)
		{
			local state = Convars.GetBool( "tf_hud_enabled" );
			TFHud.SetVisible( state );
		} );

		NetMsg.Receive( "TFHud.StatusUpdate", StatusUpdate.bindenv(this) );
	}

	function TFHud::RenderPanelEffects()
	{
		foreach( effect in m_Effects )
		{
			effect.Render();
		}
	}

	function TFHud::PerformLayout()
	{
		m_hCrosshair.SetSize( 32, 32 );
		m_hCrosshair.SetPos( XRES(320) - 16, YRES(240) - 16 );
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
		m_pPlayerHealth.m_nArmour = NetMsg.ReadShort();

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
