//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// This was initially written in a day,
// and I just kept adding to it.
// It seriously needs some refactoring
//

IncludeScript("vs_library");
IncludeScript("glow");
IncludeScript("fov");
IncludeScript("turret");

const BOOST_HP_ADD = 5;;
const TANK_HP = 350;;
const CLUTCH_HP = 400;;
const GLOW_DIST = 4096;;
const CL_T = "255 138 0";;
const CL_CT = "138 255 0";;
::MAX_COORD_VEC <- Vector(MAX_COORD_FLOAT-4096,MAX_COORD_FLOAT-4096,MAX_COORD_FLOAT-4096);

// Glow.DEBUG = true;

// There are multiple ways of calling code from the map.
// This changed a couple times during development, but I settled on this method.
::SGale <- this;

m_admins <- ["STEAM_1:1:000"];

m_bAllinRGB <- false;

function SetGlow(ply)
{
	if (!ply.IsValid())
		return::DEBUG_PRINT("Trying to glow invalid ent");

	local team = ply.GetTeam();

	if ( team == 2 )
	{
		::Glow.Set( ply, ::CONST.CL_T, 1, ::CONST.GLOW_DIST );
	}
	else if ( team == 3 )
	{
		::Glow.Set( ply, ::CONST.CL_CT, 1, ::CONST.GLOW_DIST );
	};;
}

function SayCommand( ply, msg )
{
	local argv = ::split( msg, " " )
	local argc = argv.len()

	local val
	if ( argc > 1 )
		val = argv[1]

	switch( argv[0].tolower() )
	{
		case ".kill":
			if (IsAdmin(ply))
			{
				if (!val) val = ply;
				else val = ::_.ply(val);
				Kill(val);
			}
			else
			{
				Kill(ply);
			};
			break;

		case ".tank":
			local sc = ply.GetScriptScope();

			if ( !sc.bIsTank && ply.GetHealth())
			{
				for( local wep, Entities = ::Entities; wep = Entities.FindByClassname(wep,"weapon_*"); )
					if ( wep.GetOwner() == ply )
					{
						local classname = wep.GetClassname();
						if ( classname != "weapon_knife" && classname != "weapon_c4" && classname != "weapon_breachcharge" )
							wep.Destroy();
					};

				sc.bIsTank = true;
				::Glow.Set(ply, ::Vector(255,25,25), 1, ::CONST.GLOW_DIST);
				ply.SetHealth(::CONST.TANK_HP);
				ply.EmitSound("coop_apc.gateLever");
			};
			break;

		case ".fov":
			if (val)
			{
				try(val = val.tointeger())
				catch(e){val = null}
				if (val) val = ::clamp(val, 1, 179);
			};

			::SetPlayerFOV(ply,val,0.1);
			break;

// -----------------------------------------------------------------------
// voting system isn't fleshed out, there is a lot to improve
// -----------------------------------------------------------------------
		case ".y":
		case ".yes":
			if (::Vote.bOngoing) ::Vote.Yes(ply);
			else ::VS.ShowHudHint( m_hHudHint, ply, "No vote in progress." );
			break;

		case ".vote":
			if (!val)return;

			if (!::Vote.bOngoing)
			{
				switch(val.tolower())
				{
					case "ahs":
					{
						::Vote.exec = ToggleActiveShuffle;
						::Vote.Start(0);
						::Vote.Yes(ply);
						break;
					}
					case "rgb":
					{
						local ex;

						if ( m_bAllinRGB )
						{
							ex = function()
							{
								m_bAllinRGB = false;

								foreach(ply in ::VS.GetAllPlayers())
									ply.GetScriptScope().ScrollRGB <- dummy;

								SetGlowAll();
							}.bindenv(this);
						}
						else
						{
							ex = function()
							{
								m_bAllinRGB = true;
								local ft = ::FrameTime()*11;
								foreach( i,v in ::VS.GetAllPlayers() )
									::VS.EventQueue.AddEvent( ::Glow.AddRGB, i*ft, [this,v] );
							}.bindenv(this);
						};

						::Vote.exec = ex;
						::Vote.Start(1);
						::Vote.Yes(ply);
						break;
					}
					case "bc":
					{
						if ( ::Entc("game_player_equip").GetTeam() )
						{
							return::Chat(::Vote.szChatPrefix+"Already in breach charge only mode");
						};

						::Vote.exec = function()
						{
							for( local wep,Entities=::Entities; wep = Entities.FindByClassname(wep,"weapon_*"); )
							{
								local classname = wep.GetClassname();
								if ( classname != "weapon_knife" && classname != "weapon_c4" )
									wep.Destroy();
							};

							// spawns 32 entities
							::DoEntFireByInstanceHandle(::Entc("game_player_equip"),"TriggerforActivatedPlayer","weapon_breachcharge",0,::Entc("player"),null);

							::Entc("game_player_equip").SetTeam(1);

							::VS.EventQueue.AddEvent( GiveBreachcharges, 0, this );
						}.bindenv(this);
						::Vote.Start(2);
						::Vote.Yes(ply);
						break;
					}
				}
			};
			break;
// ------------------------------------------

		case ".noclip":
			if (IsAdmin(ply))
			{
				if (!val) val = ply;
				else val = ::_.ply(val);
				::_.noclip(val);
			};
			break;

		case ".equip":
			if (IsAdmin(ply))
			{
				if (!val) return;

				// equip target (.equip john weapon_ak47)
				if (argc > 2)
				{
					::_.equip(val,argv[2]);
				}
				// self equip (.equip weapon_ak47)
				else
				{
					::_.equip(ply,val);
				};
			};
			break;

// execute arbitrary code if the message is sent by me
// .ex @Chat("test")@
		case ".ex":
			if (!val)return;

			if (ply.GetScriptScope().networkid == "STEAM_1:1:000")
			{
				local start = msg.find("@");
				if (start)
				{
					local end = msg.find("@",++start);
					if (end)
					{
						local str = msg.slice(start,end);
						::compilestring(str)();
					};
				};
			};
			break;
	}
}

function IsAdmin(ply)
{
	local id = ply.GetScriptScope().networkid;
	foreach(v in m_admins) if (id == v)
		return true;
	return false;
}

// todo:
function GiveBreachcharges()
{
	local weplist = [];
	local plylist = ::VS.GetAllPlayers();

	for( local wep; wep = ::Entities.FindByClassname(wep,"weapon_breachcharge"); )
		weplist.append(wep);

	if ( weplist.len() < plylist.len() )
	{
		local err = "ERROR, aborting... ["+weplist.len()+","+plylist.len()+"]";
		::Chat(txt.red+err);
		::DEBUG_PRINT(err);
		return;
	};

// 	if the player has the bomb, they won't get the breach charge for some reason
//	but dropping the bomb and picking up both works

	local bomb = ::Entities.FindByClassname(null,"weapon_c4");
	if (bomb)
	{
		local carrier = bomb.GetOwner();
		if ( carrier )
		{
			// can't just move the bomb out of the player,
			// can't delete and spawn it,
			// everything sucks
			// I'd rather have a bombless round than a player without breach charges
			bomb.Destroy();
		};
	};

	for( local i = 0; i < plylist.len(); ++i )
		weplist.remove(i).SetOrigin(plylist[i].EyePosition());

	foreach(v in weplist)
		v.Destroy();

	foreach(ply in plylist)
		if (ply.GetHealth())
			ply.SetHealth(::CONST.TANK_HP);

	// ::SendToConsoleServer("sv_infinite_ammo 1");
	::Entc("game_player_equip").SetTeam(1);

	::EntFire("weapon_breachcharge","SetAmmoAmount",16,1.0);
}

local list_tspawn = [];
local list_tspawn_recent = [];
local list_hostage_pos = [];
local list_hostage_ang = [];
local list_hostage_recent = [];

function GetRandHostagePt():(list_hostage_pos,list_hostage_recent)
{
	local pt = ::RandomInt( 0, list_hostage_pos.len()-1 );
	foreach( k in list_hostage_pos ) if ( pt == k )
		return GetRandHostagePt();

	if ( list_hostage_recent.len() > list_hostage_pos.len()-2 )
		list_hostage_recent.clear();

	list_hostage_recent.append(pt);

	if ( ::Entities.FindByClassnameWithin( null, "player", list_hostage_pos[pt], 64.0 ) )
	{
		::Msg("Player blocking hostage spawn, getting a new position\n");
		return GetRandHostagePt();
	};

	return pt;
}

function ShuffleHostages():(list_hostage_pos,list_hostage_ang)
{
	for ( local e; e = ::Entities.FindByClassname( e, "hostage_entity" ); )
	{
		if (!e.IsBeingCarried())
		{
			local pt = GetRandHostagePt();

			e.EmitSound( "tr.Popup" );
			e.SetOrigin( list_hostage_pos[pt] );
			e.SetAngles( 0,list_hostage_ang[pt],0 );
		};
	}
}

ToggleActiveShuffle <- function(lo=8,hi=12)
{
	if ( !m_hShuffler.GetTeam() )
	{
		::Chat( ::txt.lightblue + "Static hostages "+::txt.lightgreen+"disabled." );
		m_hShuffler.__KeyValueFromFloat( "lowerrandombound",lo );
		m_hShuffler.__KeyValueFromFloat( "upperrandombound",hi );
		::EntFireByHandle( m_hShuffler,"Enable" );
		m_hShuffler.SetTeam(1);
	}
	else
	{
		::Chat( ::txt.lightblue + "Static hostages "+::txt.lightred+"enabled." );
		::EntFireByHandle( m_hShuffler,"Disable" );
		m_hShuffler.SetTeam(0);
	};
}.bindenv(this);

function SetGlowAll()
{
	local ft = ::FrameTime();
	foreach( i,ply in ::VS.GetAllPlayers() )
	{
		// must be delayed while setting glow on multiple entities at once
		::VS.EventQueue.AddEvent( SetGlow, i*ft, [ this, ply ] );
	}
}

function Boost(x,y,z)
{
	local curr = activator.GetVelocity();

	if ( x && curr.x )
		curr.x = 0.0;

	if ( y && curr.y )
		curr.y = 0.0;

	if ( curr.z < 0.0 )
		curr.z = 0.0;

	activator.SetVelocity( curr + ::Vector(x,y,z) );
	activator.EmitSound("Survival.JumpAbility");
	activator.SetHealth( activator.GetHealth() + ::CONST.BOOST_HP_ADD );
}

// trigger_multiple: OnStartTouch > !activator > RunScriptCode > Break()
function Break( i = 1 )
{
	// get speed on x-y plane, vertical speed ignored
	if (!i) i = activator.GetVelocity().Length2DSqr() > 25600.0; // 160: walking speed with knife (130)

	if (i)
	{
		local e;

		if ( e = ::Entities.FindByClassnameWithin( null, "func_breakable", caller.GetOrigin(), 0.5 ) )
		{
			::EntFireByHandle( e, "Break", "", 0, activator );
		};

		if ( e = ::Entities.FindByClassnameWithin( null, "func_breakable_surf", caller.GetOrigin(), 0.5 ) )
		{
			::EntFireByHandle( e, "Shatter", 20 );
		};

		::EntFireByHandle( caller, "Kill" );
	};
}

function Kill(ply)
{
	::DoEntFireByInstanceHandle( ply, "SetHealth", "0", 0, null, null );
}

function SecretUse()
{
	local rand = ::RandomFloat(0.0,1.0);

	local sc = ::activator.GetScriptScope();
	local name = sc.name;

	if ( !name.len() )
		name = "Someone";

	if ( rand < 0.015 )
	{
		::Msg(name + " launched a nuke.\n");
		LaunchNuke(0);
	}
	else if ( rand < 0.17 )
	{
		::activator.EmitSound("UIPanorama.XrayStart");

		::Msg(name + " picked up reduced glow.\n");
		::VS.ShowHudHint( m_hHudHint, ::activator, "You have picked up reduced glow." );

		local team = ::activator.GetTeam();

		if ( IsClutchPlayer(::activator) )
		{
			::Glow.Set( ::activator, ::Vector(255,255,255), 0, 512 );
		}
		else if ( sc.bIsTank )
		{
			::Glow.Set( ::activator, ::Vector(255,25,25), 1, 256 );
		}
		// else if ( "ScrollRGB" in sc && ScrollRGB != ::dummy ){}
		else if ( team == 2 )
		{
			::Glow.Set( ::activator, ::CONST.CL_T, 1, 256 );
		}
		else if ( team == 3 )
		{
			::Glow.Set( ::activator, ::CONST.CL_CT, 1, 256 );
		};;;;
	}
	else if ( rand < 0.23 )
	{
		::Msg(name + " picked up a weapon.\n");
		::VS.ShowHudHint( m_hHudHint, ::activator, "You have picked up a weapon." );
		::EntFireByHandle(::Entc("game_player_equip"), "TriggerForActivatedPlayer", "weapon_ak47", 0, ::activator);
	}
	else if ( rand < 0.56 )
	{
		::Msg(name + " picked up health refill.\n");
		::VS.ShowHudHint( m_hHudHint, ::activator, "You have picked up health refill." );

		if ( IsClutchPlayer(::activator) )
		{
			::activator.SetHealth(::CONST.CLUTCH_HP);
		}
		else if ( sc.bIsTank )
		{
			::activator.SetHealth(::CONST.TANK_HP);
		}
		else
		{
			::activator.SetHealth(100);
		};;
	}
	else if ( rand < 0.75 )
	{
		if ( "ScrollRGB" in sc && sc.ScrollRGB != ::dummy )
		{
			::VS.ShowHudHint( m_hHudHint, ::activator, "You did not find anything here." );
			::activator.EmitSound("ambient.electrical_zap_3");
			return;
		};

		::Msg(name + " picked up RGB glow.\n");
		::VS.ShowHudHint( m_hHudHint, ::activator, "You have picked up RGB glow." );
		::Glow.AddRGB(::activator);
	}
	else
	{
		::VS.ShowHudHint( m_hHudHint, ::activator, "You did not find anything here." );
		::activator.EmitSound("ambient.electrical_zap_3");
		return;
	};;;;;

	::activator.EmitSound("HUDQuickInfo.LowHealth");

	::Chat( ::txt.yellow + name + ::txt.lightblue + " has found something." );
}

function IsClutchPlayer(ply)
{
	return ply.GetTeam() == m_hSpeedmod.GetTeam();
}

function LaunchNuke(i)
{
	if (!i)
	{
		::Alert("A nuke has been launched!");

		::ENT_SCRIPT.EmitSound("df_gale/siren.mp3");

		// set tonemap and move speed on every player
		::EntFire( "relay_tonemap_flash","Disable" );
		::EntFire( "relay_tonemap_flash","CancelPending" );

		::EntFire( "tonemap_global","SetTonemapRate",0.005,1.0 );
		::EntFire( "tonemap_global","SetBloomScale",1.0 );
		::EntFire( "tonemap_global","SetAutoExposureMin",425,6.0 );
		::EntFire( "tonemap_global","SetAutoExposureMax",425,6.0 );

		foreach( ply in ::VS.GetAllPlayers() )
		{
			if ( ply.GetHealth() )
			{
				::EntFireByHandle( m_hSpeedmod, "ModifySpeed", 0.75, 0.75, ply );
				::EntFireByHandle( m_hSpeedmod, "ModifySpeed", 0.55, 7.75, ply );
			};
		}

		::VS.EventQueue.AddEvent( LaunchNuke, 10.0, [ this, 1 ] );
	}
	else
	{
		::ENT_SCRIPT.EmitSound("c4.explode");

		foreach( ply in ::VS.GetAllPlayers() )
		{
			if ( ply.GetHealth() < 300 )
			{
				Kill(ply);
			}
			else
			{
				ply.SetHealth(1);
				::EntFireByHandle( m_hSpeedmod, "ModifySpeed", 1, 0, ply );
			};
		}

		::EntFire( "relay_tonemap_flash","Enable" );
		::EntFire( "tonemap_global","SetBloomScale",0.3 );
		::EntFire( "tonemap_global","SetTonemapRate",0.1 );
		::EntFire( "tonemap_global","SetAutoExposureMin",1 );
		::EntFire( "tonemap_global","SetAutoExposureMax",3 );
	};
}

function OnSecretLight(i)
{
	caller.EmitSound("LoudSpark");
}

local vlRGB = [Vector(255,42.5,0)Vector(255,85,0)Vector(255,127.5,0)Vector(255,170,0)Vector(255,212.5,0)Vector(255,255,0)Vector(212.5,255,0)Vector(170,255,0)Vector(127.5,255,0)Vector(85,255,0)Vector(42.5,255,0)Vector(0,255,0)Vector(0,255,42.5)Vector(0,255,85)Vector(0,255,127.5)Vector(0,255,170)Vector(0,255,212.5)Vector(0,255,255)Vector(0,212.5,255)Vector(0,170,255)Vector(0,127.5,255)Vector(0,85,255)Vector(0,42.5,255)Vector(0,0,255)Vector(42.5,0,255)Vector(85,0,255)Vector(127.5,0,255)Vector(170,0,255)Vector(212.5,0,255)Vector(255,0,255)Vector(255,0,212.5)Vector(255,0,170)Vector(255,0,127.5)Vector(255,0,85)Vector(255,0,42.5)Vector(255,0,0)];

function Glow::AddRGB(ply):(vlRGB)
{
	local sc = ply.GetScriptScope();

	// player already has RGB glow
	// duct tape fix
	if ( "ScrollRGB" in sc && sc.ScrollRGB != ::dummy )
		return;

	sc._X <- 0;

	sc.ScrollRGB <- function():(vlRGB)
	{
		::Glow.Set( self, vlRGB[++_X%36], 1, ::CONST.GLOW_DIST );

		return::VS.EventQueue.AddEvent( ScrollRGB, 0.078125, this );
	}

	// executed recursively until the end of the round
	sc.ScrollRGB();
}

function OnPlayerSpawn()
{
	if ( "activator" in this &&
	     activator &&
	     activator.IsValid() &&
	    (activator.GetTeam() == 2) )
		{
			local pt = GetRandSpawnPt();
			if (pt)
			{
				activator.SetOrigin(pt.GetOrigin());
				activator.SetAngles(0,pt.GetAngles().y,0);
			};
		};
}

function GetRandSpawnPt():(list_tspawn,list_tspawn_recent)
{
	local pt = ::RandomInt(0,list_tspawn.len()-1);
	foreach( k in list_tspawn_recent ) if ( pt == k )
		return GetRandSpawnPt();

	if ( list_tspawn_recent.len() > 15 )
		list_tspawn_recent.clear();

	list_tspawn_recent.append(pt);

	return list_tspawn[pt];
}

// todo:
function InitPlayerScope(ply)
{
	ply.ValidateScriptScope();
	local sc = ply.GetScriptScope();

	sc.hostagehurt <- 0;
	sc._radio_ee <- 0;
	sc.bIsTank <- false;
	if ( !("networkid" in sc) ) sc.networkid <- "";
	if ( !("name" in sc) ) sc.name <- "";

	return sc;
}

::OnGameEvent_player_spawn <- function(data)
{
	local ply = ::VS.GetPlayerByUserid(data.userid);

	if (!ply) return;

	InitPlayerScope(ply);

	SetGlow(ply);
}.bindenv(this);

::OnGameEvent_round_start <- function(data)
{
	// reset all
	foreach( ply in ::VS.GetAllPlayers() )
	{
		local sc = InitPlayerScope(ply);
		if ("ScrollRGB" in sc) sc.ScrollRGB = dummy;

		::Glow.Disable(ply);

		::DoEntFire( "point_clientcommand","Command","r_screenoverlay\"\"",0,ply,null );
	}

	::TURRET.Disable( m_hTurret0 );
	::TURRET.Disable( m_hTurret1 );

	::EntFire( "snd_heli","PlaySound" );

	m_hSpeedmod.SetTeam(0);

	// ::SendToConsoleServer("sv_infinite_ammo 0");
	::Entc("game_player_equip").SetTeam(0);
}.bindenv(this);

::OnGameEvent_bot_takeover <- function(data)
{
	::VS.EventQueue.AddEvent( SetGlow, ::FrameTime()*6, [ this, ::VS.GetPlayerByUserid(data.userid) ] );
}.bindenv(this);

::OnGameEvent_round_freeze_end <- function(data)
{
	::VS.ValidateUseridAll();

	if ( m_bAllinRGB )
	{
		local ft = ::FrameTime()*11;

		foreach( i,v in ::VS.GetAllPlayers() )
			::VS.EventQueue.AddEvent( ::Glow.AddRGB, i*ft, [ this, v ] );
	}
	else
	{
		SetGlowAll();
	};

	::AlertTeam(2,"Find the hostages, and protect them!");
	::AlertTeam(3,"Find the hostages, and rescue them!");

	ShuffleHostages();

	// apply state
	::EntFireByHandle(m_hShuffler,m_hShuffler.GetTeam()?"Enable":"Disable");

	if ( !ScriptIsWarmupPeriod() )
		::VS.EventQueue.AddEvent( CheckTSpawn, 15, this );

	TURRET.Disable(m_hTurret0);
	TURRET.Disable(m_hTurret1);

	// ::SendToConsoleServer("sv_infinite_ammo 0");
	::Entc("game_player_equip").SetTeam(0);
}.bindenv(this);

function CheckTSpawn()
{
	local ft = ::FrameTime();
	local pos = ::Vector(8960,-128,2176);
	foreach( i,ply in ::VS.GetAllPlayers() )
		if ( ply.GetHealth() )
			if ( (ply.GetOrigin()-pos).LengthSqr() < 0x400000 )
			{
				::Msg("Found a T player at spawn after freeze\n");
				::VS.EventQueue.AddEvent( OnTSpawn, i*ft, [ this, ply ] );
			};;

	local bomb = ::Entities.FindByClassname(null,"weapon_c4");

	if ( bomb )
	{
		if ( !bomb.GetOwner() )
		{
			if ( (bomb.GetOrigin()-pos).LengthSqr() < 0x400000 )
			{
				bomb.SetOrigin(Vector(71.4,-570.0,473.04));
			};
		};
	};
}

::OnGameEvent_item_pickup <- function(data)
{
	local ply = ::VS.GetPlayerByUserid(data.userid);

	if (!ply) return;

	local sc = ply.GetScriptScope();

	if ( "bIsTank" in sc && sc.bIsTank || ::Entc("game_player_equip").GetTeam() )
	{
		for( local wep, Entities = ::Entities; wep = Entities.FindByClassname(wep,"weapon_*"); )
			if ( wep.GetOwner() == ply )
			{
				local classname = wep.GetClassname();
				if ( classname != "weapon_knife" && classname != "weapon_c4" && classname != "weapon_breachcharge" )
					wep.Destroy();
			};
	};
}

::OnGameEvent_round_end <- function(data)
{
	foreach( ply in ::VS.GetAllPlayers() )
	{
		local sc = ply.GetScriptScope();
		if ( sc )
		{
			sc.bIsTank <- false;
		};
	}
}

::OnGameEvent_player_say <- function(data)
{
	if ( data.text[0] != '.' ) return;

	local ply = ::VS.GetPlayerByUserid(data.userid);

	if (!ply) return;

	SayCommand( ply, data.text );
}.bindenv(this);

// kind of an easter egg. Hurt the hostage 21 times to get a weapon
::OnGameEvent_hostage_hurt <- function(data)
{
	local ply = VS.GetPlayerByUserid(data.userid);

	if (ply)
	{
		local s = ply.GetScriptScope();

		if (++s.hostagehurt >= 21)
		{
			s.hostagehurt = 0;
			_.equip(ply,"weapon_awp");
		};
	};
}

// give weapon on specific radio combination
::OnGameEvent_player_radio <- function(data)
{
	local ply = VS.GetPlayerByUserid(data.userid);

	if (!ply) return;

	local sc = ply.GetScriptScope();

	switch(sc._radio_ee)
	{
		case 0:
			// you lead
			if (data.slot == 16)
				++sc._radio_ee;
			else sc._radio_ee = 0;
			break;
		case 1:
			// in position
			if (data.slot == 18)
				++sc._radio_ee;
			else sc._radio_ee = 0;
			break;
		case 2:
			// backup
			if (data.slot == 15)
				++sc._radio_ee;
			else sc._radio_ee = 0;
			break;
		case 3:
			// thanks
			if (data.slot == 12)
			{
				sc._radio_ee = 0;
				_.equip(ply,"weapon_ak47");
			}
			else sc._radio_ee = 0;
			break;
	}
}

function OnTSpawn(activator)
{
	::EntFire( "env_fade","Fade","",0,activator );
	::EntFire( "env_fade","FadeReverse","",1.0,activator );
	::VS.EventQueue.AddEvent( _OnTSpawn, 1.0, [ this, activator ] );
}

function _OnTSpawn(activator)
{
	local r = ::RandomFloat(0.0,1.0);

	if (r > 0.25)
	{
		activator.SetOrigin(Vector(878,1252,270));
		activator.SetAngles(0,240,0);
	}
	else
	{
		activator.SetOrigin(Vector(1000,-1044,416));
		activator.SetAngles(0,135,0);
		activator.SetVelocity(Vector());
	};
}

//-----------------------------------------------------------------------
::Vote <-
{
	flTimeEnd = 0.0,
	bOngoing = false,
	nRequiredAmt = 0,
	exec = null,
	voters = [],
	szChatPrefix = txt.lightred + "●" + txt.lightblue + " ",

	function Yes(id)
	{
		// id = ply.GetScriptScope().userid;

		// already voted
		if ( ::VS.arrayFind(voters,id) != null ) return;

		voters.append(id);

		if ( voters.len() >= nRequiredAmt ) Pass();
		else Display();
	}

	// TODO TODO TODO
	function Start(i)
	{
		voters.clear();
		bOngoing = true;
		nRequiredAmt = (::VS.GetPlayersAndBots()[0].len() * 0.5).tointeger();

		// auto accept
		if ( nRequiredAmt < 2 )
		{
			return;
		};

		// for testing offline
		// nRequiredAmt = ::floor(::VS.GetAllPlayers().len() * 0.5).tointeger();

		::Chat( szChatPrefix + "A vote has started! Type " + ::txt.yellow + ".yes" + ::txt.lightblue + " to vote" );

		switch(i)
		{
			case 0:
				Chat( szChatPrefix +
					(::SGale.m_hShuffler.GetTeam() ? ::txt.lightred+"Enable" : txt.lightgreen+"Disable") +
					::txt.lightblue+ " static hostages? " +
					::txt.yellow + nRequiredAmt +
					::txt.lightblue + " votes required" );
				break;
			case 1:
				Chat( szChatPrefix + "Toggle RGB glow on every player? " + ::txt.yellow + nRequiredAmt + ::txt.lightblue + " votes required" );
				break;
			case 2:
				Chat( szChatPrefix+"Enable breach charge only mode?" );
				break;
		}

		// ::Alert("A vote has started!\nType .yes to vote");

		::VS.EventQueue.AddEvent( ::Vote.End, 20.0, ::Vote );
	}

	function End()
	{
		if (bOngoing)
		{
			::Alert("The voting has ended, not enough votes.");
			::Chat(szChatPrefix + "The voting has ended, not enough votes. " + voters.len() + "/" + nRequiredAmt);
			bOngoing = false;
			voters.clear();
			flTimeEnd = ::Time();
		};
	}

	function Pass()
	{
		if (bOngoing)
		{
			::Alert("The vote has passed!");
			::Chat(szChatPrefix + "The vote has passed!");
			bOngoing = false;
			voters.clear();
			flTimeEnd = ::Time();

			exec();
		};
	}

	function Display()
	{
		local votes = voters.len() + "/" + nRequiredAmt;

		::Alert("Votes: " + votes);
	}
}
//-----------------------------------------------------------------------

// various utilities
::_ <-
{
	// get handle from userid OR steam name
	function ply(i)
	{
		local ply = i,ti = typeof i;
		if ( ti == "integer" )
		{
			ply = ::VS.GetPlayerByUserid(i);
		}
		else if ( ti == "string" )
		{
			foreach( v in ::VS.GetAllPlayers() )
				if ( v.GetScriptScope().name.tolower().find(i) == 0 )
					ply = v;
		};;

		if ( ti == "instance" )
		{
			if (ply.IsValid())
				return ply;
		}
		else ply = null;

		return ply;
	}

	function noclip(i)
	{
		i = ply(i);

		if (!i.IsNoclipping()) i.__KeyValueFromInt("movetype", 8);
		else i.__KeyValueFromInt("movetype", 2);

		::VS.ShowHudHint( ::SGale.m_hHudHint, i, "Toggled noclip" );
	}

	function equip(i,s)
	{
		i = ply(i);
		::EntFireByHandle(::Entc("game_player_equip"), "TriggerForActivatedPlayer", s, 0, i);
	}
}

function OnPlayerDeath()
{
	local glow = ::Glow.Disable(activator);

	if (glow)
		glow.SetAbsOrigin(::MAX_COORD_VEC);

	local sc = activator.GetScriptScope();

	sc.bIsTank = false;
	if ("ScrollRGB" in sc) sc.ScrollRGB = ::dummy;

	if ( !m_hSpeedmod.GetTeam() )
	{
		// check team balances, give powerups to the clutch player (1v4+)
		local TT = [], CT = [];
		foreach( k,v in ::VS.GetAllPlayers() )
		{
			if ( v.GetHealth() )
			{
				if ( v.GetTeam() == 2 )
				{
					TT.append(v);
				}
				else if ( v.GetTeam() == 3 )
				{
					CT.append(v);
				};;
			};
		}

		local lt = TT.len(), lc = CT.len();
		local ply, team;

		if ( (lt == 1) && (lc > 3) )
		{
			team = CT;
			ply = TT[0];
		}
		else if ( (lc == 1) && (lt > 3) )
		{
			team = TT;
			ply = CT[0];
		};;

		if ( ply )
		{
			m_hSpeedmod.SetTeam( ply.GetTeam() );

			::EntFireByHandle( m_hSpeedmod, "ModifySpeed", 1.25, 0, ply );
			ply.SetHealth(::CONST.CLUTCH_HP);

			::Glow.Set( ply, Vector(255,255,255), 0, ::CONST.GLOW_DIST );

			::Alert("Clutch powerups activated!");

			// opposite team
			foreach( v in team )
			{
				if ( v.GetHealth() < 100 || !v.GetScriptScope().bIsTank )
				{
					v.SetHealth(100);
				};
			}
		};
	};
}

function Precache():(list_tspawn,list_hostage_pos,list_hostage_ang)
{
	SendToConsoleServer("mp_autokick 0;sv_airaccelerate 100;sv_falldamage_scale 0.3;sv_falldamage_to_below_player_ratio 5;sv_autobunnyhopping 1;sv_enablebunnyhopping 0");

	PrecacheScriptSound("df_gale/siren.mp3");

	if ( !Ent("game_playerdie") )
		VS.CreateEntity( "trigger_brush",{ targetname = "game_playerdie" },true );

	VS.AddOutput( Ent("game_playerdie"), "OnUse", OnPlayerDeath );

	if ( !("m_hHudHint" in this) )
	{
		m_hHudHint <- VS.CreateEntity( "env_hudhint",null,true ).weakref();
	};

	if ( !("m_hSpeedmod" in this) )
	{
		m_hSpeedmod <- VS.CreateEntity( "player_speedmod",{ speed = 0 },true ).weakref();
	};

	if ( !("m_hShuffler" in this) )
	{
		m_hShuffler <- VS.CreateTimer( true,null,10,14,false,true ).weakref();
		VS.OnTimer( m_hShuffler,ShuffleHostages );
		m_hShuffler.SetTeam(1); // enabled by default
	};

	if ( !("m_hTurret0" in this) )
	{
		m_hTurret0 <- TURRET.Create("turret_gun_0",
									"turret_fire_0",
									"turret_target_0",
									"turret_user_0",
									"df_gale/crosshair").weakref();
		m_hTurret1 <- TURRET.Create("turret_gun_1",
									"turret_fire_1",
									"turret_target_1",
									"turret_user_1",
									"df_gale/crosshair",
									"Weapon_M249.Pump",
									"Weapon_AK47.Single").weakref();
	};

	local CreateWorldText = function( ori, ang, size, cl, msg = "" )
	{
		// cancel if text exists in this spot
		if ( Entities.FindByClassnameWithin(null, "point_worldtext", ori, 0.5) )
			return;

		local e = VS.CreateEntity("point_worldtext",
		{
			spawnflags = 0,
			origin = ori,
			angles = ang,
			message = msg,
			textsize = size,
			color = cl
		}, true);

		return e;
	}

	local char_dist = 8;
	local vec_white = Vector(255,255,255);
	local vec_orange = Vector(255,138,0);

	local debug = CreateWorldText( Vector(-283,-724,24.09),Vector(0,90,0),3,vec_white,"." );
	::VS.SetName( debug,"debugtxt" );
	local debug2 = CreateWorldText( Vector(-283,-724,24.09-6),Vector(0,90,0),3,vec_white,"." );
	::VS.SetName( debug2,"debugtxt2" );
	local debug3 = CreateWorldText( Vector(-283,-724,24.09-12),Vector(0,90,0),3,vec_white,"." );
	::VS.SetName( debug3,"debugtxt3" );

	local ang60 = Vector(0,-150,0);
	local ang180 = Vector(0,0,0);
	local ct_ori = Vector(-596,-452,84);
	CreateWorldText( ct_ori,ang180,5,vec_white,"Knife only tank mode" );
	ct_ori.z -= char_dist;
	CreateWorldText( ct_ori,ang180,5,vec_orange,".tank" );
	ct_ori.z -= char_dist;

	CreateWorldText( ct_ori,ang180,5,vec_white,"Set FOV" );
	ct_ori.z -= char_dist;
	CreateWorldText( ct_ori,ang180,5,vec_orange,".fov <value>" );
	ct_ori.z -= char_dist;

	CreateWorldText( ct_ori,ang180,5,vec_white,"Enable breach charge only mode" );
	ct_ori.z -= char_dist;
	CreateWorldText( ct_ori,ang180,5,vec_orange,".vote bc" );
	ct_ori.z -= char_dist;
	CreateWorldText( ct_ori,ang180,5,vec_white,"Toggle RGB glow on every player" );
	ct_ori.z -= char_dist;
	CreateWorldText( ct_ori,ang180,5,vec_orange,".vote rgb" );
	ct_ori.z -= char_dist;
	CreateWorldText( ct_ori,ang180,5,vec_white,"Toggle static hostages" );
	ct_ori.z -= char_dist;
	CreateWorldText( ct_ori,ang180,5,vec_orange,".vote ahs" );

	local t_ori = Vector(722.22,1190.05,65.23);
	CreateWorldText( t_ori,ang60,5,vec_white,"Knife only tank mode" );
	t_ori.z -= char_dist;
	CreateWorldText( t_ori,ang60,5,vec_orange,".tank" );
	t_ori.z -= char_dist;

	CreateWorldText( t_ori,ang60,5,vec_white,"Set FOV" );
	t_ori.z -= char_dist;
	CreateWorldText( t_ori,ang60,5,vec_orange,".fov <value>" );
	t_ori.z -= char_dist;

	CreateWorldText( t_ori,ang60,5,vec_white,"Enable breach charge only mode" );
	t_ori.z -= char_dist;
	CreateWorldText( t_ori,ang60,5,vec_orange,".vote bc" );
	t_ori.z -= char_dist;
	CreateWorldText( t_ori,ang60,5,vec_white,"Toggle RGB glow on every player" );
	t_ori.z -= char_dist;
	CreateWorldText( t_ori,ang60,5,vec_orange,".vote rgb" );
	t_ori.z -= char_dist;
	CreateWorldText( t_ori,ang60,5,vec_white,"Toggle static hostages" );
	t_ori.z -= char_dist;
	CreateWorldText( t_ori,ang60,5,vec_orange,".vote ahs" );

	for( local e; e = Entities.FindByName(e,"tspawn"); )
		list_tspawn.append(e.weakref());

	for( local e; e = Entities.FindByName(e,"hostage"); )
	{
		list_hostage_pos.append(e.GetOrigin());
		list_hostage_ang.append(e.GetAngles().y);
	};
}

//function SetupRGB(step, iR = null, iG = null, iB = null)
//{
//	::vlRGB <- [];
//
//	if ( !iR && !iG && !iB )
//	{
//		iR = 255;
//		iG = 0;
//		iB = 0;
//	};
//
//	step = step.tointeger();
//
//	local incr = 255.0/step;
//	local lim = step*6;
//
//	// Source uses color32
//	// optionally you can cast to int at the end of the loop,
//	// when getting the final colour value, or just let the engine do it
//	// if ( !VS.IsInteger(incr) )
//	//	print("SetupRGB: Some values will be clamped.\n");
//
//	for( local _R = iR,
//			   _G = iG,
//			   _B = iB,
//			   _X = 0,i = 0; i < lim; ++i )
//	{
//		switch(_X)
//		{
//			case 0:
//				_G += incr;
//				if ( _G >= 255.0 )
//				{
//					_G = 255.0;
//					_X = 1;
//				};
//				break;
//			case 1:
//				_R -= incr;
//				if ( _R <= 0.0 )
//				{
//					_R = 0.0;
//					_X = 2;
//				};
//				break;
//			case 2:
//				_B += incr;
//				if ( _B >= 255.0 )
//				{
//					_B = 255.0;
//					_X = 3;
//				};
//				break;
//			case 3:
//				_G -= incr;
//				if ( _G <= 0.0 )
//				{
//					_G = 0.0;
//					_X = 4;
//				};
//				break;
//			case 4:
//				_R += incr;
//				if ( _R >= 255.0 )
//				{
//					_R = 255.0;
//					_X = 5;
//				};
//				break;
//			case 5:
//				_B -= incr;
//				if ( _B <= 0.0 )
//				{
//					_B = 0.0;
//					_X = 0;
//				};
//				break;
//		}
//
//		::vlRGB.append(::Vector(_R,_G,_B));
//
//		// ------------- print
//		// print("[");
//		// foreach( v in vlRGB ) print( VecToString(v) );
//		// print("]");
//	}
//}

// these exist to debug in a server where I don't have access to the console
::DEBUG_PRINT <- function(err)
{
	local wrldtxt = ::Ent("debugtxt");
	local wrldtxt2 = ::Ent("debugtxt2");
	local wrldtxt3 = ::Ent("debugtxt3");

	if ( !wrldtxt || !wrldtxt.IsValid() )
		return::Chat(txt.red+"INITIALISATION ERROR");

	local stack1 = ::getstackinfos(2);
	local stack2 = ::getstackinfos(3);

	local out0 = "["+err+"]";
	local out1 = "["+stack1.func+"()] "+stack1.src+" ["+stack1.line+"]";
	local out2 = "["+stack2.func+"()] "+stack2.src+" ["+stack2.line+"]";

	::print("\t"+out0+"\n");
	::print("\t"+out1+"\n");
	::print("\t"+out2+"\n");

	wrldtxt.__KeyValueFromString("message",out0);
	wrldtxt2.__KeyValueFromString("message",out1);
	wrldtxt3.__KeyValueFromString("message",out2);
}

//::DEBUG1 <- function()
//{
//	local wrldtxt = ::Ent("debugtxt");
//	local dout = "";
//
//	foreach( v in ::VS.GetAllPlayers() )
//	{
//		local sc = v.GetScriptScope();
//
//		if ( !sc )
//		{
//			dout += "!sc:"+v.entindex();
//		}
//		else
//		{
//			if ( !("userid" in sc) )
//			{
//				dout += "!uid:"+v.entindex();
//				dout += " ";
//			}
//			else
//			{
//				if ( !("networkid" in sc) )
//					dout += "!nid:u"+sc.userid+" ";
//				else if ( !sc.networkid.len() )
//					dout += "~nid:u"+sc.userid+" ";;
//
//				if ( !("name" in sc) )
//					dout += "!nam:u"+sc.userid+" ";
//				else if ( !sc.name.len() )
//					dout += "~nam:u"+sc.userid+" ";;
//			};
//		};
//	}
//
//	local ig = 0,ig2 = 0;
//	foreach( v in ::Glow._list )
//		if ( !v )
//			++ig;
//		else if ( !v.GetMoveParent() )
//			++ig2;;
//
//	if (ig)
//		dout += "!gl:"+ig;
//	if (ig2)
//		dout += "~gl:"+ig2;
//
//	if ( !("self" in ::S) )
//		dout += "!self";
//
//	if ( dout.len() )
//	{
//		wrldtxt.__KeyValueFromString("message","#"+dout);
//
//		::print("---\n!!! Dump script error: " + dout + "\n");
//		::Chat(txt.red+dout);
//	}
//	else
//	{
//		wrldtxt.__KeyValueFromString("message","+");
//	};
//}

seterrorhandler(DEBUG_PRINT);
