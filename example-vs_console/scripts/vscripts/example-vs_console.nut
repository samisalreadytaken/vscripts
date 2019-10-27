//-----------------------------------------------------------------------
//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
//                     github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Drawing in the CS:GO console, using vs_library/vs_console
//
//  	https://youtube.com/watch?v=Y0LY2eYRf7s
//
//  	https://github.com/samisalreadytaken/vs_library
//  	https://github.com/samisalreadytaken/vscripts
//
//------------------------------

IncludeScript("vs_library")

SendToConsole("mp_warmup_end;mp_freezetime 0;mp_ignore_round_win_conditions 1")

 // init
function OnPostSpawn()
{
	VS.Console.CreateDisplay( 64,32,1 )
	VS.Console.SetPositions( Vector(1.5,-0.60,-176), 1, 1, "yz" )

	VS.Console.Run( "Think", "OnUserUpdate" )
}

function UserInput()
{

}

// Main loop
function Think()
{
	VS.Console.Clear()

	UserInput()

	VS.Console.Update()
	// VS.Console.Update2D()
}

// point[1] : Vector : worldpos
function OnUserUpdate( pt )
{
	// pixel ON
	if( pt[0] )
	{
		VS.Console.SpawnAt( pt[1] )
	}
}

//------------------------------

function Button_rev()
{

}

function Button_stp()
{
	// stop and clear
	VS.Console.Stop(1)
}

function Button_ply()
{
	VS.Console.Start()
}

function Button_fwd()
{

}
