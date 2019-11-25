//-----------------------------------------------------------------------
//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
//                     github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Directional Sound Training Map ( + music kits )
//
//  	Workshop:
//  		https://steamcommunity.com/sharedfiles/filedetails/?id=1880365804
//
//  		https://www.youtube.com/watch?v=WoJlC__oBqo
//
//------------------------------

// require vs_library v191026 or above

enum weapon{glock="glock",hkp2000="hkp2000",usp_silencer="usp_silencer",elite="elite",p250="p250",tec9="tec9",fn57="fn57",deagle="deagle",galilar="galilar",famas="famas",ak47="ak47",m4a1="m4a1",m4a1_silencer="m4a1_silencer",ssg08="ssg08",aug="aug",sg556="sg556",awp="awp",scar20="scar20",g3sg1="g3sg1",nova="nova",xm1014="xm1014",mag7="mag7",m249="m249",negev="negev",mac10="mac10",mp9="mp9",mp7="mp7",ump45="ump45",p90="p90",bizon="bizon",mp5sd="mp5sd",sawedoff="sawedoff",cz75a="cz75a"}

const T = 2
const CT = 3

const CL_GREEN = "171 255 130"
const CL_WHITE = "255 255 255"

::s <- this
_MAX <- -1
_MIN <- -1
MAX  <- -1
MIN  <- -1
nResolution<- 128
fIntvlCurr <- 1.0
bBlindMode <- false
bStarted   <- false
bSpawned   <- false
bAimHelper <- false
bRange     <- false
bSettingUp <- false
nCtrlIntvl <- 0
nThinkCount<- 0
list_bots  <- []
sSndCurr   <- ""
nSoundsLen <- 0

// CT spawned
function Init()
{
	// if a bot is CT
	foreach( b in VS.GetPlayersAndBots()[1] ) if( activator == b )
	{
		printl(" !!! WRONG TEAM\nWhat have you done?!")
		throw "WRONG TEAM"
	}

	// redundant
	SendToConsole("game_mode 0;game_type 0;mp_warmup_end")

	// t spawn points
	EntFire("tt","setenabled")

	// single player : HPlayer
	VS.GetLocalPlayer()

	SendToConsole("r_screenoverlay\"\"")
	ScriptSetRadarHidden(false)
	PrecacheScriptSound("Doors.Metal.Move1")

	// sound target
	// alternatively the bot's origin could be used,
	// but using an external entity allows playing the sound
	// even when the bot is not placed.
	if( !(hTarget <- Ent("t")) ) hTarget <- VS.Entity.Create("info_target","t")

	// play sound
	hTimerSnd <- VS.Timer( 1, fIntvlCurr, "PlaySound" )

	// vertical aim helper
	hTimerAim <- VS.Timer( 1, 0.1, "CheckAng" )

	hAIMBOT <- VS.Timer( 1, 0.01, "AIMBOT" )

	// 1. set bot angles to the center of the map
	// 2. sound-interval setting timer
	hTimerThink <- VS.Timer( 1, 0.01, "BotAng" )

	// Music kit 10 second countdown timer
	hTimer10 <- VS.Timer( 1, fFrameTime, "Tick" )
	hMsgTen <- VS.Entity.Create( "point_worldtext", null, { origin = "-179 -172 100", angles = "0 -120 0", message = "10.0000" } )

	VS.SetParent( hMsgTen, Ent("d") )

	// Display info on the music kits when looked at
	hTimerLook <- VS.Timer( 0, 0.1, "Looking" )

	// player eye angles
	HPlayerEye <- VS.CreateMeasure("player")[0]

	// hud hint
	hHudhint <- VS.CreateHudHint()

	// game_ui for sound-interval setting
	hGameUI <- Ent("u")
	VS.Entity.AddOutput( hGameUI, "PressedForward",  "SetInterval_add" )
	VS.Entity.AddOutput( hGameUI, "PressedBack",     "SetInterval_sub" )
	VS.Entity.AddOutput( hGameUI, "UnpressedForward","SetInterval_rel" )
	VS.Entity.AddOutput( hGameUI, "UnpressedBack",   "SetInterval_rel" )

	// "You killed X"
	hGametext <- VS.CreateGameText(null,{
			channel = 1,
			color = "255 255 255",
			color2 = "250 250 250",
			fadeout = 0.4,
			holdtime = 1.4,
			x = 0.435,
			y = 0.7,
	})

	// Team coin
	VS.CreateTextureToggle("c")

	// default values
	SetRange(0,0)
	SetSoundType(0,0)

	// these are delayed because of the game type 2 training
	delay( "s.Equip(weapon.m4a1)", 0.1 )
	delay( "SendToConsole(\"buy usp_silencer\")", 0.3 )
	delay( "SendToConsole(\"game_mode 0;game_type 2\")", 0.6 )
	delay( "VS.ValidateUseridAll()", 0.6 )

	ClearChat()

	// catch if the player userid is not validated
	try{
		Chat( txt.lightgreen + "● "+txt.lightblue+"Welcome, "+SPlayer.name+"!")
		Chat( ChatPrefix() + txt.yellow + "Using a silenced weapon is suggested to protect your hearing.")
		Chat(" ")
		printl("\n\nWelcome, "+SPlayer.name+"!")
		printl("Using a silenced weapon is suggested to protect your hearing.")
		printl("")
	}catch(e){printl("Loading...")}
}

// distance between spawn points
function SetResolution( d )
{
	nResolution = d
	MAX = _MAX / d
	MIN = _MIN / d
}

// true : spawn around the center
// false: spawn everywhere
function SetRange( b, m = true )
{
	if( !b )
	{
		// hard set values, dependant of the map
		_MAX = 896
		_MIN = 384

		VS.Entity.SetKeyString( Ent("t2"),"color",CL_WHITE )
		if(m)Chat( ChatPrefix() + txt.yellow + "Enemies can now spawn everywhere")
	}
	else
	{
		// if _MAX == _MIN, spawn only one line
		_MAX = 384
		_MIN = 384

		VS.Entity.SetKeyString( Ent("t2"),"color",CL_GREEN )
		if(m)Chat( ChatPrefix() + txt.yellow + "Enemies will only spawn around you")
	}

	if(m)Chat(" ")

	bRange = b
	SetResolution( nResolution )
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
	switch(RandomInt(0,3))
	{
		case 0: return Vector(RandomInt(-MAX, MAX)*nResolution,RandomInt( MIN, MAX)*nResolution,16)
		case 1: return Vector(RandomInt( MIN, MAX)*nResolution,RandomInt(-MAX, MAX)*nResolution,16)
		case 2: return Vector(RandomInt(-MAX, MAX)*nResolution,RandomInt(-MAX,-MIN)*nResolution,16)
		case 3: return Vector(RandomInt(-MAX,-MIN)*nResolution,RandomInt(-MAX, MAX)*nResolution,16)
	}
}

// place the bot and sound target (at head level)
// play the sound, enable sound timer
// until the bot is killed
function Process()
{
	if( !bStarted ) return

	if( bBlindMode ) SendToConsole("r_screenoverlay\"tools/toolsblack\"")

	local v = RandomPos()

	GetBot().SetOrigin(v)
	hTarget.SetOrigin(Vector(v.x,v.y,64))
	hTarget.EmitSound(GetSound())

	EntFireHandle( hTimerSnd,"enable" )

	EntFireHandle( hTimerThink,"enable" )

	bSpawned = true
}

// if nSoundsLen has a value,
// randomise the sounds in list_sounds.
// else use sSndCurr
function GetSound()
{
	if( nSoundsLen ) return list_sounds[RandomInt(0,nSoundsLen-1)]
	return sSndCurr
}

function GetBot()
{
	// redundant
	if( list_bots.len() == 0 ) return SendToConsole("mp_restartgame 1")
	return list_bots[0]
}

function SetSoundType( i, m = true )
{
	list_sounds <- []
	switch( i )
	{
		// headshot
		case 2:
			list_sounds = ["Player.DamageHelmet","Player.DamageHeadShot"]
			SetInterval_set(1.0)
			SetRange(0,0)
			break

		case 0:
			sSndCurr = "Weapon_AK47.Single"
			SetInterval_set(0.2)
			SetRange(0,0)
			break

		case 6:
			sSndCurr = "Weapon_M4A1.Single"
			SetInterval_set(0.2)
			SetRange(0,0)
			break

		case 1:
			sSndCurr = "CT_Concrete.StepRight"
			SetInterval_set(0.3)
			SetRange(1,0)
			break

		case 7:
			sSndCurr = "CT_SolidMetal.StepRight"
			SetInterval_set(0.3)
			SetRange(1,0)
			break

		case 4:
			sSndCurr = "Flashbang.Bounce"
			SetInterval_set(0.5)
			break

		case 5:
			sSndCurr = "Flashbang.Explode"
			SetInterval_set(1.5)
			break
	}

	nSoundsLen = list_sounds.len()

	for( local j = 0; j <= 7; j++ )
		try(VS.Entity.SetKeyString( Ent("s"+j), "color", CL_WHITE ))catch(e){/*("s"+j+" doesn't exist, I know.")*/}

	VS.Entity.SetKeyString( Ent("s"+i), "color", CL_GREEN )
}

function ToggleBlindMode( b )
{
	if( !b )
	{
		VS.Entity.SetKeyString( Ent("t1"),"color",CL_WHITE )
		Chat( ChatPrefix() + txt.yellow + "Blind mode " + txt.lightred + "disabled" )
	}
	else
	{
		VS.Entity.SetKeyString( Ent("t1"),"color",CL_GREEN )
		Chat( ChatPrefix() + txt.yellow + "Blind mode " + txt.lightgreen + "enabled" )
		if(!bAimHelper)Chat( ChatPrefix() + txt.lightblue + "Suggested: " + txt.yellow + "enabling aim helper" )
	}

	Chat(" ")
	bBlindMode = b
}

function ToggleAimHelper( b )
{
	if( b )
	{
		VS.Entity.SetKeyString( Ent("t0"),"color",CL_GREEN )
		Chat( ChatPrefix() + txt.yellow + "Vertical aim helper " + txt.lightgreen + "enabled" )
		EntFireHandle( hTimerAim,"enable" )
	}
	else
	{
		VS.Entity.SetKeyString( Ent("t0"),"color",CL_WHITE )
		Chat( ChatPrefix() + txt.yellow + "Vertical aim helper " + txt.lightred + "disabled" )
		VS.HideHudHint( hHudhint,HPlayer )
		EntFireHandle( hTimerAim,"disable" )
	}

	Chat(" ")
	bAimHelper = b
}

//--------------------------
// Hold-button to modify

function SetInterval(b)
{
	if( b )
	{
		ClearChat()
		Chat( ChatPrefix() + txt.yellow + "Set the time between sounds playing." )
		Chat( ChatPrefix() + txt.yellow + "Hold "+txt.lightgreen+"W"+txt.yellow+" to increase" )
		Chat( ChatPrefix() + txt.yellow + "Hold "+txt.lightgreen+"S"+txt.yellow+" to decrease" )

		VS.ShowHudHint( hHudhint,HPlayer,fIntvlCurr )
		VS.Entity.SetKeyString( Ent("t3"),"color",CL_GREEN )

		VS.OnTimer( hTimerThink,"ThinkButton" )
		EntFireHandle( hTimerThink,"enable" )
		EntFireHandle( hGameUI,"activate","",0.0,HPlayer )
	}
	else
	{
		VS.HideHudHint( hHudhint,HPlayer )
		VS.Entity.SetKeyString( Ent("t3"),"color",CL_WHITE )

		EntFireHandle( hTimerThink,"disable" )
		EntFireHandle( hGameUI,"deactivate","",0.0,HPlayer )
	}

	nCtrlIntvl = 0
	nThinkCount = 0
	bSettingUp = b
}

// press W
function SetInterval_add(){ nCtrlIntvl =  1 }

// press S
function SetInterval_sub(){ nCtrlIntvl = -1 }

// release key
function SetInterval_rel(){ nCtrlIntvl =  0 }

function SetInterval_mod(f)
{
	HPlayer.EmitSound("UIPanorama.container_weapon_ticker")

	local d = fIntvlCurr + f

	// clamp
	if( d < 0.1 ) return

	VS.ShowHudHint( hHudhint,HPlayer,d )

	SetInterval_set(d)
}

function SetInterval_set(d)
{
	fIntvlCurr = d
	VS.Entity.SetKeyFloat( hTimerSnd, "refiretime", d )
}

function ThinkButton()
{
	nThinkCount++
	if( nThinkCount > 9 ) nThinkCount = 0
	else return

	if( !nCtrlIntvl ) return

	if( nCtrlIntvl == 1 ) SetInterval_mod(0.2)
	else if( nCtrlIntvl == -1 ) SetInterval_mod(-0.2)
}

//--------------------------

// workaround,
// can't be bothered to fix the problem
function Start()
{
	Ent("d").EmitSound("Doors.Metal.Move1")
	Chat( ChatPrefix() + txt.purple + "START" )

	EntFireHandle( hTimerLook,"disable" )

	VS.ValidateUseridAll()
	delay("s._Start()", 0.17)
}

function _Start()
{
	SendToConsole("game_mode 0;game_type 2;r_cleardecals")
	ScriptSetRadarHidden(true)

	if(bSettingUp)SetInterval(false)
	bStarted = true
	SetupBots()

	VS.OnTimer( hTimerThink,"BotAng" )
	EntFireHandle( hTimerThink,"enable" )
	if( bAimHelper ) EntFireHandle( hTimerAim,"enable" )
	EntFire("d","open")

	delay( "s.Process()", RandomFloat(1.5,2.9) )
}

function Stop()
{
	if( !bStarted ) return

	Ent("d").EmitSound("Doors.Metal.Move1")

	Chat( ChatPrefix() + txt.purple + "STOP" )

	bSpawned = false
	bStarted = false
	Kill(GetBot())
	ScriptSetRadarHidden(false)
	SendToConsole("r_screenoverlay\"\"")
	EntFire("d","close")
	EntFireHandle( hTimerSnd,"disable" )
	EntFireHandle( hTimerThink,"disable" )
	EntFireHandle( hTimerAim,"disable" )
	EntFireHandle( hAIMBOT,"disable" )

	EntFireHandle( hTimerLook,"enable" )
}

function SetupBots()
{
	list_bots.clear()

	foreach( bot in VS.GetPlayersAndBots()[1] )
	{
		// The first spawned bot won't have its userid validated,
		// because of the game type. Kick it.
		if( bot.GetScriptScope().name.len() == 0 ) SendToConsole( "kickid " + bot.GetScriptScope().userid + ";bot_add")
		else if( bot.GetHealth() > 0 )
		{
			bot.SetHealth(1)
			list_bots.append(bot)
		}
		// Bot not spawned yet,
		// but it's okay because we have more bots in the storage, right?
		else if(GetDeveloperLevel()>=1) printl(" !!! YOU KILLED "+bot.GetScriptScope().name.toupper())
	}

	// cheap workaround to spawn all bots
	if( list_bots.len() == 0 ) SendToConsole("mp_restartgame 1")
}

// slam the bot to the ground
function Kill( h )
{
	local v = h.GetOrigin()
	v.z += 32
	h.SetOrigin(v)
	h.SetVelocity(Vector(0,0,-1000))
}

// Add the bot back to available bots list
function OnSpawn( data )
{
	if( !bStarted ) return

	if( data.teamnum == 2 )
	{
		local e = VS.GetHandleByUserid( data.userid )
		if(!e)return; // can't be bothered to fix
		e.SetHealth(1)
		list_bots.append( e )
	}
}

function OnKill( ent )
{
	if( !bStarted ) return

	// "You killed X"
	VS.Entity.SetKeyString( hGametext, "message", "You killed " + ent.GetScriptScope().name )
	EntFireHandle( hGametext, "display", "", 0.0, HPlayer )

	if( bBlindMode ) SendToConsole("r_screenoverlay\"\"")

	// remove the bot from the (available bots) list,
	// the bot will be added back when it spawns
	foreach( i, h in list_bots ) if( h == ent )
		list_bots.remove(i)

	// stop playing sound
	EntFireHandle( hTimerSnd,"disable" )

	EntFireHandle( hTimerThink,"disable" )

	bSpawned = false

	// next
	delay( "s.Process()", RandomFloat(0.4,1.2) )
}

::OnGameEvent_player_jump<-function(){ s.Stop() }
::OnGameEvent_player_spawn<-function(data){ s.OnSpawn(data) }
::OnGameEvent_player_death<-function(data){ s.OnKill(VS.GetHandleByUserid(data.userid)) }

function PlaySound()
{
	hTarget.EmitSound(GetSound())
}

function CheckAng()
{
	local x = HPlayerEye.GetAngles().x

	if( x > 4 )
		VS.ShowHudHint( hHudhint, HPlayer, "You are aiming too low!" )
	else if( x < (-0.1) )
		VS.ShowHudHint( hHudhint, HPlayer, "You are aiming too high!" )
	else VS.HideHudHint( hHudhint, HPlayer )
}

// bot look at 0,0,0
function BotAng()
{
	local bot = GetBot()

	local yaw = VS.GetAngle2D( bot.EyePosition(), Vector() )

	bot.SetAngles(0,yaw,0)
}

function ChatPrefix()
{
	return txt.orange + "● "
}

function ToggleTeam()
{
	local t = HPlayer.GetTeam()

	if( t == T ) SetTeam(CT)
	else if( t == CT ) SetTeam(T)
}

function Equip( input )
{
	if( !Ent( "equip_"+input) ) VS.Entity.SetKeyInt(VS.Entity.Create( "game_player_equip", "equip_"+input, {spawnflags = 3, weapon_knife = 1} ), "weapon_"+input, 1)

	if(input==weapon.hkp2000||input==weapon.usp_silencer||input==weapon.fn57||input==weapon.famas||input==weapon.m4a1||input==weapon.m4a1_silencer||input==weapon.aug||input==weapon.scar20||input==weapon.mag7||input==weapon.mp9)
		SetTeam(CT)

	// EntFire( "@equip", "triggerforactivatedplayer", "weapon_"+input, 0.0, HPlayer )
	EntFire( "equip_"+input, "use", "", 0.0, HPlayer )
}

function SetTeam(i)
{
	TextureToggle("c", i-1)
	VS.Entity.SetKeyInt( HPlayer, "teamnumber", i )
}

// See the standalone aimbot script for a more advanced version
// https://github.com/samisalreadytaken/vscripts/blob/master/aimbot/aimbot.nut
function AIMBOT()
{
	if( !bSpawned ) return

	local bot  = GetBot(),
	      head = VS.TraceDir( bot.EyePosition(), bot.GetForwardVector(), 14 ),
	      ang  = VS.GetAngle( HPlayer.EyePosition(), head )

	HPlayer.SetAngles(ang.x,ang.y,0)
}

function EnableAimbot()
{
	EntFireHandle( hAIMBOT, "enable" )
	Chat( ChatPrefix() + txt.green + "Aimbot enabled" )
	caller.EmitSound("UIPanorama.container_weapon_ticker")
}

//-----------------------------------------------------------------------
//-----------------------------------------------------------------------
//-----------------------------------------------------------------------
//-----------------------------------------------------------------------

enum Music {
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
}

MusicI <- [
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
	"theverkkars_01"
]

// I should've made this into one table but
// I don't want to rewrite or copy-paste all of these.
// It's not too bad anyway.

// Access ID ("valve_csgo_01") from index (38)
//    MusicI[ idx ]
// Access the description from index
//    getconsttable()["Music"][ MusicI[ idx ] ]

sMusicKitCurrID <- MusicI[0]
sMusicKitCurr <- getconsttable()["Music"][sMusicKitCurrID]
sMusicKitSoundCurr <- ""
hCurrMusicKit <- Ent("m0")
nMusicType <- 0
fFrameTime <- FrameTime()
fCountdown <- 10.0
nCounterLook <- 0

foreach( i, v in MusicI )
{
	VS.Entity.AddOutput2( Ent("m"+i), "OnPressed", "s.PickMusicKit(" + i + ")", null, true )
	i++
}

function PickMusicKit( idx )
{
	sMusicKitCurrID = MusicI[idx]
	sMusicKitCurr = getconsttable()["Music"][sMusicKitCurrID]

	hCurrMusicKit = Ent("m"+idx)

	Chat( ChatPrefix() + "Picked " + txt.white + sMusicKitCurr )
	printl( ChatPrefix() + "Picked " + txt.white + sMusicKitCurr )

	SendToConsole("r_cleardecals")
}

function PlayMusicKit()
{
	StopMusicKitAll()

	Chat( txt.lightgreen + "▶ " + txt.yellow + "Now playing " + txt.white + sMusicKitCurr )
	printl( txt.lightgreen + "▶ " + txt.yellow + "Now playing " + txt.white + sMusicKitCurr )

	if( nMusicType == 0 )
	{
		sMusicKitSoundCurr = "Music.BombTenSecCount." + sMusicKitCurrID
		fCountdown = 10.0
		EntFireHandle( hTimer10, "enable" )
	}
	else if( nMusicType == 1 )
	{
		sMusicKitSoundCurr = "Musix.HalfTime." + sMusicKitCurrID
	}

	HPlayer.EmitSound( sMusicKitSoundCurr )
	SendToConsole("r_cleardecals")
}

function StopMusicKit()
{
	Chat( txt.lightred + "■ " + txt.yellow + "Stopped playing" )
	printl( txt.lightred + "■ " + txt.yellow + "Stopped playing" )

	EntFireHandle( hTimer10, "disable" )
	VS.Entity.SetKeyString( hMsgTen, "message", "10.0000" )

	HPlayer.StopSound( sMusicKitSoundCurr )
	SendToConsole("r_cleardecals")
}

// main menu musics can stack, stop all if any are playing.
// Alternatively I could keep track of playing tracks,
// but there's no performance worry in this map, so this is fine.
function StopMusicKitAll()
{
	foreach( k in MusicI ) HPlayer.StopSound( "Musix.HalfTime." + k )
	EntFireHandle( hTimer10, "disable" )
	VS.Entity.SetKeyString( hMsgTen, "message", "10.0000" )
}

function SetMusicType()
{
	nMusicType++

	nMusicType %= 2

	if( nMusicType == 0 )
	{
		Chat( ChatPrefix() + "Music type: " + txt.yellow + "Bomb 10 second count" )
		printl( ChatPrefix() + "Music type: " + txt.yellow + "Bomb 10 second count" )

		VS.Entity.SetKeyString( hMsgTen, "textsize", 10 )
		VS.Entity.SetKeyString( hMsgTen, "message", "10.0000" )
	}
	else if( nMusicType == 1 )
	{
		Chat( ChatPrefix() + "Music type: " + txt.yellow + "Main menu" )
		printl( ChatPrefix() + "Music type: " + txt.yellow + "Main menu" )

		VS.Entity.SetKeyString( hMsgTen, "textsize", 0 )
		EntFireHandle( hTimer10, "disable" )
		VS.Entity.SetKeyString( hMsgTen, "message", "10.0000" )
	}

	SendToConsole("r_cleardecals")
}

function Tick()
{
	fCountdown -= fFrameTime

	VS.Entity.SetKeyString( hMsgTen, "message", fCountdown )

	if( fCountdown <= 0.0 )
	{
		EntFireHandle( hTimer10, "disable" )
		VS.Entity.SetKeyString( hMsgTen, "message", "0.0000" )
	}
}

function Looking()
{
	local ent = Entities.FindByClassnameNearest( "func_button", VS.TraceDir( HPlayer.EyePosition(), HPlayerEye.GetForwardVector() ), 24 )

	if( ent )
	{
		local n = ent.GetName()

		// if entity is named "n*"
		if( n.len() && n[0] == 109 )
		{
			nCounterLook++

			// Look time
			if( nCounterLook == 1 )
			{
				nCounterLook = 0
				VS.DrawEntityBBox( 0.15, ent )
				VS.ShowHudHint( hHudhint, HPlayer, getconsttable()["Music"][MusicI[n.slice(1).tointeger()]] )
			}
		}
	}
	else VS.HideHudHint( hHudhint, HPlayer )

	VS.DrawEntityBBox( 0.15, hCurrMusicKit, 128, 255, 128 )
}
