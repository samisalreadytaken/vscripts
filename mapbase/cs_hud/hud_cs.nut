//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//

local NetMsg = NetMsg, NetProps = NetProps;
local vec3_invalid = vec3_invalid;

if ( SERVER_DLL )
{
	CSHud <-
	{
		version = CSGOHUD_VERSION
	}

	function CSHud::Init( player )
	{
		if ( !player )
			return;

		local scope = player.GetOrCreatePrivateScriptScope();
		scope.__m_idrowndmg <- NetProps.GetPropInt( player, "m_idrowndmg" );

		player.SetContextThink( "CSGOHud.DamageCheck", DamageCheck.bindenv(scope), 0.0 );
		player.SetContextThink( "CSGOHud.Armor", ArmorCheck, 0.0 );

		// Custom map might have different max health & armour values.
		// Though these values can change at any time,
		// query a few times to at least catch map initialisation settings.
		{
			player.SetContextThink( "CSGOHud.StatusUpdate2", StatusUpdate2, 0.001 );
			player.SetContextThink( "CSGOHud.StatusUpdate3", StatusUpdate2, 1.0 );
			player.SetContextThink( "CSGOHud.StatusUpdate4", StatusUpdate2, 2.0 );
			player.SetContextThink( "CSGOHud.StatusUpdate5", StatusUpdate2, 3.0 );
			player.SetContextThink( "CSGOHud.StatusUpdate6", StatusUpdate2, 4.0 );
		}

		HookEnvHudHints();

		NetMsg.Receive( "CSGOHud.Reload", function( player )
		{
			print("SV: Reloading cs_hud...\n");

			player.SetContextThink( "CSGOHud.Armor", null, 0.0 );
			delete ::CSHud;

			IncludeScript( CSGOHUD_PATH + "hud_cs.nut" );
			::CSHud.Init( player );
		} );
	}

	// Mappers need to call this if they are late spawning env_hudhint entities
	function CSHud::HookEnvHudHints()
	{
		local ent;
		while ( ent = Entities.FindByClassname( ent, "env_hudhint" ) )
		{
			local scope = ent.GetOrCreatePrivateScriptScope();
			if ( ( "__m_bCSGOHudHook" in scope ) && scope.__m_bCSGOHudHook )
				continue;

			scope.__m_bCSGOHudHook <- true;

			local fnPrevShow, fnPrevHide;
			local event =
			{
				userid = -1,
				hintmessage = ""
			}

			if ( "InputShowHudHint" in scope )
				fnPrevShow = scope.InputShowHudHint;

			if ( "InputHideHudHint" in scope )
				fnPrevHide = scope.InputHideHudHint;

			const SF_HUDHINT_ALLPLAYERS = 1;

			scope.InputShowHudHint <- function()
			{
				if ( fnPrevShow )
					fnPrevShow();

				event.hintmessage = NetProps.GetPropString( self, "m_iszMessage" );

				if ( self.GetSpawnFlags() & SF_HUDHINT_ALLPLAYERS )
				{
					for ( local pl; pl = Entities.FindByClassname( pl, "player" ); )
					{
						event.userid = pl.GetUserID();
						FireGameEvent( "player_hintmessage", event );
					}
				}
				else
				{
					if ( ( "activator" in getroottable() ) && activator )
					{
						if ( "GetUserID" in activator )
						{
							event.userid = activator.GetUserID();
							FireGameEvent( "player_hintmessage", event );
						}
					}
					else
					{
						local player = Entities.GetLocalPlayer();
						if ( player )
						{
							event.userid = player.GetUserID();
							FireGameEvent( "player_hintmessage", event );
						}
					}
				}

				return false;
			}

			scope.InputHideHudHint <- function()
			{
				if ( fnPrevHide )
					fnPrevHide();

				event.hintmessage = "";

				if ( self.GetSpawnFlags() & SF_HUDHINT_ALLPLAYERS )
				{
					for ( local pl; pl = Entities.FindByClassname( pl, "player" ); )
					{
						event.userid = pl.GetUserID();
						FireGameEvent( "player_hintmessage", event );
					}
				}
				else
				{
					if ( ( "activator" in getroottable() ) && activator )
					{
						if ( "GetUserID" in activator )
						{
							event.userid = activator.GetUserID();
							FireGameEvent( "player_hintmessage", event );
						}
					}
					else
					{
						local player = Entities.GetLocalPlayer();
						if ( player )
						{
							event.userid = player.GetUserID();
							FireGameEvent( "player_hintmessage", event );
						}
					}
				}

				return false;
			}
		}
	}

	function CSHud::ArmorCheck( player )
	{
		local nArmor = player.GetArmor();
		// FIXME: If cached, message will be sent before client could receive it on save-restore
		//if ( __m_ArmorValue != nArmor )

		NetMsg.Start( "CSGOHud.Armor" );
			NetMsg.WriteShort( nArmor );
		NetMsg.Send( player, false );

		return 0.1;
	}

	function CSHud::DamageCheck( player )
	{
		local bits = 0;
		local dmgtake = NetProps.GetPropFloat( player, "m_DmgTake" );

		// HACKHACK: Drown damage is not detected through m_DmgTake during think funcs,
		// this here exists only for displaying damage indicator for DMG_DROWN
		local drowndmg = NetProps.GetPropInt( player, "m_idrowndmg" );
		if ( __m_idrowndmg != drowndmg )
		{
			dmgtake = 1.0; // += drowndmg - __m_idrowndmg;
			__m_idrowndmg = drowndmg;
			bits = DMG_DROWN;
		}

		if ( dmgtake || NetProps.GetPropFloat( player, "m_DmgSave" ) )
		{
			bits = NetProps.GetPropInt( player, "m_bitsDamageType" ) | bits;
			if ( bits & CSGOHUD_DMG_BITS )
			{
				NetMsg.Start( "CSGOHud.Damage" );
					NetMsg.WriteLong( bits );
					// This damage type is most likely on a trigger,
					// tell the player the damage is coming from all around
					if ( bits & CSGOHUD_DMG_NO_ORIGIN )
					{
						NetMsg.WriteVec3Coord( player.GetOrigin() );
					}
					else
					{
						NetMsg.WriteVec3Coord( NetProps.GetPropVector( player, "m_DmgOrigin" ) );
					}
				NetMsg.Send( player, true );
			}
		}

		return 0.0;
	}

	// Max health is not networked, sk_suit_maxarmor is replicated
	function CSHud::StatusUpdate2( player )
	{
		NetMsg.Start( "CSGOHud.StatusUpdate2" );
			NetMsg.WriteLong( player.GetMaxHealth() );
		NetMsg.Send( player, true );
	}
}


if ( CLIENT_DLL )
{
	local XRES = XRES, YRES = YRES;
	local Convars = Convars, input = input, Entities = Entities;

	CSHud <-
	{
		version = CSGOHUD_VERSION

		player = null

		m_bVisible = true

		m_pPlayerHealth = null
		m_pDamageIndicator = null
		m_pPoisonDamageIndicator = null
		m_pWeaponAmmo = null
		m_pWeaponSelection = null
		m_pFlashlight = null
		m_pSuitPower = null
		m_pScope = null
		m_pCrosshair = null
		m_pLocator = null
		m_pSquadStatus = null
		m_pHudHint = null

		m_flBackgroundAlpha = 0.5
		m_bPlayerIsDead = false
		m_bSuitEquipped = 0
		m_bPoisoned = 0
		m_hVehicle = null
		m_hWeapon = null
		m_iHideHUD = 0

		m_bCvarChange = false
	}

	IncludeScript( CSGOHUD_PATH + "vs_math" ); // for vehicle gun crosshair
	IncludeScript( CSGOHUD_PATH + "hudhealtharmor.nut", CSHud );
	IncludeScript( CSGOHUD_PATH + "huddamageindicator.nut", CSHud );
	IncludeScript( CSGOHUD_PATH + "hudpoisondamageindicator.nut", CSHud );
	IncludeScript( CSGOHUD_PATH + "hudammo.nut", CSHud );
	IncludeScript( CSGOHUD_PATH + "hudweaponselection.nut", CSHud );
	IncludeScript( CSGOHUD_PATH + "hudsuit.nut", CSHud );
	IncludeScript( CSGOHUD_PATH + "hudscope.nut", CSHud );
	IncludeScript( CSGOHUD_PATH + "hudreticle.nut", CSHud );
	IncludeScript( CSGOHUD_PATH + "hudlocator.nut", CSHud );
	IncludeScript( CSGOHUD_PATH + "hudsquadstatus.nut", CSHud );
	IncludeScript( CSGOHUD_PATH + "hudhinttext.nut", CSHud );
	//IncludeScript( CSGOHUD_PATH + "hudalerts.nut", CSHud );
	//IncludeScript( CSGOHUD_PATH + "huddeathnotice.nut", CSHud );
	//IncludeScript( CSGOHUD_PATH + "hudfreezepanel.nut", CSHud );
	//IncludeScript( CSGOHUD_PATH + "hudhistoryresource.nut", CSHud );

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
		SetHudElementVisible( "CHudDamageIndicator", istate );
		SetHudElementVisible( "CHudPoisonDamageIndicator", istate );
		SetHudElementVisible( "CHudFlashlight", istate );
		SetHudElementVisible( "CHudBattery", istate );
		SetHudElementVisible( "CHudAmmo", istate );
		SetHudElementVisible( "CHudSecondaryAmmo", istate );
		SetHudElementVisible( "CHudWeapon", istate );
		SetHudElementVisible( "CHudCrosshair", istate );
		SetHudElementVisible( "CHudVehicle", istate );
		//SetHudElementVisible( "CHudLocator", istate ); // does not work
		SetHudElementVisible( "CHudSquadStatus", istate );

		if ( state )
		{
			Entities.First().SetContextThink( "CSGOHud.Think", Think.bindenv(this), 0.0 );
			NetMsg.Receive( "CSGOHud.Damage", NET_DamageTaken.bindenv(this) );

			m_pWeaponSelection.RegisterCommands();
			m_pWeaponSelection.self.AddTickSignal( 25 );
			m_pWeaponAmmo.AddTickSignal( 50 );

			m_pPlayerHealth.self.SetVisible( state );

			if ( m_pSquadStatus.m_iSquadMembers )
				m_pSquadStatus.self.SetVisible( state );

			if ( m_bSuitEquipped )
			{
				if ( m_pFlashlight.m_flFlashlight != 1.0 )
					m_pFlashlight.SetVisible();

				if ( m_pSuitPower.m_flPower != 1.0 )
					m_pSuitPower.SetVisible();
			}

			m_hVehicle = null;
			OnSelectWeapon( m_hWeapon );

			Convars.SetFloat( "hud_locator_alpha", 0.0 );
		}
		else
		{
			Entities.First().SetContextThink( "CSGOHud.Think", dummy, 0.0 );
			NetMsg.Receive( "CSGOHud.Damage", dummy );

			m_pWeaponSelection.UnregisterCommands();
			m_pWeaponSelection.self.RemoveTickSignal();
			m_pWeaponAmmo.self.RemoveTickSignal();

			m_pPlayerHealth.self.SetVisible( state );
			m_pWeaponAmmo.SetVisible( state );
			m_pWeaponSelection.self.SetVisible( state );
			m_pFlashlight.self.SetVisible( state );
			m_pSuitPower.self.SetVisible( state );
			m_pScope.SetVisible( state );
			m_pCrosshair.SetVisible( state );
			m_pLocator.SetVisible( state );
			m_pSquadStatus.self.SetVisible( state );
			m_pHudHint.SetVisible( state );

			Convars.SetFloat( "hud_locator_alpha", Convars.GetDefaultValue( "hud_locator_alpha" ).tofloat() );
		}
	}

	function CSHud::Init()
	{
		if ( m_pPlayerHealth && (typeof m_pPlayerHealth.self == "instance") ) // for saverestore bug

		if ( m_pPlayerHealth && m_pPlayerHealth.self && m_pPlayerHealth.self.IsValid() )
			return;

		player = Entities.GetLocalPlayer();

		m_pPlayerHealth = CSGOHudHealthArmor( player );
		m_pDamageIndicator = CSGOHudDamageIndicator( player );
		m_pPoisonDamageIndicator = CSGOHudPoisonDamageIndicator();
		m_pWeaponAmmo = CSGOHudWeaponAmmo( player );
		m_pWeaponSelection = CSGOHudWeaponSelection( player );
		m_pFlashlight = CSGOHudFlashlight();
		m_pSuitPower = CSGOHudSuitPower();
		m_pScope = CCSHudScope( player );
		m_pCrosshair = CSGOHudReticle( player );
		m_pLocator = CSGOHudLocator();
		m_pSquadStatus = CSGOHudSquadStatus();
		m_pHudHint = CSGOHudHintText();

		m_pPlayerHealth.Init();
		m_pDamageIndicator.Init();
		m_pPoisonDamageIndicator.Init();
		m_pWeaponAmmo.Init();
		m_pWeaponSelection.Init();
		m_pFlashlight.Init();
		m_pSuitPower.Init();
		m_pScope.Init();
		m_pCrosshair.Init();
		m_pLocator.Init();
		m_pSquadStatus.Init();
		m_pHudHint.Init();

		m_pPlayerHealth.m_nHealthWarningThreshold = 24;
		m_pPlayerHealth.m_flMaxHealth = 100.0;
		m_pPlayerHealth.m_flMaxArmor = 100.0;
		m_pLocator.m_hTargetTexture = surface.ValidateTexture( "vgui/icons/icon_jalopy", true );

		NetMsg.Receive( "CSGOHud.Armor", function()
		{
			local nArmor = NetMsg.ReadShort();
			if ( m_pPlayerHealth.m_nArmor != nArmor )
				m_pPlayerHealth.SetArmor( nArmor );
		}.bindenv(this) );

		NetMsg.Receive( "CSGOHud.StatusUpdate2", function()
		{
			local flMaxHealth = NetMsg.ReadLong().tofloat();

			if ( CSHud.m_pPlayerHealth.m_flMaxHealth != flMaxHealth )
			{
				printf( "CSGOHud: max health (%g)->(%g)\n", CSHud.m_pPlayerHealth.m_flMaxHealth, flMaxHealth );
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

		Hooks.Add( player.GetOrCreatePrivateScriptScope(), "UpdateOnRemove", OnLevelShutdown, "CSGOHud" );

		Convars.RegisterCommand( "cs_hud_reload", Reload, "", 0 );

		// mapbase 7.1 hack, ignore
		if ( !("GetHudViewport" in vgui) )
			vgui.CreatePanel( "Panel", vgui.GetRootPanel(), "" ).Destroy();
	}

	// Write user settings
	function CSHud::OnLevelShutdown()
	{
		// Reset locator visibility hack
		Convars.SetFloat( "hud_locator_alpha", Convars.GetDefaultValue( "hud_locator_alpha" ).tofloat() );

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
		return vcfg.ReleaseKeyValues();
	}

	// Purge and reload the HUD
	// To keep forward compatibility, this should always clean itself,
	// then run `hud_cs.nut` and `CSHud.Init()`
	function CSHud::Reload(...)
	{
		print("CL: Reloading cs_hud...\n");

		::CSHud.SetVisible( false );

		::CSHud.m_pPlayerHealth.self.Destroy();
		::CSHud.m_pDamageIndicator.self.Destroy();
		::CSHud.m_pPoisonDamageIndicator.self.Destroy();
		::CSHud.m_pWeaponAmmo.self.Destroy();
		::CSHud.m_pWeaponSelection.self.Destroy();
		::CSHud.m_pFlashlight.self.Destroy();
		::CSHud.m_pSuitPower.self.Destroy();
		::CSHud.m_pScope.self.Destroy();
		::CSHud.m_pCrosshair.self.Destroy();
		::CSHud.m_pLocator.self.Destroy();
		::CSHud.m_pSquadStatus.self.Destroy();
		::CSHud.m_pHudHint.self.Destroy();
		StopListeningToAllGameEvents( "CSGOHudHintText" );

		delete ::CSHud;

		Entities.First().SetContextThink( "CSGOHud.Reload", function(_)
		{
			IncludeScript( CSGOHUD_PATH + "fonts.nut" );
			IncludeScript( CSGOHUD_PATH + "hud_cs.nut" );
			::CSHud.Init();

			NetMsg.Start( "CSGOHud.Reload" );
			NetMsg.Send();
		}, 0.1 );
	}

	function CSHud::OnSelectWeapon( weapon )
	{
		m_hWeapon = weapon;

		if ( !weapon )
			return m_pCrosshair.SetVisible( false );

		// Any different crosshairs this weapon should have?
		switch ( weapon.GetClassname() )
		{
			case "weapon_crossbow":
				m_pCrosshair.SetVisible( false );
				break;
			default:
				if ( !m_pCrosshair.m_bVisible )
					m_pCrosshair.SetVisible( true );
		}

		m_pCrosshair.m_nMuzzleFlashParity = NetProps.GetPropInt( weapon, "m_nMuzzleFlashParity" );

		// Update key bindings and convars
		m_pWeaponSelection.m_iAttackButton = input.StringToButtonCode( input.LookupBinding( "+attack" ) );
		m_pWeaponSelection.m_iAttack2Button = input.StringToButtonCode( input.LookupBinding( "+attack2" ) );
		m_pWeaponSelection.hud_fastswitch = Convars.GetInt( "hud_fastswitch" );
	}

	function CSHud::NET_DamageTaken()
	{
		local bits = NetMsg.ReadLong();
		local org = NetMsg.ReadVec3Coord();
		m_pDamageIndicator.DamageTaken( bits, org );
	}

	function CSHud::Think(_)
	{
		// This is needed because HIDEHUD_PLAYERDEAD is not set when player is dead
		if ( !m_pPlayerHealth.m_nHealth )
		{
			if ( m_bPlayerIsDead )
				return 0.0;

			m_bPlayerIsDead = true;

			PanelFadeOut( "CSGOHud.FadeOutHealth", m_pPlayerHealth.self );
			PanelFadeOut( "CSGOHud.FadeOutFlashlight", m_pFlashlight.self );
			PanelFadeOut( "CSGOHud.FadeOutSuitPower", m_pSuitPower.self );
			PanelFadeOut( "CSGOHud.FadeOutSquad", m_pSquadStatus.self );
			PanelFadeOut( "CSGOHud.FadeOutLocator", m_pLocator.self );
			m_pScope.self.SetVisible( false );
			m_pCrosshair.self.SetVisible( false );
			m_pPoisonDamageIndicator.SetVisible( false );

			return 0.0;
		}

		if ( m_bSuitEquipped = NetProps.GetPropInt( player, "m_Local.m_bWearingSuit" ) )
		{
			local flFlashlight = NetProps.GetPropFloat( player, "m_HL2Local.m_flFlashBattery" ) * 0.01;
			m_pFlashlight.m_flFlashlight = flFlashlight;

			if ( flFlashlight == 1.0 )
			{
				m_pFlashlight.FadeOut();
			}
			else if ( m_pFlashlight.m_bFading )
			{
				m_pFlashlight.SetVisible();
			}

			local flPower = NetProps.GetPropFloat( player, "m_HL2Local.m_flSuitPower" ) * 0.01;
			m_pSuitPower.m_flPower = flPower;

			if ( flPower == 1.0 )
			{
				m_pSuitPower.FadeOut();
			}
			else if ( m_pSuitPower.m_bFading )
			{
				m_pSuitPower.SetVisible();
			}
		}
		else
		{
			if ( !m_pFlashlight.m_bFading )
				m_pFlashlight.FadeOut();

			if ( !m_pSuitPower.m_bFading )
				m_pSuitPower.FadeOut();
		}

		local poisoned = NetProps.GetPropInt( player, "m_Local.m_bPoisoned" );
		if ( m_bPoisoned != poisoned )
		{
			// Simple continuous poison effect
			// Impact effects are handled in DamageIndicator
			m_pPoisonDamageIndicator.SetVisible( m_bPoisoned = poisoned )
		}

		local vehicle = NetProps.GetPropEntity( player, "m_hVehicle" );
		if ( vehicle )
		{
			if ( !m_hVehicle )
			{
				m_hVehicle = vehicle;
				m_pWeaponSelection.UnregisterCommands();

				local hasgun = NetProps.GetPropInt( vehicle, "m_bHasGun" );
				local fallback = 1;

				switch ( vehicle.GetClassname() )
				{
					case PROP_DRIVABLE_APC_CLASSNAME:
						m_pWeaponAmmo.SetVehicle( "APC" );
						m_pWeaponAmmo.SetVisible( true );
						m_pCrosshair.SetVisible( true );
						m_pCrosshair.SetVehicleCrosshair( true );
						fallback = 0;
						break;

					case PROP_AIRBOAT_CLASSNAME:
						if ( hasgun )
						{
							m_pWeaponAmmo.SetVehicle( "AIRBOAT" );
							m_pWeaponAmmo.SetVisible( true );
							m_pCrosshair.SetVisible( true );
							m_pCrosshair.SetVehicleCrosshair( true );
							fallback = 0;
						}
						break;
				}

				if ( fallback )
				{
					if ( hasgun )
					{
						m_pWeaponAmmo.SetVisible( false );
						m_pCrosshair.SetVisible( true );
						m_pCrosshair.SetVehicleCrosshair( true );
					}
					else
					{
						m_pWeaponAmmo.SetVisible( false );
						m_pCrosshair.SetVisible( false );
					}
				}
			}
		}
		else // !vehicle
		{
			local weapon = player.GetActiveWeapon();

			if ( m_hVehicle )
			{
				m_hVehicle = null;
				m_pWeaponSelection.RegisterCommands();
				m_pWeaponAmmo.SetVehicle( null );
				m_pCrosshair.SetVehicleCrosshair( false );

				OnSelectWeapon( weapon );
			}
			else if ( m_hWeapon != weapon )
			{
				OnSelectWeapon( weapon );
			}

			if ( !NetProps.GetPropInt( player, "m_HL2Local.m_bZooming" ) )
			{
				// If the player zooms in within the think interval, scope will stay visible. That's ok.
				local fov = NetProps.GetPropInt( player, "m_iFOV" );
				if ( !fov && m_pScope.m_bVisible )
				{
					m_pScope.SetVisible( false );

					if ( m_pCrosshair.m_bVisible )
						m_pCrosshair.self.SetVisible( true );

					surface.PlaySound( "ui/weapon/zoom.wav" );
				}
				else
				{
					if ( weapon &&
							( weapon.GetClassname() == "weapon_crossbow" ) &&
							( NetProps.GetPropEntity( player, "m_hZoomOwner" ) == weapon ) )
					{
						if ( fov && !m_pScope.m_bVisible )
						{
							m_pScope.SetVisible( true );
							m_pCrosshair.self.SetVisible( false );

							surface.PlaySound( "ui/weapon/zoom.wav" );
						}
					}
				}
			} // !zooming
		} // !vehicle

		local iSquadMemberCount = NetProps.GetPropInt( player, "m_HL2Local.m_iSquadMemberCount" );
		if ( m_pSquadStatus.m_iSquadMembers != iSquadMemberCount )
		{
			m_pSquadStatus.m_iSquadMembers = iSquadMemberCount;
			//m_pSquadStatus.m_iSquadMedics = NetProps.GetPropInt( player, "m_HL2Local.m_iSquadMedicCount" );

			m_pSquadStatus.self.SetVisible( !!iSquadMemberCount );
		}

		if ( !m_pLocator.m_bVisible )
		{
			local vecLocatorOrigin = NetProps.GetPropVector( player, "m_HL2Local.m_vecLocatorOrigin" );
			if ( !vecLocatorOrigin.IsEqualTo( vec3_invalid ) )
			{
				// Update faster than the rest of the logic
				Entities.First().SetContextThink( "CSGOHudLocator", LocatorThink.bindenv(this), 0.0 );
				m_pLocator.SetVisible( true );
			}
		}

		// Now see if any panel needs to be hidden.
		// A bit of a mess here, and not very reliable...
		local iHideHUD = NetProps.GetPropInt( player, "m_Local.m_iHideHUD" );
		local prevHideHUD = m_iHideHUD;
		if ( prevHideHUD != iHideHUD )
		{
			local bitsHide = ~prevHideHUD & iHideHUD;
			local bitsShow = prevHideHUD & ~iHideHUD;
			m_iHideHUD = iHideHUD;

			// Vehicle crosshair is not separate than the regular crosshair,
			// don't hide it if vehicle crosshair is supposed to be drawn
			if ( ( bitsHide & CSGOHUD_HIDEHUD_CROSSHAIR ) == CSGOHUD_HIDEHUD_CROSSHAIR )
			{
				m_pCrosshair.self.SetVisible( false );
			}
			else if ( ( bitsHide & HIDEHUD_VEHICLE_CROSSHAIR ) && m_hVehicle )
			{
				m_pCrosshair.self.SetVisible( false );
			}
			else if ( ( bitsHide & HIDEHUD_CROSSHAIR ) && !m_hVehicle )
			{
				m_pCrosshair.self.SetVisible( false );
			}

			if ( bitsShow & CSGOHUD_HIDEHUD_CROSSHAIR )
			{
				OnSelectWeapon( player.GetActiveWeapon() );
			}

			if ( bitsHide & HIDEHUD_FLASHLIGHT )
			{
				m_pFlashlight.self.SetVisible( false );
			}

			if ( bitsHide & CSGOHUD_HIDEHUD_HEALTH )
			{
				m_pPlayerHealth.self.SetVisible( false );
				m_pFlashlight.self.SetVisible( false );
				m_pSuitPower.self.SetVisible( false );
				m_pSquadStatus.self.SetVisible( false );
				m_pScope.self.SetVisible( false );
				m_pLocator.self.SetVisible( false );
			}

			if ( bitsShow & CSGOHUD_HIDEHUD_HEALTH )
			{
				m_pPlayerHealth.self.SetVisible( true );

				if ( m_pSquadStatus.m_iSquadMembers )
					m_pSquadStatus.self.SetVisible( true );

				if ( m_pScope.m_bVisible )
					m_pScope.self.SetVisible( true );

				if ( m_pLocator.m_bVisible )
					m_pLocator.self.SetVisible( true );

				if ( m_bSuitEquipped )
				{
					if ( m_pFlashlight.m_flFlashlight != 1.0 )
						m_pFlashlight.SetVisible();

					if ( m_pSuitPower.m_flPower != 1.0 )
						m_pSuitPower.SetVisible();
				}
			}

			if ( bitsHide & CSGOHUD_HIDEHUD_WEPSELECTION )
			{
				m_pWeaponSelection.m_bHidden = true;
			}

			if ( bitsShow & CSGOHUD_HIDEHUD_WEPSELECTION )
			{
				m_pWeaponSelection.m_bHidden = false;
			}

			if ( bitsHide & CSGOHUD_HIDEHUD_AMMO )
			{
				m_pWeaponAmmo.self.SetVisible( false );
			}

			if ( bitsShow & CSGOHUD_HIDEHUD_AMMO )
			{
				if ( m_pWeaponAmmo.m_bVisible )
					m_pWeaponAmmo.self.SetVisible( true );
			}
		}

		return 0.1;
	}

	function CSHud::LocatorThink(_)
	{
		local vecLocatorOrigin = NetProps.GetPropVector( player, "m_HL2Local.m_vecLocatorOrigin" );
		if ( vecLocatorOrigin.IsEqualTo( vec3_invalid ) )
		{
			m_pLocator.SetVisible( false );
			return -1;
		}

		m_pLocator.m_vecLocatorOrigin.Set( vecLocatorOrigin );
		return 0.015;
	}

	function CSHud::PanelFadeOut( id, panel, delay = 0.0 )
	{
		return Entities.First().SetContextThink( id, PanelFadeOutThink.bindenv( panel ), delay );
	}

	function CSHud::StopPanelFadeOut( id )
	{
		return Entities.First().SetContextThink( id, null, 0.0 );
	}

	local FrameTime = FrameTime;

	function CSHud::PanelFadeOutThink(_)
	{
		local alpha = GetAlpha();
		if ( alpha > 0 )
		{
			local decay = ( FrameTime() * 765.0 ).tointeger();
			SetAlpha( alpha - decay );
			return 0.0;
		}
		else
		{
			SetAlpha( 255 );
			SetVisible( false );
			return -1;
		}
	}
}
