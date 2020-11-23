//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// As seen in:
//  	https://www.youtube.com/watch?v=mjpGEXs0iLM
//
// Example map:
//  	https://www.youtube.com/watch?v=Y0LY2eYRf7s
//
// DISCLAIMER:
//             This code is published in the hope that it will be useful,
//             without any warranty of fitness for a particular purpose.
//
// Originally included in vs_library, but this is too niche, and it shouldn't be there.
//
//------------------------------
//
// Initiating:
/*

Console.CreateDisplay( width, height, 3 )
Console.SetPositions( Vector(<position>), distance, posIndex, "<plane>" )

Console.Run( "<loop_func>", "<update_func>" )

*/
// Call 'Console.Clear' and 'Console.Update' functions in the think loop
//
// Your input needs to be in between the two,
// in an example function named 'UserInput'
//
// The 'UserInput' can fire 'Console.Stop()' to terminate the loop.
// If 'Console.Stop(1)', empty the screen.
/*

function Think()
{
	// The graphics array needs to be cleared every loop, before user input
	Console.Clear()

	UserInput()

	// Update the 3D world / console
	Console.Update()
	// Console.Update2D()
}

function OnUserUpdate( point )
{
	// do something with the points
	// see 'example-vs_console' for an example
}

function UserInput()
{
	// logic, draw
}

*/
//
// In 3D Update, pixels can only be either ON or OFF (and different colours)
// In 2D Update - print to console, user can input any character
//
//------------------------------
//
// Console.CreateDisplay( GFX_X, GFX_Y, 0 )
//
// [ [0] [0] [0] [0] [0] [0] ]  --|
// [ [0] [0] [0] [0] [0] [0] ]    |
// [ [0] [0] [0] [0] [0] [0] ]    |
// [ [0] [0] [0] [0] [0] [0] ]  GFX_Y
// [ [0] [0] [0] [0] [0] [0] ]    |
// [ [0] [0] [0] [0] [0] [0] ]  --|
//
//   |------- GFX_X -------|
//
//---------------
//
// Visualised example:
/*

local width = 3
local height = 6

local GFX = Console.CreateDisplay( width, height, 2 )

*/
// [ [0,0,0] [0,0,0] [0,0,0] ]
// [ [0,0,0] [0,0,0] [0,0,0] ]
// [ [0,0,0] [0,0,0] [0,0,0] ]
// [ [0,0,0] [0,0,0] [0,0,0] ]
// [ [0,0,0] [0,0,0] [0,0,0] ]
// [ [0,0,0] [0,0,0] [0,0,0] ]
/*

local x = 1
local y = 3

local point = GFX[ y * width + x ]

point[0] = true
point[2] = 99

*/
// [ [0,0,0] [0,0,0]     [0,0,0] ]
// [ [0,0,0] [0,0,0]     [0,0,0] ]
// [ [0,0,0] [0,0,0]     [0,0,0] ]
// [ [0,0,0] [true,0,99] [0,0,0] ]
// [ [0,0,0] [0,0,0]     [0,0,0] ]
// [ [0,0,0] [0,0,0]     [0,0,0] ]
//
//------------------------------

IncludeScript("vs_library")

::Console <- {}

function Console::Run( sFuncLoop, sFuncUserUpdate, scope = null, freq = 0.1 )
{
	if( !Ent("think.console") )
		THINK <- VS.CreateTimer(1, freq)

	VS.SetName(THINK,"think.console")

	if( !scope ) scope = VS.GetCaller()

	VS.OnTimer(THINK, sFuncLoop, scope)

	OnUserUpdate <- scope[sFuncUserUpdate].bindenv(scope)

	fShowTime <- freq + FrameTime()
}

function Console::Start()
{
	if( !("THINK" in Console) ) return Msg("ERROR: Not initiated.\n")
	EntFireByHandle(THINK, "Enable")
}

function Console::Stop( i = 0 )
{
	if( !("THINK" in Console) ) return Msg("ERROR: Not started.\n")
	if(i) Clear()
	EntFireByHandle(THINK, "Disable")
}

// ix : integer [ extra array indices for data storage ]
// need at least 1 for the world positions
// return an empty 1D array
function Console::CreateDisplay( X, Y, ix = 0 )
{
	GFX_X <- X
	GFX_Y <- Y
	GFX <- CreateArray(X, Y, ix)
}

// return an empty array : ARRAY[(y*X)+x]
function Console::CreateArray( X, Y, ix = 0 )
{
	local arr = array(X*Y,null)

	foreach( k,v in arr )
		arr[k] = array(ix + 1, 0)

	return arr
}

// return an empty 2D array : ARRAY[y][x]
function Console::CreateArray2D( X, Y, ix = 0 )
{
	local arr = array(Y,null)

	foreach( k,v in arr )
	{
		arr[k] = array(X,null)

		foreach( i,n in arr[k] )
			arr[k][i] = array(ix + 1, 0)
	}

	return arr
}

function Console::DumpNestedArrays2D( arr )
{
	foreach( a1 in arr )
	{
		print( "[ " )
		foreach( a2 in a1 )
		{
			print( "[ " )
			foreach( v in a2 )
			{
				print( v + " " )
			}
			print( "] " )
		}
		print( "]\n" )
	}
}

function Console::DumpNestedArrays( arr, X, Y )
{
	for( local y = 0; y < Y; y++ )
	{
		print( "[ " )
		for( local x = 0; x < X; x++ )
		{
			print( "[ " )
			foreach( v in arr[(x*Y)+y] )
			{
				print( v + " " )
			}
			print( "] " )
		}
		print( "]\n" )
	}
}

//------------------------------
// if( idx == 1 ) then GFX[0][1] = Vector( worldstart.x,worldstart.y,worldstart.z )
// Vector [ 0,0 : top left corner : position in world space ]
// float [ distance between 2 cells/pixels ]
// integer [ the index of the array, storing the position ]
// string [ "xy" / "yz" ]
function Console::SetPositions( worldstart, distance, idx, plane = "yz" )
{
	if(typeof worldstart != "Vector")
		throw "Invalid input type '"+typeof(worldstart)+"' ; expected 'Vector'"

	if( !("GFX" in ::Console) )
		throw "Create the graphics array first with: Console.CreateDisplay(X,Y,ix)"

	vSize <- Vector(distance,distance,distance)
	vNull <- Vector()

	local vec = Vector()

	for( local y = 0; y < GFX_Y; y++ )
	{
		vec.x = worldstart.x
		vec.y = worldstart.y
		vec.z = worldstart.z

		// vertical screen (y-z)
		if( plane.tolower() == "yz" )
			vec.z -= distance * y

		// flat-on-the-ground screen (x-y plane)
		else if( plane.tolower() == "xy" )
			vec.y -= distance * y

		else throw "Invalid plane type! "+plane

		for( local x = 0; x < GFX_X; x++ )
		{
			local pt = (y*GFX_X)+x
			vec.x += distance

			GFX[pt][idx] = Vector(vec.x,vec.y,vec.z)
		}
	}
}

function Console::SpawnAt( vec, R = 255, G = 255, B = 255 )
{
	return DebugDrawBox(vec, vNull, vSize, R, G, B, 255, fShowTime)
}

// Print the graphics array to the console
function Console::Update2D( on = "o", off = " ")
{
	for( local y = 0; y < GFX_Y; y++ ) {
		for( local x = 0; x < GFX_X; x++ ) {
			local c = GFX[(y*GFX_X)+x][0]
			c?print(c):print(off)
		}
		print("\n")
	}
}

// Call to update
function Console::Update()
{
	for( local y = 0; y < GFX_Y; y++ )
		for( local x = 0; x < GFX_X; x++ )

	OnUserUpdate( GFX[(y*GFX_X)+x] )
}

// Call to clear
function Console::Clear()
{
	for( local y = 0; y < GFX_Y; y++ )
		for( local x = 0; x < GFX_X; x++ )

	GFX[(y*GFX_X)+x][0] = 0
}

function Console::OnUserUpdate( point ){}

//------------------------------
// The last parameter in all Draw functions is
// only used in Console.Update2D
//
// You can use it to print your desired character
// into the console.

// Wrapping enabled
function Console::Draw( x, y, c = 1 )
{
	if( x >= 0 && x < GFX_X && y >= 0 && y < GFX_Y )
		GFX[(y*GFX_X)+x][0] = c

	else if( x < 0 )
		Draw( x+GFX_X, y, c )

	else if( x >= GFX_X )
		Draw( x-GFX_X, y, c )

	else if( y < 0 )
		Draw( x, y+GFX_Y, c )

	else if( y >= GFX_Y )
		Draw( x, y-GFX_Y, c )
}

//-----------------------------------------------------------------------
//
// Modified code taken from:
//  	https://github.com/OneLoneCoder/videos/blob/master/olcConsoleGameEngine.h
//
// < Copyright (C) 2018 Javidx9 >
//
// All rights belong to their respective owners.
//
//-----------------------------------------------------------------------

function Console::DrawCircle( xc, yc, r, c = 1 )
{
	local x = 0
	local y = r
	local p = 3 - 2 * r
	if(!r) return

	while (y >= x) // only formulate 1/8 of circle
	{
		Draw(xc - x, yc - y, c) //upper left left
		Draw(xc - y, yc - x, c) //upper upper left
		Draw(xc + y, yc - x, c) //upper upper right
		Draw(xc + x, yc - y, c) //upper right right
		Draw(xc - x, yc + y, c) //lower left left
		Draw(xc - y, yc + x, c) //lower lower left
		Draw(xc + y, yc + x, c) //lower lower right
		Draw(xc + x, yc + y, c) //lower right right
		if(p < 0) p += 4 * x++ + 6
		else p += 4 * (x++ - y--) + 10
	}
}

function Console::DrawLine( x1, y1, x2, y2, c = 1 )
{
	local x, y, dx, dy, dx1, dy1, px, py, xe, ye
	dx = x2 - x1
	dy = y2 - y1
	dx1 = abs(dx)
	dy1 = abs(dy)
	px = 2 * dy1 - dx1
	py = 2 * dx1 - dy1
	if(dy1 <= dx1)
	{
		if(dx >= 0)
		{
			x = x1
			y = y1
			xe = x2
		}
		else
		{
			x = x2
			y = y2
			xe = x1
		}
		Draw(x, y, c)
		for(local i = 0; x<xe; i++)
		{
			x = x + 1
			if(px<0)
				px = px + 2 * dy1
			else
			{
				if((dx<0 && dy<0) || (dx>0 && dy>0))
					y = y + 1
				else
					y = y - 1
				px = px + 2 * (dy1 - dx1)
			}
			Draw(x, y, c)
		}
	}
	else
	{
		if(dy >= 0)
		{
			x = x1
			y = y1
			ye = y2
		}
		else
		{
			x = x2
			y = y2
			ye = y1
		}
		Draw(x, y, c)
		for(local i = 0; y<ye; i++)
		{
			y = y + 1
			if(py <= 0)
				py = py + 2 * dx1
			else
			{
				if((dx<0 && dy<0) || (dx>0 && dy>0))
					x = x + 1
				else
					x = x - 1
				py = py + 2 * (dx1 - dy1)
			}
			Draw(x, y, c)
		}
	}
}

function Console::FillCircle( xc, yc, r, c = 1 )
{
	// Taken from wikipedia
	local x = 0
	local y = r
	local p = 3 - 2 * r
	if(!r) return

	local drawline = function(sx, ex, ny, c)
	{
		for(local i = sx; i < ex; i++) Draw(i, ny, c)
	}

	while(y >= x)
	{
		// Modified to draw scan-lines instead of edges
		drawline(xc - x, xc + x, yc - y, c)
		drawline(xc - y, xc + y, yc - x, c)
		drawline(xc - x, xc + x, yc + y, c)
		drawline(xc - y, xc + y, yc + x, c)
		if(p < 0) p += 4 * x++ + 6
		else p += 4 * (x++ - y--) + 10
	}
}

function Console::Clip(x, y)
{
	if(x < 0) x = 0
	if(x >= GFX_X) x = GFX_X
	if(y < 0) y = 0
	if(y >= GFX_Y) y = GFX_Y
}

function Console::Fill( x1, y1, x2, y2, c = 1 )
{
	Clip(x1, y1)
	Clip(x2, y2)
	for(local x = x1; x < x2; x++)
		for(local y = y1; y < y2; y++)
			Draw(x, y, c)
}

function Console::DrawTriangle( x1, y1, x2, y2, x3, y3, c = 1 )
{
	DrawLine(x1, y1, x2, y2, c)
	DrawLine(x2, y2, x3, y3, c)
	DrawLine(x3, y3, x1, y1, c)
}
