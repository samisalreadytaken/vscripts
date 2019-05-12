//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------

function StartMazeCreation()
{
	if( !maze_dynamic_spawning )
		if( !CheckForCrash() )
			return

	EntFireHandle( ENT_SCRIPT, "RunScriptCode", "FindNext(c_next)", 1.0 )
}

function cmd_create()
{
	reset()
	EntFireHandle( ENT_SCRIPT, "RunScriptCode", "StartMazeCreation()", 0.1 )
}

::OnGameEvent_player_say <- function( data )
{
	local msg = data.text

	if( msg.slice(0,1) == "/")
		say_cmd( msg.slice(1).tolower() )
}

function say_cmd( str )
{
	local buffer = split(str, " ")
	local cmd = buffer[0]
	local val
	try( val = buffer[1] )
	catch(e){}

	switch( cmd ){
//------------------------------
		case "size":
			local buffer3 = GetInputXY( val, _MAZE_X, _MAZE_Y )
			if ( !buffer3 ) return
			_MAZE_X = buffer3[0]
			_MAZE_Y = buffer3[1]
			Chat( "Maze is now (" + _MAZE_X +"x" + _MAZE_Y + ")" )
			break

//------------------------------
		case "entrypos":
			local buffer3 = GetInputXY( val, _POS_START_X, _POS_START_Y )
			if ( !buffer3 ) return
			_POS_START_X = buffer3[0]
			_POS_START_Y = buffer3[1]
			Chat( "Entry position \t: " + _POS_START_X + "," + _POS_START_Y )
			break

		case "entrydir":
			_ENTRYDIR = TranslateTextToDir( val )
			Chat( "Entry direction\t: " + TranslateDirToText(_ENTRYDIR) )
			break

//------------------------------
		case "exitpos":
			local buffer3 = GetInputXY( val, _POS_EXIT_X, _POS_EXIT_Y )
			if ( !buffer3 ) return
			_POS_EXIT_X = buffer3[0]
			_POS_EXIT_Y = buffer3[1]
			Chat( "Exit position \t: " + _POS_EXIT_X + "," + _POS_EXIT_Y )
			break

		case "exitdir":
			_EXITDIR = TranslateTextToDir( val )
			Chat( "Exit direction \t: " + TranslateDirToText(_EXITDIR) )
			break

//------------------------------
		case "worldstart":
			// doesnt sanitise the input
			VS.Console.pos_worldstart = Vector( val )
			break

		case "create":
			cmd_create()
			break

		case "cam":
			cmd_cam()
			break

		case "printdir":
			PrintMaze_dir()
			break

		case "info":
			printVars()
			break

		case "v2":
			if( toggle_breakw == 0 )
			{
				Chat("v2 enabled.")
				toggle_breakw = 1
			}
			else if( toggle_breakw = 1 )
			{
				Chat("v2 disabled.")
				toggle_breakw = 0
			}
			break

		case "reset":
			reset()
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

		case "status":
			local buffer3 = GetInputXY( val )
			if ( !buffer3 ) return
			printStatus( buffer3[0], buffer3[1] )
			break

		case "t":

			break

		default:
			Chat("Invalid command.")
	}
}

function cmd_tp()
{
	player.SetAngles(0,0,0)

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

toggle_cam <- 0
function cmd_cam()
{
	if( toggle_cam == 0 )
	{
		EntFire("camera", "Enable", "", 0.1, player)
		SendToConsole("r_drawviewmodel 0");
		SendToConsole("fov_cs_debug 60");
		SendToConsole("r_farz 6299")
		EntFire( "mat_cam", "setmaterialvar", "1", 0.01 )

		toggle_cam = 1
	}
	else
	{
		EntFire("camera", "Disable", "", 0.1, player)
		SendToConsole("r_farz 1800")
		SendToConsole("fov_cs_debug 0")
		EntFire( "mat_cam", "setmaterialvar", "0", 0.01 )

		toggle_cam = 0
	}
}

function GetInputXY ( input, ix = 0, iy = 0 )
{
	if( input == null)
	{
		Chat("Invalid input.")
		return false
	}

	local buffer2 = split(input, ",")
	local x = ix
	local y = iy

	if ( input.slice(0,1) == ",")
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