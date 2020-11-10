//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Testing decals in CS:GO
//  	https://www.youtube.com/watch?v=xyMLJQB5nYs
//
// Needs a map with bullet_impact event listener to count hits server side
//
// Load the script:
//  	script_execute decaltest
// Start to shoot 2048 shots in a row.
// Use <host_timescale> to speed it up.
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
IncludeScript("vs_library")

// amount of shots to fire = x * y
// x : horizontal
// y : vertical
res <- { x = 64, y = 32 }

// Distance between 2 shots
offset <- 4

pos_start <- Vector(-1524, 1535, 81)

//------------------------------

VS.GetLocalPlayer()

SendToConsole("mp_warmup_end;mp_freezetime 0;mp_ignore_round_win_conditions 1;sv_infinite_ammo 1;r_cleardecals")

//------------------------------

impactCount <- 0
loopCount <- 0
lastpos <- Vector()
res.m <- res.x*res.y

BREAK <- true
VS.EventQueue.AddEvent( function(){ BREAK = false }, 0.3 )

// Timer to keep the player looking down
if( !("hTimer" in this) )
	hTimer <- VS.Timer(1, FrameTime(), "HPlayer.SetAngles(89,90,0)").weakref()

function SetPos(vec)
{
	HPlayer.SetOrigin(vec)
	HPlayer.SetAngles(89,90,0)
	lastpos = vec
}

local param_attack0 = [null, "+attack"]
local param_attack1 = [null, "-attack"]

function Attack() : (param_attack0, param_attack1)
{
	VS.EventQueue.AddEvent( SendToConsole, 0.0, param_attack0 )
	VS.EventQueue.AddEvent( SendToConsole, 0.002, param_attack1 )
}

function Add()
{
	local new

	if( impactCount && impactCount % res.x == 0 ) // newline
		new = Vector(lastpos.x - ((res.x-1) * offset), lastpos.y - offset, lastpos.z)
	else
		new = Vector(lastpos.x + offset, lastpos.y, lastpos.z)

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
		return VS.EventQueue.AddEvent( loop, 0.3, this )
	}

	loopCount++
	Add()
	VS.EventQueue.AddEvent( loop, 0.3, this )
}

function View()
{
	HPlayer.__KeyValueFromInt("movetype",8)
	HPlayer.SetOrigin(Vector((pos_start.x + offset * (res.x/2)),(pos_start.y - offset * (res.y/2)),740)) // 2626
	HPlayer.SetAngles(89,90,0)
}

function Break()
{
	BREAK = true
	EntFireByHandle(hTimer, "Disable")
}

function Start()
{
	HPlayer.__KeyValueFromInt("movetype",8)
	SetPos(pos_start)
	BREAK = false
	EntFireByHandle(hTimer, "Enable")
	VS.EventQueue.AddEvent( loop, 0.1, this )
}

::OnGameEvent_bullet_impact <- function(data)
{
	impactCount++
}
