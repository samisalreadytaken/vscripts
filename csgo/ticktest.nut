//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//------------------------------------------------------------------
//
// This script visualises every tick in the server,
// draws 3 lines back to back when +attack input is sent to the engine
//
// Orange  - tick 0 (+attack)
// Green   - tick 1
// Magenta - tick 2
//
// Reload the script to remove the lines
//
//--------------------------------------
//
// script_execute ticktest
//
// bind mouse1 "script attack();+attack"
//
//------------------------------------------------------------------

//--------------------------------------
// test conditions
SendToConsole("sv_cheats 1;sv_showlagcompensation 1;bot_stop 1;mp_ignore_round_win_conditions 1;mp_freezetime 0;sv_infinite_ammo 1;sv_showimpacts 1;sv_showimpacts_time 7;weapon_accuracy_nospread 1;mp_warmup_end")

SendToConsole("weapon_recoil_view_punch_extra 0;view_recoil_tracking 0")
//--------------------------------------

IncludeScript("vs_library")

VS.GetLocalPlayer()

flFrameTime2 <- FrameTime()*2
TICK <- true

trace0 <- null
trace1 <- null
trace2 <- null

flTimeAttack <- 0.0
fTickrate <- VS.GetTickrate()

local init = function()
{
	if( !("hThink" in this) )
		::hThink <- VS.Timer(0, FrameTime(), "dummy", null,false,true).weakref()

	if( !("hGameText" in this) )
	{
		::hGameText <- VS.CreateEntity("game_text",{
			channel = 1,
			color = Vector(255,255,255),
			holdtime = FrameTime(),
			x = 0.35,
			y = 0.25
		},true).weakref()
		::hGameText2 <- VS.CreateEntity("game_text",{
			channel = 2,
			color = Vector(255,138,0),
			holdtime = FrameTime(),
			x = 0.48,
			y = 0.55
		},true).weakref()
	}

	if( !("HPlayerEye" in this) )
		::HPlayerEye <- VS.CreateMeasure(HPlayer.GetName(),null,true).weakref()
}()

// Think
VS.OnTimer(hThink,function()
{
	TICK = !TICK

	hGameText.__KeyValueFromString("message", TICK ? "⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸\n⎸"
	                                               : "█\n█\n█\n█\n█\n█\n█\n█\n█\n█\n█\n█\n█\n█\n█\n█\n█\n█\n█\n█\n█")
	EntFireByHandle(hGameText,  "display", "", 0, HPlayer)
	EntFireByHandle(hGameText2, "display", "", 0, HPlayer)
	EntFireByHandle(hGameText2, "settext", "", 0, HPlayer)

	if( trace0 )
	{
		// orange
		// player sending the command
		DebugDrawLine(trace0.startpos, trace0.hitpos, 255, 138, 0, true, flFrameTime2)
		DebugDrawBox(trace0.hitpos, Vector(-1,-1,-1), Vector(1,1,1), 255, 138, 0, 127, flFrameTime2)
	}

	if( trace1 )
	{
		// green
		// one tick after +attack
		// impact squares should be visible
		DebugDrawLine(trace1.startpos, trace1.hitpos, 0, 255, 0, true, flFrameTime2)
		DebugDrawBox(trace1.hitpos, Vector(-1,-1,-1), Vector(1,1,1), 0, 255, 0, 127, flFrameTime2)
	}

	if( trace2 )
	{
		// magenta
		// the next tick
		DebugDrawLine(trace2.startpos, trace2.hitpos, 255, 0, 255, true, flFrameTime2)
		DebugDrawBox(trace2.hitpos, Vector(-1,-1,-1), Vector(1,1,1), 255, 0, 255, 127, flFrameTime2)
	}
})

// ORANGE LINE
// called when the player sends the attack input
function attack()
{
	SendToConsole("-attack")

	flTimeAttack = Time()

	trace0 = VS.TraceDir(HPlayer.EyePosition(), HPlayerEye.GetForwardVector())
	trace0.GetPos()

	printl("\n\n@tick 0 : +attack  : " + VecToStringF(trace0.hitpos))

	VS.EventQueue.AddEvent( OnFire, 0, this )
}

// RED LINE
// executed before the Think function, so the message changed here will be displayed
function OnFire()
{
	local tick = (Time()-flTimeAttack)*fTickrate
	Assert( VS.IsInteger(tick) )

	trace1 = VS.TraceDir(HPlayer.EyePosition(), HPlayerEye.GetForwardVector())
	trace1.GetPos()

	printl("@tick " + tick + " : OnFire   : " + VecToStringF(trace1.hitpos))

	hGameText2.__KeyValueFromString("message", "FIRE")

	VS.EventQueue.AddEvent( PostFire, 0, this )
}

// MAGENTA LINE
function PostFire()
{
	local tick = (Time()-flTimeAttack)*fTickrate
	Assert( VS.IsInteger(tick) )

	trace2 = VS.TraceDir(HPlayer.EyePosition(), HPlayerEye.GetForwardVector())
	trace2.GetPos()

	printl("@tick " + tick + " : PostFire : " + VecToStringF(trace2.hitpos))
}

::VecToStringF <- function(vec)
{
	return "Vector(" + VS.FormatPrecision(vec.x,6) + "," + VS.FormatPrecision(vec.y,6) + "," + VS.FormatPrecision(vec.z,6) + ")"
}
