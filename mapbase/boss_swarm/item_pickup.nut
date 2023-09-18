//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

local Swarm = this;

class CItemPickup extends CEntity
{
	m_szPickupSound = "";
	m_flRadius = 8.0;
	m_Item = null;
}

function CItemPickup::constructor( position, item, material )
{
	base.constructor();

	position.z = 0.0;
	m_vecPosition.Copy( position );
	m_vecHullMins.Init( -m_flRadius, -m_flRadius, 0 );
	m_vecHullMaxs.Init( m_flRadius, m_flRadius, 4 );

	m_pEntity = Swarm.SpriteCreate( material, 1.0,
		MOVETYPE_NONE, position, vec3_origin,
		m_vecHullMins, m_vecHullMaxs );

	m_Item = item;

	return Spawn();
}

function CItemPickup::OnTouch( player )
{
	//player.EquipItem( item );
	m_Item.ActivateOn( player );
	m_pEntity.EmitSound( m_szPickupSound );
	return Destroy();
}

function CItemPickup::Frame(_)
{
	foreach ( player in Swarm.m_Players )
	{
		if ( m_vecPosition.DistTo( player.m_vecPosition ) < (m_flRadius+player.m_vecHullMaxs.x) )
		{
			OnTouch( player );
			return -1;
		}
	}

	DebugDrawBBox();
	return 0.0;
}

function CItemPickup::Destroy()
{
	local x = Swarm.m_Pickups.find( this );
	if ( x != null )
		Swarm.m_Pickups.remove( x );
	m_pEntity.SetContextThink( "", null, 0.0 );
	return m_pEntity.Destroy();
}
