//-----------------------------------------------------------------------
//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
//
// This project is licensed under the terms of the GNU GPL license,
// see <https://www.gnu.org/licenses/> for details.
//-----------------------------------------------------------------------
//------------------------------
//
// CS:GO game event examples, using vscripts and vs_library
//
//  	https://youtube.com/watch?v=5KAygtqN8MI
//
//  	https://github.com/samisalreadytaken/vs_library
//  	https://github.com/samisalreadytaken/vscripts
//
//
// You must have read the vs_library/vs_events file documentation before continuing..!
//
//
//------------------------------

IncludeScript("vs_library/vs_include")

SendToConsole("mp_warmup_pausetimer 1;bot_stop 1;mp_autoteambalance 0;mp_limitteams 0")

// To access functions created in this scope from other scopes
::SMain <- this

//------------------------------
//
// player_say
//
// Execute script code on chat commands.
//
//------------------------------

::OnGameEvent_player_say <- function( data )
{
	local msg = data.text

	// command prefix
	if( msg.slice(0,1) != "!" ) return

	SMain.Say_cmd( msg.slice(1), VS.GetHandleByUserid( data.userid ) )
}

function Say_cmd( msg, player = null )
{
	local buffer = split( msg, " " )
	local val, cmd = buffer[0]
	try( val = buffer[1] ) catch(e){}

	switch( cmd.tolower() )
	{
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
	if( health == null || player == null ) return
	try( health = health.tointeger() ) catch(e){return}

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
