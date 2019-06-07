//-----------------------------------------------------------------------
//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
//                     github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Testing decals in CS:GO
//  	https://www.youtube.com/watch?v=rIXsA9flaX0
//
//
// Place this file in:
//  	/scripts/vscripts/
// Type in the console to load the script:
//  	script_execute decaltest
// Start to shoot 2048 shots in a row.
// Use < host_timescale > to speed it up.
//
// Chat commands:
//  	start
//
//  	break
//
//  	view
//
//  	add
//
//  	res <X>,<Y>
//
//  	offset <value>
//
//  	shots
//
// Console commands:
//  	script Start()
//
//  	script Break()
//
//  	script View()
//
//  	script Add()
//
//  	script res.x = <value>
//
//  	script res.y = <value>
//
//  	script offset = <value>
//
//------------------------------
IncludeScript("vs_library/vs_include")

// amount of shots to fire = x * y
// x : horizontal
// y : vertical
res <- { x = 64, y = 32 }

// Distance between 2 shots, Hammer Units
offset <- 4

pos_start <- Vector(-1524, 1535, 81)

//------------------------------

VS.GetSoloPlayer()

SendToConsole("mp_warmup_end;mp_freezetime 0;mp_ignore_round_win_conditions 1;sv_infinite_ammo 1;cl_drawhud_force_radar -1;r_cleardecals")

lasermode(1)

//------------------------------

impactCount <- 0
loopCount <- 0
lastpos <- Vector()
res.m <- res.x*res.y

BREAK <- true
delay( "::BREAK <- false", 0.3 )

// Timer to keep the player looking down
function SetAngles(){HPlayer.SetAngles(89,90,0)}
if(!Entities.FindByName(null,"timer_angles"))
	VS.Timer.OnTimer( VS.Timer.Create( "timer_angles", 0.001, 0, 0, 0, 1 ), "SetAngles", this )

function SetPos( vec )
{
	HPlayer.SetOrigin( vec )
	HPlayer.SetAngles( 89, 90, 0 )
	lastpos = vec
}

function Attack()
{
	delay( "SendToConsole(\"+attack\")", 0.0 )
	delay( "SendToConsole(\"-attack\")", 0.002 )
}

function Add()
{
	local new

	if( impactCount && impactCount % res.x == 0 ) // newline
		new = Vector( lastpos.x - ((res.x-1) * offset), lastpos.y - offset, lastpos.z )
	else
		new = Vector( lastpos.x + offset, lastpos.y, lastpos.z )

	SetPos(new)
	Attack()
}

function loop()
{
	if( BREAK ) return

	if( impactCount == res.m )
	{
		Chat(impactCount + " shots fired.")
		return Break()
	}

	if( loopCount != impactCount )
	{
		Attack()
		return delay( "loop()", 0.3 )
	}

	loopCount++
	Add()
	delay( "loop()", 0.3 )
}

function View()
{
	if( !HPlayer.IsNoclipping() ) SendToConsole("noclip")
	HPlayer.SetOrigin( Vector((pos_start.x + offset * (res.x/2)),(pos_start.y - offset * (res.y/2)),740) ) // 2626
	HPlayer.SetAngles( 89, 90, 0 )
}

function Break()
{
	BREAK = 1
	EntFire( "timer_angles", "Disable" )
}

function Start()
{
	if( !HPlayer.IsNoclipping() ) SendToConsole("noclip")
	SetPos( pos_start )
	BREAK = 0
	EntFire( "timer_angles", "Enable" )
	delay( "loop()", 0.1 )
}

//------------------------------

::OnGameEvent_bullet_impact <- function( data )
{
	impactCount++
}

::OnGameEvent_player_say <- function( data )
{
	local msg = data.text

	say_cmd( msg )
}

function say_cmd( msg )
{
	local buffer = split( msg, " " )
	local val, cmd = buffer[0]
	try( val = buffer[1] ) catch(e){}

	switch( cmd.tolower() )
	{
		case "res":
			local xy = GetInputXY(val)
			res.x = xy[0].tointeger()
			res.y = xy[1].tointeger()
			res.m = res.x*res.y
			break

		case "offset":
			offset = val.tofloat()
			break

		case "loop":
		case "start":
			Start()
			break

		case "next":
		case "add":
			Add()
			break

		case "stop":
		case "break":
			Break()
			break

		case "view":
			View()
			break

		case "decals":
		case "decal":
		case "impact":
		case "shot":
		case "shots":
			Chat(impactCount + " shots fired.")
			printl(impactCount + " shots fired.")
			break

		default:
	}
}

function GetInputXY( input, ix = 0, iy = 0 )
{
	if( !input )
	{
		Chat("Invalid input.")
		return null
	}

	local buffer2 = split(input, ",")
	local x = ix, y = iy

	if( input.slice(0,1) == ",")
	{
		try( y = buffer2[0].tofloat() )
		catch(e){Chat("Invalid input.")}
	}
	else
	{
		try( x = buffer2[0].tofloat() )
		catch(e){Chat("Invalid input.x")}
		try( y = buffer2[1].tofloat() )
		catch(e){Chat("Invalid input.y")}
	}

	return [x, y]
}
