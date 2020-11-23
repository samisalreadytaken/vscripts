//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// test script
//
// Planting bomb starts measuring the damage,
// taking damage displays momentarily predicted and taken damage
//
//
// Three damage values are displayed live in the middle of the screen
// Each calculates from different positions:
// - EyePosition
// - WorldSpaceCenter
// - average of top 2
//
// When they are equal, the explosion damage is consistent
// When they are not equal, the explosion damage is consistently inconsistent
//
// Testing at the same position when the displayed values are different:
// sometimes EyePosition is true, sometimes WorldSpaceCenter;
// but the average is correct when testing vertically???
//
// I didn't test enough to figure out why or how.
//
// script test( x, 995.838562 )
//

IncludeScript("vs_library");

SendToConsole("mp_warmup_pausetimer 1;mp_freezetime 0;mp_c4timer 12;mp_plant_c4_anywhere 1;mp_anyone_can_pickup_c4 1")

VS.GetLocalPlayer();

if( !("_BOMBRADIUS_" in getroottable()) )
	::_BOMBRADIUS_ <- {}

local __init__ = function(){

flBombRadius <- 500.0;

flFrameTime <- FrameTime();
flFrameTime2 <- flFrameTime * 2.0;
flBombDamage <- flBombRadius;
flBombRadius *= 3.5;
nLastDealtDmg <- -1;
flLastPredDmg <- -1.0;

if( !("hThink" in this) )
{
	hThink <- VS.Timer(0,flFrameTime,null,null,0,1).weakref();
	hThinkEquipment <- VS.Timer(0,2,null,null,0,1).weakref();
	hHudHint <- VS.CreateEntity("env_hudhint",null,1).weakref();
	hEquip <- VS.CreateEntity("game_player_equip",{ spawnflags = (1<<0)|(1<<2) },1).weakref();

	hGameText <- VS.CreateEntity("game_text",
	{
		channel = 1,
		color = Vector(255,138,0),
		holdtime = flFrameTime2,
		x = 0.5
		y = 0.55
	},true).weakref();

	hGameText2 <- VS.CreateEntity("game_text",
	{
		channel = 3,
		color = Vector(255,138,0),
		holdtime = flFrameTime2,
		x = 0.5,
		y = 0.58
	},true).weakref();

	hGameText3 <- VS.CreateEntity("game_text",
	{
		channel = 4,
		color = Vector(255,138,0),
		holdtime = flFrameTime2,
		x = 0.5,
		y = 0.61
	},true).weakref();

	hDisplayLastDmg <- VS.CreateEntity("game_text",
	{
		channel = 2,
		color = Vector(255,50,0),
		holdtime = flFrameTime2,
		x = 0.075,
		y = 0.55
	},true).weakref();
}

VS.OnTimer(hThinkEquipment,function()
{
	for( local ent; ent = Entities.FindByClassname(ent,"weapon_c4"); )
	{
		if( ent.GetOwner() )
			return;

		ent.Destroy()
	}

	// HPlayer.SetHealth(100)
	// EntFireByHandle(hEquip,"triggerforactivatedplayer","weapon_c4",0,HPlayer)
	SendToConsole("sv_cheats 1;give weapon_c4")
	EntFireByHandle(hEquip,"triggerforactivatedplayer","item_kevlar",0,HPlayer)
})

function Kill()
{
	if(hThink)(delete hThink).Destroy()
	if(hHudHint)(delete hHudHint).Destroy()
	if(hEquip)(delete hEquip).Destroy()
	if(hGameText)(delete hGameText).Destroy()
	if(hGameText2)(delete hGameText2).Destroy()
	if(hGameText3)(delete hGameText3).Destroy()
	if(hDisplayLastDmg)(delete hDisplayLastDmg).Destroy()
}

// bombpos, bombrad*3.5, playerpos
function RadiusDamage(vecSrc, flRadius, vecTarget)
{
	DebugDrawLine(vecSrc, vecTarget, 255,0,255, true, flFrameTime2);

	vecSrc = VS.VectorCopy(vecSrc,Vector());
	// vecSrc.z += 1.0

	local vecDelta = vecSrc - vecTarget;
	local flRadiusSqr = flRadius * flRadius;
	local flAdjustedDmg = flBombDamage * exp(-vecDelta.LengthSqr() / (flRadiusSqr * 0.22222222))

	local flHealthDmgRaw = flAdjustedDmg * 0.5;		// damage reduced by armour
	local flHealthDmg = (flHealthDmgRaw).tointeger();
	// local flArmourDmg = (flAdjustedDmg - flHealthDmg) * 0.5; // damage done to armour

	Assert( flHealthDmg == floor(flHealthDmgRaw) )

	local trunc = flHealthDmgRaw-flHealthDmg

	Msg(format( "dist [[ %.6f ]]   ", (vecSrc-vecTarget).Length() ))
	Msg(format( "truncated [[ %.6f ]] %g -> %g\n", trunc, flHealthDmgRaw, flHealthDmg ))

	return flHealthDmg
}

VS.OnTimer(hThink,function()
{
	local hC4, flDmg

	// kill previous bombs, have only one (the latest) in map
	for( local ent,i=0;++i,ent=Entities.FindByClassname(ent,"planted_c4"); )
	{
		if( i > 1 )
		{
			hC4.Destroy()
			nLastDealtDmg = -1
		}

		hC4 = ent
	}

	if( !hC4 || !hC4.IsValid() )
		return

	local vecBombPos = hC4.GetOrigin()

	DebugDrawBox(vecBombPos, Vector(-2,-2,-2), Vector(2,2,2), 25, 255, 25, 25, flFrameTime2);

	// origin distance is printed for usage with 'test()'

	Msg("\n")
	Msg(format( "ori dist: [[ %.6f ]]\n", (HPlayer.GetOrigin()-vecBombPos).Length() ))
	Msg("eye: ")
	flDmg = RadiusDamage(vecBombPos, flBombRadius, HPlayer.EyePosition());
	Msg("ctr: ")
	local dmg2 = RadiusDamage(vecBombPos, flBombRadius, HPlayer.GetCenter());
	Msg("avg: ")
	local dmg3 = RadiusDamage(vecBombPos, flBombRadius, (HPlayer.EyePosition()+HPlayer.GetCenter())*0.5);

	VS.ShowGameText(hGameText,HPlayer, flDmg)
	VS.ShowGameText(hGameText2,HPlayer, dmg2)
	VS.ShowGameText(hGameText3,HPlayer, dmg3)

	local hp = HPlayer.GetHealth()

	// took damage, bomb exploded? save values
	if( hp != 100 )
	{
		nLastDealtDmg = 100 - hp
		flLastPredDmg = flDmg

		Msg("--[[          Resetting player\n")
		HPlayer.SetHealth(100)
	}

	if( nLastDealtDmg != -1 )
	{
		local str = format( "Dealt damage: %d\nPredicted damage: %g", nLastDealtDmg, flLastPredDmg )
		VS.ShowGameText(hDisplayLastDmg, HPlayer, str)
	}
});

::x <- "x"
::y <- "y"
::z <- "z"

::test <- function(plane,val)
{
	HPlayer.__KeyValueFromInt("movetype",0)

	local c4 = Entc("planted_c4")
	local pos = c4.GetOrigin()

	// Assert( VS.VectorsAreEqual(pos,g_vecBombPos) )
	// pos.z += 1.0 // RadiusDamage

	pos[plane] += val
	HPlayer.SetOrigin(pos)
}.bindenv(this)

::get <- function()
{
	POS <- HPlayer.GetOrigin()
}.bindenv(this)

::set <- function()
{
	HPlayer.SetOrigin(POS)
}.bindenv(this)

}.call(_BOMBRADIUS_)
