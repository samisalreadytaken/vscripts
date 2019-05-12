//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------

/////////////////////////////////
/////////////////////////////////
/////////////////////////////////
/////////////////////////////////
// cell values
// ["value", "1", "2", "3", "4", "position", "propSpawned"]
//    [0]    [1]  [2]  [3]  [4]     [5]           [6]
/////////////////////////////////
/////////////////////////////////
//   x 1 2 3 4 5 6
// y
// 1   0 0 0 0 0 0
// 2   0 0 0 0 0 0
// 3   0 0 0 0 0 0
// 4   0 0 0 0 0 0
// 5   0 0 0 0 0 0
// 6   0 0 0 0 0 0
//
//////////////////////
//////directions//////
///////// 1 //////////
/////// 4   2 ////////
///////// 3 //////////
//////////////////////
//////////////////////

PrecacheModel(mdl_player)
PrecacheModel(pxl_rev)

PrecacheModel(mdl_o_1)
PrecacheModel(mdl_o_2)
PrecacheModel(mdl_o_3)
PrecacheModel(mdl_o_4)

PrecacheModel(mdl_v_1)
PrecacheModel(mdl_v_2)
PrecacheModel(mdl_v_3)
PrecacheModel(mdl_v_4)

PrecacheModel(mdl_s_h)
PrecacheModel(mdl_s_v)

PrecacheModel(mdl_t_1)
PrecacheModel(mdl_t_2)
PrecacheModel(mdl_t_3)
PrecacheModel(mdl_t_4)

// gameui <- VS.Entity.CreateUI()
VS.GetSoloPlayer()

MAZE_YX <- VS.Console.CreateDisplayArray( _MAZE_X+2,_MAZE_Y+2, 7 )
VS.Console.SetPositions3D( 5, "xy" )

breakwalls_amt <- ceil(sqrt(_MAZE_X * _MAZE_Y) / 5).tointeger()

EXT <- _EXT - _WALL
CELL_DIST <- _WALL * 2 + EXT * 2 + _CELL_SIZE

VS.Console.PXL_DIST <- CELL_DIST

// return vector
function cell(x, y)
{
	return Vector(x,y,MAZE_YX[y][x][0])
}
// x,y input, set value
function cellSet2(x, y, value)
{
	MAZE_YX[y][x][0] = value
}
// vector input, set value
function cellSet(input, value)
{
	cellPoint(input)[0] = value
}
// vector input, return point
function cellPoint(input)
{
	return MAZE_YX[input.y][input.x]
}

isBorder <- 9

function SetBorders()
{
	for( local x = 0; x <= _MAZE_X+1; x++ ) cellSet2(x, 0, isBorder)
	for( local x = 0; x <= _MAZE_X+1; x++ ) cellSet2(x, _MAZE_Y+1, isBorder)
	for( local y = 0; y <= _MAZE_Y+1; y++ ) cellSet2(_MAZE_X+1, y, isBorder)
	for( local y = 0; y <= _MAZE_Y+1; y++ ) cellSet2(0, y, isBorder)
}

SetBorders()

c_start <- cell(_POS_START_X,_POS_START_Y)
c_next <- c_start
cellPoint(c_start)[_ENTRYDIR] = 1
cellPoint(c_start)[0] = 1

c_exit <- cell(_POS_EXIT_X,_POS_EXIT_Y)
cellPoint(c_exit)[_EXITDIR] = 1

toggle_breakw <- 0
d_override <- 0
d_reverse <- 0
m_path <- array(1,0)
c_previous <- null

function FindNext(input)
{
	c_previous = input
	c_next = null
	local dir = 0

	if( d_override == 0 )
	{
		dir = RandomInt(1,4)

		GetNext(dir)
		Check_fwd(dir)
	}
	else if( d_override == 1 )
	{
		TestDir()
	}

	if( IsComplete() )
	{
		OnPostComplete()
		return
	}

	if( DEBUG == 1 )
	{
		PrintMaze()
//		PrintMaze_dir()
		if( fGenDelay != 0.0 )
			EntFireHandle( ENT_SCRIPT, "RunScriptCode", "FindNext(c_next)", fGenDelay )
		else {
			// manual
		}
	}
	else if( DEBUG == 0 )
	{
		EntFireHandle( ENT_SCRIPT, "RunScriptCode", "FindNext(c_next)", fGenDelay )
	}
}

function GetNext(dir)
{
	switch(dir)
	{
		case 1:
			c_next = cell(c_previous.x,c_previous.y-1)
//			printd(" ^  " + dir + "up")
			break
		case 2:
			c_next = cell(c_previous.x+1,c_previous.y)
//			printd(" -> " + dir + "right")
			break
		case 3:
			c_next = cell(c_previous.x,c_previous.y+1)
//			printd(" v  " + dir + "down")
			break
		case 4:
			c_next = cell(c_previous.x-1,c_previous.y)
//			printd(" <- " + dir + "left")
			break
	}
//	printd("next: ["+c_next.x+","+c_next.y+"] = "+cellPoint(c_next)[0]+" | up: "+cellPoint(c_next)[1]+"; right: "+cellPoint(c_next)[2]+"; down: "+cellPoint(c_next)[3]+"; left: "+cellPoint(c_next)[4]+"; pos: "+cellPoint(c_next)[5].x+","+cellPoint(c_next)[5].y+"; ")
}

function TestDir()
{
	local i = 1

	while( i <= 4 )
	{
		GetNext(i)
		if( Check_fwd(i) )
			break
		i++
	}

	if( i == 5 )
	{
		if( DEBUG == 1 )
		{
			printl("STUCK!")
			printl("path: ")
			foreach( k in m_path )
				print(k)
			printl("\n")
		}

		local k = m_path.pop()

		// check here to prevent depleting m_path array
		if( k == 0 ) return

		GetNext( revdir(k) )
		Check_reverse( revdir(k) )
	}
}

function Check_fwd(dir)
{
	if( showprocess && !maze_dynamic_spawning )
		Create_cell(cellPoint(c_previous))

	if( cellPoint(c_next)[0] == 0 )
	{
		cellSet(c_next,1)
		cellPoint(c_next)[revdir(dir)] = 1

		cellPoint(c_previous)[dir] = 1

		m_path.append(dir)

		if( d_override == 1 ) d_override = 0

//		printd("\nNot visited, marked:")
//		printd("      ["+c_next.x+","+c_next.y+"] = "+ cellPoint(c_next)[0] +" | up: "+cellPoint(c_next)[1]+"; right: "+cellPoint(c_next)[2]+"; down: "+cellPoint(c_next)[3]+"; left: "+cellPoint(c_next)[4])
//		printd("")
		return true
	}
	else if( cellPoint(c_next)[0] != 0 )
	{
		c_next = c_previous

		d_override = 1
//		printd("Already visited, re-search from the previous cell \n")

		return false
	}
}

function Check_reverse(dir)
{
	cellSet( c_previous,2 )

	if( showprocess )
		Kreate_cell( cellPoint(c_previous) )

	if( !maze_dynamic_spawning )
		Create_cell( cellPoint(c_previous) )

	if( cellPoint(c_next)[0] == 1 )
	{
		cellSet( c_next,2 )
		cellPoint( c_next )[ revdir(dir) ] = 1

//		printd("Revisited")
	}
	else if( cellPoint(c_next)[0] == 2 )
	{
//		printd("Already revisited.")
	}
	else throw("Something went horribly wrong.")
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

function Create_cell(input)
{
//	printd("Create_cell() input pos: \t"+input[5].x+","+input[5].y+","+input[5].z)

	// kill if prop already exists on the point
	if( showprocess && !maze_dynamic_spawning ) if( input[6] == 1 ) return

	// dead end
	if( input[1] == 1 && input[2] == 0 && input[3] == 0 && input[4] == 0)
		Create_core(input[5], "U")

	else if( input[1] == 0 && input[2] == 1 && input[3] == 0 && input[4] == 0)
		Create_core(input[5], "R")

	else if( input[1] == 0 && input[2] == 0 && input[3] == 1 && input[4] == 0)
		Create_core(input[5], "D")

	else if( input[1] == 0 && input[2] == 0 && input[3] == 0 && input[4] == 1)
		Create_core(input[5], "L")

	// v turn
	else if( input[1] == 1 && input[2] == 1 && input[3] == 0 && input[4] == 0)
		Create_core(input[5], "UR") // 1-2

	else if( input[1] == 1 && input[2] == 0 && input[3] == 0 && input[4] == 1)
		Create_core(input[5], "LU") // 1-4

	else if( input[1] == 0 && input[2] == 1 && input[3] == 1 && input[4] == 0)
		Create_core(input[5], "RD") // 2-3

	else if( input[1] == 0 && input[2] == 0 && input[3] == 1 && input[4] == 1)
		Create_core(input[5], "DL") // 3-4

	// straight
	else if( input[1] == 1 && input[2] == 0 && input[3] == 1 && input[4] == 0)
		Create_core(input[5], "SV") // vertical

	else if( input[1] == 0 && input[2] == 1 && input[3] == 0 && input[4] == 1)
		Create_core(input[5], "SH") // horizontal

	// t junc
	else if( input[1] == 1 && input[2] == 1 && input[3] == 1 && input[4] == 0)
		Create_core(input[5], "URD") // up right down

	else if( input[1] == 0 && input[2] == 1 && input[3] == 1 && input[4] == 1)
		Create_core(input[5], "RDL") // right down left

	else if( input[1] == 1 && input[2] == 0 && input[3] == 1 && input[4] == 1)
		Create_core(input[5], "UDL") // up down left

	else if( input[1] == 1 && input[2] == 1 && input[3] == 0 && input[4] == 1)
		Create_core(input[5], "URL") // up right left

	else if( input[1] == 1 && input[2] == 1 && input[3] == 1 && input[4] == 1){
//		printd("NO CELL, DONT CREATE PROP \t " + input[5].x + " " + input[5].y + " " + input[5].z)
	}
	else
	{
		if( !showprocess )
		{
			printl(input[0]+" | up: "+input[1]+"; right: "+input[2]+"; down: "+input[3]+"; left: "+input[4]+"; pos: "+input[5].x+","+input[5].y+"; ")
			throw("Something went horribly wrong.")
		}
	}

	// marked, already created prop
	input[6] = 1
}

function Create_core(pos, type)
{
	local ent
	switch(type){
//--------------------------------------------------------
		case "UR":
			ent = CreateSolidProp(pos, mdl_v_1)
			break
		case "RD":
			ent = CreateSolidProp(pos, mdl_v_2)
			break
		case "DL":
			ent = CreateSolidProp(pos, mdl_v_3)
			break
		case "LU":
			ent = CreateSolidProp(pos, mdl_v_4)
			break
//--------------------------------------------------------
		case "SH":
			ent = CreateSolidProp(pos, mdl_s_h)
			break
		case "SV":
			ent = CreateSolidProp(pos, mdl_s_v)
			break
//--------------------------------------------------------
		case "U":
			ent = CreateSolidProp(pos, mdl_o_1)
			break
		case "R":
			ent = CreateSolidProp(pos, mdl_o_2)
			break
		case "D":
			ent = CreateSolidProp(pos, mdl_o_3)
			break
		case "L":
			ent = CreateSolidProp(pos, mdl_o_4)
			break
//--------------------------------------------------------
		case "URD":
			ent = CreateSolidProp(pos, mdl_t_1)
			break
		case "RDL":
			ent = CreateSolidProp(pos, mdl_t_2)
			break
		case "UDL":
			ent = CreateSolidProp(pos, mdl_t_3)
			break
		case "URL":
			ent = CreateSolidProp(pos, mdl_t_4)
			break
//--------------------------------------------------------
	}

	// make sure it's solid for the 3rd time
	VS.Entity.SetKey(ent, "solid", 6)
}

function CreateSolidProp(vec, mdl)
{
	local ent = VS.Entity.CreateProp( vec, mdl )
	VS.Entity.SetKey(ent, "solid", 6)
	return ent
}

function GetPropAt(vec)
{
	local ent = Entities.FindByClassnameNearest("prop_*", vec, 1)
	// make sure it's solid, again!
	VS.Entity.SetKey(ent, "solid", 6)
	return ent
}

function BreakRandomWalls()
{
	local rand_x = RandomInt(2, _MAZE_X-1)
	local rand_y = RandomInt(2, _MAZE_Y-1)
	local rand_cell = cell( rand_x, rand_y )
	local rand_point = cellPoint( cell( rand_x, rand_y ) )
	local rand_dir = RandomInt(1,4)

	while( rand_point[ rand_dir ] == 1 )
	{
		if( rand_point[1] == 1 && rand_point[2] == 1 && rand_point[3] == 1 && rand_point[4] == 1 )
		{
		//	printl(" No walls, break the loop... \t" + rand_point[5].x + " " + rand_point[5].y + " " + rand_point[5].z)
			break
		}
			//print(rand_dir)
		rand_dir = RandomInt(1,4)
			//printl(" is already open, checking "+rand_dir)
	}

	rand_point[ rand_dir ] = 1
	GetPropAt( rand_point[5] ).Destroy()
	Create_cell( rand_point )
	c_previous = rand_cell
	GetNext( rand_dir )

	//printl("rand " + c_previous.x + "," + c_previous.y + "\t next " + c_next.x + "," + c_next.y + "\n")

	GetPropAt( cellPoint( c_next )[5] ).Destroy()
	cellPoint( c_next )[ revdir( rand_dir ) ] = 1
	Create_cell( cellPoint( c_next ) )
}

//------------------------------

function IsComplete()
{
	if(m_path.len() == 0)
		return true
	return false
}

function OnPostComplete()
{
	if( showprocess )
		Kreate_cell(cellPoint(c_start))

	if( maze_dynamic_spawning )
		EnableDynamicSpawning()

	else if( !maze_dynamic_spawning )
		Create_cell(cellPoint(c_start))

//	prints("\n MAZE COMPLETE ("+_MAZE_X+"x"+_MAZE_Y+") - " +count)
	Chat("Maze created.")

	if( toggle_breakw )
	{
		local p = 1
		while( p < breakwalls_amt)
		{
		// This is done to prevent overflow issues
			EntFireHandle( ENT_SCRIPT, "RunScriptCode", "BreakRandomWalls()" )
			p++
		}
//		prints(" Broke walls.")
	}
	FindEnt()
}

function PrintMaze()
{
	for(local y = 0; y < _MAZE_Y+2; y++)
	{
		for(local x = 0; x < _MAZE_X+2; x++)
		{
			print(MAZE_YX[y][x][0]+" ")
		}
		print("\n")
	}
}

function PrintMaze_dir()
{
	print("\n");
	for(local y = 1; y < _MAZE_Y+1; y++)
	{
		for(local x = 1; x < _MAZE_X+1; x++)
		{
			print("| "+MAZE_YX[y][x][1]+" "+MAZE_YX[y][x][2]+" "+MAZE_YX[y][x][3]+" "+MAZE_YX[y][x][4]+" | ")
		}
		printl("\n")
	}
}

//------------------------------

function CheckForCrash()
{
	if( maze_dynamic_spawning ) return

	// can't have more than 2000, unfortunately
	if( ( FindEnt() + CalcPropAmt() ) > 2000 )
	{
		CrashWarning()
		return true
	}
	return false
}

function CrashWarning()
{
	printl("\t ! WARNING !")
	printl(" The maze is too large to be created.")
	Chat(txt.red + " ! WARNING !")
	Chat(txt.red +"The maze is too large to be created.")
}

function CalcPropAmt()
{
	return ( _MAZE_X * _MAZE_Y )
}

list_ent <- []
list_prop <- []

function FindEnt()
{
	local ent, i = 0
	list_ent.clear()
	list_prop.clear()

	while( ent = Entities.Next(ent) )
	{
		i++
		list_ent.append( ent )
		if(ent.GetClassname().slice(0,4) == "prop")
			list_prop.append(ent)
	}
//	printd("Total entity count: " + list_ent.len() )
//	printd("Total prop   count: " + list_prop.len() )

	return list_ent.len()
}

//------------------------------

function reset()
{
	MAZE_YX <- VS.Console.CreateDisplayArray(_MAZE_X+2,_MAZE_Y+2, 7)
	VS.Console.SetPositions3D(5, "xy")
	SetBorders()

	breakwalls_amt <- ceil(sqrt(_MAZE_X * _MAZE_Y) / 5).tointeger()

	c_start <- cell(_POS_START_X,_POS_START_Y)
	c_next <- c_start
	c_exit <- cell(_POS_EXIT_X,_POS_EXIT_Y)

	cellPoint(c_start)[_ENTRYDIR] = 1
	cellPoint(c_start)[0] = 1
	cellPoint(c_exit)[_EXITDIR] = 1

	d_override <- 0
	d_reverse <- 0
	m_path <- array(1,0)
	c_previous <- null

	FindEnt()

	foreach( ent in list_prop ) ent.Destroy()

	list_ent.clear()
	list_prop.clear()

	Chat("Maze reset and updated.")

	return true
}

function printVars()
{
	print("\n")
	printl( "Maze size \t: " + _MAZE_X + "x" + _MAZE_Y )
	printl( "v2 status \t: " + TranslateBoolToText(toggle_breakw) )
	printl( "Entry position \t: " + _POS_START_X + "," + _POS_START_Y )
	printl( "Entry direction\t: " + TranslateDirToText(_ENTRYDIR) )
	printl( "Exit position \t: " + _POS_EXIT_X + "," + _POS_EXIT_Y )
	printl( "Exit direction \t: " + TranslateDirToText(_EXITDIR) )
	printl( "worldstart pos \t: " + VS.Console.pos_worldstart.x + "," + VS.Console.pos_worldstart.y + "," + VS.Console.pos_worldstart.z)
	printl(" ----")
	FindEnt()
	printl("Total entity count: " + (list_ent.len() - list_prop.len()) + " (excluding props)")
	printl("Total prop   count: " + list_prop.len() )
	print("\n")

	Chat( "Maze size : "+ txt.yellow + _MAZE_X + "x" + _MAZE_Y )
	Chat( "v2 status : "+ txt.yellow + TranslateBoolToText(toggle_breakw) )
	Chat( "Entry position : "+ txt.yellow + _POS_START_X + "," + _POS_START_Y )
	Chat( "Entry direction: "+ txt.yellow + TranslateDirToText(_ENTRYDIR) )
	Chat( "Exit position : "+ txt.yellow + _POS_EXIT_X + "," + _POS_EXIT_Y )
	Chat( "Exit direction : "+ txt.yellow + TranslateDirToText(_EXITDIR) )
}

function TranslateBoolToText( input )
{
	if( input )
		return txt.lightgreen+"enabled"
	else if( input )
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

function Kreate_cell(input)
{
	GetPropAt( input[5] ).Destroy()
	VS.Console.CreatePixel( input[5], pxl_rev )
	input[6] = 1
}

//------------------------------

function EnableDynamicSpawning()
{
//	printd("ENABLED DYNAMIC SPAWNING")

	DS_SetPlayer()

	VS.Entity.OnTimer( VS.Entity.CreateTimer( "think_dyn_spwn", 0.1, 0, 0, 0, 0 ), "Think_DynamicSpawning", this )
}

function Think_DynamicSpawning()
{
	DS_GetPlayer()
	DS_Process()
}

// find player in nearby cells
function DS_GetPlayer()
{
	for( local i = 0; i < ds_nearby.len(); i++ )
	{
		local point = ds_nearby[i]

		if( Entities.FindByClassnameNearest( "player" , point[0][5], 80 ) != null )
		{
			// [x, y]
			ds_currnt = [point[1], point[2]]

			//printl("Found player at " + ds_currnt[0] + "," + ds_currnt[1])
			break
		}
	}
}

// the code isn't complete
// it cannot spawn the border cells
// that's why the player is spawned in the middle for now
// will fix later
function DS_SetPlayer()
{
	//HPlayer.SetOrigin( cellPoint(cell(_POS_START_X,_POS_START_Y))[5] )
	HPlayer.SetOrigin( cellPoint(cell(75,75))[5] )

	//ds_currnt = [_POS_START_X,_POS_START_Y]
	ds_currnt = [75,75]

	local pos = HPlayer.EyePosition()
	local prop = VS.Entity.CreateProp( Vector(pos.x,pos.y,pos.z+20), mdl_player )

	VS.Entity.SetParent( prop, HPlayer )
}

// list of nearby cells
ds_nearby <- []

// list of cells to kill
ds_delete <- []

// position of the current cell
ds_currnt <- [-1,-1]

function DS_Process()
{
	local r = 5
	local cx = ds_currnt[0]
	local cy = ds_currnt[1]

	ds_nearby.clear()
	ds_delete.clear()

	// this method isn't perfect with small radii,
	// but it's better than hard coding the cells
	for( local xx = cx - r; xx <= cx + r; xx++ )
	{
		for( local yy = cy - r; yy <= cy + r; yy++ )
		{
			local point = cellPoint(cell(xx,yy))
			local dx = xx - cx
			local dy = yy - cy
			local d = sqrt( dx*dx + dy*dy )

			if( d < r )
				ds_nearby.append([point, xx, yy])
			else
				ds_delete.append(point)
		}
	}

	foreach( i in ds_nearby )
		DS_Create(i[0])

	foreach( i in ds_delete )
		DS_Delete(i)
}

function DS_Create( input )
{
	if( input[6] == 0 && input[0] != 9 )
		Create_cell( input )
}

function DS_Delete( input )
{
	if( input[6] == 1 && input[0] != 9 )
	{
		try(GetPropAt(input[5]).Destroy())
		catch(e){}
		input[6] = 0
	}
}