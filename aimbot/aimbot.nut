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
//    script aimbot()
// Toggle aimbot
//
//    script trigger()
// Toggle triggerbot - weapons are 100% accurate while this is active and shooting
//
//    script settrigger(f)
// Set triggerbot shooting interval
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
// this script calculates 8 units forward from the "eye position" (which is
// exact center of the player, it is where the camera lands and where the bullets
// come from) to simulate the head position. For this reason, the aimbot will aim
// at empty space at certain angles. Though is is not an issue when
// both players are facing each other.
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

	local i; while( i = Ent(NAME_P2,i) ) VS.SetName( i, "" )
	if( hPlayer2 ) VS.SetName( hPlayer2, NAME_P2 )

	if( !Ent("vs_timer*") )
	{
		bNoclip <- false
		bAimHead <- true
		fTriggerInterval <- 0.25
		bAttacked <- false
		bTrigger <- false
		bAimbot <- false
		bWH <- false

		hTimer <- VS.Timer( 0, 0.001, "Think" )

		hCMD <- VS.Entity.Create("point_clientcommand")

		local a = VS.CreateMeasure(NAME_P2)

		hPlayer2Measure <- a[1]
		hPlayer2Eye <- a[0]
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
	SendToConsoleServer("weapon_accuracy_nospread 1")
	CMD( "+attack" )
	CMD( "-attack", 0.002 )
	delay( "SendToConsoleServer(\"weapon_accuracy_nospread 0\")", 0.01 )
}

function P1( i )
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

	if( typeof i != "integer" ) return printl("[][P1] Invalid value")

	local players = VS.GetPlayersAndBots()[0]

	if( i > players.len() || i < 1 ) return printl("[][P1] Invalid player id")

	hPlayer1 = players[i-1]
}

function P2( i )
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

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
		if( bAimbot )
		{
			local h2

			if( bAimHead ) h2 = VS.TraceDir( hPlayer2.EyePosition(), hPlayer2Eye.GetForwardVector(), 8 )
			else
			{
				h2 = hPlayer2.EyePosition()
				h2.z -= 16
			}

			local h1  = hPlayer1.EyePosition(),
			      ang = VS.GetAngle( h1, h2 )

			hPlayer1.SetAngles( ang.x, ang.y, 0 )

			if( bTrigger )
			{
				if( !bAttacked )
				{
					if( (VS.TraceLine(h1, h2) - h1).LengthSqr() == (h2 - h1).LengthSqr() )
					{
						attack()
						bAttacked = true
						delay( "bAttacked = false", fTriggerInterval )
					}
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

function aimbot()
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

	bAimbot = !bAimbot

	printl("[][] Aimbot " + (bAimbot ? "enabled" : "disabled"))
}

function wh()
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

	bWH = !bWH

	printl("[][] Wallhack " + (bWH ? "enabled" : "disabled"))
}

function trigger()
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

	bTrigger = !bTrigger

	printl("[][] Triggerbot " + (bTrigger ? "enabled" : "disabled"))
}

function settrigger( f )
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

	if( f < 0.1 ) return printl("[][] Invalid value")

	fTriggerInterval = f.tofloat()

	printl("[][] Triggerbot shooting interval set to " + fTriggerInterval)
}

OnPostSpawn()
