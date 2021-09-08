//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//- v0.5.4 --------------------------------------------------------------
//
// Player controlled turret (multiplayer compatible)
//
// Required entities (targetnames are arbitrary):
//
//	prop_dynamic:                      (gun model prop)
//		targetname: turret_gun_0
//		model: models/weapons/w_mach_m249.mdl
//
//	env_gunfire:                       (fire origin, place in front of the gun barrel)
//		targetname: turret_fire_0
//		parentname: turret_gun_0       (gun model prop)
//		target:     turret_target_0    (aim target)
//		weaponname: weapon_p90         (determines the damage)
//		StartDisabled: 1
//		maxburstdelay: 0
//		minburstdelay: 0
//
//	info_target:                       (aim target, placement does not matter)
//		targetname: turret_target_0
//
//	func_button:                       (to use the turret)
//		OnPressed > !activator > RunScriptCode > ::TURRET.Use( #YOUR_TURRET_VAR# )
//
// Create your turret in your script
//
//	#YOUR_TURRET_VAR# <- ::TURRET.Create( "turret_gun_0", "turret_fire_0", "turret_target_0" );
//
// Disable on round start to make sure there are no players left using the
// turret from the previous round
//	VS.ListenToGameEvent( "round_start", function(ev)
//	{
//		::TURRET.Disable( #YOUR_TURRET_VAR# )
//	}, "TurretDisable" );
//
//
// Crosshair overlay and sounds can also be set exclusively for each turret
//
//	hTurret2 <- ::TURRET.Create( "turret_gun_2",
//	                             "turret_fire_2",
//	                             "turret_target_2",
//	                             "mymap/overlay",
//	                             "Weapon_M249.Pump",
//	                             "Weapon_AK47.Single" );
//

// option defaults
local SND_USE = "Weapon_M249.Pump";
local SND_FIRE = "Weapon_M249.Single";
local TURRET_USE_OVERLAY = "";

IncludeScript("vs_library");

if ( !("g_TurretList" in getroottable()) )
	::g_TurretList <- {};;

if ( !("g_pClientCommand" in getroottable()) )
	::g_pClientCommand <- VS.CreateEntity( "point_clientcommand", null, true );;

if ( !("TURRET" in getroottable()) )
	::TURRET <- {}

else return;;


function TURRET::Create(
			szNameGunMDL,
			szNameGunFire,
			szNameGunTarget,
			szOverlayOn = TURRET_USE_OVERLAY,
			szSndUse = SND_USE,
			szSndFire = SND_FIRE
		)
{
	local hGunProp = ::Ent(szNameGunMDL);
	local hGunFire = ::Ent(szNameGunFire);
	local hTarget = ::Ent(szNameGunTarget);

	if ( !hGunProp || !hTarget || !hGunFire )
		return Msg("TURRET: could not find entities\n");

	local hCtrl;

	foreach( k,v in g_TurretList )
	{
		if ( k.IsValid() && (k.GetScriptScope().m_hGunProp.GetName() == szNameGunMDL) )
		{
			hCtrl = k;
			break;
		};
	}

	if ( !hCtrl )
	{
		hCtrl = ::VS.CreateEntity( "game_ui",{ spawnflags = (1<<5)|(1<<6)|(1<<7), fieldofview = -1.0 },true );

		g_TurretList[hCtrl] <-
		{
			szSndFire = szSndFire,
			szSndUse = szSndUse,
			szOverlayOn = szOverlayOn,
			szNameGunMDL = szNameGunMDL,
			szNameGunFire = szNameGunFire,
			szNameGunTarget = szNameGunTarget
		}
	};

	Reset(hCtrl);

	return hCtrl;
}

function TURRET::Reset( hCtrl ) : (g_TurretList)
{
	hCtrl.ValidateScriptScope();
	local sc = hCtrl.GetScriptScope();
	local ls = g_TurretList[hCtrl];

	local hGunProp = ::Ent( ls.szNameGunMDL );
	local hGunFire = ::Ent( ls.szNameGunFire );
	local hTarget = ::Ent( ls.szNameGunTarget );

	sc.m_bShooting <- false;
	sc.m_hUser <- null;
	sc.m_hGunProp <- hGunProp.weakref();
	sc.m_hGunFire <- hGunFire.weakref();
	sc.m_hTarget <- hTarget.weakref();
	sc.m_szOverlayOn <- ls.szOverlayOn;
	sc.m_szSndFire <- ls.szSndFire;
	sc.m_szSndUse <- ls.szSndUse;

	AddOutputs( hCtrl );
}

function TURRET::Disable( hCtrl, bForceDeactivate = true ) : (g_pClientCommand)
{
	local sc = hCtrl.GetScriptScope();

	if ( sc.m_hUser && sc.m_hUser.IsValid() )
	{
		// +use already deactivates itself (spawnflag 7)
		// but this is required if the player did not deactivate, but was killed or round ended
		if ( bForceDeactivate )
			::DoEntFireByInstanceHandle( hCtrl, "Deactivate", "", 0, sc.m_hUser.self, null );

		::DoEntFireByInstanceHandle( g_pClientCommand, "Command", "r_screenoverlay\"\"", 0, sc.m_hUser.self, null );
	};

	if ( sc.m_hGunFire )
		::EntFireByHandle( sc.m_hGunFire, "Disable" );

	sc.m_bShooting = false;
	sc.m_hUser = null;
}

function TURRET::Use( hCtrl, ply = null )
{
	if ( !ply )
	{
		if ( "activator" in ::getroottable() )
		{
			ply = ::activator;
		}
		else
		{
			return Msg("TURRET: could not find player to use\n");
		};
	};

	local sc = hCtrl.GetScriptScope();

	// this block will not be called because +use already disables the turret (spawnflag 7)
	if ( sc.m_hUser )
	{
		if ( sc.m_hUser.self == ply )
		{
			Msg("TURRET: unexpected execution!\n");
			DoEntFireByInstanceHandle( sc.self, "Deactivate", "", 0, ply, null );
			return;
		}
		else if ( sc.m_hUser.IsValid() )
		{
			return Msg("TURRET: Someone tried to use the turret while it was already in use\n");
		};;
	};

	if ( ply && ply.IsValid() && ply.GetClassname() == "player" )
	{
		// round restart, gunfire and prop are respawned, previous references are invalid
		if ( !sc.m_hGunFire )
		{
			Reset(hCtrl);
		};

		::DoEntFireByInstanceHandle( sc.self, "Activate", "", 0, ply, null );

//		local scPlayer = ply.GetScriptScope();
//		if( scPlayer )
//		{
//			scPlayer.hControlledTurret <- sc.self.weakref();
//		};
	};
}

// internal functions --------------------------------------

function TURRET::OnUse() : (g_pClientCommand)
{
	m_hUser = ToExtendedPlayer( ::activator );
	m_bShooting = false;

	::EntFireByHandle( m_hGunFire, "Disable" );
	::DoEntFireByInstanceHandle( g_pClientCommand,
		"Command",
		"r_screenoverlay\""+m_szOverlayOn+"\"",
		0, m_hUser.self, null );

	m_hGunProp.EmitSound( m_szSndUse );

	// start thinking
	Think();
}

function TURRET::OnAttackPressed()
{
	::EntFireByHandle( m_hGunFire, "Enable" );
	m_bShooting = true;
}

function TURRET::OnAttackRelease()
{
	::EntFireByHandle( m_hGunFire, "Disable" );
	m_bShooting = false;
}

function TURRET::Think()
{
	if ( !m_hUser || !m_hUser.IsValid() )
		return;

	if ( !m_hUser.GetHealth() )
		return ::TURRET.Disable(self);

//	if( m_nFireCount ++>= m_nCooldownLimit )
//	{
//		return VS.EventQueue.AddEvent( Think, m_flRecoverTime, this );
//	};

	local vecTargetPos = VS.TraceDir(
		m_hUser.EyePosition(),
		m_hUser.EyeForward(),
		MAX_TRACE_LENGTH,
		m_hUser.self,
		MASK_SOLID ).GetPos();

	m_hTarget.SetOrigin( vecTargetPos );
	m_hGunProp.SetForwardVector( vecTargetPos - m_hGunProp.GetOrigin() );

	if ( m_bShooting )
	{
		m_hGunProp.EmitSound(m_szSndFire);
	};

	return VS.EventQueue.AddEvent( Think, 0.05, this );
}

function TURRET::AddOutputs( hCtrl )
{
	local sc = hCtrl.GetScriptScope();
	VS.AddOutput( hCtrl, "PressedAttack", OnAttackPressed, sc );
	VS.AddOutput( hCtrl, "UnpressedAttack", OnAttackRelease, sc );
	VS.AddOutput( hCtrl, "PlayerOn", OnUse, sc );
	VS.AddOutput( hCtrl, "PlayerOff", function(){ return ::TURRET.Disable( self, false ) }, sc );
	sc.Think <- Think.bindenv( sc );
}

