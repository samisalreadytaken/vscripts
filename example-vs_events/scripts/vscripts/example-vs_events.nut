//-----------------------------------------------------------------------
//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
//                     github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// CS:GO game event examples, using vscripts and vs_library
//
//  	https://youtube.com/watch?v=5KAygtqN8MI
//
//  	https://github.com/samisalreadytaken/vs_library
//  	https://github.com/samisalreadytaken/vscripts
//
// Standalone events library:
//  	https://github.com/samisalreadytaken/vs_library/blob/master/vs_library-events.nut
//
//
// You must have read the vs_library/vs_events file documentation before continuing..!
//
//
//------------------------------

IncludeScript("vs_library")

SendToConsole("mp_warmup_pausetimer 1;bot_stop 1;mp_autoteambalance 0;mp_limitteams 0")

// Add reference to your scope to access it from the event scopes.
// The variable name is arbitrary
::SMain <- this

//------------------------------
//
// player_say
//
// Example 1.1: Execute script code on chat commands.
// Does not require vs_library.
//
// Example 1.2: Changing the player health
// Requirements:
//    vs_library
//    logic_eventlistener : player_say
//    logic_eventlistener : player_info
//    logic_eventlistener : player_connect
//
//------------------------------

::OnGameEvent_player_say <- function( data )
{
	// get the chat message
	local msg = data.text

	// if the message isn't a command, leave
	if( msg.slice(0,1) != "!" ) return

	// get the userid
	local id = data.userid

	// get the player handle
	local player = VS.GetHandleByUserid( id )

	// execute
	SMain.say_cmd( msg.slice(1), player )
}

function Say_cmd( msg, player = null )
{
	// Your chat commands are string cases in this switch statement
	// Strings are case sensitive
	// If you'd like to make them insensitive, you can add 'tolower' method to the message string
	// In this case, every case string needs to be lower case characters

	local buffer = split( msg, " " )
	local val, cmd = buffer[0]

	// if there are no spaces in the message, meaning the message is just "hp"
	// buffer[1] will not exist. Then val = null
	// The same result can be achieved by checking the buffer length but this is good enough.
	// val = "1337"
	try( val = buffer[1] ) catch(e){}

	switch( cmd.tolower() )
	{
		// multiple chat messages can execute the same code
		case "hp":
		case "health":
			cmd_hp( val, player )
			break

		default:
			printl("Invalid command.")
	}
}

function cmd_hp( health, player )
{
	// if health is null, the message did not have the value
	// if player is null, the player was not found - userids not set up or player disconnected
	if( health == null || player == null ) return

	// val is string, convert to int
	// if a character exists before the number, cannot convert - invalid input
	// example wrong message: "!hp m26"
	// but this will work: "!hp 26m"
	// health = 1337
	try( health = health.tointeger() )

	// invalid value
	catch(e){return}

	// setting health to a value lower than 1 causes problems
	if( health < 1 ) health = 1

	player.SetHealth( health )
}

//------------------------------
//
// player_hurt
//
// Heal on bizon hit
//
// Increases the health after the damage is done.
// So if the shot does enough damage to kill the player,
// the healing will not be done.
//
// Event datas WILL be lost on multiple player penetration.
//
//------------------------------

::OnGameEvent_player_hurt <- function(data)
{
	// VS.DumpScope(data)

	if( data.weapon == "bizon" )
	{
		SMain.BizonHeal(data)
	}
}

function BizonHeal(data)
{
	local prevHP = data.health + data.dmg_health
	local add = 2
	local player = VS.GetHandleByUserid(data.userid)

	player.SetHealth( prevHP+add )

	// do the same to the attacker to debug
	local attacker = VS.GetHandleByUserid(data.attacker)
	attacker.SetHealth( prevHP+add )
}

//------------------------------
//
// player_blind
//
// Event datas can get lost when multiple events happen in the same tick.
// You can easily test this by throwing a flash in front of multiple players
// and seeing only one player's event data being printed.
//
//------------------------------

::OnGameEvent_flashbang_detonate <- function(data)
{
	// VS.DumpScope(data)
	printl(" --- ")
	printl("Flash banged @ "+data.x+","+data.y+","+data.z)
	printl("Thrown by " + VS.GetHandleByUserid(data.userid))
}

::OnGameEvent_player_blind <- function(data)
{
	// VS.DumpScope(data)
	local player = VS.GetHandleByUserid(data.userid)
	local name = player.GetScriptScope().name

	printl(name+" is blind for "+data.blind_duration+" seconds.")
}

//------------------------------
//
// bullet_impact
//
// Spawn a watermelon on impact, kill it after 2 seconds
//
//------------------------------

PrecacheModel("models/props_junk/watermelon01.mdl")

::OnGameEvent_bullet_impact <- function(data)
{
	local pos = Vector(data.x,data.y,data.z)

	SMain.SpawnMelon( pos, SMain.nMelonCount )
	delay( "SMain.KillMelon("+SMain.nMelonCount+")", 2.0 )
	SMain.nMelonCount++
}

nMelonCount <- 0

function SpawnMelon(pos,idx)
{
	this["melon" + idx] <- VS.Entity.CreateProp( pos, "models/props_junk/watermelon01.mdl" )
}

function KillMelon(idx)
{
	(delete this["melon" + idx]).Destroy()
}
