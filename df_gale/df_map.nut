//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// This was written in a day.
// I tried cleaning it up, but it's still messy. Beware
//
//-----------------------------------------------------------------------

IncludeScript("vs_library");
IncludeScript("vs_library/glow");

const BOOST_HP_ADD = 5;;
const GLOW_DIST = 1280;;
const CL_T = "255 138 0";;
const CL_CT = "138 255 0";;

// Glow.DEBUG = true;

// There are multiple ways of calling code from the map.
// This changed a couple times during development, but I settled on this method.
::S <- this;

_admins <- [];

list_hostage_pos <-
[
	Vector(-416,704,984),
	Vector(-468,-1274,467),
	Vector(1168,1364,978),
	Vector(1302,306,627),
	Vector(-414,2686,627)
];

bAllinRGB <- false;

function PrintPlayers(list)
{
	::Chat("");
	::Chat(::txt.lightblue + "[MOST GLASSES BROKEN]");

	if( list.len() > 0 )
	{
		Print(::txt.green+"1.", list[0]);
	};

	if( list.len() > 1 )
	{
		Print(::txt.yellow+"2.", list[1]);
	};

	if( list.len() > 2 )
	{
		Print(::txt.orange+"3.", list[2]);
	};

	::Chat("");
}

function Print(rank, ply)
{
	ply = ply.GetScriptScope();

	::Chat(rank + " " + ::txt.white + (ply.bot?"BOT ":"") + ply.name + ::txt.lightblue + " - " + ::txt.purple + ply.breakamt);
}

function SetGlow(ply)
{
	if(!ply.IsValid()) return printl("Trying to glow invalid ent");

	local team = ply.GetTeam();

	if( team == 2 )
	{
		::Glow.Set(ply, ::CONST.CL_T, 1, ::CONST.GLOW_DIST);
	}
	else if( team == 3 )
	{
		::Glow.Set(ply, ::CONST.CL_CT, 1, ::CONST.GLOW_DIST);
	};;
}

function SayCommand(msg,ply)
{
	local buffer = ::split(msg, " ");
	local val, cmd = buffer[0];

	if( buffer.len() > 1 )
		val = buffer[1];

	switch( cmd.tolower() )
	{
		case "kill":
		case "killme":
			Kill(ply);
			break;

// -----------------------------------------------------------------------
// voting system isn't fleshed out, there is a lot to improve
// -----------------------------------------------------------------------
		case "y":
		case "yes":
			if(::Vote.bOngoing) ::Vote.Yes(ply);
			else ::VS.ShowHudHint(hHudHint,ply,"No vote in progress.");
			break;

		case "vote":
			if(!val)return;

			if(!::Vote.bOngoing)
			{
				if( (::Time()-::Vote.flTimeEnd) >= 35.0 )
				{
					if(val.tolower() == "ahs")
					{
						::Vote.exec = ToggleActiveShuffle;
						::Vote.Start(0);
						::Vote.Yes(ply);
					}
					else if(val.tolower() == "rgb")
					{
						if( !bAllinRGB )
						{
							local ex = function()
							{
								::S.bAllinRGB = true;
								local FT = ::FrameTime()*11;
								foreach(i,v in ::VS.GetAllPlayers())
									::delay("Glow.AddRGB(activator)",i*FT,::ENT_SCRIPT,v);
							}

							::Vote.exec = ex;
							::Vote.Start(1);
							::Vote.Yes(ply);
						}
						else
						{
							::Chat(::txt.lightblue+"Every player is already glowing RGB");
						};
					};;
				}
				else::Chat(txt.lightblue+"Cannot start a vote this soon after another has ended. " +txt.yellow+ (35.0-Time()+::Vote.flTimeEnd).tointeger() +txt.lightblue +" sec left");
			};
			break;
// ------------------------------------------

		case "rgb":
			if(!val)return;

			local id = ply.GetScriptScope().networkid;
			foreach(v in _admins) if(id == v)
			{
				if(val.tolower() == "all")
				{
					if( !bAllinRGB )
					{
						bAllinRGB = true;
						local FT = FrameTime()*11;
						foreach(i,v in ::VS.GetAllPlayers())
							::delay("Glow.AddRGB(activator)",i*FT,::ENT_SCRIPT,v);
					};
				}
				else
				{
					local tg = _.ply(val);

					if(tg) Glow.AddRGB(tg);
				};
			};
			break;

		case "noclip":
			if(!val) val = ply;
			else val = ::_.ply(val);
			::_.noclip(val);
			break;

		case "equip":
			if(!val) return;

			// equip target (.equip john weapon_ak47)
			if(buffer.len() > 2)
			{
				::_.equip(val,buffer[2]);
			}
			// self equip (.equip weapon_ak47)
			else
			{
				::_.equip(ply,val);
			};
			break;

// execute arbitrary code if the message is sent by me
// .ex @Chat("test")@
		case "ex":
			if(!val)return;

			if(ply.GetScriptScope().networkid == "STEAM_1:1:XXX")
			{
				local start = msg.find("@");
				if(start)
				{
					local end = msg.find("@",++start);
					if(end)
					{
						local str = msg.slice(start,end);
						::compilestring(str)();
					};
				};
			};
			break;

		default:
	}
}

function ShuffleHostages()
{
	local list = clone list_hostage_pos;

	for(local e; e = ::Entities.FindByClassname(e,"hostage_entity");)
	{
		if(!e.IsBeingCarried())
		{
			local pos = list.remove( ::RandomInt(0,list.len()-1) );

			e.EmitSound("tr.Popup");
			e.SetOrigin(pos);
		};
	}
}

function ToggleActiveShuffle(lo=10,hi=16)
{
	if( !::S.hShuffle.GetTeam() )
	{
		::Chat(::txt.lightblue + "Active hostage shuffle "+::txt.lightgreen+"enabled.");
		::VS.SetKeyFloat(::S.hShuffle,"lowerrandombound",lo);
		::VS.SetKeyFloat(::S.hShuffle,"upperrandombound",hi);
		::EntFireByHandle(::S.hShuffle,"enable");
		::S.hShuffle.SetTeam(1);
	}
	else
	{
		::Chat(::txt.lightblue + "Active hostage shuffle "+::txt.lightred+"disabled.");
		::EntFireByHandle(::S.hShuffle,"disable");
		::S.hShuffle.SetTeam(0);
	};
}

function SetGlowAll()
{
	foreach( i,ply in ::VS.GetAllPlayers() )
	{
		// delaying is a must on setting glow on multiple entities at once
		::delay("SetGlow(activator)", i*::FrameTime(), self, ply);
	}
}

function Boost(x,y,z)
{
	local curr = activator.GetVelocity();

	if( x && curr.x )
		curr.x = 0.0;

	if( y && curr.y )
		curr.y = 0.0;

	if( curr.z < 0.0 )
		curr.z = 0.0;

	activator.SetVelocity(curr + ::Vector(x,y,z));
	activator.EmitSound("Survival.JumpAbility");
	activator.SetHealth(activator.GetHealth()+::CONST.BOOST_HP_ADD);
}

// trigger_multiple: OnStartTouch > !activator > RunScriptCode > Break()
function Break(i=1)
{
	// get speed on x-y plane, vertical speed ignored
	if(!i) i = activator.GetVelocity().Length2DSqr() > 25600.0; // 160: walking speed with knife (130)

	if(i)
	{
		local e;

		if( e = ::Entities.FindByClassnameWithin(null, "func_breakable", caller.GetOrigin(), 0.5) )
		{
			::EntFireByHandle(e, "break", "", 0, activator);
		};

		if( e = ::Entities.FindByClassnameWithin(null, "func_breakable_surf", caller.GetOrigin(), 0.5) )
		{
			::EntFireByHandle(e, "shatter", 20);
		};

		::EntFireByHandle(caller, "kill");
	};
}

function EndOfPit()
{
	if(activator.GetClassname() == "player")
	{
		local sc = activator.GetScriptScope();

		if(sc.bot) Kill(activator);

		local pos = activator.GetOrigin();

		if( ::fabs(activator.GetVelocity().z) >= 3400.0 )
		{
			// activator.EmitSound("c4.explode")

			::VS.ShowHudHint(hHudHint,activator,"Type .killme to end this never ending torment");

			if( ++sc.fallct >= 22 )
			{
				Kill(activator);
			};
		};

		pos.z += 2800.0;

		activator.SetOrigin(pos);
	};
}

// can triggers not detect weapons?
function CleanFallenWep()
{
	for(local e; e = ::Entities.FindByClassnameWithin(e,"weapon_*",Vector(0,0,-2304),2400.0);)
	{
		if(e.IsValid())
			if(!e.GetOwner())
				e.Destroy();;
	}

	for(local e; e = ::Entities.FindByClassnameWithin(e,"weapon_*",Vector(7840,0,-2304),2400.0);)
	{
		if(e.IsValid())
			if(!e.GetOwner())
				e.Destroy();;
	}
}

function Kill(ply)
{
	::EntFireByHandle(hHurt, "hurt", "", 0, ply);
}

// seamless teleport
function OnFall()
{
	local pos = activator.GetOrigin();

	// pos += Vector(7744,0,2288);

	pos.x += 7744;
	// pos.y += 0;
	pos.z += 2288;

	activator.SetOrigin(pos);
	activator.EmitSound("Player.DrownStart");
}

function SecretUse()
{
	local rand = ::RandomInt(0,100);

	local name = activator.GetScriptScope().name;

	if( rand < 15 )
	{
		::printl(name + " picked up reduced glow.");
		::VS.ShowHudHint(hHudHint, activator, "You have picked up reduced glow.");

		local team = activator.GetTeam();

		if( team == 2 )
		{
			::Glow.Set(activator, ::CONST.CL_T, 1, 128);
		}
		else if( team == 3 )
		{
			::Glow.Set(activator, ::CONST.CL_CT, 1, 128);
		};;
	}
	else if( rand < 45 )
	{
		::printl(name + " picked up wide vision.");
		::VS.ShowHudHint(hHudHint, activator, "You have picked up wide vision.");

		::EntFireByHandle(activator, "setfogcontroller", "fog_wide");
		::EntFire("fog_wide", "setstartdist", 128);
		::EntFire("fog_wide", "setenddist", 1280);
		::EntFire("fog_wide", "setfarz", 2048);
	}
	else if( rand < 75 )
	{
		::printl(name + " picked up RGB glow.");
		::VS.ShowHudHint(hHudHint, activator, "You have picked up RGB glow.");

		::Glow.AddRGB(activator);
	};;;

	activator.EmitSound("HUDQuickInfo.LowHealth");

	::Chat(::txt.yellow + name + ::txt.lightblue + " has found something.");
}

function HintHostage()
{
	::VS.ShowHudHint(hHudHint, activator, "You are in a hostage rescue zone.");
}

function Glow::AddRGB(ply)
{
	local sc = ply.GetScriptScope();

	// player already has RGB glow
	// duct tape
	if("ScrollRGB" in sc) return;

	sc._X <- 0;

	sc.ScrollRGB <- function()
	{
		::Glow.Set(self, ::vlRGB[++_X%36] ,1,::CONST.GLOW_DIST);

		::delay("ScrollRGB()", 0.078125, self);
	}

	// executed recursively until the end of the round
	sc.ScrollRGB();
}

::OnGameEvent_player_spawn <- function(data)
{
	local ply = VS.GetPlayerByUserid(data.userid);

	if(!ply) return;

	S.SetGlow(ply);
}

::OnGameEvent_round_start <- function(data)
{
	S.bAllinRGB = false;

	// reset all
	foreach(ply in VS.GetAllPlayers())
	{
		local s = _init_scope(ply);
		s.breakamt <- 0;
		s.hostagehurt <- 0;
		s.fallct <- 0;

		if("ScrollRGB" in s) s.ScrollRGB = dummy;

		Glow.Disable(ply);
	}
}

::OnGameEvent_bot_takeover <- function(data)
{
	S.SetGlow(VS.GetPlayerByUserid(data.userid));
}

::OnGameEvent_round_freeze_end <- function(data)
{
	S.SetGlowAll();

	AlertTeam(2,"Find the hostages, and protect them!");
	AlertTeam(3,"Find the hostages, and rescue them!");

	S.ShuffleHostages();
}

::OnGameEvent_break_breakable <- function(data)
{
	if( !ScriptIsWarmupPeriod() )
	{
		// glass
		if( data.material == 1 )
		{
			local ply = VS.GetPlayerByUserid(data.userid);

			if(ply)
			{
				local sp = _init_scope(ply);

				sp.breakamt++;
			};
		};
	};
}

::OnGameEvent_round_end <- function(data)
{
	if( !ScriptIsWarmupPeriod() )
	{
		local list = VS.GetAllPlayers();

		if(list.len())
		{
			// sort by most glasses broken
			list.sort(function(x,y)
			{
				x = _init_scope(x);
				y = _init_scope(y);
				x = x.breakamt;
				y = y.breakamt;
				if( x > y ) return -1;
				else if( x < y ) return 1;;
				return 0;
			});

			S.PrintPlayers(list);
		};
	};
}

::_init_scope <- function(s)
{
	s = s.GetScriptScope();

	if( !("breakamt" in s) ) s.breakamt <- 0;
	if( !("hostagehurt" in s) ) s.hostagehurt <- 0;
	if( !("fallct" in s) ) s.fallct <- 0;
	if( !("bot" in s) ) s.bot <- s.networkid == "BOT";

	return s;
}

::OnGameEvent_player_say <- function(data)
{
	if( data.text[0] != '.' ) return;

	local ply = VS.GetPlayerByUserid(data.userid);

	if(!ply || !ply.IsValid()) return;

	S.SayCommand(data.text.slice(1),ply);
}

// kind of an easter egg. Hurt the hostage 21 times to get a weapon
::OnGameEvent_hostage_hurt <- function(data)
{
	local ply = VS.GetPlayerByUserid(data.userid);

	if(ply)
	{
		local s = ply.GetScriptScope();

		if(++s.hostagehurt >= 21)
		{
			s.hostagehurt = 0;
			_.equip(ply,"weapon_awp");
		};
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

	function Yes(id)
	{
		// id = ply.GetScriptScope().userid;

		// already voted
		if( ::VS.arrayFind(voters,id) != null ) return;

		voters.append(id);

		if( voters.len() >= nRequiredAmt ) Pass();
		else Display();
	}

	// TODO TODO TODO
	function Start(i)
	{
		voters.clear();
		bOngoing = true;
		nRequiredAmt = ::floor(::VS.GetPlayersAndBots()[0].len() * 0.5).tointeger();

		// for testing offline
		// nRequiredAmt = ::floor(::VS.GetAllPlayers().len() * 0.5).tointeger();

		::Chat(::txt.lightblue+"● A vote has started! Type "+::txt.yellow+".yes"+::txt.lightblue+" to vote");

		if(i == 0)
		{
			::Chat((::S.hShuffle.GetTeam() ? ::txt.lightred+"Disable" : ::txt.lightgreen+"Enable") + ::txt.lightblue+ " active hostage shuffle? " +::txt.yellow+ nRequiredAmt +::txt.white+ " votes required");
		}
		else if(i == 1)
		{
			::Chat(::txt.lightblue+"Give every player RGB glow? " +::txt.yellow+ nRequiredAmt +::txt.white+ " votes required");
		};;

		// ::Alert("A vote has started!\nType .yes to vote");

		::delay("::Vote.End()", 35.0);
	}

	function End()
	{
		if(bOngoing)
		{
			::Alert("The voting has ended, not enough votes. " + voters.len() + "/" + nRequiredAmt);
			::Chat("The voting has ended, not enough votes. " + voters.len() + "/" + nRequiredAmt);
			bOngoing = false;
			voters.clear();
			flTimeEnd = ::Time();
		};
	}

	function Pass()
	{
		if(bOngoing)
		{
			::Alert("The vote has passed!");
			bOngoing = false;
			voters.clear();
			flTimeEnd = ::Time();

			exec();
		};
	}

	function Display()
	{
		// local status = ::S.hShuffle.GetTeam() ? "Disable" : "Enable";

		local votes = voters.len() + "/" + nRequiredAmt;

		// ::Alert(status + " active hostage shuffling?\nVotes: " + votes);
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
		if( ti == "integer" )
		{
			ply = ::VS.GetPlayerByUserid(i);
		}
		else if( ti == "string" )
		{
			foreach(v in ::VS.GetAllPlayers())
				if(("_"+v.GetScriptScope().name).tolower().find(i))
					ply = v;
		}
		else if( ti == "instance" )
		{
			if(ply.IsValid())
				return ply;
		};;;

		return ply;
	}

	function noclip(i)
	{
		i = ply(i);

		if(!i.IsNoclipping()) ::VS.SetKeyInt(i, "movetype", 8);
		else ::VS.SetKeyInt(i, "movetype", 2);

		::VS.ShowHudHint(::S.hHudHint, i, "Toggled noclip");
	}

	function equip(i,s)
	{
		i = ply(i);
		::EntFireByHandle(::Entc("game_player_equip"), "triggerforactivatedplayer", s, 0, i);
	}
}

function Precache()
{
	SendToConsoleServer("sv_airaccelerate 100;sv_falldamage_scale 0.25;sv_falldamage_to_below_player_ratio 4");

	if( !Ent("game_playerdie") )
		VS.MakePermanent(VS.CreateEntity("trigger_brush","game_playerdie"));

	VS.AddOutput(Ent("game_playerdie"), "OnUse", function()
	{
		::Glow.Disable(activator);
		::S.CleanFallenWep();
	});

	if( !("hHudHint" in S) )
	{
		S.hHudHint <- VS.CreateHudHint();
		VS.MakePermanent(S.hHudHint);
	};

	if( !("hShuffle" in S) )
	{
		S.hShuffle <- VS.CreateTimer(null,null,12,18);
		VS.OnTimer(S.hShuffle,S.ShuffleHostages);
		VS.MakePermanent(S.hShuffle);
	};

	if( !("hHurt" in S) )
	{
		S.hHurt <- VS.CreateEntity("point_hurt",null,
		{
			damagetarget = "!activator",
			damage = 13370,
			damagedelay = 0,
			damageradius = 0,
			damagetype = 0x7FFFFFFF
		});

		VS.MakePermanent(S.hHurt);
	};

	// creating inside hammer uses more resources
	local CreateWorldText = function(name,ori,ang,size,cl,msg="")
	{
		// if(Ent(name)) return Ent(name);
		if( Entities.FindByClassnameWithin(null, "point_worldtext", ori, 0.5) ) return;

		local e = VS.CreateEntity("point_worldtext",name,
		{
			spawnflags = 0,
			origin = ori,
			angles = ang,
			message = msg,
			textsize = size,
			color = cl
		});

		VS.MakePermanent(e);

		return e;
	}

//	local SetupRGB = function()
//	{
//		::vlRGB <- [];
//
//		local _X = 0;
//		local _R = 255.0;
//		local _G = 0.0;
//		local _B = 0.0;
//
//		for( local i = 0; i < 36; ++i )
//		{
//			switch(_X)
//			{
//				case 0:
//				{
//					_G += 42.5;
//					if( _G >= 255.0 )
//					{
//						_G = 255.0;
//						_X = 1;
//					};
//					break;
//				}
//				case 1:
//				{
//					_R -= 42.5;
//					if( _R <= 0.0 )
//					{
//						_R = 0.0;
//						_X = 2;
//					};
//					break;
//				}
//				case 2:
//				{
//					_B += 42.5;
//					if( _B >= 255.0 )
//					{
//						_B = 255.0;
//						_X = 3;
//					};
//					break;
//				}
//				case 3:
//				{
//					_G -= 42.5;
//					if( _G <= 0.0 )
//					{
//						_G = 0.0;
//						_X = 4;
//					};
//					break;
//				}
//				case 4:
//				{
//					_R += 42.5;
//					if( _R >= 255.0 )
//					{
//						_R = 255.0;
//						_X = 5;
//					};
//					break;
//				}
//				case 5:
//				{
//					_B -= 42.5;
//					if( _B <= 0.0 )
//					{
//						_B = 0.0;
//						_X = 0;
//					};
//					break;
//				}
//			}
//
//			::vlRGB.append(::Vector(_R,_G,_B));
//		}
//	}();

	CreateWorldText(null,Vector(-2240.39,368.46,1203.69+36),Vector(0,90,0),7,Vector(255,255,255),"Toggle Active Hostage Shuffle");
	CreateWorldText(null,Vector(-2240.39,368.46,1191.69+36),Vector(0,90,0),7,Vector(255,138,0),".vote ahs");
	CreateWorldText(null,Vector(-386.874,-1334.89,280.867+36),Vector(0,180,0),7,Vector(255,255,255),"Toggle Active Hostage Shuffle");
	CreateWorldText(null,Vector(-386.874,-1334.89,268.867+36),Vector(0,180,0),7,Vector(255,138,0),".vote ahs");

	CreateWorldText(null,Vector(-2240.39,368.46,1203.69),Vector(0,90,0),7,Vector(255,255,255),"Enable RGB glow on every player");
	CreateWorldText(null,Vector(-2240.39,368.46,1191.69),Vector(0,90,0),7,Vector(255,138,0),".vote rgb");
	CreateWorldText(null,Vector(-386.874,-1334.89,280.867),Vector(0,180,0),7,Vector(255,255,255),"Enable RGB glow on every player");
	CreateWorldText(null,Vector(-386.874,-1334.89,268.867),Vector(0,180,0),7,Vector(255,138,0),".vote rgb");
}

::vlRGB <- [Vector(255,42.5,0)Vector(255,85,0)Vector(255,127.5,0)Vector(255,170,0)Vector(255,212.5,0)Vector(255,255,0)Vector(212.5,255,0)Vector(170,255,0)Vector(127.5,255,0)Vector(85,255,0)Vector(42.5,255,0)Vector(0,255,0)Vector(0,255,42.5)Vector(0,255,85)Vector(0,255,127.5)Vector(0,255,170)Vector(0,255,212.5)Vector(0,255,255)Vector(0,212.5,255)Vector(0,170,255)Vector(0,127.5,255)Vector(0,85,255)Vector(0,42.5,255)Vector(0,0,255)Vector(42.5,0,255)Vector(85,0,255)Vector(127.5,0,255)Vector(170,0,255)Vector(212.5,0,255)Vector(255,0,255)Vector(255,0,212.5)Vector(255,0,170)Vector(255,0,127.5)Vector(255,0,85)Vector(255,0,42.5)Vector(255,0,0)];
