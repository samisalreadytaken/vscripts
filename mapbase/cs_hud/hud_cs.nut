//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//

local NetMsg = NetMsg;

if ( SERVER_DLL )
{
	CSHud <- {}

	function CSHud::Init( player )
	{
		if ( !player )
			return;

		player.SetContextThink( "CSHud.StatusUpdate", StatusUpdate, 0.0 );

		// Custom map might have different max health & armour values.
		// Though these values can change at any time,
		// query a few times to at least catch map initialisation settings.
		{
			player.SetContextThink( "CSHud.StatusUpdate2", StatusUpdate2, 0.001 );
			player.SetContextThink( "CSHud.StatusUpdate3", StatusUpdate2, 1.0 );
			player.SetContextThink( "CSHud.StatusUpdate4", StatusUpdate2, 2.0 );
			player.SetContextThink( "CSHud.StatusUpdate5", StatusUpdate2, 3.0 );
			player.SetContextThink( "CSHud.StatusUpdate6", StatusUpdate2, 4.0 );
		}

		NetMsg.Receive( "CSHud.Reload", function( player )
		{
			print("SV: Reloading cs_hud...\n");

			player.SetContextThink( "CSHud.StatusUpdate", null, 0.0 );
			delete ::CSHud;

			IncludeScript( "cs_hud/hud_cs.nut" );
			::CSHud.Init( player );
		} );
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

			// NOTE: Not using WriteEntity because of memory leaks
			// (see mapbase-source/source-sdk-2013 #123 and #104)
			local vehicle = player.GetVehicleEntity();
			if ( vehicle )
			{
				NetMsg.WriteShort( vehicle.entindex() );
			}
			else
			{
				NetMsg.WriteShort( 0 );
			}
		NetMsg.Send( player, false );

		return 0.1;
	}

	// Max health is not networked, sk_suit_maxarmor is replicated
	function CSHud::StatusUpdate2( player )
	{
		NetMsg.Start( "CSHud.StatusUpdate2" );
			NetMsg.WriteLong( player.GetMaxHealth() );
		NetMsg.Send( player, true );
	}
}


if ( CLIENT_DLL )
{
	local XRES = XRES, YRES = YRES;

	// Only tested on Linux, Windows is a guess.
	local PROP_DRIVABLE_APC_CLASSNAME = IsWindows() ? "class C_PropDrivableAPC" : "17C_PropDrivableAPC";

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
		//m_pLocator = null

		m_flBackgroundAlpha = 0.5
		m_bSuitEquipped = null // 'null' so that StatusUpdate() detects 'false' as change
		m_hVehicle = null
		m_hWeapon = null

		m_CrosshairGap = null

		m_bCvarChange = false
	}

	IncludeScript( "cs_hud/hudhealtharmor.nut", CSHud );
	IncludeScript( "cs_hud/hudammo.nut", CSHud );
	IncludeScript( "cs_hud/hudweaponselection.nut", CSHud );
	IncludeScript( "cs_hud/hudsuit.nut", CSHud );
	IncludeScript( "cs_hud/hudscope.nut", CSHud );
	IncludeScript( "cs_hud/hudreticle.nut", CSHud );
	//IncludeScript( "cs_hud/hudlocator.nut", CSHud );

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
		//SetHudElementVisible( "CHudLocator", istate ); // does not work

		if ( state )
		{
			m_hVehicle = null;

			NetMsg.Receive( "CSHud.StatusUpdate", StatusUpdate.bindenv(this) );

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

			//Convars.SetFloat( "hud_locator_alpha", 0 );
		}
		else
		{
			m_bSuitEquipped = null;

			NetMsg.Receive( "CSHud.StatusUpdate", dummy );

			m_pWeaponSelection.UnregisterCommands();
			m_pScope.UnregisterCommands();

			m_pWeaponAmmo.RemoveTickSignal();

			m_pPlayerHealth.self.SetVisible( state );
			m_pWeaponAmmo.self.SetVisible( state );
			m_pWeaponAmmo.m_bVisible = state;
			m_pWeaponSelection.self.SetVisible( state );
			m_pFlashlight.self.SetVisible( state );
			m_pSuitPower.self.SetVisible( state );
			m_pScope.self.SetVisible( state );
			m_pScope.m_bVisible = state;
			m_pCrosshair.SetVisible( state );
			//m_pLocator.SetVisible( state, null, null );

			//Convars.SetFloat( "hud_locator_alpha", Convars.GetDefaultValue( "hud_locator_alpha" ).tofloat() );
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
			//m_pLocator = CSGOHudLocator( CSHud );

		m_pPlayerHealth.Init();
		m_pWeaponAmmo.Init();
		m_pWeaponSelection.Init();
		m_pFlashlight.Init();
		m_pSuitPower.Init();
		m_pScope.Init();
		m_pCrosshair.Init();
		//m_pLocator.Init();

		m_pPlayerHealth.m_nHealthWarningThreshold = 24;
		m_pPlayerHealth.m_flMaxHealth = 100.0;
		m_pPlayerHealth.m_flMaxArmor = 100.0;

		NetMsg.Receive( "CSHud.StatusUpdate2", function()
		{
			local flMaxHealth = NetMsg.ReadLong().tofloat();

			if ( CSHud.m_pPlayerHealth.m_flMaxHealth != flMaxHealth )
			{
				printf( "CSHud: max health (%g)->(%g)\n", CSHud.m_pPlayerHealth.m_flMaxHealth, flMaxHealth );
				CSHud.m_pPlayerHealth.m_flMaxHealth = flMaxHealth;
			}
		} );

		SetVisible( m_bVisible );

		Convars.RegisterConvar( "cl_hud_background_alpha", m_flBackgroundAlpha.tofloat().tostring(), "", FCVAR_CLIENTDLL | FCVAR_ARCHIVE );
		Convars.SetChangeCallback( "cl_hud_background_alpha", function(...)
		{
			CSHud.m_flBackgroundAlpha = clamp( Convars.GetFloat( "cl_hud_background_alpha" ), 0.0, 1.0 );
			CSHud.m_bCvarChange = true;
		} );

		// Persistent cvars
		local pKV = FileToKeyValues( "cs_hud.vcfg" );
		if ( pKV )
		{
			local vcfg = {}
			pKV.SubKeysToTable( vcfg );
			foreach ( k, v in vcfg )
			{
				switch ( typeof v )
				{
						case "integer":		Convars.SetInt( k, v ); break;
						case "float":		Convars.SetFloat( k, v ); break;
				}
			}
		}

		// Change callbacks just set this, reset
		m_bCvarChange = false;

		Hooks.Add( player.GetOrCreatePrivateScriptScope(), "UpdateOnRemove", OnLevelShutdown, "CSHud" );

		Convars.RegisterCommand( "cs_hud_reload", Reload, "", 0 );

		// mapbase 7.1 hack, ignore
		if ( !("GetHudViewport" in vgui) )
			vgui.CreatePanel( "Panel", vgui.GetRootPanel(), "" ).Destroy();
	}

	// Write user settings
	function CSHud::OnLevelShutdown()
	{
		// Reset locator visibility hack
		//Convars.SetFloat( "hud_locator_alpha", Convars.GetDefaultValue( "hud_locator_alpha" ).tofloat() );

		if ( !CSHud.m_bCvarChange )
			return;

		local vcfg = CScriptKeyValues();
		vcfg.SetName( "cfg" );

		vcfg.SetKeyFloat( "cl_hud_background_alpha", Convars.GetFloat( "cl_hud_background_alpha" ) );
		vcfg.SetKeyInt( "cl_crosshairstyle", Convars.GetInt( "cl_crosshairstyle" ) );
		vcfg.SetKeyInt( "cl_crosshaircolor_r", Convars.GetInt( "cl_crosshaircolor_r" ) );
		vcfg.SetKeyInt( "cl_crosshaircolor_g", Convars.GetInt( "cl_crosshaircolor_g" ) );
		vcfg.SetKeyInt( "cl_crosshaircolor_b", Convars.GetInt( "cl_crosshaircolor_b" ) );
		vcfg.SetKeyInt( "cl_crosshairalpha", Convars.GetInt( "cl_crosshairalpha" ) );
		vcfg.SetKeyInt( "cl_crosshairsize", Convars.GetInt( "cl_crosshairsize" ) );
		vcfg.SetKeyInt( "cl_crosshairgap", Convars.GetInt( "cl_crosshairgap" ) );
		vcfg.SetKeyInt( "cl_crosshairthickness", Convars.GetInt( "cl_crosshairthickness" ) );
		vcfg.SetKeyInt( "cl_crosshair_outlinethickness", Convars.GetInt( "cl_crosshair_outlinethickness" ) );
		vcfg.SetKeyInt( "cl_crosshairdot", Convars.GetInt( "cl_crosshairdot" ) );

		KeyValuesToFile( "cs_hud.vcfg", vcfg );
		vcfg.ReleaseKeyValues();
	}

	// Purge and reload the HUD
	// To keep forward compatibility, this should always clean itself,
	// then run `hud_cs.nut` and `CSHud.Init()`
	//
	// BUGBUG: Overridden concommands stop working when CSHud.Reload() is called on some saves.
	// Saving and loading the game again in this state is fine.
	// TODO: After fixing this, auto-update the HUD on save files by comparing versions.
	function CSHud::Reload(...)
	{
		print("CL: Reloading cs_hud...\n");

		::CSHud.SetVisible( false );

		::CSHud.m_pPlayerHealth.self.Destroy();
		::CSHud.m_pWeaponAmmo.self.Destroy();
		::CSHud.m_pWeaponSelection.self.Destroy();
		::CSHud.m_pFlashlight.self.Destroy();
		::CSHud.m_pSuitPower.self.Destroy();
		::CSHud.m_pScope.self.Destroy();
		::CSHud.m_pCrosshair.self.Destroy();
		//::CSHud.m_pLocator.self.Destroy();

		delete ::CSHud;

		Entities.First().SetContextThink( "CSHud.Reload", function(_)
		{
			IncludeScript( "cs_hud/fonts.nut" );
			IncludeScript( "cs_hud/hud_cs.nut" );
			::CSHud.Init();

			NetMsg.Start( "CSHud.Reload" );
			NetMsg.Send();
		}, 0.1 );
	}

	function CSHud::OnSelectWeapon( weapon )
	{
		if ( m_CrosshairGap )
		{
			local classname = weapon.GetClassname();
			if ( classname in m_CrosshairGap )
			{
				local gap = m_CrosshairGap[classname];
				if ( gap != 0xAAAAFFFF ) // Hide crosshair
				{
					if ( !m_pCrosshair.m_bVisible )
						m_pCrosshair.SetVisible( true );

					m_pCrosshair.m_nGapTarget = gap;
					m_pCrosshair.m_flStartTime = Time();
				}
				else
				{
					// Start interpolation from 0 when switched back from this weapon
					m_pCrosshair.m_nGap = 0;
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

		// Weapon change, update crosshair
		local weapon = player.GetActiveWeapon();
		if ( m_hWeapon != weapon )
		{
			if ( m_hWeapon = weapon )
			{
				OnSelectWeapon( weapon );
			}
			else
			{
				m_pCrosshair.SetVisible( false );
			}
		}

		local vehicle = NetMsg.ReadShort();
		if ( vehicle )
		{
			if ( !m_hVehicle )
			{
				vehicle = EntIndexToHScript( vehicle );
				m_hVehicle = vehicle;
				m_pWeaponSelection.UnregisterCommands();

				switch ( vehicle.GetClassname() )
				{
					case PROP_DRIVABLE_APC_CLASSNAME:
						m_pWeaponAmmo.SetVehicle( "APC" );
						m_pCrosshair.SetVisible( true );
						SetCrosshairGap( null, YRES(6) ); // -24
						break;

					default:
						if ( NetProps.GetPropInt( vehicle, "m_bHasGun" ) == 1 )
						{
							m_pWeaponAmmo.self.SetVisible( false );
							m_pCrosshair.SetVisible( true );
							SetCrosshairGap( null, YRES(2) );
						}
						else
						{
							m_pWeaponAmmo.self.SetVisible( false );
							m_pCrosshair.SetVisible( false );
						}
				}
			}
		}
		else if ( m_hVehicle )
		{
			m_hVehicle = null;
			m_pWeaponSelection.RegisterCommands();
			m_pWeaponAmmo.SetVehicle( null );

			// FIXME: Ammo panel will become visible after getting out of
			// a vehicle with a weapon without ammo (crowbar, physgun...)
			if ( weapon )
			{
				m_pWeaponAmmo.self.SetVisible( true );
				OnSelectWeapon( weapon );
			}
		}

		// Hide crosshair when dead
		if ( m_pCrosshair.m_bVisible )
		{
			if ( player.GetHealth() <= 0 )
			{
				m_pCrosshair.SetVisible( false );
			}
		}

		//if ( m_pLocator.m_bVisible )
		//{
		//	if ( player.GetHealth() <= 0 )
		//	{
		//		m_pLocator.SetVisible( false, null, null );
		//	}
		//}
	}
}
