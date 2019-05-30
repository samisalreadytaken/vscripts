//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------

::OnGameEvent_player_say <- function( data )
{
	local msg = data.text

	if( msg.slice(0,1) != "/") return

	SMain.say_cmd( msg.slice(1).tolower() )
}

function say_cmd( str )
{
	local buffer = split(str, " ")
	local val, cmd = buffer[0]
	try( val = buffer[1] ) catch(e){}

	switch( cmd ){
//------------------------------
		case "size":
			local buffer3 = GetInputXY( val, _MAZE_X, _MAZE_Y )
			if ( !buffer3 ) return
			_MAZE_X = buffer3[0]
			_MAZE_Y = buffer3[1]
			Chat( "Maze is now (" + _MAZE_X +"x" + _MAZE_Y + ")" )
			printl( "Maze is now (" + _MAZE_X +"x" + _MAZE_Y + ")" )
			break

//------------------------------
		case "entrypos":
			local buffer3 = GetInputXY( val, _POS_START_X, _POS_START_Y )
			if ( !buffer3 ) return
			_POS_START_X = buffer3[0]
			_POS_START_Y = buffer3[1]
			Chat( "Entry position \t: " + _POS_START_X + "," + _POS_START_Y )
			printl( "Entry position \t: " + _POS_START_X + "," + _POS_START_Y )
			break

		case "entrydir":
			_ENTRYDIR = TranslateTextToDir( val )
			Chat( "Entry direction\t: " + TranslateDirToText(_ENTRYDIR) )
			printl( "Entry direction\t: " + TranslateDirToText(_ENTRYDIR) )
			break

//------------------------------
		case "exitpos":
			local buffer3 = GetInputXY( val, _POS_EXIT_X, _POS_EXIT_Y )
			if ( !buffer3 ) return
			_POS_EXIT_X = buffer3[0]
			_POS_EXIT_Y = buffer3[1]
			Chat( "Exit position \t: " + _POS_EXIT_X + "," + _POS_EXIT_Y )
			printl( "Exit position \t: " + _POS_EXIT_X + "," + _POS_EXIT_Y )
			break

		case "exitdir":
			_EXITDIR = TranslateTextToDir( val )
			Chat( "Exit direction \t: " + TranslateDirToText(_EXITDIR) )
			printl( "Exit direction \t: " + TranslateDirToText(_EXITDIR) )
			break

//------------------------------
		case "create":
			cmd_create()
			break

		case "printdir":
			PrintMaze_dir()
			break

		case "info":
			printVars()
			break

		case "v2":
			toggle_breakw != toggle_breakw
			printl( "V2 "+TranslateBoolToText(toggle_breakw) )
			Chat( "V2 "+TranslateBoolToText(toggle_breakw) )
			break

		case "init":
		case "reset":
			Init(1)
			break

		case "findent":
			FindEnt()
			break

		case "tp":
			cmd_tp()
			break

		case "fp":
			cmd_fp()
			break

		case "dyn":
		case "dynamic":
			maze_dynamic_spawning = !maze_dynamic_spawning
			printl("Dynamic spawning "+TranslateBoolToText(maze_dynamic_spawning))
			Chat("Dynamic spawning "+TranslateBoolToText(maze_dynamic_spawning))
			break

		default:
			Chat("Invalid command.")
	}
}

function StartMazeCreation()
{
	if( !maze_dynamic_spawning )
		if( CheckForCrash() )
			return

	Init()
	delay( "FindNext(c_next)", 1.0 )
}

function cmd_create()
{
	VS.GetSoloPlayer()
	delay( "StartMazeCreation()", 0.1 )
}

function cmd_tp()
{
	HPlayer.SetAngles(0,0,0)

	SendToConsole("cam_collision 0")
	SendToConsole("cam_idealdist 4000")
	SendToConsole("cam_idealpitch 90")
	SendToConsole("cam_idealyaw 0")
	SendToConsole("fov_cs_debug 100")
	SendToConsole("r_farz 3999")
	SendToConsole("thirdperson")
	SendToConsole("thirdperson_mayamode")
}

function cmd_fp()
{
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

	if( input.slice(0,1) == ",")
	{
		try( y = buffer2[0].tointeger() )
		catch(e){Chat("Invalid input.")}
	}
	else
	{
		try( x = buffer2[0].tointeger() )
		catch(e){Chat("Invalid input.x")}
		try( y = buffer2[1].tointeger() )
		catch(e){Chat("Invalid input.y")}
	}

	return [x, y]
}
