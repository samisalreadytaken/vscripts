//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// CS:GO game event examples
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
//    ::OnGameEvent_bomb_abortdefuse <- function(event){}
//
// If you need to access other variables in your script file,
// bind callback function to 'this'
//
//    ::OnGameEvent_bomb_abortdefuse <- function(event){}.bindenv(this)
// OR
//    ::OnGameEvent_bomb_abortdefuse <- MyOnAbortDefuse.bindenv(this)
//
//------------------------------
//
// For userid, SteamID and Steam name acquisition,
// read vs_library documentation on using VS.ListenToGameEvent
//
// Using 'VS.ListenToGameEvent()' requires lightweight 'vs_events.nut'.
// Using 'ToExtendedPlayer()' requires 'vs_library.nut'.
// Using the math library requires 'vs_math.nut'.
// 'vs_library.nut' includes both the events and math libraries.
//
//------------------------------

IncludeScript("vs_library")

// test conditions
SendToConsole("mp_warmup_pausetimer 1;bot_stop 1;mp_autoteambalance 0;mp_limitteams 0")


// Collect and register game event callbacks prefixed with "OnGameEvent_" in the root
function OnPostSpawn()
{
	foreach( k,v in getroottable() )
	{
		if ( typeof v != "function" )
			continue;

		if ( k.find("OnGameEvent_") == null )
			continue;

		local event = k.slice(12);
		VS.ListenToGameEvent( event, v, "GameEventCallbacks" );
	}
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
	local msg = event.text;

	// require all chat commands to be prepended with a symbol (!)
	// if the message is not a command, leave
	if ( msg[0] != '!' )
		return;

	// Get the player. Always valid, NULL only if disconnected
	local player = VS.GetPlayerByUserid( event.userid );
	SayCommand( player, msg );

}.bindenv(this)

function SayCommand( player, msg )
{
	// tokenise the message (split by spaces)
	// 'argv[0]' is the command
	// values separated with " " can be accessed with 'argv[1]', 'argv[2]'...
	local argv = split( msg, " " );
	local argc = argv.len();

	// Your chat commands are string cases in this switch statement.
	// Strings are case sensitive.
	// To make them insensitive, 'tolower' can be added to the command string.
	// In that case, every case string needs to be lower case.
	switch ( argv[0].tolower() )
	{
		// multiple chat messages can execute the same code
		case "!hp":
		case "!health":
		{
			local value;
			if ( argc > 1 )
				value = argv[1];

			CommandSetHealth( player, value );
			break;
		}
	//	default:
	//		Msg("Invalid chat command '"+msg+"'.\n");
	}
}

function CommandSetHealth( player, health )
{
	// if health is null, the message did not have a value
	// if player is null, the player was not found
	if ( !health || !player )
		return;

	// 'value' is string, convert to int
	// invalid conversion throws excpetion
	try( health = health.tointeger() )

	// invalid value
	catch(e){ return }

	// clamp the value
	if ( health < 1 )
		health = 1;

	player.SetHealth( health );

	local sc = player.GetScriptScope();

	ScriptPrintMessageChatAll(format( "%s (%s) set their health to %d", sc.name, sc.networkid, health ));
}

// toggle flashlight by inspecting
VS.ListenToGameEvent( "inspect_weapon", function( event )
{
	local player = VS.GetPlayerByUserid( event.userid );
	if ( !player )
		return;

	// if you are adding your own flags to the player,
	// keep track of the flags in the scope of the player
	// If not, just toggle flashlight

	local scope = player.GetScriptScope();

	// ensure the flags key exists
	if ( !("fEffects" in scope) )
		scope.fEffects <- 0;

	// toggle
	scope.fEffects = scope.fEffects ^ 4;

	player.__KeyValueFromInt( "effects", scope.fEffects );
}, "" );

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
//------------------------------

VS.ListenToGameEvent( "player_spawn", function( event )
{
	local ply = VS.GetPlayerByUserid(event.userid)

	// if exists and alive
	if ( ply && ply.GetHealth() )
		ply.SetHealth(1000)
}, "SetHealthOnSpawn" );

VS.ListenToGameEvent( "player_hurt", function( event )
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
}, "OnPlayerHurt" );

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
VS.ListenToGameEvent( "item_equip", function( data )
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
}.bindenv(this), "" );

// OnWeaponDropped
VS.ListenToGameEvent( "item_remove", function( data )
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
}.bindenv(this), "" );

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
              VS.CreateEntity( "trigger_brush",{ targetname = "game_playerdie" } ),
              "OnUse", OnPlayerDeath )

//------------------------------
//
// player_blind
//
//------------------------------

VS.ListenToGameEvent( "flashbang_detonate", function( data )
{
	local name = VS.GetPlayerByUserid( data.userid ).GetScriptScope().name

	print( " ---\n" )
	print(format( "Flash banged at %g,%g,%g\n", data.x, data.y, data.z ))
	print(format( "Thrown by %s\n", name ))
}, "" );

VS.ListenToGameEvent( "player_blind", function( data )
{
	local player = VS.GetPlayerByUserid(data.userid)
	local name = player.GetScriptScope().name

	print( name + " is blind for " + data.blind_duration + " seconds.\n" )
}, "" );

//------------------------------
//
// bullet_impact
//
// Place a rotating box at bullet impact position.
//
//------------------------------

VS.ListenToGameEvent( "bullet_impact", function( event )
{
	local hitPos = Vector( event.x, event.y, event.z );
	DebugDrawBox( hitPos, Vector(-2,-2,-2), Vector(2,2,2), 255,0,255,127, 2.0 );

	// Get surface normal to stick the point out
	local ply = VS.GetPlayerByUserid( event.userid );
	local eyePos = ply.EyePosition();
	local normal = VS.TraceLine( eyePos, hitPos, ply, MASK_SOLID ).GetNormal();

	// Angle the box in reflection
	local eyeToPos = hitPos - eyePos;
	eyeToPos.Norm();
	local reflection = eyeToPos - normal * 2.0 * eyeToPos.Dot(normal);

	// Cache the player to change rotation speed while the player is looking at the box
	m_hOwner = ToExtendedPlayer( ply );
	m_bLooking = false;

	InitAnimatedBox( hitPos + normal * 6.0, reflection );

}.bindenv(this), "DrawImpact" );


m_hTimer <- null;

m_flTimeout <- 0.0;
m_vecBoxMins <- null;
m_vecBoxMaxs <- null;
m_vecBoxOrigin <- null;
m_vecRotAxis <- null;
m_vecBoxAngles <- null;
m_qRotation <- null;

m_bLooking <- false;
m_hOwner <- null;

const ROTATION_ANGLE_SLOW = 3.0;
const ROTATION_ANGLE_FAST = 12.0;

function InitAnimatedBox( vOrigin, vAxis )
{
	if ( !m_hTimer )
	{
		m_hTimer = Entities.CreateByClassname( "logic_timer" ).weakref();
		m_hTimer.__KeyValueFromFloat( "refiretime", 0.01 );
		m_hTimer.ValidateScriptScope();
		m_hTimer.GetScriptScope().BoxAnimThink <- BoxAnimThink.bindenv(this);
		m_hTimer.ConnectOutput( "OnTimer", "BoxAnimThink" );
	};

	EntFireByHandle( m_hTimer, "Enable" );

	// Think for 15 seconds
	m_flTimeout = Time() + 15.0;

	m_vecBoxMins = Vector( 0, -4, -4 );
	m_vecBoxMaxs = Vector( 32, 4, 4 );

	m_vecBoxOrigin = vOrigin;

	// Rotation axis
	m_vecRotAxis = vAxis;

	// Box angles
	m_vecBoxAngles = Vector();
	VS.VectorAngles( vAxis, m_vecBoxAngles );

	// Rotation quaternion
	m_qRotation = Quaternion();
	VS.AxisAngleQuaternion( m_vecRotAxis, ROTATION_ANGLE_SLOW, m_qRotation );
}

function BoxAnimThink()
{
	if ( Time() >= m_flTimeout )
	{
		EntFireByHandle( m_hTimer, "Disable" );
		return;
	}

	// Rotate box angles
	local qCur = Quaternion();

	VS.AngleQuaternion( m_vecBoxAngles, qCur );
	VS.QuaternionMult( m_qRotation, qCur, qCur );
	VS.QuaternionAngles( qCur, m_vecBoxAngles );

	local r,g;

	local eyePos = m_hOwner.EyePosition();
	local ray = Ray_t();
	ray.Init( eyePos, eyePos + m_hOwner.EyeForward() * MAX_COORD_FLOAT );

	// Is player looking directly at the box?
	if ( VS.IsRayIntersectingOBB( ray, m_vecBoxOrigin, m_vecBoxAngles, m_vecBoxMins, m_vecBoxMaxs ) )
	{
		r = 63; g = 255;

		if ( !m_bLooking )
		{
			m_bLooking = true;
			VS.AxisAngleQuaternion( m_vecRotAxis, ROTATION_ANGLE_FAST, m_qRotation );
		}
	}
	else
	{
		r = 255; g = 0;

		if ( m_bLooking )
		{
			m_bLooking = false;
			VS.AxisAngleQuaternion( m_vecRotAxis, ROTATION_ANGLE_SLOW, m_qRotation );
		}
	}

	// Draw rotation axis
	local p1 = m_vecBoxOrigin - m_vecRotAxis * 16;
	local p2 = m_vecBoxOrigin + m_vecRotAxis * 32;
	DebugDrawLine( p1, p2, 255,255,0,false, 0.05 );

	// Draw the box
	DebugDrawBoxAngles( m_vecBoxOrigin, m_vecBoxMins, m_vecBoxMaxs, m_vecBoxAngles, r,g,0,4, 0.05 );
}
