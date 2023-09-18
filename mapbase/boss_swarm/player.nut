//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

local Swarm = this;
local Time = Time, NetMsg = NetMsg, atan2 = atan2, Lerp = Lerp, RandomFloat = RandomFloat;

local SND_HIT = "Geiger.BeepLow";
local SND_DEATH = "Geiger.BeepHigh";

PrecacheModel( "swarm/player2.vmt" );
PrecacheModel( "swarm/heart.vmt" );
PrecacheSoundScript( SND_HIT );

const CURSOR_PAN_RATE = 0.25;
const CAM_DIST = 512.0;

class moveparam_t
{
	friction = 0.0;
	maxspeed = 500.0;
	move = 0.0;

	constructor( params )
	{
		if ( "friction" in params )
			friction = params.friction;
		if ( "maxspeed" in params )
			maxspeed = params.maxspeed;
		if ( "move" in params )
			move = params.move;
	}

	function _cloned( v )
	{
		friction = v.friction;
		maxspeed = v.maxspeed;
		move = v.move;
	}
}

class CPlayer extends CEntity
{
	m_nTeam = 1;
	m_nMaxHealth = 6;
	m_nHealth = 0;
	m_MoveParams = null;
	m_BaseMoveParams = moveparam_t({ friction = 12.0, move = 10.0, maxspeed = 8.0 });

	m_pBasePlayer = null;
	m_hView = null;

	m_vecViewPosition = null;
	m_vecCursorRay = null;

	m_vecShakeOffset = null;
	m_vecShakeRoll = null;
	m_flShakeEndTime = 0.0;
	m_flShakeDuration = 0.5;
	m_flShakeFreq = 30.0;
	m_flShakeOffsetAmp = 4.0;
	m_flShakeRollAmp = 1.0;
	m_nShakeType = 0;

	m_Buttons = 0;

	m_Items = null;
	m_ItemOrderCache = null;
	m_ItemOffers = null;
	m_Slots = null;
	m_iActiveSlot = 0;
	m_CurWeapon = null;

	// HACKHACK: Everything regarding the 'alt weapon' is a hack, hastily put together.
	m_AltWeapon = null;

	m_Shields = null;
	UpdateHealthStats = dummy; // HACK: for shields

	m_flCutsceneStartTime = 0.0;
	m_flCutsceneTransTime = 0.0;
	m_flCutsceneHoldTime = 0.0;
	m_fnCutsceneEndCallback = null;
	m_bCutsceneIn = true;
	m_bGodMode = false;
}

function CPlayer::constructor( basePlayer )
{
	base.constructor();

	Swarm.m_PlayerMap[ basePlayer ] <- this;
	Swarm.m_Players.append( this );
	Swarm.m_HurtableEntities.append( this );

	m_pBasePlayer = basePlayer;

	m_vecHullMins.Init( -16, -16, 0 );
	m_vecHullMaxs.Init( 16, 16, 4 );

	m_vecViewPosition = Vector( 0, 0, CAM_DIST );
	m_vecCursorRay = Vector( 0, 0, -1 );
	m_vecShakeOffset = Vector();
	m_vecShakeRoll = Vector( 90, 90, 0 );

	m_pEntity = Swarm.SpriteCreate( "swarm/player2.vmt", 0.15, MOVETYPE_STEP,
		vec3_origin, vec3_origin,
		m_vecHullMins, m_vecHullMaxs );

	m_hView = Entities.CreateByClassname( "point_viewcontrol" );
	m_hView.AddSpawnFlags( 8 | 128 );
	m_hView.SetFov( 70, 0 );
	m_hView.SetLocalAngles( Vector( 90, 90, 0 ) );
	m_hView.AcceptInput( "Enable", "", m_pBasePlayer, null );

	m_Items = array( MAX_ITEMS );
	m_Slots = array( MAX_SLOTS );
	m_ItemOffers = array( MAX_ITEM_OFFERS );
	m_ItemOrderCache = [];
	m_Shields = [];
}

function CPlayer::SetPosition( vec )
{
	vec.z = 0.0;
	m_vecPosition.Copy( vec );
	m_vecViewPosition.Init( vec.x, vec.y, CAM_DIST );
	m_pEntity.SetOrigin( m_vecPosition );
	m_hView.SetOrigin( m_vecViewPosition );
	m_hView.SetLocalAngles( Vector( 90, 90, 0 ) ); // clear shake residue
}

function CPlayer::Spawn()
{
	foreach ( i, item in m_Items )
	{
		if ( item )
		{
			item.Deactivate();
			m_Items[i] = null;
		}
	}

	foreach ( i, item in m_Slots )
	{
		if ( item )
		{
			item.Deactivate();
			m_Slots[i] = null;
		}
	}

	if ( m_AltWeapon )
	{
		m_AltWeapon.Deactivate();
		m_AltWeapon = null;
	}

	foreach ( obj in m_Shields )
	{
		if ( obj.m_nHealth > 0 )
			obj.Destroy();
	}

	base.Spawn();

	m_MoveParams = clone m_BaseMoveParams;
	m_nHealth = m_nMaxHealth;
	m_pBasePlayer.SetHealth( m_nHealth );
	m_vecVelocity.Init( 0, 0, 0 );
	m_iActiveSlot = 0;
	m_ItemOrderCache.clear();
	m_Shields.clear();

	return UpdateClient();
}

function CPlayer::UpdateClient()
{
	NetMsg.Start( "Swarm.CPlayer.Update" );
		NetMsg.WriteByte( m_nMaxHealth );
		NetMsg.WriteEntity( m_pEntity );
	return NetMsg.Send( m_pBasePlayer, true );
}

class CHealthPickup extends CItem
{
	function ActivateOn( owner )
	{
		if ( owner )
		{
			//if ( owner.m_nHealth >= owner.m_nMaxHealth )
			//	return;

			++owner.m_nHealth;
			owner.m_pBasePlayer.SetHealth( owner.m_nHealth );
		}
	}
}

function CPlayer::HealthSpawnerThink(_)
{
	if ( Swarm.m_Pickups.len() >= 2 )
	{
		return -1;
	}

	if ( m_nHealth > 2 )
	{
		return -1;
	}

	// HACKHACK: Item pickups are mostly hardcoded for health, including spawn area here
	local position = Vector();
	local c = 0;
	do
	{
		position.Init(
			RandomInt( -480, 480 ),
			RandomInt( 480, 1400 ),
			0.0 );
	} while ( position.DistTo( Swarm.m_hBigBoss.m_vecPosition ) < 160.0 && ++c < 100 );

	if ( position.IsEqualTo( vec3_origin ) )
		return 1.0;

	local pickup = Swarm.CItemPickup( position, Swarm.CHealthPickup(this), "swarm/heart.vmt" );
	pickup.m_szPickupSound = "Weapon_AR2.Reload_Rotate";
	Swarm.m_Pickups.append( pickup );

	return 5.0;
}

function CPlayer::SelectSlot( slot )
{
	local targetItem = m_Slots[slot];
	if ( !targetItem )
	{
		printf( " ! no item in slot %d\n", slot );
		NetMsg.Start( "Swarm.CPlayer.SelectSlot" );
			NetMsg.WriteByte( m_iActiveSlot );
		return NetMsg.Send();
	}

	local curItem = m_Slots[m_iActiveSlot];
	if ( curItem )
	{
		curItem.Deactivate();
	}

	m_iActiveSlot = slot;
	m_CurWeapon = targetItem;
	return targetItem.Activate();
}

function CPlayer::EquipAltWeapon( item )
{
	local isID = typeof item == "integer";

	if ( m_AltWeapon )
	{
		m_AltWeapon.Deactivate();
	}

	if ( isID )
	{
		item = Swarm.m_EquipmentMap[ item ]( this );
	}

	m_AltWeapon = item;

	item.m_iSlot = ALT_WEP_SLOT;
	item.Activate();

	return UpdateEquipment();
}

function CPlayer::EquipWeapon( item )
{
	local isID = typeof item == "integer";

	local slot = -1;
	foreach ( x, item in m_Slots )
	{
		if ( !item )
		{
			slot = x;
			break;
		}
	}

	if ( slot == -1 )
	{
		m_Slots[m_iActiveSlot].Deactivate();
		m_Slots[m_iActiveSlot] = null;
		slot = m_iActiveSlot;
	}

	if ( isID )
	{
		item = Swarm.m_EquipmentMap[ item ]( this );
	}

	m_Slots[slot] = item;
	item.m_iSlot = slot;
	m_iActiveSlot = slot;
	m_CurWeapon = item;

	item.Activate();

	return UpdateEquipment();
}

function CPlayer::EquipItem( item, bOffer = false )
{
	local isID = typeof item == "integer";
	if ( isID && item >= SwarmEquipment.WEAPON_START && item <= SwarmEquipment.WEAPON_END )
		return EquipWeapon( item );

	local slot = -1;
	foreach ( x, item in m_Items )
	{
		if ( !item )
		{
			slot = x;
			break;
		}
	}

	if ( slot == -1 )
	{
		local x = m_ItemOrderCache.pop();

		if ( bOffer )
		{
			// Equipping this just replaced one of the existing items.
			// Put that replaced item back into offers.
			local replacedItem = m_Items[x];

			if ( m_ItemOffers[ replacedItem.m_iSlot ] )
			{
				// cannot, should not happen
				printf( " ! offer slot %d is full\n", replacedItem.m_iSlot );
			}

			m_ItemOffers[ replacedItem.m_iSlot ] = replacedItem;
			NetMsg.Start( "Swarm.UpdateItemOffer" );
				NetMsg.WriteByte( replacedItem.m_iSlot );
				NetMsg.WriteByte( replacedItem.m_ID );
				replacedItem.NET_WriteData();
			NetMsg.Send( m_pBasePlayer, true );
		}

		m_Items[x].Deactivate();
		m_Items[x] = null;
		slot = x;
	}

	m_ItemOrderCache.insert( 0, slot );

	if ( isID )
	{
		item = Swarm.m_EquipmentMap[ item ]( this );
	}

	m_Items[slot] = item;
	item.Activate();

	return UpdateEquipment();
}

function CPlayer::UpdateEquipment()
{
	NetMsg.Start( "Swarm.CPlayer.UpdateEquipment" );
		if ( m_AltWeapon )
		{
			NetMsg.WriteByte( m_AltWeapon.m_ID );
		}
		else
		{
			NetMsg.WriteByte( 0 );
		}
		foreach ( i, item in m_Slots )
		{
			if ( item )
			{
				NetMsg.WriteByte( item.m_ID );
				NetMsg.WriteByte( item.m_Modifiers );
				item.NET_WriteData();
			}
			else
			{
				NetMsg.WriteByte( 0 );
			}
		}
		foreach ( i, item in m_Items )
		{
			if ( item )
			{
				NetMsg.WriteByte( item.m_ID );
				item.NET_WriteData();
			}
			else
			{
				NetMsg.WriteByte( 0 );
			}
		}
		NetMsg.WriteByte( m_iActiveSlot );
	return NetMsg.Send( m_pBasePlayer, true );
}

function CPlayer::ProcessInput()
{
	local buttons = m_Buttons;

	local move = m_MoveParams.move;
	local friction = m_MoveParams.friction;
	local limit = m_MoveParams.maxspeed;
	local accel = move * friction * TICK_INTERVAL;

	if ( buttons & SwarmInput.FORWARD )
		m_vecVelocity.y += accel;
	else if ( buttons & SwarmInput.BACK )
		m_vecVelocity.y -= accel;

	if ( buttons & SwarmInput.LEFT )
		m_vecVelocity.x -= accel;
	else if ( buttons & SwarmInput.RIGHT )
		m_vecVelocity.x += accel;

	//if ( buttons & SwarmInput.USE )
	//	CameraShake( 2, 0.5, 4.0, 30.0 );

	if ( buttons & SwarmInput.RELOAD )
	{
		if ( m_CurWeapon && !m_CurWeapon.m_bInReload && m_CurWeapon.m_nClip != m_CurWeapon.m_nMaxClip )
		{
			m_CurWeapon.Reload();
		}
	}

	local spd = m_vecVelocity.Norm();
	local newspd = spd - spd * friction * TICK_INTERVAL;

	if ( newspd > limit )
		newspd = limit;

	m_vecVelocity.Multiply( newspd );

	return ResolveCollisions();
}

function CPlayer::ProcessAttack()
{
	if ( m_Buttons & SwarmInput.ATTACK )
	{
		if ( m_CurWeapon )
			m_CurWeapon.Attack();
	}

	if ( m_Buttons & SwarmInput.ATTACK2 )
	{
		if ( m_AltWeapon )
			return m_AltWeapon.Attack2();
	}
}

function CPlayer::ProcessDirection()
{
	local vecTargetDir = m_vecCursorRay + m_vecVelocity - m_vecPosition
	vecTargetDir.Norm();
	return SetForward( vecTargetDir );
}

function CPlayer::CameraThink()
{
	// NOTE: Panning towards the cursor jitters due to self-feedback.
	// This would not be a problem if I could just move the camera on client.
	// A fully clientside solution would be keeping render view static and
	// moving every sprite on client to simulate moving camera.
	// HACK: Calculate cursor end position on server, causing not smooth movement due to tickrate.
	// ALTERNATIVE: No crosshair camera pan :(

	// HACK:
	if ( m_vecCursorRay.z )
	{
		// VS.IntersectRayWithPlane()
		m_vecCursorRay.Multiply( m_vecPosition.z - m_vecViewPosition.z / m_vecCursorRay.z ).Add( m_vecViewPosition );
	}
	else
	{
		m_vecCursorRay.Add( m_vecViewPosition );
	}

	m_vecViewPosition.Init(
		Lerp( CURSOR_PAN_RATE, m_vecPosition.x, m_vecCursorRay.x ),
		Lerp( CURSOR_PAN_RATE, m_vecPosition.y, m_vecCursorRay.y ),
		CAM_DIST );

	if ( !m_vecViewPosition.IsValidVector() )
	{
		Warning( "Bogus camera position!\n" );
		printf( "  m_vecCursorRay     %s\n", ""+m_vecCursorRay );
		printf( "  m_vecViewPosition  %s\n", ""+m_vecViewPosition );
		printf( "  m_vecPosition      %s\n", ""+m_vecPosition );

		SetPosition( m_vecPosition );
		return;
	}

	local curtime = Time();

	if ( curtime <= m_flShakeEndTime )
	{
		local frac = ( m_flShakeEndTime - curtime ) / m_flShakeDuration;
		local freq = m_flShakeFreq / frac;

		local angle = curtime * freq;
		if ( angle > 1.e+8 )
			angle = 1.e+8;

		frac = sin( angle ) * frac * frac;

		switch ( m_nShakeType )
		{
			// roll & pan
			case 0:
				m_vecShakeOffset.Init(
					RandomFloat( -m_flShakeOffsetAmp, m_flShakeOffsetAmp ),
					RandomFloat( -m_flShakeOffsetAmp, m_flShakeOffsetAmp ),
					0.0 );
				m_vecShakeRoll.z = RandomFloat( -m_flShakeRollAmp, m_flShakeRollAmp );

				local t = ( FrameTime() / (m_flShakeDuration * m_flShakeFreq) );
				m_flShakeOffsetAmp -= m_flShakeOffsetAmp * t;
				m_flShakeRollAmp -= m_flShakeRollAmp * t;

				m_hView.SetLocalAngles( m_vecShakeRoll );
				return m_hView.SetLocalOrigin( m_vecShakeOffset.Add( m_vecViewPosition ) );

			// pan
			case 1:
				m_vecShakeOffset.Init(
					RandomFloat( -m_flShakeOffsetAmp, m_flShakeOffsetAmp ),
					RandomFloat( -m_flShakeOffsetAmp, m_flShakeOffsetAmp ),
					0.0 );
				m_flShakeOffsetAmp -= m_flShakeOffsetAmp * ( FrameTime() / (m_flShakeDuration * m_flShakeFreq) );
				return m_hView.SetLocalOrigin( m_vecShakeOffset.Add( m_vecViewPosition ) );

			// roll
			case 2:
				m_vecShakeRoll.z = RandomFloat( -m_flShakeRollAmp, m_flShakeRollAmp );
				m_flShakeRollAmp -= m_flShakeRollAmp * ( FrameTime() / (m_flShakeDuration * m_flShakeFreq) );
				m_hView.SetLocalAngles( m_vecShakeRoll );
				return m_hView.SetLocalOrigin( m_vecViewPosition );
		}
	}

	return m_hView.SetLocalOrigin( m_vecViewPosition );
}

function CPlayer::Frame( m_pEntity )
{
	if ( m_flCutsceneStartTime )
	{
		return 0.0;
	}

	if ( !m_nHealth )
	{
		CameraThink();
		return 0.0;
	}

	ProcessInput();
	CameraThink();
	ProcessDirection(); // after CameraThink if world pos is calculated on server

	// Check all weapons so that the reload end sound plays without switching to them
	foreach ( weapon in m_Slots )
	{
		if ( weapon && weapon.m_bInReload )
			weapon.CheckReload();
	}
	if ( m_AltWeapon && m_AltWeapon.m_bInReload )
		m_AltWeapon.CheckReload();

	ProcessAttack();

	DebugDrawBBox();

	return 0.0;
}

function CPlayer::CameraShake( type, duration, amplitude, frequency )
{
	m_flShakeDuration = duration;
	m_flShakeEndTime = Time() + duration;

	m_flShakeFreq = frequency;
	m_flShakeOffsetAmp = amplitude;
	m_flShakeRollAmp = amplitude * 0.25;

	m_nShakeType = type;
}

function CPlayer::TakeProjectileDamage( projectile )
{
	if ( m_bGodMode )
		return;

	if ( !m_nHealth )
		return;

	m_nHealth -= 1;

	if ( m_nHealth <= 0 )
	{
		m_hView.EmitSound( SND_DEATH );
		m_nHealth = 0;

		NetMsg.Start( "Swarm.CPlayer.OnDeath" );
		NetMsg.Send( m_pBasePlayer, true );
	}
	else
	{
		m_hView.EmitSound( SND_HIT );
		CameraShake( 0, 0.5, 4.0, 30.0 );

		if ( m_nHealth < 2 )
		{
			m_pBasePlayer.SetContextThink( "HealthSpawner", HealthSpawnerThink.bindenv(this), 0.2 );
		}
	}

	m_pBasePlayer.SetHealth( m_nHealth );
}

function CPlayer::StartCutsceneBigBoss( endcallback )
{
	m_flCutsceneStartTime = Time();
	m_flCutsceneTransTime = BIG_BOSS_INTRO_TRANS_TIME;
	m_flCutsceneHoldTime = BIG_BOSS_INTRO_HOLD_TIME;
	m_fnCutsceneEndCallback = endcallback;
	m_bCutsceneIn = true;

	m_pBasePlayer.SetContextThink( "Swarm.Cutscene", CutsceneBigBossIntro.bindenv(this), 0.0 );

	NetMsg.Start( "Swarm.CutsceneBigBossIntro" );
	NetMsg.Send( m_pBasePlayer, true );
}

function CPlayer::CutsceneBigBossIntro(_)
{
	local curtime = Time();
	if ( m_flCutsceneStartTime < curtime )
	{
		local t = ( curtime - m_flCutsceneStartTime ) / m_flCutsceneTransTime;

		local viewPos = m_hView.GetLocalOrigin();
		local targetPos;

		if ( m_bCutsceneIn )
		{
			targetPos = Swarm.m_hBigBoss.m_pEntity.GetLocalOrigin();

			if ( t >= 1.0 )
			{
				m_bCutsceneIn = false;
				m_flCutsceneStartTime = curtime + m_flCutsceneHoldTime;
			}
		}
		else
		{
			targetPos = m_vecViewPosition * 1;

			if ( t >= 1.0 )
			{
				m_fnCutsceneEndCallback();
				m_flCutsceneStartTime = 0.0;
				return -1;
			}
		}

		targetPos.z = viewPos.z;

		targetPos.Subtract( viewPos ).Multiply( VS.SmoothCurve(t) ).Add( viewPos );
		m_hView.SetLocalOrigin( targetPos );
	}

	return 0.0;
}
