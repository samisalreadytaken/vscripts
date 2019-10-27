//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
//------------------------------
//
// cell values
// ["value", "1", "2", "3", "4", "position", "propSpawned"]
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

function StripWeapons()
{
	if(!Entities.FindByName(null,"strip")) VS.Entity.Create("game_player_equip","strip",{spawnflags=2})
	EntFire( "strip", "use", "", 0.0, HPlayer )
}

VS.GetSoloPlayer()
StripWeapons()

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

function Init(i=0)
{
	MAZE_YX = VS.Console.CreateArray2D(_MAZE_X+2,_MAZE_Y+2, 6)

	SetPositions( pos_worldstart, CELL_DIST, 5, "xy" )
	SetBorders()

	breakwalls_amt = ceil(sqrt(_MAZE_X * _MAZE_Y) / 5).tointeger()

	c_start = cell(_POS_START_X,_POS_START_Y)
	c_exit = cell(_POS_EXIT_X,_POS_EXIT_Y)
	c_next = c_start
	c_previous = null

	c_start.point()[0] = 1
	c_start.point()[_ENTRYDIR] = 1
	c_exit.point()[_EXITDIR] = 1

	d_override = 0
	d_reverse = 0
	m_path = array(1,0)

	FindEnt()
	foreach( ent in list_prop ) ent.Destroy()
	list_ent.clear()
	list_prop.clear()

	if(i)Chat("Maze reset and updated.")
}

class cell
{
	constructor(x,y)
	{
		this.x = x
		this.y = y
	}

	x=-1
	y=-1

	function point()
	{
		return SMain.MAZE_YX[y][x]
	}

	function set(val)
	{
		point()[0] = val
	}
}

function SetPositions( worldstart, distance, idx, plane = "yz" )
{
	if(typeof worldstart != "Vector") throw "Invalid input type '"+typeof(worldstart)+"' ; expected 'Vector'"

	local vec = Vector()
	local X = _MAZE_X+2

	for( local y = 0; y < _MAZE_Y+2; y++ )
	{
		vec.x = worldstart.x
		vec.y = worldstart.y
		vec.z = worldstart.z

		if( plane.tolower() == "yz" )      vec.z -= distance * y
		else if( plane.tolower() == "xy" ) vec.y -= distance * y
		else throw "Invalid plane type! "+plane

		for( local x = 0; x < _MAZE_X+2; x++ )
		{
			local pt = MAZE_YX[y][x]
			vec.x += distance

			pt[idx]   = Vector()
			pt[idx].x = vec.x
			pt[idx].y = vec.y
			pt[idx].z = vec.z
		}
	}
}

// border value = 9
function SetBorders()
{
	for( local x = 0; x <= _MAZE_X+1; x++ ) MAZE_YX[0][x][0] = 9
	for( local x = 0; x <= _MAZE_X+1; x++ ) MAZE_YX[_MAZE_Y+1][x][0] = 9
	for( local y = 0; y <= _MAZE_Y+1; y++ ) MAZE_YX[y][_MAZE_X+1][0] = 9
	for( local y = 0; y <= _MAZE_Y+1; y++ ) MAZE_YX[y][0][0] = 9
}

function FindNext(input)
{
	c_previous = input
	c_next = null

	if( d_override == 0 )
	{
		local dir = RandomInt(1,4)

		GetNext(dir)
		Check_fwd(dir)
	}
	else if( d_override == 1 )
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
			delay( "FindNext(c_next)", fGenDelay )
		else {
			// manual
		}
	}
	else delay( "FindNext(c_next)", fGenDelay )
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
	// PrintCell(c_next)
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
		if(DEBUG)
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
	if( c_next.point()[0] == 0 )
	{
		c_next.set(1)
		c_next.point()[revdir(dir)] = 1

		c_previous.point()[dir] = 1

		m_path.append(dir)

		if( d_override == 1 ) d_override = 0

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
		c_next = c_previous

		d_override = 1
		// printd("Already visited, re-search from the previous cell \n")

		return false
	}
}

function Check_reverse(dir)
{
	c_previous.set(2)

	if( !maze_dynamic_spawning )
		Create_cell( c_previous.point() )

	if( c_next.point()[0] == 1 )
	{
		c_next.set(2)
		c_next.point()[ revdir(dir) ] = 1

		// printd("Revisited")
	}
	else if( c_next.point()[0] == 2 )
	{
		// printd("Already revisited.")
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
	// printd("Create_cell() input pos: \t"+input[5].x+","+input[5].y+","+input[5].z)

	// kill if prop already exists on the point
	if( !maze_dynamic_spawning ) if( input[6] == 1 ) return

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
		// printd("NO CELL, DONT CREATE PROP \t " + input[5].x + " " + input[5].y + " " + input[5].z)
	}
	else
	{
		printl(input[0]+" | up: "+input[1]+"; right: "+input[2]+"; down: "+input[3]+"; left: "+input[4]+"; pos: "+input[5].x+","+input[5].y+"; ")
		throw("Something went horribly wrong.")
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

// An better method would be spawning
// as many props that can be seen at once, all types
// then moving them to create the maze.
// This would save resources, and be better for performance.
function CreateSolidProp(vec, mdl)
{
	local ent = VS.CreateProp( vec, mdl )
	VS.Entity.SetKeyInt(ent, "solid", 6)
	return ent
}

function GetPropAt(vec)
{
	local ent = Entities.FindByClassnameNearest("prop_*", vec, 1)
	// make sure it's solid, again!
	VS.Entity.SetKeyInt(ent, "solid", 6)
	return ent
}

function BreakRandomWalls()
{
	local rand_x = RandomInt(2, _MAZE_X-1)
	local rand_y = RandomInt(2, _MAZE_Y-1)
	local rand_cell = cell( rand_x, rand_y )
	local rand_point = rand_cell.point()
	local rand_dir = RandomInt(1,4)

	while( rand_point[ rand_dir ] == 1 )
	{
		if( rand_point[1] == 1 && rand_point[2] == 1 && rand_point[3] == 1 && rand_point[4] == 1 )
		{
			// printl(" No walls, break the loop... \t" + rand_point[5].x + " " + rand_point[5].y + " " + rand_point[5].z)
			break
		}
		// print(rand_dir)
		rand_dir = RandomInt(1,4)
		// printl(" is already open, checking "+rand_dir)
	}

	rand_point[ rand_dir ] = 1
	GetPropAt( rand_point[5] ).Destroy()
	Create_cell( rand_point )
	c_previous = rand_cell
	GetNext( rand_dir )

	// printl("rand " + c_previous.x + "," + c_previous.y + "\t next " + c_next.x + "," + c_next.y + "\n")

	GetPropAt( c_next.point()[5] ).Destroy()
	c_next.point()[ revdir( rand_dir ) ] = 1
	Create_cell( c_next.point() )
}

function PrintCell(input)
{
	printl("      ["+input.x+","+input.y+"] = "+ input.point()[0] +" | up: "+input.point()[1]+"; right: "+input.point()[2]+"; down: "+input.point()[3]+"; left: "+input.point()[4])
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
	if( maze_dynamic_spawning )
		EnableDynamicSpawning()

	else if( !maze_dynamic_spawning )
		Create_cell(c_start.point())

	// prints("\n MAZE COMPLETE ("+_MAZE_X+"x"+_MAZE_Y+") - " +count)
	Chat("Maze created.")

	if( toggle_breakw )
	{
		local p = 1
		while( p < breakwalls_amt)
		{
			// This is done to prevent overflow issues
			delay("BreakRandomWalls()")
			p++
		}
		// prints(" Broke walls.")
	}
	FindEnt()

	HPlayer.SetOrigin(Vector(c_start.point()[5].x,c_start.point()[5].y+CELL_DIST,c_start.point()[5].z))
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
	print("\n")
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
	// printd("Total entity count: " + list_ent.len() )
	// printd("Total prop   count: " + list_prop.len() )

	return list_ent.len()
}

//------------------------------

function printVars()
{
	print("\n")
	printl( "Maze size       : " + _MAZE_X + "x" + _MAZE_Y )
	printl( "V2 status       : " + TranslateBoolToText(toggle_breakw) )
	printl( "Entry position  : " + _POS_START_X + "," + _POS_START_Y )
	printl( "Entry direction : " + TranslateDirToText(_ENTRYDIR) )
	printl( "Exit position   : " + _POS_EXIT_X + "," + _POS_EXIT_Y )
	printl( "Exit direction  : " + TranslateDirToText(_EXITDIR) )
	printl( "worldstart pos  : " + pos_worldstart.x + "," +pos_worldstart.y + "," + pos_worldstart.z)
	printl( "Dynamic spawning: " + TranslateBoolToText(maze_dynamic_spawning) )
	printl(" ----")
	FindEnt()
	printl("Total entity count: " + (list_ent.len() - list_prop.len()) + " (excluding props)")
	printl("Total prop   count: " + list_prop.len() )
	print("\n")

	Chat( "Maze size: "+ txt.yellow + _MAZE_X + "x" + _MAZE_Y )
	Chat( "V2 status: "+ txt.yellow + TranslateBoolToText(toggle_breakw) )
	Chat( "Entry position: "+ txt.yellow + _POS_START_X + "," + _POS_START_Y )
	Chat( "Entry direction: "+ txt.yellow + TranslateDirToText(_ENTRYDIR) )
	Chat( "Exit position: "+ txt.yellow + _POS_EXIT_X + "," + _POS_EXIT_Y )
	Chat( "Exit direction: "+ txt.yellow + TranslateDirToText(_EXITDIR) )
	Chat( "Dynamic spawning: " + TranslateBoolToText(maze_dynamic_spawning) )
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

	delay( "DS_SetPlayer()" )

	VS.OnTimer( VS.CreateTimer( "think_dyn_spwn", 0.1 ), "Think_DynamicSpawning" )
}

function Think_DynamicSpawning()
{
	if( bTP ) HPlayer.SetAngles(89,0,0)
	DS_GetPlayer()
	DS_Process()
}

// find player in nearby cells
function DS_GetPlayer()
{
	for( local i = 0; i < ds_nearby.len(); i++ )
	{
		local point = ds_nearby[i]

		if( Entities.FindByClassnameNearest( "player" , point[0][5], 80 ) )
		{
			// [x, y]
			ds_currnt = [point[1], point[2]]

			// printl("Found player at " + ds_currnt[0] + "," + ds_currnt[1])
			break
		}
	}
}

function DS_SetPlayer()
{
	EntFireHandle(VS.Entity.Create("player_speedmod",null,{speed=0}),"modifyspeed","3",0,HPlayer)

	HPlayer.SetOrigin(Vector(c_start.point()[5].x,c_start.point()[5].y+CELL_DIST,c_start.point()[5].z))
	ds_currnt = [_POS_START_X,_POS_START_Y]

	local pos = HPlayer.EyePosition()
	local prop = VS.CreateProp( Vector(pos.x,pos.y,pos.z+20), mdl_player )

	VS.SetParent( prop, HPlayer )
}

// list of nearby cells
ds_nearby <- []

// list of cells to kill
ds_delete <- []

// position of the current cell
ds_currnt <- [-1,-1]

function DS_Process()
{
	local r = 8
	local cx = ds_currnt[0]
	local cy = ds_currnt[1]

	ds_nearby.clear()
	ds_delete.clear()

	// this method isn't perfect with small radii,
	// but it's better than hard coding the cells
	for( local xx = cx - r; xx <= cx + r; xx++ ) for( local yy = cy - r; yy <= cy + r; yy++ )
	{
		if(xx<1)xx=1;else if(xx>_MAZE_X)break
		if(yy<1)yy=1;else if(yy>_MAZE_Y)break

		local point = cell(xx,yy).point()
		local dx = xx - cx
		local dy = yy - cy
		local d = sqrt( dx*dx + dy*dy )

		if( d < r )
			ds_nearby.append([point, xx, yy])
		else
			ds_delete.append(point)
	}

	foreach( i in ds_nearby ) DS_Create(i[0])

	foreach( i in ds_delete ) DS_Delete(i)
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
		try(GetPropAt(input[5]).Destroy())catch(e){}
		input[6] = 0
	}
}
