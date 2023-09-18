//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

if ( SERVER_DLL ){

IncludeScript( "boss_swarm/projectile_simple.nut", this );

local Swarm = this;
local Time = Time, RandomFloat = RandomFloat;

local SND_FIRE = "Weapon_AR2.NPC_Single";

PrecacheSoundScript( SND_FIRE );

local CProjectile = class extends CSimpleProjectile
{
	m_flLifeTime = 2.0;
}

class CWeapon_Shotgun extends CBaseWeapon
{
	CProjectile = CProjectile;

	m_ID = SwarmEquipment.Shotgun;

	m_szSoundReload = "Weapon_357.RemoveLoader";
	m_szSoundReloadEnd = "Weapon_Shotgun.Special1";

	m_flProjectileSpeed = 200.0;
	m_flRefireTime = 0.75;
	m_nClip = 6;
	m_nMaxClip = 6;
	m_flReloadTime = 2.25;

	constructor( owner )
	{
		base.constructor( owner );
	}
}

function CWeapon_Shotgun::Attack()
{
	local curtime = Time();
	if ( curtime < m_flNextAttackTime )
		return;

	m_flNextAttackTime = curtime + m_flRefireTime;

	local shootPos = ( m_hOwner.m_vecForward * 32.0 ).Add( m_hOwner.m_vecPosition );

	local v = Vector( RandomFloat( -12.0, 12.0 ), RandomFloat( -12.0, 12.0 ) );
	shootPos.Copy( v.Add( shootPos ) );
	shootPos.z = 0.0;

	local attackDir = VS.VectorYawRotate( m_hOwner.m_vecForward, RandomFloat( -10.0, 10.0 ) ) * 1;
	CProjectile( this, shootPos, attackDir.Multiply( m_flProjectileSpeed ) );

	v = Vector( RandomFloat( -12.0, 12.0 ), RandomFloat( -12.0, 12.0 ) );
	shootPos.Copy( v.Add( shootPos ) );
	shootPos.z = 0.0;
	attackDir = VS.VectorYawRotate( m_hOwner.m_vecForward, RandomFloat( -10.0, 10.0 ) ) * 1;
	CProjectile( this, shootPos, attackDir.Multiply( m_flProjectileSpeed ) );

	v = Vector( RandomFloat( -12.0, 12.0 ), RandomFloat( -12.0, 12.0 ) );
	shootPos.Copy( v.Add( shootPos ) );
	shootPos.z = 0.0;
	attackDir = VS.VectorYawRotate( m_hOwner.m_vecForward, RandomFloat( -10.0, 10.0 ) ) * 1;
	CProjectile( this, shootPos, attackDir.Multiply( m_flProjectileSpeed ) );

	v = Vector( RandomFloat( -12.0, 12.0 ), RandomFloat( -12.0, 12.0 ) );
	shootPos.Copy( v.Add( shootPos ) );
	shootPos.z = 0.0;
	attackDir = VS.VectorYawRotate( m_hOwner.m_vecForward, RandomFloat( -10.0, 10.0 ) ) * 1;
	CProjectile( this, shootPos, attackDir.Multiply( m_flProjectileSpeed ) );

	v = Vector( RandomFloat( -12.0, 12.0 ), RandomFloat( -12.0, 12.0 ) );
	shootPos.Copy( v.Add( shootPos ) );
	shootPos.z = 0.0;
	attackDir = VS.VectorYawRotate( m_hOwner.m_vecForward, RandomFloat( -10.0, 10.0 ) ) * 1;
	CProjectile( this, shootPos, attackDir.Multiply( m_flProjectileSpeed ) );

	Swarm.PlaySound( SwarmSound.PlayerWeapon, SND_FIRE );
	Swarm.PlaySound( SwarmSound.PlayerWeapon, SND_FIRE );

	if ( --m_nClip == 0 )
	{
		if ( m_nAmmo )
		{
			return Reload();
		}
	}
}

function CWeapon_Shotgun::NET_WriteData()
{
	NetMsg.WriteByte( m_nDamage );
	NetMsg.WriteByte( m_nPenetration );
	NetMsg.WriteFloat( m_flProjectileSpeed );
	NetMsg.WriteFloat( m_flRefireTime );
}

} // SERVER_DLL

if ( CLIENT_DLL ){

class CWeapon_Shotgun
{
	function NET_ReadDataIntoItem( item )
	{
		local damage = NetMsg.ReadByte();
		local penetration = NetMsg.ReadByte();
		local speed = NetMsg.ReadFloat();
		local refire = NetMsg.ReadFloat();
		item.tooltip = format( "Shotgun\nDMG: %d\nPEN: %d\nSPD: %.4g\nTRG: %.4g\n",
			damage, penetration, speed, refire );
	}
}

} // CLIENT_DLL
