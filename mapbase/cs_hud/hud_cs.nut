//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//


if ( SERVER_DLL )
{
	CSHud <- {}

	function CSHud::Init( player )
	{
		if ( !player )
			return;

		player.SetContextThink( "CSHud.StatusUpdate", StatusUpdate, 0.0 );
	}

	function CSHud::StatusUpdate( player )
	{
		local suit = player.IsSuitEquipped();

		NetMsg.Start( "CSHud.StatusUpdate" );
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

	CSHud <-
	{
		m_bVisible = true

		m_pPlayerHealth = null
		m_pWeaponAmmo = null
		m_pWeaponSelection = null
		m_pFlashlight = null
		m_pSuitPower = null
		m_pScope = null

		m_flBackgroundAlpha = 0.5
		m_bSuitEquipped = false

		m_hCrosshair = null
		m_Crosshairs = null
	}

	IncludeScript( "cs_hud/hudhealtharmor.nut" );
	IncludeScript( "cs_hud/hudammo.nut" );
	IncludeScript( "cs_hud/hudweaponselection.nut" );
	IncludeScript( "cs_hud/hudsuit.nut" );
	IncludeScript( "cs_hud/hudscope.nut" );

	function CSHud::GetRootPanel()
	{
		if ( !("GetHudViewport" in vgui) )
			return vgui.GetClientDLLRootPanel();
		return vgui.GetHudViewport();
	}

	function CSHud::SetVisible( state )
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
	}

	function CSHud::Init()
	{
		if ( m_pPlayerHealth && (typeof m_pPlayerHealth.self == "instance") ) // for saverestore bug

		if ( m_pPlayerHealth && m_pPlayerHealth.self && m_pPlayerHealth.self.IsValid() )
			return;

			m_pPlayerHealth = CSGOHudHealthArmor( CSHud );
			m_pWeaponAmmo = CSGOHudWeaponAmmo( CSHud );
			m_pWeaponSelection = CSGOHudWeaponSelection( CSHud );
			m_pFlashlight = CSGOHudFlashlight( CSHud );
			m_pSuitPower = CSGOHudSuitPower( CSHud );
			m_pScope = CCSHudScope();

		m_pPlayerHealth.Init();
		m_pWeaponAmmo.Init();
		m_pWeaponSelection.Init();
		m_pFlashlight.Init();
		m_pSuitPower.Init();
		m_pScope.Init();

		m_pPlayerHealth.m_nHealthWarningThreshold = 24;
		m_pPlayerHealth.m_flMaxHealth = 100.0;
		m_pPlayerHealth.m_flMaxArmor = 100.0;

		// "layout/hud/hudreticle.xml"
		// "styles/hud/hudreticle.css"
		m_hCrosshair = vgui.CreatePanel( "ImagePanel", GetRootPanel(), "CSGOHudReticle" );
		m_hCrosshair.SetZPos( 1 );
		m_hCrosshair.SetVisible( true );
		// m_hCrosshair.SetPos( 0, 0 );
		// m_hCrosshair.SetSize( ScreenWidth(), ScreenHeight() );
		// m_hCrosshair.SetPaintBackgroundEnabled( false );
		// m_hCrosshair.SetCallback( "Paint", DrawCrosshair.bindenv(this) );
		m_hCrosshair.SetShouldScaleImage( false );
		m_hCrosshair.SetImage( "panorama/images/hud/reticle/crosshair", true );
		m_hCrosshair.SetDrawColor( 0xff, 0xcc, 0x00, 0xff );
		//crosshairColor1: #82b116;
		//crosshairColor2: #ffcc00;
		//crosshairColor3: #00ffff;
		//crosshairColor4: #96ffff;

		SetVisible( m_bVisible );

		Convars.RegisterConvar( "cl_hud_background_alpha", m_flBackgroundAlpha.tofloat().tostring(), "", FCVAR_CLIENTDLL | FCVAR_ARCHIVE );
		Convars.SetChangeCallback( "cl_hud_background_alpha", function(...)
		{
			CSHud.m_flBackgroundAlpha = clamp( Convars.GetFloat( "cl_hud_background_alpha" ), 0.0, 1.0 );
		} );

		NetMsg.Receive( "CSHud.StatusUpdate", StatusUpdate.bindenv(this) );
	}
/*
	function CSHud::DrawCrosshair()
	{
		surface.SetColor( 0x82, 0xb1, 0x16, 0xcc );

		local ww = XRES(320);
		local hh = YRES(240);

		local size = 8;
		local gap = 6;
		local thickness = 2;
		local thicknessHalf = thickness / 2;

		// top
		local x0 = ww - thicknessHalf;
		local y0 = hh - gap - size;
		surface.DrawFilledRect( x0, y0, thickness, size );

		// left
		local y1 = hh - thicknessHalf;
		local x1 = ww - gap - size;
		surface.DrawFilledRect( x1, y1, size, thickness );

		// right
		local y2 = hh - thicknessHalf;
		local x2 = ww + gap;
		surface.DrawFilledRect( x2, y2, size, thickness );

		// bottom
		local x3 = ww - thicknessHalf;
		local y3 = hh + gap;
		surface.DrawFilledRect( x3, y3, thickness, size );

		local outline = 1;
		{
			thickness += outline+outline;
			size += outline+outline;

			surface.SetColor( 0x00, 0x00, 0x00, 0xcc );
			surface.DrawOutlinedRect( x0-outline, y0-outline, thickness, size, outline );
			surface.DrawOutlinedRect( x1-outline, y1-outline, size, thickness, outline );
			surface.DrawOutlinedRect( x2-outline, y2-outline, size, thickness, outline );
			surface.DrawOutlinedRect( x3-outline, y3-outline, thickness, size, outline );
		}
	}
*/
	function CSHud::OnSelectWeapon( weapon )
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

	function CSHud::SetCrosshairImage( img, classname = null )
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

	function CSHud::SetCrosshairVisible( state )
	{
		return m_hCrosshair.SetVisible( state );
	}
/*
	// autoaim crosshair
	local function WorldDirectionToScreen( dir )
	{
		local viewOrigin = CurrentViewOrigin();
		local aspectRatio = ScreenWidth() / ScreenHeight();
		local fov = NetProps.GetPropInt( player, "m_iFOV" );
		if ( !fov )
			fov = 90.0;
		local fovx = VS.CalcFovX( fov, aspectRatio * 0.75 );

		local worldToScreen = VS.VMatrix();
		VS.WorldToScreenMatrix( worldToScreen,
			viewOrigin,
			CurrentViewForward(),
			CurrentViewRight(),
			CurrentViewUp(),
			fovx, aspectRatio,
			8.0, MAX_COORD_FLOAT );

		return VS.WorldToScreen( viewOrigin.Add(dir), worldToScreen );
	}

	function CSHud::SetCrosshairDir( vec )
	{
		if ( vec )
		{
			local screen = WorldDirectionToScreen( vec );
			local x = screen.x;
			local y = screen.y;

			if ( x < 0.0 || x > 1.0 || y < 0.0 || y > 1.0 || screen.z > 1.0 )
				return;

			m_hCrosshair.SetPos( ScreenWidth() * x - 16 + 0.5, ScreenHeight() * y - 16 + 0.5 );
		}
		else
		{
			m_hCrosshair.SetPos( XRES(320) - 16, YRES(240) - 16 );
		}
	}
*/
	function CSHud::StatusUpdate()
	{
		local nArmor = NetMsg.ReadShort();
		if ( m_pPlayerHealth.m_nArmor != nArmor )
		{
			m_pPlayerHealth.SetArmor( nArmor );
		}

		if ( m_bSuitEquipped = NetMsg.ReadBool() )
		{
			local flFlashlight = NetMsg.ReadFloat();
			m_pFlashlight.m_flFlashlight = flFlashlight;

			if ( flFlashlight == 1.0 )
			{
				m_pFlashlight.StartFade();
			}
			else if ( m_pFlashlight.m_bFade )
			{
				m_pFlashlight.StopFade();
			}

			local flPower = NetMsg.ReadFloat();
			m_pSuitPower.m_flPower = flPower;

			if ( flPower == 1.0 )
			{
				m_pSuitPower.StartFade();
			}
			else if ( m_pSuitPower.m_bFade )
			{
				m_pSuitPower.StopFade();
			}
		}
		else
		{
			if ( m_pFlashlight.self.IsVisible() )
			{
				m_pFlashlight.self.SetVisible( false );
			}

			if ( m_pSuitPower.self.IsVisible() )
			{
				m_pSuitPower.self.SetVisible( false );
			}
		}
	}
}
