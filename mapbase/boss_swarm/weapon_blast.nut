//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

if ( SERVER_DLL ){

local Swarm = this;
local Time = Time, RandomFloat = RandomFloat;

local SND_FIRE = "Weapon_AR2.NPC_Double";

PrecacheSoundScript( SND_FIRE );

const BLAST_RANGE = 256.0;
const RECHARGE_TIME = 10.0;

class CWeapon_Blast extends CBaseWeapon
{
	m_ID = SwarmEquipment.Blast;

	m_szSoundReloadEnd = "Weapon_AR2.Reload_Rotate";

	m_flProjectileSpeed = 0.0;
	m_flRefireTime = 0.0;
	m_nClip = 1;
	m_nMaxClip = 1;
	m_flReloadTime = RECHARGE_TIME;
	m_flRange = BLAST_RANGE;

	constructor( owner )
	{
		base.constructor( owner );
	}
}

function CWeapon_Blast::Attack2()
{
	local curtime = Time();
	if ( curtime < m_flNextAttackTime )
		return;

	m_flNextAttackTime = curtime + m_flRefireTime;

	// TODO: CSimpleProjectile::Destroy() doesn't have to remove itself from m_Projectiles immediately.
	local cache = [];
	local vecPosition = m_hOwner.m_vecPosition;
	local flRange = m_flRange;

	foreach ( projectile in Swarm.m_Projectiles )
	{
		local vecTarget = projectile.m_vecPosition;

		if ( projectile.m_nTeam != m_nTeam && vecPosition.DistTo( vecTarget ) < (flRange+projectile.m_flRadius) )
		{
			DispatchParticleEffect( "impact_metal", vecTarget, vec3_origin );
			cache.append( projectile );
		}
	}

	foreach ( projectile in cache )
	{
		projectile.Destroy();
	}

	// Yes, I'm using debugoverlay, what of it?
	debugoverlay.Circle( vecPosition, Vector(0,1,0), Vector(1,0,0), flRange, 10, 100, 255, 15, false, 0.1 );

	Swarm.PlaySound( SwarmSound.PlayerWeapon, SND_FIRE );

	if ( --m_nClip <= 0 )
	{
		return Reload();
	}
}

} // SERVER_DLL

if ( CLIENT_DLL ){

class CWeapon_Blast
{
	function NET_ReadDataIntoItem( item )
	{
		item.tooltip = format( "Deletes nearby projectiles\n\nCooldown %.2gs", RECHARGE_TIME );
	}
}

} // CLIENT_DLL

