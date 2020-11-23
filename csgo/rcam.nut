//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// remote cameras
//
// equip, fire to shoot camera, right click to stop
//
// written in a day, not tested with multiple players but it should work
//

IncludeScript("vs_library")

if ( !("RCAM" in getroottable()) )
	::RCAM <- {}

local __init__ = function(){
//==============================================

// delay between shooting and seeing the camera
const RCAM_FIRE_DELAY = 0.25

hEye <- null
trace <- null
list_cam_inuse <- []
list_cam_free <- []
list_ui_free <- []
list_ui_inuse <- []

function Kill()
{
	::print("RCAM::Kill:\n")

	if (hEye) hEye.Destroy()

	foreach( v in list_cam_free )
		if (v) v.Destroy()
	foreach( v in list_cam_inuse )
		if (v) v.Destroy()
	foreach( v in list_ui_free )
		if (v) v.Destroy()
	foreach( v in list_ui_inuse )
		if (v) v.Destroy()

	foreach( v in VS.GetAllPlayers() )
	{
		local sc = v.GetScriptScope()
		if ( "using_cam" in sc )
			sc.using_cam = false
	}

	delete::RCAM
}

function TraceEye(ply)
{
	if ( !hEye )
	{
		::print("RCAM::TraceEye: Creating new measure entity\n")
		hEye = ::VS.CreateMeasure("").weakref()
	}

	::print("RCAM::TraceEye: Setting measure\n")

	// if the player already has a name save it to revert back to it after trace
	local name = ply.GetName()

	::VS.SetName( ply, "PLAYER_EYE" )

	// setting the measure target takes one frame
	::VS.SetMeasure( hEye, "PLAYER_EYE" )

	// get the trace in the next frame
	return::VS.EventQueue.AddEvent( _TraceEye, 0.0, [this, ply, name] )
}

function _TraceEye(ply,name)
{
	::print("RCAM::TraceEye:\n")

	trace = ::VS.TraceDir( ply.EyePosition(), hEye.GetForwardVector() )
	::VS.SetName( ply, name )
}

// Make sure a camera exists and linked to the player
function GetNewCamera(ply)
{
	local cam,ui

	if ( cam = GetOwnCamera(ply) )
		return cam

	// found available
	if ( list_cam_free.len() )
	{
		::print("RCAM::GetNewCamera: Found free camera\n")
		cam = list_cam_free.pop().ref() // .top and .pop return weakref
		ui = list_ui_free.pop().ref()
	}
	// create new
	else
	{
		::print("RCAM::GetNewCamera: Creating new camera entity\n")
		cam = ::VS.CreateEntity( "point_viewcontrol",{ spawnflags = 1<<3 } )
		ui = ::VS.CreateEntity( "game_ui",{ spawnflags = 0, fieldofview = -1.0 },true )

		::VS.AddOutput( ui, "PressedAttack", Fire, null, true )
		::VS.AddOutput( ui, "PressedAttack2", StopCamera, null, true )
	}

	cam.SetOwner(ply)

	list_cam_inuse.append( cam.weakref() )
	list_ui_inuse.append( ui.weakref() )

	return cam
}

// if player owns any cameras
// todo: use lookup tables?
function GetOwnCamera(ply)
{
	foreach( k,v in list_cam_inuse )
		if ( v.GetOwner() == ply )
		{
			::print("RCAM::GetOwnCamera: Found player's camera\n")
			return v
		}
}

// this should work because all ui and cam list actions are done together
function GetOwnIdx(ply)
{
	foreach( k,v in list_cam_inuse )
		if ( v.GetOwner() == ply )
		{
			::print("RCAM::GetOwnIdx: " + k + "\n")
			return k
		}
}

function FreeCamera(cam)
{
	foreach( k,v in list_cam_inuse ) if ( cam == v )
	{
		::print("RCAM::FreeCamera:\n")

		local old = list_cam_inuse.remove(k)
		list_cam_free.append(old.weakref())

		local oldui = list_ui_inuse.remove(k)
		list_ui_free.append(oldui.weakref())

		old.SetFov(90,0)
		old.SetOwner(null)
		return
	}

	::print("RCAM::FreeCamera: Could not find camera to free\n")
}

function Equip( ply = null )
{
	if ( !ply )
	{
		if ( !("activator" in ::getroottable()) )
			return ::print("RCAM::Equip: No player!\n")

		ply = ::activator
	}
	else if ( !ply.IsValid() || ply.GetClassname() != "player" )
		return ::print("RCAM::Equip: Invalid player!\n")

	::print("RCAM::Equip: Equipping player\n")

	GetNewCamera(ply)

	local ui = list_ui_inuse[GetOwnIdx(ply)]

	// listen for +attack to fire the camera
	::EntFireByHandle( ui, "Activate", "", 0, ply )

	ply.EmitSound("Sensor.Equip")
}

// executed in the scope of the ui for 'activator'
// because I'm not willing to make a queue system or whatever
function Fire( ply = null )
{
	if ( !ply )
	{
		if ( !("activator" in ::getroottable()) )
			return ::print("RCAM::Fire: No player!\n")

		ply = ::activator
	}

	local cam = ::RCAM.GetOwnCamera(ply)

	if ( !cam )
	{
		return ::print("RCAM::Fire: No camera found\n")
	}

	local sc = ply.GetScriptScope()
	if ( !("using_cam" in sc) )
		sc.using_cam <- false

	if ( sc.using_cam )
	{
		return ::print("RCAM::Fire: Already using camera\n")
	}

	::print("RCAM::Fire:\n")

	return::VS.EventQueue.AddEvent( _Fire, RCAM_FIRE_DELAY, [this, ply] )
}

function _Fire(ply)
{
	::RCAM.TraceEye(ply)

	return::VS.EventQueue.AddEvent( __Fire, 0.0, [this, ply] )
}

// executed one frame after getting the trace
function __Fire(ply)
{
	::print("RCAM::_Fire:\n")

	// trace should be ready by now
	if ( !trace )
		throw "RCAM::_Fire: trace not found!"

	local pos = trace.GetPos()
	local normal = trace.GetNormal()

	trace = null

	local cam = GetOwnCamera(ply)

	// stick out of wall
	cam.SetOrigin(pos + normal)

	// look at the normal direction
	cam.SetForwardVector(normal)

	cam.SetFov(110,0)

	cam.EmitSound("c4.plantquiet")
	ply.EmitSound("C4.ExplodeTriggerTrip")

	::EntFireByHandle( cam, "Enable", "", 0, ply )
	::EntFireByHandle( ply, "SetHudVisibility", 0 )

	ply.GetScriptScope().using_cam = true
	ply.__KeyValueFromInt( "movetype", 0 )
}

function StopCamera( ply = null )
{
	::print("RCAM::StopCamera:\n")

	if ( !ply )
	{
		if ( !("activator" in ::getroottable()) )
			return ::print("RCAM::StopCamera: No player!\n")

		ply = ::activator
	}

	local sc = ply.GetScriptScope()

	if ( !sc.using_cam )
		return ::print("RCAM::StopCamera: Not using\n")

	local idx = ::RCAM.GetOwnIdx(ply)
	local cam = ::RCAM.list_cam_inuse[idx]
	local ui = ::RCAM.list_ui_inuse[idx]

	sc.using_cam = false
	ply.__KeyValueFromInt( "movetype", 2 )

	::EntFireByHandle( cam, "Disable", "", 0, ply )
	::EntFireByHandle( ply, "SetHudVisibility", 1 )
	if ( ply.IsValid() )::EntFireByHandle( ui, "Deactivate", "", 0, ply )
	else ::print("RCAM::StopCamera: Invalid player\n")
	cam.SetFov(90,0)
	// cam.EmitSound("")
	::RCAM.FreeCamera(cam)
}

//==============================================
}.call(RCAM)
