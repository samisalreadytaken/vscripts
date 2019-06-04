//-----------------------------------------------------------------------
//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
//
// This project is licensed under the terms of the GNU GPL license,
// see <https://www.gnu.org/licenses/> for details.
//-----------------------------------------------------------------------
//------------------------------
//
// Drawing in the CS:GO console, using vs_library/vs_console
//
//  	https://youtube.com/watch?v=Y0LY2eYRf7s
//
//  	https://github.com/samisalreadytaken/vs_library
//  	https://github.com/samisalreadytaken/vscripts
//
//------------------------------

IncludeScript("vs_library/vs_include")

SendToConsole("mp_warmup_end;mp_freezetime 0;mp_ignore_round_win_conditions 1")

function OnPostSpawn() // init
{
	VS.Console.CreateDisplay( 64,32,3 )
	VS.Console.SetPositions( Vector(1.5,-0.60,-176), 1, 1, "yz" )

	VS.Console.SetModel( "models/pixel/pixel_1.mdl" )

	VS.Console.Run( "Think", "OnUserUpdate", this )
}

loop <- 0
function UserInput()
{
	if(loop == 15) loop = 0
	VS.Console.DrawCircle( 31, 15, loop, "." )
	loop++

	VS.Console.DrawLine( 1, 2, 60, 31, "\\" )
	VS.Console.DrawCircle( 13, 21, 9, "o" )
}

function Think() // Main loop
{
	VS.Console.Clear()

	UserInput()

	// VS.Console.Update()
	VS.Console.Update2D()
}

// point[1] : Vector : worldpos
// point[2] : handle : spawned entity
// point[3] : bool : spawned or not? - required to prevent stacked spawns
function OnUserUpdate( pt )
{
	// pixel OFF
	if( !pt[0] )
	{
		// prop exists
		if( pt[3] )
		{
			try(pt[2].Destroy())catch(e){}
			pt[3] = 0
		}
	}
	// pixel ON
	else
	{
		// prop does not exist
		if( !pt[3] )
		{
			pt[2] = VS.Console.CreatePixel( pt[1] )
			pt[3] = 1
		}
	}
}

//------------------------------

function Button_rev()
{

}

function Button_stp()
{
	VS.Console.Stop(1)
}

function Button_ply()
{
	VS.Console.Start()
}

function Button_fwd()
{

}
