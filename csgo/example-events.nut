//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// CS:GO game event examples, using vscripts and vs_library
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
//                                ::OnGameEvent_bomb_abortdefuse(event_data)
//
// In code:
//    ::OnGameEvent_bomb_abortdefuse <- function(event_data){}
//
// If you will be calling other code in your script file,
// you can either add a reference to 'this' to access your code, (example in bullet_impact below)
// or bind the OnGameEvent function to 'this' (example in player_say)
//
//    ::OnGameEvent_bomb_abortdefuse <- function(event_data){}.bindenv(this)
// OR
//    ::OnGameEvent_bomb_abortdefuse <- MyOnAbortDefuse.bindenv(this)
//
//------------------------------
//
// For userid, SteamID and Steam name acquisition,
// read the vs_library documentation on setting up basis eventlisteners.
//
//------------------------------

IncludeScript("vs_library")

// test conditions
SendToConsole("mp_warmup_pausetimer 1;bot_stop 1;mp_autoteambalance 0;mp_limitteams 0")

//------------------------------

::OnGameEvent_round_freeze_end <- function(e)
{
	VS.ValidateUseridAll()
}

//------------------------------
//
// player_say
//
// Example 1.1: Execute script code on chat commands.
// Requirements:
//    logic_eventlistener : player_say
//
//
// Example 1.2: Changing the player health
// Requirements:
//    vs_library
//    logic_eventlistener : player_say
//
//------------------------------

::OnGameEvent_player_say <- function( event )
{
	// get the chat message
	local msg = event.text

	// require all chat commands to be prepended with a symbol (!)
	// if the message is not a command, leave
	if ( msg[0] != '!' )
		return

	local player = VS.GetPlayerByUserid( event.userid )
	SayCommand( player, msg )

}.bindenv(this)

function SayCommand( player, msg )
{
	// split the message by spaces
	local argv = ::split( msg, " " )
	local argc = argv.len()

	// 'argv[0]' is the command
	// values separated with " " can be accessed with 'argv[1]', 'argv[2]'...

	local value
	if ( argc > 1 )
		value = argv[1]

	// Your chat commands are string cases in this switch statement.
	// Strings are case sensitive.
	// If you'd like to make them insensitive, you can add 'tolower' to the command string
	// In that case, every case string needs to be lower case.
	switch ( argv[0].tolower() )
	{
		// multiple chat messages can execute the same code
		case "!hp":
		case "!health":
		{
			CommandSetHealth( player, value )
			break
		}
	//	default:
	//		Msg("Invalid command.\n")
	}
}

function CommandSetHealth( player, health )
{
	// if health is null, the message did not have a value
	// if player is null, the player was not found
	if ( !health || !player )
		return

	// 'value' is string, convert to int
	// if a character exists before the number, cannot convert - invalid input
	// example invalid message: "!hp m26"
	// but this will work: "!hp 26m"
	try( health = health.tointeger() )

	// invalid value
	catch(e){ return }

	// clamp the value
	if ( health < 1 )
		health = 1

	player.SetHealth( health )

	local sc = player.GetScriptScope()

	ScriptPrintMessageChatAll(format( "%s (%s) set their health to %d", sc.name, sc.networkid, health ))
}

// toggle flashlight by inspecting
::OnGameEvent_inspect_weapon <- function( event )
{
	local player = VS.GetPlayerByUserid( event.userid )

	if ( !player )
		return

	// if you are adding your own flags to the player,
	// keep track of the flags in the scope of the player
	// If not, just toggle flashlight

	local scope = player.GetScriptScope()

	// ensure the flags key exists
	if ( !("EFlags" in scope) )
		scope.EFlags <- 0

	// toggle
	scope.EFlags = scope.EFlags ^ 4

	player.__KeyValueFromInt( "effects", scope.EFlags )
}

//------------------------------
//
// player_hurt
//
// 'Changing' weapon damages
// There is no way to hook events or modify weapon network properties,
// so this is one way to manage custom damage levels.
//
// Multiply every HP and damage by 10, so the original damages will in most cases not kill the player,
// allowing you to set player health yourself.
//
// Event datas WILL be lost on multiple player penetration.
//
//------------------------------

::OnGameEvent_player_spawn <- function(event)
{
	local ply = VS.GetPlayerByUserid(event.userid)

	// if exists and alive
	if ( ply && ply.GetHealth() )
		ply.SetHealth(1000)
}

::OnGameEvent_player_hurt <- function(event)
{
	// if the victim is alive
	if ( event.health )
	{
		local victim = VS.GetPlayerByUserid(event.userid)

		switch( event.weapon )
		{
			// heal with bizon
			case "bizon":
			{
				local prevhp = event.health + event.dmg_health

				victim.SetHealth(prevhp + 2)

				// do the same to the attacker to debug
				// local attacker = VS.GetPlayerByUserid(event.attacker)
				// attacker.SetHealth(prevhp + 2)

				break
			}

			// default behaviour, damage multiplied by 10, then applied.
			// if the damage is large enough to kill the victim, manually kill
			// and manually add points to the attacker
			default:
			{
				local damage = event.dmg_health * 10
				local prevhp = event.health + event.dmg_health
				local newhp = prevhp - damage

				if ( newhp <= 0 )
				{
					local attacker = VS.GetPlayerByUserid(event.attacker)

					EntFireByHandle( victim, "SetHealth", 0 )
					EntFire( "game_score", "ApplyScore", "", 0, attacker )
				}
				else
				{
					victim.SetHealth( newhp )
				}
			}
		}
	}
}

//------------------------------
//
// Custom gun viewmodel
//
// Change the viewmodel of the player who is holding "glock"
//
// This example changes the glock of the player 'hCustomGunOwner' to deagle model
//
// Weapons with skins will print out errors every frame for skins that don't exist on the changed model
//
// It does not keep track of dropped custom weapon
//
//------------------------------

const W_CUSTOM_GUN = "models/weapons/w_pist_deagle.mdl"
const V_CUSTOM_GUN = "models/weapons/v_pist_deagle.mdl"

PrecacheModel( W_CUSTOM_GUN )
PrecacheModel( V_CUSTOM_GUN )

// These can easily be changed into arrays for multiple players
hCustomGunOwner <- null
hCustomGunViewmodel <- null

function PickupCustomGun( player )
{
	for( local ent; ent = Entities.FindByClassname( ent, "predicted_viewmodel" ); )
	{
		if ( ent.GetMoveParent() == player )
		{
			hCustomGunViewmodel = ent
			break;
		}
	}

	if ( !hCustomGunViewmodel )
	{
		print("Failed to pickup gun\n")

		return
	}

	hCustomGunOwner = player
	hCustomGunViewmodel.SetModel( V_CUSTOM_GUN )
}

// OnWeaponSwitch
::OnGameEvent_item_equip <- function( data )
{
	if ( data.item == "glock" )
	{
		local ply = VS.GetPlayerByUserid( data.userid )

		if ( ply )
		{
			if ( ply == hCustomGunOwner )
			{
				hCustomGunViewmodel.SetModel( V_CUSTOM_GUN )
			}
		}
	}
}.bindenv(this)

// OnWeaponDropped
::OnGameEvent_item_remove <- function( data )
{
	if ( data.item == "glock" )
	{
		local ply = VS.GetPlayerByUserid( data.userid )

		if ( ply )
		{
			if ( ply == hCustomGunOwner )
			{
				hCustomGunOwner = null
				hCustomGunViewmodel = null
			}
		}
	}
}.bindenv(this)

function OnPlayerDeath()
{
	if ( ::activator == hCustomGunOwner )
	{
		hCustomGunOwner = null
		hCustomGunViewmodel = null
	}
}

// Alternative way to listen to player death with no event listeners
VS.AddOutput( Ent("game_playerdie") ? Ent("game_playerdie") :
              VS.CreateEntity( "trigger_brush",{ targetname = "game_playerdie" },true ),
              "OnUse", OnPlayerDeath )

//------------------------------
//
// player_blind
//
// Event datas get lost when multiple events happen in the same tick.
// You can easily test this by throwing a flash in front of multiple players
// and seeing only one player's event data being printed.
//
//------------------------------

::OnGameEvent_flashbang_detonate <- function(data)
{
	local name = VS.GetPlayerByUserid( data.userid ).GetScriptScope().name

	print( " ---\n" )
	print(format( "Flash banged at %g,%g,%g\n", data.x, data.y, data.z ))
	print(format( "Thrown by %s\n", name ))
}

::OnGameEvent_player_blind <- function(data)
{
	local player = VS.GetPlayerByUserid(data.userid)
	local name = player.GetScriptScope().name

	print( name + " is blind for " + data.blind_duration + " seconds.\n" )
}

//------------------------------
//
// bullet_impact
//
// Spawn a watermelon on impact, kill it after 2 seconds
//
//------------------------------

PrecacheModel("models/props_junk/watermelon01.mdl")

// If you don't bind your event functions,
// Add reference to your scope to access it from the event scopes.
// The variable name is arbitrary
::SEvents <- this

::OnGameEvent_bullet_impact <- function(data)
{
	local pos = Vector(data.x,data.y,data.z)

	SEvents.OnImpact(pos)
}

function OnImpact(pos)
{
	SpawnMelon( pos )
	VS.EventQueue.AddEvent( KillMelon, 2.0, this )
}

list_melons <- []

function SpawnMelon(pos)
{
	local prop = CreateProp( "prop_dynamic_override", pos, "models/props_junk/watermelon01.mdl", 0 )

	list_melons.append(prop)
}

// Note that instead of constantly spawning and deleting props,
// it is better to store as many as you need instead of killing, and reusing them.
// This is only a demonstration of events.
function KillMelon()
{
	list_melons.remove(0).Destroy()
}
