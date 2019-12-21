//-----------------------------------------------------------------------
//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
//                     github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// A snippet to demonstrate usage of the interpolation library (vs_interp)
//
// Output of this script:
//  	https://steamuserimages-a.akamaihd.net/ugc/776240207164901303/2EA7036A0A36D926004611162277C06E385177C0/
//
//-----------------------------------------------------------------------

IncludeScript("vs_library")
IncludeScript("vs_library/vs_interp")

VS.GetLocalPlayer()
SendToConsole("mp_freezetime 0;mp_ignore_round_win_conditions 1;mp_warmup_end")

list_pos <- [Vector(531.029,-167.653,54.685)Vector(642.706,373.037,106.219)Vector(-17.9624,370.866,109.592)Vector(-427.136,782.254,191.718)Vector(-1005.76,1154.56,660.829)Vector(-989.918,474.171,909.928)Vector(-1335.03,-189.327,499.407)Vector(-1093.28,-991.457,190.941)Vector(-527.3,-1217.58,329.72)Vector(-318.908,-1013.62,111.247)]

list_catmull <- []
list_kochanek <- []
list_cubic <- []

function Process()
{
	// resolution [0,1]
	local res = 0.01

	for( local f = 0; f < 1; f += res )
		for( local i = 0; i < list_pos.len()-4; i++ )
		{
			local vOut = Vector()

			list_catmull.append(
				VS.Interpolator_CurveInterpolate( INTERPOLATE.CATMULL_ROM, list_pos[i], list_pos[i+1], list_pos[i+2], list_pos[i+3], f, vOut )
			)

			list_kochanek.append(
				VS.Interpolator_CurveInterpolate( INTERPOLATE.KOCHANEK_BARTELS, list_pos[i], list_pos[i+1], list_pos[i+2], list_pos[i+3], f, vOut )
			)

			list_cubic.append(
				VS.Interpolator_CurveInterpolate( INTERPOLATE.SIMPLE_CUBIC, list_pos[i], list_pos[i+1], list_pos[i+2], list_pos[i+3], f, vOut )
			)
		}
}

function DrawAll()
{
	// green
	foreach( v in list_pos ) Draw( v, 16, 10, 0, 255, 0 )

	// orange
	foreach( v in list_catmull ) Draw( v, 4, 10, 255, 138, 0 )

	// red
	foreach( v in list_kochanek ) Draw( v, 4, 10, 255, 0, 0 )

	// purple
	foreach( v in list_cubic ) Draw( v, 4, 10, 100, 0, 200 )
}

function Draw( v, s = 4, t = null, R = 255, G = 138, B = 0, A = 10 )
{
	DebugDrawBox( v, Vector(-s,-s,-s), Vector(s,s,s), R, G, B, A, t )
}
