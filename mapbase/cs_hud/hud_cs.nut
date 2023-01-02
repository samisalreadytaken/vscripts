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
			NetMsg.WriteBool( !!player.GetVehicleEntity() );
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
		m_pCrosshair = null

		m_flBackgroundAlpha = 0.5
		m_bSuitEquipped = false
		m_bVehicle = false

		m_CrosshairGap = null
	}

	IncludeScript( "cs_hud/hudhealtharmor.nut" );
	IncludeScript( "cs_hud/hudammo.nut" );
	IncludeScript( "cs_hud/hudweaponselection.nut" );
	IncludeScript( "cs_hud/hudsuit.nut" );
	IncludeScript( "cs_hud/hudscope.nut" );
	IncludeScript( "cs_hud/hudreticle.nut" );

	function CSHud::GetRootPanel()
	{
		if ( !("GetHudViewport" in vgui) )
			return vgui.GetClientDLLRootPanel();
		return vgui.GetHudViewport();
	}

	function CSHud::SetVisible( state )
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
			m_pWeaponSelection.RegisterCommands();
			m_pScope.RegisterCommands();

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
			m_pWeaponSelection.UnregisterCommands();
			m_pScope.UnregisterCommands();
		}
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
			m_pCrosshair = CSGOHudReticle();

		m_pPlayerHealth.Init();
		m_pWeaponAmmo.Init();
		m_pWeaponSelection.Init();
		m_pFlashlight.Init();
		m_pSuitPower.Init();
		m_pScope.Init();
		m_pCrosshair.Init();

		m_pPlayerHealth.m_nHealthWarningThreshold = 24;
		m_pPlayerHealth.m_flMaxHealth = 100.0;
		m_pPlayerHealth.m_flMaxArmor = 100.0;

		SetVisible( m_bVisible );

		Convars.RegisterConvar( "cl_hud_background_alpha", m_flBackgroundAlpha.tofloat().tostring(), "", FCVAR_CLIENTDLL | FCVAR_ARCHIVE );
		Convars.SetChangeCallback( "cl_hud_background_alpha", function(...)
		{
			CSHud.m_flBackgroundAlpha = clamp( Convars.GetFloat( "cl_hud_background_alpha" ), 0.0, 1.0 );
		} );

		NetMsg.Receive( "CSHud.StatusUpdate", StatusUpdate.bindenv(this) );
	}

	function CSHud::OnSelectWeapon( weapon )
	{
		if ( m_CrosshairGap )
		{
			local classname = weapon.GetClassname();
			if ( classname in m_CrosshairGap )
			{
				local gap = m_CrosshairGap[classname];
				if ( gap != -1 )
				{
					if ( !m_pCrosshair.m_bVisible )
						m_pCrosshair.SetVisible( true );

					m_pCrosshair.m_nGapTarget = gap;
					m_pCrosshair.m_flStartTime = Time();
				}
				else
				{
					m_pCrosshair.SetVisible( false );
				}
			}
			else
			{
				m_pCrosshair.m_nGapTarget = YRES(6);
				m_pCrosshair.m_flStartTime = Time();
			}
		}
	}

	function CSHud::SetCrosshairGap( classname, val )
	{
		if ( classname )
		{
			if ( !m_CrosshairGap )
				m_CrosshairGap = {}

			m_CrosshairGap[classname] <- val;
		}
		else
		{
			m_pCrosshair.m_nGapTarget = val;
			m_pCrosshair.m_flStartTime = Time();
		}
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

			m_pCrosshair.SetPos( ScreenWidth() * x - 16 + 0.5, ScreenHeight() * y - 16 + 0.5 );
		}
		else
		{
			m_pCrosshair.SetPos( XRES(320) - 16, YRES(240) - 16 );
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

		if ( NetMsg.ReadBool() )
		{
			if ( !m_bVehicle )
			{
				m_bVehicle = true;
				m_pWeaponSelection.UnregisterCommands();
				m_pWeaponAmmo.self.SetVisible( false );
				SetCrosshairGap( null, YRES(6) );
			}
		}
		else if ( m_bVehicle )
		{
			m_bVehicle = false;
			m_pWeaponSelection.RegisterCommands();

			// FIXME: Ammo panel will become visible after getting out of
			// a vehicle with a weapon without ammo (crowbar, physgun...)
			local weapon = player.GetActiveWeapon();
			if ( weapon )
			{
				m_pWeaponAmmo.self.SetVisible( true );
				OnSelectWeapon( weapon );
			}
		}
	}
}
