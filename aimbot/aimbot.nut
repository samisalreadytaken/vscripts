//-----------------------------------------------------------------------
//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
//                     github.com/samisalreadytaken
//-----------------------------------------------------------------------
//------------------------------
//
// Local aimbot and wallhack
// The server host can execute the script without sv_cheats enabled
//
// Player 1 has the cheats enabled against every enemy player
//
// By default, the first player that has joined the server is chosen as player 1
//
// Persistent through rounds, needs to be executed only once.
//
// To install it, place aimbot.nut and vs_library.nut in /csgo/scripts/vscripts/
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
//    script toggle()
// Toggle aimbot and wallhack
//
//    script toggle2()
// Toggle wallhack and triggerbot
//
//    script aimbot()
// Toggle aimbot
// Lock onto the enemy
//
//    script trigger()
// Toggle triggerbot
// weapons are 100% accurate while this is active and shooting
// unaffected by any inaccuracies
// Automatically aims at the enemy and shoots
//
//    script wh()
// Toggle wallhack - show the position of player 2 (1v1 only)
//
//    script aim()
// Toggle aiming at head and torso
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
// All-enemies mode is more expensive
//
//
// Setting players:
//
// Manual setup:
// Get the player's number from the status command (NOT userid)
/*

#userid name     uniqueid connected ping loss state rate adr
#21 1   "Sam"    STEAM_1:1:26669608
#22     "Brandon"BOT
#23     "Keith"  BOT
#24     "Perry"  BOT
#25     "Shawn"  BOT
#26     "Martin" BOT
#27     "Wyatt"  BOT
#28     "Ethan"  BOT
#29     "Adam"   BOT
#30     "Norm"   BOT
#31     "ExamplePlayer" STEAM_1:1:001
#end

*/
// For example Brandon's ID is 2, Perry's is 4
// Sam's ID is 1, ExamplePlayer's is 11
//
//
//    script P2(8)
// This sets Ethan as player 2
//
//    script P2(11)
// This sets ExamplePlayer as player 2
//
//    script P1(11)
// This sets ExamplePlayer as player 1
//
//    script P1(1)
// This sets Sam as player 1
//
//------------------------------
//
// Since it is not possible to get the position of the head bone of a player,
// this script calculates 4 units backwards from the front of the face (facemask attachment)
//
// This script is shared in the hope that it will be useful,
// without any warranty of fitness for a particular purpose.
//
// I do not condone cheating in multiplayer games.
//
//------------------------------

IncludeScript("vs_library")

const NAME_P2 = "player2"

function OnPostSpawn()
{
	// make bots human
	local i; while( i = Entc("cs_bot",i) ) VS.SetName( i, "" )

	local players = VS.GetPlayersAndBots()[0],
	      len = players.len()

	if( !("hPlayer1" in this) )
	{
		hPlayer1 <- null
		hPlayer2 <- null

		if( len == 0 )
		{
			printl("[][] No players found!")
		}
		else if( len == 1 )
		{
			printl("[][] Only 1 player found")
		}
		else if( len >= 2 )
		{
			printl("[][] "+len+" players found")

			hPlayer1 <- players[0]
			hPlayer2 <- players[1]
		}
	}

	nTeamP1 <- hPlayer1.GetTeam()
	UpdateEnemyPlayers()

	// clear previous player2's name
	local i; while( i = Ent(NAME_P2,i) ) VS.SetName( i, "" )

	// naming to get the player angles
	if( hPlayer2 ) VS.SetName( hPlayer2, NAME_P2 )

	// initiate entities
	if( !Ent("vs_timer*") )
	{
		b1v1 <- false
		bNoclip <- false
		bAimHead <- true
		fTriggerInterval <- 0.02
		bTrigger <- false
		bAimbot <- false
		bWH <- false

		hTimer <- VS.Timer( 0, 0.001, "Think2" )

		// for triggerbot - to make player shoot
		hCMD <- VS.Entity.Create("point_clientcommand")

		// to calculate player2's head origin
		local a = VS.CreateMeasure(NAME_P2)
		hPlayer2Measure <- a[1]
		hPlayer2Eye <- a[0]

		// persistency through rounds
		VS.MakePermanent( hTimer )
		VS.MakePermanent( hCMD )
		VS.MakePermanent( hPlayer2Measure )
		VS.MakePermanent( hPlayer2Eye )
	}

	bAttacked <- false
	CMD("-attack")

	if( !hPlayer2 || !list_enemy_players.len() ) EntFireHandle( hTimer, "disable" )
	else
	{
		if( Ent("vs_timer*") ) EntFireHandle( hTimer, "enable" )
		VS.SetMeasure( hPlayer2Measure, NAME_P2 )
	}
}

function CMD( cmd, delay = 0.0 )
{
	EntFireHandle( hCMD, "command", cmd, delay, hPlayer1 )
}

function attack()
{
	SendToConsoleServer("weapon_accuracy_nospread 1;weapon_recoil_scale 0.0")
	CMD( "+attack" )
	CMD( "-attack", 0.002 )
	delay( "SendToConsoleServer(\"weapon_accuracy_nospread 0;weapon_recoil_scale 2.0\")", 0.01 )
}

function P1( i )
{
	if( typeof i != "integer" ) return printl("[][P1] Invalid value")

	local players = VS.GetPlayersAndBots()[0]

	if( i > players.len() || i < 1 ) return printl("[][P1] Invalid player id")

	hPlayer1 = players[i-1]

	nTeamP1 = hPlayer1.GetTeam()
}

function P2( i )
{
	if( typeof i != "integer" ) return printl("[][P2] Invalid value")

	local players = VS.GetPlayersAndBots()[0]

	if( i > players.len() || i < 1 ) return printl("[][P2] Invalid player id")

	_P2( players[i-1] )
}

function _P2(h)
{
	hPlayer2 = h

	local i; while( i = Ent(NAME_P2,i) ) VS.SetName( i, "" )
	VS.SetName( hPlayer2, NAME_P2 )
	VS.SetMeasure( hPlayer2Measure, NAME_P2 )
}

function targets()
{
	b1v1 = !b1v1

	if( b1v1 )
	{
		P2(2)
		VS.OnTimer( hTimer, "Think" )
	}
	else
	{
		UpdateEnemyPlayers()
		bWH = false
		VS.OnTimer( hTimer, "Think2" )
		EntFireHandle( hTimer, "enable" )
	}

	printl("[][] " + (b1v1 ? "1v1 mode" : "all enemies mode"))
}

function Think()
{
	if( hPlayer2.GetHealth() )
	{
		local h2

		if( bAimHead ) h2 = VS.TraceDir( hPlayer2.GetAttachmentOrigin(15), hPlayer2Eye.GetForwardVector(), -4 )
		else
		{
			h2 = hPlayer2.EyePosition()
			h2.z -= 16
		}

		local h1  = hPlayer1.EyePosition(),
		      ang = VS.GetAngle( h1, h2 )

		if( bAimbot ) hPlayer1.SetAngles( ang.x, ang.y, 0 )

		if( bTrigger )
		{
			if( !bAttacked )
			{
				if( TraceLine( h1, h2, null ) == 1 )
				{
					hPlayer1.SetAngles( ang.x, ang.y, 0 )
					attack()
					bAttacked = true
					delay( "bAttacked = false", fTriggerInterval )
				}
			}
		}

		if( bWH ) DebugDrawBox( hPlayer2.EyePosition(), Vector(-2,-2,-2), Vector(2,2,2), 25, 255, 25, 255, 0.025 )
	}
}

function Think2()
{
	local h1 = hPlayer1.EyePosition()

	// calculate LOS to every enemy player
	foreach( player in list_enemy_players )
	{
		// if alive
		if( player.GetHealth() )
		{
			// if direct LOS
			if( TraceLine( h1, player.GetAttachmentOrigin(15), null ) == 1 )
			{
				// set P2 if not already set
				if( player.GetName() != NAME_P2 ) _P2( player )

				// logic
				return Think()
			}
		}
	}
}

function UpdateEnemyPlayers()
{
	list_enemy_players <- []

	foreach( player in VS.GetPlayersAndBots()[0] )
	{
		if( player.GetTeam() != nTeamP1 )
		{
			list_enemy_players.append( player )
		}
	}
}

function noclip()
{
	bNoclip = !bNoclip

	if( bNoclip )
	{
		VS.Entity.SetKeyInt( hPlayer1, "movetype", 8 )
		// VS.Entity.SetKeyInt( hPlayer1, "rendermode", 1 )
		// VS.Entity.SetKeyInt( hPlayer1, "renderamt", 0 )
	}
	else
	{
		VS.Entity.SetKeyInt( hPlayer1, "movetype", 2 )
		// VS.Entity.SetKeyInt( hPlayer1, "rendermode", 1 )
		// VS.Entity.SetKeyInt( hPlayer1, "renderamt", 255 )
	}

	printl("[][] Noclip " + (bNoclip ? "enabled" : "disabled"))
}

function aim()
{
	bAimHead = !bAimHead

	printl("[][] Aiming at " + (bAimHead ? "head" : "torso"))
}

function toggle()
{
	aimbot()
	wh()
}

function toggle2()
{
	wh()
	trigger()
}

function aimbot()
{
	bAimbot = !bAimbot

	printl("[][] Aimbot " + (bAimbot ? "enabled" : "disabled"))
}

function wh()
{
	if( !b1v1 ) return printl("[][!] Cannot enable WH while in all-enemies mode")

	bWH = !bWH

	printl("[][] Wallhack " + (bWH ? "enabled" : "disabled"))
}

function trigger()
{
	bTrigger = !bTrigger

	printl("[][] Triggerbot " + (bTrigger ? "enabled" : "disabled"))
}

OnPostSpawn()
