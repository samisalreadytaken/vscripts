//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

if ( SERVER_DLL ){

IncludeScript( "boss_swarm/projectile_simple.nut", this );

local Swarm = this;
local Time = Time, RandomFloat = RandomFloat;

local SND_FIRE = "Weapon_AR2.NPC_Single";
local SND_EMPTY = "Weapon_AR2.Empty";

PrecacheSoundScript( SND_FIRE );

local CProjectile = class extends CSimpleProjectile
{
	m_flLifeTime = 2.0;
}

class CWeapon_BurstGun extends CBaseWeapon
{
	CProjectile = CProjectile;

	m_ID = SwarmEquipment.BurstGun;

	m_szSoundReload = "Weapon_AR2.NPC_Reload";
	m_szSoundReloadEnd = "Weapon_Shotgun.Special1";

	m_nDamage = CSimpleProjectile.m_nDamage + 1;
	m_flProjectileSpeed = 420.0;
	m_flRefireTime = 0.5;
	m_flBurstRefireTime = 0.05;
	m_flReloadTime = 1.75;
	m_nMaxBurstShots = 3;

	m_nClip = 21;
	m_nAmmo = -1;
	m_nMaxClip = 21;

	m_flNextBurstTime = 0.0;
	m_nBurstShots = 0;

	constructor( owner )
	{
		base.constructor( owner );
	}

	function Activate()
	{
		return m_hOwner.m_pBasePlayer.SetContextThink( "WeaponFrame", Frame.bindenv(this), 0.0 );
	}

	function Deactivate()
	{
		return m_hOwner.m_pBasePlayer.SetContextThink( "WeaponFrame", null, 0.0 );
	}
}

function CWeapon_BurstGun::Frame( _ )
{
	if ( !this ) // HACKHACK: lol. weapon was freed but player is still thinking of it.
		return -1;

	if ( m_nBurstShots )
	{
		local curtime = Time();
		if ( curtime < m_flNextBurstTime )
			return 0.0;

		if ( ++m_nBurstShots == m_nMaxBurstShots )
		{
			m_flNextBurstTime = 0.0;
			m_nBurstShots = 0;
			m_flNextAttackTime = curtime + m_flRefireTime;
		}
		else
		{
			m_flNextBurstTime = curtime + m_flBurstRefireTime;
		}

		local shootPos = ( m_hOwner.m_vecForward * 32.0 ).Add( m_hOwner.m_vecPosition );
		local attackDir = m_hOwner.m_vecForward * m_flProjectileSpeed;
		attackDir.x += RandomFloat( -15.0, 15.0 );
		attackDir.y += RandomFloat( -15.0, 15.0 );
		CProjectile( this, shootPos, attackDir );
		Swarm.PlaySound( SwarmSound.PlayerWeapon, SND_FIRE );

		if ( --m_nClip == 0 )
		{
			if ( m_nAmmo )
			{
				Reload();
			}
		}
	}

	return 0.0;
}

function CWeapon_BurstGun::Attack()
{
	if ( m_nBurstShots )
		return;

	local curtime = Time();
	if ( curtime < m_flNextAttackTime )
		return;

	if ( m_nClip <= 0 )
	{
		m_flNextAttackTime = curtime + m_flRefireTime * 0.5;
		return Swarm.PlaySound( SwarmSound.PlayerWeapon, SND_EMPTY );
	}

	local shootPos = ( m_hOwner.m_vecForward * 32.0 ).Add( m_hOwner.m_vecPosition );
	local attackDir = m_hOwner.m_vecForward * 1;
	attackDir.x += RandomFloat( -0.1, 0.1 );
	attackDir.y += RandomFloat( -0.1, 0.1 );
	attackDir.Norm();
	attackDir.Multiply( m_flProjectileSpeed );

	CProjectile( this, shootPos, attackDir );

	Swarm.PlaySound( SwarmSound.PlayerWeapon, SND_FIRE );

	if ( --m_nClip == 0 )
	{
		if ( m_nAmmo )
		{
			return Reload();
		}
	}
	else
	{
		m_flNextBurstTime = curtime + m_flBurstRefireTime;
		++m_nBurstShots;
	}
}

function CWeapon_BurstGun::NET_WriteData()
{
	NetMsg.WriteByte( m_nDamage );
	NetMsg.WriteByte( m_nPenetration );
	NetMsg.WriteFloat( m_flProjectileSpeed );
	NetMsg.WriteFloat( m_flBurstRefireTime );
}

} // SERVER_DLL

if ( CLIENT_DLL ){

class CWeapon_BurstGun
{
	function NET_ReadDataIntoItem( item )
	{
		local damage = NetMsg.ReadByte();
		local penetration = NetMsg.ReadByte();
		local speed = NetMsg.ReadFloat();
		local refire = NetMsg.ReadFloat();
		item.tooltip = format( "Burstgun\nDMG: %d\nPEN: %d\nSPD: %.4g\nTRG: %.4g\n",
			damage, penetration, speed, refire );
	}
}

} // CLIENT_DLL
