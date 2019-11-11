//-----------------------------------------------------------------------
//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
//                     github.com/samisalreadytaken
//-----------------------------------------------------------------------
//------------------------------
//
// Local aimbot and wallhack for 1v1 games
// The server host can execute the script without sv_cheats enabled
//
// Player 1 has the cheats enabled against the player 2
//
// By default, the first player that has joined the server
// is chosen as player 1, the second one as player 2.
//
// Players can be manually chosen with P1 and P2 functions.
//
// Persistent through rounds, needs to be executed only once.
//
// To install it, place this file and vs_library in /csgo/scripts/vscripts/
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
// Toggle triggerbot - no recoil
// weapons are 100% accurate while this is active and shooting
// unaffected by any inaccuracies
// Automatically aims at the enemy and shoots
//
//    script wh()
// Toggle wallhack - show the position of player 2
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
//
// Setting players:
//
// Reloading the script will set the player 1 and 2 to their default values
// ( default : first and second players to join the server )
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
	// make bots players
	local i; while( i = Entc("cs_bot",i) ) VS.SetName( i, "" )

	local players = VS.GetPlayersAndBots()[0],
	      len = players.len()

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

	// clear previous player2's name
	local i; while( i = Ent(NAME_P2,i) ) VS.SetName( i, "" )

	// naming to get the player angles
	if( hPlayer2 ) VS.SetName( hPlayer2, NAME_P2 )

	// initiate entities
	if( !Ent("vs_timer*") )
	{
		bNoclip <- false
		bAimHead <- true
		fTriggerInterval <- 0.02
		bAttacked <- false
		bTrigger <- false
		bAimbot <- false
		bWH <- false

		hTimer <- VS.Timer( 0, 0.001, "Think" )

		// for triggerbot - to make player shoot
		hCMD <- VS.Entity.Create("point_clientcommand")

		// to calculate player2's head origin
		local a = VS.CreateMeasure(NAME_P2)
		hPlayer2Measure <- a[1]
		hPlayer2Eye <- a[0]

		// persistency through rounds
		VS.Entity.SetKeyString( hTimer, "classname", "info_target" )
		VS.Entity.SetKeyString( hCMD, "classname", "info_target" )
		VS.Entity.SetKeyString( hPlayer2Measure, "classname", "info_target" )
		VS.Entity.SetKeyString( hPlayer2Eye, "classname", "info_target" )
	}

	if( !hPlayer2 ) EntFireHandle( hTimer, "disable" )
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
}

function P2( i )
{
	if( typeof i != "integer" ) return printl("[][P2] Invalid value")

	local players = VS.GetPlayersAndBots()[0]

	if( i > players.len() || i < 1 ) return printl("[][P2] Invalid player id")

	hPlayer2 = players[i-1]

	local i; while( i = Ent(NAME_P2,i) ) VS.SetName( i, "" )
	VS.SetName( hPlayer2, NAME_P2 )
	VS.SetMeasure( hPlayer2Measure, NAME_P2 )
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
				// getting the world pos is more useful for debugging
				// if( (VS.TraceLine(h1, h2) - h1).LengthSqr() == (h2 - h1).LengthSqr() )
				if( ::TraceLine( h1, h2, null ) == 1 )
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
	bWH = !bWH

	printl("[][] Wallhack " + (bWH ? "enabled" : "disabled"))
}

function trigger()
{
	bTrigger = !bTrigger

	printl("[][] Triggerbot " + (bTrigger ? "enabled" : "disabled"))
}

OnPostSpawn()
