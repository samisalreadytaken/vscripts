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
	m_flLifeTime = 5.0;
}

class CWeapon_Basic extends CBaseWeapon
{
	CProjectile = CProjectile;

	m_ID = SwarmEquipment.BasicGun;

	m_szSoundReload = "Weapon_357.RemoveLoader";
	m_szSoundReloadEnd = "Weapon_Shotgun.Special1";

	m_flProjectileSpeed = 250.0;
	m_flRefireTime = 0.175;
	m_flReloadTime = 1.0;
	m_nClip = 12;
	m_nAmmo = -1;
	m_nMaxClip = 12;

	constructor( owner )
	{
		base.constructor( owner );
	}
}

function CWeapon_Basic::Attack()
{
	local curtime = Time();
	if ( curtime < m_flNextAttackTime )
		return;

	if ( m_nClip <= 0 )
	{
		m_flNextAttackTime = curtime + m_flRefireTime * 0.5;
		return Swarm.PlaySound( SwarmSound.PlayerWeapon, SND_EMPTY );
	}

	m_flNextAttackTime = curtime + m_flRefireTime;

	Swarm.PlaySound( SwarmSound.PlayerWeapon, SND_FIRE );

	local attackDir = m_hOwner.m_vecForward * 1;
	attackDir.x += RandomFloat( -0.25, 0.25 );
	attackDir.y += RandomFloat( -0.25, 0.25 );
	attackDir.Norm();
	attackDir.Multiply( m_flProjectileSpeed );

	local shootPos = ( m_hOwner.m_vecForward * 32.0 ).Add( m_hOwner.m_vecPosition );
	CProjectile( this, shootPos, attackDir );

	if ( --m_nClip == 0 )
	{
		if ( m_nAmmo )
		{
			return Reload();
		}
	}
}

function CWeapon_Basic::NET_WriteData()
{
	NetMsg.WriteByte( m_nDamage );
	NetMsg.WriteByte( m_nPenetration );
	NetMsg.WriteFloat( m_flProjectileSpeed );
	NetMsg.WriteFloat( m_flRefireTime );
}

} // SERVER_DLL

if ( CLIENT_DLL ){

class CWeapon_Basic
{
	function NET_ReadDataIntoItem( item )
	{
		local damage = NetMsg.ReadByte();
		local penetration = NetMsg.ReadByte();
		local speed = NetMsg.ReadFloat();
		local refire = NetMsg.ReadFloat();
		item.tooltip = format( "Pistol\nDMG: %d\nPEN: %d\nSPD: %.4g\nTRG: %.4g\n",
			damage, penetration, speed, refire );
	}
}

} // CLIENT_DLL
