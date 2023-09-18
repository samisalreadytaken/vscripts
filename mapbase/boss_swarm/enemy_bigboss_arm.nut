//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

if ( "CBossArm" in this )
	return;

local Swarm = this;
local Time = Time, RandomFloat = RandomFloat;

local SND_FIRE = "GenericNPC.GunSound";
local SND_FIRE2 = "GenericNPC.GunSound";
local SND_FIRE3 = "Grenade.Blip";

PrecacheSoundScript( SND_FIRE );
PrecacheSoundScript( SND_FIRE2 );
PrecacheSoundScript( SND_FIRE3 );


local CProjectile = class extends CSimpleProjectile
{
	m_flLifeTime = 10.0;
}

PrecacheModel( "swarm/bossarm.vmt" );

local SUB_RestoreColour = function( ent )
{
	if ( ent )
		ent.SetRenderColor( 255, 120, 0 );
}

class CBossArm extends CEntity
{
	m_index = -1;
	m_nTeam = 2;

	m_nHealth = 100;

	m_hOwner = null;
	m_bIdle = false;
	m_nCurAttack = 0;
	m_flNextAttackTime = 0.0;
	m_flRefireTime = 0.0;
	m_flProjectileSpeed = 180.0;

	// CBaseWeapon (for CSimpleProjectile)
	m_nPenetration = 1;
	m_nDamage = 1;
}

//
// NOTE: Using game's parenting instead of keeping track of own transforms
// so that all arms can be easily rotated at once by rotating the parent.
//
function CBossArm::constructor( hParent, position, forward )
{
	base.constructor();

	m_hOwner = hParent;
	++m_hOwner.m_nArmCount;

	Swarm.m_HurtableEntities.append( this );

	position.z = 0.0;
	m_vecPosition.Copy( position );
	m_vecHullMins.Init( -16, -16, 0 );
	m_vecHullMaxs.Init( 16, 16, 4 );

	m_pEntity = Swarm.SpriteCreate( "swarm/bossarm.vmt", 0.5,
		MOVETYPE_NONE, position, vec3_origin,
		m_vecHullMins, m_vecHullMaxs );

	m_pEntity.SetRenderColor( 255, 120, 0 );

	SetForward( forward );
	SetParent( hParent.m_pEntity );

	return Spawn();
}

function CBossArm::Destroy()
{
	--m_hOwner.m_nArmCount;
	local x = Swarm.m_HurtableEntities.find( this );
	if ( x != null )
		Swarm.m_HurtableEntities.remove( x );
	m_pEntity.SetContextThink( "", null, 0.0 );
	return m_pEntity.Destroy();
}

local sqrt = sqrt;

class CHomingProjectile extends CSimpleProjectile
{
	m_flLifeTime = 2.5;

	constructor( ownerWeapon, position, velocity )
	{
		base.constructor( ownerWeapon, position, velocity );
		m_pEntity.SetContextThink( "Nudge", NudgeThink.bindenv(this), 0.0 );

		m_flInitVel = sqrt(m_flInitVel);
	}

	function Destroy()
	{
		m_pEntity.SetContextThink( "Nudge", null, 0.0 );
		return base.Destroy();
	}

	function NudgeThink( m_pEntity )
	{
		local vecTarget = Swarm.m_Players[0].m_vecPosition;
		local vecDelta = vecTarget - m_vecPosition;

		local vel = m_pEntity.GetVelocity();
		local dot = vel.Dot( vecDelta );
		vecDelta.Norm();
		vel.Norm();
		vel.Add( vecDelta.Multiply( 0.75 ) );
		vel.Multiply( m_flInitVel );
		m_pEntity.SetVelocity( vel );

		return 0.15;
	}

	// Copied from CSimpleProjectile with velocity check removed so the weapons
	// on the opposite side to the player can shoot as well.
	// Life time is relied on to kill these projectiles
	function Frame( m_pEntity )
	{
		local pos = m_pEntity.GetLocalOrigin();
		local radius = m_flRadius;
		local penetration = m_iMaxHits;
		local team = m_nTeam;

		foreach ( obj in Swarm.m_HurtableEntities )
		{
			if ( ( obj.m_nTeam != team ) &&
				( obj.m_vecPosition.DistTo( pos ) < (radius+obj.m_vecHullMaxs.x) ) &&
				( ( penetration == 1 ) || (m_PreviousHits.find(obj) == null) ) )
			{
				obj.TakeProjectileDamage( this );

				m_PreviousHits[m_iHits] = obj;

				if ( ++m_iHits >= penetration )
				{
					Destroy();
					return -1;
				}
			}
		}

		m_vecPosition.Copy( pos );

		return 0.0;
	}
}

local CHomingProjectile = CHomingProjectile;

function CBossArm::Frame( m_pEntity )
{
	m_vecPosition.Copy( m_pEntity.GetOrigin() );

	if ( m_bIdle )
		return 0.0;

	local curtime = Time();

	switch ( m_nCurAttack )
	{
		// Basic
		case ArmAttack.Type1:
		{
			if ( m_flNextAttackTime <= curtime )
			{
				m_flNextAttackTime = curtime + m_flRefireTime;

				local attackDir = m_pEntity.GetUpVector();
				attackDir.Multiply( m_flProjectileSpeed );

				local shootPos = m_vecPosition;
				CProjectile( this, shootPos, attackDir );
				Swarm.PlaySound( SwarmSound.BossWeapon, SND_FIRE );
			}
			break;
		}
		// Homing projectiles
		case ArmAttack.Type2:
		{
			if ( m_flNextAttackTime <= curtime )
			{
				m_flNextAttackTime = curtime + m_flRefireTime;

				local attackDir = m_pEntity.GetUpVector();
				attackDir.Multiply( m_flProjectileSpeed );

				local shootPos = m_vecPosition;
				CHomingProjectile( this, shootPos, attackDir );
				Swarm.PlaySound( SwarmSound.BossWeapon, SND_FIRE2 );
			}
			break;
		}
		// Identical to Type1 but with SND_FIRE3 fire sound and 10% slower projectiles
		case ArmAttack.Type3:
		{
			if ( m_flNextAttackTime <= curtime )
			{
				m_flNextAttackTime = curtime + m_flRefireTime;

				local attackDir = m_pEntity.GetUpVector();
				attackDir.Multiply( m_flProjectileSpeed * 0.9 );

				local shootPos = m_vecPosition;
				CProjectile( this, shootPos, attackDir );
				Swarm.PlaySound( SwarmSound.BossWeapon, SND_FIRE3 );
			}
			break;
		}
	}

	DebugDrawBBox();

	return 0.0;
}

function CBossArm::TakeProjectileDamage( projectile )
{
	m_nHealth -= projectile.m_nDamage;

	if ( m_nHealth < 0 )
		m_nHealth = 0;

	m_hOwner.UpdateHealthStats();

	m_pEntity.SetRenderColor( 255, 255, 255 );
	m_pEntity.SetContextThink( "RestoreColour", SUB_RestoreColour, 0.2 );

	if ( m_nHealth == 0 )
	{
		Destroy();
	}
}
