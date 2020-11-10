//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//- v0.5.3 --------------------------------------------------------------
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
//	::OnGameEvent_round_start <- function(event)
//	{
//		::TURRET.Disable( #YOUR_TURRET_VAR# )
//	}
//
// If there are multiple turrets in the map, set the user name as well
//
//	hTurret1 <- ::TURRET.Create( "turret_gun_1", "turret_fire_1", "turret_target_1", "turret_user_1" );
//	hTurret2 <- ::TURRET.Create( "turret_gun_2", "turret_fire_2", "turret_target_2", "turret_user_2" );
//
// Crosshair overlay and sounds can also be set exclusively for each turret
//
//	hTurret2 <- ::TURRET.Create( "turret_gun_2",
//	                             "turret_fire_2",
//	                             "turret_target_2",
//	                             "turret_user_2",
//	                             "mymap/overlay",
//	                             "Weapon_M249.Pump",
//	                             "Weapon_AK47.Single" );
//

// option defaults
local SND_USE = "Weapon_M249.Pump";
local SND_FIRE = "Weapon_M249.Single";
local TURRET_USE_OVERLAY = "";
local TURRET_USER_NAME = "turret_user";

IncludeScript("vs_library");

if( !("TURRET" in getroottable()) )
{
::TURRET <- {}

local _ = function():(SND_USE,SND_FIRE,TURRET_USER_NAME,TURRET_USE_OVERLAY){

local m_list = {}
local m_hCommand = ::VS.CreateEntity("point_clientcommand",null,true);

function Create(szNameGunMDL,
				szNameGunFire,
				szNameGunTarget,
				szUserName = TURRET_USER_NAME,
				szOverlayOn = TURRET_USE_OVERLAY,
				szSndUse = SND_USE,
				szSndFire = SND_FIRE):(m_list)
{
	local hGunProp = ::Ent(szNameGunMDL);
	local hGunFire = ::Ent(szNameGunFire);
	local hTarget = ::Ent(szNameGunTarget);

	if( !hGunProp || !hTarget || !hGunFire )
		throw "TURRET: could not find entities";

	local bCreateNew = true;
	local hCtrl;

	foreach( k,v in m_list )
	{
		if( k.GetScriptScope().m_hGunProp.GetName() == szNameGunMDL )
		{
			bCreateNew = false;
			hCtrl = k;
			break;
		};
	}

	if( bCreateNew )
	{
		local hEye = ::VS.CreateMeasure( szUserName, null, true );
		hCtrl = ::VS.CreateEntity( "game_ui",{ spawnflags = (1<<5)|(1<<6)|(1<<7), fieldofview = -1.0 },true );

		m_list[hCtrl] <-
		{
			szSndFire = szSndFire,
			szSndUse = szSndUse,
			szOverlayOn = szOverlayOn,
			szUserName = szUserName,
			hEye = hEye.weakref(),
			szNameGunMDL = szNameGunMDL,
			szNameGunFire = szNameGunFire,
			szNameGunTarget = szNameGunTarget
		}
	};

	Reset(hCtrl);

	return hCtrl;
}

function Reset( hCtrl ):(m_list)
{
	hCtrl.ValidateScriptScope();
	local sc = hCtrl.GetScriptScope();
	local ls = m_list[hCtrl];

	local hGunProp = ::Ent(ls.szNameGunMDL);
	local hGunFire = ::Ent(ls.szNameGunFire);
	local hTarget = ::Ent(ls.szNameGunTarget);

	sc.m_bShooting <- false;
	sc.m_hUser <- null;
	sc.m_hEye <- ls.hEye.weakref();
	sc.m_hGunProp <- hGunProp.weakref();
	sc.m_hGunFire <- hGunFire.weakref();
	sc.m_hTarget <- hTarget.weakref();
	sc.m_szUserName <- ls.szUserName;
	sc.m_szOverlayOn <- ls.szOverlayOn;
	sc.m_szSndFire <- ls.szSndFire;
	sc.m_szSndUse <- ls.szSndUse;

	AddOutputs(hCtrl);

	for( local ent; ent = ::Entities.FindByName( ent, sc.m_szUserName ); )
		::VS.SetName( ent, "" );
}

function Disable( hCtrl,bForceDeactivate = true ) : (m_hCommand)
{
	local sc = hCtrl.GetScriptScope();

	if ( sc.m_hUser )
	{
		// +use already deactivates itself (spawnflag 7)
		// but this is required if the player did not deactivate, but was killed or round ended
		if ( bForceDeactivate )
			::DoEntFireByInstanceHandle( hCtrl, "Deactivate", "", 0, sc.m_hUser, null );

		::DoEntFireByInstanceHandle( m_hCommand, "Command", "r_screenoverlay\"\"", 0, sc.m_hUser, null );
		::VS.SetName( sc.m_hUser, "" );

//		local scPlayer = sc.m_hUser.GetScriptScope();
//		if( "hControlledTurret" in scPlayer )
//		{
//			scPlayer.hControlledTurret = null;
//		};

		sc.m_hUser = null;
	};

	for ( local ent; ent = ::Entities.FindByName( ent, sc.m_szUserName ); )
		::VS.SetName( ent, "" );

	if ( sc.m_hGunFire )
		::EntFireByHandle( sc.m_hGunFire, "Disable" );

	sc.m_bShooting = false;
	sc.m_hUser = null;
}

function Use( hCtrl, ply = null )
{
	if ( !ply )
	{
		if ( "activator" in ::getroottable() )
		{
			ply = ::activator;
		}
		else
		{
			throw "TURRET: could not find player to use";
		};
	};

	local sc = hCtrl.GetScriptScope();

	// this block will not be called because +use already disables the turret (spawnflag 7)
	if( sc.m_hUser == ply )
	{
		::Msg("TURRET: unexpected execution!\n");
		::DoEntFireByInstanceHandle( sc.self, "Deactivate", "", 0, ply, null );
		return;
	}
	else if( sc.m_hUser )
	{
		return::Msg("TURRET: Someone tried to use the turret while it was already in use\n");
	};;

	if( ply && ply.IsValid() && ply.GetClassname() == "player" )
	{
		// round restart, gunfire and prop are respawned, previous references are invalid
		if( !sc.m_hGunFire )
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

function OnUse():(m_hCommand)
{
	m_hUser = ::activator.weakref();
	m_bShooting = false;

	::VS.SetName( m_hUser,m_szUserName );
	::VS.SetMeasure( m_hEye,m_szUserName );

	::EntFireByHandle( m_hGunFire, "Disable" );
	::DoEntFireByInstanceHandle( m_hCommand,"Command","r_screenoverlay\""+m_szOverlayOn+"\"",0,m_hUser,null );

	m_hGunProp.EmitSound(m_szSndUse);
	Think();
}

function OnAttack()
{
	::EntFireByHandle( m_hGunFire, "Enable" );
	m_bShooting = true;
}

function OnAttackRelease()
{
	::EntFireByHandle( m_hGunFire, "Disable" );
	m_bShooting = false;
}

local TraceDir = ::VS.TraceDir.bindenv(::VS);
local VSAddEvent = ::VS.EventQueue.AddEvent;

function Think() : (TraceDir, VSAddEvent)
{
	if( !m_hUser )
		return;

	if( !m_hUser.GetHealth() )
		return::TURRET.Disable(self);

//	if( m_nFireCount ++>= m_nCooldownLimit )
//	{
//		return VSAddEvent( Think, m_flRecoverTime, this );
//	};

	local vecTargetPos = TraceDir(m_hUser.EyePosition(),m_hEye.GetForwardVector()).GetPos();
	m_hTarget.SetOrigin(vecTargetPos);

	// get the correct shooting angle
	// This will cause the gun orientation to 'jump' as it aims at where the target is
	// local vAng = ::VS.GetAngle(m_hGunProp.GetOrigin(),vecTargetPos);

	// Player eye angle can be used to keep the movement smooth, but misaligned with shot direction
	// (shots will not come straight out of the barrel)
	local vAng = m_hEye.GetAngles();

	m_hGunProp.SetAngles(vAng.x,vAng.y,vAng.z);

	if( m_bShooting )
	{
		m_hGunProp.EmitSound(m_szSndFire);
	};

	return VSAddEvent( Think, 0.05, this );
}

function AddOutputs(hCtrl)
{
	::VS.AddOutput( hCtrl, "PressedAttack", OnAttack, null, true );
	::VS.AddOutput( hCtrl, "UnpressedAttack", OnAttackRelease, null, true );
	::VS.AddOutput( hCtrl, "PlayerOn", OnUse, null, true );
	::VS.AddOutput( hCtrl, "PlayerOff", function(){ ::TURRET.Disable( self, false ) }, null, true );

	hCtrl.GetScriptScope().Think <- Think.bindenv( hCtrl.GetScriptScope() );
}

}.call(::TURRET);
};;
