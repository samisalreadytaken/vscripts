//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

local Swarm = this;
local Time = Time, NetMsg = NetMsg, Fmt = format, RandomFloat = RandomFloat, RandomInt = RandomInt;

if ( SERVER_DLL ){

class CItemSpeedBoost extends CItem
{
	m_ID = SwarmEquipment.SpeedBoost;
	m_nRarity = 1;

	constructor( owner )
	{
		m_hOwner = owner;
	}

	function Activate()
	{
		m_hOwner.m_MoveParams = Swarm.moveparam_t({ friction = 12.0, move = 12.0, maxspeed = 10.0 });
	}

	function Deactivate()
	{
		m_hOwner.m_MoveParams = m_hOwner.m_BaseMoveParams;
	}
}

class CItemPenetration extends CItem
{
	m_ID = SwarmEquipment.Penetration;

	m_pInstance = null;
	m_nAmount = 1;

	constructor( owner )
	{
		m_hOwner = owner;

		local chance = RandomFloat( 0.0, 1.0 );

		if ( chance < 0.01 )
		{
			m_nAmount = 3;
			m_nRarity = 3;
		}
		else if ( chance < 0.1 )
		{
			m_nAmount = 2;
			m_nRarity = 2;
		}
	}

	function Activate()
	{
		if ( m_hOwner.m_CurWeapon )
		{
			m_pInstance = m_hOwner.m_CurWeapon.weakref();
			m_hOwner.m_CurWeapon.m_nPenetration += m_nAmount;
			++m_hOwner.m_CurWeapon.m_Modifiers;
		}
	}

	function Deactivate()
	{
		if ( m_pInstance )
		{
			m_pInstance.m_nPenetration -= m_nAmount;
			--m_pInstance.m_Modifiers;
		}
	}

	function NET_WriteData()
	{
		NetMsg.WriteByte( m_nRarity );
		NetMsg.WriteByte( m_nAmount );
	}
}

class CItemShield extends CItem
{
	m_ID = SwarmEquipment.Shield;
	m_nRarity = 2;
	m_hShield = null;

	constructor( owner )
	{
		m_hOwner = owner;
	}

	function Activate()
	{
		m_hShield = Swarm.CShield( m_hOwner,
			m_hOwner.m_pEntity,
			m_hOwner.m_vecPosition + m_hOwner.m_vecForward * 32.0,
			m_hOwner.m_vecForward );
		m_hOwner.m_Shields.append( m_hShield );

		m_hShield.m_nMaxHealth = 6;
		m_hShield.m_nHealth = 6;
	}

	function Deactivate()
	{
		if ( m_hShield )
		{
			if ( m_hShield.m_nHealth > 0 )
			{
				m_hShield.Destroy();
			}

			local i = m_hOwner.m_Shields.find( m_hShield );
			if ( i != null )
				m_hOwner.m_Shields.remove( i );
		}
	}
}

class CItemExtraLife extends CItem
{
	m_ID = SwarmEquipment.ExtraLife;

	constructor( owner )
	{
		m_hOwner = owner;
	}

	function Activate()
	{
		m_hOwner.m_nMaxHealth += 3;
		m_hOwner.m_nHealth = m_hOwner.m_nMaxHealth;

		m_hOwner.UpdateClient();

		m_hOwner.m_pBasePlayer.SetHealth( m_hOwner.m_nHealth );
	}

	function Deactivate()
	{
		m_hOwner.m_nMaxHealth -= 3;
		m_hOwner.m_nHealth = m_hOwner.m_nMaxHealth;

		m_hOwner.UpdateClient();
		m_hOwner.m_pBasePlayer.SetHealth( m_hOwner.m_nHealth );
	}
}

class CItemDamageBoost extends CItem
{
	m_ID = SwarmEquipment.DamageBoost;

	m_pInstance = null;
	m_nAmount = 1;

	constructor( owner )
	{
		m_hOwner = owner;

		local chance = RandomFloat( 0.0, 1.0 );

		if ( chance < 0.005 )
		{
			m_nAmount = 4;
			m_nRarity = 3;
		}
		else if ( chance < 0.01 )
		{
			m_nAmount = 3;
			m_nRarity = 2;
		}
		else if ( chance < 0.3 )
		{
			m_nAmount = 2;
			m_nRarity = 1;
		}
	}

	function Activate()
	{
		if ( m_hOwner.m_CurWeapon )
		{
			m_pInstance = m_hOwner.m_CurWeapon.weakref();
			m_hOwner.m_CurWeapon.m_nDamage += m_nAmount;
			++m_hOwner.m_CurWeapon.m_Modifiers;
		}
	}

	function Deactivate()
	{
		if ( m_pInstance )
		{
			m_pInstance.m_nDamage -= m_nAmount;
			--m_pInstance.m_Modifiers;
		}
	}

	function NET_WriteData()
	{
		NetMsg.WriteByte( m_nRarity );
		NetMsg.WriteByte( m_nAmount );
	}
}

class CItemFastShoot extends CItem
{
	m_ID = SwarmEquipment.FastShoot;

	m_pInstance = null;
	m_flMultiplier = 0.0;
	m_flAmount = 0.0;

	constructor( owner )
	{
		m_hOwner = owner;
		m_flMultiplier = RandomFloat( 0.1, 0.75 );

		if ( m_flMultiplier > 0.65 )
		{
			m_nRarity = 2;
		}
		else if ( m_flMultiplier > 0.5 )
		{
			m_nRarity = 1;
		}
	}

	function Activate()
	{
		if ( m_hOwner.m_CurWeapon )
		{
			m_pInstance = m_hOwner.m_CurWeapon.weakref();
			m_flAmount = m_hOwner.m_CurWeapon.m_flRefireTime * m_flMultiplier;
			m_hOwner.m_CurWeapon.m_flRefireTime -= m_flAmount;
			++m_hOwner.m_CurWeapon.m_Modifiers;
		}
	}

	function Deactivate()
	{
		if ( m_pInstance )
		{
			m_pInstance.m_flRefireTime += m_flAmount;
			--m_pInstance.m_Modifiers;
		}
	}

	function NET_WriteData()
	{
		NetMsg.WriteByte( m_nRarity );
		NetMsg.WriteByte( m_flMultiplier * 100.0 );
	}
}

class CItemNoReload extends CItem
{
	m_ID = SwarmEquipment.NoReload;

	m_nRarity = 1;
	m_pInstance = null;

	constructor( owner )
	{
		m_hOwner = owner;
	}

	function Activate()
	{
		if ( m_hOwner.m_CurWeapon )
		{
			m_pInstance = m_hOwner.m_CurWeapon.weakref();
			// HACKHACK:
			m_hOwner.m_CurWeapon.m_nClip = INT_MAX;
			++m_hOwner.m_CurWeapon.m_Modifiers;
		}
	}

	function Deactivate()
	{
		if ( m_pInstance )
		{
			m_pInstance.m_nClip = m_pInstance.getclass().m_nClip;
			--m_pInstance.m_Modifiers;
		}
	}
}

} // SERVER_DLL

if ( CLIENT_DLL ){

class CItemSpeedBoost
{
	m_ID = SwarmEquipment.SpeedBoost;

	function NET_ReadDataIntoItem( item )
	{
		item.rarity = 1;
		item.tooltip = "movement speed boost";
	}
}

class CItemPenetration
{
	m_ID = SwarmEquipment.Penetration;

	function NET_ReadDataIntoItem( item )
	{
		item.rarity = NetMsg.ReadByte();
		item.tooltip = Fmt( "+%d bullet penetration", NetMsg.ReadByte() );
	}
}

class CItemShield
{
	m_ID = SwarmEquipment.Shield;

	function NET_ReadDataIntoItem( item )
	{
		item.rarity = 2;
		item.tooltip = "+1 shield";
	}
}

class CItemExtraLife
{
	m_ID = SwarmEquipment.ExtraLife;

	function NET_ReadDataIntoItem( item )
	{
		item.tooltip = "+3 health";
	}
}

class CItemDamageBoost
{
	m_ID = SwarmEquipment.DamageBoost;

	function NET_ReadDataIntoItem( item )
	{
		item.rarity = NetMsg.ReadByte();
		item.tooltip = Fmt( "+%d weapon damage", NetMsg.ReadByte() );
	}
}

class CItemFastShoot
{
	m_ID = SwarmEquipment.FastShoot;

	function NET_ReadDataIntoItem( item )
	{
		item.rarity = NetMsg.ReadByte();
		item.tooltip = Fmt( "+%d percent faster shooting", NetMsg.ReadByte() );
	}
}

class CItemNoReload
{
	m_ID = SwarmEquipment.NoReload;

	function NET_ReadDataIntoItem( item )
	{
		item.tooltip = "no weapon reload";
	}
}

} // CLIENT_DLL
