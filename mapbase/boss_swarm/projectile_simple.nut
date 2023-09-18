//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

if ( "CSimpleProjectile" in this )
	return;

local Swarm = this;
local Vector = Vector, array = array,
	TraceLineComplex = TraceLineComplex, DispatchParticleEffect = DispatchParticleEffect;

PrecacheModel( "swarm/projectile2.vmt" );
PrecacheParticleSystem( "impact_metal" );

class CSimpleProjectile extends CEntity
{
	m_flLifeTime = 2.0;
	m_flRadius = 4.0;
	m_nDamage = 1;
	m_iMaxHits = 1;
	m_flInitVel = 0.0;
	m_iHits = 0;
	m_PreviousHits = null;
}

function CSimpleProjectile::constructor( ownerWeapon, position, velocity )
{
	Swarm.m_Projectiles.append( this );

	m_vecPosition = Vector().Copy( position );

	m_nTeam = ownerWeapon.m_nTeam;
	m_iMaxHits = ownerWeapon.m_nPenetration;
	m_nDamage = ownerWeapon.m_nDamage;

	m_PreviousHits = array( m_iMaxHits );

	m_flInitVel = velocity.LengthSqr();

	local ent = m_pEntity = Swarm.SpriteCreate( "swarm/projectile2.vmt", 0.15,
			MOVETYPE_FLY, position, velocity,
			Vector( -2, -2, 0 ), Vector( 2, 2, 2 ) );

	ent.SetContextThink( "Expire", ExpireThink.bindenv(this), m_flLifeTime );

	return Spawn();
}

function CSimpleProjectile::ExpireThink( m_pEntity )
{
	// HACKHACK: just glueing everything together in the last day
	if ( !this )
		return;

	DispatchParticleEffect( "impact_metal", m_vecPosition, vec3_origin );
	Destroy();
}

function CSimpleProjectile::Destroy()
{
	Swarm.m_Projectiles.remove( Swarm.m_Projectiles.find( this ) );

	m_pEntity.SetContextThink( "", null, 0.0 );
	m_pEntity.SetContextThink( "Expire", null, 0.0 );
	return m_pEntity.Destroy();
}

//
// TODO: Lose damage after penetration.
//
function CSimpleProjectile::Frame( m_pEntity )
{
	local pos = m_pEntity.GetLocalOrigin();
	local radius = m_flRadius;
	//local damage = m_flDamage;
	local penetration = m_iMaxHits;
	local team = m_nTeam;

	//debugoverlay.Circle( pos, Vector(0,1,0), Vector(1,0,0), radius, 255, 255, 255, 0, true, -1 );

	foreach ( obj in Swarm.m_HurtableEntities )
	{
		if ( ( obj.m_nTeam != team ) &&
			( obj.m_vecPosition.DistTo( pos ) < (radius+obj.m_vecHullMaxs.x) ) &&
			( ( penetration == 1 ) || (m_PreviousHits.find(obj) == null) ) )
		{
			// HACKHACK: Yes, this is horrible I know. But I'm out of time.
			if ( team == 1 )
			{
				local player = Swarm.m_Players[0].m_pBasePlayer;
				SteamAchievements.IncrementStat( player, "ACH_MANY_DAMAGE", 1 );
				local stat = SteamAchievements.GetStat( player, "ACH_MANY_DAMAGE" );
				if ( (stat % 2000) == 0 )
				{
					SteamAchievements.IndicateAchievementProgress( player, "ACH_MANY_DAMAGE" );
				}
			}

			obj.TakeProjectileDamage( this );

			m_PreviousHits[m_iHits] = obj;

			if ( ++m_iHits >= penetration )
			{
				Destroy();
				return -1;
			}
		}
	}

	local vel = m_pEntity.GetVelocity();
	if ( vel.LengthSqr() < m_flInitVel )
	{
		// Impact particle effect

		// Position delta will be 0 when projectiles are destroyed in the frame they are spawned,
		// causing incorrect particle positioning.
		// I _could_ fix this by keeping track of more elements, but it's not worth it.
		if ( pos.IsEqualTo( m_vecPosition ) )
		{
			Destroy();
			return -1;
		}

		// vecDelta
		pos.Subtract( m_vecPosition );
		pos.Norm();
		pos.Multiply( MAX_COORD_FLOAT );

		local tr = TraceLineComplex( m_vecPosition, pos, m_pEntity, MASK_SOLID, COLLISION_GROUP_NONE );
		local endpos = tr.EndPos();
		local normal = tr.Plane().normal;

		DispatchParticleEffect( "impact_metal", endpos, VS.VectorAngles( normal ) );

		tr.Destroy();
		Destroy();
		return -1;
	}

	m_vecPosition.Copy( pos );

	return 0.0;
}
