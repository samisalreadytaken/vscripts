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
//    script aimbot()
// Toggle aimbot for player 1
//
//    script trigger()
// Toggle triggerbot for player 1.
// Note that this isn't always ideal because of the inaccuracies,
// you are better off prefiring and wallbanging yourself
//
//    script settrigger(f)
// Set triggerbot shooting interval
//
//    script wh()
// Toggle wallhack - show the position of player 2
//
//    script P1(i)
//    script P2(i,bot)
// Manually set players
//
//
// Setting players:
//
// You can reload the script to set the player 1 and 2 to their default values
//
// Manual setup:
// Get the player / bot's number from the status command (NOT userid)
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
// For example Brandon's ID is 1, Perry's is 3
// Sam's ID is 1, ExamplePlayer's is 2
//
// While setting a bot as the player 2,
// set the second parameter of the P2 function to true (1)
//
//    script P2(7,1)
// This sets Ethan as player 2
//
//    script P2(2)
// This sets ExamplePlayer as player 2
//
//    script P1(2)
// This sets ExamplePlayer as player 1
//
//    script P1(1)
// This sets Sam as player 1
//
//------------------------------
//
// Since it is not possible to get the position of the head bone of a player,
// this script calculates 12 units forward from the "eye position" (which is
// exact center of the player, it is where the camera lands and where the bullets
// come from) to simulate the head position. For this reason, the aimbot will aim
// at empty space at certain angles. Though is is not an issue when
// both players are facing the same way.
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
	local pb = VS.GetPlayersAndBots(),
	      players = pb[0],
	      bots = pb[1]

	local len_p = players.len(),
	      len_b = bots.len()

	hPlayer1 <- null
	hPlayer2 <- null

	if( len_p == 0 )
	{
		printl("No players found!")
	}
	else if( len_p == 1 )
	{
		printl("1 player found")

		hPlayer1 <- players[0]

		if( len_b > 0 )
		{
			printl("1 bot found")
			hPlayer2 <- bots[0]
		}
	}
	else if( len_p >= 2 )
	{
		hPlayer1 <- players[0]
		hPlayer2 <- players[1]
	}

	if( Ent(NAME_P2) ) VS.ChangeName( NAME_P2, "" )
	if( hPlayer2 ) VS.SetName( hPlayer2, NAME_P2 )

	if( !Ent("vs_timer*") )
	{
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
	else EntFireHandle( hTimer, "enable" )

	if( Ent(NAME_P2) ) VS.SetMeasure( hPlayer2Measure, NAME_P2 )
}

function CMD( cmd, delay = 0.0 )
{
	EntFireHandle( hCMD, "command", cmd, delay, hPlayer1 )
}

function attack()
{
	CMD( "+attack" )
	CMD( "-attack", 0.002 )
}

function P1( i )
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

	local players = VS.GetPlayersAndBots()[0]

	if( i > players.len() ) return printl("Invalid player id")

	hPlayer1 = players[i-1]
}

function P2( i, bot = false )
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

	local pb = VS.GetPlayersAndBots(),
	      players = pb[0],
	      bots = pb[1]

	if( !bot )
	{
		if( i > players.len() ) return printl("Invalid player id")

		hPlayer2 = players[i-1]
	}
	else
	{
		if( i > bots.len() ) return printl("Invalid bot id")

		hPlayer2 = bots[i-1]
	}

	VS.SetName( hPlayer2, NAME_P2 )
}

function Think()
{
	if( hPlayer2.GetHealth() )
	{
		if( bAimbot )
		{
			local h2 = VS.TraceDir( hPlayer2.EyePosition(), hPlayer2Eye.GetForwardVector(), 12 ),
			      h1 = hPlayer1.EyePosition(),
			      ang = VS.GetAngle( h1, h2 )

			hPlayer1.SetAngles( ang.x, ang.y, 0 )

			if( bTrigger )
			{
				if( (VS.TraceLine(h1, h2) - h1).LengthSqr() == (h2 - h1).LengthSqr() )
				{
					if( !bAttacked )
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

function enable()
{
	aimbot()
	wh()
}

function aimbot()
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

	bAimbot = !bAimbot
}

function wh()
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

	bWH = !bWH
}

function trigger()
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

	bTrigger = !bTrigger
}

function settrigger( f )
{
	if( !Ent("vs_timer*") ) OnPostSpawn()

	fTriggerInterval = f.tofloat()
}

OnPostSpawn()
