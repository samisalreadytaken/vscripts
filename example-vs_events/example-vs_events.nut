//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// CS:GO game event examples, using vscripts and vs_library
//
//    https://youtube.com/watch?v=5KAygtqN8MI
//
//------------------------------
//
// Creating a new event listener:       (example bomb_abortdefuse)
//    targetname:     bomb_abortdefuse
//    EventName:      bomb_abortdefuse
//    FetchEventData: 1
//    Output:         OnEventFired >
//                        bomb_abortdefuse >
//                            RunScriptCode >
//                                OnGameEvent_bomb_abortdefuse(event_data)
//
// In code:
//    ::OnGameEvent_bomb_abortdefuse <- function(data){}
//
//------------------------------
//
// Read the vs_library documentation on setting up basis eventlisteners
// for userid, SteamID and Steam name acquisition.
//
//------------------------------

IncludeScript("vs_library")

// test conditions
SendToConsole("mp_warmup_pausetimer 1;bot_stop 1;mp_autoteambalance 0;mp_limitteams 0")

// Add reference to your scope to access it from the event scopes.
// The variable name is arbitrary

// If you have only 1 file, you can name it something simple like `s` or `S`
// If you have more than 1, give it a recognisable name, such as `SMain`
::S <- this

//------------------------------
//
// player_say
//
// Example 1.1: Execute script code on chat commands.
// Does NOT require vs_library.
//
// Example 1.2: Changing the player health
// Requirements:
//    vs_library
//    logic_eventlistener : player_spawn
//    logic_eventlistener : player_connect
//    logic_eventlistener : player_say
//
//------------------------------

::OnGameEvent_player_say <- function( data )
{
	// get the chat message
	local msg = data.text

	// if the message isn't a command, leave
	if( msg[0] != '!' ) return

	// get the player handle
	local player = VS.GetPlayerByUserid(data.userid)

	// execute
	// pass the text after the command prefix (!)
	S.SayCommand( msg.slice(1), player )
}

function SayCommand( msg, player = null )
{
	// Your chat commands are string cases in this switch statement
	// Strings are case sensitive
	// If you'd like to make them insensitive, you can add 'tolower' to the message string
	// In this case, every case string needs to be lower case character

	local buffer = split(msg, " ")
	local val, cmd = buffer[0]

	// if there are no spaces in the message, meaning the message is just "hp"
	// buffer[1] will not exist. Then val = null
	// other values that are separated with " " can be got with,
	// val2 = buffer[2]

	// val = "1337"
	if( buffer.len() > 1 )
		val = buffer[1]

	switch( cmd.tolower() )
	{
		// multiple chat messages can execute the same code
		case "hp":
		case "health":
			cmd_hp( val, player )
			break

		case "flashlight":
		case "f":
			cmd_flashlight( player )
			break

		default:
			printl("Invalid command.")
	}
}

function cmd_hp( health, player )
{
	// if health is null, the message did not have the value
	// if player is null, the player was not found player disconnected, or unexpected error
	if( health == null || player == null ) return

	// val is string, convert to int
	// if a character exists before the number, cannot convert - invalid input
	// example wrong message: "!hp m26"
	// but this will work: "!hp 26m"
	// health = 1337
	try( health = health.tointeger() )

	// invalid value
	catch(e){return}

	// setting health to a value lower than 1 causes problems, clamp it
	if( health < 1 ) health = 1

	player.SetHealth( health )
}

function cmd_flashlight(player)
{
	if( !player ) return

	// if you are adding your own additional flags to the player,
	// keep track of the flags in the scope of the player
	// If not, just toggle flashlight

	local scope = player.GetScriptScope()

	// ensure the flags key exists
	if( !("flags" in scope) ) scope.flags <- 0

	// toggle
	scope.flags = scope.flags ^ 4

	VS.SetKeyInt(player, "effects", scope.flags)
}

// toggle flashlight by inspecting
::OnGameEvent_inspect_weapon <- function(data)
{
	S.cmd_flashlight( VS.GetPlayerByUserid(data.userid) )
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
		S.BizonHeal(data)
	}
}

function BizonHeal(data)
{
	local prevHP = data.health + data.dmg_health
	local add = 2
	local player = VS.GetPlayerByUserid(data.userid)

	player.SetHealth( prevHP+add )

	// do the same to the attacker to debug
	// local attacker = VS.GetPlayerByUserid(data.attacker)
	// attacker.SetHealth( prevHP+add )
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
	printl("Flash banged @ " + data.x + "," + data.y + "," + data.z)
	printl("Thrown by " + VS.GetPlayerByUserid(data.userid))
}

::OnGameEvent_player_blind <- function(data)
{
	// VS.DumpScope(data)
	local player = VS.GetPlayerByUserid(data.userid)
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

	S.OnImpact( pos )
}

function OnImpact( pos )
{
	SpawnMelon( pos )
	delay( "KillMelon()", 2.0 )
}

list_melons <- []

function SpawnMelon(pos)
{
	local prop = CreateProp( "prop_dynamic_override", pos, "models/props_junk/watermelon01.mdl", 0 )

	list_melons.append(prop)
}

// Note that instead of constantly spawning and deleting props,
// it is better to store as many as you need instead of killing, and reusing them.
function KillMelon()
{
	list_melons.remove(0).Destroy()
}
