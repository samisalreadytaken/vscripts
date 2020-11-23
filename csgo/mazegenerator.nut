//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Depth-first search maze generator in CS:GO
//
// Messy and inefficient code because
// I didn't expect it to become this large.
// It started as a little experiment.
//
//------------------------------
//
// cell values
// ["value", "1", "2", "3", "4", "position", "spawnedprop"]
//    [0]    [1]  [2]  [3]  [4]     [5]           [6]
//
// not visited = 0
// visited     = 1
// revisited   = 2
// border      = 9
//
//------------------------------
//   x 1 2 3 4 5 6
// y
// 1   0 0 0 0 0 0
// 2   0 0 0 0 0 0
// 3   0 0 0 0 0 0
// 4   0 0 0 0 0 0
// 5   0 0 0 0 0 0
// 6   0 0 0 0 0 0
//
//------------------------------
//--- directions ---------------
//        1
//      4   2
//        3
//------------------------------

IncludeScript("vs_library")

// debug
FINAL <- false
DEBUG <- false

// debug : maze generation delay
fGenDelay <- 0.0

// Dynamically spawn cell walls to allow very large mazes
// Type in chat to toggle: "/dyn"
// Currently only works single player
bDynamicSpawning <- true

//--- Predefined user inputs ---

// default settings:
// maze size
_MAZE_X <- 150
_MAZE_Y <- 150

// start position and direction
_POS_START_X <- 8
_POS_START_Y <- 1
_ENTRYDIR <- 1

// exit position and direction
_POS_EXIT_X <- 8
_POS_EXIT_Y <- 150
_EXITDIR <- 3

// model settings, see the reference file
// min EXT is WALL
// EXT = WALL means there's no gap in the void
local _EXT =  4
local _WALL = 4
local _CELL_SIZE = 112

// [1,1] top left cell
vecWorldOrigin <- Vector(-10176,10176,0)

const MDL_O_1 = "models/maze_generator/wall_o_1.mdl"
const MDL_O_2 = "models/maze_generator/wall_o_2.mdl" //
const MDL_O_3 = "models/maze_generator/wall_o_3.mdl" //
const MDL_O_4 = "models/maze_generator/wall_o_4.mdl" //

const MDL_V_1 = "models/maze_generator/wall_v_1.mdl"
const MDL_V_2 = "models/maze_generator/wall_v_2.mdl" //
const MDL_V_3 = "models/maze_generator/wall_v_3.mdl" //
const MDL_V_4 = "models/maze_generator/wall_v_4.mdl" //

const MDL_S_H = "models/maze_generator/wall_s_h.mdl"
const MDL_S_V = "models/maze_generator/wall_s_v.mdl" //

const MDL_T_1 = "models/maze_generator/wall_t_1.mdl"
const MDL_T_2 = "models/maze_generator/wall_t_2.mdl" //
const MDL_T_3 = "models/maze_generator/wall_t_3.mdl" //
const MDL_T_4 = "models/maze_generator/wall_t_4.mdl" //

const MDL_PXL_REV = "models/maze_generator/pixel_rev.mdl"
const MDL_PLAYER = "models/maze_generator/player_24.mdl"

//------------------------------

if (_WALL > _EXT)
	throw "WALL cannot be smaller than EXT"

//------------------------------

EXT <- _EXT - _WALL
CELL_DIST <- _WALL * 2 + EXT * 2 + _CELL_SIZE

nBreakWallAmount <- 0
bBreakWalls <- 0
bDirOverride <- 0
maze_path <- null

c_start <- null
c_exit <- null
c_prev <- null
c_next <- null

bThirdperson <- false
MAZE_YX <- []
local MAZE_YX = MAZE_YX
local THIS = this

PrecacheModel(MDL_PLAYER)
PrecacheModel(MDL_PXL_REV)

PrecacheModel(MDL_O_1)
PrecacheModel(MDL_O_2)
PrecacheModel(MDL_O_3)
PrecacheModel(MDL_O_4)

PrecacheModel(MDL_V_1)
PrecacheModel(MDL_V_2)
PrecacheModel(MDL_V_3)
PrecacheModel(MDL_V_4)

PrecacheModel(MDL_S_H)
PrecacheModel(MDL_S_V)

PrecacheModel(MDL_T_1)
PrecacheModel(MDL_T_2)
PrecacheModel(MDL_T_3)
PrecacheModel(MDL_T_4)

function StripWeapons()
{
	if(!Ent("strip")) VS.CreateEntity("game_player_equip",{ targetname = "strip", spawnflags = 2 })
	EntFire( "strip", "use", "", 0, HPlayer )
}

function Init(i=0)
{
	MAZE_YX.clear()
	MAZE_YX.resize((_MAZE_X+2)*(_MAZE_Y+2))
	foreach( k,v in MAZE_YX )
		MAZE_YX[k] = array(6 + 1, 0)

	SetPositions( vecWorldOrigin, CELL_DIST, 5, "xy" )
	SetBorders()

	nBreakWallAmount = ceil(sqrt(_MAZE_X * _MAZE_Y) / 5).tointeger()

	c_start = Cell(_POS_START_X,_POS_START_Y)
	c_exit = Cell(_POS_EXIT_X,_POS_EXIT_Y)
	c_next = c_start
	c_prev = null

	c_start.Set(1)
	c_start.Point()[_ENTRYDIR] = 1
	c_exit.Point()[_EXITDIR] = 1

	bDirOverride = 0
	maze_path = [0]

	FindEnt()
	foreach( ent in list_prop ) ent.Destroy()
	list_ent.clear()
	list_prop.clear()

	if(i)Chat("Maze reset and updated.")
}

class Cell
{
	constructor(x,y)
	{
		this.x = x
		this.y = y
	}

	x = -1
	y = -1

	function Point():(THIS,MAZE_YX)
	{
		return MAZE_YX[y*(THIS._MAZE_X+2)+x] // [y][x]
	}

	function Set(val)
	{
		Point()[0] = val
	}

	function Get()
	{
		return Point()[0]
	}
}

function SetPositions( worldstart, distance, idx, plane = "yz" )
{
	if (typeof worldstart == "instance")
		worldstart = worldstart.GetOrigin()
	else if (typeof worldstart != "Vector")
		throw "Invalid input type '"+typeof worldstart+"' ; expected 'Vector'"

	if ( plane.tolower() == "yz" )
		plane = "z"
	else if ( plane.tolower() == "xy" )
		plane = "y"
	else throw "Invalid plane type "+plane

	local vec = Vector()

	local YY = _MAZE_Y+2
	local XX = _MAZE_X+2

	for ( local y = 0; y < YY; y++ )
	{
		vec.x = worldstart.x
		vec.y = worldstart.y
		vec.z = worldstart.z

		vec[plane] -= distance * y

		for ( local x = 0; x < XX; x++ )
		{
			local pt = MAZE_YX[y*XX+x]

			vec.x += distance

			pt[idx] = Vector(vec.x,vec.y,vec.z)
		}
	}
}

// border value = 9
function SetBorders()
{
	for( local x = 0; x < _MAZE_X+2; x++ )
	{
		MAZE_YX[x][0] = 9 // [0][x]
		MAZE_YX[((_MAZE_Y+1)*(_MAZE_X+2))+x][0] = 9 // [_MAZE_Y+1][x]
	}

	for( local y = 0; y < _MAZE_Y+2; y++ )
	{
		MAZE_YX[y*(_MAZE_X+2)][0] = 9 // [y][0]
		MAZE_YX[y*(_MAZE_X+2)+_MAZE_X+1][0] = 9 // [y][_MAZE_X+1]
	}
}

function FindNext(input)
{
	c_prev = input
	c_next = null

	if( bDirOverride == 0 )
	{
		local dir = RandomInt(1,4)

		GetNext(dir)
		CheckForward(dir)
	}
	else if( bDirOverride == 1 )
	{
		TestDir()
	}

	if( IsComplete() )
		return OnPostComplete()

	if( DEBUG )
	{
		PrintMaze()
		// PrintMaze_dir()
		if( fGenDelay != 0.0 )
			VS.EventQueue.AddEvent( FindNext, fGenDelay, [this, c_next] )
		// else { } // manual
	}
	else VS.EventQueue.AddEvent( FindNext, fGenDelay, [this, c_next] )
}

function GetNext(dir)
{
	switch(dir)
	{
		case 1:
			c_next = Cell(c_prev.x,c_prev.y-1)
			// printd(" ^  " + dir + "up")
			break
		case 2:
			c_next = Cell(c_prev.x+1,c_prev.y)
			// printd(" -> " + dir + "right")
			break
		case 3:
			c_next = Cell(c_prev.x,c_prev.y+1)
			// printd(" v  " + dir + "down")
			break
		case 4:
			c_next = Cell(c_prev.x-1,c_prev.y)
			// printd(" <- " + dir + "left")
			break
	}
	// PrintCell(c_next)
}

function TestDir()
{
	local i = 1

	while( i <= 4 )
	{
		GetNext(i)
		if( CheckForward(i) )
			break
		i++
	}

	if( i == 5 )
	{
		if(DEBUG)
		{
			print("STUCK!\n")
			print("path: \n")
			foreach( k in maze_path )
				print(k)
			print("\n\n")
		}

		local k = maze_path.pop()

		// prevent depleting the array
		if( k == 0 ) return

		GetNext( revdir(k) )
		CheckReverse( revdir(k) )
	}
}

function CheckForward(dir)
{
	if( c_next.Get() == 0 )
	{
		c_next.Set(1)
		c_next.Point()[revdir(dir)] = 1

		c_prev.Point()[dir] = 1

		maze_path.append(dir)

		if( bDirOverride == 1 )
			bDirOverride = 0

		if(DEBUG)
		{
			printl("\nNot visited, marked:")
			PrintCell(c_next)
			print("\n")
		}

		return true
	}
	else
	{
		c_next = c_prev

		bDirOverride = 1
		// printd("Already visited, re-search from the previous cell \n")

		return false
	}
}

function CheckReverse(dir)
{
	c_prev.Set(2)

	if( !bDynamicSpawning )
		CreateCell( c_prev.Point() )

	if( c_next.Get() == 1 )
	{
		c_next.Set(2)
		c_next.Point()[ revdir(dir) ] = 1

		// printd("Revisited")
	}
	else if( c_next.Get() == 2 )
	{
		// printd("Already revisited.")
	}
	else throw "Something went horribly wrong"
}

function revdir(input)
{
	switch(input)
	{
		case 1: return 3
		case 2: return 4
		case 3: return 1
		case 4: return 2
	}
}

function CreateCell(input)
{
	// printd("CreateCell() input pos: \t"+input[5].x+","+input[5].y+","+input[5].z)

	// if prop already exists on the point
	if( !bDynamicSpawning ) if( input[6] ) return

	local prop

	// dead end
	if( input[1] == 1 && input[2] == 0 && input[3] == 0 && input[4] == 0)
		prop = _Create(input[5], "U")

	else if( input[1] == 0 && input[2] == 1 && input[3] == 0 && input[4] == 0)
		prop = _Create(input[5], "R")

	else if( input[1] == 0 && input[2] == 0 && input[3] == 1 && input[4] == 0)
		prop = _Create(input[5], "D")

	else if( input[1] == 0 && input[2] == 0 && input[3] == 0 && input[4] == 1)
		prop = _Create(input[5], "L")

	// v turn
	else if( input[1] == 1 && input[2] == 1 && input[3] == 0 && input[4] == 0)
		prop = _Create(input[5], "UR") // 1-2

	else if( input[1] == 1 && input[2] == 0 && input[3] == 0 && input[4] == 1)
		prop = _Create(input[5], "LU") // 1-4

	else if( input[1] == 0 && input[2] == 1 && input[3] == 1 && input[4] == 0)
		prop = _Create(input[5], "RD") // 2-3

	else if( input[1] == 0 && input[2] == 0 && input[3] == 1 && input[4] == 1)
		prop = _Create(input[5], "DL") // 3-4

	// straight
	else if( input[1] == 1 && input[2] == 0 && input[3] == 1 && input[4] == 0)
		prop = _Create(input[5], "SV") // vertical

	else if( input[1] == 0 && input[2] == 1 && input[3] == 0 && input[4] == 1)
		prop = _Create(input[5], "SH") // horizontal

	// t junc
	else if( input[1] == 1 && input[2] == 1 && input[3] == 1 && input[4] == 0)
		prop = _Create(input[5], "URD") // up right down

	else if( input[1] == 0 && input[2] == 1 && input[3] == 1 && input[4] == 1)
		prop = _Create(input[5], "RDL") // right down left

	else if( input[1] == 1 && input[2] == 0 && input[3] == 1 && input[4] == 1)
		prop = _Create(input[5], "UDL") // up down left

	else if( input[1] == 1 && input[2] == 1 && input[3] == 0 && input[4] == 1)
		prop = _Create(input[5], "URL") // up right left

	else if( input[1] == 1 && input[2] == 1 && input[3] == 1 && input[4] == 1)
	{
		// printd("NO CELL, DONT CREATE PROP \t " + input[5].x + " " + input[5].y + " " + input[5].z)
		return
	}
	else
	{
		print(input[0]+
			" | up: "+input[1]+
			"; right: "+input[2]+
			"; down: "+input[3]+
			"; left: "+input[4]+
			"; pos: "+input[5].x+","+input[5].y+"; \n")
		throw "Something went horribly wrong"
	}

	input[6] = prop.weakref()
}

//
//  x   x      xxxxx      x   x      x   x
//  x   x                 x          x
//  xxxxx      xxxxx      x   x      xxxxx
//
// MDL_O_1    MDL_S_H    MDL_T_1    MDL_V_1
//
function _Create(pos, type)
{
	local ent
	switch(type)
	{
//--------------------------------------------------------
		case "UR":
			ent = CreateSolidProp(pos, MDL_V_1)
			// ent.SetAngles(0,0,0)
			break
		case "RD":
			ent = CreateSolidProp(pos, MDL_V_2)
			// ent.SetAngles(0,-90,0)
			break
		case "DL":
			ent = CreateSolidProp(pos, MDL_V_3)
			// ent.SetAngles(0,-180,0)
			break
		case "LU":
			ent = CreateSolidProp(pos, MDL_V_4)
			// ent.SetAngles(0,90,0)
			break
//--------------------------------------------------------
		case "SH":
			ent = CreateSolidProp(pos, MDL_S_H)
			// ent.SetAngles(0,0,0)
			break
		case "SV":
			ent = CreateSolidProp(pos, MDL_S_V)
			// ent.SetAngles(0,90,0)
			break
//--------------------------------------------------------
		case "U":
			ent = CreateSolidProp(pos, MDL_O_1)
			// ent.SetAngles(0,0,0)
			break
		case "R":
			ent = CreateSolidProp(pos, MDL_O_2)
			// ent.SetAngles(0,-90,0)
			break
		case "D":
			ent = CreateSolidProp(pos, MDL_O_3)
			// ent.SetAngles(0,-180,0)
			break
		case "L":
			ent = CreateSolidProp(pos, MDL_O_4)
			// ent.SetAngles(0,90,0)
			break
//--------------------------------------------------------
		case "URD":
			ent = CreateSolidProp(pos, MDL_T_1)
			// ent.SetAngles(0,0,0)
			break
		case "RDL":
			ent = CreateSolidProp(pos, MDL_T_2)
			// ent.SetAngles(0,-90,0)
			break
		case "UDL":
			ent = CreateSolidProp(pos, MDL_T_3)
			// ent.SetAngles(0,-180,0)
			break
		case "URL":
			ent = CreateSolidProp(pos, MDL_T_4)
			// ent.SetAngles(0,90,0)
			break
//--------------------------------------------------------
		default:
			throw "Invalid type"
	}

	ent.__KeyValueFromInt("solid", 6)

	return ent
}

// TODO
// A better method would be spawning
// as many props that can be seen at once, all types
// then moving them to create the maze.
// This would save resources
function CreateSolidProp(vec, mdl)
{
	local ent = CreateProp("prop_dynamic_override", vec, mdl, 0)
	ent.__KeyValueFromInt("solid", 6)
	ent.__KeyValueFromInt("effects", 8)
	return ent
}

function BreakRandomWalls()
{
	local rand_x = RandomInt(2, _MAZE_X-1)
	local rand_y = RandomInt(2, _MAZE_Y-1)
	local rand_cell = Cell( rand_x, rand_y )
	local rand_point = rand_cell.Point()
	local rand_dir = RandomInt(1,4)

	while( rand_point[ rand_dir ] == 1 )
	{
		if( rand_point[1] == 1 && rand_point[2] == 1 && rand_point[3] == 1 && rand_point[4] == 1 )
		{
			// printl(" No walls, break the loop... \t" +
			//	rand_point[5].x + " " + rand_point[5].y + " " + rand_point[5].z)
			break
		}
		// print(rand_dir)
		rand_dir = RandomInt(1,4)
		// printl(" is already open, checking "+rand_dir)
	}

	rand_point[ rand_dir ] = 1

	if( rand_point[6] )
		rand_point[6].Destroy()
	else
		print("?!")

	CreateCell( rand_point )
	c_prev = rand_cell
	GetNext( rand_dir )

	// printl("rand " + c_prev.x + "," + c_prev.y + "\t next " + c_next.x + "," + c_next.y + "\n")

	c_next.Point()[6].Destroy()
	c_next.Point()[ revdir( rand_dir ) ] = 1
	CreateCell( c_next.Point() )
}

function PrintCell(input)
{
	printl("      ["+input.x+","+input.y+"] = "+ input.Point()[0] +
		" | up: "+input.Point()[1]+
		"; right: "+input.Point()[2]+
		"; down: "+input.Point()[3]+
		"; left: "+input.Point()[4])
}

//------------------------------

function IsComplete()
{
	return maze_path.len() == 0
}

function OnPostComplete()
{
	if( bDynamicSpawning )
		EnableDynamicSpawning()

	else if( !bDynamicSpawning )
		CreateCell(c_start.Point())

	// prints("\n MAZE COMPLETE ("+_MAZE_X+"x"+_MAZE_Y+") - " +count)
	Chat("Maze created.")

	if( bBreakWalls )
	{
		local p = 1
		local ft = FrameTime()
		while( p ++< nBreakWallAmount)
		{
			// delay a frame to prevent overflow issues
			VS.EventQueue.AddEvent( BreakRandomWalls, p*ft, this )
		}

		// prints("Broke walls.")
	}

	FindEnt()

	HPlayer.SetOrigin(Vector(c_start.Point()[5].x,c_start.Point()[5].y+CELL_DIST,c_start.Point()[5].z))
}

function PrintMaze()
{
	local YY = _MAZE_Y+2
	local XX = _MAZE_X+2

	for(local y = 0; y < YY; y++)
	{
		for(local x = 0; x < XX; x++)
		{
			print(MAZE_YX[y*XX+x][0]+" ")
		}
		print("\n")
	}
}

function PrintMaze_dir()
{
	local YY = _MAZE_Y+1
	local XX = _MAZE_X+1

	print("\n")
	for(local y = 1; y < YY; y++)
	{
		for(local x = 1; x < XX; x++)
		{
			local p = y*XX+x
			print("| "+MAZE_YX[p][1]+" "+MAZE_YX[p][2]+" "+MAZE_YX[p][3]+" "+MAZE_YX[p][4]+" | ")
		}
		printl("\n")
	}
}

//------------------------------

// overflow
function CheckForCrash()
{
	if( bDynamicSpawning )
		return

	if( ( FindEnt() + CalcPropAmount() ) > 2000 )
	{
		printl("\t ! WARNING !")
		printl(" The maze is too large to be created.")
		Chat(txt.red + " ! WARNING !")
		Chat(txt.red +"The maze is too large to be created.")

		return true
	}

	return false
}

function CalcPropAmount()
{
	return ( _MAZE_X * _MAZE_Y )
}

list_ent <- []
list_prop <- []

function FindEnt()
{
	local ent
	list_ent.clear()
	list_prop.clear()

	while ( ent = Entities.Next(ent) )
	{
		list_ent.append(ent.weakref())

		if ( ent.GetClassname().find("prop") == 0 )
			list_prop.append(ent.weakref())
	}
	// printd("Total entity count: " + list_ent.len() )
	// printd("Total prop   count: " + list_prop.len() )

	return list_ent.len()
}

//------------------------------

function PrintVars()
{
	print("\n")
	printl( "Maze size       : " + _MAZE_X + "x" + _MAZE_Y )
	printl( "V2 status       : " + TranslateBoolToText(bBreakWalls) )
	printl( "Entry position  : " + _POS_START_X + "," + _POS_START_Y )
	printl( "Entry direction : " + TranslateDirToText(_ENTRYDIR) )
	printl( "Exit position   : " + _POS_EXIT_X + "," + _POS_EXIT_Y )
	printl( "Exit direction  : " + TranslateDirToText(_EXITDIR) )
	printl( "vecWorldOrigin  : " + vecWorldOrigin.x + "," +vecWorldOrigin.y + "," + vecWorldOrigin.z)
	printl( "Dynamic spawning: " + TranslateBoolToText(bDynamicSpawning) )
	printl(" ----")
	FindEnt()
	printl("Total edict count: " + (list_ent.len() - list_prop.len()) + " (excluding props)")
	printl("Total prop  count: " + list_prop.len() )
	print("\n")

	Chat( "Maze size: "+ txt.yellow + _MAZE_X + "x" + _MAZE_Y )
	Chat( "V2 status: "+ txt.yellow + TranslateBoolToText(bBreakWalls) )
	Chat( "Entry position: "+ txt.yellow + _POS_START_X + "," + _POS_START_Y )
	Chat( "Entry direction: "+ txt.yellow + TranslateDirToText(_ENTRYDIR) )
	Chat( "Exit position: "+ txt.yellow + _POS_EXIT_X + "," + _POS_EXIT_Y )
	Chat( "Exit direction: "+ txt.yellow + TranslateDirToText(_EXITDIR) )
	Chat( "Dynamic spawning: " + TranslateBoolToText(bDynamicSpawning) )
}

function TranslateBoolToText( input )
{
	if( input )
		return txt.lightgreen+"enabled"
	else
		return txt.lightred+"disabled"
}

function TranslateTextToDir( input )
{
	switch(input)
	{
		case "up":    return 1
		case "right": return 2
		case "down":  return 3
		case "left":  return 4
	}
}

function TranslateDirToText( input )
{
	switch(input)
	{
		case 1: return "up"
		case 2: return "right"
		case 3: return "down"
		case 4: return "left"
	}
}

//------------------------------

function EnableDynamicSpawning()
{
	// printd("ENABLED DYNAMIC SPAWNING")

	if ( !("hDSThink" in this) || !hDSThink )
		hDSThink <- VS.Timer(1, 0.1, Think_DynamicSpawning).weakref()

	VS.EventQueue.AddEvent( DS_SetPlayer, 0, this )
}

function Think_DynamicSpawning()
{
	if( bThirdperson ) HPlayer.SetAngles(89,0,0)
	DS_GetPlayer()
	DS_Process()
}

// find player in nearby cells
function DS_GetPlayer()
{
	for( local i = ds_nearby.len(); i--; )
	{
		local point = ds_nearby[i]

		if( Entities.FindByClassnameNearest("player", point[0][5], 80.0) )
		{
			ds_nCurrX = point[1]
			ds_nCurrY = point[2]

			// printl("Found player at " + ds_nCurrX + "," + ds_nCurrY)
			break
		}
	}
}

function DS_SetPlayer()
{
	if( !(hSpeed <- Entc("player_speedmod")) )
		hSpeed = VS.CreateEntity("player_speedmod",{speed=0}).weakref()

	EntFireByHandle(hSpeed,"modifyspeed","3",0,HPlayer)

	HPlayer.SetOrigin(Vector(c_start.Point()[5].x,c_start.Point()[5].y+CELL_DIST,c_start.Point()[5].z))
	ds_nCurrX = _POS_START_X
	ds_nCurrY = _POS_START_Y

	local pos = HPlayer.EyePosition()
	local prop

	if( !(prop = Entities.FindByModel(null,MDL_PLAYER)) )
		prop = CreateProp("prop_dynamic_override", Vector(pos.x,pos.y,pos.z+20), MDL_PLAYER, 0)
	else prop.SetAbsOrigin(Vector(pos.x,pos.y,pos.z+20))

	VS.SetParent( prop, HPlayer )

	EntFireByHandle(hDSThink,"enable")
}

// list of nearby cells
ds_nearby <- []

// list of cells to remove
ds_remove <- []

// position of the current cell
ds_nCurrX <- -1
ds_nCurrY <- -1

// Search for the player in the radius, spawn props,
// remove props in the outer ring
function DS_Process()
{
	local r = 8
	local rSqr = 64
	local cx = ds_nCurrX
	local cy = ds_nCurrY

	ds_nearby.clear()
	ds_remove.clear()

	// this method isn't perfect with small radii,
	// but it's better than hard coding the cells
	for( local xx = cx - r; xx <= cx + r; ++xx )
		for( local yy = cy - r; yy <= cy + r; ++yy )
		{
			if(xx<1)xx=1;else if(xx>_MAZE_X)break
			if(yy<1)yy=1;else if(yy>_MAZE_Y)break

			local pt = Cell(xx,yy).Point()
			local dx = xx - cx
			local dy = yy - cy
			local d = dx*dx + dy*dy

			if( d < rSqr )
				ds_nearby.append([pt, xx, yy])
			else
				ds_remove.append(pt)
		}

	foreach( i in ds_nearby ) DS_Create(i[0])

	foreach( i in ds_remove ) DS_Remove(i)
}

function DS_Create( input )
{
	if( !input[6] && input[0] != 9 )
		CreateCell( input )
}

function DS_Remove( input )
{
	if( input[6] && input[0] != 9 )
		input[6].Destroy()
}

// inputs --------------------------------------------------------------

::OnGameEvent_player_say <- function(data)
{
	local msg = data.text

	if( msg[0] != '/' ) return

	local buffer = split(msg, " ")
	local val, cmd = buffer[0]

	if( buffer.len() > 1 )
		val = buffer[1]

	switch( cmd.tolower() )
	{
//------------------------------
		case "/size":
			local buffer3 = GetInputXY( val, _MAZE_X, _MAZE_Y )
			if ( !buffer3 ) return
			_MAZE_X = buffer3[0]
			_MAZE_Y = buffer3[1]
			Chat( "Maze is now (" + _MAZE_X +"x" + _MAZE_Y + ")" )
			printl( "Maze is now (" + _MAZE_X +"x" + _MAZE_Y + ")" )
			break

//------------------------------
		case "/entrypos":
			local buffer3 = GetInputXY( val, _POS_START_X, _POS_START_Y )
			if ( !buffer3 ) return
			_POS_START_X = buffer3[0]
			_POS_START_Y = buffer3[1]
			Chat( "Entry position \t: " + _POS_START_X + "," + _POS_START_Y )
			printl( "Entry position \t: " + _POS_START_X + "," + _POS_START_Y )
			break

		case "/entrydir":
			_ENTRYDIR = TranslateTextToDir( val )
			Chat( "Entry direction\t: " + TranslateDirToText(_ENTRYDIR) )
			printl( "Entry direction\t: " + TranslateDirToText(_ENTRYDIR) )
			break

//------------------------------
		case "/exitpos":
			local buffer3 = GetInputXY( val, _POS_EXIT_X, _POS_EXIT_Y )
			if ( !buffer3 ) return
			_POS_EXIT_X = buffer3[0]
			_POS_EXIT_Y = buffer3[1]
			Chat( "Exit position \t: " + _POS_EXIT_X + "," + _POS_EXIT_Y )
			printl( "Exit position \t: " + _POS_EXIT_X + "," + _POS_EXIT_Y )
			break

		case "/exitdir":
			_EXITDIR = TranslateTextToDir( val )
			Chat( "Exit direction \t: " + TranslateDirToText(_EXITDIR) )
			printl( "Exit direction \t: " + TranslateDirToText(_EXITDIR) )
			break

//------------------------------
		case "/create":
			Command_create()
			break

		case "/printdir":
			PrintMaze_dir()
			break

		case "/info":
			PrintVars()
			break

		case "/v2":
			bBreakWalls = !bBreakWalls
			printl( "V2 "+TranslateBoolToText(bBreakWalls) )
			Chat( "V2 "+TranslateBoolToText(bBreakWalls) )
			break

		case "/init":
		case "/reset":
			Init(1)
			break

		case "/findent":
			FindEnt()
			break

		case "/cam":
		case "/tp":
			Command_tp()
			break

		case "/fp":
			Command_fp()
			break

		case "/dyn":
		case "/dynamic":
			bDynamicSpawning = !bDynamicSpawning
			printl("Dynamic spawning "+TranslateBoolToText(bDynamicSpawning))
			Chat("Dynamic spawning "+TranslateBoolToText(bDynamicSpawning))
			break

		default:
			Chat("Invalid command.")
	}
}.bindenv(this)

function StartMazeCreation()
{
	if( !bDynamicSpawning )
		if( CheckForCrash() )
			return

	Init()
	VS.EventQueue.AddEvent( FindNext, 1.0, [this, c_next] )
}

function Command_create()
{
	VS.GetLocalPlayer()
	StripWeapons()
	VS.EventQueue.AddEvent( StartMazeCreation, 0.1, this )
}

function Command_tp()
{
	bThirdperson = true
	HPlayer.SetAngles(0,0,0)

	SendToConsole("cam_collision 0")
	SendToConsole("cam_idealdist 4000")
	SendToConsole("cam_idealpitch 90")
	SendToConsole("cam_idealyaw 0")
	SendToConsole("fov_cs_debug 50")
	SendToConsole("r_farz 3999")
	SendToConsole("thirdperson")
	SendToConsole("thirdperson_mayamode")
}

function Command_fp()
{
	bThirdperson = false
	SendToConsole("r_farz -1")
	SendToConsole("firstperson")
	SendToConsole("fov_cs_debug 0")
}

function GetInputXY( input, ix = 0, iy = 0 )
{
	if( !input )
		return Chat("Invalid input.")

	local buffer2 = split(input, ",")
	local x = ix, y = iy

	if( input[0] == ',')
	{
		try( y = buffer2[0].tointeger() )
		catch(e){ Chat("Invalid input.") }
	}
	else
	{
		try( x = buffer2[0].tointeger() )
		catch(e){ Chat("Invalid input.x") }
		try( y = buffer2[1].tointeger() )
		catch(e){ Chat("Invalid input.y") }
	}

	return [x,y]
}
