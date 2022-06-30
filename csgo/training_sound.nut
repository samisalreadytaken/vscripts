//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Directional Sound Training Map ( + music kits )
//
//------------------------------

IncludeScript("vs_library");
IncludeScript("aimbot");

enum weapon
{
	glock = "weapon_glock",
	hkp2000 = "weapon_hkp2000",
	usp_silencer = "weapon_usp_silencer",
	elite = "weapon_elite",
	p250 = "weapon_p250",
	tec9 = "weapon_tec9",
	fn57 = "weapon_fn57",
	deagle = "weapon_deagle",
	galilar = "weapon_galilar",
	famas = "weapon_famas",
	ak47 = "weapon_ak47",
	m4a1 = "weapon_m4a1",
	m4a1_silencer = "weapon_m4a1_silencer",
	ssg08 = "weapon_ssg08",
	aug = "weapon_aug",
	sg556 = "weapon_sg556",
	awp = "weapon_awp",
	scar20 = "weapon_scar20",
	g3sg1 = "weapon_g3sg1",
	nova = "weapon_nova",
	xm1014 = "weapon_xm1014",
	mag7 = "weapon_mag7",
	m249 = "weapon_m249",
	negev = "weapon_negev",
	mac10 = "weapon_mac10",
	mp9 = "weapon_mp9",
	mp7 = "weapon_mp7",
	ump45 = "weapon_ump45",
	p90 = "weapon_p90",
	bizon = "weapon_bizon",
	mp5sd = "weapon_mp5sd",
	sawedoff = "weapon_sawedoff",
	cz75a = "weapon_cz75a"
}

const TEAM_T = 2;;
const TEAM_CT = 3;;

const CLR_GREEN = "171 255 130 255";;
const CLR_WHITE = "255 255 255 255";;

// TextColor.Immortal
const CHAT_PREFIX = "\x10● ";;

const SND_WALLS_MOVE = "Doors.Metal.Move1";;
const SND_HIT = "ui/hitsound.wav";;
const SND_CRITHIT = "player/crit_hit.wav";; // "TFPlayer.CritHit"

const BOT_HEALTH = 1;;

enum SOUNDTYPE
{
	AK47_SINGLE			= 0,
	M4A4_SINGLE			= 6,
	HEADSHOT			= 2,
	STEP_CONCRETE		= 1,
	STEP_METAL			= 7,
	FLASHBANG_BOUNCE	= 4,
	FLASHBANG_EXPLODE	= 5
}

::TR_SND <- this;

m_flRadiusMax		<- -1.0;
m_flRadiusMin		<- -1.0;
m_fIntvlCurr		<- 1.0;
m_bBlindMode		<- false;
m_bStarted			<- false;
m_bSpawned			<- false;
m_bAimHelper		<- false;
m_bRange			<- false;
m_bAtControls		<- false;
m_nCtrlIntvl		<- 0;
m_nThinkCount		<- 0;
m_Bots				<- [];
m_Sounds			<- [];
m_szSndCur			<- null;
m_bAimLockEnabled	<- false;
m_pCritSpawner		<- null;
player				<- null;
m_hPlatformWalls	<- null;
m_hStopText			<- null;
m_hCntdnMsg			<- null;

vec3_origin <- Vector();
Fmt <- format;

function Precache()
{
		// sound target
		// alternatively the bot's origin could be used,
		// but using an external entity allows playing the sound
		// even when the bot is not placed.
		g_hTarget <- VS.CreateEntity( "info_target" ).weakref();

		//g_hVisBlocker <- VS.CreateEntity( "info_target" ).weakref();
		//g_hVisBlocker.SetOrigin( Ent("d").GetOrigin() - Vector(0,0,16) );
		//g_hVisBlocker.SetModel( Ent("d").GetModelName() );
		//g_hVisBlocker.__KeyValueFromInt( "effects", 32 );

		// play sound
		g_hTimerSnd <- VS.Timer( 1, m_fIntvlCurr, PlayTargetSoundThink, this, 0, 1 ).weakref();

		g_hTimerThink <- VS.Timer( 1, 0.0, Think, this, 0, 1 ).weakref();

		// Music kit 10 second countdown timer
		g_hTimer10 <- VS.Timer( 1, 0.0, Tick, this, 0, 1 ).weakref();

		// "You killed X"
		g_hGameText <- VS.CreateEntity( "game_text",
		{
			channel = 1,
			color = "255 255 255",
			color2 = "250 250 250",
			fadeout = 0.4,
			holdtime = 1.4,
			x = 0.435,
			y = 0.7
		},true ).weakref();

		// helper indicator
		g_hGameText2 <- VS.CreateEntity( "game_text",
		{
			channel = 2,
			color = "255 255 255",
			color2 = "250 250 250",
			fadeout = 0.0,
			holdtime = FrameTime() * 2,
			message = "⬤"
		},true ).weakref();

		// hud hint
		g_hHudHint <- VS.CreateEntity( "env_hudhint",null,true ).weakref();

		// Team coin
		VS.CreateEntity( "env_texturetoggle",{targetname = "texture_c", target="c"},true ).weakref();

		VS.CreateEntity( "game_player_equip",{targetname = "equip", spawnflags = 5, weapon_knife = 1},true ).weakref();

	PrecacheScriptSound( SND_WALLS_MOVE );
	PrecacheScriptSound( SND_HIT );
	PrecacheScriptSound( SND_CRITHIT );

	// these should already be set in the map config
	SendToConsoleServer("sv_cheats 1;achievement_disable 1;mp_autokick 0;mp_limitteams 0;mp_autoteambalance 0;sv_disable_radar 0;sv_infinite_ammo 1;mp_ignore_round_win_conditions 1;mp_teammates_are_enemies 1;mp_solid_teammates 0;mp_respawn_immunitytime 0;mp_give_player_c4 0;mp_respawn_on_death_t 1;mp_respawn_on_death_ct 1;weapon_accuracy_nospread 0;sv_auto_adjust_bot_difficulty 0");
	SendToConsoleServer("mp_buy_anywhere 1;mp_buytime 216000;mp_maxmoney 32000;mp_startmoney 32000;mp_death_drop_gun 0;mp_playercashawards 0;mp_freezetime 0;mp_maxrounds 1;mp_roundtime 60");
}

function OnPostSpawn()
{
	Msg("TR_SND spawn\n");
}


// CT spawned
function Init()
{
	player = ToExtendedPlayer( VS.GetPlayerByIndex(1) );

	SendToConsole("r_screenoverlay\"\"");

	// default values
	SetRange(0,0);
	SetSoundType(0,0);

	Equip( weapon.m4a1 );
	Equip( weapon.usp_silencer );

	for ( local i = 9; i--; ) Chat("");

	Chat( TextColor.Achievement + "● "+TextColor.Uncommon+"Welcome, " + player.GetPlayerName() + "!" );
	Msg( "\n\nWelcome, " + player.GetPlayerName() + "! ["+ player.GetNetworkIDString() +"]\n" );
	Chat( "" );

	EntFireByHandle( g_hTimerThink, "Enable" );

	// -------------------------------------------------------------------

	local template = Ent("crit_template");
	template.ValidateScriptScope();
	local sc = template.GetScriptScope();
	sc.PreSpawnInstance <- dummy;
	sc.PostSpawn <- __PostSpawn;
	m_pCritSpawner = Ent("crit_spawner");

	// -------------------------------------------------------------------

	m_hPlatformWalls = Ent("d");
	m_hStopText = Ent("stoptext");

	// -------------------------------------------------------------------
	// must be executed every round, so do it on player spawn
	if ( !m_hCurrMusicKit.IsValid() )
		m_hCurrMusicKit = Ent("m0");

	foreach( i, v in MusicI )
		Ent( "m"+i ).__KeyValueFromString( "OnPressed", "!self,RunScriptCode,TR_SND.PickMusicKit("+(i++)+")" );

	m_hCntdnMsg = Ent("msg10");

	// -------------------------------------------------------------------

	// in case server settings are not set
	// the map may already be broken if these were not set
	SendToConsole("game_mode 0;game_type 3;mp_warmup_end;mp_warmuptime 0;bot_join_after_player 0;bot_quota 6;bot_quota_mode fill;bot_stop 1;bot_dont_shoot 1;bot_chatter off;bot_knives_only;bot_join_after_player 1");
}


// true : spawn close
// false: spawn everywhere
function SetRange( b, m = true )
{
	if ( !b )
	{
		// hard set values, dependant on the map
		m_flRadiusMax = 960.0;
		m_flRadiusMin = 320.0;

		Ent("t2").__KeyValueFromString( "color",CLR_WHITE );
		if (m) Chat( CHAT_PREFIX + TextColor.Gold + "Enemies will spawn everywhere" );
	}
	else
	{
		m_flRadiusMax = 320.0;
		m_flRadiusMin = 320.0;

		Ent("t2").__KeyValueFromString( "color",CLR_GREEN );
		if (m) Chat( CHAT_PREFIX + TextColor.Gold + "Enemies will only spawn nearby" );
	};

	m_bRange = b;
}

// Pick a random position vector
//
function GetRandomPosition()
{
	local a = RandomFloat( -PI, PI );
	return Vector(
		cos( a ) * RandomFloat( m_flRadiusMin, m_flRadiusMax ),
		sin( a ) * RandomFloat( m_flRadiusMin, m_flRadiusMax ),
		0.5
	);
}

// place the bot and sound target
// play the sound, enable sound timer
function Process()
{
	if ( !m_bStarted )
		return;

	local pos = GetRandomPosition();
	local bot = GetBot();
	if ( !bot || !bot.IsValid() )
		return Stop();

	if ( m_bBlindMode )
	{
		bot.SetEffects( 32 );
	}
	else
	{
		bot.SetEffects( 0 );
	}

	bot.SetOrigin(pos);

	if ( m_bAimLockEnabled )
		aimbot_add_p2( bot );

	local sndPos = pos*1;
	sndPos.z = 64.0;
	g_hTarget.SetOrigin( sndPos );
	g_hTarget.EmitSound( GetSound() );
	EntFireByHandle( g_hTimerSnd, "Enable" );

	m_bSpawned = true;
}

// if m_nSounds is not empty, randomise from it.
// else use m_szSndCur
function GetSound()
{
	if ( 0 in m_Sounds )
		return m_Sounds[ RandomInt( 0, m_Sounds.len()-1 ) ];
	return m_szSndCur;
}

function GetBot()
{
	if ( 0 in m_Bots )
		return m_Bots[0];
	return Msg("No bot found\n");
}

function SetSoundType( i, m = true )
{
	m_Sounds.clear();

	switch( i )
	{
		case SOUNDTYPE.HEADSHOT:
			m_Sounds.append("Player.DamageHelmet");
			m_Sounds.append("Player.DamageHeadShot");
			SetInterval_set(1.0);
			SetRange(0,0);
			break;

		case SOUNDTYPE.AK47_SINGLE:
			m_szSndCur = "Weapon_AK47.Single";
			SetInterval_set(0.2);
			SetRange(0,0);
			break;

		case SOUNDTYPE.M4A4_SINGLE:
			m_szSndCur = "Weapon_M4A1.Single";
			SetInterval_set(0.2);
			SetRange(0,0);
			break;

		case SOUNDTYPE.STEP_CONCRETE:
			m_szSndCur = "CT_Concrete.StepRight";
			SetInterval_set(0.3);
			SetRange(1,0);
			break;

		case SOUNDTYPE.STEP_METAL:
			m_szSndCur = "CT_SolidMetal.StepRight";
			SetInterval_set(0.3);
			SetRange(1,0);
			break;

		case SOUNDTYPE.FLASHBANG_BOUNCE:
			m_szSndCur = "Flashbang.Bounce";
			SetInterval_set(0.5);
			break;

		case SOUNDTYPE.FLASHBANG_EXPLODE:
			m_szSndCur = "Flashbang.Explode";
			SetInterval_set(1.5);
			break;
	};

	for( local j = 0; j <= 7; j++ )
	{
		local e = ::Ent("s"+j);
		if (e) e.__KeyValueFromString( "color", CLR_WHITE );
		// else Msg("Entity <"+"s"+j+"> does not exist.\n");
	}

	::Ent("s"+i).__KeyValueFromString("color", CLR_GREEN );
}

function SetBlindMode( b )
{
	if ( !b )
	{
		Ent("t1").__KeyValueFromString("color",CLR_WHITE );
		Chat( CHAT_PREFIX + TextColor.Gold + "Blind mode " + TextColor.Penalty + "disabled" );
	}
	else
	{
		Ent("t1").__KeyValueFromString("color",CLR_GREEN );
		Chat( CHAT_PREFIX + TextColor.Gold + "Blind mode " + TextColor.Achievement + "enabled" );

		if ( !m_bAimHelper )
			Chat( CHAT_PREFIX + TextColor.Uncommon + "Suggested: " + TextColor.Gold + "enabling aim helper" );
	};

	m_bBlindMode = b;
}

function SetAimHelper( b )
{
	if ( b )
	{
		Ent("t0").__KeyValueFromString("color",CLR_GREEN );
		Chat( CHAT_PREFIX + TextColor.Gold + "Aim helper " + TextColor.Achievement + "enabled" );
	}
	else
	{
		Ent("t0").__KeyValueFromString("color",CLR_WHITE );
		Chat( CHAT_PREFIX + TextColor.Gold + "Aim helper " + TextColor.Penalty + "disabled" );
		HideHudHint();
	};

	m_bAimHelper = b;
}

function SetInterval( b )
{
	if ( b )
	{
		player.SetMoveType(0);
		player.SetVelocity( vec3_origin );

		Chat( CHAT_PREFIX + TextColor.Gold + "Set the time between sounds playing." );
		Chat( CHAT_PREFIX + TextColor.Gold + "Hold "+TextColor.Achievement+"W"+TextColor.Gold+" to increase" );
		Chat( CHAT_PREFIX + TextColor.Gold + "Hold "+TextColor.Achievement+"S"+TextColor.Gold+" to decrease" );

		ShowHudHint( m_fIntvlCurr );
		Ent("t3").__KeyValueFromString("color",CLR_GREEN );

		VS.SetInputCallback( player, "+forward", function(...){ return SetInterval_add() }, this );
		VS.SetInputCallback( player, "+back", function(...){ return SetInterval_sub() }, this );
		local unpressed = function(...){ return SetInterval_rel() };
		VS.SetInputCallback( player, "-forward", unpressed, this );
		VS.SetInputCallback( player, "-back", unpressed, this );
	}
	else
	{
		player.SetMoveType(2);

		HideHudHint();
		Ent("t3").__KeyValueFromString("color",CLR_WHITE );

		VS.SetInputCallback( player, "+forward", null, this );
		VS.SetInputCallback( player, "+back", null, this );
		VS.SetInputCallback( player, "-forward", null, this );
		VS.SetInputCallback( player, "-back", null, this );
	};

	m_nCtrlIntvl = 0;
	m_nThinkCount = 0;
	m_bAtControls = b;
}

// press W
function SetInterval_add(){ m_nCtrlIntvl =  1 }

// press S
function SetInterval_sub(){ m_nCtrlIntvl = -1 }

// release key
function SetInterval_rel(){ m_nCtrlIntvl =  0 }

function SetInterval_mod(f)
{
	player.EmitSound("UIPanorama.container_weapon_ticker");

	local d = m_fIntvlCurr + f;

	// clamp
	if ( d < 0.1 )
		return;

	ShowHudHint( Fmt( "%.1f", d ) );

	SetInterval_set(d);
}

function SetInterval_set(d)
{
	m_fIntvlCurr = d;
	g_hTimerSnd.__KeyValueFromFloat("refiretime", d );
}

function ThinkButton()
{
	if ( ++m_nThinkCount <= 6 )
		return;

	m_nThinkCount = 0;

	if ( !m_nCtrlIntvl )
		return;

	if ( m_nCtrlIntvl == 1 )
	{
		SetInterval_mod(0.2);
	}
	else if ( m_nCtrlIntvl == -1 )
	{
		SetInterval_mod(-0.2);
	}
}

//--------------------------

function Start()
{
	Chat( CHAT_PREFIX + TextColor.Purple + "START" );

	// the only benefit of the training gamemode is the steam rich presence.
	// is it even worth when it causes so many problems?
	// SendToConsole("game_mode 0;game_type 2;r_cleardecals");

	// ScriptSetRadarHidden(true);
	SendToConsoleServer("sv_disable_radar 1");

	if ( m_bAtControls )
		SetInterval(false);
	m_bStarted = true;

	m_hPlatformWalls.EmitSound(SND_WALLS_MOVE);
	EntFireByHandle( m_hPlatformWalls, "Open" );

	m_hStopText.__KeyValueFromInt( "rendermode", 0 );

	VS.EventQueue.AddEvent( Process, RandomFloat(1.5,2.5), this );
}

function Stop()
{
	if ( !m_bStarted )
	{
		if ( m_bAtControls )
			return SetInterval(false);

		return;
	};

	m_hStopText.__KeyValueFromInt( "rendermode", 10 );
	m_hPlatformWalls.EmitSound(SND_WALLS_MOVE);

	Chat( CHAT_PREFIX + TextColor.Purple + "STOP" );

	m_bSpawned = false;
	m_bStarted = false;

	if ( player.GetOrigin().Length() > 132.0 )
		player.SetOrigin( Vector(0,0,2) );

	Kill( GetBot() );
	// ScriptSetRadarHidden(false);
	SendToConsoleServer("sv_disable_radar 0");
	SendToConsole("r_screenoverlay\"\"");
	EntFireByHandle( m_hPlatformWalls, "Close" );
	EntFireByHandle( g_hTimerSnd, "Disable" );

	if ( m_bAimLockEnabled )
	{
		m_bAimLockEnabled = false;
		aimbot_clear();
	}

	// EntFire( "item_cash", "Kill", "", 1.0 );

	SendToConsole("game_mode 0;game_type 3;r_cleardecals");
}

function Kill( ply )
{
	if ( ply )
		return EntFireByHandle( ply.self, "SetHealth", 0 );
}

// Add bots to available bots list
VS.ListenToGameEvent( "player_spawn", function(ev)
{
	local bot = ToExtendedPlayer( VS.GetPlayerByUserid( ev.userid ) );
	if ( !bot || !bot.IsBot() || !bot.GetHealth() )
		return;

	bot.SetEffects( 32 );
	bot.SetMoveType(0);
	bot.SetHealth( BOT_HEALTH );

	local bIn = false;
	foreach( p in m_Bots )
		if ( p == bot )
		{
			bIn = true;
			break;
		};

	if ( !bIn )
		m_Bots.append(bot);

	Msg("\tBOT " + bot.GetPlayerName() + " spawned\n");

}.bindenv(this), "" );

VS.ListenToGameEvent( "player_disconnect", function(ev)
{
	Msg("\tBOT "+ev.name+" left the game\n");

	for ( local i = m_Bots.len(); i--; )
	{
		if ( !m_Bots[i].IsValid() )
		{
			m_Bots.remove(i);
		}
	}
}.bindenv(this), "" );

VS.ListenToGameEvent( "player_jump", Stop.bindenv(this), "" );


m_pPrevHitmarkerEvent <- null;

local InvalidateHitmarker = function()
{
	m_pPrevHitmarkerEvent = null;
	SendToConsole("r_screenoverlay\"\"");
}

VS.ListenToGameEvent( "player_hurt", function(ev) : (InvalidateHitmarker)
{
	// suicide
	if ( ev.attacker == ev.userid )
		return;

	player.EmitSound( SND_HIT );

	if ( !m_bBlindMode )
	{
		SendToConsole("r_screenoverlay\"ui/hitmarker\"");

		if ( m_pPrevHitmarkerEvent )
			VS.EventQueue.CancelEventsByInput( InvalidateHitmarker );
		m_pPrevHitmarkerEvent = VS.EventQueue.AddEvent( InvalidateHitmarker, 0.1, this );

		// crit
		if ( ev.hitgroup == 1 &&
			ev.dmg_health > 75 &&
			!RandomInt(0,7) ) // do it on chance so it doesn't get annoying
		{
			local bot = VS.GetPlayerByUserid( ev.userid );
			m_pCritSpawner.SpawnEntityAtLocation( bot.EyePosition(), Vector() );
			bot.EmitSound( SND_CRITHIT );
		};
	};

}.bindenv(this), "" );


__PostSpawn <- function(...)
{
	foreach (p in vargv[0])
	{
		// p.__KeyValueFromFloat( "scale", 0.1 );
		// p.__KeyValueFromString( "rendercolor", "0 255 30 255" );
		// p.__KeyValueFromInt( "rendermode", 5 );
		p.__KeyValueFromInt( "movetype", 8 );
		p.SetVelocity( Vector(0,0,20) );
	}

	// crit_text.nut
	//@"m_nRenderAlpha <- 255;
	//m_RenderColor <- Vector( 0, 255, 30 );
	//m_flSpawnTime <- Time();
	//kColorRed <- Vector( 255, 0, 0 );
	//Think <- ::TR_SND.CritThink;"
}

function CritThink() : ( Time, FrameTime )
{
	local curtime = Time();
	local deltaTime = curtime - m_flSpawnTime;

	// fadeout 0.5
	if ( deltaTime > 1.0 )
	{
		local a = ( ( 255 / (0.5 / FrameTime()) ) + 0.5 ).tointeger();
		m_nRenderAlpha -= a;
	};

	if ( m_nRenderAlpha <= 0 )
	{
		self.Destroy();
		return;
	};

	// color fade
	if ( deltaTime > 0.5 )
	{
		VS.VectorLerp( m_RenderColor, kColorRed, 0.025, m_RenderColor );
		self.__KeyValueFromVector( "rendercolor", m_RenderColor );
		self.__KeyValueFromInt( "renderamt", m_nRenderAlpha );
	};

	return 0.0;
}

VS.ListenToGameEvent( "player_death", function(ev)
{
	local bot = ToExtendedPlayer( VS.GetPlayerByUserid( ev.userid ) );

	if ( !bot || !bot.IsBot() )
		return;

	foreach( i, v in m_Bots )
		if ( v == bot )
			m_Bots.remove(i);

	if ( m_bBlindMode )
	{
		// SendToConsole("r_screenoverlay\"\"");
		// g_hVisBlocker.__KeyValueFromInt( "effects", 32 );
		// EntFireByHandle( player.self, "SetFogController", "fog_default" );
		bot.SetEffects( 0 );
	}

	if ( !m_bStarted )
		return;

	g_hGameText.__KeyValueFromString( "message", "You killed " + bot.GetPlayerName() );
	EntFireByHandle( g_hGameText, "Display", "", 0.0, player.self );

	// stop playing sound
	EntFireByHandle( g_hTimerSnd, "Disable" );

	m_bSpawned = false;

	// next
	VS.EventQueue.AddEvent( Process, RandomFloat(0.4,1.2), this );

}.bindenv(this), "" );

function PlayTargetSoundThink()
{
	g_hTarget.EmitSound( GetSound() );
}

m_vecPlayerMins <- Vector( -12, -12, 4 );
m_vecPlayerMaxs <- Vector( 12, 12, 70 );

function AimHelperThink()
{
	if ( !m_bSpawned )
		return;

	local bot = GetBot();

	local viewOrigin = player.EyePosition();
	local viewForward = player.EyeForward();

	local ray = Ray_t();
	ray.Init( viewOrigin, viewOrigin + viewForward * MAX_COORD_FLOAT );

	if ( VS.IsRayIntersectingOBB( ray, bot.GetOrigin(), bot.GetAngles(), m_vecPlayerMins, m_vecPlayerMaxs ) )
	{

	}
	else
	{
		local attachment = bot.LookupAttachment("facemask");
		local vecTarget = bot.GetAttachmentOrigin( attachment ) - bot.EyeForward() * 4.0;

		local vecDelta = vecTarget - viewOrigin;

		local ang = atan2( -vecDelta.Dot( player.EyeRight() ), -vecDelta.Dot( player.EyeUp() ) ) + PI;

		vecDelta.Norm();

		local radius = VS.RemapValClamped( 1.0 - viewForward.Dot( vecDelta ), 1.0, 0.0, 0.3, 0.015 );

		local x = 0.5 + sin( ang ) * radius * 0.75 - 0.005;
		local y = 0.5 - cos( ang ) * radius - 0.0225;

		g_hGameText2.__KeyValueFromFloat( "x", x );
		g_hGameText2.__KeyValueFromFloat( "y", y );

		EntFireByHandle( g_hGameText2, "Display", "", 0.0, player.self );
	}
}

function Think()
{
	if ( m_bStarted )
	{
		if ( m_bAimHelper )
			AimHelperThink();
	}
	else
	{
		ButtonLookThink();

		if ( m_bAtControls )
			ThinkButton();
	}
}

function ToggleTeam()
{
	switch ( player.GetTeam() )
	{
		case TEAM_T:
			return SetTeam(TEAM_CT);
		case TEAM_CT:
			return SetTeam(TEAM_T);
	}
}

function Equip( input )
{
	switch ( input )
	{
		case weapon.hkp2000:
		case weapon.usp_silencer:
		case weapon.fn57:
		case weapon.famas:
		case weapon.m4a1:
		case weapon.m4a1_silencer:
		case weapon.aug:
		case weapon.scar20:
		case weapon.mag7:
		case weapon.mp9:
			SetTeam(TEAM_CT);
			break;
		// case weapon.axe:
		default:
			SetTeam(TEAM_T);
			break;
	}

	EntFire( "equip", "TriggerForActivatedPlayer", input, 0.0, player.self );

	VS.EventQueue.AddEvent( SetTeam, 0, [this, TEAM_CT] );
}

function SetTeam(i)
{
	EntFire( "texture_c", "SetTextureIndex", (i-1) );
	player.__KeyValueFromInt( "teamnumber", i );
}

function EnableAimlock()
{
	aimbot_clear();
	aimbot_add_p1( player );
	aimbot_lock( 1 );
	aimbot_fov( 0.0 );
	aimbot_trigger( 0 );
	aimbot_wh( 0 );

	Chat( CHAT_PREFIX + TextColor.Award + "Aimlock enabled" );
	player.EmitSound("UIPanorama.container_weapon_ticker");
	m_bAimLockEnabled = true;

	if ( m_bStarted && m_bSpawned )
	{
		aimbot_add_p2( GetBot() );
	}
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

	Chat( CHAT_PREFIX + "Picked " + TextColor.Normal + m_szMusicKitCurr );
	Msg( CHAT_PREFIX + "Picked " + m_szMusicKitCurr + "\n" );

	SendToConsole("r_cleardecals");
}

function PlayMusicKit()
{
	StopMusicKitAll();

	Chat( TextColor.Achievement + "▶ " + TextColor.Gold + "Now playing " + TextColor.Normal + m_szMusicKitCurr );
	Msg( "▶ Now playing " + m_szMusicKitCurr + "\n" );

	if ( m_nMusicType == 0 )
	{
		// these are affected by the client's music settings, but the direct file playing cannot be stopped
		m_szMusicKitSoundCurr = "Music.BombTenSecCount." + m_szMusicKitCurrID;
		m_flCountdown = 10.0;
		EntFireByHandle( g_hTimer10, "Enable" );
	}
	else if ( m_nMusicType == 1 )
	{
		m_szMusicKitSoundCurr = "Musix.HalfTime." + m_szMusicKitCurrID;
	};;

	player.EmitSound(m_szMusicKitSoundCurr);
	SendToConsole("r_cleardecals");
}

function StopMusicKit()
{
	Chat( TextColor.Penalty + "■ " + TextColor.Gold + "Stopped playing" );
	Msg("■ Stopped playing\n");

	EntFireByHandle( g_hTimer10, "Disable" );
	m_hCntdnMsg.__KeyValueFromString( "message", "10.0000" );

	player.StopSound(m_szMusicKitSoundCurr);
	SendToConsole("r_cleardecals");
}

// main menu musics can stack, stop all if any are playing.
// Alternatively I could keep track of playing tracks, but this is fine.
function StopMusicKitAll()
{
	foreach( k in MusicI ) player.StopSound("Musix.HalfTime." + k);
	EntFireByHandle( g_hTimer10, "Disable" );
	m_hCntdnMsg.__KeyValueFromString( "message", "10.0000" );
}

function SetMusicType()
{
	m_nMusicType++;

	m_nMusicType %= 2;

	// TODO: add all types
	if ( m_nMusicType == 0 )
	{
		Chat( CHAT_PREFIX + "Music type: " + TextColor.Gold + "Bomb 10 second count" );
		Msg( CHAT_PREFIX + "Music type: Bomb 10 second count\n" );

		m_hCntdnMsg.__KeyValueFromInt( "textsize", 10 );
		m_hCntdnMsg.__KeyValueFromString( "message", "10.0000" );
	}
	else if ( m_nMusicType == 1 )
	{
		Chat( CHAT_PREFIX + "Music type: " + TextColor.Gold + "Main menu" );
		Msg( CHAT_PREFIX + "Music type: Main menu\n" );

		m_hCntdnMsg.__KeyValueFromInt( "textsize", 0 );
		EntFireByHandle( g_hTimer10, "Disable" );
		m_hCntdnMsg.__KeyValueFromString( "message", "10.0000" );
	};;

	SendToConsole("r_cleardecals");
}

function Tick()
{
	m_flCountdown -= TICK_INTERVAL;

	m_hCntdnMsg.__KeyValueFromString( "message", Fmt("%.5f",m_flCountdown) );

	if ( m_flCountdown <= 0.0 )
	{
		EntFireByHandle( g_hTimer10, "Disable" );
		m_hCntdnMsg.__KeyValueFromString( "message", "0.00000" );
	};
}

m_vecMusicKitMaxs <- Vector(5,17,17);

// Draw all buttons that the player is looking at
function ButtonLookThink()
{
	local tr = VS.TraceDir( player.EyePosition(), player.EyeForward(), 1024.0, player.self, MASK_SOLID );
	local ent = tr.GetEntByClassname( "func_button", 24.0 );
	if ( ent )
	{
		DebugDrawBoxAngles( ent.GetOrigin(),
			ent.GetBoundingMins(),
			ent.GetBoundingMaxs(),
			ent.GetAngles(),
			255, 127, 0, 2, 0.2 );

		if ( !m_bStarted )
		{
			local name = ent.GetName();

			if ( (0 in name) && name[0] == 'm' )
			{
				local idx = name.slice(1);

				if ( (0 in idx) && idx[0] < 58 )
				{
					ShowHudHint( Music[MusicI[idx.tointeger()]] );
				};
			}
			else
			{
				if ( !m_bAimHelper && !m_bAtControls )
				{
					HideHudHint();
				};
			};

		};
	};

	if ( !m_bStarted && m_hCurrMusicKit.IsValid() )
		DebugDrawBoxAngles( m_hCurrMusicKit.GetOrigin(), m_vecMusicKitMaxs*-1, m_vecMusicKitMaxs, m_hCurrMusicKit.GetAngles(), 128, 255, 128, 4, 0.2 );
}

// Set the bot and player teams manually instead of relying on server settings
VS.ListenToGameEvent( "player_team", function(ev)
{
	if ( ev.disconnect )
		return;

	local p = VS.GetPlayerByUserid( ev.userid );
	if (!p)
		return;

	if ( !ev.isbot )
	{
		if ( ev.team != TEAM_CT )
		{
			p.SetTeam( TEAM_CT );
		};
	}
	else
	{
		if ( ev.team != TEAM_T )
		{
			p.SetTeam( TEAM_T );
		};
	};
}, "" );


function ShowHudHint( msg = "" )
{
	g_hHudHint.__KeyValueFromString("message", "" + msg);
	return EntFireByHandle( g_hHudHint, "ShowHudHint", "", 0, player.self );
}

function HideHudHint()
{
	return EntFireByHandle( g_hHudHint, "HideHudHint", "", 0, player.self );
}
