//-----------------------------------------------------------------------
//----------------------- Copyright (C) 2019 Sam ------------------------
//                     github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// https://www.youtube.com/watch?v=brUpQi_9ZIU
//
//------------------------------

IncludeScript("vs_library")
IncludeScript("vs_library/vs_collision")

SendToConsole("sv_cheats 1;mp_roundtime 60;mp_freezetime 0;mp_ignore_round_win_conditions 1;mp_respawn_on_death_t 1;mp_warmup_end")

::s <- this

::OnGameEvent_player_use <- function( data )
{
	s.OnUse(data)
}

::OnGameEvent_player_jump <- function( data )
{
	s.OnJump(data)
}

::OnGameEvent_weapon_fire <- function( data )
{
	if( s.bHolding )
		s.StopHolding()
}

function _Button()
{
	Chat("Completed in " + txt.yellow + VS.FormatPrecision( Time()-fTimeStart, 5 ) + txt.white + " seconds" )

	// abrupt ending, random
	activator.EmitSound("BaseGrenade.Explode")
	activator.SetVelocity( Vector(0,0,1700) )
	SendToConsole("kill")
	delay("SendToConsole(\"fadeout\")", 0.4)
}

function PlayMusic()
{
	HPlayer.EmitSound( "Musix.HalfTime.damjanmravunac_01" );
}

function Hint(s)
{
	VS.ShowHudHint( hHudHint, HPlayer, s )
}

function HideHint()
{
	VS.HideHudHint( hHudHint, HPlayer )
}

function OnPostSpawn()
{
	if( !VS.GetLocalPlayer() ) return printl("Loading...")

	if( !Ent("vs_timer*") )
	{
		::HPlayerEye <- VS.CreateMeasure("player")[0]
		::hBuffer <- VS.CreateEntity("logic_script")
		::hHudHint <- VS.CreateHudHint()
		hThink <- VS.Timer( 0, 0.015625, "Think" )
		hThinkObj <- VS.Timer( 0, 0.15625, "ThinkBombs" )

		VS.MakePermanent( HPlayerEye )
		VS.MakePermanent( hBuffer )
		VS.MakePermanent( hHudHint )
	}

	ChangeLevel( 0 )

	// todo: better method
	SendToConsole("r_drawviewmodel 0")
}

function CloseDoors()
{
	local e
	while( e = Entities.Next(e) ) if( e.GetName().find("wall_") != null ) EntFireHandle( e, "enable" )
}

/*
// Parent the jammer parts.
// This process will be different depending on what is used, and how
function ProcessChildren()
{
	local base

	// find the base model
	while( base = Entities.FindByModel(base, "models/props/de_inferno/hr_i/inferno_chimney/inferno_chimney_01.mdl") )
	{
		local ent1, ent2

		printl("--- Parenting:")
		printl("base:\t" + base)

		// find the tip
		// 50 is the size of the button - the whole thing
		if( ent1 = Entities.FindByClassnameNearest( "prop_dynamic", base.GetOrigin(), 50 ) )
		{
			if( ent1.GetModelName() == "models/props_urban/chimney001.mdl" )
			{
				printl("tip:\t" + ent1)

				VS.SetParent( ent1, base )
			}
		}
		else Assert(0) // map was configured incorrectly

		// find the button
		if( ent2 = Entities.FindByClassnameNearest( "func_button", base.GetOrigin(), 50 ) )
		{
			printl("bttn:\t" + ent2)

			VS.SetParent( ent2, base )
		}
		else Assert(0) // map was configured incorrectly
	}
}
*/

function ChangeLevel( i )
{
	local list_bombs

	switch(i)
	{
		case 0:
			vStartPos = Vector(-1896.596191,6.483833,12)

			list_bombs = [ Ent("obj_01"),
			               Ent("obj_02") ]

			break

		case 1:
		case 2:
		case 3:
		case 4:
		default: printl("Invalid level!")
	}

	foreach( ent in list_bombs ) obj_bombs[ent] <- false

	vCheckpoint = vStartPos
	CloseDoors()
}

function Checkpoint()
{
	local new = caller.GetOrigin()

	if( VS.VectorsAreEqual( vCheckpoint, new ) ) return

	vCheckpoint = new

	Chat(txt.lightgreen + "Checkpoint...")
}

function Start()
{
	fTimeStart = Time()
	Chat(txt.lightgreen+"...")
}

//----------------------------------------------
// entity names should follow this style:
// type_spec_id
// i_type_spec_id

// if prefixed with "i_", ent is target

// TODO: better method
function GetType( ent )
{
	local name = ent.GetName()
	if( name[0] == 'i' )
		return split( name, "_" )[1]
	return split( name, "_" )[0]
}

function Think()
{
	trace = VS.TraceDir( HPlayer.EyePosition(), HPlayerEye.GetForwardVector() )

	// DebugDrawBox( trace.GetPos(), Vector(-2,-2,-2), Vector(2,2,2), 255, 138, 0, 128, 0.1 )

	if( bHolding )
	{
		ThinkAngles(trace)
	}

	// DEBUG
	ThinkLook(trace)
}

function ThinkAngles(tr)
{
	// keep the base moving and rotating only on the yaw axis
	hBuffer.SetAbsOrigin( HPlayer.GetOrigin() )
	hBuffer.SetAngles( 0, HPlayerEye.GetAngles().y, 0 )

	// where the player is looking at
	local ply_trace = tr.GetPos()

	// angle from the tip to where the player is looking at
	local ang = VS.GetAngle( hEntTip.GetOrigin(), ply_trace )

	// set the pitch angle of the tip to where the player is looking at
	hEntTip.SetAngles( ang.x + 90/* + 90 because of the chimney model */, 0, 0 )
}

function ThinkLook(tr)
{
	// DEBUG
	// if looking at the general direction of a jammable object, draw ent bbox
	local ent = VS.FindEntityClassNearestFacingNearest( HPlayer.GetOrigin(), HPlayerEye.GetForwardVector(), 0.85, TARGET_TYPE, 1024 )

	if( ent )
	{
		VS.DrawEntityBBox( fT2, ent.GetMoveParent() )
	}
}

function ThinkBombs()
{
	foreach( bomb, jammed in obj_bombs )
	{
		if( !jammed )
		{
			// if player is closer than 128 units
			if( (HPlayer.GetOrigin()-bomb.GetOrigin()).LengthSqr() < 16384 ) // 128 * 128
			{
				// fixme: use env_fade
				SendToConsole("fadein")

				HPlayer.SetOrigin( vCheckpoint )
				HPlayer.SetAngles( 0,0,0 )

				// fixme: reset links

				// break the loop
				return
			}
		}
	}
}

function OnJump(data)
{
	if( bHolding )
	{
		StopHolding()

		// stop the player jumping
		HPlayer.SetVelocity(Vector(0,0,-300))

		// put the base on the ground
		hEntBase.SetAbsOrigin( VS.TraceDir( hEntBase.GetCenter(), Vector(0,0,-1), 0 ).GetPos() )
		// put the player on the ground
		HPlayer .SetAbsOrigin( VS.TraceDir( HPlayer .GetCenter(), Vector(0,0,-1), 0 ).GetPos() )
	}
}

const TARGET_TYPE = "info_teleport_destination"

trace <- null
fT2 <- FrameTime() * 2
fTimeStart <- 0.0
vCheckpoint <- null
vStartPos <- null
bHolding <- false
hEntFacing <- null
hEntBase <- null
hEntTip <- null

// jammer : object
links <- {}

// object : isJammed
obj_bombs <- {}

function OnUse(data)
{
	local e

	// if pressed on a func_button
	if( e = VS.FindEntityByIndex( data.entity, "func_button" ) )
	{
		// if it has a name (check len to prevent error at GetType)
		if( e.GetName().len() > 2 )
		{
			// if the button that was used is prefixed with "jammer_"
			if( GetType( e ) == "jammer" )
			{
				hEntBase = e.GetMoveParent()

				if( !bHolding )
				{
					StartHolding()
				}
				else
				{
					StopHolding()
				}
			}
		}
	}
}

function StartHolding()
{
	bHolding = true

	// get the tip that points at stuff
	local id = hEntBase.GetName().slice( "jammer_base_".len() )
	hEntTip = Ent("jammer_tip_" + id)

	// reorientate
	hEntBase.SetAngles( 0, HPlayerEye.GetAngles().y, 0 )

	// reposition 64 units in front of the player
	local new = HPlayerEye.GetForwardVector() * 64 + HPlayer.GetOrigin()
	hEntBase.SetAbsOrigin( Vector(new.x, new.y, hEntBase.GetOrigin().z) )

	// follow player's angle
	VS.SetParent( hEntBase, hBuffer )

	PickupJammer()
}

function StopHolding()
{
	bHolding = false

	// stop following player
	VS.SetParent( hEntBase, null )

	PlaceJammer()

	// DEBUG: draw red line to where the tip is pointing at
	DebugDrawLine( hEntTip.GetOrigin(), VS.TraceDir( hEntTip.GetOrigin(), hEntTip.GetUpVector()/* Up vector because of the chimney model */).GetPos(), 255, 0, 0, false, 2 )

	// DEBUG: Draw green line to where the player is looking at
	DebugDrawLine( HPlayer.EyePosition(), VS.TraceDir( HPlayer.EyePosition(), HPlayerEye.GetForwardVector() ).GetPos(), 0, 255, 0, false, 2 )
}

function PlaceJammer()
{
	// if looking at the general direction of a jammable object, and is closer than 1024 units away
	local ent = VS.FindEntityClassNearestFacingNearest( HPlayer.GetOrigin(), HPlayerEye.GetForwardVector(), 0.85, TARGET_TYPE, 1024 )

	if( ent )
	{
		if( GetType( ent ) == "wall" )
		{
			ent = Entities.FindByClassnameWithin( null, "func_brush", ent.GetOrigin(), 2.0 )

			// map was configured incorrectly
			// the info_teleport_destination needs to be placed in the center of the jammable objects
			Assert(ent)

			// if looking directly at a jammable wall
			if( VS.IsBoxIntersectingRay( ent.GetCenter(), ent.GetBoundingMins(), ent.GetBoundingMaxs(), trace.Ray(), 0.5 ) )
			{
				links[hEntBase] <- ent

				EntFireHandle( ent, "disable" )
			}
		}
		else if( GetType( ent ) == "obj" )
		{
			ent = Entities.FindByClassnameWithin( null, "func_tanktrain", ent.GetOrigin(), 2.0 )
			Assert(ent)

			if( VS.IsBoxIntersectingRay( ent.GetCenter(), ent.GetBoundingMins(), ent.GetBoundingMaxs(), trace.Ray(), 0.5 ) )
			{
				links[hEntBase] <- ent
				obj_bombs[ent] = true

				EntFireHandle( ent, "stop" )
			}
		}
	}
}

function PickupJammer( input = null )
{
	local jammer = input ? input : hEntBase

	// if the jammer is jamming an object
	if( jammer in links )
	{
		// do nothing if there's another jammer jamming the same object
		foreach( k, v in links )
			if( k != jammer )
				if( v == links[jammer] )
					return delete links[jammer] // break the link

		// break the link
		local ent = delete links[jammer]
		local typ = GetType( ent )

		if( typ == "wall" )
		{
			EntFireHandle( ent, "enable" )
		}
		else if( typ == "obj" )
		{
			// FIXME: resume double jammed bombs after picking up both jammers
			obj_bombs[ent] = false

			EntFireHandle( ent, "resume" )
		}
	}
}
