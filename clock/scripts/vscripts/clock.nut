//-----------------------------------------------------------------------
//----------------------- Copyright (C) 2019 Sam ------------------------
//                     github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Valve's Portal countdown timer recreated in vscripts
//
// This is a 1 to 1 recreation with slight adjustments
// especially on how seconds work on displays.
//
// There are probably better ways of creating timer displays.
//
//---------------
//
// Clock.Show()
// Clock.Hide()
//
// Clock.Init()
// Clock.Set( min, sec )
// Clock.Start()
// Clock.Stop()
//
//------------------------------

IncludeScript("vs_library")

::Clock <- {}

function Clock::Init()
{
	if( !("CD" in this) )
	{
		CD <- []
		for( local i = 59; i >= 0; i-- ) CD.append(i)
	}

	VS.CreateTextureToggle( "clock_minutes" )
	VS.CreateTextureToggle( "clock_seconds" )

	if( !Entities.FindByName(null, "timer_clock_seconds") )
	{
		VS.OnTimer( VS.CreateTimer( "timer_clock_seconds", 1,0,0,0,1 ), "TimerSec" )
		VS.OnTimer( VS.CreateTimer( "timer_clock_milliseconds", 0.1,0,0,0,1 ), "TimerMSec" )
		VS.OnTimer( VS.CreateTimer( "timer_clock_target", 1,0,0,0,1 ), "TimerFin" )
	}

	Reset()
}

function Clock::Set( imin, isec = 0 )
{
	Reset()

	bFirst <- true
	bCheck <- isec
	SET <- imin.tointeger()*60+isec.tointeger()
	TG <- SET
	TextureToggle( "clock_minutes", CD[imin.tointeger()] )
	TextureToggle( "clock_seconds", CD[isec.tointeger()] )
	Entities.FindByName(null,"timer_clock_target").__KeyValueFromFloat("refiretime",SET--)

	printl("Setting timer to " + imin + " minutes, " + isec + " seconds.")
}

function Clock::TimerFin()
{
	printl("FIN")

	Disable()
	Reset()
}

function Clock::TimerSec()
{
	if( SET % 60 == 0 )
	{
		TextureToggleIncrement( "clock_minutes" )
		TextureToggle( "clock_seconds", CD[0] )
	}

	SET--
	TextureToggleIncrement( "clock_seconds" )
	MaterialModify( "clock_centiseconds", "startfloatlerp", "0 59 1 0" )
}

function Clock::TimerMSec()
{
	MaterialModify( "clock_milliseconds", "startfloatlerp", "0 9 .1 1" )
}

//------------------------------

function Clock::Stop()
{
	printl("STOP")
	printl((Time()-time_start)+" seconds elapsed.")
	printl((TG-Time()+time_start)+" seconds left.")
	Disable()
}

function Clock::Start()
{
	if(bFirst)
	{
		time_start <- Time()
		if(!bCheck)TextureToggleIncrement( "clock_minutes" )
		TextureToggleIncrement( "clock_seconds" )
		MaterialModify( "clock_centiseconds", "startfloatlerp", "0 59 1 0" )
		MaterialModify( "clock_milliseconds", "startfloatlerp", "0 9 .1 1" )
		bFirst = false
	}

	EntFire( "timer_clock_target", "enable" )
	EntFire( "timer_clock_seconds", "enable" )
	EntFire( "timer_clock_milliseconds", "enable", 0.9 )
}

function Clock::Disable()
{
	EntFire( "timer_clock_target", "disable" )
	EntFire( "timer_clock_seconds", "disable" )
	EntFire( "timer_clock_milliseconds", "disable" )
}

function Clock::Reset()
{
	TextureToggle( "clock_minutes", CD[0] )
	TextureToggle( "clock_seconds", CD[0] )
	MaterialModify( "clock_centiseconds", "setmaterialvar", CD[0] )
	MaterialModify( "clock_milliseconds", "setmaterialvar", 9 )
}

function Clock::Hide()
{
	EntFire( "clock_dots", "disable" )
	EntFire( "clock_minutes", "disable" )
	EntFire( "clock_seconds", "disable" )
	EntFire( "clock_centiseconds", "disable" )
	EntFire( "clock_milliseconds", "disable" )
}

function Clock::Show()
{
	EntFire( "clock_dots", "enable" )
	EntFire( "clock_minutes", "enable" )
	EntFire( "clock_seconds", "enable" )
	EntFire( "clock_centiseconds", "enable" )
	EntFire( "clock_milliseconds", "enable" )
}
