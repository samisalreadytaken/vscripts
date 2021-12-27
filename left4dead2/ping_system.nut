//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Contextual Pinging System
//
//
// in dire need of refactoring
//
//
//
//
//
//
//


const CONTENTS_EMPTY				= 0x0;;
const CONTENTS_SOLID				= 0x1;;
const CONTENTS_WINDOW				= 0x2;;
const CONTENTS_AUX					= 0x4;;
const CONTENTS_GRATE				= 0x8;;
const CONTENTS_SLIME				= 0x10;;
const CONTENTS_WATER				= 0x20;;
const CONTENTS_BLOCKLOS				= 0x40;;
const CONTENTS_OPAQUE				= 0x80;;
const LAST_VISIBLE_CONTENTS			= 0x80;;
const ALL_VISIBLE_CONTENTS			= 0xFF;;
const CONTENTS_TESTFOGVOLUME		= 0x100;;
const CONTENTS_TEAM1				= 0x800;;
const CONTENTS_TEAM2				= 0x1000;;
const CONTENTS_IGNORE_NODRAW_OPAQUE	= 0x2000;;
const CONTENTS_MOVEABLE				= 0x4000;;
const CONTENTS_AREAPORTAL			= 0x8000;;
const CONTENTS_PLAYERCLIP			= 0x10000;;
const CONTENTS_MONSTERCLIP			= 0x20000;;
const CONTENTS_ORIGIN				= 0x1000000;;
const CONTENTS_MONSTER				= 0x2000000;;
const CONTENTS_DEBRIS				= 0x4000000;;
const CONTENTS_DETAIL				= 0x8000000;;
const CONTENTS_TRANSLUCENT			= 0x10000000;;
const CONTENTS_LADDER				= 0x20000000;;
const CONTENTS_HITBOX				= 0x40000000;;

const MASK_ALL						= 0xFFFFFFFF;;
//(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_MONSTER|CONTENTS_GRATE)
const MASK_SOLID					= 0x200400B;;
const MASK_PLAYERSOLID				= 0x201400B;;
const MASK_NPCSOLID					= 0x202400B;;
const MASK_WATER					= 0x4030;;
const MASK_OPAQUE					= 0x4081;;
const MASK_OPAQUE_AND_NPCS			= 0x2004081;;
const MASK_BLOCKLOS					= 0x4041;;
const MASK_BLOCKLOS_AND_NPCS		= 0x2004041;;
const MASK_VISIBLE					= 0x6081;;
const MASK_VISIBLE_AND_NPCS			= 0x2006081;;
//(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_MONSTER|CONTENTS_WINDOW|CONTENTS_DEBRIS|CONTENTS_HITBOX)
const MASK_SHOT						= 0x46004003;;
//(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_MONSTER|CONTENTS_WINDOW|CONTENTS_DEBRIS|CONTENTS_GRATE)
const MASK_SHOT_HULL				= 0x600400B;;
const MASK_SHOT_PORTAL				= 0x2004003;;
const MASK_SOLID_BRUSHONLY			= 0x400B;;
const MASK_PLAYERSOLID_BRUSHONLY	= 0x1400B;;
const MASK_NPCSOLID_BRUSHONLY		= 0x2400B;;
const MASK_NPCWORLDSTATIC			= 0x2000B;;
const MASK_SPLITAREAPORTAL			= 0x30;;

const IN_ATTACK		= 0x1;;
const IN_JUMP		= 0x2;;
const IN_DUCK		= 0x4;;
const IN_FORWARD	= 0x8;;
const IN_BACK		= 0x10;;
const IN_USE		= 0x20;;
const IN_CANCEL		= 0x40;;
const IN_LEFT		= 0x80;;
const IN_RIGHT		= 0x100;;
const IN_MOVELEFT	= 0x200;;
const IN_MOVERIGHT	= 0x400;;
const IN_ATTACK2	= 0x800;;
const IN_RUN		= 0x1000;;
const IN_RELOAD		= 0x2000;;
const IN_ALT1		= 0x4000;;
const IN_ALT2		= 0x8000;;
const IN_SCORE		= 0x10000;;
const IN_SPEED		= 0x20000;;
const IN_WALK		= 0x40000;;
const IN_ZOOM		= 0x80000;;
const IN_WEAPON1	= 0x100000;;
const IN_WEAPON2	= 0x200000;;
const IN_BULLRUSH	= 0x400000;;
const IN_GRENADE1	= 0x800000;;
const IN_GRENADE2	= 0x1000000;;
const IN_ATTACK3	= 0x2000000;;

const EF_NODRAW		= 32;;
const FL_FAKECLIENT	= 256;;

const FLT_EPSILON		= 1.192092896e-7;;
const FLT_MAX			= 3.402823466e+38;;
const FLT_MIN			= 1.175494351e-38;;

const INT_MAX			= 0x7FFFFFFF;;
const INT_MIN			= 0x80000000;;

const DEG2RAD			= 0.017453293;;
const RAD2DEG			= 57.295779513;;
const PI				= 3.141592654;;
const RAND_MAX			= 0x7FFF;;
const MAX_COORD_FLOAT	= 16384.0;;
const MAX_TRACE_LENGTH	= 56755.840862417;;

local CONST = getconsttable();
local Assert = assert;

local SpawnEntityFromTable = SpawnEntityFromTable;
local TraceLine = TraceLine;
local rr_GetResponseTargets = rr_GetResponseTargets;
local AddThinkToEnt = AddThinkToEnt;
local Time = Time;
local EmitSoundOnClient = EmitSoundOnClient;

local FireScriptEvent = FireScriptEvent;
local ScriptEventCallbacks = ScriptEventCallbacks; // static when using mapspawn_ping


local FindEntityByClassWithin = Entities.FindByClassnameWithin.bindenv( Entities );
local FindEntityByModel = Entities.FindByModel.bindenv( Entities );
// local GetNetPropIntArray = NetProps.GetPropIntArray.bindenv( NetProps );
local GetNetPropInt = NetProps.GetPropInt.bindenv( NetProps );
local SetNetPropInt = NetProps.SetPropInt.bindenv( NetProps );
local SetNetPropEntity = NetProps.SetPropEntity.bindenv( NetProps );
local GetNetPropEntity = NetProps.GetPropEntity.bindenv( NetProps );
// local GetNetPropString = NetProps.GetPropString.bindenv( NetProps );


const COS_5DEG = 0.995396;; // 5.5
const COS_10DEG = 0.984808;;
const COS_25DEG = 0.906308;;
const COS_90DEG = 0.0;;


const PING_DEBUG = 1;
const PING_DEBUG_DRAW = 0;
const PING_DEBUG_VERBOSE = 1;






enum PingType
{
	BASE,
	TEAMMATE,
	INFECTED,
	// UNCOMMON,
	INCAP,
	ONFIRE,

	WARNING,
	// WARNING_URGENT,
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
	RESCUE,
	SAFEROOM,
	FUELBARREL,

	// chatter
	AFFIRMATIVE,
	NEGATIVE,
	WAIT,
	NOTICE,
	HURRY,
	LOOKOUT,

	MAX_COUNT
}

m_PingIsWarning <-
{
	[PingType.WARNING]			= null,
	[PingType.WARNING_ONFIRE]	= null,
	[PingType.INCAP]			= null,
}

m_PingIsItem <-
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
	[PingType.FUELBARREL]				= null,
}

//m_PingIsChatter <-
//{
//	[PingType.RESCUE]		= null,
//	[PingType.AFFIRMATIVE]	= null,
//	[PingType.NEGATIVE]		= null,
//	[PingType.WAIT]			= null,
//	[PingType.NOTICE]		= null,
//	[PingType.HURRY]		= null,
//	[PingType.LOOKOUT]		= null,
//}

local PingMaterial = array( PingType.MAX_COUNT );
	PingMaterial[PingType.BASE]			= "ping_system/ping_base.vmt",
	PingMaterial[PingType.TEAMMATE]		= "ping_system/ping_base.vmt",
	PingMaterial[PingType.INFECTED]		= "ping_system/ping_base.vmt",
	// PingMaterial[PingType.UNCOMMON]		= "ping_system/ping_base.vmt",
	PingMaterial[PingType.INCAP]		= "ping_system/ping_base.vmt",
	PingMaterial[PingType.ONFIRE]			= "ping_system/ping_base_fire.vmt",

	PingMaterial[PingType.WARNING]			= "ping_system/ping_warning.vmt",
	// PingMaterial[PingType.WARNING_URGENT]	= "ping_system/ping_warning.vmt",
	PingMaterial[PingType.WARNING_ONFIRE]	= "ping_system/ping_warning_fire.vmt",
	PingMaterial[PingType.WARNING_MILD]		= "ping_system/ping_warning.vmt",

	PingMaterial[PingType.MEDKIT]			= "ping_system/ping_first_aid_kit.vmt",
	PingMaterial[PingType.PILLS]			= "ping_system/ping_pills.vmt",
	PingMaterial[PingType.ADRENALINE]		= "ping_system/ping_adrenaline.vmt",
	PingMaterial[PingType.DEFIBRILLATOR]	= "ping_system/ping_defibrillator.vmt",
	PingMaterial[PingType.MEDCAB]			= "ping_system/ping_medcabinet.vmt",

	PingMaterial[PingType.UPGRADEPACK_EXP]		= "ping_system/ping_upgradepack_explosive.vmt",
	PingMaterial[PingType.UPGRADEPACK_INC]		= "ping_system/ping_upgradepack_incendiary.vmt",
	PingMaterial[PingType.UPGRADEPACK_LASER]	= "ping_system/ping_upgradepack_laser.vmt",

	PingMaterial[PingType.PIPEBOMB]		= "ping_system/ping_pipebomb.vmt",
	PingMaterial[PingType.MOLOTOV]		= "ping_system/ping_molotov.vmt",
	PingMaterial[PingType.VOMITJAR]		= "ping_system/ping_vomitjar.vmt",

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

	PingMaterial[PingType.DOOR]			= "ping_system/ping_door.vmt",
	PingMaterial[PingType.RESCUE]		= "ping_system/ping_rescue.vmt",
	PingMaterial[PingType.SAFEROOM]		= "ping_system/ping_saferoom.vmt",
	PingMaterial[PingType.FUELBARREL]	= PingMaterial[PingType.WARNING_MILD],

	PingMaterial[PingType.AFFIRMATIVE]	= "ping_system/ping_affirmative.vmt",
	PingMaterial[PingType.NEGATIVE]		= "ping_system/ping_negative.vmt",
	PingMaterial[PingType.WAIT]			= "ping_system/ping_wait.vmt",
	PingMaterial[PingType.NOTICE]		= "ping_system/ping_notice.vmt",
	PingMaterial[PingType.HURRY]		= "ping_system/ping_wait.vmt",
	PingMaterial[PingType.LOOKOUT]		= "ping_system/ping_lookout.vmt"


enum PingColour
{
	NULL			= 0,
	BASE			= "255 255 255 255",
	TEAMMATE		= "78 100 150 255",
	WARNING			= "255 0 0 255",
	INFECTED		= "255 100 100 255",
	INCAP			= "255 145 25 255",
	// HEALTH			= "210 233 197 255"
}

enum PingSound
{
	DEFAULT		= "Default.Right", // "common/right.wav"
	ALERT		= "Default.RearRight", // "common/rearright.wav"
}

const PING_LIFETIME = 8.0;;

const m_colour = 1;;
const m_lifetime = 2;;

// define colour when reusing pings
local InitPingType = function( material, colour = PingColour.BASE, lifetime = PING_LIFETIME )
{
	return [ material, colour, lifetime ];
}

if ( !("m_PingLookup" in this) )
{
	m_PingLookup <- array( PingType.MAX_COUNT );

	foreach ( i, v in PingMaterial )
		m_PingLookup[ i ] = InitPingType( v );
};;

local m_PingLookup = m_PingLookup;

	m_PingLookup[ PingType.TEAMMATE ][ m_colour ]			= PingColour.TEAMMATE;
	m_PingLookup[ PingType.TEAMMATE ][ m_lifetime ]			= 5.0;

	m_PingLookup[ PingType.INFECTED ][ m_colour ]			= PingColour.INFECTED;
	m_PingLookup[ PingType.INFECTED ][ m_lifetime ]			= 5.0;

	m_PingLookup[ PingType.WARNING ][ m_colour ]			= PingColour.WARNING;
	m_PingLookup[ PingType.WARNING ][ m_lifetime ]			= 5.0;

	m_PingLookup[ PingType.WARNING_MILD ][ m_colour ]		= PingColour.INCAP;

	m_PingLookup[ PingType.WARNING_ONFIRE ][ m_colour ]		= PingColour.INCAP;
	m_PingLookup[ PingType.ONFIRE ][ m_colour ]				= PingColour.INCAP;

	m_PingLookup[ PingType.INCAP ][ m_colour ]				= PingColour.INCAP;
	m_PingLookup[ PingType.HURRY ][ m_colour ]				= PingColour.INCAP;

	m_PingLookup[ PingType.FUELBARREL ][ m_colour ]			= PingColour.INCAP;


if ( !("m_Players" in this) )
{
	m_Players <- [];		// [CBasePlayer]
	g_ButtonState <- {}		// CBasePlayer : state
	g_Teams <- array(4);	// team : [CBasePlayer]
	g_Pings <- {}			// CBasePlayer : pingSprite

	g_lastWarningPos <- {}	// CBasePlayer : Vector
	g_lastChatterPing <- {}	// CBasePlayer : pingSprite
	g_lastWarningPing <- {}	// CBasePlayer : pingSprite

	// ping targets
	g_Targets <- {}			// CBaseEntity : pingSprite

	// m_Users <- {}		// CBasePlayer : CPingUser
};;

local m_Players = m_Players;
local g_ButtonState = g_ButtonState;
local g_Pings = g_Pings;
local g_Targets = g_Targets;
local g_lastChatterPing = g_lastChatterPing;
local g_lastWarningPing = g_lastWarningPing;
local g_lastWarningPos = g_lastWarningPos;

function Precache()
{
	foreach ( mat in PingMaterial )
		PrecacheModel( mat );

	foreach ( snd in CONST.PingSound )
		PrecacheSound( snd );
}


m_hManager <- null;

local InitMan = function()
{
	if ( m_hManager )
		return;

	local fn = InputThink.bindenv(this);
	local p = SpawnEntityFromTable( "info_target", [] );
	p.ValidateScriptScope();
	p.GetScriptScope().Think <- function() { return fn(); }
	AddThinkToEnt( p, "Think" );
	m_hManager = p.weakref();
}

function Init()
{
	InitMan();

	for ( local p; p = Entities.FindByClassname( p, "player" ); )
	{
		AddPlayer( p, GetNetPropInt( p, "m_iTeamNum" ) );
	}

	local b = rr_AddDecisionRule(
		RRule(
			"PingSystem",
			[ CriterionFunc( "PingSystem", rr_Ping.bindenv(this) ) ],
			[ ResponseSingle( ResponseKind.print, "", null, null, { scenename = "" } ) ],
			RGroupParams()
		)
	);

	if ( !b )
		error( "PingSystem: ERROR invalid RR!\n");

	Msg("PingSystem::Init()   [13]\n");
}

function OnGameEvent_round_start(ev)
{
	return InitMan();
}


function RemoveInvalidPlayers()
{
	for ( local i = m_Players.len(); i--; )
	{
		local p = m_Players[i];
		if ( p && p.IsValid() )
			continue;

		m_Players.remove(i);

		if ( p in g_ButtonState )
			delete g_ButtonState[p];

		if ( p in g_Pings )
			delete g_Pings[p];

		if ( p in g_lastWarningPos )
			delete g_lastWarningPos[p];

		if ( p in g_lastWarningPing )
			delete g_lastWarningPing[p];

		if ( p in g_lastChatterPing )
			delete g_lastChatterPing[p];

		foreach ( team in g_Teams )
		{
			if ( team )
			{
				local idx = team.find( p );
				if ( idx != null )
					team.remove(idx);
			}
		}
	}
}

function AddPlayer( hPlayer, plyTeam )
{
	RemoveInvalidPlayers();

	if ( !hPlayer || !hPlayer.IsValid() )
		return;

	// Validate team
	if ( !(plyTeam in g_Teams) )
		g_Teams.resize( plyTeam+1 );

	if ( !g_Teams[ plyTeam ] )
		g_Teams[ plyTeam ] = [];

	// Remove from team
	foreach ( team in g_Teams )
	{
		if ( team )
		{
			local idx = team.find( hPlayer );
			if ( idx != null )
				team.remove(idx);
		}
	}

	// Add to team
	g_Teams[ plyTeam ].append( hPlayer );

	// Reset members
	g_ButtonState[ hPlayer ] <- 0;
	g_lastWarningPos[ hPlayer ] <-
	g_lastWarningPing[ hPlayer ] <-
	g_lastChatterPing[ hPlayer ] <- null;

	if ( !(hPlayer in g_Pings) )
		g_Pings[ hPlayer ] <- [];
	else
		g_Pings[ hPlayer ].clear();

	if ( m_Players.find( hPlayer ) == null )
		m_Players.append( hPlayer );


	if (PING_DEBUG)
	{
		Msg("PingSystem::AddPlayer\n");
		local hPlayerResource = Entities.FindByClassname( null, "terror_player_manager" );

		foreach ( teamnum, team in g_Teams )
		{
			Msg("\t[" + teamnum + "]\n");

			if ( team )
			{
				foreach( player in team )
				{
					Msg("\t\t" + player + "\t(" +
						NetProps.GetPropIntArray( hPlayerResource, "m_iPing", player.GetEntityIndex() ) +
					")\n");
				}
			}
		}
	}
}

function __DebugPrint()
{
	Msg("PingSystem::__DebugPrint: ["+GetFrameCount()+"]\n");

	local Msg = Msg, Fmt = format;
	local hPlayerResource = Entities.FindByClassname( null, "terror_player_manager" );

	for ( local i = m_Players.len(); i--; )
	{
		local p = m_Players[i];

		local teamnum = -1;
		foreach ( num, team in g_Teams )
		{
			if ( team )
			{
				local idx = team.find( p );
				if ( idx != null )
				{
					teamnum = num;
					break;
				}
			}
		}

		Msg(Fmt( "\t[%i](%i) %i|%i\t%i %i %i %i %i (%i) [%i]\n",
			p.GetEntityIndex(),
			p.GetPlayerUserId(),
			teamnum,
			GetNetPropInt( p, "m_iTeamNum" ),
			( p in g_ButtonState ).tointeger(),
			( p in g_Pings ).tointeger(),
			( p in g_lastWarningPos ).tointeger(),
			( p in g_lastWarningPing ).tointeger(),
			( p in g_lastChatterPing ).tointeger(),
			NetProps.GetPropIntArray( hPlayerResource, "m_iPing", p.GetEntityIndex() ),
			(!!(GetNetPropInt( p, "m_fFlags" ) & FL_FAKECLIENT)).tointeger()
		));
	}
}

function OnGameEvent_player_team( ev )
{
	if ( ev.disconnect )
		return RemoveInvalidPlayers();

	local pl = GetPlayerFromUserID( ev.userid );
	if ( !pl )
		return;

	return AddPlayer( pl, ev.team );
}


function InputThink()
{
	if ( 0 in m_Players )
	{
		foreach ( ply in m_Players )
		{
			if ( !GetNetPropInt( ply, "m_lifeState" ) ) // pl.deadflag
			{
				local curPressed = ( ply.GetButtonMask() & IN_ALT2 );

				if ( curPressed != g_ButtonState[ ply ] )
				{
					g_ButtonState[ ply ] = curPressed;
					if ( curPressed )
					{
						OnCommandPing( ply );
					};
				};
			};
		}
		return 0.01;
	};
	// hibernate
	return 5.0;
}

local GetHeadOrigin = function( pEnt )
{
	// Use attachments because invalid attachment origin is local vec3_origin, invalid bone origin is vec3_invalid
	// It makes falling back simpler
	const PING_ATTACHMENT = "forward";;
	const PING_ATTACHMENT1 = "mouth";;

	// const PING_BONE_NAME = "ValveBiped.Bip01_Head1";;
	// const PING_BONE_NAME1 = "ValveBiped.Bip01_Head";;

	local bone = pEnt.LookupAttachment( PING_ATTACHMENT );
	if ( !bone )
		bone = pEnt.LookupAttachment( PING_ATTACHMENT1 );

	if (PING_DEBUG) Assert( bone > 0 );
	// if (PING_DEBUG) Assert( bone > -1 );

	return pEnt.GetAttachmentOrigin( bone );
}

enum PingResponse
{
	pass,
	weapon,
	special,
	dominated,
	chat,
	// remark
}

m_ValidConcepts <-
{
	// TLK_REMARK				= PingResponse.remark,
	PlayerSpotWeapon		= PingResponse.weapon,
	PlayerWarnSpecial		= PingResponse.special,
	PlayerAlsoWarnSpecial	= PingResponse.special,

	// ping dominator
	ScreamWhilePounced		= PingResponse.dominated,	//SurvivorWasPounced
	SurvivorJockeyed		= PingResponse.dominated,
	chargerpound			= PingResponse.dominated,
	PlayerTonguePullStart	= PingResponse.dominated,	//PlayerGrabbedByTongue

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

	// ammo				= "models/props/terror/ammo_stack.mdl",
	// ammo				= "models/props_unique/spawn_apartment/coffeeammo.mdl",

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
}

m_UncommonModels <-
[
	"models/infected/common_male_riot.mdl",
	"models/infected/common_male_ceda.mdl",
	"models/infected/common_male_clown.mdl",

	"models/infected/common_male_fallen_survivor.mdl",
	"models/infected/common_male_fallen_survivor_l4d1.mdl",

	"models/infected/common_male_roadcrew.mdl",
	"models/infected/common_male_roadcrew_l4d1.mdl",

	"models/infected/common_male_mud.mdl",
	"models/infected/common_male_mud_l4d1.mdl",

	"models/infected/common_male_parachutist.mdl",
	"models/infected/common_male_parachutist_l4d1.mdl",

	"models/infected/common_male_jimmy.mdl",
];

m_ModelForUncommon <-
{
	riot_control	= "models/infected/common_male_riot.mdl",
	ceda			= "models/infected/common_male_ceda.mdl",
	clown			= "models/infected/common_male_clown.mdl",
	fallen			= "models/infected/common_male_fallen_survivor_l4d1.mdl",
	undistractable	= "models/infected/common_male_roadcrew_l4d1.mdl",
	crawler			= "models/infected/common_male_mud_l4d1.mdl",
	jimmy			= "models/infected/common_male_jimmy.mdl",
	// "models/infected/common_male_parachutist_l4d1.mdl",
}

m_survivorCharacter <-
{
	NamVet		= 4,
	Biker		= 6,
	Manager		= 7,
	TeenGirl	= 9,

	Gambler		= 19,
	Mechanic	= 20,
	Coach		= 21,
	Producer	= 22,
}


local m_ValidConcepts = m_ValidConcepts;
local m_WeaponClassForName = m_WeaponClassForName;
local m_ZombieTypeForSI = m_ZombieTypeForSI;
local m_ModelForUncommon = m_ModelForUncommon;
local m_ModelForWeaponName = m_ModelForWeaponName;

local s_bPlaySound = true;
local s_AutoBlock =
{
	[PingResponse.pass] = null
}


function rr_Ping( Q )
{
	local concept = Q.concept;
	if ( !(concept in m_ValidConcepts) )
		return;


	if (PING_DEBUG)
	{
		if ( !( "who" in Q ) && !( "Who" in Q ) )
		{
			printf( "[???] %s   <------------------------\n", Q.concept );
			error("no response target!\n");
			__DumpScope( 2, Q );
		};
	};


	local who;

	if ( "who" in Q )
	{
		who = Q.who;
	}
	else if ( "Who" in Q )
	{
		// why
		who = Q.Who;
	};;


	if (PING_DEBUG)
	{
		printf("[%s] %s   <------------------------", who, Q.concept );
	};


	local targets = rr_GetResponseTargets();
	if ( who in targets )
	{
		who = targets[ who ];
	}
	else
	{
		if ( who in m_survivorCharacter )
		{
			local id = m_survivorCharacter[ who ];

			foreach ( p in m_Players )
			{
				if ( p.IsValid() && GetNetPropInt( p, "m_survivorCharacter" ) == id )
				{
					who = p;
					break;
				};
			}
		};

		if ( !("IsValid" in who) )
			return Msg( "\nPingSystem: Response target '" + who + "' not found\n" );
	};

	local bAuto = !("smartlooktype" in Q) || Q.smartlooktype != "manual";

	if (PING_DEBUG)
	{
		if ( bAuto )
			print(" (auto)");
		if ( GetNetPropInt( who, "m_fFlags" ) & FL_FAKECLIENT )
			print(" [bot]");
		print("\n");
	};

	local resp = m_ValidConcepts[ concept ];

	if ( bAuto && resp in s_AutoBlock )
	{
		if (PING_DEBUG)
			print("   auto-ping is disabled\n");
		return;
	};

	// Don't play sound when auto-pinged or using chatter
	s_bPlaySound = !bAuto;

	switch ( resp )
	{
		case PingResponse.pass:

			if (PING_DEBUG)
			{
				// Should always be blocked in s_AutoBlock
				Assert( !bAuto );
				Assert( resp in s_AutoBlock );
			};

			return OnCommandPing( who );

		case PingResponse.weapon:

			if ( !("weaponname" in Q) )
			{
				if (PING_DEBUG) error( "   PingResponse.weapon : NULL\n" );

				// no weaponname, trace if not auto
				//
				// it could be gascan, propanetank, upgradepack
				if ( bAuto )
					return;

				return PingTrace( who );
			};

			if (PING_DEBUG) printl( "   PingResponse.weapon : " + Q.weaponname );

			local weaponname = Q.weaponname.tolower();
			if ( !(weaponname in m_WeaponClassForName) )
			{
				if (PING_DEBUG) error("weapon class not found for '" + weaponname + "'\n");
				return;
			};

			local weaponclass = m_WeaponClassForName[ weaponname ];

			local flThresholdBase = COS_5DEG;
			if ( bAuto )
			{
				if ( GetNetPropInt( who, "m_fFlags" ) & FL_FAKECLIENT )
					flThresholdBase = COS_90DEG;
				else
					flThresholdBase = COS_25DEG;
			};
			local flThreshold = flThresholdBase;

			local eyePos = who.EyePosition();
			local eyeDir = who.EyeAngles().Forward();
			local pEnt, pTarget;

			while ( pEnt = FindEntityByClassWithin( pEnt, weaponclass, eyePos, 256.0 ) )
			{
				local delta = pEnt.GetCenter() - eyePos;
				delta.Norm();
				local dot = eyeDir.Dot( delta );
				if ( dot > flThreshold )
				{
					pTarget = pEnt;
					flThreshold = dot;
				};
			}

			if (PING_DEBUG) printl( "      target : " + pTarget );

			if ( pTarget )
			{
				// if auto and target is already pinged, extends its lifetime
				// TODO: this sucks
				//if (bAuto)
				//{
				//	local ping;
				//	if ( (pTarget in g_Targets) && (ping = g_Targets[pTarget]).IsValid() )
				//	{
				//	};
				//};

				return PingEntity( who, pTarget );
			};

			// TODO: This is not very good...

			// It could be a 'weapon_spawn', re-search -

			local weaponmodel;
			if ( weaponname in m_ModelForWeaponName )
				weaponmodel = m_ModelForWeaponName[ weaponname ];


			if (PING_DEBUG)
			{
				if ( !weaponmodel && weaponname != "ammo" )
					error("model not found for weaponname " + weaponname);
			};


			pEnt = null;
			flThreshold = flThresholdBase;
			while ( pEnt = FindEntityByClassWithin( pEnt, "weapon*", eyePos, 256.0 ) )
			{
				// Looking for weapon* class, check the model if it is the one we're searching for.
				// if there is no model data, found generic weapon entity's model will be looked up in PingEntity.
				// Checking weaponID is not viable with melee weapons and medkit.
				if ( weaponmodel && (pEnt.GetModelName() != weaponmodel) )
					continue;

				local delta = pEnt.GetCenter() - eyePos;
				delta.Norm();
				local dot = eyeDir.Dot( delta );
				if ( dot > flThreshold )
				{
					pTarget = pEnt;
					flThreshold = dot;
				};
			}


			if (PING_DEBUG)
				printf( "      target : %s | %s\n", ""+pTarget, (weaponmodel?split(weaponmodel,"/").top():"weapon*"));
			if (PING_DEBUG_DRAW) if (pTarget)
				DebugDrawBox( pTarget.GetOrigin(), Vector(-1,-1,-1), Vector(1,1,1), 255,255,255,255, PING_LIFETIME );


			if ( pTarget )
				return PingEntity( who, pTarget );

			if ( bAuto )
				return;

			if (PING_DEBUG_VERBOSE) print( "      trace fallback\n" );

			return PingTrace( who );

		case PingResponse.special:

			local specialtype = Q.specialtype;


			if (PING_DEBUG)
			{
				printl("   PingResponse.special : " + specialtype);

				if ( !( specialtype in m_ZombieTypeForSI ) && !( specialtype in m_ModelForUncommon ) )
					error("unrecognised specialtype '" + specialtype + "'\n");
			};


			if ( specialtype in m_ZombieTypeForSI )
			{
				specialtype = m_ZombieTypeForSI[ specialtype ];

				local szClassname = "player";

				// hack for witch
				if (specialtype == 7)
					szClassname = "witch";

				local flThreshold = COS_10DEG;
				if ( bAuto )
				{
					flThreshold = COS_25DEG;
				};

				local eyePos = who.EyePosition();
				local eyeDir = who.EyeAngles().Forward();
				local pEnt, pTarget;

				while ( pEnt = FindEntityByClassWithin( pEnt, szClassname, eyePos, 2048.0 ) )
				{
					if ( szClassname != "witch" && pEnt.GetZombieType() != specialtype )
						continue;

					local delta = pEnt.GetCenter() - eyePos;
					delta.Norm();
					local dot = eyeDir.Dot( delta );
					if ( dot > flThreshold )
					{
						pTarget = pEnt;
						flThreshold = dot;
					};
				}

				if (PING_DEBUG) printl( "      SI target : " + pTarget );

				if ( pTarget )
					return PingEntity( who, pTarget );
			}
			else if ( specialtype in m_ModelForUncommon )
			{
				specialtype = m_ModelForUncommon[ specialtype ];

				local eyePos = who.EyePosition();
				local eyeDir = who.EyeAngles().Forward();
				local flThreshold = COS_25DEG;
				local pEnt, pTarget;

				while ( pEnt = FindEntityByModel( pEnt, specialtype ) )
				{
					local org = pEnt.GetOrigin();
					local delta = org - eyePos;
					local dist = delta.Norm();
					local dot = eyeDir.Dot( delta );

					if ( dist <= 1024.0 && dot > flThreshold )
					{
						pTarget = pEnt;
						flThreshold = dot;
					};
				}

				if ( pTarget )
				{
					if (PING_DEBUG) printl( "      uncommon target : " + pTarget );

					// local pos
					local vecPingPos = GetHeadOrigin( pTarget ) - pTarget.GetOrigin();
					vecPingPos.x = vecPingPos.y = 0.0;
					vecPingPos.z += 32.0;

					return SpriteCreate( who, PingType.INCAP, vecPingPos, pTarget, pTarget );
				};
			};;

			// no target found, trace if not auto
			if ( bAuto )
				return;

			if (PING_DEBUG_VERBOSE) print( "      trace fallback\n" );

			return PingTrace( who );

		// player is attacked by SI
		case PingResponse.dominated:

			if ( !bAuto )
				return;

			if (PING_DEBUG) print("   auto ping\n");

			local hMyDominator = who.GetSpecialInfectedDominatingMe();
			if ( hMyDominator )
			{
				local vecPingPos = hMyDominator.EyePosition();
				vecPingPos.z = GetHeadOrigin( hMyDominator ).z + 32.0;

				return SpriteCreate( who, PingType.WARNING, vecPingPos, hMyDominator );
			};
			return;

		//case PingResponse.remark:
        //
		//	if ( (Q.subject != "remark_caralarm") )
		//		return;
        //
		//	break;

		case PingResponse.chat:
			return PingChatter( who, concept );
	}
}

local s_nErrCount = 0;

local PreFadeOut = function( hSpr, hOwner, hTarget = null )
{
	if ( hOwner in g_Pings )
	{
		local pings = g_Pings[ hOwner ];
		if (PING_DEBUG) Assert(pings);
		local i = pings.find(hSpr);
		if ( i != null )
			pings.remove(i);

		if (PING_DEBUG) if ( i == null ) error("ping not found in list");

	}
	// TODO: Find and fix the cause
	else
	{
		if ( hOwner && !hOwner.IsValid() )
			Msg("PingSystem: invalid ping owner\n");
		else
			Msg("PingSystem: missing ping owner ["+hOwner.GetPlayerUserId()+"]"+hOwner+"\n");

		if ( ++s_nErrCount >= 6 )
		{
			__DebugPrint();
			s_nErrCount = 0;
			RemoveInvalidPlayers();
		};
	};

	if ( hTarget in g_Targets )
	{
		delete g_Targets[ hTarget ];
		if (PING_DEBUG_VERBOSE) printl("freed ping target " + hTarget);
	};
}

local FadeOut = function()
{
	if ( m_nRenderAlpha > 64 )
	{
		self.__KeyValueFromInt( "renderamt", m_nRenderAlpha -= 64 );
		return 0.0;
	};

	self.Kill();
	return -1;
}


// Attached to enemies
local SpriteThinkEnemy = function()
{
	if ( Time() < m_flDieTime )
	{
		if ( GetNetPropInt( m_hTarget, "m_lifeState" ) > 0 )
		{
			if (PING_DEBUG_VERBOSE)
				printf( "ping target is dead %s : %d\n", ""+m_hTarget, GetNetPropInt( m_hTarget, "m_lifeState" ));

			return m_flDieTime = 0.0;
		};
		return 1.0;
	};

	PreFadeOut( self, m_hOwner, m_hTarget );

	if ( self == g_lastWarningPing[ m_hOwner ] )
		g_lastWarningPing[ m_hOwner ] = null;

	return (SpriteThink = FadeOut)();
}

// Attached to items
local SpriteThinkItem = function()
{
	if ( Time() < m_flDieTime )
	{
		if ( m_hTarget &&
			(
				GetNetPropEntity( m_hTarget, "m_hOwnerEntity" ) ||
				( GetNetPropInt( m_hTarget, "m_fEffects" ) & EF_NODRAW )
			)
		)
		{
			if (PING_DEBUG_VERBOSE)
				printf( "ping item is taken %s m_hOwnerEntity%s nodraw[%d]\n", ""+m_hTarget, ""+GetNetPropEntity( m_hTarget, "m_hOwnerEntity" ), ( GetNetPropInt( m_hTarget, "m_fEffects" ) & EF_NODRAW ) );

			return m_flDieTime = 0.0;
		};
		return 1.0;
	};

	PreFadeOut( self, m_hOwner, m_hTarget );

	return (SpriteThink = FadeOut)();
}

// Base
local SpriteThink = function()
{
	if ( m_bInitRem )
	{
		m_bInitRem = false;
		return m_flLifeTime;
	};

	PreFadeOut( self, m_hOwner );

	// if I'm a chatter ping
	if ( self == g_lastChatterPing[ m_hOwner ] )
		g_lastChatterPing[ m_hOwner ] = null;

	return (SpriteThink = FadeOut)();
}

local sprite_kv =
{
	scale = 5.25,
	framerate = 0.0,
	model = PingMaterial[ PingType.BASE ]
}

function SpriteCreate( owner, type, origin, target = null, hParent = null )
{
	local ping = m_PingLookup[ type ];
	local colour = ping[m_colour];
	local lifetime = ping[m_lifetime];

	local bIsWarning = type in m_PingIsWarning;

	if ( bIsWarning )
	{
		// if this warning ping is very close to another warning ping, extends its life and cancel current
		foreach ( pl, lastPing in g_lastWarningPing )
		{
			// local lastPing = g_lastWarningPing[ owner ];
			if ( lastPing && lastPing.IsValid() && ( lastPing.GetLocalOrigin() - origin ).LengthSqr() < 2048.0 ) // 45 * 45
			{
				if (PING_DEBUG_VERBOSE)
				{
					printf("\n\t%s pinged too close to %s's %s (%.2f)\n", ""+owner, ""+pl, ""+lastPing, ( lastPing.GetLocalOrigin() - origin ).Length() );
					if (PING_DEBUG_DRAW)
						DebugDrawLine( origin, lastPing.GetOrigin(), 255,255,255,true,PING_LIFETIME );
				};

				lastPing.GetScriptScope().m_flDieTime = Time() + lifetime;
				AddThinkToEnt( lastPing, "SpriteThink" );

				return lastPing.SetLocalOrigin( origin );
			};
		}
	};

	local pEnt;
	local playerPings = g_Pings[ owner ];

	// no more than 4 pings per player
	if ( 3 in playerPings )
	{
		// kill the oldest
		// local p = playerPings.remove(0);
		// p.GetScriptScope().SpriteThink = FadeOut;
		// reset next think time
		// AddThinkToEnt( p, "SpriteThink" );

		// Reuse
		// NOTE: Reusing will interpolate origin, which might be distracting
		// NOTE: Need to check if this ping is in other lists!
		if ( ( pEnt = playerPings.remove(0) ).IsValid() )
		{
			if (PING_DEBUG_VERBOSE) print("reusing ping "+pEnt);

			pEnt.SetModel( ping[0] );

			local sc = pEnt.GetScriptScope();
			if ( ("m_hTarget" in sc) && sc.m_hTarget in g_Targets )
			{
				if (PING_DEBUG_VERBOSE) print(" found targeting " + sc.m_hTarget);
				delete g_Targets[ sc.m_hTarget ];
			};

			if (PING_DEBUG_VERBOSE) print("\n");
		}
		else
		{
			if (PING_DEBUG) error("NULL ent in player pings " + pEnt);

			sprite_kv.model = ping[0];
			pEnt = SpawnEntityFromTable( "env_sprite", sprite_kv );
		};
	}
	else
	{
		sprite_kv.model = ping[0];
		pEnt = SpawnEntityFromTable( "env_sprite", sprite_kv );

		if (PING_DEBUG_VERBOSE) printl("new ping " + pEnt);
	};

	playerPings.append( pEnt );

	pEnt.SetLocalOrigin( origin );

	local playerTeam = GetNetPropInt( owner, "m_iTeamNum" );
	SetNetPropInt( pEnt, "m_iTeamNum", playerTeam );
	pEnt.__KeyValueFromInt( "effects", 0 );
	pEnt.__KeyValueFromInt( "rendermode", 2 );
	if (!colour) Assert( colour );
	pEnt.__KeyValueFromString( "rendercolor", colour );

	//if ( frame )
	//	SetNetPropFloat( pEnt, "m_flFrame", frame );

	// nullify parent if reusing
	SetNetPropEntity( pEnt, "m_hMoveParent", hParent );

	AddThinkToEnt( pEnt, "SpriteThink" );
	pEnt.ValidateScriptScope();
	local sc = pEnt.GetScriptScope();
	sc.m_nRenderAlpha	<- 0xff;
	sc.m_hOwner			<- owner;

	if ( bIsWarning )
	{
		sc.m_flDieTime		<- Time() + lifetime;
		sc.m_hTarget		<- target;
		sc.SpriteThink		<- SpriteThinkEnemy;

		if ( target )
		{
			if (PING_DEBUG_VERBOSE) printl( "target " + target + " is pinged by " + owner );

			// Remove previous ping on this target
			//
			if ( target in g_Targets )
			{
				if (PING_DEBUG_VERBOSE) printl( "re-pinged target " + target );

				// This target is already pinged
				// TODO: Transfer ownership?
				local prevPing = g_Targets[ target ];
				if ( prevPing.IsValid() )
				{
					local prevPingSc = prevPing.GetScriptScope();
					local prevOwner = prevPingSc.m_hOwner;
					local pings = g_Pings[ prevOwner ];
					local i = pings.find(prevPing);
					if ( i != null )
					{
						pings.remove(i);
						prevPingSc.SpriteThink = FadeOut;
						AddThinkToEnt( prevPing, "SpriteThink" );
					};
					// else: when player pings elsewhere before their ping with a target is removed

					if ( prevPing == g_lastWarningPing[ prevOwner ] )
						g_lastWarningPing[ prevOwner ] = null;

					if (PING_DEBUG_VERBOSE) if ( i != null ) printl( "   removing ping" + prevPing + " from owner" + prevOwner );
				};
			};

			g_Targets[ target ] <- g_lastWarningPing[ owner ] <- pEnt;
		};
	}
	// items
	else if ( type in m_PingIsItem )
	{
		sc.m_flDieTime		<- Time() + lifetime;
		sc.m_hTarget		<- target;
		sc.SpriteThink		<- SpriteThinkItem;

		if (PING_DEBUG) Assert( target );

		// TODO:
		if ( target )
		{
			if (PING_DEBUG_VERBOSE) printl( "target " + target + " is pinged by " + owner );

			// Remove previous ping on this target
			//
			if ( target in g_Targets )
			{
				if (PING_DEBUG_VERBOSE) printl( "re-pinged target " + target );

				// This target is already pinged
				// TODO: Transfer ownership?
				local prevPing = g_Targets[ target ];
				if ( prevPing.IsValid() )
				{
					local prevPingSc = prevPing.GetScriptScope();
					local prevOwner = prevPingSc.m_hOwner;
					local pings = g_Pings[ prevOwner ];
					local i = pings.find(prevPing);
					if ( i != null )
					{
						pings.remove(i);
						prevPingSc.SpriteThink = FadeOut;
						AddThinkToEnt( prevPing, "SpriteThink" );
					};
					// else: when player pings elsewhere before their ping with a target is removed

					if ( prevPing == g_lastWarningPing[ prevOwner ] )
						g_lastWarningPing[ prevOwner ] = null;

					if (PING_DEBUG_VERBOSE) if ( i != null ) printl( "   removing ping" + prevPing + " from owner" + prevOwner );
				};
			};

			g_Targets[ target ] <- pEnt;
		};
	}
	// base, static
	else
	{
		sc.m_bInitRem		<- true;
		sc.m_flLifeTime		<- lifetime;
		sc.SpriteThink		<- SpriteThink;
	};;

	// DispatchParticleEffect(  );

	if ( s_bPlaySound )
	{
		foreach ( p in g_Teams[playerTeam] )
			EmitSoundOnClient( PingSound.DEFAULT, p );
	}
	else
	{
		s_bPlaySound = true;
	};

	if ( PING_DEBUG )
	{
		::__player <- owner.weakref();
		::__spr <- pEnt.weakref();

		if (PING_DEBUG_DRAW)
		{
			if (hParent) origin += hParent.GetOrigin();
			DebugDrawLine( owner.EyePosition(), origin, 0,255,0,true,1.0 );
			// DebugDrawBox( origin, Vector(4,4,4)*-1, Vector(4,4,4), 255,0,255,16, lifetime );
		};
	};

	if ( "player_ping" in ScriptEventCallbacks )
	{
		FireScriptEvent( "player_ping", { player = owner, origin = origin * 1, target = target } );
		// FireGameEvent( "player_ping", { userid = owner.GetPlayerUserId(), target = target.GetEntityIndex(), x = origin.x, y = origin.y, z = origin.z } );
	};

	// return sprite to register last chatter ping in PingChatter
	return pEnt;
}

m_PingTypeForConcept <-
{
	PlayerYes			= PingType.AFFIRMATIVE,
	PlayerNo			= PingType.NEGATIVE,
	PlayerWaitHere		= PingType.WAIT,
	PlayerWarnCareful	= PingType.LOOKOUT,
	PlayerMoveOn		= PingType.RESCUE,
	PlayerHurryUp		= PingType.HURRY,
	// NOTICE,
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

m_PingTypeForWeaponClass <-
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
	["models/props_junk/gascan001a.mdl"]			= PingType.WEAPON_GASCAN,
	["models/props_junk/gnome.mdl"]					= PingType.WEAPON_GNOME,
	["models/props_junk/explosive_box001.mdl"]		= PingType.WEAPON_FIREWORKCRATE,
	["models/props_junk/propanecanister001a.mdl"]	= PingType.WEAPON_PROPANETANK,
	["models/props_equipment/oxygentank01.mdl"]		= PingType.WEAPON_OXYGENTANK,
}

local m_PingTypeForConcept = m_PingTypeForConcept;
local m_PingTypeForWeaponClass = m_PingTypeForWeaponClass;
local m_PingTypeForWeaponModel = m_PingTypeForWeaponModel;
local m_PingTypeForPhysModel = m_PingTypeForPhysModel;

function PingChatter( player, concept )
{
	local pingType = m_PingTypeForConcept[ concept ];

	// local pos
	local vecPingPos = GetHeadOrigin( player ) - player.GetOrigin();
	vecPingPos.x = vecPingPos.y = 0.0;
	vecPingPos.z += 32.0;

	local lastPing = g_lastChatterPing[ player ];

	if (PING_DEBUG_VERBOSE) printl("g_lastChatterPing[ "+player+" ] " + lastPing)

	if ( lastPing )
	{
		// NOTE: it might be reused for other pings, reset pos and parent

		local ping = m_PingLookup[ pingType ];
		local lifetime = ping[m_lifetime];
		local colour = ping[m_colour];

		lastPing.SetModel( ping[0] );
		if (!colour) Assert( colour );
		lastPing.__KeyValueFromString( "rendercolor", colour );
		SetNetPropEntity( lastPing, "m_hMoveParent", player );
		lastPing.SetLocalOrigin( vecPingPos );

		local sc = lastPing.GetScriptScope();
		sc.m_bInitRem		= true;
		sc.m_flLifeTime		= lifetime;
		sc.SpriteThink		= SpriteThink;

		return AddThinkToEnt( lastPing, "SpriteThink" );
	};

	local spr = SpriteCreate( player, pingType, vecPingPos, null, player );
	g_lastChatterPing[ player ] <- spr;
}

//
// Input: CBasePlayer caller, CBaseEntity target, Vector fallbackPos
//
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
					// TODO: show teammate health on the ping?

					// A teammate pinged me
					EmitSoundOnClient( PingSound.ALERT, pEnt );

					local hDominator = pEnt.GetSpecialInfectedDominatingMe();
					if ( hDominator )
					{
						pingType = PingType.WARNING;
						pEnt = hDominator;
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
					// A teammate pinged me
					EmitSoundOnClient( PingSound.ALERT, pEnt );
					pingType = PingType.TEAMMATE;
				}
			};

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

			if ( m_UncommonModels.find( pEnt.GetModelName() ) )
			{
				vecPingPos = GetHeadOrigin( pEnt ) - pEnt.GetOrigin();
				vecPingPos.x = vecPingPos.y = 0.0;
				vecPingPos.z += 32.0;

				// just create it here
				return SpriteCreate( player, PingType.INCAP, vecPingPos, pEnt, pEnt );
			};

			pingType = PingType.INFECTED;
			break;

		case "prop_physics":

			local mdl = pEnt.GetModelName();
			if ( mdl in m_PingTypeForPhysModel )
			{
				pingType = m_PingTypeForPhysModel[mdl];
				vecPingPos = pEnt.GetCenter();
				vecPingPos.z += 12.0;
			};
			break;

		case "prop_health_cabinet":
			pingType = PingType.MEDCAB;
			local f = pEnt.GetForwardVector();
			local r = f.Cross( Vector(0.0, 0.0, 1.0) );
			r.Norm();
			local u = r.Cross(f);
			u.Norm();
			vecPingPos = pEnt.GetCenter() + f * 8.0 + u * 40.0;
			break;

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

		case "upgrade_ammo_explosive":
			pingType = PingType.UPGRADEPACK_EXP;
			vecPingPos = pEnt.GetCenter();
			vecPingPos.z += 12.0;
			break;

		case "upgrade_ammo_incendiary":
			pingType = PingType.UPGRADEPACK_INC;
			vecPingPos = pEnt.GetCenter();
			vecPingPos.z += 12.0;
			break;

		case "upgrade_laser_sight":
			pingType = PingType.UPGRADEPACK_LASER;
			vecPingPos = pEnt.GetCenter();
			vecPingPos.z += 12.0;
			break;

		// Partial matches and undefined entities
		default:
		{
			if ( !player.IsSurvivor() )
				break;

			// All weapons go through here
			if ( szClassname.find("weapon") == 0 )
			{
				if (PING_DEBUG_VERBOSE)
				{
					printl( "         "+szClassname+"->m_weaponID " + GetNetPropInt( pEnt, "m_weaponID" ) );
					// printl( "         "+szClassname+"->m_iszMeleeWeapon " + GetNetPropString( pEnt, "m_iszMeleeWeapon" ) );
					// printl( "         "+szClassname+"->m_iszWeaponToSpawn " + GetNetPropString( pEnt, "m_iszWeaponToSpawn" ) );
				};

				// sanitise the name
				local i = szClassname.find("_spawn");
				if ( i )
				{
					szClassname = szClassname.slice( 0, i );
					if (PING_DEBUG_VERBOSE) printl( "         sanitised weapon classname " + szClassname );
				};

				if ( szClassname in m_PingTypeForWeaponClass )
				{
					pingType = m_PingTypeForWeaponClass[ szClassname ];
					// if (PING_DEBUG_VERBOSE) print( "            match classname\n" );
				}
				else
				{
					local szModelName = pEnt.GetModelName();

					// full model name match
					if ( szModelName in m_PingTypeForWeaponModel )
					{
						pingType = m_PingTypeForWeaponModel[ szModelName ];
						// if (PING_DEBUG_VERBOSE) print( "            match modelname\n" );
					}
					// fallback
					else
					{
						if ( szClassname == "weapon_melee" )
							pingType = PingType.WEAPON_FIREAXE;
						else // szClassname == "weapon"
							pingType = PingType.WEAPON_PISTOL;

						if (PING_DEBUG) error("unrecognised weapon model and class '"+szClassname+"', '"+szModelName+"'\n");
					};
				};

				vecPingPos = pEnt.GetCenter();
				vecPingPos.z += 12.0;
				break;

			}; // weapon class

			// undefined entity type, use fallback pos
			if (PING_DEBUG) Assert( vecPingPos );

		} // classname switch default
	} // classname switch

	if ( PING_DEBUG_DRAW )
		DrawEntAxis( pEnt, PING_LIFETIME );

	return SpriteCreate( player, pingType, vecPingPos, pEnt );
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

function PingTrace( player, tr = s_tr )
{
	local eyePos = player.EyePosition();
	tr.start = eyePos;
	tr.end = eyePos + player.EyeAngles().Forward().Scale( MAX_TRACE_LENGTH );
	tr.ignore = player;

	TraceLine( tr );

	if ( PING_DEBUG )
	{
		printf( "(%.2f) Trace info %s:\n", Time(), ""+player );
		printf( "\tent         : %s\n", ""+tr.enthit );

		if ( tr.startsolid )
		{
			printf( "\tstartsolid  : %s\n", ""+tr.startsolid );
			tr.startsolid = null;
		};

		if ( tr.enthit && tr.enthit != Entities.First() )
		{
			printf( "\tclass       : %s\n", tr.enthit.GetClassname() );
			printf( "\tmodel       : %s\n", tr.enthit.GetModelName() );
		};

		if ( !tr.enthit )
			print("\nNULL ent in trace\n\n");
	};

	return PingEntity( player, tr.enthit, tr.pos );
}

function OnCommandPing( player )
{
	// If player is being dominated, skip trace and ping self
	local hMyDominator = player.GetSpecialInfectedDominatingMe();
	if ( hMyDominator )
	{
		local vecPingPos = hMyDominator.EyePosition();
		vecPingPos.z = GetHeadOrigin( hMyDominator ).z + 32.0;

		return SpriteCreate( player, PingType.WARNING, vecPingPos, hMyDominator );
	};

	return PingTrace( player );
}


::__CollectGameEventCallbacks( this );


if ( PING_DEBUG )
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

		DebugDrawLine( v, v + forward * 16.0, 255,0,0,true, tm );
		DebugDrawLine( v, v + right * 16.0, 0,255,0,true, tm );
		DebugDrawLine( v, v + up * 16.0, 0,0,255,true, tm );
	}
};


// VERY basic interface to change some settings
//----------------------------------------------------------------------

function SetPingDuration( type, time )
{
	if ( type == -1 )
	{
		foreach ( ping in m_PingLookup )
		{
			ping[m_lifetime] = time.tofloat();
		}
	}
	else if ( type in m_PingLookup )
	{
		m_PingLookup[type][m_lifetime] = time.tofloat();
	}

	Msg(format( "PingSystem::SetPingDuration(%i, %f)\n", type, time.tofloat() ));
}

function SetPingColour( type, r, g, b )
{
	r = r.tointeger() & 0xFF;
	g = g.tointeger() & 0xFF;
	b = b.tointeger() & 0xFF;

	local col = format( "%i %i %i 255", r, g, b );;

	if ( type == -1 )
	{
		foreach ( ping in m_PingLookup )
		{
			ping[m_colour] = col;
		}
	}
	else if ( type in m_PingLookup )
	{
		m_PingLookup[type][m_colour] = col;
	}

	Msg(format( "PingSystem::SetPingColour(%i, %i, %i, %i)\n", type, r, g, b ));
}

function DisableAutoPing( i = 1 )
{
	local add = function(n)
	{
		s_AutoBlock.rawset( n, null );
	}

	s_AutoBlock.clear();
	add( PingResponse.pass );

	switch ( i )
	{
	case 1:
		add( PingResponse.special );
		add( PingResponse.dominated );
		add( PingResponse.weapon );
		break;

	case 2:
		add( PingResponse.special );
		add( PingResponse.dominated );
		break;

	case 3:
		add( PingResponse.weapon );
		break;
	}

	Msg("PingSystem::DisableAutoPing("+i+")\n");

	if (PING_DEBUG)
	{
		foreach ( v,_ in s_AutoBlock )
		{
			foreach ( name, val in CONST.PingResponse )
			{
				if ( val == v )
				{
					printf( "\tPingResponse.%s\n", name );
				};
			}
		}
	};
}

//----------------------------------------------------------------------

// load server settings
// PingSystem.SetPingDuration( -1, 1.0 )
// PingSystem.SetPingDuration( PingType.WARNING, 10.0 )

local szScript = FileToString( "ping_system_settings.txt" );
if ( szScript )
{
	try ( compilestring(szScript)() )
	catch ( er ) { error(er) }
}

