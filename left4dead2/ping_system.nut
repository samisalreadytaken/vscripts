//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Contextual Ping System
//

const PING_SYSTEM_VERSION = 36;

const CONTENTS_WINDOW				= 0x2;
//(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_MONSTER|CONTENTS_WINDOW|CONTENTS_DEBRIS|CONTENTS_GRATE)
const MASK_SHOT_HULL				= 0x600400B;

const OBS_MODE_DEATHCAM = 1;
const OBS_MODE_FREEZECAM = 2;
const OBS_MODE_FIXED = 3;
const OBS_MODE_IN_EYE = 4;
const OBS_MODE_CHASE = 5;
const OBS_MODE_ROAMING = 6;

const IN_ATTACK2	= 0x0800;
const IN_ALT2		= 0x8000;

const EF_NOINTERP	= 0x08;
const EF_NODRAW		= 0x20;
const FL_FAKECLIENT	= 0x100;
const PING_SYSTEM_EF_DEFAULT	= 0x50;
const PING_SYSTEM_EF_NOINTERP	= 0x58;

const FLT_MAX			= 3.402823466e+38;
const DEG2RAD			= 0.017453293;
const RAD2DEG			= 57.295779513;
const PI				= 3.141592654;
const MAX_COORD_FLOAT	= 16384.0;
const MAX_TRACE_LENGTH	= 56755.840862417;
const DEG2RADDIV2		= 0.008726646;
const PIDIV2			= 1.570796327;

local TICK_INTERVAL;
local CONST = getconsttable();
local Assert = assert;
local Msg = Msg, Fmt = format;
local split = split, array = array;

local SpawnEntityFromTable = SpawnEntityFromTable;
local AddThinkToEnt = AddThinkToEnt;
local EmitSoundOnClient = EmitSoundOnClient;
local Time = Time;
local TraceLine = TraceLine;
local EntFire = EntFire;
local rr_GetResponseTargets = rr_GetResponseTargets;
local IsPlayerABot = IsPlayerABot;
local GetPlayerFromUserID = GetPlayerFromUserID;
local Vector = Vector;
local tan = tan, atan = atan, atan2 = atan2, cos = cos,
	sqrt = sqrt, fabs = fabs;

local FireScriptEvent = FireScriptEvent;
local ScriptEventCallbacks = ScriptEventCallbacks; // static with mapspawn_ping

local FindEntityInSphere = Entities.FindInSphere.bindenv( Entities );
local FindEntityByClassWithin = Entities.FindByClassnameWithin.bindenv( Entities );
local GetNetPropInt = NetProps.GetPropInt.bindenv( NetProps );
local SetNetPropInt = NetProps.SetPropInt.bindenv( NetProps );
local SetNetPropFloat = NetProps.SetPropFloat.bindenv( NetProps );
local GetNetPropFloat = NetProps.GetPropFloat.bindenv( NetProps );
local SetNetPropEntity = NetProps.SetPropEntity.bindenv( NetProps );
local GetNetPropEntity = NetProps.GetPropEntity.bindenv( NetProps );

local PING_DEBUG = 1;
local PING_DEBUG_DRAW = 0;
local PING_DEBUG_VERBOSE = 1;
function PING_DEBUG(i) { PING_DEBUG = i; }
function PING_DEBUG_DRAW(i) { PING_DEBUG_DRAW = i; }
function PING_DEBUG_VERBOSE(i) { PING_DEBUG_VERBOSE = i; }
local print = print;

const COS_10DEG = 0.984808;
const COS_20DEG = 0.93969262;
const COS_37DEG = 0.8;
const COS_53DEG = 0.6;
const COS_90DEG = 0.0;

const PING_SYSTEM_LIFETIME_DEFAULT = 8.0;
const PING_SYSTEM_LIFETIME_CHATTER = 6.0;
const PING_SYSTEM_ITEM_SEARCH_RADIUS = 12.0;
const PING_SYSTEM_DEFAULT_SCALE_INTERNAL = 5.0;
const PING_SYSTEM_OFFSCREEN_DEFAULT_SCALE_INTERNAL = 2.0;
const PING_SYSTEM_PING_INTERVAL = 0.27;
const PING_SYSTEM_SOUND_INTERVAL = 0.35;
const PING_SYSTEM_SOUND_ALERT_THRESHOLD = 0.135;
const PING_SYSTEM_SOUND_COUNT_THRESHOLD = 5;
const PING_SYSTEM_SOUND_COOLDOWN = 1.25;
const PING_SYSTEM_SOUND_COOLDOWN_SHORT = 0.7;
const PING_SYSTEM_DEFAULT_MAX_PING_COUNT = 4;
const PING_SYSTEM_OFFSCREEN_INDICATOR_RADIUS = 6.0;
const PING_SYSTEM_FADE_DURATION_INV = 2.0;
const PING_SYSTEM_ITEM_TAKEN_FADE_DURATION = 0.25;
const PING_SYSTEM_PING_THINK_SLOW = 0.75;
const PING_SYSTEM_WHEEL_OPEN_TIME = 0.25;
const PING_SYSTEM_WHEEL_ITEM_COUNT = 4;

delete CONST.PING_SYSTEM_EF_DEFAULT;
delete CONST.PING_SYSTEM_EF_NOINTERP;
delete CONST.DEG2RADDIV2;
delete CONST.PIDIV2;
delete CONST.COS_10DEG;
delete CONST.COS_37DEG;
delete CONST.COS_53DEG;
delete CONST.COS_90DEG;
delete CONST.PING_SYSTEM_LIFETIME_DEFAULT;
delete CONST.PING_SYSTEM_LIFETIME_CHATTER;
delete CONST.PING_SYSTEM_DEFAULT_SCALE_INTERNAL;
delete CONST.PING_SYSTEM_OFFSCREEN_DEFAULT_SCALE_INTERNAL;
delete CONST.PING_SYSTEM_DEFAULT_MAX_PING_COUNT;
delete CONST.PING_SYSTEM_OFFSCREEN_INDICATOR_RADIUS;
delete CONST.PING_SYSTEM_FADE_DURATION_INV;
delete CONST.PING_SYSTEM_ITEM_TAKEN_FADE_DURATION;
delete CONST.PING_SYSTEM_PING_THINK_SLOW;
delete CONST.PING_SYSTEM_WHEEL_OPEN_TIME;
delete CONST.PING_SYSTEM_WHEEL_ITEM_COUNT;

if (PING_DEBUG)
{
	Assert( PING_SYSTEM_OFFSCREEN_INDICATOR_RADIUS >= 0.0 && PING_SYSTEM_OFFSCREEN_INDICATOR_RADIUS <= 10.0 );
}


enum PingType
{
	BASE,
	TEAMMATE,
	INFECTED,
	UNCOMMON,
	INCAP,
	ONFIRE,
	DEAD_SURVIVOR,

	WARNING,
	WARNING_ONFIRE,
	WARNING_MILD,

	MEDKIT,
	PILLS,
	ADRENALINE,
	DEFIBRILLATOR,
	MEDCAB,

	UPGRADEPACK_EXP,
	UPGRADEPACK_INC,
	UPGRADEPACK_LASER,

	PIPEBOMB,
	MOLOTOV,
	VOMITJAR,

	WEAPON_AMMO,
	WEAPON_AUTOSHOTGUN,
	WEAPON_BASEBALL,
	WEAPON_CHAINSAW,
	WEAPON_COLA,
	WEAPON_CRICKET,
	WEAPON_CROWBAR,
	WEAPON_GUITAR,
	WEAPON_FIREAXE,
	WEAPON_FRYINGPAN,
	WEAPON_GASCAN,
	WEAPON_GOLFCLUB,
	WEAPON_GRENADEL,
	WEAPON_HUNTING_RIFLE,
	WEAPON_KATANA,
	WEAPON_KNIFE,
	WEAPON_MACHETE,
	WEAPON_PISTOL,
	WEAPON_PISTOL_MAGNUM,
	WEAPON_PITCHFORK,
	WEAPON_PUMPSHOTGUN,
	WEAPON_RIFLE,
	WEAPON_RIFLE_AK47,
	WEAPON_RIFLE_DESERT,
	WEAPON_RIFLE_M60,
	WEAPON_RIFLE_SG552,
	WEAPON_SHOTGUN_CHROME,
	WEAPON_SHOTGUN_SPAS,
	WEAPON_SHOVEL,
	WEAPON_SMG,
	WEAPON_SMG_MP5,
	WEAPON_SMG_SILENCED,
	WEAPON_SNIPER_AWP,
	WEAPON_SNIPER_MIL,
	WEAPON_SNIPER_SSG,
	WEAPON_TONFA,
	WEAPON_RIOTSHIELD,

	// NOTE: These become prop_physics when thrown.
	WEAPON_GNOME,
	WEAPON_FIREWORKCRATE,
	WEAPON_PROPANETANK,
	WEAPON_OXYGENTANK,

	// misc
	DOOR,
	SAFEROOM,
	FUELBARREL,
	MINIGUN,
	LADDER,
	INTERACTABLE,
	COUNTDOWN,
	QUESTION,

	// chatter
	AFFIRMATIVE,
	NEGATIVE,
	WAIT,
	RESCUE,
	HURRY,
	LOOKOUT,

	MAX_COUNT,

	ALL = -1
}

m_PingIsWarning <-
{
	[PingType.WARNING]			= null,
	[PingType.WARNING_ONFIRE]	= null,
	[PingType.WARNING_MILD]		= null,
	[PingType.INCAP]			= null,
}

m_PingIsUsable <-
{
	[PingType.MEDKIT]					= null,
	[PingType.PILLS]					= null,
	[PingType.ADRENALINE]				= null,
	[PingType.DEFIBRILLATOR]			= null,
	[PingType.MEDCAB]					= null,
	[PingType.UPGRADEPACK_EXP]			= null,
	[PingType.UPGRADEPACK_INC]			= null,
	[PingType.UPGRADEPACK_LASER]		= null,
	[PingType.PIPEBOMB]					= null,
	[PingType.MOLOTOV]					= null,
	[PingType.VOMITJAR]					= null,
	[PingType.WEAPON_AMMO]				= null,
	[PingType.WEAPON_AUTOSHOTGUN]		= null,
	[PingType.WEAPON_BASEBALL]			= null,
	[PingType.WEAPON_CHAINSAW]			= null,
	[PingType.WEAPON_COLA]				= null,
	[PingType.WEAPON_CRICKET]			= null,
	[PingType.WEAPON_CROWBAR]			= null,
	[PingType.WEAPON_GUITAR]			= null,
	[PingType.WEAPON_FIREAXE]			= null,
	[PingType.WEAPON_FRYINGPAN]			= null,
	[PingType.WEAPON_GASCAN]			= null,
	[PingType.WEAPON_GOLFCLUB]			= null,
	[PingType.WEAPON_GRENADEL]			= null,
	[PingType.WEAPON_HUNTING_RIFLE]		= null,
	[PingType.WEAPON_KATANA]			= null,
	[PingType.WEAPON_KNIFE]				= null,
	[PingType.WEAPON_MACHETE]			= null,
	[PingType.WEAPON_PISTOL]			= null,
	[PingType.WEAPON_PISTOL_MAGNUM]		= null,
	[PingType.WEAPON_PITCHFORK]			= null,
	[PingType.WEAPON_PUMPSHOTGUN]		= null,
	[PingType.WEAPON_RIFLE]				= null,
	[PingType.WEAPON_RIFLE_AK47]		= null,
	[PingType.WEAPON_RIFLE_DESERT]		= null,
	[PingType.WEAPON_RIFLE_M60]			= null,
	[PingType.WEAPON_RIFLE_SG552]		= null,
	[PingType.WEAPON_SHOTGUN_CHROME]	= null,
	[PingType.WEAPON_SHOTGUN_SPAS]		= null,
	[PingType.WEAPON_SHOVEL]			= null,
	[PingType.WEAPON_SMG]				= null,
	[PingType.WEAPON_SMG_MP5]			= null,
	[PingType.WEAPON_SMG_SILENCED]		= null,
	[PingType.WEAPON_SNIPER_AWP]		= null,
	[PingType.WEAPON_SNIPER_MIL]		= null,
	[PingType.WEAPON_SNIPER_SSG]		= null,
	[PingType.WEAPON_TONFA]				= null,
	[PingType.WEAPON_RIOTSHIELD]		= null,
	[PingType.WEAPON_GNOME]				= null,
	[PingType.WEAPON_FIREWORKCRATE]		= null,
	[PingType.WEAPON_PROPANETANK]		= null,
	[PingType.WEAPON_OXYGENTANK]		= null,
	[PingType.INTERACTABLE]				= null,
}

m_PingHasTarget <-
{
	[PingType.TEAMMATE]			= null,
	[PingType.UNCOMMON]			= null,
	[PingType.DEAD_SURVIVOR]	= null,
	[PingType.SAFEROOM]			= null,
	[PingType.DOOR]				= null,
	[PingType.FUELBARREL]		= null,
	[PingType.MINIGUN]			= null,
}

foreach ( k, v in m_PingIsUsable )
	m_PingHasTarget[k] <- null;

m_PingIsChatter <-
{
	[PingType.AFFIRMATIVE]	= null,
	[PingType.NEGATIVE]		= null,
	[PingType.WAIT]			= null,
	[PingType.RESCUE]		= null,
	[PingType.HURRY]		= null,
	[PingType.LOOKOUT]		= null,
}

enum PingColour
{
	BASE			= 0xFFFFFFFF,
	TEAMMATE		= 0xFF96644E,
	INFECTED		= 0xFF6464FF,
	WARNING			= 0xFF0000FF,
	WARNING_MILD	= 0xFF1991FF,
	INCAP			= 0xFF1991FF,
}

enum PingSound
{
	DEFAULT		= "Default.Right", // "common/right.wav"
	ALERT		= "Default.RearRight", // "common/rearright.wav"
}

if ( !( "m_Players" in this ) )
{
	m_Players <- [];		// entindex - 1 : CBasePlayer[]
	m_Users <- [];			// entindex - 1 : CPingUser[]
	m_Teams <- array(4);	// teamnum : CBasePlayer[]
	m_Targets <- array(4);	// teamnum : { CBaseEntity : sprite }
	m_hManager <- null;
	m_PingLookup <- array( PingType.MAX_COUNT );
	m_PingWheelItems <- array( PING_SYSTEM_WHEEL_ITEM_COUNT );
	m_PingWheelItems[0] = PingType.RESCUE;
	m_PingWheelItems[1] = PingType.COUNTDOWN;
	m_PingWheelItems[2] = PingType.QUESTION;
	m_PingWheelItems[3] = PingType.LOOKOUT;

	const m_Pings = 0; // sprite[]
	const m_Buttons = 1; // int
	const m_hChatterPing = 2; // sprite
	const m_flLastPingTime = 3; // float
	const m_flLastPingSoundTime = 4; // float
	const m_flPingButtonTime = 5; // float
	const m_nConsecutivePings = 6; // int
	const m_OffscreenIndicators = 7; // {}[4]
	const m_hPingWheel = 8; // sprite
	const PING_SYSTEM_USER_MEMBER_COUNT = 9;

	delete CONST.m_Buttons;
	delete CONST.m_Pings;
	delete CONST.m_hChatterPing;
	delete CONST.m_flLastPingTime;
	delete CONST.m_flLastPingSoundTime;
	delete CONST.m_flPingButtonTime;
	delete CONST.m_nConsecutivePings;
	delete CONST.m_OffscreenIndicators;
	delete CONST.m_hPingWheel;
	delete CONST.PING_SYSTEM_USER_MEMBER_COUNT;

	const m_colour = 1;
	const m_lifetime = 2;
	const m_soundDefault = 3;
	const m_soundAlert = 4;

	delete CONST.PingColour;
	delete CONST.PingSound;
	delete CONST.m_colour;
	delete CONST.m_lifetime;
	delete CONST.m_soundDefault;
	delete CONST.m_soundAlert;
}

{
	local PingMaterial = array( PingType.MAX_COUNT );
	PingMaterial[PingType.BASE]						= "ping_system/ping_base.vmt",
	PingMaterial[PingType.TEAMMATE]					= "ping_system/ping_base.vmt",
	PingMaterial[PingType.INFECTED]					= "ping_system/ping_base.vmt",
	PingMaterial[PingType.UNCOMMON]					= "ping_system/ping_base.vmt",
	PingMaterial[PingType.INCAP]					= "ping_system/ping_base.vmt",
	PingMaterial[PingType.ONFIRE]					= "ping_system/ping_base_fire.vmt",
	PingMaterial[PingType.DEAD_SURVIVOR]			= "ping_system/ping_dead_survivor.vmt",

	PingMaterial[PingType.WARNING]					= "ping_system/ping_warning.vmt",
	PingMaterial[PingType.WARNING_ONFIRE]			= "ping_system/ping_warning_fire.vmt",
	PingMaterial[PingType.WARNING_MILD]				= "ping_system/ping_warning.vmt",

	PingMaterial[PingType.MEDKIT]					= "ping_system/ping_first_aid_kit.vmt",
	PingMaterial[PingType.PILLS]					= "ping_system/ping_pills.vmt",
	PingMaterial[PingType.ADRENALINE]				= "ping_system/ping_adrenaline.vmt",
	PingMaterial[PingType.DEFIBRILLATOR]			= "ping_system/ping_defibrillator.vmt",
	PingMaterial[PingType.MEDCAB]					= "ping_system/ping_medcabinet.vmt",

	PingMaterial[PingType.UPGRADEPACK_EXP]			= "ping_system/ping_upgradepack_explosive.vmt",
	PingMaterial[PingType.UPGRADEPACK_INC]			= "ping_system/ping_upgradepack_incendiary.vmt",
	PingMaterial[PingType.UPGRADEPACK_LASER]		= "ping_system/ping_upgradepack_laser.vmt",

	PingMaterial[PingType.PIPEBOMB]					= "ping_system/ping_pipebomb.vmt",
	PingMaterial[PingType.MOLOTOV]					= "ping_system/ping_molotov.vmt",
	PingMaterial[PingType.VOMITJAR]					= "ping_system/ping_vomitjar.vmt",

	PingMaterial[PingType.WEAPON_AMMO]				= "ping_system/ping_ammo.vmt",
	PingMaterial[PingType.WEAPON_AUTOSHOTGUN]		= "ping_system/ping_autoshotgun.vmt",
	PingMaterial[PingType.WEAPON_BASEBALL]			= "ping_system/ping_baseball_bat.vmt",
	PingMaterial[PingType.WEAPON_CHAINSAW]			= "ping_system/ping_chainsaw.vmt",
	PingMaterial[PingType.WEAPON_COLA]				= "ping_system/ping_cola.vmt",
	PingMaterial[PingType.WEAPON_CRICKET]			= "ping_system/ping_cricket_bat.vmt",
	PingMaterial[PingType.WEAPON_CROWBAR]			= "ping_system/ping_crowbar.vmt",
	PingMaterial[PingType.WEAPON_GUITAR]			= "ping_system/ping_electric_guitar.vmt",
	PingMaterial[PingType.WEAPON_FIREAXE]			= "ping_system/ping_fireaxe.vmt",
	PingMaterial[PingType.WEAPON_FRYINGPAN]			= "ping_system/ping_frying_pan.vmt",
	PingMaterial[PingType.WEAPON_GASCAN]			= "ping_system/ping_gascan.vmt",
	PingMaterial[PingType.WEAPON_GOLFCLUB]			= "ping_system/ping_golfclub.vmt",
	PingMaterial[PingType.WEAPON_GRENADEL]			= "ping_system/ping_grenade_launcher.vmt",
	PingMaterial[PingType.WEAPON_HUNTING_RIFLE]		= "ping_system/ping_hunting_rifle.vmt",
	PingMaterial[PingType.WEAPON_KATANA]			= "ping_system/ping_katana.vmt",
	PingMaterial[PingType.WEAPON_KNIFE]				= "ping_system/ping_knife.vmt",
	PingMaterial[PingType.WEAPON_MACHETE]			= "ping_system/ping_machete.vmt",
	PingMaterial[PingType.WEAPON_PISTOL]			= "ping_system/ping_pistol.vmt",
	PingMaterial[PingType.WEAPON_PISTOL_MAGNUM]		= "ping_system/ping_pistol_magnum.vmt",
	PingMaterial[PingType.WEAPON_PITCHFORK]			= "ping_system/ping_pitchfork.vmt",
	PingMaterial[PingType.WEAPON_PUMPSHOTGUN]		= "ping_system/ping_pumpshotgun.vmt",
	PingMaterial[PingType.WEAPON_RIFLE]				= "ping_system/ping_rifle.vmt",
	PingMaterial[PingType.WEAPON_RIFLE_AK47]		= "ping_system/ping_rifle_ak47.vmt",
	PingMaterial[PingType.WEAPON_RIFLE_DESERT]		= "ping_system/ping_rifle_desert.vmt",
	PingMaterial[PingType.WEAPON_RIFLE_M60]			= "ping_system/ping_rifle_m60.vmt",
	PingMaterial[PingType.WEAPON_RIFLE_SG552]		= "ping_system/ping_rifle_sg552.vmt",
	PingMaterial[PingType.WEAPON_SHOTGUN_CHROME]	= "ping_system/ping_shotgun_chrome.vmt",
	PingMaterial[PingType.WEAPON_SHOTGUN_SPAS]		= "ping_system/ping_shotgun_spas.vmt",
	PingMaterial[PingType.WEAPON_SHOVEL]			= "ping_system/ping_shovel.vmt",
	PingMaterial[PingType.WEAPON_SMG]				= "ping_system/ping_smg.vmt",
	PingMaterial[PingType.WEAPON_SMG_MP5]			= "ping_system/ping_smg_mp5.vmt",
	PingMaterial[PingType.WEAPON_SMG_SILENCED]		= "ping_system/ping_smg_silenced.vmt",
	PingMaterial[PingType.WEAPON_SNIPER_AWP]		= "ping_system/ping_sniper_awp.vmt",
	PingMaterial[PingType.WEAPON_SNIPER_MIL]		= "ping_system/ping_sniper_military.vmt",
	PingMaterial[PingType.WEAPON_SNIPER_SSG]		= "ping_system/ping_sniper_scout.vmt",
	PingMaterial[PingType.WEAPON_TONFA]				= "ping_system/ping_tonfa.vmt",
	PingMaterial[PingType.WEAPON_RIOTSHIELD]		= "ping_system/ping_riotshield.vmt",

	PingMaterial[PingType.WEAPON_GNOME]				= "ping_system/ping_gnome.vmt",
	PingMaterial[PingType.WEAPON_FIREWORKCRATE]		= "ping_system/ping_fireworkcrate.vmt",
	PingMaterial[PingType.WEAPON_PROPANETANK]		= "ping_system/ping_propanetank.vmt",
	PingMaterial[PingType.WEAPON_OXYGENTANK]		= "ping_system/ping_oxygentank.vmt",

	PingMaterial[PingType.DOOR]						= "ping_system/ping_door.vmt",
	PingMaterial[PingType.SAFEROOM]					= "ping_system/ping_saferoom.vmt",
	PingMaterial[PingType.FUELBARREL]				= "ping_system/ping_fuelbarrel.vmt",
	PingMaterial[PingType.MINIGUN]					= "ping_system/ping_minigun.vmt",
	PingMaterial[PingType.LADDER]					= "ping_system/ping_ladder.vmt",
	PingMaterial[PingType.INTERACTABLE]				= "ping_system/ping_interactable.vmt",
	PingMaterial[PingType.COUNTDOWN]				= "ping_system/ping_countdown.vmt",
	PingMaterial[PingType.QUESTION]					= "ping_system/ping_question.vmt",

	PingMaterial[PingType.AFFIRMATIVE]				= "ping_system/ping_affirmative.vmt",
	PingMaterial[PingType.NEGATIVE]					= "ping_system/ping_negative.vmt",
	PingMaterial[PingType.WAIT]						= "ping_system/ping_wait.vmt",
	PingMaterial[PingType.RESCUE]					= "ping_system/ping_rescue.vmt",
	PingMaterial[PingType.HURRY]					= "ping_system/ping_wait.vmt",
	PingMaterial[PingType.LOOKOUT]					= "ping_system/ping_lookout.vmt"

	foreach ( type, mat in PingMaterial )
	{
		m_PingLookup[type] =
			[ mat, PingColour.BASE, PING_SYSTEM_LIFETIME_DEFAULT, PingSound.DEFAULT, PingSound.ALERT ];
	}
}

local m_PingLookup = m_PingLookup;

	m_PingLookup[ PingType.TEAMMATE ][ m_colour ]			= PingColour.TEAMMATE;
	m_PingLookup[ PingType.TEAMMATE ][ m_lifetime ]			= 4.0;

	m_PingLookup[ PingType.INCAP ][ m_colour ]				= PingColour.INCAP;
	m_PingLookup[ PingType.INCAP ][ m_lifetime ]			= 4.0;

	m_PingLookup[ PingType.INFECTED ][ m_colour ]			= PingColour.INFECTED;
	m_PingLookup[ PingType.INFECTED ][ m_lifetime ]			= 4.0;

	m_PingLookup[ PingType.UNCOMMON ][ m_colour ]			= PingColour.WARNING_MILD;
	m_PingLookup[ PingType.UNCOMMON ][ m_lifetime ]			= 2.0;

	m_PingLookup[ PingType.WARNING ][ m_colour ]			= PingColour.WARNING;
	m_PingLookup[ PingType.WARNING ][ m_lifetime ]			= 4.0;

	m_PingLookup[ PingType.WARNING_ONFIRE ][ m_colour ]		= PingColour.WARNING;
	m_PingLookup[ PingType.WARNING_ONFIRE ][ m_lifetime ]	= 4.0;

	m_PingLookup[ PingType.WARNING_MILD ][ m_colour ]		= PingColour.WARNING_MILD;
	m_PingLookup[ PingType.ONFIRE ][ m_colour ]				= PingColour.WARNING_MILD;
	m_PingLookup[ PingType.HURRY ][ m_colour ]				= PingColour.WARNING_MILD;
	m_PingLookup[ PingType.FUELBARREL ][ m_colour ]			= PingColour.WARNING_MILD;

	m_PingLookup[ PingType.AFFIRMATIVE ][ m_lifetime ]		= PING_SYSTEM_LIFETIME_CHATTER;
	m_PingLookup[ PingType.NEGATIVE ][ m_lifetime ]			= PING_SYSTEM_LIFETIME_CHATTER;
	m_PingLookup[ PingType.WAIT ][ m_lifetime ]				= PING_SYSTEM_LIFETIME_CHATTER;
	m_PingLookup[ PingType.RESCUE ][ m_lifetime ]			= PING_SYSTEM_LIFETIME_CHATTER;
	m_PingLookup[ PingType.HURRY ][ m_lifetime ]			= PING_SYSTEM_LIFETIME_CHATTER;
	m_PingLookup[ PingType.LOOKOUT ][ m_lifetime ]			= PING_SYSTEM_LIFETIME_CHATTER;

enum PingResponse
{
	pass,
	weapon,
	special,
	dominated,
	chat,
	//remark
	death
}

m_ValidConcepts <-
{
	//TLK_REMARK				= PingResponse.remark,
	PlayerSpotWeapon		= PingResponse.weapon,
	PlayerWarnSpecial		= PingResponse.special,
	PlayerAlsoWarnSpecial	= PingResponse.special,

	ScreamWhilePounced		= PingResponse.dominated,	//SurvivorWasPounced
	SurvivorJockeyed		= PingResponse.dominated,
	chargerpound			= PingResponse.dominated,
	PlayerChoke				= PingResponse.dominated,
	//PlayerHelp

	PlayerIncoming			= PingResponse.pass,
	PlayerLockTheDoor		= PingResponse.pass,
	PlayerLook				= PingResponse.pass,
	PlayerLookHere			= PingResponse.pass,

	PlayerYes				= PingResponse.chat,
	PlayerNo				= PingResponse.chat,
	PlayerWaitHere			= PingResponse.chat,
	PlayerWarnCareful		= PingResponse.chat,
	PlayerMoveOn			= PingResponse.chat,
	PlayerHurryUp			= PingResponse.chat,
}

m_WeaponClassForName <-
{
	firstaidkit			= "weapon_first_aid_kit*",
	painpills			= "weapon_pain_pills*",
	adrenaline			= "weapon_adrenaline*",
	defibrillator		= "weapon_defibrillator*",

	molotov				= "weapon_molotov*",
	pipebomb			= "weapon_pipe_bomb*",
	vomitjar			= "weapon_vomitjar*",

	upgradepack_explosive	= "weapon_upgradepack_explosive*",
	upgradepack_incendiary	= "weapon_upgradepack_incendiary*",
	lasersights				= "upgrade_laser_sight*",

	ammo				= "weapon_ammo*",

	secondpistol		= "weapon_pistol*",
	magnum				= "weapon_pistol_magnum*",

	rifle				= "weapon_rifle*",
	rifle_ak47			= "weapon_rifle_ak47*",
	rifle_desert		= "weapon_rifle_desert*",
	m60					= "weapon_rifle_m60*",
	rifle_sg552			= "weapon_rifle_sg552*",

	huntingrifle		= "weapon_hunting_rifle*",
	sniper_awp			= "weapon_sniper_awp*",
	sniper_military		= "weapon_sniper_military*",
	sniper_scout		= "weapon_sniper_scout*",

	smg					= "weapon_smg*",
	smg_mp5				= "weapon_smg_mp5*",
	smg_silenced		= "weapon_smg_silenced*",

	pumpshotgun			= "weapon_pumpshotgun*",
	autoshotgun			= "weapon_autoshotgun*",
	shotgun_spas		= "weapon_shotgun_spas*",
	shotgun_chrome		= "weapon_shotgun_chrome*",

	grenadelauncher		= "weapon_grenade_launcher*",
	chainsaw			= "weapon_chainsaw*",
	colabottles			= "weapon_cola_bottles*",
	gnome				= "weapon_gnome*",
	fireworkcrate		= "weapon_fireworkcrate*",

	// Comment these out to enable model lookup for response spotting
	baseball_bat		= "weapon_melee*",
	fireaxe				= "weapon_melee*",
	crowbar				= "weapon_melee*",
	cricket_bat			= "weapon_melee*",
	electric_guitar		= "weapon_melee*",
	frying_pan			= "weapon_melee*",
	golfclub			= "weapon_melee*",
	katana				= "weapon_melee*",
	knife				= "weapon_melee*",
	machete				= "weapon_melee*",
	pitchfork			= "weapon_melee*",
	shovel				= "weapon_melee*",
	tonfa				= "weapon_melee*",
	riotshield			= "weapon_melee*",
}

m_ModelForWeaponName <-
{
	firstaidkit			= "models/w_models/weapons/w_eq_Medkit.mdl",
	painpills			= "models/w_models/weapons/w_eq_painpills.mdl",
	adrenaline			= "models/w_models/weapons/w_eq_adrenaline.mdl",
	defibrillator		= "models/w_models/weapons/w_eq_defibrillator.mdl",

	molotov				= "models/w_models/weapons/w_eq_molotov.mdl",
	pipebomb			= "models/w_models/weapons/w_eq_pipebomb.mdl",
	vomitjar			= "models/w_models/weapons/w_eq_bile_flask.mdl",

	upgradepack_explosive	= "models/w_models/weapons/w_eq_explosive_ammopack.mdl",
	upgradepack_incendiary	= "models/w_models/weapons/w_eq_incendiary_ammopack.mdl",
	lasersights				= "models/w_models/Weapons/w_laser_sights.mdl",

	//ammo				= "models/props/terror/ammo_stack.mdl",
	//ammo				= "models/props_unique/spawn_apartment/coffeeammo.mdl",

	secondpistol		= "models/w_models/weapons/w_pistol_B.mdl",
	magnum				= "models/w_models/weapons/w_desert_eagle.mdl",

	rifle				= "models/w_models/weapons/w_rifle_m16a2.mdl",
	rifle_ak47			= "models/w_models/weapons/w_rifle_ak47.mdl",
	rifle_desert		= "models/w_models/weapons/w_desert_rifle.mdl",
	m60					= "models/w_models/weapons/w_m60.mdl",
	rifle_sg552			= "models/w_models/weapons/w_rifle_sg552.mdl",

	huntingrifle		= "models/w_models/weapons/w_sniper_mini14.mdl",
	sniper_awp			= "models/w_models/weapons/w_sniper_awp.mdl",
	sniper_military		= "models/w_models/weapons/w_sniper_military.mdl",
	sniper_scout		= "models/w_models/weapons/w_sniper_scout.mdl",

	smg					= "models/w_models/weapons/w_smg_uzi.mdl",
	smg_mp5				= "models/w_models/weapons/w_smg_mp5.mdl",
	smg_silenced		= "models/w_models/weapons/w_smg_a.mdl",

	pumpshotgun			= "models/w_models/weapons/w_shotgun.mdl",
	autoshotgun			= "models/w_models/weapons/w_autoshot_m4super.mdl",
	shotgun_spas		= "models/w_models/weapons/w_shotgun_spas.mdl",
	shotgun_chrome		= "models/w_models/weapons/w_pumpshotgun_A.mdl",

	grenadelauncher		= "models/w_models/weapons/w_grenade_launcher.mdl",
	chainsaw			= "models/w_models/weapons/w_chainsaw.mdl",
	colabottles			= "models/w_models/weapons/w_cola.mdl",
	gnome				= "models/props_junk/gnome.mdl",
	fireworkcrate		= "models/props_junk/explosive_box001.mdl",

	baseball_bat		= "models/weapons/melee/w_bat.mdl",
	fireaxe				= "models/weapons/melee/w_fireaxe.mdl",
	crowbar				= "models/weapons/melee/w_crowbar.mdl",
	cricket_bat			= "models/weapons/melee/w_cricket_bat.mdl",
	electric_guitar		= "models/weapons/melee/w_electric_guitar.mdl",
	frying_pan			= "models/weapons/melee/w_frying_pan.mdl",
	golfclub			= "models/weapons/melee/w_golfclub.mdl",
	katana				= "models/weapons/melee/w_katana.mdl",
	knife				= "models/w_models/weapons/w_knife_t.mdl",
	machete				= "models/weapons/melee/w_machete.mdl",
	pitchfork			= "models/weapons/melee/w_pitchfork.mdl",
	shovel				= "models/weapons/melee/w_shovel.mdl",
	tonfa				= "models/weapons/melee/w_tonfa.mdl",
	riotshield			= "models/weapons/melee/w_riotshield.mdl",
}

m_ZombieTypeForSI <-
{
	SMOKER		= 1,
	BOOMER		= 2,
	HUNTER		= 3,
	SPITTER		= 4,
	JOCKEY		= 5,
	CHARGER		= 6,
	WITCH		= 7,
	TANK		= 8,
	SURVIVOR	= 9,
	NORMAL		= 9,
}

m_UncommonModels <-
[
	"models/infected/common_male_riot.mdl",
	"models/infected/common_male_clown.mdl",

	"models/infected/common_male_ceda.mdl",
	"models/infected/common_male_ceda_l4d1.mdl",

	"models/infected/common_male_fallen_survivor.mdl",
	"models/infected/common_male_fallen_survivor_l4d1.mdl",

	"models/infected/common_male_roadcrew.mdl",
	"models/infected/common_male_roadcrew_l4d1.mdl",

	"models/infected/common_male_mud.mdl",
	"models/infected/common_male_mud_L4D1.mdl",

	"models/infected/common_male_parachutist.mdl",
	"models/infected/common_male_parachutist_l4d1.mdl",

	"models/infected/common_male_jimmy.mdl",
];

m_ModelForUncommon <-
{
	RIOT_CONTROL	= "models/infected/common_male_riot.mdl",
	CEDA			= "models/infected/common_male_ceda.mdl",
	CLOWN			= "models/infected/common_male_clown.mdl",
	FALLEN			= "models/infected/common_male_fallen_survivor.mdl",
	UNDISTRACTABLE	= "models/infected/common_male_roadcrew.mdl",
	CRAWLER			= "models/infected/common_male_mud.mdl",
	JIMMY			= "models/infected/common_male_jimmy.mdl",
	//"models/infected/common_male_parachutist_l4d1.mdl",
}

m_ModelForUncommonL4D1 <-
{
	CEDA			= "models/infected/common_male_ceda_l4d1.mdl",
	FALLEN			= "models/infected/common_male_fallen_survivor_l4d1.mdl",
	UNDISTRACTABLE	= "models/infected/common_male_roadcrew_l4d1.mdl",
	CRAWLER			= "models/infected/common_male_mud_l4d1.mdl",
}

m_survivorCharacter <-
{
	namvet		= 4,
	biker		= 6,
	manager		= 7,
	teengirl	= 9,

	gambler		= 19,
	mechanic	= 20,
	coach		= 21,
	producer	= 22,
}

m_PingTypeForConcept <-
{
	PlayerYes			= PingType.AFFIRMATIVE,
	PlayerNo			= PingType.NEGATIVE,
	PlayerWaitHere		= PingType.WAIT,
	PlayerMoveOn		= PingType.RESCUE,
	PlayerHurryUp		= PingType.HURRY,
	PlayerWarnCareful	= PingType.LOOKOUT,
}

//m_PingTypeForWeaponID <-
//{
//	[1]		= PingType.WEAPON_PISTOL,
//	[2]		= PingType.WEAPON_SMG,
//	[3]		= PingType.WEAPON_PUMPSHOTGUN,
//	[4]		= PingType.WEAPON_AUTOSHOTGUN,
//	[5]		= PingType.WEAPON_RIFLE,
//	[6]		= PingType.WEAPON_HUNTING_RIFLE,
//	[7]		= PingType.WEAPON_SMG_SILENCED,
//	[8]		= PingType.WEAPON_SHOTGUN_CHROME,
//	[9]		= PingType.WEAPON_RIFLE_DESERT,
//	[10]	= PingType.WEAPON_SNIPER_MIL,
//	[11]	= PingType.WEAPON_SHOTGUN_SPAS,
//	[12]	= PingType.MEDKIT,
//	[13]	= PingType.MOLOTOV,
//	[14]	= PingType.PIPEBOMB,
//	[15]	= PingType.PILLS,
//	[16]	= PingType.WEAPON_GASCAN
//	[17]	= PingType.WEAPON_PROPANETANK
//	[18]	= PingType.WEAPON_OXYGENTANK
//	// melee
//	[20]	= PingType.WEAPON_CHAINSAW,
//	[21]	= PingType.WEAPON_GRENADEL,
//	//[22]
//	[23]	= PingType.ADRENALINE,
//	// PingType.DEFIBRILLATOR
//	[25]	= PingType.VOMITJAR,
//	[26]	= PingType.WEAPON_RIFLE_AK47,
//	[27]	= PingType.WEAPON_GNOME
//	[28]	= PingType.WEAPON_COLA
//	[29]	= PingType.WEAPON_FIREWORKCRATE
//	[30]	= PingType.UPGRADEPACK_INC,
//	[31]	= PingType.UPGRADEPACK_EXP,
//	[32]	= PingType.WEAPON_PISTOL_MAGNUM,
//	[33]	= PingType.WEAPON_SMG_MP5,
//	[34]	= PingType.WEAPON_RIFLE_SG552,
//	[35]	= PingType.WEAPON_SNIPER_AWP,
//	[36]	= PingType.WEAPON_SNIPER_SSG,
//	[37]	= PingType.WEAPON_RIFLE_M60,
//	//...
//	[54]	= PingType.WEAPON_AMMO,
//}

m_PingTypeForWeaponClass <- {}
local tmp_PingTypeForWeaponClass =
{
	weapon_first_aid_kit		= PingType.MEDKIT,
	weapon_pain_pills			= PingType.PILLS,
	weapon_adrenaline			= PingType.ADRENALINE,
	weapon_defibrillator		= PingType.DEFIBRILLATOR,

	weapon_upgradepack_explosive	= PingType.UPGRADEPACK_EXP,
	weapon_upgradepack_incendiary	= PingType.UPGRADEPACK_INC,

	weapon_pipe_bomb			= PingType.PIPEBOMB,
	weapon_molotov				= PingType.MOLOTOV,
	weapon_vomitjar				= PingType.VOMITJAR,

	weapon_oxygentank			= PingType.WEAPON_OXYGENTANK,
	weapon_propanetank			= PingType.WEAPON_PROPANETANK,
	weapon_fireworkcrate		= PingType.WEAPON_FIREWORKCRATE,
	weapon_gnome				= PingType.WEAPON_GNOME,
	weapon_cola_bottles			= PingType.WEAPON_COLA,
	weapon_gascan				= PingType.WEAPON_GASCAN,
	weapon_ammo					= PingType.WEAPON_AMMO,
	weapon_autoshotgun			= PingType.WEAPON_AUTOSHOTGUN,
	weapon_chainsaw				= PingType.WEAPON_CHAINSAW,
	weapon_grenade_launcher		= PingType.WEAPON_GRENADEL,
	weapon_hunting_rifle		= PingType.WEAPON_HUNTING_RIFLE,
	weapon_pistol				= PingType.WEAPON_PISTOL,
	weapon_pistol_magnum		= PingType.WEAPON_PISTOL_MAGNUM,
	weapon_pumpshotgun			= PingType.WEAPON_PUMPSHOTGUN,
	weapon_rifle				= PingType.WEAPON_RIFLE,
	weapon_rifle_ak47			= PingType.WEAPON_RIFLE_AK47,
	weapon_rifle_desert			= PingType.WEAPON_RIFLE_DESERT,
	weapon_rifle_m60			= PingType.WEAPON_RIFLE_M60,
	weapon_rifle_sg552			= PingType.WEAPON_RIFLE_SG552,
	weapon_shotgun_chrome		= PingType.WEAPON_SHOTGUN_CHROME,
	weapon_shotgun_spas			= PingType.WEAPON_SHOTGUN_SPAS,
	weapon_smg					= PingType.WEAPON_SMG,
	weapon_smg_mp5				= PingType.WEAPON_SMG_MP5,
	weapon_smg_silenced			= PingType.WEAPON_SMG_SILENCED,
	weapon_sniper_awp			= PingType.WEAPON_SNIPER_AWP,
	weapon_sniper_military		= PingType.WEAPON_SNIPER_MIL,
	weapon_sniper_scout			= PingType.WEAPON_SNIPER_SSG,
}

// Only includes weapons that can be classified as a different class than themselves (e.g. weapon_spawn)
// Excludes medical items
// This is checked when classname/weaponID is not found
m_PingTypeForWeaponModel <-
{
	// weapon_melee_spawn
	[m_ModelForWeaponName.fireaxe]			= PingType.WEAPON_FIREAXE,
	[m_ModelForWeaponName.baseball_bat]		= PingType.WEAPON_BASEBALL,
	[m_ModelForWeaponName.cricket_bat]		= PingType.WEAPON_CRICKET,
	[m_ModelForWeaponName.crowbar]			= PingType.WEAPON_CROWBAR,
	[m_ModelForWeaponName.electric_guitar]	= PingType.WEAPON_GUITAR,
	[m_ModelForWeaponName.frying_pan]		= PingType.WEAPON_FRYINGPAN,
	[m_ModelForWeaponName.golfclub]			= PingType.WEAPON_GOLFCLUB,
	[m_ModelForWeaponName.katana]			= PingType.WEAPON_KATANA,
	[m_ModelForWeaponName.machete]			= PingType.WEAPON_MACHETE,
	[m_ModelForWeaponName.pitchfork]		= PingType.WEAPON_PITCHFORK,
	[m_ModelForWeaponName.shovel]			= PingType.WEAPON_SHOVEL,
	[m_ModelForWeaponName.tonfa]			= PingType.WEAPON_TONFA,
	[m_ModelForWeaponName.riotshield]		= PingType.WEAPON_RIOTSHIELD,
	[m_ModelForWeaponName.knife]			= PingType.WEAPON_KNIFE,

	// weapon_spawn
	[m_ModelForWeaponName.autoshotgun]		= PingType.WEAPON_AUTOSHOTGUN,
	[m_ModelForWeaponName.chainsaw]			= PingType.WEAPON_CHAINSAW,
	[m_ModelForWeaponName.grenadelauncher]	= PingType.WEAPON_GRENADEL,
	[m_ModelForWeaponName.huntingrifle]		= PingType.WEAPON_HUNTING_RIFLE,
	[m_ModelForWeaponName.secondpistol]		= PingType.WEAPON_PISTOL,
	[m_ModelForWeaponName.magnum]			= PingType.WEAPON_PISTOL_MAGNUM,
	[m_ModelForWeaponName.pumpshotgun]		= PingType.WEAPON_PUMPSHOTGUN,
	[m_ModelForWeaponName.rifle]			= PingType.WEAPON_RIFLE,
	[m_ModelForWeaponName.rifle_ak47]		= PingType.WEAPON_RIFLE_AK47,
	[m_ModelForWeaponName.rifle_desert]		= PingType.WEAPON_RIFLE_DESERT,
	[m_ModelForWeaponName.m60]				= PingType.WEAPON_RIFLE_M60,
	[m_ModelForWeaponName.rifle_sg552]		= PingType.WEAPON_RIFLE_SG552,
	[m_ModelForWeaponName.shotgun_chrome]	= PingType.WEAPON_SHOTGUN_CHROME,
	[m_ModelForWeaponName.shotgun_spas]		= PingType.WEAPON_SHOTGUN_SPAS,
	[m_ModelForWeaponName.smg]				= PingType.WEAPON_SMG,
	[m_ModelForWeaponName.smg_mp5]			= PingType.WEAPON_SMG_MP5,
	[m_ModelForWeaponName.smg_silenced]		= PingType.WEAPON_SMG_SILENCED,
	[m_ModelForWeaponName.sniper_awp]		= PingType.WEAPON_SNIPER_AWP,
	[m_ModelForWeaponName.sniper_military]	= PingType.WEAPON_SNIPER_MIL,
	[m_ModelForWeaponName.sniper_scout]		= PingType.WEAPON_SNIPER_SSG,
}

m_PingTypeForPhysModel <-
{
	["models/w_models/weapons/w_cola.mdl"]			= PingType.WEAPON_COLA,
	["models/props_junk/gascan001a.mdl"]			= PingType.WEAPON_GASCAN,
	["models/props_junk/gnome.mdl"]					= PingType.WEAPON_GNOME,
	["models/props_junk/explosive_box001.mdl"]		= PingType.WEAPON_FIREWORKCRATE,
	["models/props_junk/propanecanister001a.mdl"]	= PingType.WEAPON_PROPANETANK,
	["models/props_equipment/oxygentank01.mdl"]		= PingType.WEAPON_OXYGENTANK,
}

m_WeaponsWithoutWeaponNameInResponse <-
[
	"weapon_gascan",
	"upgrade_ammo_explosive",
	"upgrade_ammo_incendiary",
]

m_IsSpawnEntity <-
{
	weapon_spawn = null,
	weapon_melee_spawn = null
}

m_IsPingableEntity <-
{
	weapon = null,
	weapon_spawn = null,
	weapon_melee = null,
	weapon_melee_spawn = null,
	upgrade_ammo_explosive = null,
	upgrade_ammo_incendiary = null,
	upgrade_laser_sight = null,
	survivor_death_model = null,
	prop_physics = null,
	trigger_finale = null,
}

local m_bButtonEnabled = true;
local m_bOffscreenIndicators = true;
local m_bPingWheelEnabled = true;
local m_nOffscreenIndicatorStyle = 0;
local m_nMaxPingCount = PING_SYSTEM_DEFAULT_MAX_PING_COUNT-1;
local m_bChatterEnabled = true;
local m_bPlaySoundOverride = true;
local s_bPlaySound = true;
local m_AutoBlock =
{
	[PingResponse.pass] = null
}

local sprite_kv =
{
	scale = PING_SYSTEM_DEFAULT_SCALE_INTERNAL,
	framerate = 0.0,
	rendermode = 2,
	model = m_PingLookup[ PingType.BASE ][0]
}

local offscreen_sprite_kv =
{
	scale = PING_SYSTEM_OFFSCREEN_DEFAULT_SCALE_INTERNAL,
	framerate = 0.0,
	rendermode = 2,
	model = "ping_system/ping_arrow.vmt"
}

local offscreen_interactable_sprite_kv =
{
	scale = PING_SYSTEM_OFFSCREEN_DEFAULT_SCALE_INTERNAL,
	framerate = 0.0,
	rendermode = 2,
	model = "ping_system/ping_interactable_detail.vmt"
}

local wheel_sprite_kv =
{
	scale = 2.0,
	framerate = 0.0,
	rendermode = 2,
	model = "ping_system/wheel_bg.vmt"
}

local wheel_item_sprite_kv =
{
	scale = 1.0,
	framerate = 0.0,
	rendermode = 2,
	model = "ping_system/wheel_items.vmt"
}

local m_Players = m_Players;
local m_Users = m_Users;
local m_Teams = m_Teams;
local m_Targets = m_Targets;
local m_PingWheelItems = m_PingWheelItems;
local m_PingIsWarning = m_PingIsWarning;
local m_PingIsUsable = m_PingIsUsable;
local m_PingHasTarget = m_PingHasTarget;
local m_PingHasSelfOffscreen = m_PingIsWarning;
local m_PingTypeForConcept = m_PingTypeForConcept;
local m_PingTypeForWeaponModel = m_PingTypeForWeaponModel;
local m_PingTypeForWeaponClass = m_PingTypeForWeaponClass;
local m_PingTypeForPhysModel = m_PingTypeForPhysModel;
local m_WeaponsWithoutWeaponNameInResponse = m_WeaponsWithoutWeaponNameInResponse;
local m_IsSpawnEntity = m_IsSpawnEntity;
local m_IsPingableEntity = m_IsPingableEntity;
local m_ValidConcepts = m_ValidConcepts;
local m_WeaponClassForName = m_WeaponClassForName;
local m_ZombieTypeForSI = m_ZombieTypeForSI;
local m_ModelForUncommon = m_ModelForUncommon;
local m_ModelForUncommonL4D1 = m_ModelForUncommonL4D1;
local m_ModelForWeaponName = m_ModelForWeaponName;

// Get _only_ weapon_spawn entities
foreach ( k, v in tmp_PingTypeForWeaponClass )
	m_IsSpawnEntity[ k + "_spawn" ] <- null;

// Cache weapon_spawn entities alongside regular entities
foreach ( k, v in tmp_PingTypeForWeaponClass )
	m_PingTypeForWeaponClass[ k ] <- m_PingTypeForWeaponClass[ k + "_spawn" ] <- v;

// Get all pingable entities
foreach ( k, v in m_PingTypeForWeaponClass )
	m_IsPingableEntity[ k ] <- null;

local PlayerPing, PingChatter, UpdateOffscreenIndicators, PingWheelUpdate, PingWheelClose;
local FadeOutOffscreen;

function Precache()
{
	foreach ( pingInfo in m_PingLookup )
		PrecacheModel( pingInfo[0] );

	PrecacheModel( offscreen_sprite_kv.model );
	PrecacheModel( offscreen_interactable_sprite_kv.model );
	PrecacheModel( wheel_sprite_kv.model );
	PrecacheModel( wheel_item_sprite_kv.model );

	if ( !IsSoundPrecached( PingSound.DEFAULT ) )
	{
		PrecacheSound( PingSound.DEFAULT );
		PrecacheSound( PingSound.ALERT );
	}
}

function ManagerThink()
{
	if ( 0 in m_Players )
	{
		foreach ( idx, player in m_Players ) if ( player )
		{
			if ( IsPlayerABot( player ) || GetNetPropInt( player, "m_lifeState" ) )
				continue;

			local user = m_Users[idx];

			if ( m_bButtonEnabled )
			{
				local buttons = player.GetButtonMask();
				local curPressed = buttons & IN_ALT2;

				if ( user[m_Buttons] != curPressed )
				{
					user[m_Buttons] = curPressed;

					if ( curPressed )
					{
						OnCommandPing( player );

						if ( m_bPingWheelEnabled )
							user[m_flPingButtonTime] = Time();
					}
					else if ( user[m_flPingButtonTime] )
					{
						PingWheelClose( player, user, 1 );
						user[m_flPingButtonTime] = 0.0;
					}
				}
				else
				{
					local buttonTime = user[m_flPingButtonTime];

					if ( buttonTime )
					{
						if (PING_DEBUG)
							Assert( curPressed );

						if ( user[m_hPingWheel] )
						{
							if ( buttons & IN_ATTACK2 )
							{
								PingWheelClose( player, user, 0 );
								user[m_flPingButtonTime] = 0.0;
							}
						}
						else if ( Time() - buttonTime >= PING_SYSTEM_WHEEL_OPEN_TIME )
						{
							PingWheelUpdate( player, user, 0 );
						}
					}
				}
			}

			if ( m_bOffscreenIndicators )
				UpdateOffscreenIndicators( player, user );
		}

		return 0.0;
	}

	// hibernate
	return 5.0;
}

local ManagerThink = ManagerThink.bindenv(this);

local s_prevtime;
local ManagerThink1 = function()
{
	if ( s_prevtime && ( TICK_INTERVAL = Time() - s_prevtime ) )
	{
		s_prevtime = null;

		if (PING_DEBUG)
			printf( "TICK_INTERVAL = %f (%f)\n", TICK_INTERVAL, 1.0 / TICK_INTERVAL );

		local fn = ManagerThink;
		Think = function() { return fn(); }
		return -1;
	}

	s_prevtime = Time();
	return 0.0;
}

local InitManager = function()
{
	if ( m_bButtonEnabled || m_bOffscreenIndicators )
	{
		if ( !( m_hManager && m_hManager.IsValid() ) )
		{
			m_hManager = SpawnEntityFromTable( "info_target", {} );
			m_hManager.ValidateScriptScope();
			m_hManager.GetScriptScope()[""] <- RemoveInvalidPlayers;
		}

		local sc = m_hManager.GetScriptScope();

		if ( TICK_INTERVAL )
		{
			local fn = ManagerThink;
			sc.Think <- function() { return fn(); }
		}
		else
		{
			sc.Think <- ManagerThink1;
		}

		AddThinkToEnt( m_hManager, "Think" );
	}
	else
	{
		if ( m_hManager && m_hManager.IsValid() )
		{
			m_hManager.GetScriptScope().Think <- null;
			AddThinkToEnt( m_hManager, null );
		}
	}

	if (PING_DEBUG)
	{
		printf( "InitManager %s %d\n",
				""+m_hManager, ( m_bButtonEnabled || m_bOffscreenIndicators ).tointeger() );
	}
}

function Init()
{
	InitManager();

	for ( local p; p = Entities.FindByClassname( p, "player" ); )
		AddPlayer( p, GetNetPropInt( p, "m_iTeamNum" ) );

	// RRule::SelectResponse() and RRule::criteria[0].func are cached on C++,
	// their return values are checked.
	// RRule::SelectResponse() is called when criteria match, expected to return ResponseSingle instance.
	// I don't care about responses as the criterion is used as a callback.
	local RRule = class extends this.RRule { SelectResponse = dummy; }

	if (PING_DEBUG)
	{
		RRule.SelectResponse <- function() { error( "PingSystem RR criterion matched\n" ); }
	}

	local rr = RRule( "PingSystem", [ CriterionFunc( "", rr_Ping.bindenv(this) ) ], [ null ], null );

	if (PING_DEBUG)
	{
		// NULL check in debug to be able to reload as rules can't seem to be able to be unregistered
		rr.criteria[0].func = function(Q) { if ( !!this ) return rr_Ping(Q); }.bindenv(this);
	}

	if ( !rr_AddDecisionRule( rr ) )
		error( "PingSystem: ERROR invalid RR!\n");

	return Msg(Fmt( "PingSystem::Init() [%d]\n", PING_SYSTEM_VERSION ));
}

function OnGameEvent_round_start( event )
{
	if ( !( m_hManager && m_hManager.IsValid() ) )
		return InitManager();
}

local RemovePings_user = function( user )
{
	foreach ( spr in user[m_Pings] )
		if ( spr && spr.IsValid() )
			spr.Kill();

	return user[m_Pings].clear();
}

local RemoveOffscreenIndicators_user = function( user )
{
	local len = user[m_OffscreenIndicators].len();

	for ( local i = 0; i < len; i += 4 )
	{
		local spr = user[m_OffscreenIndicators][ i + 1 ];
		if ( spr && spr.IsValid() )
		{
			local sc = spr.GetScriptScope();
			if ( sc.m_hDetailIcon )
				sc.m_hDetailIcon.Kill();
			spr.Kill();
		}
	}

	return user[m_OffscreenIndicators].clear();
}

local RemoveOffscreenIndicatorsOfPing = function( ping, user )
{
	local indicators = user[m_OffscreenIndicators];
	local i = indicators.find( ping );
	if ( i != null )
	{
		local offscreen = indicators[ i + 1 ];
		local osc = offscreen.GetScriptScope();
		osc.m_flDieTime = Time();
		osc.Think = FadeOutOffscreen;

		if (PING_DEBUG_VERBOSE)
		{
			printf( "\n(remove offscreen[%d] of player[%d])\n",
					offscreen.GetEntityIndex(),
					m_Users.find( user ) + 1 );
		}
	}
}

local RemoveWheel_user = function( user )
{
	local pWheel = user[m_hPingWheel];

	if ( pWheel && pWheel.IsValid() )
	{
		local sc = pWheel.GetScriptScope();

		if ( sc.m_Item1 && sc.m_Item1.IsValid() )
			sc.m_Item1.Kill();

		if ( sc.m_Item2 && sc.m_Item2.IsValid() )
			sc.m_Item2.Kill();

		if ( sc.m_Item3 && sc.m_Item3.IsValid() )
			sc.m_Item3.Kill();

		if ( sc.m_Item4 && sc.m_Item4.IsValid() )
			sc.m_Item4.Kill();

		pWheel.Kill();
	}
}

function RemoveInvalidPlayers()
{
	local count = 0;

	for ( local idx = m_Players.len(); idx--; )
	{
		local player = m_Players[idx];

		if ( !player )
			continue;

		if ( player.IsValid() )
		{
			++count;
			continue;
		}

		if (PING_DEBUG)
			printf( "PingSystem::RemoveInvalidPlayers() [%d]\n", idx + 1 );

		m_Players[idx] = null;

		local user = m_Users[idx];

		RemovePings_user( user );
		RemoveOffscreenIndicators_user( user );
		RemoveWheel_user( user );

		if ( user[m_hChatterPing] && user[m_hChatterPing].IsValid() )
			user[m_hChatterPing].Kill();

		foreach ( team in m_Teams ) if ( team )
		{
			local i = team.find( player );
			if ( i != null )
				team.remove(i);
		}
	}

	if ( !count )
	{
		m_Players.clear();
		m_Users.clear();
	}
}

function AddPlayer( player, teamnum )
{
	if (PING_DEBUG)
	{
		Assert( player && player.IsValid() );
		Assert( teamnum >= 0 );
	}

	// Remove from team
	foreach ( team in m_Teams ) if ( team )
	{
		local i = team.find( player );
		if ( i != null )
			team.remove(i);
	}

	local idx = player.GetEntityIndex() - 1;

	// Ignore spectators and unassigned even though they could ping
	if ( teamnum > 1 )
	{
		if ( !( teamnum in m_Teams ) )
			m_Teams.resize( teamnum+1 );

		if ( !m_Teams[ teamnum ] )
			m_Teams[ teamnum ] = [];

		m_Teams[ teamnum ].append( player );

		if ( !( teamnum in m_Targets ) )
			m_Targets.resize( teamnum+1 );

		if ( !m_Targets[ teamnum ] )
			m_Targets[ teamnum ] = {};

		if ( !( idx in m_Players ) )
		{
			local size = ( idx + 1 + 3 ) & ~3;
			m_Players.resize( size );
			m_Users.resize( size );
		}

		m_Players[ idx ] = player;
		local user = m_Users[ idx ];

		if ( user )
		{
			RemovePings_user( user );
			RemoveOffscreenIndicators_user( user );
			RemoveWheel_user( user );
		}
		else
		{
			user = m_Users[ idx ] = array( PING_SYSTEM_USER_MEMBER_COUNT );
			user[m_Pings] = [];
			user[m_OffscreenIndicators] = [];
		}

		if ( user[m_hChatterPing] && user[m_hChatterPing].IsValid() )
			user[m_hChatterPing].Kill();

		user[m_Buttons] = 0;
		user[m_hChatterPing] = null;
		user[m_flLastPingTime] =
		user[m_flLastPingSoundTime] =
		user[m_flPingButtonTime] = 0.0;
		user[m_nConsecutivePings] = 0;
		user[m_hPingWheel] = null;
	}
	else if ( idx in m_Players )
	{
		m_Players[ idx ] = null;
		local user = m_Users[ idx ];

		if ( user )
		{
			RemovePings_user( user );
			RemoveOffscreenIndicators_user( user );
			RemoveWheel_user( user );

			if ( user[m_hChatterPing] && user[m_hChatterPing].IsValid() )
				user[m_hChatterPing].Kill();

			user[m_Buttons] = 0;
			user[m_hChatterPing] = null;
			user[m_flLastPingTime] =
			user[m_flLastPingSoundTime] =
			user[m_flPingButtonTime] = 0.0;
			user[m_nConsecutivePings] = 0;
			user[m_hPingWheel] = null;
		}
	}

	if (PING_DEBUG)
	{
		Msg(Fmt( "PingSystem::AddPlayer() [%d] %s\n", teamnum, ""+player ));
		local gPR = Entities.FindByClassname( null, "terror_player_manager" );

		foreach ( teamnum, team in m_Teams )
		{
			Msg(Fmt( "  [%d]\n", teamnum ));

			if ( team )
			{
				foreach ( pl in team )
				{
					local entindex = pl.GetEntityIndex();
					local bot = IsPlayerABot( pl );
					local spec = GetNetPropInt( pl, "m_humanSpectatorEntIndex" );
					local ping = bot ? 0 : NetProps.GetPropIntArray( gPR, "m_iPing", entindex );

					Msg(Fmt( "      [%d]%s (%s)%s\n",
								pl.GetEntityIndex(),
								pl.GetClassname(),
								bot ? "bot" : ""+ping,
								spec > 0 ? Fmt( "<-[%d]", spec ) : "" ));
				}
			}
		}
	}
}

function DebugPrint()
{
	local gPR = Entities.FindByClassname( null, "terror_player_manager" );

	Msg(Fmt( "PingSystem::DebugPrint ver %d (%.2f)\n", PING_SYSTEM_VERSION, Time() ));
	Msg(Fmt( "  %d|%d\n", m_Players.len(), m_Users.len() ));

	foreach ( idx, player in m_Players )
	{
		local teamnum = -1;

		if ( player )
			foreach ( num, team in m_Teams ) if ( team )
		{
			local i = team.find( player );
			if ( i != null )
			{
				teamnum = num;
				break;
			}
		}

		if ( player && player.IsValid() )
		{
			local entindex = player.GetEntityIndex();
			local bot = IsPlayerABot( player );
			local spec = GetNetPropInt( player, "m_humanSpectatorEntIndex" );
			local obsTarget = GetNetPropEntity( player, "m_hObserverTarget" );
			local obsMode = GetNetPropInt( player, "m_iObserverMode" );
			local ping = bot ? 0 : NetProps.GetPropIntArray( gPR, "m_iPing", entindex );

			obsTarget = obsTarget && obsTarget.IsValid() ? obsTarget.GetEntityIndex() : -1;

			switch ( obsMode )
			{
				case OBS_MODE_DEATHCAM: obsMode = "DEATHCAM"; break;
				case OBS_MODE_FREEZECAM: obsMode = "FREEZECAM"; break;
				case OBS_MODE_FIXED: obsMode = "FIXED"; break;
				case OBS_MODE_IN_EYE: obsMode = "IN_EYE"; break;
				case OBS_MODE_CHASE: obsMode = "CHASE"; break;
				case OBS_MODE_ROAMING: obsMode = "ROAMING"; break;
			}

			Msg(Fmt( "  [%d](%d) %d|%d %d (%s)%s%s\n",
						entindex,
						player.GetPlayerUserId(),
						teamnum,
						GetNetPropInt( player, "m_iTeamNum" ),
						( !!m_Users[idx] && !!m_Users[idx][m_Pings] ).tointeger(),
						bot ? "bot" : ""+ping,
						spec > 0 ? Fmt( "<-[%d]", spec ) : "",
						obsMode ? Fmt( "  ->[%d](%s)", obsTarget, obsMode ) : "" ));
		}
		else
		{
			Msg( "  [-1]\n" );
		}
	}

	Msg("  ---\n");

	foreach ( idx, player in m_Players )
	{
		Msg(Fmt( "  [%d]\n",
					player && player.IsValid() ? player.GetEntityIndex() : -1 ));

		local user = m_Users[idx];
		if ( !user )
			continue;

		local teamnum = GetNetPropInt( player, "m_iTeamNum" );

		if ( user[m_Pings].len() )
		{
			Msg( "    pings:\n" );

			foreach ( spr in user[m_Pings] )
			{
				Msg(Fmt( "      [%s]",
							spr && spr.IsValid() ?
								""+spr.GetEntityIndex() :
								(""+spr).slice( (""+spr).find("0x"), -1 ) ));

				foreach ( target, ping in m_Targets[teamnum] )
				{
					if ( ping == spr )
						Msg( "->" + target );
				}

				Msg("\n");
			}
		}

		local len = user[m_OffscreenIndicators].len();
		if ( len )
		{
			Msg( "    offscreen:\n" );

			for ( local i = 0; i < len; i += 4 )
			{
				local target = user[m_OffscreenIndicators][ i ];
				local spr = user[m_OffscreenIndicators][ i + 1 ];

				Msg(Fmt( "      [%d]->[%d]\n",
							spr && spr.IsValid() ? spr.GetEntityIndex() : -1,
							target && target.IsValid() ? target.GetEntityIndex() : -1 ));
			}
		}

		local chatterPing = user[m_hChatterPing];
		if ( chatterPing )
		{
			Msg(Fmt( "    chatter: [%d]\n", chatterPing.IsValid() ? chatterPing.GetEntityIndex() : -1 ));
		}

		local wheel = user[m_hPingWheel];
		if ( wheel )
		{
			Msg(Fmt( "    wheel: [%d]\n", wheel.IsValid() ? wheel.GetEntityIndex() : -1 ));
		}
	}

	return Msg( "PingSystem::DebugPrint END\n" );
}

function OnGameEvent_player_disconnect( event )
{
	// queue
	return EntFire( "!activator", "CallScriptFunction", "", 0.0, m_hManager );
}

function OnGameEvent_player_team( event )
{
	RemoveInvalidPlayers();

	if ( event.disconnect )
		return;

	local player = GetPlayerFromUserID( event.userid );
	if ( player )
		return AddPlayer( player, event.team );
}

function OnGameEvent_finale_vehicle_leaving( event )
{
	if (PING_DEBUG)
		print( "finale_vehicle_leaving, remove all pings...\n" );

	foreach ( user in m_Users ) if ( user )
	{
		RemovePings_user( user );
		RemoveOffscreenIndicators_user( user );
		RemoveWheel_user( user );

		if ( user[m_hChatterPing] && user[m_hChatterPing].IsValid() )
			user[m_hChatterPing].Kill();
	}
}

function OnGameEvent_dead_survivor_visible( event )
{
	if ( PingResponse.death in m_AutoBlock )
		return;

	local player = GetPlayerFromUserID( event.userid );
	if ( player && player.IsSurvivor() )
	{
		local entity = EntIndexToHScript( event.subject );
		if ( entity )
		{
			if (PING_DEBUG)
			{
				printf( "dead_survivor_visible %s -> %s [%s]\n",
						""+player, ""+GetPlayerFromUserID(event.deadplayer), ""+entity );
			}

			s_bPlaySound = false;
			return PingEntity( player, entity );
		}
	}
}

function OnGameEvent_player_death( event )
{
	// player_death is fired for common infected kills as well, and without 'userid'...
	if ( "userid" in event )
	{
		if ( PingResponse.death in m_AutoBlock )
			return;

		local player = GetPlayerFromUserID( event.userid );
		if ( player && player.IsSurvivor() )
		{
			local entity = FindEntityByClassWithin( null, "survivor_death_model", player.GetOrigin(), 0.1 );
			if ( entity )
			{
				if (PING_DEBUG)
					printf( "player_death %s [%s]\n", ""+player, ""+entity );

				s_bPlaySound = false;
				return PingEntity( player, entity );
			}
		}
	}
}

delete CONST.PING_ATTACHMENT;
delete CONST.PING_ATTACHMENT1;

local GetHeadOrigin = function( pEnt )
{
	// Use attachments because invalid attachment origin is local vec3_origin,
	// invalid bone origin is vec3_invalid
	// It makes falling back simpler
	const PING_ATTACHMENT = "forward";
	const PING_ATTACHMENT1 = "mouth";

	// const PING_BONE_NAME = "ValveBiped.Bip01_Head1";
	// const PING_BONE_NAME1 = "ValveBiped.Bip01_Head";

	local bone = pEnt.LookupAttachment( PING_ATTACHMENT );
	if ( !bone )
		bone = pEnt.LookupAttachment( PING_ATTACHMENT1 );

	if (PING_DEBUG) Assert( bone > 0 );
	// if (PING_DEBUG) Assert( bone > -1 );

	return pEnt.GetAttachmentOrigin( bone );
}

function rr_Ping( Q )
{
	local concept;

	if ( "concept" in Q )
	{
		concept = Q.concept;
	}
	else if ( "Concept" in Q )
	{
		concept = Q.Concept;
	}
	else if (PING_DEBUG)
	{
		print( "[???] ???   <------------------------\n" );
		error("no concept!\n");
		__DumpScope( 2, Q );
	}

	if ( !( concept in m_ValidConcepts ) )
		return;

	local who;

	if ( "who" in Q )
	{
		who = Q.who;
	}
	else if ( "Who" in Q )
	{
		who = Q.Who;
	}

	if (PING_DEBUG)
	{
		if ( who )
		{
			printf( "[%s] %s   <------------------------", who, Q.concept );
		}
		else
		{
			printf( "[???] %s   <------------------------", Q.concept );
			error( "\nno response target!\n" );
			__DumpScope( 2, Q );
		}
	}

	local targets = rr_GetResponseTargets();

	if ( who in targets )
	{
		who = targets[ who ];
	}
	else
	{
		local szWho = who.tolower();

		if ( szWho in m_survivorCharacter )
		{
			local id = m_survivorCharacter[ szWho ];

			foreach ( p in m_Players )
			{
				if ( p.IsValid() && GetNetPropInt( p, "m_survivorCharacter" ) == id )
				{
					who = p;
					break;
				}
			}
		}

		// Some people can't spell, retry
		switch ( who )
		{
			case "Namvet":
				if (PING_DEBUG) error("found Namvet\n");
				Q.who <- "NamVet";
				return rr_Ping( Q );
			case "Teengirl":
				if (PING_DEBUG) error("found Teengirl\n");
				Q.who <- "TeenGirl";
				return rr_Ping( Q );
		}

		if ( !( "IsValid" in who ) )
			return Msg( "\nPingSystem: Response target '" + who + "' not found\n" );
	}

	local bAuto = !( "smartlooktype" in Q ) || Q.smartlooktype != "manual";
	local resp = m_ValidConcepts[ concept ];

	if (PING_DEBUG)
	{
		if ( bAuto )
			print(" (auto)");
		if ( IsPlayerABot( who ) )
			print(" [bot]");
		print("\n");
	}

	if ( bAuto && resp in m_AutoBlock )
	{
		if ( concept != "PlayerLookHere" || PingResponse.weapon in m_AutoBlock )
		{
			if (PING_DEBUG)
				print("   auto-ping is disabled\n");

			return;
		}
		else
		{
			resp = PingResponse.weapon;
		}
	}

	// Don't play sound when auto-pinged
	s_bPlaySound = !bAuto;

	switch ( resp )
	{
		case PingResponse.pass:

			if (PING_DEBUG)
			{
				// Should always be blocked in m_AutoBlock
				Assert( !bAuto );
				Assert( resp in m_AutoBlock );
			}

			return OnCommandPing( who );

		case PingResponse.weapon:
		{
			if ( "weaponname" in Q )
			{
				if (PING_DEBUG)
					printl( "   PingResponse.weapon : " + Q.weaponname );

				local weaponname = Q.weaponname.tolower();
				if ( !( weaponname in m_WeaponClassForName ) )
				{
					if (PING_DEBUG)
						error( "weapon class not found for '" + weaponname + "'\n" );
					return;
				}

				local weaponclass = m_WeaponClassForName[ weaponname ];

				local flThresholdBase = COS_10DEG;
				if ( bAuto )
				{
					if ( IsPlayerABot(who) )
						flThresholdBase = COS_90DEG;
					else
						flThresholdBase = COS_37DEG;
				}

				local flThreshold = flThresholdBase;
				local eyePos = who.EyePosition();
				local eyeDir = who.EyeAngles().Forward();
				local pEnt, pTarget;

				while ( pEnt = FindEntityByClassWithin( pEnt, weaponclass, eyePos, 256.0 ) )
				{
					if ( GetNetPropEntity( pEnt, "m_hOwnerEntity" ) ||
							( GetNetPropInt( pEnt, "m_fEffects" ) & EF_NODRAW ) )
						continue;

					local delta = pEnt.GetCenter() - eyePos;
					local dist = delta.Norm();
					local dot = eyeDir.Dot( delta );
					if ( dot > flThreshold ||
							// Use higher FOV for close items
							// but not too high if players are pinging beyond the items in front
							( dist < 85.0 && dot > COS_20DEG ) )
					{
						pTarget = pEnt;
						flThreshold = dot;
					}
				}

				if (PING_DEBUG) if ( pTarget )
				{
					printf( "	  target %s (%.2f, %.2f)\n",
							""+pTarget,
							acos( flThreshold ) * RAD2DEG,
							( pTarget.GetCenter() - eyePos ).Length() );

					if ( GetNetPropInt( pTarget, "m_fEffects" ) & EF_NODRAW )
						print( "	 nodraw\n" );
				}

				if ( pTarget )
					return PingEntity( who, pTarget );

				// It could be a 'weapon_spawn', re-search -

				local weaponmodel;
				if ( weaponname in m_ModelForWeaponName )
					weaponmodel = m_ModelForWeaponName[ weaponname ];

				if (PING_DEBUG)
				{
					if ( !weaponmodel && weaponname != "ammo" )
						error( "model not found for weaponname " + weaponname + "\n" );
				}

				pEnt = null;
				flThreshold = flThresholdBase;
				while ( pEnt = FindEntityByClassWithin( pEnt, "weapon*", eyePos, 256.0 ) )
				{
					// Looking for weapon* class, check the model if it is the one we're searching for.
					// if there is no model data, found generic weapon entity's model will be looked up in PingEntity.
					// Checking weaponID is not viable with melee weapons and medkit.
					if ( weaponmodel && pEnt.GetModelName() != weaponmodel )
						continue;

					if ( GetNetPropEntity( pEnt, "m_hOwnerEntity" ) ||
							( GetNetPropInt( pEnt, "m_fEffects" ) & EF_NODRAW ) )
						continue;

					local delta = pEnt.GetCenter() - eyePos;
					local dist = delta.Norm();
					local dot = eyeDir.Dot( delta );
					if ( dot > flThreshold ||
							( dist < 85.0 && dot > COS_20DEG ) )
					{
						pTarget = pEnt;
						flThreshold = dot;
					}
				}

				if (PING_DEBUG) if ( pTarget )
				{
					printf( "	  target %s (%.2f, %.2f) | %s\n",
							""+pTarget,
							acos( flThreshold ) * RAD2DEG,
							( pTarget.GetCenter() - eyePos ).Length(),
							(weaponmodel?split(weaponmodel,"/").top():"weapon*") );

					if ( GetNetPropInt( pTarget, "m_fEffects" ) & EF_NODRAW )
						print( "	 nodraw\n" );
				}

				if (PING_DEBUG_DRAW) if (pTarget)
				{
					DebugDrawBox( pTarget.GetOrigin(),
							Vector(-1,-1,-1), Vector(1,1,1),
							255, 255, 255, 255,
							PING_SYSTEM_LIFETIME_DEFAULT );
				}

				if ( pTarget )
					return PingEntity( who, pTarget );

				if ( bAuto )
					return;

				if (PING_DEBUG_VERBOSE)
					print( "	  trace fallback\n" );

				return PingTrace( who );
			}
			else
			{
				// this is a mess...
				if (PING_DEBUG)
					print( "   PingResponse.weapon : NULL\n" );

				local flThresholdBase = COS_10DEG;
				if ( bAuto )
					flThresholdBase = COS_37DEG;

				local flThreshold = flThresholdBase;
				local eyePos = who.EyePosition();
				local eyeDir = who.EyeAngles().Forward();
				local pEnt, pTarget;

				// Auto-ping of propanetank, oxygentank
				// Sometimes "PlayerLook" is also fired, but that seems rarer than "PlayerLookHere"
				if ( concept == "PlayerLookHere" )
				{
					while ( pEnt = FindEntityByClassWithin( pEnt, "prop_physics", eyePos, 256.0 ) )
					{
						if ( !( pEnt.GetModelName() in m_PingTypeForPhysModel ) )
							continue;

						local moveparent = pEnt.GetMoveParent();
						if ( moveparent && moveparent.GetClassname() == "player" )
							continue;

						local delta = pEnt.GetCenter() - eyePos;
						local dist = delta.Norm();
						local dot = eyeDir.Dot( delta );
						if ( dot > flThreshold ||
								( dist < 85.0 && dot > COS_20DEG ) )
						{
							pTarget = pEnt;
							flThreshold = dot;
						}
					}
				}
				// gascan, upgradepack
				else
				{
					foreach ( weaponclass in m_WeaponsWithoutWeaponNameInResponse )
					{
						pEnt = null;
						while ( pEnt = FindEntityByClassWithin( pEnt, weaponclass, eyePos, 256.0 ) )
						{
							if ( GetNetPropEntity( pEnt, "m_hOwnerEntity" ) ||
									( GetNetPropInt( pEnt, "m_fEffects" ) & EF_NODRAW ) )
								continue;

							local delta = pEnt.GetCenter() - eyePos;
							local dist = delta.Norm();
							local dot = eyeDir.Dot( delta );
							if ( dot > flThreshold ||
									( dist < 85.0 && dot > COS_20DEG ) )
							{
								pTarget = pEnt;
								flThreshold = dot;
							}
						}
					}
				}

				if (PING_DEBUG) if ( pTarget )
				{
					printf( "	  target %s (%.2f, %.2f)\n",
							""+pTarget,
							acos( flThreshold ) * RAD2DEG,
							( pTarget.GetCenter() - eyePos ).Length() );

					if ( GetNetPropInt( pTarget, "m_fEffects" ) & EF_NODRAW )
						print( "     nodraw\n" );
				}

				if ( pTarget )
					return PingEntity( who, pTarget );

				if ( bAuto )
					return;

				return PingTrace( who );
			}
		}
		case PingResponse.special:
		{
			local specialtype;

			if ( "specialtype" in Q )
			{
				specialtype = Q.specialtype.toupper();
			}
			else if ( "SpecialType" in Q )
			{
				if (PING_DEBUG) error("found SpecialType\n");
				specialtype = Q.SpecialType.toupper();
			}

			if (PING_DEBUG)
			{
				printl( "   PingResponse.special : " + specialtype );

				if ( specialtype )
				{
					if ( !( specialtype in m_ZombieTypeForSI ) &&
							!( specialtype in m_ModelForUncommon ) &&
							!( specialtype in m_ModelForUncommonL4D1 ) )
						error( "unrecognised specialtype '" + specialtype + "'\n" );
				}
				else
				{
					error("no specialtype!\n");
					__DumpScope( 2, Q );
				}
			}

			if ( specialtype in m_ZombieTypeForSI )
			{
				specialtype = m_ZombieTypeForSI[ specialtype ];

				local szClassname = "player";

				// hack for witch
				if ( specialtype == 7 )
					szClassname = "witch";

				local flThreshold = COS_10DEG;
				if ( bAuto )
					flThreshold = COS_37DEG;

				local eyePos = who.EyePosition();
				local eyeDir = who.EyeAngles().Forward();
				local pEnt, pTarget;

				while ( pEnt = FindEntityByClassWithin( pEnt, szClassname, eyePos, 1024.0 ) )
				{
					if ( szClassname != "witch" && pEnt.GetZombieType() != specialtype )
						continue;

					local delta = pEnt.GetCenter() - eyePos;
					local dist = delta.Norm();
					local dot = eyeDir.Dot( delta );
					if ( dot > flThreshold ||
							// Use higher FOV for close enemies
							( dist < 256.0 && dot > COS_37DEG ) )
					{
						pTarget = pEnt;
						flThreshold = dot;
					}
				}

				if (PING_DEBUG) if ( pTarget )
				{
					printf( "	  SI target %s (%.2f, %.2f)\n",
							""+pTarget,
							acos( flThreshold ) * RAD2DEG,
							( pTarget.GetCenter() - eyePos ).Length() );
				}

				if ( pTarget )
					return PingEntity( who, pTarget );
			}
/*
			// Uncommon infected
			else
			{
				local i = 2;
				local lookupTable = m_ModelForUncommon;
				do
				{
					if ( specialtype in lookupTable )
					{
						local szMdl = lookupTable[ specialtype ];

						local eyePos = who.EyePosition();
						local eyeDir = who.EyeAngles().Forward();
						local flThreshold = COS_37DEG;
						local pEnt, pTarget;

						while ( pEnt = FindEntityByModel( pEnt, szMdl ) )
						{
							local org = pEnt.GetOrigin();
							local delta = org - eyePos;
							local dist = delta.Norm();
							local dot = eyeDir.Dot( delta );

							if ( dist <= 768.0 && dot > flThreshold )
							{
								pTarget = pEnt;
								flThreshold = dot;
							}
						}

						if ( pTarget )
						{
							if (PING_DEBUG)
								printl( "      uncommon target : " + pTarget );

							// local pos
							local vecPingPos = GetHeadOrigin( pTarget ) - pTarget.GetOrigin();
							vecPingPos.x = vecPingPos.y = 0.0;
							vecPingPos.z += 32.0;

							return PlayerPing( who, PingType.UNCOMMON, vecPingPos, pTarget, pTarget );
						}

						lookupTable = m_ModelForUncommonL4D1;
					}
				} while ( --i )
			}
*/

			// no target found, trace if not auto
			if ( bAuto )
				return;

			if (PING_DEBUG_VERBOSE)
				print( "      trace fallback\n" );

			return PingTrace( who );
		}
		case PingResponse.dominated:
		{
			if ( !bAuto )
				return;

			if (PING_DEBUG)
				print("   auto ping\n");

			local hMyDominator = who.GetSpecialInfectedDominatingMe();
			if ( hMyDominator )
			{
				local type = PingType.WARNING;

				// Smoker can dominate from far away, ping self as incap
				if ( hMyDominator.GetZombieType() == m_ZombieTypeForSI.SMOKER )
				{
					if ( !GetNetPropInt( who, "m_isHangingFromTongue" ) )
						return;

					hMyDominator = who;
					type = PingType.INCAP;
				}

				local vecPingPos = hMyDominator.EyePosition();
				vecPingPos.z = GetHeadOrigin( hMyDominator ).z + 32.0;

				return PlayerPing( who, type, vecPingPos, hMyDominator );
			}

			return;
		}
		//case PingResponse.remark:
		//
		//	if ( Q.subject != "remark_caralarm" )
		//		return;
		//
		//	break;

		case PingResponse.chat:
			if ( m_bChatterEnabled )
				return PingChatter( who, m_PingTypeForConcept[ concept ] );
	}
}

local PreFadeOut = function( target = null )
{
	local pings = m_hUser[m_Pings];
	local i = pings.find( self );

	if (PING_DEBUG) if ( i == null )
	{
		printf( "\nfading ping[%d] not found in user\n", self.GetEntityIndex() );
		PingSystem.DebugPrint();
	}

	if ( i != null )
		pings.remove(i);

	if ( target in m_hTeamTargets )
	{
		delete m_hTeamTargets[ target ];
		if (PING_DEBUG_VERBOSE)
			printf( "  free ping target %s\n", ""+target );
	}
}

local FadeOut = function()
{
	local dt = Time() - m_flDieTime;
	local alpha = m_nRenderAlpha * ( 1.0 - dt * PING_SYSTEM_FADE_DURATION_INV );

	if (PING_DEBUG)
	{
		Assert( dt >= 0.0 );
		Assert( alpha < 256.0 );
		Assert( alpha >= 0.0 );
	}

	if ( alpha > 4.0 )
	{
		self.__KeyValueFromInt( "renderamt", m_nRenderAlpha = alpha );
		return 0.0;
	}

	if (PING_DEBUG_VERBOSE)
		printf( "ping[%d] expired\n", self.GetEntityIndex() );

	self.Kill();
	return -1;
}

FadeOutOffscreen = function()
{
	local dt = Time() - m_flDieTime;
	local alpha = m_nRenderAlpha * ( 1.0 - dt * PING_SYSTEM_FADE_DURATION_INV );

	if (PING_DEBUG)
	{
		Assert( dt >= 0.0 );
		Assert( alpha < 256.0 );
		Assert( alpha >= 0.0 );
	}

	if ( alpha > 4.0 )
	{
		self.__KeyValueFromInt( "renderamt", m_nRenderAlpha = alpha );

		if ( m_hDetailIcon )
			m_hDetailIcon.__KeyValueFromInt( "renderamt", alpha );

		return 0.0;
	}

	if (PING_DEBUG_VERBOSE)
	{
		printf( "offscreen[%d]->ping[%d] expired\n",
				self.GetEntityIndex(),
				m_hTarget.IsValid() ? m_hTarget.GetEntityIndex() : -1 );
	}

	local indicators = m_hUser[m_OffscreenIndicators];
	local i = indicators.find( self );

	if (PING_DEBUG) if ( i == null )
	{
		printf( "\nfading offscreen[%d] not found in user\n", self.GetEntityIndex() );
		PingSystem.DebugPrint();
	}

	if ( i != null )
	{
		--i;
		indicators.remove( i );
		indicators.remove( i );
		indicators.remove( i );
		indicators.remove( i );
	}

	if ( m_hDetailIcon )
		m_hDetailIcon.Kill();

	self.Kill();
	return -1;
}

local SpriteThinkOffscreen = function()
{
	if ( m_hTarget.IsValid() &&
			// Fade out with the target
			m_hTarget.GetScriptScope().m_nRenderAlpha == 255 )
	{
		if ( m_bVisible )
			return 0.0;

		local alpha = m_nRenderAlpha;
		local alphaTarget = m_nRenderAlphaTarget;

		if ( alpha != alphaTarget )
		{
			local delta = alphaTarget - alpha;
			local speed = 31;

			if ( delta > speed )
			{
				alpha += speed;
			}
			else if ( -speed > delta )
			{
				alpha -= speed;
			}
			else
			{
				alpha = alphaTarget;
			}

			self.__KeyValueFromInt( "renderamt", m_nRenderAlpha = alpha );

			local pDetailIcon = m_hDetailIcon;
			if ( pDetailIcon )
				pDetailIcon.__KeyValueFromInt( "renderamt", alpha );
		}

		return 0.0;
	}

	if (PING_DEBUG_VERBOSE)
	{
		printf( "start fade offscreen[%d]->ping[%d] a(%d)\n",
				self.GetEntityIndex(),
				m_hTarget.IsValid() ? m_hTarget.GetEntityIndex() : -1,
				m_hTarget.IsValid() ? m_hTarget.GetScriptScope().m_nRenderAlpha : -1 );
	}

	m_flDieTime = Time() - 0.01;
	return (Think = FadeOutOffscreen)();
}

local SpriteThinkEnemy = function()
{
	local curtime = Time();

	if ( curtime < m_flDieTime )
	{
		if ( !GetNetPropInt( m_hTarget, "m_lifeState" ) )
			return PING_SYSTEM_PING_THINK_SLOW;

		curtime -= PING_SYSTEM_ITEM_TAKEN_FADE_DURATION;

		if (PING_DEBUG_VERBOSE)
		{
			printf( "ping[%d] target %s is dead : lifeState(%d)\n",
					self.GetEntityIndex(),
					""+m_hTarget, GetNetPropInt( m_hTarget, "m_lifeState" ));
		}
	}
	else if (PING_DEBUG_VERBOSE)
	{
		printf( "start fade ping[%d]\n", self.GetEntityIndex() );
	}

	m_flDieTime = curtime - 0.01;
	PreFadeOut( m_hTarget );
	return (Think = FadeOut)();
}

local SpriteThinkIncap = function()
{
	local curtime = Time();

	if ( curtime < m_flDieTime )
	{
		if ( m_hTarget.IsValid() && !GetNetPropInt( m_hTarget, "m_lifeState" ) &&
				( m_hTarget.IsIncapacitated() || GetNetPropInt( m_hTarget, "m_isHangingFromTongue" ) ) )
			return PING_SYSTEM_PING_THINK_SLOW;

		curtime -= PING_SYSTEM_ITEM_TAKEN_FADE_DURATION;

		if (PING_DEBUG_VERBOSE)
		{
			printf( "ping[%d] target %s is not incap : incap(%d) lifeState(%d)\n",
					self.GetEntityIndex(),
					""+m_hTarget,
					m_hTarget.IsValid() ? m_hTarget.IsIncapacitated().tointeger() : -1,
					GetNetPropInt( m_hTarget, "m_lifeState" ));
		}
	}
	else if (PING_DEBUG_VERBOSE)
	{
		printf( "start fade ping[%d]\n", self.GetEntityIndex() );
	}

	m_flDieTime = curtime - 0.01;
	PreFadeOut( m_hTarget );
	return (Think = FadeOut)();
}

local SpriteThinkItem = function()
{
	local curtime = Time();

	if ( curtime < m_flDieTime )
	{
		if ( m_hTarget.IsValid() &&
				!( GetNetPropEntity( m_hTarget, "m_hOwnerEntity" ) ||
					( GetNetPropInt( m_hTarget, "m_fEffects" ) & EF_NODRAW ) ) )
		{
			return PING_SYSTEM_PING_THINK_SLOW;
		}

		curtime -= PING_SYSTEM_ITEM_TAKEN_FADE_DURATION;

		if (PING_DEBUG_VERBOSE)
		{
			printf( "ping[%d] item %s is taken : owner%s nodraw[%d]\n",
					self.GetEntityIndex(),
					""+m_hTarget,
					""+GetNetPropEntity( m_hTarget, "m_hOwnerEntity" ),
					( GetNetPropInt( m_hTarget, "m_fEffects" ) & EF_NODRAW ) );
		}
	}
	else if (PING_DEBUG_VERBOSE)
	{
		printf( "start fade ping[%d]\n", self.GetEntityIndex() );
	}

	m_flDieTime = curtime - 0.01;
	PreFadeOut( m_hTarget );
	return (Think = FadeOut)();
}

local SpriteThinkDoor = function()
{
	local curtime = Time();

	if ( curtime < m_flDieTime )
	{
		if ( m_hTarget.IsValid() && !( GetNetPropInt( m_hTarget, "m_fEffects" ) & EF_NODRAW ) )
			return PING_SYSTEM_PING_THINK_SLOW;

		curtime -= PING_SYSTEM_ITEM_TAKEN_FADE_DURATION;

		if (PING_DEBUG_VERBOSE)
		{
			printf( "ping[%d] door %s is no more : nodraw[%d]\n",
					self.GetEntityIndex(),
					""+m_hTarget,
					( GetNetPropInt( m_hTarget, "m_fEffects" ) & EF_NODRAW ) );
		}
	}
	else if (PING_DEBUG_VERBOSE)
	{
		printf( "start fade ping[%d]\n", self.GetEntityIndex() );
	}

	m_flDieTime = curtime - 0.01;
	PreFadeOut( m_hTarget );
	return (Think = FadeOut)();
}

local SpriteThinkDroppedPhysics = function()
{
	local curtime = Time();

	if ( curtime < m_flDieTime )
	{
		// prop_physics no longer exists when picked up
		if ( m_hTarget.IsValid() )
			return PING_SYSTEM_PING_THINK_SLOW;

		curtime -= PING_SYSTEM_ITEM_TAKEN_FADE_DURATION;

		if (PING_DEBUG_VERBOSE)
			printf( "ping[%d] item %s is taken\n", self.GetEntityIndex(), ""+m_hTarget );
	}
	else if (PING_DEBUG_VERBOSE)
	{
		printf( "start fade ping[%d]\n", self.GetEntityIndex() );
	}

	m_flDieTime = curtime - 0.01;
	PreFadeOut( m_hTarget );
	return (Think = FadeOut)();
}

local SpriteThinkChatter = function()
{
	local curtime = Time();

	if ( curtime < m_flDieTime )
	{
		if ( m_hTarget.IsValid() )
		{
			// Recalculate position on state change
			// not perfect, good enough
			local state = 0;

			if ( m_hTarget.IsImmobilized() )
				state = 0x1;

			if ( GetNetPropInt( m_hTarget, "m_Local.m_bDucked" ) )
				state = state | 0x2;

			if ( m_nState != state )
			{
				m_nState = state;

				local vecPingPos = GetHeadOrigin( m_hTarget ) - m_hTarget.GetOrigin();
				vecPingPos.x = vecPingPos.y = 0.0;
				vecPingPos.z += 32.0;
				self.SetLocalOrigin( vecPingPos );

				if (PING_DEBUG_VERBOSE)
					printf( "player[%d] chatter[%d] correct pos\n", m_hTarget.GetEntityIndex(), self.GetEntityIndex() );
			}

			return PING_SYSTEM_PING_THINK_SLOW;
		}
	}

	local user = m_hUser;

	if ( self == user[m_hChatterPing] )
		user[m_hChatterPing] = null;

	m_flDieTime = curtime - 0.01;
	return (Think = FadeOut)();
}

local SpriteThinkCountdown = function()
{
	if ( m_flFrame == 3.0 )
	{
		if (PING_DEBUG_VERBOSE)
			printf( "ping[%d] countdown end\n", self.GetEntityIndex() );

		PreFadeOut( m_hTarget );
		self.Kill();
		return -1;
	}

	SetNetPropFloat( self, "m_flFrame", m_flFrame++ );

	if (PING_DEBUG_VERBOSE)
		printf( "ping[%d] countdown %d\n", self.GetEntityIndex(), m_flFrame.tointeger() );

	return 1.0;
}

local SpriteThink = function()
{
	if ( m_bInitRem )
	{
		m_bInitRem = false;
		return m_flDieTime;
	}

	m_flDieTime = Time();
	PreFadeOut();
	return (Think = FadeOut)();
}

local EmitPingSound = function( curtime, user, playerTeam, pingInfo )
{
	local timediff = curtime - user[m_flLastPingSoundTime];

	if ( timediff >= 1.0 )
	{
		user[m_flLastPingSoundTime] = curtime;
		user[m_nConsecutivePings] = 1;

		local sound = pingInfo[m_soundDefault];
		foreach ( p in m_Teams[ playerTeam ] )
			EmitSoundOnClient( sound, p );
	}
	else if ( timediff >= PING_SYSTEM_SOUND_INTERVAL )
	{
		// Sufficient time for a ping but put on cooldown if it was spam
		if ( ++user[m_nConsecutivePings] <= PING_SYSTEM_SOUND_COUNT_THRESHOLD )
		{
			user[m_flLastPingSoundTime] = curtime;

			local sound = pingInfo[m_soundDefault];
			foreach ( p in m_Teams[ playerTeam ] )
				EmitSoundOnClient( sound, p );
		}
		else
		{
			user[m_flLastPingSoundTime] = curtime + PING_SYSTEM_SOUND_COOLDOWN;
			user[m_nConsecutivePings] = 0;

			local sound = pingInfo[m_soundAlert];
			foreach ( p in m_Teams[ playerTeam ] )
				EmitSoundOnClient( sound, p );
		}
	}
	// Quick consecutive pings, short cooldown
	else if ( timediff < PING_SYSTEM_SOUND_ALERT_THRESHOLD &&
			// Check to make sure this isn't after cooldown
			timediff > 0.0 &&
			user[m_nConsecutivePings] )
	{
		user[m_flLastPingSoundTime] = curtime + PING_SYSTEM_SOUND_COOLDOWN_SHORT;
		user[m_nConsecutivePings] = 0;

		local sound = pingInfo[m_soundAlert];
		foreach ( p in m_Teams[ playerTeam ] )
			EmitSoundOnClient( sound, p );
	}
	else if (PING_DEBUG_VERBOSE)
	{
		printf( "player[%d] no ping sound : diff(%.2f) count(%d)\n",
				m_Users.find( user ) + 1,
				timediff,
				user[m_nConsecutivePings] );
	}
}

local SetPingThink = function( pSpr, sc, type, target = null )
{
	AddThinkToEnt( pSpr, "Think" );

	if ( type in m_PingIsWarning )
	{
		if ( type != PingType.INCAP )
		{
			sc.Think <- SpriteThinkEnemy;
		}
		else
		{
			sc.Think <- SpriteThinkIncap;
		}
	}
	else if ( type in m_PingHasTarget )
	{
		if ( type != PingType.DOOR )
		{
			if ( target.GetClassname() == "prop_physics" && GetNetPropEntity( target, "m_hOwnerEntity" ) )
			{
				sc.Think <- SpriteThinkDroppedPhysics;
			}
			else
			{
				sc.Think <- SpriteThinkItem;
			}
		}
		else
		{
			sc.Think <- SpriteThinkDoor;
		}
	}
	else if ( type == PingType.COUNTDOWN )
	{
		sc.Think <- SpriteThinkCountdown;
	}
	else
	{
		sc.Think <- SpriteThink;
	}
}

PlayerPing = function( player, type, origin, target = null, hParent = null )
{
	local pingInfo = m_PingLookup[ type ];
	local user = m_Users[ player.GetEntityIndex() - 1 ];
	local playerPings = user[m_Pings];
	local playerTeam = GetNetPropInt( player, "m_iTeamNum" );
	local teamTargets = m_Targets[playerTeam];
	local curtime = Time();
	local pSpr, sc;

	if (PING_DEBUG) if ( playerTeam <= 1 )
	{
		error("invalid player team\n");
		return;
	}

	if ( s_bPlaySound && m_bPlaySoundOverride )
	{
		EmitPingSound( curtime, user, playerTeam, pingInfo );
	}
	else
	{
		s_bPlaySound = true;
	}

	// Re-pinged a target
	if ( target in teamTargets )
	{
		pSpr = teamTargets[target];

		if (PING_DEBUG_VERBOSE)
		{
			printf( "player[%d] re-pinged %s <- ping[%d]\n",
					player.GetEntityIndex(),
					""+target,
					pSpr.IsValid() ? pSpr.GetEntityIndex() : -1 );
		}

		if ( pSpr.IsValid() )
		{
			sc = pSpr.GetScriptScope();

			// Ignore fading pings,
			// their offscreen parts would also need resetting,
			// complicating the logic
			if ( sc.m_nRenderAlpha == 255 )
			{
				if (PING_DEBUG)
					Assert( sc.Think != FadeOut );

				// Transfer ownership
				local prevUser = sc.m_hUser;
				if ( prevUser != user )
				{
					sc.m_hUser = user;

					local prevUserPings = prevUser[m_Pings];
					local i = prevUserPings.find( pSpr );

					if (PING_DEBUG) if ( i == null )
					{
						printf( "\ntransferring ping[%d] not found in user\n", pSpr.GetEntityIndex() );
						DebugPrint();
					}

					if ( i != null )
						prevUserPings.remove(i);

					playerPings.append( pSpr );

					if (PING_DEBUG_VERBOSE)
					{
						printf( "  transferred ping[%d] from player[%d] to player[%d]\n",
								pSpr.GetEntityIndex(),
								m_Users.find( prevUser ) + 1,
								m_Users.find( user ) + 1 );
					}
				}
				// Move ping to latest
				else
				{
					local i = playerPings.find( pSpr );

					if (PING_DEBUG) if ( i == null )
					{
						printf( "\nextending ping[%d] not found in user\n", pSpr.GetEntityIndex() );
						DebugPrint();
					}

					if ( i != null )
					{
						playerPings.append( playerPings.remove(i) );
					}
				}

				sc.m_flDieTime = curtime + pingInfo[m_lifetime];

				// Enable interp if it was disabled
				// and teleport to prevent invalid interpolation
				if ( GetNetPropInt( pSpr, "m_fEffects" ) & EF_NOINTERP )
				{
					SetNetPropInt( pSpr, "m_fEffects", PING_SYSTEM_EF_DEFAULT );
					pSpr.SetOrigin( origin );
				}
				else
				{
					pSpr.SetLocalOrigin( origin );
				}

				if ( sc.m_nPingType != type )
				{
					if (PING_DEBUG_VERBOSE)
						printf( "  type change %d -> %d\n", sc.m_nPingType, type );

					if ( sc.m_nPingType == PingType.COUNTDOWN )
					{
						SetNetPropFloat( pSpr, "m_flFrame", 0.0 );
						SetPingThink( pSpr, sc, type, target );
					}

					sc.m_nPingType = type;
					pSpr.SetModel( pingInfo[0] );
					SetNetPropInt( pSpr, "m_clrRender", pingInfo[m_colour] );
				}

				if (PING_DEBUG_VERBOSE)
					print( "  extending\n" );

				return;
			}
		}
	}
	// If this base ping was very soon after the previous base ping,
	// move that to this position
	else
	{
		local lastPingTime = user[m_flLastPingTime];
		user[m_flLastPingTime] = curtime;

		if ( type == PingType.BASE &&
				0 in playerPings &&
				curtime - lastPingTime < PING_SYSTEM_PING_INTERVAL &&
				( sc = ( pSpr = playerPings.top() ).GetScriptScope() ).m_nPingType == PingType.BASE &&
				sc.m_nRenderAlpha == 255 )
		{
			if (PING_DEBUG_VERBOSE)
				printf( "player[%d] extended base ping[%d]\n", player.GetEntityIndex(), pSpr.GetEntityIndex() );

			sc.m_flDieTime = curtime + pingInfo[m_lifetime];

			if ( GetNetPropInt( pSpr, "m_fEffects" ) & EF_NOINTERP )
			{
				SetNetPropInt( pSpr, "m_fEffects", PING_SYSTEM_EF_DEFAULT );
				pSpr.SetOrigin( origin );
			}
			else
			{
				pSpr.SetLocalOrigin( origin );
			}

			return;
		}
	}

	if (PING_DEBUG_VERBOSE)
		printf( "player[%d] ", player.GetEntityIndex() );

	if ( m_nMaxPingCount in playerPings )
	{
		if ( ( pSpr = playerPings.remove(0) ).IsValid() )
		{
			if (PING_DEBUG_VERBOSE)
				printf( "reuse ping[%d]", pSpr.GetEntityIndex() );

			pSpr.SetModel( pingInfo[0] );
			SetNetPropInt( pSpr, "m_fEffects", PING_SYSTEM_EF_NOINTERP );
			SetNetPropFloat( pSpr, "m_flFrame", 0.0 );

			sc = pSpr.GetScriptScope();

			if ( "m_hTarget" in sc && sc.m_hTarget in teamTargets )
			{
				if (PING_DEBUG_VERBOSE)
					printf( "->" + sc.m_hTarget );
				delete teamTargets[ sc.m_hTarget ];
			}

			// If this ping had an offscreen indicator and it's no more
			if ( m_bOffscreenIndicators &&
					sc.m_nPingType in m_PingHasSelfOffscreen && !( type in m_PingHasSelfOffscreen ) )
			{
				RemoveOffscreenIndicatorsOfPing( pSpr, user );
			}
		}
		else
		{
			if (PING_DEBUG)
			{
				printf( "\nNULL ent in player pings %s\n", ""+pSpr );
				DebugPrint();
			}

			sprite_kv.model = pingInfo[0];
			pSpr = SpawnEntityFromTable( "env_sprite", sprite_kv );
			SetNetPropInt( pSpr, "m_iTeamNum", playerTeam );
			pSpr.ValidateScriptScope();
		}
	}
	else
	{
		sprite_kv.model = pingInfo[0];
		pSpr = SpawnEntityFromTable( "env_sprite", sprite_kv );
		SetNetPropInt( pSpr, "m_iTeamNum", playerTeam );
		pSpr.ValidateScriptScope();

		if (PING_DEBUG_VERBOSE)
			printf( "new ping[%d]", pSpr.GetEntityIndex() );
	}

	if (PING_DEBUG_VERBOSE)
	{
		if ( target )
			printf( "->" + target );

		printf( "\n" );
	}

	playerPings.append( pSpr );

	pSpr.SetLocalOrigin( origin );
	SetNetPropInt( pSpr, "m_clrRender", pingInfo[m_colour] );
	SetNetPropEntity( pSpr, "m_hMoveParent", hParent );
	AddThinkToEnt( pSpr, "Think" );

	sc = pSpr.GetScriptScope();
	sc.m_nRenderAlpha <- 255;
	sc.m_hUser <- user;
	sc.m_nPingType <- type;

	if ( type in m_PingIsWarning )
	{
		sc.m_flDieTime <- curtime + pingInfo[m_lifetime];
		sc.m_hTarget <- target;
		sc.m_hTeamTargets <- teamTargets;

		if ( type != PingType.INCAP )
		{
			sc.Think <- SpriteThinkEnemy;
		}
		else
		{
			sc.Think <- SpriteThinkIncap;
		}

		if ( target )
			teamTargets[ target ] <- pSpr;
	}
	else if ( type in m_PingHasTarget )
	{
		sc.m_flDieTime <- curtime + pingInfo[m_lifetime];
		sc.m_hTarget <- target;
		sc.m_hTeamTargets <- teamTargets;

		if (PING_DEBUG)
			Assert( target );

		if ( type != PingType.DOOR )
		{
			// HACKHACK: If this is a prop_physics with an owner, assume it is a dropped item
			if ( target.GetClassname() == "prop_physics" && GetNetPropEntity( target, "m_hOwnerEntity" ) )
			{
				// NOTE: prop_physics might be rolling around, but parenting doesn't look good,
				// and I don't want to correct pos/rot every frame
				sc.Think <- SpriteThinkDroppedPhysics;
			}
			else
			{
				sc.Think <- SpriteThinkItem;
			}
		}
		else
		{
			// Double doors have owners for the other half
			sc.Think <- SpriteThinkDoor;
		}

		teamTargets[ target ] <- pSpr;
	}
	else if ( type == PingType.COUNTDOWN )
	{
		sc.m_flDieTime <- 0.0;
		sc.m_hTarget <- null;
		sc.m_flFrame <- 0.0;
		sc.Think <- SpriteThinkCountdown;
	}
	// base, static
	else
	{
		sc.m_bInitRem <- true;
		sc.m_flDieTime <- pingInfo[m_lifetime];
		sc.m_hTeamTargets <- null;
		sc.Think <- SpriteThink;
	}

	if ( "player_ping" in ScriptEventCallbacks )
	{
		return FireScriptEvent( "player_ping", { player = player, origin = origin * 1, target = target } );
		//FireGameEvent( "player_ping", { userid = player.GetPlayerUserId(), target = target ? target.GetEntityIndex() : -1, x = origin.x, y = origin.y, z = origin.z } );
	}
}

PingChatter = function( player, pingType )
{
	// local pos
	local vecPingPos = GetHeadOrigin( player ) - player.GetOrigin();
	vecPingPos.x = vecPingPos.y = 0.0;
	vecPingPos.z += 32.0;

	// Chatter pings don't count towards ping limit
	local user = m_Users[ player.GetEntityIndex() - 1 ];
	local pSpr = user[m_hChatterPing];
	local pingInfo = m_PingLookup[ pingType ];

	if ( pSpr && pSpr.IsValid() )
	{
		pSpr.SetModel( pingInfo[0] );

		if (PING_DEBUG_VERBOSE)
			printf( "player[%d] reuse chatter[%d]\n", player.GetEntityIndex(), pSpr.GetEntityIndex() );
	}
	else
	{
		sprite_kv.model = pingInfo[0];
		user[m_hChatterPing] = pSpr = SpawnEntityFromTable( "env_sprite", sprite_kv );
		SetNetPropInt( pSpr, "m_iTeamNum", GetNetPropInt( player, "m_iTeamNum" ) );
		SetNetPropEntity( pSpr, "m_hMoveParent", player );
		pSpr.ValidateScriptScope();

		if (PING_DEBUG_VERBOSE)
			printf( "player[%d] new chatter[%d]\n", player.GetEntityIndex(), pSpr.GetEntityIndex() );
	}

	pSpr.SetLocalOrigin( vecPingPos );
	SetNetPropInt( pSpr, "m_clrRender", pingInfo[m_colour] );
	AddThinkToEnt( pSpr, "Think" );

	local sc = pSpr.GetScriptScope();
	sc.m_nRenderAlpha <- 255;
	sc.m_hUser <- user;
	sc.m_nPingType <- pingType;
	sc.m_flDieTime <- Time() + pingInfo[m_lifetime];
	sc.m_hTarget <- player;
	sc.Think <- SpriteThinkChatter;

	local state = 0;

	if ( player.IsImmobilized() )
		state = 0x1;

	if ( GetNetPropInt( player, "m_Local.m_bDucked" ) )
		state = state | 0x2;

	sc.m_nState <- state;
}

UpdateOffscreenIndicators = function( player, user )
{
	local indicators = user[m_OffscreenIndicators];
	local eyePos, eyeAng, forward, left, up,
		  fov, foviw,
		  cosz = COS_53DEG, cosy = COS_37DEG;

	// for each of my team's pings
	foreach ( pl in m_Teams[ GetNetPropInt( player, "m_iTeamNum" ) ] ) if ( pl.IsValid() )
	{
		local pings = m_Users[ pl.GetEntityIndex() - 1 ][m_Pings];

		// Only calculate FOV if any pings exist
		if ( ( 0 in pings || 0 in indicators ) && !eyePos )
		{
			eyePos = player.EyePosition();
			eyeAng = player.EyeAngles();
			forward = eyeAng.Forward();
			left = eyeAng.Left();
			up = eyeAng.Up();

			fov = GetNetPropInt( player, "m_iFOV" );
			local fovstart = GetNetPropInt( player, "m_iFOVStart" );

			if ( fov || fovstart != 90 )
			{
				if ( !fov )
					fov = 90;

				// 7 ticks in the future roughly matches client interpolation time
				local timebase = Time() + TICK_INTERVAL * 7.0;
				local fovtime = GetNetPropFloat( player, "m_flFOVTime" );
				local fovrate = GetNetPropFloat( player, "m_Local.m_flFOVRate" );
				local dt = ( timebase - fovtime ) / fovrate;

				if ( dt < 1.0 )
				{
					// VS.SimpleSplineRemapVal( dt, 0.0, 1.0, fovstart, fov )
					local sqr = dt * dt;
					fov = fovstart + ( fov - fovstart ) * ( 3.0 * sqr - 2.0 * sqr * dt );
				}

				foviw = tan( fov * DEG2RADDIV2 );
				cosy = cos( PIDIV2 - atan( foviw * 1.333333 ) );
				cosz = cos( PIDIV2 - atan( foviw * 0.75 ) );
			}
		}

		foreach ( target in pings )
			if ( target && target.IsValid() &&
					// Ignore self pings if not in whitelist
					( pl != player || target.GetScriptScope().m_nPingType in m_PingHasSelfOffscreen ) )
		{
			local delta = target.GetOrigin() - eyePos;
			local dist = delta.Norm();

			local i = indicators.find( target );

			// Cheaper than checking view matrix
			if ( delta.Dot( forward ) < COS_53DEG ||
					fabs( delta.Dot( up ) ) > cosz ||
					fabs( delta.Dot( left ) ) > cosy )
			{
				if ( i == null )
				{
					indicators.append( target );
					indicators.append( null );
					indicators.append( delta );
					indicators.append( dist );
				}
				else
				{
					indicators[ i + 2 ] = delta;
					indicators[ i + 3 ] = dist;
					local pSpr = indicators[ i + 1 ];
					local sc = pSpr.GetScriptScope();
					sc.m_bVisible = false;
				}
			}
			// Ping is visible
			else
			{
				if ( i != null )
				{
					local pSpr = indicators[ i + 1 ];
					local sc = pSpr.GetScriptScope();
					sc.m_bVisible = true;
					pSpr.__KeyValueFromInt( "renderamt", sc.m_nRenderAlpha = 0 );
					if ( sc.m_hDetailIcon )
						sc.m_hDetailIcon.__KeyValueFromInt( "renderamt", 0 );
				}
			}
		}
	}

	local sc, pingType;
	local len = indicators.len();

	if ( len && !eyePos )
	{
		eyePos = player.EyePosition();
		eyeAng = player.EyeAngles();
		forward = eyeAng.Forward();
		left = eyeAng.Left();
		up = eyeAng.Up();

		forward.z = 0.0;
	}

	for ( local i = 0; i < len; i += 4 )
	{
		local target = indicators[ i ];
		local pSpr = indicators[ i + 1 ];

		// Target is dead and offscreen should die next frame
		if ( !target.IsValid() )
			continue;

		if ( pSpr && pSpr.IsValid() )
		{
			sc = pSpr.GetScriptScope();
			if ( sc.m_bVisible )
				continue;

			pingType = target.GetScriptScope().m_nPingType;

			// Type change in reused ping
			if ( sc.m_nPingType != pingType )
			{
				sc.m_nPingType = pingType;

				SetNetPropInt( pSpr, "m_clrRender", GetNetPropInt( target, "m_clrRender" ) );

				local pDetailIcon = sc.m_hDetailIcon;
				if ( pDetailIcon )
				{
					if ( !( pingType in m_PingIsUsable ) )
					{
						if (PING_DEBUG_VERBOSE)
						{
							printf( "player[%d] reuse offscreen[%d]->ping[%d], remove detail[%d]\n",
									player.GetEntityIndex(),
									pSpr.GetEntityIndex(),
									target.GetEntityIndex(),
									sc.m_hDetailIcon.GetEntityIndex() );
						}

						pDetailIcon.Kill();
						sc.m_hDetailIcon = null;
					}
				}
				else
				{
					if ( pingType in m_PingIsUsable )
					{
						pDetailIcon =
							sc.m_hDetailIcon = SpawnEntityFromTable( "env_sprite", offscreen_interactable_sprite_kv );
						SetNetPropEntity( pDetailIcon, "m_hMoveParent", GetNetPropEntity( player, "m_hViewModel" ) );

						if (PING_DEBUG_VERBOSE)
						{
							printf( "player[%d] reuse offscreen[%d]->ping[%d], new detail[%d]\n",
									player.GetEntityIndex(),
									pSpr.GetEntityIndex(),
									target.GetEntityIndex(),
									sc.m_hDetailIcon.GetEntityIndex() );
						}
					}
				}
			}
		}
		else
		{
			indicators[ i + 1 ] = pSpr = SpawnEntityFromTable( "env_sprite", offscreen_sprite_kv );
			SetNetPropInt( pSpr, "m_clrRender", GetNetPropInt( target, "m_clrRender" ) & 0x00FFFFFF );
			SetNetPropEntity( pSpr, "m_hMoveParent", GetNetPropEntity( player, "m_hViewModel" ) );
			AddThinkToEnt( pSpr, "Think" );
			pSpr.ValidateScriptScope();
			sc = pSpr.GetScriptScope();
			sc.m_nRenderAlphaTarget <- 0;
			sc.m_nRenderAlpha <- 0;
			sc.m_bVisible <- false;
			sc.m_hTarget <- target;
			sc.m_flDieTime <- 0.0;
			pingType = sc.m_nPingType <- target.GetScriptScope().m_nPingType;
			sc.m_hUser <- user;
			sc.Think <- SpriteThinkOffscreen;

			if ( pingType in m_PingIsUsable )
			{
				local pDetailIcon =
					sc.m_hDetailIcon <- SpawnEntityFromTable( "env_sprite", offscreen_interactable_sprite_kv );
				// Sprite tries being clever and disobeys parallel orientation
				// when parented to the directional sprite, complicating this logic
				SetNetPropEntity( pDetailIcon, "m_hMoveParent", GetNetPropEntity( player, "m_hViewModel" ) );
			}
			else
			{
				sc.m_hDetailIcon <- null;
			}

			if (PING_DEBUG_VERBOSE)
			{
				if ( sc.m_hDetailIcon )
				{
					printf( "player[%d] new offscreen[%d]->ping[%d], detail[%d]\n",
							player.GetEntityIndex(),
							pSpr.GetEntityIndex(),
							target.GetEntityIndex(),
							sc.m_hDetailIcon.GetEntityIndex() );
				}
				else
				{
					printf( "player[%d] new offscreen[%d]->ping[%d]\n",
							player.GetEntityIndex(),
							pSpr.GetEntityIndex(),
							target.GetEntityIndex() );
				}
			}
		}

		local delta = indicators[ i + 2 ];
		local dist = indicators[ i + 3 ];

		local fwd = 15.0;
		local deltaY = -delta.Dot( left );
		local deltaZ = delta.Dot( up );
		local deltaLen = PING_SYSTEM_OFFSCREEN_INDICATOR_RADIUS / sqrt( deltaY * deltaY + deltaZ * deltaZ );
		local angle = ( atan2( deltaY, -deltaZ ) + PI ) * RAD2DEG;

		// Point downwards if the target is behind and the player is looking up
		// It can be confusing when the arrow is pointing up for a target behind.
		// Not using 2D forward vector for angle because
		// that still points up for targets on the sides
		if ( deltaZ > 0.0 && delta.Dot( forward ) < 0.0 )
		{
			deltaZ = -deltaZ;
			angle = 180.0 - angle;
		}

		if ( fov )
		{
			if ( fov <= 90 )
			{
				fwd /= foviw;
			}
			else
			{
				deltaLen *= foviw;
			}
		}

		// Depth sort
		// Prioritise warning pings
		if ( pingType in m_PingIsWarning )
		{
			eyePos.x = fwd - i * 0.01;
		}
		else
		{
			eyePos.x = fwd + i * 0.01;
		}

		eyePos.y = deltaY * deltaLen;

		if ( m_nOffscreenIndicatorStyle )
		{
			eyePos.z = PING_SYSTEM_OFFSCREEN_INDICATOR_RADIUS;
		}
		else
		{
			eyePos.z = deltaZ * deltaLen;
		}

		pSpr.SetLocalOrigin( eyePos );

		local pDetailIcon = sc.m_hDetailIcon;
		if ( pDetailIcon )
			pDetailIcon.SetLocalOrigin( eyePos );

		// Angle has to be set on server as client cannot access this data
		eyeAng.x = eyeAng.y = 0.0; eyeAng.z = -angle;
		pSpr.SetLocalAngles( eyeAng );

		// VS.RemapValClamped( dist, 1536.0, 3072.0, 255.0, 15.0 )
		dist = ( dist - 1536.0 ) * 0.00065104166666667;

		if ( dist <= 0.0 )
		{
			dist = 255;
		}
		else if ( dist >= 1.0 )
		{
			dist = 15;
		}
		else
		{
			dist = ( 255.0 - 240.0 * dist ).tointeger();
		}

		sc.m_nRenderAlphaTarget = dist;
	}
}

local ThinkWheel = function()
{
	local alpha = m_nRenderAlpha;
	local alphaTarget = 255;

	if ( alpha != alphaTarget )
	{
		local delta = alphaTarget - alpha;
		local speed = 63;

		if ( delta > speed )
		{
			alpha += speed;
		}
		else if ( -speed > delta )
		{
			alpha -= speed;
		}
		else
		{
			alpha = alphaTarget;
		}

		self.__KeyValueFromInt( "renderamt", m_nRenderAlpha = alpha );
		m_Item1.__KeyValueFromInt( "renderamt", alpha );
		m_Item2.__KeyValueFromInt( "renderamt", alpha );
		m_Item3.__KeyValueFromInt( "renderamt", alpha );
		m_Item4.__KeyValueFromInt( "renderamt", alpha );
	}

	return PingWheelUpdate( m_hPlayer, m_hUser, 1 );
}

PingWheelUpdate = function( player, user, state )
{
	local fov = GetNetPropInt( player, "m_iFOV" );
	local fovstart = GetNetPropInt( player, "m_iFOVStart" );
	local fwd = 10.0;

	if ( fov || fovstart != 90 )
	{
		if ( !fov )
			fov = 90;

		local timebase = Time() + TICK_INTERVAL * 7.0;
		local fovtime = GetNetPropFloat( player, "m_flFOVTime" );
		local fovrate = GetNetPropFloat( player, "m_Local.m_flFOVRate" );
		local dt = ( timebase - fovtime ) / fovrate;

		if ( dt < 1.0 )
		{
			local sqr = dt * dt;
			fov = fovstart + ( fov - fovstart ) * ( 3.0 * sqr - 2.0 * sqr * dt );
		}

		if ( fov <= 90 )
			fwd /= tan( fov * DEG2RADDIV2 );
	}

	if ( state )
	{
		if ( !m_hTarget.IsValid() )
		{
			PingWheelClose( player, user, 0 );
			user[m_flPingButtonTime] = 0.0;
			return -1;
		}

		local eyeAng = player.EyeAngles();
		local dtx = eyeAng.x - m_vecLastEyeAngles.x;
		local dty = eyeAng.y - m_vecLastEyeAngles.y;
		m_vecLastEyeAngles = eyeAng;

		if ( ( dtx || dty ) && fabs(dtx) + fabs(dty) > 0.15 )
		{
			local angle = atan2( dty * DEG2RAD, dtx * DEG2RAD ) + PI;

			// 0|360
			if ( angle < 0.78539816339745 || angle > 5.4977871437821 )
			{
				m_iSelection = 1;
				SetNetPropFloat( self, "m_flFrame", 1.0 );
			}
			// 90
			else if ( angle < 2.3561944901923 && angle > 0.78539816339745 )
			{
				m_iSelection = 2;
				SetNetPropFloat( self, "m_flFrame", 2.0 );
			}
			// 180
			else if ( angle < 3.9269908169872 && angle > 2.3561944901923 )
			{
				m_iSelection = 3;
				SetNetPropFloat( self, "m_flFrame", 3.0 );
			}
			// 270
			else if ( angle < 5.4977871437821 && angle > 3.9269908169872 )
			{
				m_iSelection = 4;
				SetNetPropFloat( self, "m_flFrame", 4.0 );
			}
		}

		self.SetLocalOrigin( Vector( fwd ) );
		return 0.0;
	}
	else
	{
		if (PING_DEBUG)
			Assert( 0 in user[m_Pings] );

		local target = user[m_Pings].top();

		if ( target.IsValid() && target.GetScriptScope().m_nRenderAlpha == 255 )
		{
			if (PING_DEBUG)
				Assert( !user[m_hPingWheel] );

			local pWheel =
				user[m_hPingWheel] = SpawnEntityFromTable( "env_sprite", wheel_sprite_kv );
			SetNetPropInt( pWheel, "m_clrRender", 0x00FFFFFF );
			SetNetPropEntity( pWheel, "m_hMoveParent", GetNetPropEntity( player, "m_hViewModel" ) );

			AddThinkToEnt( pWheel, "Think" );
			pWheel.ValidateScriptScope();
			local sc = pWheel.GetScriptScope();

			{
				local item1 = SpawnEntityFromTable( "env_sprite", wheel_item_sprite_kv );
				local item2 = SpawnEntityFromTable( "env_sprite", wheel_item_sprite_kv );
				local item3 = SpawnEntityFromTable( "env_sprite", wheel_item_sprite_kv );
				local item4 = SpawnEntityFromTable( "env_sprite", wheel_item_sprite_kv );

				SetNetPropInt( item1, "m_clrRender", 0x00FFFFFF );
				SetNetPropInt( item2, "m_clrRender", 0x00FFFFFF );
				SetNetPropInt( item3, "m_clrRender", 0x00FFFFFF );
				SetNetPropInt( item4, "m_clrRender", 0x00FFFFFF );

				SetNetPropEntity( item1, "m_hMoveParent", pWheel );
				SetNetPropEntity( item2, "m_hMoveParent", pWheel );
				SetNetPropEntity( item3, "m_hMoveParent", pWheel );
				SetNetPropEntity( item4, "m_hMoveParent", pWheel );

				SetNetPropFloat( item1, "m_flFrame", 0.0 );
				SetNetPropFloat( item2, "m_flFrame", 1.0 );
				SetNetPropFloat( item3, "m_flFrame", 2.0 );
				SetNetPropFloat( item4, "m_flFrame", 3.0 );

				local z = -0.1;
				local dist = 1.2 * wheel_item_sprite_kv.scale;
				item1.SetLocalOrigin( Vector( z, 0, dist ) );
				item2.SetLocalOrigin( Vector( z, -dist, 0 ) );
				item3.SetLocalOrigin( Vector( z, 0, -dist ) );
				item4.SetLocalOrigin( Vector( z, dist, 0 ) );

				sc.m_Item1 <- item1;
				sc.m_Item2 <- item2;
				sc.m_Item3 <- item3;
				sc.m_Item4 <- item4;
			}

			sc.m_nRenderAlpha <- 0;
			sc.m_hPlayer <- player;
			sc.m_hUser <- user;
			sc.m_hTarget <- target;
			sc.m_iSelection <- null;
			sc.m_vecLastEyeAngles <- player.EyeAngles();
			sc.Think <- ThinkWheel;

			pWheel.SetLocalOrigin( Vector( fwd ) );

			if (PING_DEBUG_VERBOSE)
			{
				printf( "player[%d] wheel[%d] open target ping[%d]\n",
						player.GetEntityIndex(),
						pWheel.GetEntityIndex(),
						sc.m_hTarget.GetEntityIndex() );
			}
		}
		else if (PING_DEBUG_VERBOSE)
		{
			if ( !target.IsValid() )
			{
				print( "player[%d] wheel[-1] open no target\n",
						player.GetEntityIndex() );
			}
			else if ( target.GetScriptScope().m_nRenderAlpha != 255 )
			{
				printf( "player[%d] wheel[-1] open target is fading %d\n",
						player.GetEntityIndex(),
						target.GetScriptScope().m_nRenderAlpha );
			}
		}
	}
}

PingWheelClose = function( player, user, success )
{
	local pWheel = user[m_hPingWheel];

	if ( pWheel && pWheel.IsValid() )
	{
		local sc = pWheel.GetScriptScope();

		if ( success )
		{
			local target, targetsc;

			if ( sc.m_iSelection &&
					( target = sc.m_hTarget ).IsValid() &&
					( targetsc = target.GetScriptScope() ).m_nRenderAlpha == 255 )
			{
				if (PING_DEBUG_VERBOSE)
				{
					printf( "player[%d] wheel[%d] apply %d target ping[%d]\n",
							player.GetEntityIndex(),
							pWheel.GetEntityIndex(),
							sc.m_iSelection,
							target.GetEntityIndex() );
				}

				if (PING_DEBUG)
					Assert( sc.m_iSelection - 1 in m_PingWheelItems );

				local selectedPing = m_PingWheelItems[ sc.m_iSelection - 1 ];
				local pingInfo = m_PingLookup[ selectedPing ];
				target.SetModel( pingInfo[0] );
				SetNetPropInt( target, "m_clrRender", pingInfo[m_colour] );
				SetNetPropFloat( target, "m_flFrame", 0.0 );

				targetsc.m_flDieTime = Time() + pingInfo[m_lifetime];

				// If this ping had an offscreen indicator and it's no more
				if ( m_bOffscreenIndicators && targetsc.m_nPingType in m_PingHasSelfOffscreen )
					RemoveOffscreenIndicatorsOfPing( target, user );

				if ( selectedPing == PingType.COUNTDOWN )
				{
					targetsc.m_flFrame <- 0.0;
					targetsc.Think = SpriteThinkCountdown;
					if ( !( "m_hTarget" in targetsc ) )
						targetsc.m_hTarget <- null;

					AddThinkToEnt( target, "Think" );
				}
				else if ( targetsc.Think == SpriteThink )
				{
					// Extend time
					AddThinkToEnt( target, "Think" );
					targetsc.Think = SpriteThink;
					targetsc.m_bInitRem = true;
					targetsc.m_flDieTime = pingInfo[m_lifetime];
				}
				else if ( targetsc.m_nPingType == PingType.COUNTDOWN )
				{
					// Changing countdown back to another wheel ping means it had a target
					// but its original type is lost.
					// Convert to static ping
					targetsc.Think = SpriteThink;
					targetsc.m_bInitRem <- true;
					targetsc.m_flDieTime = pingInfo[m_lifetime];
				}

				targetsc.m_nPingType = selectedPing;
			}
			else if (PING_DEBUG_VERBOSE)
			{
				if ( !sc.m_iSelection )
				{
					printf( "player[%d] wheel[%d] apply no selection\n",
							player.GetEntityIndex(),
							pWheel.GetEntityIndex() );
				}
				else if ( !target.IsValid() )
				{
					printf( "player[%d] wheel[%d] apply no target\n",
							player.GetEntityIndex(),
							pWheel.GetEntityIndex() );
				}
				else if ( target.GetScriptScope().m_nRenderAlpha != 255 )
				{
					printf( "player[%d] wheel[%d] apply target is fading\n",
							player.GetEntityIndex(),
							pWheel.GetEntityIndex() );
				}
			}
		}

		AddThinkToEnt( pWheel, null );
		RemoveWheel_user( user );
		user[m_hPingWheel] = null;
	}
}

local s_tr =
{
	start = null,
	end = null,
	mask = MASK_SHOT_HULL & (~CONTENTS_WINDOW),
	ignore = null,
	pos = null,
	hit = null,
	enthit = null,
	startsolid = null
}

function PingEntity( player, pEnt, vecPingPos = null )
{
	local pingType = PingType.BASE;
	local szClassname = pEnt.GetClassname();

	switch ( szClassname )
	{
		case "player":

			// player is survivor
			if ( player.IsSurvivor() )
			{
				// teammate (survivor)
				if ( pEnt.IsSurvivor() )
				{
					local hDominator = pEnt.GetSpecialInfectedDominatingMe();
					if ( hDominator )
					{
						if ( hDominator.GetZombieType() == m_ZombieTypeForSI.SMOKER )
						{
							// Smoker can dominate from far away, ping the survivor as incap
							if ( GetNetPropInt( pEnt, "m_isHangingFromTongue" ) )
								pingType = PingType.INCAP;
						}
						else
						{
							// The SI should be on top of the survivor, ping the SI as warning
							pingType = PingType.WARNING;
							pEnt = hDominator;
						}
					}
					else if ( pEnt.IsOnFire() )
					{
						pingType = PingType.ONFIRE;
					}
					else if ( pEnt.IsIncapacitated() )
					{
						pingType = PingType.INCAP;
					}
					else
					{
						pingType = PingType.TEAMMATE;
					}
				}
				// enemy (SI)
				else
				{
					if ( pEnt.IsOnFire() )
					{
						pingType = PingType.WARNING_ONFIRE;
					}
					else
					{
						pingType = PingType.WARNING;
					}
				}
			}
			// player is SI
			else
			{
				// enemy (survivor)
				if ( pEnt.IsSurvivor() )
				{
					if ( pEnt.IsOnFire() )
					{
						pingType = PingType.WARNING_ONFIRE;
					}
					else
					{
						pingType = PingType.WARNING;
					}
				}
				// teammate (SI)
				else
				{
					pingType = PingType.TEAMMATE;
				}
			}

			vecPingPos = pEnt.EyePosition();
			vecPingPos.z = GetHeadOrigin( pEnt ).z + 32.0;
			break;

		case "witch":

			if ( !player.IsSurvivor() )
				break;

			pingType = PingType.WARNING;

			vecPingPos = pEnt.GetCenter();
			vecPingPos.z = GetHeadOrigin( pEnt ).z + 32.0;
			break;

		case "infected":

			if ( !player.IsSurvivor() )
				break;

			if ( m_UncommonModels.find( pEnt.GetModelName() ) != null )
			{
				vecPingPos = GetHeadOrigin( pEnt ) - pEnt.GetOrigin();
				vecPingPos.x = vecPingPos.y = 0.0;
				vecPingPos.z += 32.0;

				return PlayerPing( player, PingType.UNCOMMON, vecPingPos, pEnt, pEnt );
			}

			pingType = PingType.INFECTED;
			break;

		case "prop_physics":
		{
			if ( !player.IsSurvivor() )
				break;

			local mdl = pEnt.GetModelName();
			if ( mdl in m_PingTypeForPhysModel )
			{
				pingType = m_PingTypeForPhysModel[mdl];
				vecPingPos = pEnt.GetCenter();
				vecPingPos.z += 12.0;
			}
			else
			{
				// Is there an item on me the player wanted to ping?
				for ( local item; item = FindEntityInSphere( item, vecPingPos, PING_SYSTEM_ITEM_SEARCH_RADIUS ); )
				{
					local szClassname = item.GetClassname();
					// Prevent infinite loop by ignoring prop_physics
					if ( ( szClassname in m_IsPingableEntity ) &&
							( szClassname != "prop_physics" ) &&
							!GetNetPropEntity( item, "m_hOwnerEntity" ) )
					{
						if (PING_DEBUG)
							printf( "      ping item in physics prop vicinity: %s\n", ""+item );

						return PingEntity( player, item, vecPingPos );
					}
				}
			}

			break;
		}
		case "prop_health_cabinet":
		{
			if ( !player.IsSurvivor() )
				break;

			if ( GetNetPropInt( pEnt, "m_isUsed" ) == 1 )
			{
				s_tr.start = vecPingPos;
				s_tr.end = vecPingPos + player.EyeAngles().Forward().Scale( MAX_COORD_FLOAT );
				s_tr.ignore = pEnt;
				TraceLine( s_tr );

				local enthit = s_tr.enthit;
				if ( enthit.GetEntityIndex() )
				{
					if (PING_DEBUG)
					{
						printf( "found item in cabinet %s\n", ""+enthit );
						DebugDrawLine( s_tr.start, s_tr.pos, 255, 0, 0, true, 5.0 );
					}

					return PingEntity( player, enthit, vecPingPos );
				}

				if (PING_DEBUG)
					print( "could not found item in cabinet\n" );
			}

			pingType = PingType.MEDCAB;
			local fw = pEnt.GetForwardVector();
			local rt = vecPingPos;
			rt.x = fw.y;
			rt.y = -fw.x;
			rt.z = 0.0;
			rt.Norm();
			local up = rt.Cross(fw);
			up.Norm();
			vecPingPos = pEnt.GetCenter() + fw * 8.0 + up * 40.0;
			break;
		}
		case "prop_car_alarm":
			if ( !GetNetPropInt( pEnt, "m_bDisabled" ) )
				pingType = PingType.WARNING_MILD;
			break;

		case "prop_door_rotating":
			pingType = PingType.DOOR;
			break;

		case "prop_door_rotating_checkpoint":
			pingType = PingType.SAFEROOM;
			break;

		case "prop_fuel_barrel":
			pingType = PingType.FUELBARREL;
			vecPingPos = pEnt.GetCenter();
			vecPingPos.z += 32.0;
			break;

		case "prop_minigun":
		case "prop_minigun_l4d1":
			pingType = PingType.MINIGUN;
			vecPingPos = pEnt.GetCenter();
			vecPingPos.z += 32.0;
			break;

		case "upgrade_ammo_explosive":
			if ( !player.IsSurvivor() )
				break;

			pingType = PingType.UPGRADEPACK_EXP;
			vecPingPos = pEnt.GetCenter();
			vecPingPos.z += 12.0;
			break;

		case "upgrade_ammo_incendiary":
			if ( !player.IsSurvivor() )
				break;

			pingType = PingType.UPGRADEPACK_INC;
			vecPingPos = pEnt.GetCenter();
			vecPingPos.z += 12.0;
			break;

		case "upgrade_laser_sight":
			if ( !player.IsSurvivor() )
				break;

			pingType = PingType.UPGRADEPACK_LASER;
			vecPingPos = pEnt.GetCenter();
			vecPingPos.z += 12.0;
			break;

		case "survivor_death_model":
			pingType = PingType.DEAD_SURVIVOR;
			vecPingPos = pEnt.GetCenter();
			vecPingPos.z += 12.0;
			break;

		case "func_simpleladder":
		case "func_ladder":
			pingType = PingType.LADDER;
			break;

		case "trigger_finale":
			if ( !player.IsSurvivor() )
				break;

			if ( !GetNetPropInt( pEnt, "m_bDisabled" ) )
			{
				pingType = PingType.INTERACTABLE;

				// Different models have different sizes,
				// put the ping closer to the player
				vecPingPos = pEnt.GetCenter();
				local delta = player.EyePosition() - vecPingPos;
				delta.Norm();
				vecPingPos = vecPingPos + delta * 8.0;
			}

			break;

		// Partial matches and undefined entities
		default:
		{
			if ( szClassname == "worldspawn" )
				pEnt = null;

			if ( !player.IsSurvivor() )
				break;

			// All weapons go through here
			if ( szClassname.find("weapon") == 0 )
			{
				if (PING_DEBUG_VERBOSE)
				{
					printf( "          %s->m_weaponID: %d\n",
							szClassname, GetNetPropInt( pEnt, "m_weaponID" ) );
					//printf( "          %s->m_iszMeleeWeapon: %s\n",
					//		szClassname, ""+NetProps.GetPropString( pEnt, "m_iszMeleeWeapon" ) );
					//printf( "          %s->m_iszWeaponToSpawn: %s\n",
					//		szClassname, ""+NetProps.GetPropString( pEnt, "m_iszWeaponToSpawn" ) );
					if ( GetNetPropInt( pEnt, "m_fEffects" ) & EF_NODRAW )
						print( "          nodraw\n" );
				}

				// check if this spawn entity is visible
				if ( !(( szClassname in m_IsSpawnEntity ) && ( GetNetPropInt( pEnt, "m_fEffects" ) & EF_NODRAW )) )
				{
					if ( szClassname in m_PingTypeForWeaponClass )
					{
						pingType = m_PingTypeForWeaponClass[ szClassname ];

						if (PING_DEBUG_VERBOSE)
							print( "            match classname\n" );
					}
					else
					{
						local szModelName = pEnt.GetModelName();

						// full model name match
						if ( szModelName in m_PingTypeForWeaponModel )
						{
							pingType = m_PingTypeForWeaponModel[ szModelName ];

							if (PING_DEBUG_VERBOSE)
								print( "            match modelname\n" );
						}
						// fallback
						else
						{
							if ( szClassname == "weapon_melee" )
								pingType = PingType.WEAPON_FIREAXE;
							else // szClassname == "weapon"
								pingType = PingType.WEAPON_PISTOL;

							if (PING_DEBUG)
								error("unrecognised weapon model and class '"+szClassname+"', '"+szModelName+"'\n");
						}
					}

					vecPingPos = pEnt.GetCenter();
					vecPingPos.z += 12.0;
				}
				else if (PING_DEBUG)
				{
					error( "            NO MATCH\n" );
				}

				break;
			} // weapon class

			// undefined entity type, use fallback pos
			// this is most likely worldspawn
			if (PING_DEBUG) Assert( vecPingPos );

			// ping the first valid entity in the vicinity
			// NOTE: The distance is calculated from the collision box.
			if (PING_DEBUG_DRAW)
			{
				VS.DrawSphere( vecPingPos,
						PING_SYSTEM_ITEM_SEARCH_RADIUS,
						5, 5,
						64, 64, 64, false,
						PING_SYSTEM_LIFETIME_DEFAULT );
			}

			for ( local item; item = FindEntityInSphere( item, vecPingPos, PING_SYSTEM_ITEM_SEARCH_RADIUS ); )
			{
				// Volume entities will be found before any of the items,
				// check classname of all entities in this radius
				// and check if it's already being carried by a player
				// (because carried items are invisible at player origin)
				//
				// NOTE: Dropped prop_physics retain their owner entity.
				// Checking for move parent instead of owner here
				// to be able to ping dropped prop_physics.

				local szClassname = item.GetClassname();
				if ( szClassname in m_IsPingableEntity )
				{
					if ( szClassname != "prop_physics" )
					{
						if ( GetNetPropEntity( item, "m_hOwnerEntity" ) ||
								( GetNetPropInt( item, "m_fEffects" ) & EF_NODRAW ) )
							continue;
					}
					else
					{
						local moveparent = item.GetMoveParent();
						if ( moveparent && moveparent.GetClassname() == "player" )
							continue;
					}

					if (PING_DEBUG_VERBOSE)
					{
						local c = 0;
						for ( local i; i = FindEntityInSphere( i, vecPingPos, PING_SYSTEM_ITEM_SEARCH_RADIUS ); )
						{
							++c;
							if ( i != item )
							{
								printf( "   %s\n", ""+i );
							}
							else
							{
								printf( "*  %s\n", ""+i );
							}
						}

						printf( "  iterated %d entities\n", c );
					}

					if (PING_DEBUG)
						printf( "      ping item in vicinity: %s\n", ""+item );

					return PingEntity( player, item, vecPingPos );
				}
			}
		} // classname switch default
	} // classname switch

	if (PING_DEBUG_DRAW)
		DrawEntAxis( pEnt, PING_SYSTEM_LIFETIME_DEFAULT );

	return PlayerPing( player, pingType, vecPingPos, pEnt );
}

function PingTrace( player )
{
	local eyePos = player.EyePosition();
	s_tr.start = eyePos;
	s_tr.end = eyePos + player.EyeAngles().Forward().Scale( MAX_TRACE_LENGTH );
	s_tr.ignore = player;
	TraceLine( s_tr );

	if (PING_DEBUG)
	{
		if ( ( s_tr.enthit && s_tr.enthit != Entities.First() ) || s_tr.startsolid )
		{
			printf( "player[%d] trace: " + s_tr.enthit, player.GetEntityIndex() );

			if ( !(""+s_tr.enthit).find( s_tr.enthit.GetClassname() ) )
				printf( "[%s]", s_tr.enthit.GetClassname() );

			printf( "[%s]\n", s_tr.enthit.GetModelName() );

			if ( s_tr.startsolid )
			{
				print( "    startsolid\n" );
				s_tr.startsolid = null;
			}
		}
	}

	return PingEntity( player, s_tr.enthit, s_tr.pos );
}

function OnCommandPing( player )
{
	// If player is being dominated, skip trace and ping self
	local hMyDominator = player.GetSpecialInfectedDominatingMe();
	if ( hMyDominator )
	{
		local type = PingType.WARNING;

		// Smoker can dominate from far away, ping self as incap
		if ( hMyDominator.GetZombieType() == m_ZombieTypeForSI.SMOKER )
		{
			if (PING_DEBUG)
			{
				printf( "smoker[%d]->player[%d]\n", hMyDominator.GetEntityIndex(), player.GetEntityIndex() );
				if (PING_DEBUG_VERBOSE)
				{
					printf( "  player.m_isHangingFromTongue %d\n", GetNetPropInt( player, "m_isHangingFromTongue" ) );
					printf( "  player.m_reachedTongueOwner  %d\n", GetNetPropInt( player, "m_reachedTongueOwner" ) );
					printf( "  player.m_isProneTongueDrag   %d\n", GetNetPropInt( player, "m_isProneTongueDrag" ) );
				}
			}

			if ( !GetNetPropInt( player, "m_isHangingFromTongue" ) )
				return PingTrace( player );

			hMyDominator = player;
			type = PingType.INCAP;
		}
		else if (PING_DEBUG)
		{
			printf( "dominator[%d]->player[%d]\n", hMyDominator.GetEntityIndex(), player.GetEntityIndex() );
		}

		local vecPingPos = hMyDominator.EyePosition();
		vecPingPos.z = GetHeadOrigin( hMyDominator ).z + 32.0;

		return PlayerPing( player, type, vecPingPos, hMyDominator );
	}

	return PingTrace( player );
}

function OnGameEvent_player_say( event )
{
	if (PING_DEBUG)
	{
		if ( event.text[0] == '@' )
		{
			local env = getroottable();
			local i = event.text.find( "@", 1 );
			local exec;
			if ( i != null )
			{
				local envstr = event.text.slice( 1, i );
				if ( envstr.find( "." ) != null )
				{
					printf( "env '%s' not supported\n", envstr );
					return;
				}

				if ( !(envstr in env) )
				{
					printf( "env '%s' not found\n", envstr );
					return;
				}

				env = env[envstr];

				exec = event.text.slice( i+1, event.text.len() );
			}
			else
			{
				exec = event.text.slice( 1, event.text.len() );
			}

			printf( "EXEC %s\n", exec );

			try
			{
				compilestring( exec ).call( env );
			}
			catch ( err )
			{
				printf( "ERROR %s\n", err );
			}

			return;
		}
	}

	if ( event.text[0] != '!' || event.text.find( "!ping_system" ) != 0 )
		return;

	local player = GetPlayerFromUserID( event.userid );
	if ( GetListenServerHost() != player )
		return;

	local _Msg = Msg;
	local ClientPrint = ClientPrint;
	Msg = function( msg )
	{
		return ClientPrint( null, DirectorScript.HUD_PRINTTALK, msg );
	}

	local argv = split( event.text, " " );
	local commands =
		[
			"autoping", "duration", "colour",
			"scale", "maxcount", "sound",
			"button", "chatter", "wheel",
			"offscreen", "offscreenstyle", "offscreenscale",
			"savecfg", "loadcfg", "debug"
		];
	local strcmp = function( a, b )
	{
		local ret = 0;
		foreach ( i, c in a )
		{
			if ( i in b && b[i] == c )
			{
				++ret;
			}
			else
			{
				return 0;
			}
		}
		return ret;
	}
	local match = function( input, commands )
	{
		if ( !input )
			return;

		local bestcmd;
		local bestmatch = 0;

		foreach ( cmd in commands )
		{
			local t = strcmp( input, cmd );
			if ( t )
			{
				if ( t > bestmatch )
				{
					bestmatch = t;
					bestcmd = cmd;

					if ( input.len() == cmd.len() )
						return bestcmd;
				}
				else if ( t == bestmatch )
				{
					// ambiguous
					return;
				}
			}
		}

		return bestcmd;
	}

	local cmd;
	if ( 1 in argv )
		cmd = argv[1];

	switch ( match( cmd, commands ) )
	{
		case "autoping":
			if ( !(2 in argv) )
			{
				Msg( "Usage: !ping_system autoping <option>" );
				foreach ( v, _ in m_AutoBlock )
				{
					foreach ( name, val in CONST.PingResponse )
					{
						if ( val == v && name != "pass" )
						{
							Msg(Fmt( "\tPingResponse.%s\n", name ));
						}
					}
				}
				break;
			}

			try { argv[2] = argv[2].tointeger(); }
			catch ( err )
			{
				Msg(Fmt( "value is not an integer '%s'", argv[2] ));
				break;
			}

			PingSystem.DisableAutoPing( argv[2] );
			break;

		case "duration":
			if ( !(2 in argv) || !(3 in argv) )
			{
				Msg( "Usage: !ping_system duration <type> <time>" );
				break;
			}

			try { argv[2] = argv[2].tointeger(); }
			catch ( err )
			{
				local doErr = 1;
				try
				{
					// try parsing enum
					if ( argv[2] != "-1" && argv[2].find(".") == null )
					{
						argv[2] = "PingType." + argv[2].toupper();
					}
					else
					{
						argv[2] = argv[2].toupper();
					}

					argv[2] = compilestring( "return "+argv[2] )();

					if ( typeof argv[2] != "integer" )
						throw "";

					doErr = 0;
				}
				catch ( err2 )
				{
					doErr = 1;
				}

				if ( doErr )
				{
					Msg(Fmt( "invalid ping type '%s'", ""+argv[2] ));
					break;
				}
			}

			try { argv[3] = argv[3].tofloat(); }
			catch ( err )
			{
				Msg(Fmt( "value is not a float '%s'", argv[3] ));
				break;
			}

			PingSystem.SetPingDuration( argv[2], argv[3] );
			break;

		case "colour":
			if ( !(5 in argv) )
			{
				Msg( "Usage: !ping_system colour <type> <R> <G> <B>" );
				break;
			}

			try { argv[2] = argv[2].tointeger(); }
			catch ( err )
			{
				local doErr = 1;
				try
				{
					// try parsing enum
					if ( argv[2] != "-1" && argv[2].find(".") == null )
					{
						argv[2] = "PingType." + argv[2].toupper();
					}
					else
					{
						argv[2] = argv[2].toupper();
					}

					argv[2] = compilestring( "return "+argv[2] )();

					if ( typeof argv[2] != "integer" )
						throw "";

					doErr = 0;
				}
				catch ( err2 )
				{
					doErr = 1;
				}

				if ( doErr )
				{
					Msg(Fmt( "invalid ping type '%s'", ""+argv[2] ));
					break;
				}
			}

			try
			{
				argv[3] = argv[3].tointeger();
				argv[4] = argv[4].tointeger();
				argv[5] = argv[5].tointeger();
			}
			catch ( err )
			{
				Msg(Fmt( "invalid RGB %s,%s,%s", argv[3], argv[4], argv[5] ));
				break;
			}

			PingSystem.SetPingColour( argv[2], argv[3], argv[4], argv[5] );
			break;

		case "scale":
			if ( !(2 in argv) )
			{
				Msg( "Usage: !ping_system scale <value>" );
				break;
			}

			try { argv[2] = argv[2].tofloat(); }
			catch ( err )
			{
				Msg(Fmt( "value is not a float '%s'", argv[2] ));
				break;
			}

			PingSystem.SetScaleMultiplier( argv[2] );
			break;

		case "maxcount":
			if ( !(2 in argv) )
			{
				Msg( "Usage: !ping_system maxcount <amount>" );
				break;
			}

			try { argv[2] = argv[2].tointeger(); }
			catch ( err )
			{
				Msg(Fmt( "value is not an integer '%s'", argv[2] ));
				break;
			}

			PingSystem.SetMaxPingCount( argv[2] );
			break;

		case "sound":
			if ( !(2 in argv) )
			{
				Msg( "Usage: !ping_system sound <0|1>" );
				break;
			}

			try { argv[2] = argv[2].tointeger(); }
			catch ( err )
			{
				Msg(Fmt( "value is not an integer '%s'", argv[2] ));
				break;
			}

			PingSystem.DisableSound( !argv[2] );
			break;

		case "button":
			if ( !(2 in argv) )
			{
				Msg( "Usage: !ping_system button <0|1>" );
				break;
			}

			try { argv[2] = argv[2].tointeger(); }
			catch ( err )
			{
				Msg(Fmt( "value is not an integer '%s'", argv[2] ));
				break;
			}

			PingSystem.DisableButton( !argv[2] );
			break;

		case "chatter":
			if ( !(2 in argv) )
			{
				Msg( "Usage: !ping_system chatter <0|1>" );
				break;
			}

			try { argv[2] = argv[2].tointeger(); }
			catch ( err )
			{
				Msg(Fmt( "value is not an integer '%s'", argv[2] ));
				break;
			}

			PingSystem.DisableChatter( !argv[2] );
			break;

		case "wheel":
			if ( !(2 in argv) )
			{
				Msg( "Usage: !ping_system wheel <0|1>" );
				break;
			}

			try { argv[2] = argv[2].tointeger(); }
			catch ( err )
			{
				Msg(Fmt( "value is not an integer '%s'", argv[2] ));
				break;
			}

			PingSystem.DisableWheel( !argv[2] );
			break;

		case "offscreen":
			if ( !(2 in argv) )
			{
				Msg( "Usage: !ping_system offscreen <0|1>" );
				break;
			}

			try { argv[2] = argv[2].tointeger(); }
			catch ( err )
			{
				Msg(Fmt( "value is not an integer '%s'", argv[2] ));
				break;
			}

			PingSystem.DisableOffscreenIndicators( !argv[2] );
			break;

		case "offscreenstyle":
			if ( !(2 in argv) )
			{
				Msg( "Usage: !ping_system offscreenstyle <0|1>" );
				break;
			}

			try { argv[2] = argv[2].tointeger(); }
			catch ( err )
			{
				Msg(Fmt( "value is not an integer '%s'", argv[2] ));
				break;
			}

			PingSystem.SetOffscreenIndicatorStyle( argv[2] );
			break;

		case "offscreenscale":
			if ( !(2 in argv) )
			{
				Msg( "Usage: !ping_system offscreenscale <value>" );
				break;
			}

			try { argv[2] = argv[2].tofloat(); }
			catch ( err )
			{
				Msg(Fmt( "value is not a float '%s'", argv[2] ));
				break;
			}

			PingSystem.SetOffscreenIndicatorScale( argv[2] );
			break;

		case "loadcfg":
			switch ( LoadConfig() )
			{
				case 1:
				{
					Msg("Loaded settings from ping_system_settings.txt\n");
					break;
				}
				case 2:
				{
					Msg("No changes found in ping_system_settings.txt\n");
					break;
				}
				default:
				{
					Msg("No settings found.\n");
				}
			}

			break;

		case "savecfg":
			if ( SaveConfig() )
			{
				Msg("Saved settings in ping_system_settings.txt\n");
			}
			else
			{
				Msg("No changes, nothing is written.\n");
			}

			break;

		case "debug":
			Msg = _Msg;
			DebugPrint();
			break;

		default:
			Msg( "Usage: !ping_system <[c]ommand> [value...]" );
			Msg( "   autoping, duration, colour\n   scale, maxcount, sound\n   button, chatter, wheel\n   offscreen, offscreenstyle, offscreenscale\n   savecfg, loadcfg" );
	}

	Msg = _Msg;
}

::__CollectGameEventCallbacks( this );

//----------------------------------------------------------------------

local PingTypeName = function( type )
{
	foreach ( k, v in CONST.PingType )
	{
		if ( v == type )
			return "PingType."+k;
	}

	return ""+type;
}

function SetMaxPingCount( n )
{
	n = n.tointeger();

	if ( n < 1 )
		n = 1;
	else if ( n > 64 )
		n = 64;

	m_nMaxPingCount = n - 1;
	return Msg(Fmt( "PingSystem.SetMaxPingCount(%d)\n", n ));
}

function SetPingDuration( type, time )
{
	time = time.tofloat();

	if ( type == -1 )
	{
		foreach ( pingInfo in m_PingLookup )
		{
			pingInfo[m_lifetime] = time;
		}
	}
	else if ( type in m_PingLookup )
	{
		m_PingLookup[type][m_lifetime] = time;
	}
	else
	{
		time = null;
	}

	if ( time )
		return Msg(Fmt( "PingSystem.SetPingDuration(%s, %g)\n", PingTypeName(type), time ));
}

function SetPingColour( type, r, g, b )
{
	r = r.tointeger() & 0xFF;
	g = g.tointeger() & 0xFF;
	b = b.tointeger() & 0xFF;

	local col = r | ( g << 8 ) | ( b << 16 ) | 0xFF000000;

	if ( type == -1 )
	{
		foreach ( pingInfo in m_PingLookup )
		{
			pingInfo[m_colour] = col;
		}
	}
	else if ( type in m_PingLookup )
	{
		m_PingLookup[type][m_colour] = col;
	}
	else
	{
		col = null;
	}

	if ( col )
		return Msg(Fmt( "PingSystem.SetPingColour(%s, %d, %d, %d)\n", PingTypeName(type), r, g, b ));
}

function SetPingSound( type, soundDefault, soundAlert )
{
	if ( typeof soundDefault == "string" )
	{
		if ( !IsSoundPrecached( soundDefault ) )
			PrecacheSound( soundDefault );
	}
	else if ( soundDefault != null )
	{
		throw "invalid parameter 2, expected string|null";
	}
	else
	{
		soundDefault = PingSound.DEFAULT;
	}

	if ( typeof soundAlert == "string" )
	{
		if ( !IsSoundPrecached( soundAlert ) )
			PrecacheSound( soundAlert );
	}
	else if ( soundAlert != null )
	{
		throw "invalid parameter 3, expected string|null";
	}
	else
	{
		soundAlert = PingSound.ALERT;
	}

	if ( type == -1 )
	{
		foreach ( pingInfo in m_PingLookup )
		{
			if ( type in m_PingIsChatter )
				continue;

			pingInfo[m_soundDefault] = soundDefault;
			pingInfo[m_soundAlert] = soundAlert;
		}
	}
	else if ( type in m_PingLookup )
	{
		if ( type in m_PingIsChatter )
			return Msg(Fmt( "Cannot set ping sound on chatter ping \"%s\"\n", PingTypeName(type) ));

		local pingInfo = m_PingLookup[type];
		pingInfo[m_soundDefault] = soundDefault;
		pingInfo[m_soundAlert] = soundAlert;
	}

	soundDefault = ( soundDefault != PingSound.DEFAULT ) ? Fmt( "\"%s\"", soundDefault ) : "null";
	soundAlert = ( soundAlert != PingSound.ALERT ) ? Fmt( "\"%s\"", soundAlert ) : "null";

	return Msg(Fmt( "PingSystem.SetPingSound(%s, %s, %s)\n",
				PingTypeName(type), soundDefault, soundAlert ));
}

function DisableAutoPing( option = 1 )
{
	local add = function(n)
	{
		return m_AutoBlock.rawset( n, null );
	}

	m_AutoBlock.clear();
	add( PingResponse.pass );

	switch ( option )
	{
		case 1:
			add( PingResponse.special );
			add( PingResponse.dominated );
			add( PingResponse.weapon );
			add( PingResponse.death );
			break;

		case 2:
			add( PingResponse.special );
			add( PingResponse.dominated );
			add( PingResponse.death );
			break;

		case 3:
			add( PingResponse.weapon );
			break;
	}

	Msg("PingSystem.DisableAutoPing("+option+")\n");

	foreach ( v, _ in m_AutoBlock )
	{
		foreach ( name, val in CONST.PingResponse )
		{
			if ( val == v && name != "pass" )
			{
				Msg(Fmt( "\tPingResponse.%s\n", name ));
			}
		}
	}
}

function SetScaleMultiplier( scale )
{
	scale = scale.tofloat();

	if ( scale < 0.25 )
		scale = 0.25;
	else if ( scale > 2.0 )
		scale = 2.0;

	sprite_kv.scale = PING_SYSTEM_DEFAULT_SCALE_INTERNAL * scale;
	offscreen_sprite_kv.scale = PING_SYSTEM_OFFSCREEN_DEFAULT_SCALE_INTERNAL * scale;
	offscreen_interactable_sprite_kv.scale = PING_SYSTEM_OFFSCREEN_DEFAULT_SCALE_INTERNAL * scale;
	wheel_sprite_kv.scale = 2.0 * scale;
	wheel_item_sprite_kv.scale = scale;

	return Msg("PingSystem.SetScaleMultiplier("+scale+")\n");
}

function DisableSound( state )
{
	m_bPlaySoundOverride = !state;
	return Msg("PingSystem.DisableSound("+(!!state).tointeger()+")\n");
}

function DisableButton( state )
{
	local bWasThinking = m_bButtonEnabled || m_bOffscreenIndicators;
	local bIsThinking = !state || m_bOffscreenIndicators;

	m_bButtonEnabled = !state;

	if ( bWasThinking != bIsThinking )
		InitManager();

	return Msg("PingSystem.DisableButton("+(!!state).tointeger()+")\n");
}

function DisableOffscreenIndicators( state )
{
	local bWasThinking = m_bButtonEnabled || m_bOffscreenIndicators;
	local bIsThinking = m_bButtonEnabled || !state;

	m_bOffscreenIndicators = !state;

	if ( bWasThinking != bIsThinking )
		InitManager();

	foreach ( user in m_Users ) if ( user )
	{
		RemoveOffscreenIndicators_user( user );
	}

	return Msg("PingSystem.DisableOffscreenIndicators("+(!!state).tointeger()+")\n");
}

function SetOffscreenIndicatorStyle( style )
{
	style = style.tointeger();

	switch ( style )
	{
		case 0:
		case 1:
			m_nOffscreenIndicatorStyle = style;
			break;
		default:
			return;
	}

	return Msg("PingSystem.SetOffscreenIndicatorStyle("+style+")\n");
}

function SetOffscreenIndicatorScale( scale )
{
	scale = scale.tofloat();

	if ( scale < 0.25 )
		scale = 0.25;
	else if ( scale > 2.0 )
		scale = 2.0;

	offscreen_sprite_kv.scale = PING_SYSTEM_OFFSCREEN_DEFAULT_SCALE_INTERNAL * scale;
	offscreen_interactable_sprite_kv.scale = PING_SYSTEM_OFFSCREEN_DEFAULT_SCALE_INTERNAL * scale;

	return Msg("PingSystem.SetOffscreenIndicatorScale("+scale+")\n");
}

function DisableChatter( state )
{
	m_bChatterEnabled = !state;
	return Msg("PingSystem.DisableChatter("+(!!state).tointeger()+")\n");
}

function SetWheelItem( index, type )
{
	if ( type in m_PingLookup && index - 1 in m_PingWheelItems )
	{
		m_PingWheelItems[ index - 1 ] = type;
		return Msg(Fmt( "PingSystem.SetWheelItem(%d, %s)\n", index, PingTypeName(type) ));
	}
}

function DisableWheel( state )
{
	m_bPingWheelEnabled = !state;
	return Msg("PingSystem.DisableWheel("+(!!state).tointeger()+")\n");
}

function RemovePings( entindex )
{
	--entindex;

	if ( entindex in m_Users && m_Users[ entindex ] )
		return RemovePings_user( m_Users[ entindex ] );
}

//----------------------------------------------------------------------

local WriteConfig = function()
{
	local WriteColourIfNotEq = function( buf, type, defcol )
	{
		local col = m_PingLookup[type][m_colour];
		if ( col != defcol )
		{
			local r = col & 0xFF;
			local g = ( col >> 8 ) & 0xFF;
			local b = ( col >> 16 ) & 0xFF;
			return Fmt( "%sPingSystem.SetPingColour(%s, %d, %d, %d)\n", buf,
					PingTypeName(type), r, g, b );
		}

		return buf;
	}

	local WriteTimeIfNotEq = function( buf, type, deftime )
	{
		local time = m_PingLookup[type][m_lifetime];
		if ( time != deftime )
		{
			return Fmt( "%sPingSystem.SetPingDuration(%s, %g)\n", buf,
					PingTypeName(type), time );
		}

		return buf;
	}

	local buf = "";

	if ( m_AutoBlock.len() > 1 )
	{
		if ( (PingResponse.special in m_AutoBlock) &&
				(PingResponse.dominated in m_AutoBlock) &&
				(PingResponse.weapon in m_AutoBlock) &&
				(PingResponse.death in m_AutoBlock) )
		{
			buf = buf + "PingSystem.DisableAutoPing(1)\n";
		}
		else if ( (PingResponse.special in m_AutoBlock) &&
				(PingResponse.dominated in m_AutoBlock) &&
				(PingResponse.death in m_AutoBlock) )
		{
			buf = buf + "PingSystem.DisableAutoPing(2)\n";
		}
		else if ( (PingResponse.weapon in m_AutoBlock) )
		{
			buf = buf + "PingSystem.DisableAutoPing(3)\n";
		}
	}

	if ( !m_bPlaySoundOverride )
		buf = buf + "PingSystem.DisableSound(1)\n";

	if ( !m_bButtonEnabled )
		buf = buf + "PingSystem.DisableButton(1)\n";

	if ( !m_bChatterEnabled )
		buf = buf + "PingSystem.DisableChatter(1)\n";

	if ( !m_bPingWheelEnabled )
		buf = buf + "PingSystem.DisableWheel(1)\n";

	if ( !m_bOffscreenIndicators )
		buf = buf + "PingSystem.DisableOffscreenIndicators(1)\n";

	if ( m_nOffscreenIndicatorStyle )
		buf = buf + "PingSystem.SetOffscreenIndicatorStyle(1)\n";

	if ( m_nMaxPingCount != PING_SYSTEM_DEFAULT_MAX_PING_COUNT-1 )
		buf = Fmt( "%sPingSystem.SetMaxPingCount(%d)\n", buf, m_nMaxPingCount+1 );

	if ( sprite_kv.scale != PING_SYSTEM_DEFAULT_SCALE_INTERNAL )
	{
		buf = Fmt( "%sPingSystem.SetScaleMultiplier(%.6g)\n", buf,
				sprite_kv.scale / PING_SYSTEM_DEFAULT_SCALE_INTERNAL );
	}

	if ( offscreen_sprite_kv.scale !=
			( PING_SYSTEM_OFFSCREEN_DEFAULT_SCALE_INTERNAL *
			  ( sprite_kv.scale / PING_SYSTEM_DEFAULT_SCALE_INTERNAL ) ) )
	{
		buf = Fmt( "%sPingSystem.SetOffscreenIndicatorScale(%.6g)\n", buf,
				offscreen_sprite_kv.scale / PING_SYSTEM_OFFSCREEN_DEFAULT_SCALE_INTERNAL );
	}

	if ( m_PingWheelItems[0] != PingType.RESCUE )
		buf = Fmt( "%sPingSystem.SetWheelItem(%d, %s)\n", buf, 1, PingTypeName(m_PingWheelItems[0]) );

	if ( m_PingWheelItems[1] != PingType.COUNTDOWN )
		buf = Fmt( "%sPingSystem.SetWheelItem(%d, %s)\n", buf, 2, PingTypeName(m_PingWheelItems[1]) );

	if ( m_PingWheelItems[2] != PingType.QUESTION )
		buf = Fmt( "%sPingSystem.SetWheelItem(%d, %s)\n", buf, 3, PingTypeName(m_PingWheelItems[2]) );

	if ( m_PingWheelItems[3] != PingType.LOOKOUT )
		buf = Fmt( "%sPingSystem.SetWheelItem(%d, %s)\n", buf, 4, PingTypeName(m_PingWheelItems[3]) );

	buf += "\n";

	local timesareequal = true;
	local customsound = 0;
	local prevtime = m_PingLookup[0][m_lifetime];
	local soundDefault = PingSound.DEFAULT;
	local soundAlert = PingSound.ALERT;

	foreach ( type, pingInfo in m_PingLookup )
	{
		if ( pingInfo[m_lifetime] != prevtime )
		{
			timesareequal = false;
		}

		// Only need to detect 2 changes
		if ( customsound < 2 &&
				( pingInfo[m_soundDefault] != soundDefault ||
				  pingInfo[m_soundAlert] != soundAlert ) )
		{
			++customsound;
			soundDefault = pingInfo[m_soundDefault];
			soundAlert = pingInfo[m_soundAlert];
		}
	}

	// time and colour defaults aren't saved, go through them manually
	if ( !timesareequal )
	{
		foreach ( type, pingInfo in m_PingLookup )
		{
			switch ( type )
			{
				case PingType.TEAMMATE: case PingType.INFECTED: case PingType.UNCOMMON:
				case PingType.WARNING: case PingType.WARNING_MILD: case PingType.WARNING_ONFIRE:
				case PingType.ONFIRE: case PingType.INCAP: case PingType.FUELBARREL:
				case PingType.AFFIRMATIVE: case PingType.NEGATIVE: case PingType.WAIT:
				case PingType.RESCUE: case PingType.HURRY: case PingType.LOOKOUT:
					continue;
			}

			buf = WriteColourIfNotEq( buf, type, PingColour.BASE );
			buf = WriteTimeIfNotEq( buf, type, PING_SYSTEM_LIFETIME_DEFAULT );
		}

		buf = WriteColourIfNotEq( buf, PingType.TEAMMATE, PingColour.TEAMMATE );
		buf = WriteTimeIfNotEq( buf, PingType.TEAMMATE, 4.0 );

		buf = WriteColourIfNotEq( buf, PingType.INCAP, PingColour.INCAP );
		buf = WriteTimeIfNotEq( buf, PingType.INCAP, 4.0 );

		buf = WriteColourIfNotEq( buf, PingType.INFECTED, PingColour.INFECTED );
		buf = WriteTimeIfNotEq( buf, PingType.INFECTED, 4.0 );

		buf = WriteColourIfNotEq( buf, PingType.UNCOMMON, PingColour.WARNING_MILD );
		buf = WriteTimeIfNotEq( buf, PingType.UNCOMMON, 2.0 );

		buf = WriteColourIfNotEq( buf, PingType.WARNING, PingColour.WARNING );
		buf = WriteTimeIfNotEq( buf, PingType.WARNING, 4.0 );

		buf = WriteColourIfNotEq( buf, PingType.WARNING_ONFIRE, PingColour.WARNING );
		buf = WriteTimeIfNotEq( buf, PingType.WARNING_ONFIRE, 4.0 );

		buf = WriteColourIfNotEq( buf, PingType.WARNING_MILD, PingColour.WARNING_MILD );
		buf = WriteColourIfNotEq( buf, PingType.ONFIRE, PingColour.WARNING_MILD );
		buf = WriteColourIfNotEq( buf, PingType.HURRY, PingColour.WARNING_MILD );
		buf = WriteColourIfNotEq( buf, PingType.FUELBARREL, PingColour.WARNING_MILD );

		buf = WriteTimeIfNotEq( buf, PingType.AFFIRMATIVE, PING_SYSTEM_LIFETIME_CHATTER );
		buf = WriteTimeIfNotEq( buf, PingType.NEGATIVE, PING_SYSTEM_LIFETIME_CHATTER );
		buf = WriteTimeIfNotEq( buf, PingType.WAIT, PING_SYSTEM_LIFETIME_CHATTER );
		buf = WriteTimeIfNotEq( buf, PingType.RESCUE, PING_SYSTEM_LIFETIME_CHATTER );
		buf = WriteTimeIfNotEq( buf, PingType.HURRY, PING_SYSTEM_LIFETIME_CHATTER );
		buf = WriteTimeIfNotEq( buf, PingType.LOOKOUT, PING_SYSTEM_LIFETIME_CHATTER );
	}
	else
	{
		buf = Fmt( "%sPingSystem.SetPingDuration(PingType.ALL, %.2g)\n", buf, prevtime );
	}

	if ( customsound == 1 )
	{
		soundDefault = ( soundDefault != PingSound.DEFAULT ) ? Fmt( "\"%s\"", soundDefault ) : "null";
		soundAlert = ( soundAlert != PingSound.ALERT ) ? Fmt( "\"%s\"", soundAlert ) : "null";

		buf = Fmt( "%sPingSystem.SetPingSound(PingType.ALL, %s, %s)\n", buf,
				soundDefault, soundAlert );
	}
	else if ( customsound > 1 )
	{
		foreach ( type, pingInfo in m_PingLookup )
		{
			if ( type in m_PingIsChatter )
				continue;

			soundDefault = pingInfo[m_soundDefault];
			soundAlert = pingInfo[m_soundAlert];

			if ( soundDefault != PingSound.DEFAULT || soundAlert != PingSound.ALERT )
			{
				soundDefault = ( soundDefault != PingSound.DEFAULT ) ? Fmt( "\"%s\"", soundDefault ) : "null";
				soundAlert = ( soundAlert != PingSound.ALERT ) ? Fmt( "\"%s\"", soundAlert ) : "null";

				buf = Fmt( "%sPingSystem.SetPingSound(%s, %s, %s)\n", buf,
						PingTypeName(type), soundDefault, soundAlert );
			}
		}
	}

	return buf;
}

function SaveConfig()
{
	local buf = WriteConfig();
	local szScript = FileToString( "ping_system_settings.txt" );

	if ( !szScript || szScript != buf )
	{
		StringToFile( "ping_system_settings.txt", buf );
		return true;
	}

	return false;
}

function LoadConfig( initial = false )
{
	local buf = "";

	if ( !initial )
		buf = WriteConfig();

	local szScript = FileToString( "ping_system_settings.txt" );
	if ( szScript && szScript != buf )
	{
		try
		{
			compilestring( szScript )();
			return 1;
		}
		catch ( err )
		{
			error(Fmt( "ping_system_settings.txt ERROR: %s\n", err ));
		}
	}
	else if ( szScript == buf )
	{
		return 2;
	}

	return 0;
}

LoadConfig(true);

//----------------------------------------------------------------------

if (PING_DEBUG)
{
	IncludeScript("vs_math");

	local print = print, format = format;

	::printf <- function(...)
	{
		vargv.insert( 0, null );
		return print( format.acall(vargv) );
	}

	function DrawEntAxis( pEnt, tm )
	{
		if ( !pEnt )
			return;

		local v = pEnt.GetCenter();

		local right = Vector(), up = Vector(), forward = pEnt.GetForwardVector();
		VS.VectorVectors( forward, right, up );

		DebugDrawLine( v, v + forward * 16.0, 255, 0, 0, true, tm );
		DebugDrawLine( v, v + right * 16.0, 0, 255, 0, true, tm );
		DebugDrawLine( v, v + up * 16.0, 0, 0, 255, true, tm );
	}

	function __Reload()
	{
		print( "PingSystem::Reload() ----------\n" );
		DebugPrint();

		foreach ( event, listener in ::GameEventCallbacks )
		{
			local i = listener.len();
			while ( i-- )
			{
				local scope = listener[i];
				if ( scope == this )
				{
					listener.remove(i);
					printl( "Removed game event listener PingSystem::" + event );
					break;
				}
			}
		}

		if ( m_hManager && m_hManager.IsValid() )
		{
			m_hManager.Kill();
		}

		foreach ( user in m_Users ) if ( user )
		{
			RemovePings_user( user );
			RemoveOffscreenIndicators_user( user );
			RemoveWheel_user( user );

			if ( user[m_hChatterPing] && user[m_hChatterPing].IsValid() )
				user[m_hChatterPing].Kill();
		}

		if ( "PingSystem" in getroottable() )
		{
			print( "Free " + ::PingSystem + " {"+ this + "}\n" );
			delete ::PingSystem;
		}

		DoIncludeScript( "ping_system_load", getroottable() );

		return print( "Reloaded PingSystem " + ::PingSystem + "\n" );
	}
}

