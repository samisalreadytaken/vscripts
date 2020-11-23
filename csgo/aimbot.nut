//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// The server host can execute the script without sv_cheats enabled
//
// Player 1 has the cheats enabled against every enemy player
//
// By default, the first player that has joined the server is chosen as player1
// and the second player as player2
//
// Persistent through rounds, needs to be executed only once.
//
// To install it, place 'aimbot.nut', 'glow.nut' and 'vs_library.nut' in /csgo/scripts/vscripts/
//
// Video:
//  	https://www.youtube.com/watch?v=j3sOgjRgoJ0
//
//------------------------------
//
// Commands:
//
//    script_execute aimbot
// Load the script
//
//    script aimlock()
// Toggle aimlock
// Lock onto the enemy
//
//    script trigger()
// Toggle auto shoot
// weapons are 100% accurate while this is active and shooting
// unaffected by any inaccuracies
// Automatically aims at the enemy and shoots
// You can escape the auto aim while not in low fov mode,
// but moving will most likely make the you miss the shot
//
//    script wh()
// Toggle wallhack - show the position of player 2 (1v1 only)
//
//    script aim()
// Toggle aiming at head and torso
//
//    script mode()
// Toggle low fov mode
//
//    script speed()
// Toggle shooting speed
//
//    script noclip()
// Toggle noclip
//
//    script P1(i)
//    script P2(i)
// Manually set players
//
//    script targets()
// Toggle between 1v1 and all-enemies
//
//
// Setting players:
//
// Manual setup:
// Get the player's index from the status command (NOT userid)
/*

#userid name     uniqueid connected ping loss state rate adr
#21 1   "Sam"    STEAM_1:0:11101
#22     "Brandon"BOT
#23     "Keith"  BOT
#24     "Perry"  BOT
#25     "Shawn"  BOT
#26     "Martin" BOT
#27     "Wyatt"  BOT
#28     "Ethan"  BOT
#29     "Adam"   BOT
#30     "Norm"   BOT
#31     "ExamplePlayer" STEAM_1:0:11101
#end

*/
// For example Brandon's ID is 2, Perry's is 4
// Sam's ID is 1, ExamplePlayer's is 11
//
//
//    script P2(8)
// Set Ethan as player2
//
//    script P2(11)
// Set ExamplePlayer as player2
//
//    script P1(11)
// Set ExamplePlayer as player1
//
//    script P1(1)
// Set Sam as player1
//
//------------------------------

IncludeScript("vs_library")
IncludeScript("glow")

if ( !("_AIMBOT_" in this) || !_AIMBOT_ )
{
	_AIMBOT_ <-
	{
		NAME_P1 = "_aimbot_p1"
		NAME_P2 = "_aimbot_p2"

		m_hPlayer1 = null
		m_hPlayer2 = null
		m_nTeamP1 = 0
		m_list_enemy_players = []
		m_b1v1 = false
		m_bNoclip = false
		m_bAimAtHead = true
		m_flAutoShootInterval = -1.0
		m_bAutoShoot = false
		m_bAimlock = false
		m_bWH = false
		m_bMode = false
		m_bAttacked = false
		m_hCMD = null
	}

	local _ = function(){

	local VIEW_FOV  = 0.995
	local VEC_MINS  = Vector(-2,-2,-2)
	local VEC_MAXS  = Vector(2,2,2)
	local VEC_RED   = Vector(255,25,25)
	local VEC_GREEN = Vector(25,255,25)
	local flFrameTime2 = FrameTime()*3
	local INTERVAL_FIRE = 0.0625
	m_flAutoShootInterval = INTERVAL_FIRE

	m_hThink <- ::VS.Timer( 0,0,null,null,false,true ).weakref()

	// to calculate player2's head origin
	m_hPlayer2Eye <- ::VS.CreateMeasure( NAME_P2,null,true ).weakref()

	// for no low fov mode
	m_hPlayer1Eye <- ::VS.CreateMeasure( NAME_P1,null,true ).weakref()

	function Init()
	{
		::VS.OnTimer( m_hThink, Think2 )

		local players = ::VS.GetAllPlayers()
		local len = players.len()

		if ( len == 0 )
		{
			Msg("[][] No players found!\n")
		}
		else if ( len == 1 )
		{
			Msg("[][] Only 1 player found\n")

			_P1( players[0] )
		}
		else if ( len >= 2 )
		{
			Msg("[][] "+len+" players found\n")

			_P1( players[0] )
			_P2( players[1] )

			if ( len == 2 )
			{
				m_b1v1 = true
				::VS.OnTimer( m_hThink, Think )
			}
		}

		UpdateEnemyPlayers()

		if ( !m_hPlayer2 || !m_list_enemy_players.len() )
		{
			EntFireByHandle( m_hThink, "disable" )
		}
		else
		{
			if ( m_hThink ) EntFireByHandle( m_hThink, "enable" )
			::VS.SetMeasure( m_hPlayer2Eye, NAME_P2 )
		}

		Msg("[][] aimbot script loaded\n")
	}

	// kill and stop everything
	function Kill()
	{
		Msg("Terminating...\n")

		SetGlow(null)

		m_hThink.Destroy()
		m_hCMD.Destroy()
		m_hPlayer1Eye.Destroy()
		m_hPlayer2Eye.Destroy()

		// delete ::noclip
		// delete ::targets
		// delete ::wh
		// delete ::trigger
		// delete ::aim
		// delete ::aimlock

		delete _env._AIMBOT_
	}

	function SetGlow(ply)
	{
		if (!ply)
			return

		::Glow.Set( ply, ::Vector(255,25,25), 0, 3072 )
	}

	function CMD( cmd, delay = 0.0 )
	{
		return::DoEntFireByInstanceHandle( m_hCMD, "Command", cmd, delay, m_hPlayer1, null )
	}

	local param_attack = [null, "weapon_accuracy_nospread 0;weapon_recoil_scale 2.0"]

	function attack():(flFrameTime2,param_attack)
	{
		::SendToConsoleServer("weapon_accuracy_nospread 1;weapon_recoil_scale 0.0")
		CMD("+attack")
		CMD("-attack", flFrameTime2)
		::VS.EventQueue.AddEvent( ::SendToConsoleServer, flFrameTime2, param_attack )
	}

	function P1(i)
	{
		if ( typeof i != "integer" )
			return Msg("[][P1] Invalid value\n")

		local players = ::VS.GetAllPlayers()

		if ( i > players.len() || i < 1 )
			return Msg("[][P1] Invalid player id\n")

		_P1(players[i-1])
	}

	function _P1(h)
	{
		m_hPlayer1 = h.weakref()

		m_nTeamP1 = m_hPlayer1.GetTeam()

		for(local i; i = ::Ent(NAME_P1,i); )
		{
			::VS.SetName(i, "")
			::Glow.Disable(i)
		}

		::VS.SetName(m_hPlayer1, NAME_P1)
		::VS.SetMeasure(m_hPlayer1Eye, NAME_P1)
	}

	function P2( i )
	{
		if ( typeof i != "integer" )
			return Msg("[][P2] Invalid value\n")

		local players = ::VS.GetAllPlayers()

		if ( i > players.len() || i < 1 )
			return Msg("[][P2] Invalid player id\n")

		_P2( players[i-1] )
	}

	function _P2(h)
	{
		m_hPlayer2 = h.weakref()

		for ( local i; i = ::Ent(NAME_P2,i); )
		{
			::VS.SetName(i, "")
			::Glow.Disable(i)
		}

		::VS.SetName( m_hPlayer2, NAME_P2 )
		::VS.SetMeasure( m_hPlayer2Eye, NAME_P2 )

		if (m_bWH) SetGlow( m_hPlayer2 )
	}

	local __AutoShootEnd = function()
	{
		m_bAttacked = false
	}

	function Think():(VIEW_FOV,VEC_MINS,VEC_MAXS,VEC_RED,VEC_GREEN,__AutoShootEnd)
	{
		if ( m_hPlayer2.GetHealth() )
		{
			local h2

			// Since it is not possible to get the position of the head bone of a player,
			// this script calculates 4 units backwards from the front of the face (facemask attachment)
			if ( m_bAimAtHead )
			{
				h2 = m_hPlayer2.GetAttachmentOrigin(15) - m_hPlayer2Eye.GetForwardVector() * 4.0
			}
			else
			{
				h2 = m_hPlayer2.EyePosition()
				h2.z -= 16.0
			}

			local h1  = m_hPlayer1.EyePosition()
			local dt = h2 - h1

			if ( m_bAimlock )
				m_hPlayer1.SetForwardVector(dt)

			local bLOS = ::VS.TraceLine( h1, h2 ).DidHit()

			if ( m_bAutoShoot )
			{
				if ( !m_bAttacked )
				{
					if ( !bLOS )
					{
						if ( !m_bMode )
							if ( !::VS.IsLookingAt( h1,h2,m_hPlayer1Eye.GetForwardVector(),VIEW_FOV ) )
								return

						m_hPlayer1.SetForwardVector(dt)
						attack()
						m_bAttacked = true
						::VS.EventQueue.AddEvent( __AutoShootEnd, m_flAutoShootInterval, this )
					}
				}
			}

			if ( m_bWH )
			{
				::DebugDrawBox( m_hPlayer2.EyePosition(), VEC_MINS,VEC_MAXS, 25,255,25,255, 0.025 )

				if ( bLOS )
					::Glow.Set( ply, VEC_GREEN, 0, 3072 )
				else
					::Glow.Set( ply, VEC_RED, 0, 3072 )
			}
		}
	}

	function Think2():(VIEW_FOV)
	{
		local h1 = m_hPlayer1.EyePosition()

		// calculate LOS to every enemy player
		foreach( player in m_list_enemy_players )
			if ( player )
			{
				// if alive
				if ( player.GetHealth() )
				{
					local h2 = player.GetAttachmentOrigin(15)

					// if direct LOS
					if ( !VS.TraceLine(h1, h2).DidHit() )
					{
						if ( !m_bMode )
							if ( !VS.IsLookingAt( h1,h2,m_hPlayer1Eye.GetForwardVector(),VIEW_FOV ) )
								continue

						// set P2 if not already set
						if ( player.GetName() != NAME_P2 )
							_P2(player)

						// logic
						return Think()
					}
				}
			}
			else continue
	}

	function UpdateEnemyPlayers()
	{
		m_list_enemy_players.clear()

		foreach( player in ::VS.GetAllPlayers() )
		{
			if ( player.GetTeam() != m_nTeamP1 )
			{
				m_list_enemy_players.append( player.weakref() )
			}
		}
	}

// controls =============================

	function noclip()
	{
		m_bNoclip = !m_bNoclip

		if ( m_bNoclip )
		{
			m_hPlayer1.__KeyValueFromInt( "movetype", 8 )
			m_hPlayer1.__KeyValueFromInt( "rendermode", 10 )
		}
		else
		{
			m_hPlayer1.__KeyValueFromInt( "movetype", 2 )
			m_hPlayer1.__KeyValueFromInt( "rendermode", 0 )
		}

		Msg("[][] Noclip " + (m_bNoclip ? "enabled\n" : "disabled\n"))
	}

	function targets()
	{
		m_b1v1 = !m_b1v1

		if ( m_b1v1 )
		{
			P2(2)
			::VS.OnTimer( m_hThink, "Think" )
		}
		else
		{
			UpdateEnemyPlayers()
			m_bWH = false
			::VS.OnTimer( m_hThink, "Think2" )
			EntFireByHandle( m_hThink, "enable" )
		}

		Msg("[][] " + (m_b1v1 ? "1v1 mode\n" : "all enemies mode\n"))
	}

	function mode()
	{
		m_bMode = !m_bMode

		Msg("[][] Low fov " + (m_bMode ? "enabled\n" : "disabled\n"))
	}

	function speed():(INTERVAL_FIRE)
	{
		local out

		if ( m_flAutoShootInterval == INTERVAL_FIRE )
		{
			m_flAutoShootInterval = INTERVAL_FIRE + 0.25
			out = "slower"
		}
		else
		{
			m_flAutoShootInterval = INTERVAL_FIRE
			out = "faster"
		}

		Msg("[][] Shooting speed is now " + out + "\n")
	}

	function aim()
	{
		m_bAimAtHead = !m_bAimAtHead

		Msg("[][] Aiming at " + (m_bAimAtHead ? "head\n" : "torso\n"))
	}

	function aimlock()
	{
		m_bAimlock = !m_bAimlock

		Msg("[][] Aimlock " + (m_bAimlock ? "enabled\n" : "disabled\n"))
	}

	function wh()
	{
		if ( ::VS.GetAllPlayers().len() > 2 )
			return Msg("[][!] Cannot enable WH while there are more than 1 enemy\n")

		m_bWH = !m_bWH

		if (m_bWH) SetGlow(m_hPlayer2)
		else ::Glow.Disable(m_hPlayer2)

		Msg("[][] Wallhack " + (m_bWH ? "enabled\n" : "disabled\n"))
	}

	function trigger()
	{
		if ( ::VS.IsDedicatedServer() )
		{
			return Msg("[][!] Cannot enable AutoShoot in a dedicated server\n")
		}

		if ( !m_hCMD )
		{
			m_hCMD = ::VS.CreateEntity( "point_clientcommand",null,true ).weakref()
		}

		m_bAutoShoot = !m_bAutoShoot

		Msg("[][] AutoShoot " + (m_bAutoShoot ? "enabled\n" : "disabled\n"))
	}

	// save the environment so the script can be used anywhere
	_env <- this

	if ( this != getroottable() )
		::_AIMBOT_ <- this.weakref()

	// add the list of control functions inside _AIMBOT_ to the root for easy access
	// don't call if implementing this in a map
	local addtoroot = function()
	{
		local list = ["P1",
		              "P2",
		              "trigger",
		              "wh",
		              "aimlock",
		              "aim",
		              "speed",
		              "mode",
		              "targets",
		              "noclip"]

		local root = getroottable()

		foreach( k in list )
		{
			this[k] = this[k].bindenv(this) // strong ref
			root[k] <- this[k].weakref()
		}
	}()

	}.call(_AIMBOT_)
}

VS.EventQueue.AddEvent( _AIMBOT_.Init, VS.flCanCheckForDedicatedAfterSec, _AIMBOT_ )
