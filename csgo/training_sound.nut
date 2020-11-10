//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Directional Sound Training Map ( + music kits )
//
// This map doesn't really have a purpose. It's kind of a collection of various tests.
// Things WILL be broken and suboptimal.
//
//------------------------------

IncludeScript("vs_library");
IncludeScript("glow");

enum weapon{glock="glock",hkp2000="hkp2000",usp_silencer="usp_silencer",elite="elite",p250="p250",tec9="tec9",fn57="fn57",deagle="deagle",galilar="galilar",famas="famas",ak47="ak47",m4a1="m4a1",m4a1_silencer="m4a1_silencer",ssg08="ssg08",aug="aug",sg556="sg556",awp="awp",scar20="scar20",g3sg1="g3sg1",nova="nova",xm1014="xm1014",mag7="mag7",m249="m249",negev="negev",mac10="mac10",mp9="mp9",mp7="mp7",ump45="ump45",p90="p90",bizon="bizon",mp5sd="mp5sd",sawedoff="sawedoff",cz75a="cz75a"}

const T = 2;;
const CT = 3;;

const CL_GREEN = "171 255 130";;
const CL_WHITE = "255 255 255";;

::TR_SND <- this;

_MAX <- -1;
_MIN <- -1;
MAX  <- -1;
MIN  <- -1;
m_nResolution <- 128;
m_fIntvlCurr  <- 1.0;
m_bBlindMode  <- false;
m_bStarted    <- false;
m_bSpawned    <- false;
m_bAimHelper  <- false;
m_bRange      <- false;
m_bSettingUp  <- false;
m_nCtrlIntvl  <- 0;
m_nThinkCount <- 0;
m_list_bots   <- [];
m_list_sounds <- [];
m_szSndCurr   <- "";
m_nSoundsLen  <- 0;
m_bAimbotON   <- false;
vec3_origin   <- Vector();

function Precache()
{
	if ( !("ENT" in getroottable()) )
	{
		::ENT <-
		{
			// sound target
			// alternatively the bot's origin could be used,
			// but using an external entity allows playing the sound
			// even when the bot is not placed.
			hTarget = ::VS.CreateEntity( "info_target",{targetname = "t"},true ).weakref(),

			// play sound
			hTimerSnd = ::VS.Timer( 1, m_fIntvlCurr, delete PlaySound,null,false,true ).weakref(),

			// vertical aim helper
			hTimerAim = ::VS.Timer( 1, 0.1, delete CheckAng,null,false,true ).weakref(),

			hAIMBOT = ::VS.Timer( 1, 0.01, delete ThinkAimbot,null,false,true ).weakref(),

			// 1. set bot angles to the center of the map
			// 2. sound-interval setting timer
			hTimerThink = ::VS.Timer( 1, 0.01, BotAng,null,false,true ).weakref(),

			// Music kit 10 second countdown timer
			hTimer10 = ::VS.Timer( 1, TICK_INTERVAL, delete Tick,null,false,true ).weakref(),
			// hMsgTen = ::VS.CreateEntity("point_worldtext", {origin = Vector(-179 -172 100), angles = Vector(0 -120 0), message = "10.0000"},true ).weakref(),
			hMsgTen = ::Ent("msg10" ).weakref(),

			// Display info on the music kits when looked at
			hTimerLook = ::VS.Timer( 1, 0.1, delete Looking,null,false,true ).weakref(),

			// for aimbot head measuring
			hBotEye = ::VS.CreateMeasure( "BOT",null,true ).weakref(),

			// game_ui for sound-interval setting
			hGameUI = ::VS.CreateEntity( "game_ui",{spawnflags = 1<<5, fieldofview = -1.0},true ).weakref(),

			// "You killed X"
			hGametext = ::VS.CreateEntity( "game_text",
			{
				channel = 1,
				color = "255 255 255",
				color2 = "250 250 250",
				fadeout = 0.4,
				holdtime = 1.4,
				x = 0.435,
				y = 0.7
			},true ).weakref()
		}

		// player eye angles
		::HPlayerEye <- ::VS.CreateMeasure( "",null,true ).weakref();

		// hud hint
		::g_hHudhint <- ::VS.CreateEntity( "env_hudhint",null,true ).weakref();

		// Team coin
		::VS.CreateEntity( "env_texturetoggle",{targetname = "texture_c", target="c"},true ).weakref();

		::VS.CreateEntity( "game_player_equip",{targetname = "equip", spawnflags = 5, weapon_knife = 1},true ).weakref();

		// ::VS.CreateEntity("point_worldtext",{targetname="s0",origin=Vector(152.966,187.136,93),angles=Vector(0,60,0),textsize=3.5,message="AK47"},true);
		// ::VS.CreateEntity("point_worldtext",{targetname="s6",origin=Vector(152.966,187.136,85),angles=Vector(0,60,0),textsize=3.5,message="M4A4"},true);
		// ::VS.CreateEntity("point_worldtext",{targetname="s1",origin=Vector(152.966,187.136,77),angles=Vector(0,60,0),textsize=3.5,message="Footsteps (concrete)"},true);
		// ::VS.CreateEntity("point_worldtext",{targetname="s7",origin=Vector(152.966,187.136,69),angles=Vector(0,60,0),textsize=3.5,message="Footsteps (metal)"},true);
		// ::VS.CreateEntity("point_worldtext",{targetname="s2",origin=Vector(152.966,187.136,61),angles=Vector(0,60,0),textsize=3.5,message="Headshot"},true);
		// ::VS.CreateEntity("point_worldtext",{targetname="s4",origin=Vector(152.966,187.136,53),angles=Vector(0,60,0),textsize=3.5,message="Flashbang (bounce)"},true);
		// ::VS.CreateEntity("point_worldtext",{targetname="s5",origin=Vector(152.966,187.136,45),angles=Vector(0,60,0),textsize=3.5,message="Flashbang (explode)"},true);

		// ::VS.CreateEntity("point_worldtext",{targetname="t0",origin=Vector(199.002,81,33),angles=Vector(),textsize=10,message="HELPER"},true);
		// ::VS.CreateEntity("point_worldtext",{targetname="t1",origin=Vector(199.002,14,33),angles=Vector(),textsize=10,message="BLIND"},true);
		// ::VS.CreateEntity("point_worldtext",{targetname="t2",origin=Vector(199,-40,33),angles=Vector(),textsize=10,message="DISTANCE"},true);
		// ::VS.CreateEntity("point_worldtext",{targetname="t3",origin=Vector(45.396,247.136,57),angles=Vector(0,60,0),textsize=5,message="sound interval"},true);
	};

	::VS.AddOutput( ::ENT.hGameUI, "PressedForward",  delete SetInterval_add );
	::VS.AddOutput( ::ENT.hGameUI, "PressedBack",     delete SetInterval_sub );
	::VS.AddOutput( ::ENT.hGameUI, "UnpressedForward",       SetInterval_rel );
	::VS.AddOutput( ::ENT.hGameUI, "UnpressedBack",   delete SetInterval_rel );

	PrecacheScriptSound("Doors.Metal.Move1");

	// these should already be set in the map config
	SendToConsoleServer("sv_cheats 1;achievement_disable 1;mp_autokick 0;mp_limitteams 0;mp_autoteambalance 0;sv_disable_radar 0;sv_infinite_ammo 1;mp_ignore_round_win_conditions 1;mp_teammates_are_enemies 1;mp_solid_teammates 0;mp_respawn_immunitytime 0;mp_give_player_c4 0;mp_respawn_on_death_t 1;mp_respawn_on_death_ct 1;weapon_accuracy_nospread 0;sv_auto_adjust_bot_difficulty 0");
	SendToConsoleServer("mp_buytime 216000;mp_maxmoney 32000;mp_startmoney 32000;mp_death_drop_gun 0;mp_playercashawards 0;mp_freezetime 0;mp_maxrounds 1;mp_roundtime 60");
}

// CT spawned
function Init()
{
	VS.GetLocalPlayer();

	SendToConsole("r_screenoverlay\"\"");

	// default values
	SetRange(0,0);
	SetSoundType(0,0);
	VS.SetMeasure( HPlayerEye, HPlayer.GetName() );

	::EntFireByHandle( ENT.hTimerLook, "enable" );

	Equip( weapon.m4a1 );
	Equip( weapon.usp_silencer );

	for ( local i = 9; i--; ) Chat(" ");

	// catch if the player userid is not validated
	local sc = HPlayer.GetScriptScope();
	if ( "name" in sc )
	{
		Chat( txt.lightgreen + "● "+txt.lightblue+"Welcome, " + sc.name + "!" );
		Chat( m_szChatPrefix + txt.yellow + "Using a silenced weapon is suggested to protect your hearing." );
		Chat( "" );
		Msg( "\n\nWelcome, " + sc.name + "!\n" );
		Msg( "Using a silenced weapon is suggested to protect your hearing.\n" );
		Msg( "\n" );
	}
	else VS.ValidateUseridAll();

	VS.EventQueue.AddEvent( PurgeTheUnfit, 1.25, this );

	// -------------------------------------------------------------------
	// must be executed every round, so do it on player spawn
	if ( !m_hCurrMusicKit.IsValid() )
		m_hCurrMusicKit = Ent("m0");

	foreach( i, v in MusicI )
		VS.AddOutput2( Ent("m"+i), "OnPressed", "TR_SND.PickMusicKit(" + (i++) + ")", null, true );

	ENT.hMsgTen = Ent("msg10");
//	for( local d = Ent("d"), i = 0; i < 8; ++i )
//	{
//		local e1 = Ent("s"+i);
//		local e2 = Ent("t"+i);
//		if (e1) VS.SetParent(e1,d);
//		if (e2) VS.SetParent(e2,d);
//	}
//
//	VS.SetParent(ENT.hMsgTen,Ent("d"));
	// -------------------------------------------------------------------

	// in case server settings are not set
	// the map may already be broken if these were not set
	// maybe restartgame once after these?
	SendToConsole("game_mode 0;game_type 3;mp_warmup_end;mp_warmuptime 0;bot_join_after_player 0;bot_quota 6;bot_quota_mode fill;bot_stop 1;bot_dont_shoot 1;bot_chatter off;bot_knives_only;bot_join_after_player 1");
}

// FIXME
// The first bot to join will not trigger the player_connect event,
// thus cannot be validated. Force validate the userid, then kick it
// so the newly connected bot will work.
function PurgeTheUnfit()
{
	local bots = ::VS.GetPlayersAndBots()[1];
	local i = 0, b = false;

	foreach( bot in bots )
	{
		if ( !bot.GetScriptScope() )
		{
			VS.EventQueue.AddEvent( VS.ForceValidateUserid, TICK_INTERVAL * i++, [VS, bot] );
			b = true;
		}
		else if ( bot.GetScriptScope().name.len() == 0 )
			SendToConsole("kickid " + bot.GetScriptScope().userid + ";bot_add");;
	}

	if ( b )
		VS.EventQueue.AddEvent( PurgeTheUnfit, TICK_INTERVAL * 2 * i, this );
}

// distance between spawn points
function SetResolution( d )
{
	m_nResolution = d;
	MAX = _MAX / d;
	MIN = _MIN / d;
}

// true : spawn around the center
// false: spawn everywhere
function SetRange( b, m = true )
{
	if ( !b )
	{
		// hard set values, dependant of the map
		_MAX = 896;
		_MIN = 384;

		Ent("t2").__KeyValueFromString( "color",CL_WHITE );
		if (m) Chat( m_szChatPrefix + txt.yellow + "Enemies can now spawn everywhere" );
	}
	else
	{
		// if _MAX == _MIN, spawn only one line
		_MAX = 384;
		_MIN = 384;

		Ent("t2").__KeyValueFromString( "color",CL_GREEN );
		if (m) Chat( m_szChatPrefix + txt.yellow + "Enemies will only spawn around you" );
	};

	if (m) Chat("");

	m_bRange = b;
	SetResolution( m_nResolution );
}


// Pick a random position vector
//
// xxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxx
// xx           xx
// xx           xx
// xx           xx
// xx           xx
// xx           xx
// xx     o     xx
// xx           xx
// xx           xx
// xx           xx
// xx           xx
// xx           xx
// xxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxx
//
// Alternatively, a more complex shape could be calculated
// and the positions could be added to a list,
// where random vectors could be picked to get random positions
//
function RandomPos()
{
	switch ( ::RandomInt(0,3) )
	{
		case 0: return::Vector( ::RandomInt(-MAX, MAX)*m_nResolution,::RandomInt( MIN, MAX)*m_nResolution,16 );
		case 1: return::Vector( ::RandomInt( MIN, MAX)*m_nResolution,::RandomInt(-MAX, MAX)*m_nResolution,16 );
		case 2: return::Vector( ::RandomInt(-MAX, MAX)*m_nResolution,::RandomInt(-MAX,-MIN)*m_nResolution,16 );
		case 3: return::Vector( ::RandomInt(-MAX,-MIN)*m_nResolution,::RandomInt(-MAX, MAX)*m_nResolution,16 );
	};
}

// place the bot and sound target (at head level)
// play the sound, enable sound timer
// until the bot is killed
function Process()
{
	if ( !m_bStarted )
		return;

	if ( m_bBlindMode )
		SendToConsole("r_screenoverlay\"tools/toolsblack\"");

	local v = RandomPos();

	local bot = GetBot();

	::Glow.Set( bot, Vector(255,78,78), 1, 4096.0 );

	bot.SetOrigin(v);
	::ENT.hTarget.SetOrigin( Vector(v.x,v.y,64) );
	::ENT.hTarget.EmitSound( GetSound() );

	::EntFireByHandle( ::ENT.hTimerSnd,"enable" );

	::EntFireByHandle( ::ENT.hTimerThink,"enable" );

	m_bSpawned = true;
}

// if m_nSoundsLen has a value,
// randomise the sounds in m_list_sounds.
// else use m_szSndCurr
function GetSound()
{
	if ( m_nSoundsLen ) return m_list_sounds[::RandomInt(0,m_nSoundsLen-1)];
	return m_szSndCurr;
}

function GetBot()
{
	// redundant?
	if ( m_list_bots.len() == 0 )
		return SendToConsole("mp_restartgame 1;echo\"No bot found\"");

	if ( m_bAimbotON )
	{
		// blank previous named bots
		// start measuring new
		local i; while( i = Ent("BOT",i) ) ::VS.SetName( i, "" );
		::VS.SetName( m_list_bots[0], "BOT" );
		::VS.SetMeasure( ::ENT.hBotEye, "BOT" );
	};

	return m_list_bots[0];
}

function SetSoundType( i, m = true )
{
	m_list_sounds.clear();

	switch( i )
	{
		// headshot
		case 2:
			m_list_sounds.append("Player.DamageHelmet");
			m_list_sounds.append("Player.DamageHeadShot");
			SetInterval_set(1.0);
			SetRange(0,0);
			break;

		case 0:
			m_szSndCurr = "Weapon_AK47.Single";
			SetInterval_set(0.2);
			SetRange(0,0);
			break;

		case 6:
			m_szSndCurr = "Weapon_M4A1.Single";
			SetInterval_set(0.2);
			SetRange(0,0);
			break;

		case 1:
			m_szSndCurr = "CT_Concrete.StepRight";
			SetInterval_set(0.3);
			SetRange(1,0);
			break;

		case 7:
			m_szSndCurr = "CT_SolidMetal.StepRight";
			SetInterval_set(0.3);
			SetRange(1,0);
			break;

		case 4:
			m_szSndCurr = "Flashbang.Bounce";
			SetInterval_set(0.5);
			break;

		case 5:
			m_szSndCurr = "Flashbang.Explode";
			SetInterval_set(1.5);
			break;
	};

	m_nSoundsLen = m_list_sounds.len();

	for( local j = 0; j <= 7; j++ )
	{
		local e = ::Ent("s"+j);
		if (e) e.__KeyValueFromString( "color", CL_WHITE );
		// else Msg("Entity <"+"s"+j+"> does not exist.\n");
	}

	::Ent("s"+i).__KeyValueFromString("color", CL_GREEN );
}

function ToggleBlindMode( b )
{
	if ( !b )
	{
		Ent("t1").__KeyValueFromString("color",CL_WHITE );
		Chat( m_szChatPrefix + txt.yellow + "Blind mode " + txt.lightred + "disabled" );
	}
	else
	{
		Ent("t1").__KeyValueFromString("color",CL_GREEN );
		Chat( m_szChatPrefix + txt.yellow + "Blind mode " + txt.lightgreen + "enabled" );
		if (!m_bAimHelper)Chat( m_szChatPrefix + txt.lightblue + "Suggested: " + txt.yellow + "enabling aim helper" );
	};

	Chat("");
	m_bBlindMode = b;
}

function ToggleAimHelper( b )
{
	if ( b )
	{
		Ent("t0").__KeyValueFromString("color",CL_GREEN );
		Chat( m_szChatPrefix + txt.yellow + "Vertical aim helper " + txt.lightgreen + "enabled" );
		::EntFireByHandle( ::ENT.hTimerAim,"enable" );
	}
	else
	{
		Ent("t0").__KeyValueFromString("color",CL_WHITE );
		Chat( m_szChatPrefix + txt.yellow + "Vertical aim helper " + txt.lightred + "disabled" );
		::VS.HideHudHint( ::g_hHudhint,::HPlayer );
		::EntFireByHandle( ::ENT.hTimerAim,"disable" );
	};

	Chat("");
	m_bAimHelper = b;
}

//--------------------------
// Hold-button to modify

function SetInterval(b)
{
	if ( b )
	{
		for ( local i = 9; i--; ) Chat(" ");
		Chat( m_szChatPrefix + txt.yellow + "Set the time between sounds playing." );
		Chat( m_szChatPrefix + txt.yellow + "Hold "+txt.lightgreen+"W"+txt.yellow+" to increase" );
		Chat( m_szChatPrefix + txt.yellow + "Hold "+txt.lightgreen+"S"+txt.yellow+" to decrease" );

		::VS.ShowHudHint( ::g_hHudhint,::HPlayer,m_fIntvlCurr );
		Ent("t3").__KeyValueFromString("color",CL_GREEN );

		::VS.OnTimer( ::ENT.hTimerThink,ThinkButton );
		::EntFireByHandle( ::ENT.hTimerThink,"enable" );
		::EntFireByHandle( ::ENT.hTimerLook,"disable" );
		::EntFireByHandle( ::ENT.hGameUI,"activate","",0.0,::HPlayer );
	}
	else
	{
		::VS.HideHudHint( ::g_hHudhint,::HPlayer );
		Ent("t3").__KeyValueFromString("color",CL_WHITE );

		::EntFireByHandle( ::ENT.hTimerThink,"disable" );
		::EntFireByHandle( ::ENT.hTimerLook,"enable" );
		::EntFireByHandle( ::ENT.hGameUI,"deactivate","",0.0,::HPlayer );
	};

	m_nCtrlIntvl = 0;
	m_nThinkCount = 0;
	m_bSettingUp = b;
}

// press W
function SetInterval_add(){ m_nCtrlIntvl =  1 }

// press S
function SetInterval_sub(){ m_nCtrlIntvl = -1 }

// release key
function SetInterval_rel(){ m_nCtrlIntvl =  0 }

function SetInterval_mod(f)
{
	::HPlayer.EmitSound("UIPanorama.container_weapon_ticker");

	local d = m_fIntvlCurr + f;

	// clamp
	if ( d < 0.1 ) return;

	::VS.ShowHudHint( ::g_hHudhint,::HPlayer,d );

	SetInterval_set(d);
}

function SetInterval_set(d)
{
	m_fIntvlCurr = d;
	::ENT.hTimerSnd.__KeyValueFromFloat("refiretime", d );
}

function ThinkButton()
{
	if ( ++m_nThinkCount > 6 ) m_nThinkCount = 0;
	else return;

	if ( !m_nCtrlIntvl ) return;

	if ( m_nCtrlIntvl == 1 ) SetInterval_mod(0.2);
	else if ( m_nCtrlIntvl == -1 ) SetInterval_mod(-0.2);;
}

//--------------------------

// workaround,
// can't be bothered to fix the problem
function Start()
{
	Ent("d").EmitSound("Doors.Metal.Move1");
	Chat( m_szChatPrefix + txt.purple + "START" );

	::EntFireByHandle( ::ENT.hTimerLook,"disable" );

	// the only benefit of the training gamemode is the steam rich presence
	// is it even worth when it causes so many problems?
	SendToConsole("game_mode 0;game_type 2;r_cleardecals");

	VS.EventQueue.AddEvent( _Start, 0.17, this );
}

function _Start()
{
	// ScriptSetRadarHidden(true);
	SendToConsoleServer("sv_disable_radar 1");

	if ( m_bSettingUp )
		SetInterval(false);
	m_bStarted = true;

	if ( !SetupBots() ) return Msg("\nERROR\n\n");

	::VS.OnTimer( ::ENT.hTimerThink,BotAng );
	::EntFireByHandle( ::ENT.hTimerThink,"enable" );
	if ( m_bAimHelper ) ::EntFireByHandle( ::ENT.hTimerAim,"enable" );
	::EntFire("d","open");

	::VS.EventQueue.AddEvent( Process, RandomFloat(1.5,2.9), this );
}

function Stop()
{
	if ( !m_bStarted ) if ( m_bSettingUp ) return SetInterval(false); else return;;

	Ent("d").EmitSound("Doors.Metal.Move1");

	Chat( m_szChatPrefix + txt.purple + "STOP" );

	m_bSpawned = false;
	m_bStarted = false;
	Kill( GetBot() );
	// ScriptSetRadarHidden(false);
	SendToConsoleServer("sv_disable_radar 0");
	SendToConsole("r_screenoverlay\"\"");
	::EntFire("d","close");
	::EntFireByHandle( ::ENT.hTimerSnd,"disable" );
	::EntFireByHandle( ::ENT.hTimerThink,"disable" );
	::EntFireByHandle( ::ENT.hTimerAim,"disable" );
	::EntFireByHandle( ::ENT.hAIMBOT,"disable" );
	m_bAimbotON = false;

	::EntFireByHandle( ::ENT.hTimerLook,"enable" );

	SendToConsole("game_mode 0;game_type 3;r_cleardecals");
}

// fixme this mess
function SetupBots()
{
	m_list_bots.clear();

	local bots = ::VS.GetPlayersAndBots()[1];

	if ( bots.len() == 0 )
		return SendToConsole("echo\" === NO BOT FOUND\";bot_add;bot_add;bot_add;bot_add;bot_add;bot_add");

	foreach( bot in bots )
	{
		// error checks
		// FIXME
		if ( !bot.GetScriptScope() )
			VS.EventQueue.AddEvent( PurgeTheUnfit, 0, this );

		// bot is alive
		else if ( bot.GetHealth() )
		{
			bot.SetHealth(1);
			m_list_bots.append(bot);
		}
		// Bot not spawned yet,
		// but it's okay because we have more bots in the storage, right?
		else if ( GetDeveloperLevel() >= 1 )
			Msg( " !!! YOU KILLED " + bot.GetScriptScope().name.toupper() + "\n" );;;
	};

	// cheap workaround to spawn all bots
	if ( m_list_bots.len() == 0 )
		return SendToConsole("mp_restartgame 1;echo\" === Empty list\"");

	return true;
}

function Kill( ply )
{
	::EntFireByHandle( ply, "sethealth", 0 );
}

// Add the bot back to available bots list
::OnGameEvent_player_spawn <- function(data)
{
	if ( !m_bStarted )
		return;

	if ( data.teamnum == 2 )
	{
		local e = ::VS.GetPlayerByUserid(data.userid);
		if (!e)return; // can't be bothered to fix
		e.SetHealth(1);
		m_list_bots.append(e);
	};
}.bindenv(this);

function OnKill( ent )
{
	if ( !m_bStarted )
		return;

	// "You killed X"
	::ENT.hGametext.__KeyValueFromString( "message", "You killed " + ent.GetScriptScope().name );
	::EntFireByHandle( ::ENT.hGametext, "display", "", 0.0, ::HPlayer );

	if ( m_bBlindMode ) SendToConsole("r_screenoverlay\"\"");

	// remove the bot from the (available bots) list,
	// the bot will be added back when it spawns
	foreach( i, h in m_list_bots ) if ( h == ent )
		m_list_bots.remove(i);

	// stop playing sound
	::EntFireByHandle( ::ENT.hTimerSnd,"disable" );

	::EntFireByHandle( ::ENT.hTimerThink,"disable" );

	m_bSpawned = false;

	::Glow.Disable(ent);

	// next
	::VS.EventQueue.AddEvent( Process, ::RandomFloat(0.4,1.2), this );
}

::OnGameEvent_player_jump <- Stop.bindenv(this);

::OnGameEvent_player_death <- function(e)
{
	OnKill( ::VS.GetPlayerByUserid( e.userid ) )
}.bindenv(this);

function PlaySound()
{
	::ENT.hTarget.EmitSound( GetSound() );
}

function CheckAng()
{
	local x = ::HPlayerEye.GetAngles().x;

	if ( x > 4 )
		::VS.ShowHudHint( ::g_hHudhint, ::HPlayer, "You are aiming too low!" );
	else if ( x < (-0.1) )
		::VS.ShowHudHint( ::g_hHudhint, ::HPlayer, "You are aiming too high!" );
	else ::VS.HideHudHint( ::g_hHudhint, ::HPlayer );;
}

// bot look at map origin 0,0,0
// the hitboxes are desynced for a second or two when they spawn
function BotAng()
{
	local bot = GetBot();

	if (!bot) return;

	local yaw = ::VS.GetAngle2D( bot.EyePosition(), vec3_origin );

	bot.SetAngles(0,yaw,0);
}

m_szChatPrefix <- txt.orange + "● ";

function ToggleTeam()
{
	local t = ::HPlayer.GetTeam();

	if ( t == T ) SetTeam(CT);
	else if ( t == CT ) SetTeam(T);;
}

function Equip( input )
{
	if (input==weapon.hkp2000||input==weapon.usp_silencer||input==weapon.fn57||input==weapon.famas||input==weapon.m4a1||input==weapon.m4a1_silencer||input==weapon.aug||input==weapon.scar20||input==weapon.mag7||input==weapon.mp9)
		SetTeam(CT);
	else SetTeam(T);

	::EntFire( "equip", "triggerforactivatedplayer", "weapon_"+input, 0.0, ::HPlayer );

	::VS.EventQueue.AddEvent( SetTeam, 0, [this, CT] );
}

function SetTeam(i)
{
	::EntFire( "texture_c", "SetTextureIndex", (i-1) );
	::HPlayer.__KeyValueFromInt( "teamnumber", i );
}

// See the standalone aimbot.nut script for a more advanced version
// github.com/samisalreadytaken/vscripts
function ThinkAimbot()
{
	if ( !m_bSpawned ) return;

	local bot  = GetBot();
	local head = ::VS.TraceDir( bot.GetAttachmentOrigin(15), ::ENT.hBotEye.GetForwardVector(), -4 ).GetPos();
	local ang  = ::VS.GetAngle( ::HPlayer.EyePosition(), head );

	::HPlayer.SetAngles(ang.x,ang.y,0);
}

// When the aimbot is on, and the player kills every bot too fast,
// without letting them respawn, the game will restart
function EnableAimbot()
{
	::EntFireByHandle( ::ENT.hAIMBOT, "enable" );
	Chat( m_szChatPrefix + txt.green + "Aimbot enabled" );
	::HPlayer.EmitSound("UIPanorama.container_weapon_ticker");
	m_bAimbotON = true;
}

//-----------------------------------------------------------------------
//-----------------------------------------------------------------------

Music <-
{
	valve_csgo_01 = "Valve 01",
	valve_csgo_02 = "Valve 02",
	feedme_01 = "Feed Me, High Noon",
	austinwintory_01 = "Austin Wintory, Desert Fire",
	skog_01 = "Skog, Metal",
	noisia_01 = "Noisia, Sharpened",
	robertallaire_01 = "Robert Allaire, Insurgency",
	danielsadowski_01 = "Daniel Sadowski, Crimson Assault",
	seanmurray_01 = "Sean Murray, A*D*8",
	sasha_01 = "Sasha, LNOE",
	dren_01 = "dren, Death's Head Demolition",
	midnightriders_01 = "Midnight Riders, All I Want for Christmas",
	hotlinemiami_01 = "Various Artists, Hotline Miami",
	danielsadowski_02 = "Daniel Sadowski, Total Domination",
	damjanmravunac_01 = "Damjan Mravunac, The Talos Principle",
	mateomessina_01 = "Mateo Messina, For No Mankind",
	mattlange_01 = "Matt Lange, IsoRhythm",
	awolnation_01 = "AWOLNATION, I Am",
	mordfustang_01 = "Mord Fustang, Diamonds",
	danielsadowski_03 = "Daniel Sadowski, The 8-Bit Kit",
	newbeatfund_01 = "New Beat Fund, Sponge Fingerz",
	lenniemoore_01 = "Lennie Moore, Java Havana Funkaloo",
	proxy_01 = "Proxy, Battlepack",
	kitheory_01 = "Ki:Theory, MOLOTOV",
	darude_01 = "Darude, Moments CSGO",
	michaelbross_01 = "Michael Bross, Invasion!",
	beartooth_01 = "Beartooth, Disgusting",
	kellybailey_01 = "Kelly Bailey, Hazardous Environments",
	ianhultquist_01 = "Ian Hultquist, Lion's Mouth",
	skog_02 = "Skog, II-Headshot",
	troelsfolmann_01 = "Troels Folmann, Uber Blasto Phone",
	skog_03 = "Skog, III-Arena",
	hundredth_01 = "Hundredth, FREE",
	beartooth_02 = "Beartooth, Aggressive",
	roam_01 = "Roam, Backbone",
	twinatlantic_01 = "Twin Atlantic, GLA",
	neckdeep_01 = "Neck Deep, Life's Not Out To Get You",
	blitzkids_01 = "Blitz Kids, The Good Youth",
	theverkkars_01 = "The Verkkars, EZ4ENCE",
	halo_01 = "Halo, The Master Chief Collection",
	halflife_alyx_01 = "Half-Life: Alyx, Anti-Citizen"
}

MusicI <-
[
	"valve_csgo_01",
	"valve_csgo_02",
	"feedme_01",
	"austinwintory_01",
	"skog_01",
	"noisia_01",
	"robertallaire_01",
	"danielsadowski_01",
	"seanmurray_01",
	"sasha_01",
	"dren_01",
	"midnightriders_01",
	"hotlinemiami_01",
	"danielsadowski_02",
	"damjanmravunac_01",
	"mateomessina_01",
	"mattlange_01",
	"awolnation_01",
	"mordfustang_01",
	"danielsadowski_03",
	"newbeatfund_01",
	"lenniemoore_01",
	"proxy_01",
	"kitheory_01",
	"darude_01",
	"michaelbross_01",
	"beartooth_01",
	"kellybailey_01",
	"ianhultquist_01",
	"skog_02",
	"troelsfolmann_01",
	"skog_03",
	"hundredth_01",
	"beartooth_02",
	"roam_01",
	"twinatlantic_01",
	"neckdeep_01",
	"blitzkids_01",
	"theverkkars_01",
	"halo_01",
	"halflife_alyx_01"
];

// I should've made this into one table but
// I don't want to rewrite or copy-paste all of these.
// It's not too bad anyway.

// Access ID ("valve_csgo_01") from index (38)
//    MusicI[ idx ]
// Access the description from index
//    Music[ MusicI[ idx ] ]

m_szMusicKitCurrID <- MusicI[0];
m_szMusicKitCurr <- Music[m_szMusicKitCurrID];
m_szMusicKitSoundCurr <- "";
m_hCurrMusicKit <- Ent("m0");
m_nMusicType <- 0;
TICK_INTERVAL <- FrameTime();
m_flCountdown <- 10.0;

function PickMusicKit(idx)
{
	m_szMusicKitCurrID = MusicI[idx];
	m_szMusicKitCurr = Music[m_szMusicKitCurrID];

	m_hCurrMusicKit = Ent("m"+idx);

	Chat( m_szChatPrefix + "Picked " + txt.white + m_szMusicKitCurr );
	Msg( m_szChatPrefix + "Picked " + m_szMusicKitCurr + "\n" );

	SendToConsole("r_cleardecals");
}

function PlayMusicKit()
{
	StopMusicKitAll();

	Chat( txt.lightgreen + "▶ " + txt.yellow + "Now playing " + txt.white + m_szMusicKitCurr );
	Msg( "▶ Now playing " + m_szMusicKitCurr + "\n" );

	if ( m_nMusicType == 0 )
	{
		// these are affected by the client's music settings, but the direct file playing cannot be stopped
		m_szMusicKitSoundCurr = "Music.BombTenSecCount." + m_szMusicKitCurrID;
		m_flCountdown = 10.0;
		::EntFireByHandle( ::ENT.hTimer10, "enable" );
	}
	else if ( m_nMusicType == 1 )
	{
		m_szMusicKitSoundCurr = "Musix.HalfTime." + m_szMusicKitCurrID;
	};;

	::HPlayer.EmitSound(m_szMusicKitSoundCurr);
	SendToConsole("r_cleardecals");
}

function StopMusicKit()
{
	Chat( txt.lightred + "■ " + txt.yellow + "Stopped playing" );
	Msg("■ Stopped playing\n");

	::EntFireByHandle( ::ENT.hTimer10, "disable" );
	::ENT.hMsgTen.__KeyValueFromString( "message", "10.0000" );

	::HPlayer.StopSound(m_szMusicKitSoundCurr);
	SendToConsole("r_cleardecals");
}

// main menu musics can stack, stop all if any are playing.
// Alternatively I could keep track of playing tracks, (TODO)
// but there's no performance worry in this map, so this is fine.
function StopMusicKitAll()
{
	foreach( k in MusicI ) ::HPlayer.StopSound("Musix.HalfTime." + k);
	::EntFireByHandle( ::ENT.hTimer10, "disable" );
	::ENT.hMsgTen.__KeyValueFromString( "message", "10.0000" );
}

function SetMusicType()
{
	m_nMusicType++;

	m_nMusicType %= 2;

	// TODO: add all types
	// switch( m_nMusicType ){}
	if ( m_nMusicType == 0 )
	{
		Chat( m_szChatPrefix + "Music type: " + txt.yellow + "Bomb 10 second count" );
		Msg( m_szChatPrefix + "Music type: Bomb 10 second count\n" );

		::ENT.hMsgTen.__KeyValueFromInt( "textsize", 10 );
		::ENT.hMsgTen.__KeyValueFromString( "message", "10.0000" );
	}
	else if ( m_nMusicType == 1 )
	{
		Chat( m_szChatPrefix + "Music type: " + txt.yellow + "Main menu" );
		Msg( m_szChatPrefix + "Music type: Main menu\n" );

		::ENT.hMsgTen.__KeyValueFromInt( "textsize", 0 );
		::EntFireByHandle( ::ENT.hTimer10, "disable" );
		::ENT.hMsgTen.__KeyValueFromString( "message", "10.0000" );
	};;

	SendToConsole("r_cleardecals");
}

function Tick()
{
	m_flCountdown -= TICK_INTERVAL;

	::ENT.hMsgTen.__KeyValueFromString( "message", ::format("%.5f",m_flCountdown) );

	if ( m_flCountdown <= 0.0 )
	{
		::EntFireByHandle( ::ENT.hTimer10, "disable" );
		::ENT.hMsgTen.__KeyValueFromString( "message", "0.00000" );
	};
}

function Looking()
{
	// if found entity named "m*"
	local ent = ::VS.TraceDir(::HPlayer.EyePosition(), ::HPlayerEye.GetForwardVector()).GetEntByName("m*", 24);

	if ( ent )
	{
		local idx = ent.GetName().slice(1);

		if ( idx.len() && idx[0] < 58 )
		{
			::VS.DrawEntityBBox( 0.15, ent );
			::VS.ShowHudHint( ::g_hHudhint, ::HPlayer, Music[MusicI[idx.tointeger()]] );
		};
	}
	else if ( !m_bAimHelper ) ::VS.HideHudHint( ::g_hHudhint, ::HPlayer );;

	if ( m_hCurrMusicKit.IsValid() )
		::VS.DrawEntityBBox( 0.15, m_hCurrMusicKit, 128, 255, 128 );
}

// Set the bot and player teams manually instead of relying on server settings
::OnGameEvent_player_team <- function(D)
{
	if ( !D.disconnect )
	{
		if ( !D.isbot )
		{
			if ( D.team != 3 )
			{
				local p = ::VS.GetPlayerByUserid( D.userid );

				if (p)
				{
					p.SetTeam(3);
				};
			};
		}
		else
		{
			if ( D.team != 2 )
			{
				local p = ::VS.GetPlayerByUserid( D.userid );

				if (p)
				{
					p.SetTeam(2);
				};
			};
		};
	};
}
