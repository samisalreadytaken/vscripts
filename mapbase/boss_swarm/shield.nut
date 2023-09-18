//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

if ( "CShield" in this )
	return;

local Swarm = this;
local Time = Time;

PrecacheModel( "swarm/shield3.vmt" );

local SUB_RestoreColour = function( ent )
{
	if ( ent )
		ent.SetRenderColor( 0, 120, 255 );
}

class CShield extends CEntity
{
	m_hOwner = null;
	m_nMaxHealth = 30;
	m_nHealth = 30;
}

function CShield::constructor( owner, pParent, position, forward )
{
	base.constructor();

	m_hOwner = owner;
	m_nTeam = owner.m_nTeam;

	Swarm.m_HurtableEntities.append( this );

	position.z = 0.0;
	m_vecPosition.Copy( position );
	m_vecHullMins.Init( -16, -16, 0 );
	m_vecHullMaxs.Init( 16, 16, 4 );

	m_pEntity = Swarm.SpriteCreate( "swarm/shield3.vmt", 0.5,
		MOVETYPE_NONE, position, vec3_origin,
		m_vecHullMins, m_vecHullMaxs );

	m_pEntity.SetRenderColor( 0, 120, 255 );

	SetForward( forward );
	SetParent( pParent );

	return Spawn();
}

function CShield::Frame(_)
{
	m_vecPosition.Copy( m_pEntity.GetOrigin() );
	DebugDrawBBox();
	return 0.0;
}

function CShield::Destroy()
{
	local x = Swarm.m_HurtableEntities.find( this );
	if ( x != null )
		Swarm.m_HurtableEntities.remove( x );
	m_pEntity.SetContextThink( "", null, 0.0 );
	return m_pEntity.Destroy();
}

function CShield::TakeProjectileDamage( projectile )
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
