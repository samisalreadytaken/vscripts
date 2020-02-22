//-----------------------------------------------------------------------
//
// github.com/samisalreadytaken
//
// https://www.youtube.com/watch?v=lycpeJ7Pcp8&t=4m24s
//
//-----------------------------------------------------------------------

IncludeScript("vs_library")

function OnPostSpawn()
{
	fSpeed <- 0.1
	fIncrement <- 0.01

	fIncrementInterval <- 0.1

	// de_cache
	vStartPos <- Vector(3236.45,-26.97,1677.09)
	fStartAngYaw <- 180

	VS.GetLocalPlayer()

	if( !(hThink <- Ent("gamethink")) )
		hThink <- VS.CreateTimer( "gamethink", FrameTime(), 0,0,0, 1 )

	if( !(hIncr <- Ent("incrementer")) )
		hIncr <- VS.CreateTimer( "incrementer", fIncrementInterval, 0,0,0, 1 )

	if( !(hSpeed <- Ent("speed")) )
		hSpeed <- VS.CreateEntity("player_speedmod","speed",{speed=0})

	VS.OnTimer( hThink, "Think" )
	VS.OnTimer( hIncr, "IncrementSpeed" )
	EntFireByHandle( hIncr, "refiretime", fIncrementInterval )

	EntFireByHandle( hThink, "disable" )
	EntFireByHandle( hIncr, "disable" )

	HPlayerEye <- VS.CreateMeasure("player")

	// SendToConsole("-forward;sv_noclipspeed "+fSpeed)
	SendToConsole("-forward")
}

function IncrementSpeed()
{
	fSpeed += fIncrement

	// SendToConsole("sv_noclipspeed "+fSpeed)

	EntFireByHandle( hSpeed, "modifyspeed", fSpeed, 0.0, HPlayer )
}

function Start()
{
	fSpeed = 0.1

	HPlayer.SetOrigin(vStartPos)
	HPlayer.SetAngles(0,vStartAngYaw,0)
	VS.SetKeyInt( HPlayer, "movetype", 8 )
	EntFireByHandle( hSpeed, "modifyspeed", fSpeed, 0.0, HPlayer )

	HPlayer.EmitSound("UI.CounterBeep")
	Alert("Starting in 3...")
	delay("Alert(\"Starting in 2...\");HPlayer.EmitSound(\"UI.CounterBeep\")", 1)
	delay("Alert(\"Starting in 1...\");HPlayer.EmitSound(\"UI.CounterBeep\")", 2)
	delay("Alert(\"Start!\");_Start();HPlayer.EmitSound(\"UI.CounterBeep\")", 3)
}

function _Start()
{
	SendToConsole("+forward")

	EntFireByHandle( hThink, "enable" )
	EntFireByHandle( hIncr, "enable" )
}

function Stop()
{
	SendToConsole("-forward")
	HPlayer.SetVelocity(Vector())
	EntFireByHandle( hThink, "disable" )
	EntFireByHandle( hIncr, "disable" )
	EntFireByHandle( hSpeed, "modifyspeed", 1, 0.0, HPlayer )
	HPlayer.EmitSound("UI.ArmsRace.Demoted")
}

function Think()
{
	local e = HPlayer.EyePosition()

	local t = VS.TraceDir( e, HPlayerEye.GetForwardVector() )

	local a = t.GetPos()

	local d = t.GetDist()

	// DebugDrawBox( a, Vector(-2,-2,-2), Vector(2,2,2), 255, 255, 255, 128, 0.1 )

	if( d <= 17 )
	{
		Chat( txt.red + "Hit a wall!" )
		Alert( "Hit a wall!" )
		DebugDrawBox( a, Vector(-2,-2,-2), Vector(2,2,2), 255, 100, 100, 255, 5.0 )
		Stop()
	}
}

OnPostSpawn()
