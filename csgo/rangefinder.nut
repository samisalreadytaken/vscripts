//-----------------------------------------------------------------------
//
// Measure distance from the player to the wall
// Shoot to print the distance to chat and console, in units
// Does not print while spraying
//
// An alternative to the rangefinder command, but also calculates the normalised distance.
// ______________________________
//       \
//       |\
//       | \ 3D dist
//       |  \
//       |   \
//       |----P
// norm dist
//
// Note: Some surfaces may have a few units thick clip brushes.
// These may lower the calculated distance by that thickness.
// It's negligible is most cases.
//
//-----------------------------------------------------------------------

IncludeScript("vs_library");

local init = function()
{
	VS.GetLocalPlayer();

	if( !("HPlayerEye" in getroottable()) )
		::HPlayerEye <- VS.CreateMeasure(HPlayer.GetName(),null,true).weakref();
	if( !("_RF_hListener" in this) )
		_RF_hListener <- VS.CreateEntity("game_ui",{ spawnflags = 0, fieldofview = -1.0 },true).weakref();

	EntFireByHandle(_RF_hListener, "activate", "", 0, HPlayer);
}();

VS.AddOutput(_RF_hListener,"PressedAttack",function()
{
	flTimeAttack <- Time();

	local eye = HPlayer.EyePosition();

	local tr = VS.TraceDir(eye,HPlayerEye.GetForwardVector());

	tr.GetPos();
	tr.GetNormal();

	local pt = VS.PointOnLineNearestPoint(tr.hitpos, tr.hitpos+tr.normal*MAX_COORD_FLOAT, eye);

	__dist <- eye - tr.hitpos;
	__ndist <- pt - tr.hitpos;

	DebugDrawBox(pt, Vector(-2,-2,-2), Vector(2,2,2), 255,138,0,255, 5);
	DebugDrawBox(eye, Vector(-2,-2,-2), Vector(2,2,2), 255,138,0,255, 5);
	DebugDrawLine(tr.hitpos, eye, 255,0,255,true, 5);
	DebugDrawLine(tr.hitpos, pt, 0,255,0,true, 5);
},null,true);

VS.AddOutput(_RF_hListener,"UnpressedAttack",function()
{
	if( Time() - flTimeAttack < 0.2 )
	{
		local d = VS.FormatPrecision(__dist.Length(),4);
		local d2 = VS.FormatPrecision(__dist.Length2D(),4);
		local nd = VS.FormatPrecision(__ndist.Length(),4);

		Chat("");
		Chat(txt.lightblue + "Distance: " + txt.yellow + d);
		Chat(txt.lightblue + "Distance2D: " + txt.yellow + d2);
		Chat(txt.lightblue + "Norm Dist: " + txt.yellow + nd);
		printl("\nDistance: " + d);
		printl("Distance2D: " + d2);
		printl("Norm Dist: " + nd);
	};
},null,true);
