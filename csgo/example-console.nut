//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Drawing in the CS:GO console, using console.nut
//
//  	https://youtube.com/watch?v=Y0LY2eYRf7s
//
//------------------------------

IncludeScript("vs_library")
IncludeScript("console")

SendToConsole("mp_warmup_end;mp_freezetime 0;mp_ignore_round_win_conditions 1")

// init
function OnPostSpawn()
{
	Console.CreateDisplay( 64,32,1 )
	Console.SetPositions( Vector(1.5,-0.60,-176), 1, 1, "yz" )

	Console.Run( "Think", "OnUserUpdate" )
}

function UserInput()
{

}

// Main loop
function Think()
{
	Console.Clear()

	UserInput()

	Console.Update()
	// Console.Update2D()
}

// point[1] : Vector : worldpos
function OnUserUpdate( pt )
{
	// pixel ON
	if( pt[0] )
	{
		Console.SpawnAt( pt[1] )
	}
}

//------------------------------

function Button_rev()
{

}

function Button_stp()
{
	// stop and clear
	Console.Stop(1)
}

function Button_ply()
{
	Console.Start()
}

function Button_fwd()
{

}
