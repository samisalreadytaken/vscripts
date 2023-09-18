//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

if ( "CBaseWeapon" in this )
	return;

local Swarm = this;
local Time = Time, NetMsg = NetMsg;

class CBaseWeapon extends CItem
{
	m_flProjectileSpeed = 0.0;
	m_flRefireTime = 0.0;
	m_nClip = 0;
	m_nAmmo = -1;
	m_nMaxClip = 0;
	m_flReloadTime = 1.0;

	m_nPenetration = 1;
	m_nDamage = 1;

	m_vecShootPosition = null;
	m_flNextAttackTime = 0.0;
	m_bInReload = false;
	m_szSoundReload = "";
	m_szSoundReloadEnd = "";

	m_Modifiers = 0;

	constructor( owner )
	{
		m_hOwner = owner;
		m_nTeam = owner.m_nTeam;
	}

	Attack = dummy;
}

function CBaseWeapon::CheckReload()
{
	//Assert( m_bInReload );

	local curtime = Time();
	if ( curtime < m_flNextAttackTime )
		return;

	m_bInReload = false;

	m_flNextAttackTime = curtime;

	if ( m_nAmmo != -1 )
	{
		local clip = min( m_nMaxClip - m_nClip, m_nAmmo );
		m_nAmmo -= m_nClip = clip;
	}
	else
	{
		m_nClip = m_nMaxClip;
	}

	return Swarm.PlaySound( SwarmSound.PlayerWeapon, m_szSoundReloadEnd );
}

function CBaseWeapon::Reload()
{
	//Assert( !m_bInReload );

	m_bInReload = true;
	local curtime = Time();
	m_flNextAttackTime = curtime + m_flReloadTime;

	NetMsg.Start( "Swarm.CPlayer.Reload" );
		NetMsg.WriteByte( m_iSlot );
		NetMsg.WriteFloat( m_flReloadTime );
	NetMsg.Send( m_hOwner.m_pBasePlayer, true );

	return Swarm.PlaySound( SwarmSound.PlayerWeapon, m_szSoundReload );
}
