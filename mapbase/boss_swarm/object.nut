//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//

local Swarm = this;
local Vector = Vector, SpawnEntityFromTable = SpawnEntityFromTable, atan2 = atan2,
	TraceHullComplex = TraceHullComplex;

local Convars = Convars;

local SUB_SetVisible = function( ent )
{
	// Entity might have been killed before it had time to become visible
	if ( ent )
		ent.SetRenderAlpha( 255 );
}

local spritekv =
{
	model = "swarm/projectile1.vmt",
	angles = Vector( 90, 0, 0 ),
	origin = Vector(),
	basevelocity = Vector(),
	scale = 1.0,
	framerate = 0.0,
	frame = 0.0
}

// NOTE: Using sprites are limiting for controlling draw order.
function SpriteCreate( sprite, scale = 1.0,
	movetype = MOVETYPE_NOCLIP, origin = vec3_origin, velocity = vec3_origin,
	mins = null, maxs = null )
{
	spritekv.model = sprite;
	spritekv.origin.Copy( origin );
	spritekv.basevelocity.Copy( velocity );
	spritekv.scale = scale;

	local p = SpawnEntityFromTable( "env_sprite", spritekv );

	// for debugging draw perf
	//local p;
	//{
	//	p = Entities.CreateByClassname( "info_null" );
	//	p.SetLocalOrigin( origin );
	//	p.SetVelocity( velocity );
	//	p.SetSolid( 0 );
	//}

	p.AddSolidFlags( FSOLID_NOT_SOLID );
	p.SetMoveType( movetype );

	if ( movetype == MOVETYPE_STEP )
	{
		p.AddFlag( FL_FLY );
	}

	// HACKHACK: The entity is stationary for 2 frames.
	// Keep it invisible during that time to give a smooth look.
	if ( velocity != vec3_origin )
	{
		p.SetRenderMode( 2 );
		p.SetRenderAlpha( 0 );
		p.SetContextThink( "vis", SUB_SetVisible, TICK_INTERVAL*3 );
	}

	if ( mins )
		p.SetSize( mins, maxs );

	return p;
}

class CItem
{
	m_nTeam = 0;
	m_ID = SwarmEquipment.None;
	m_iSlot = -1;
	m_hOwner = null;
	m_nRarity = 0;

	constructor( owner )
	{
		m_hOwner = owner;
	}

	Activate = dummy;
	Deactivate = dummy;
	NET_WriteData = dummy;
}

class CEntity
{
	m_nTeam = 0;
	m_pEntity = null;
	m_vecVelocity = null;
	m_vecPosition = null;
	m_vecAngles = null;
	m_vecForward = null;
	m_vecHullMins = null;
	m_vecHullMaxs = null;

	m_nHealth = 1;

	constructor()
	{
		m_vecVelocity = Vector();
		m_vecPosition = Vector();
		m_vecAngles = Vector( 90, 0, 0 );
		m_vecForward = Vector( 1, 0, 0 );
		m_vecHullMins = Vector();
		m_vecHullMaxs = Vector();
	}

	function Spawn()
	{
		ECHO_FUNC("3a");

		return m_pEntity.SetContextThink( "", Frame.bindenv(this), 0.0 );
	}

	//
	// Use m_pEntity.GetUpVector() instead of m_vecForward when parented!
	//
	// TODO: Maybe just use own transforms for convenience
	//
	function SetParent( pParent )
	{
		m_pEntity.SetParent( pParent, "" );
		m_vecAngles.x = 0.0;
	}

	function SetForward( forward )
	{
		m_vecForward.Copy( forward );
		m_vecAngles.y = atan2( forward.y, forward.x ) * RAD2DEG;
		return m_pEntity.SetLocalAngles( m_vecAngles );
	}

	function SetAngle( yaw )
	{
		m_vecAngles.y = yaw;
		VS.AngleVectors( m_vecAngles, m_vecForward );
		return m_pEntity.SetLocalAngles( m_vecAngles );
	}

	function RotateByAngle( dy )
	{
		local forward = m_vecForward;
		VS.VectorYawRotate( forward, dy, forward );
		m_vecAngles.y = atan2( forward.y, forward.x ) * RAD2DEG;
		return m_pEntity.SetLocalAngles( m_vecAngles );
	}

	function RotateBaseEntityByAngle( ent, dy )
	{
		local forward = ent.GetForwardVector();
		VS.VectorYawRotate( forward, dy, forward );
		return ent.SetLocalAngles( VS.VectorAngles( forward ) );
		return ent.SetForwardVector( forward );
	}

	function DebugDrawBBox()
	{
		if ( !Convars.GetInt("swarm_debugdraw") )
			return;

		local forward, right;

		if ( m_pEntity.GetMoveParent() )
		{
			forward = m_pEntity.GetUpVector();
			right = m_pEntity.GetRightVector();
		}
		else
		{
			forward = m_vecForward;
			right = forward.Cross( Vector(0,0,1) );
		}

		local org = m_vecPosition;
		debugoverlay.Line( org, org + forward * 12, 255, 0, 0, true, -1 );
		debugoverlay.Line( org, org + right * 12, 0, 255, 0, true, -1 );
		//debugoverlay.Box( org, m_vecHullMins, m_vecHullMaxs, 255, 255, 255, 2, -1 );
		return debugoverlay.Circle( org, Vector(0,1,0), Vector(1,0,0), m_vecHullMaxs.x, 255, 255, 255, 2, true, -1 );
	}

	function Frame( m_pEntity )
	{
		return 0.0;
	}

	Destroy = dummy;
	TakeProjectileDamage = dummy;
}

local s_nDepth = 0;

function CEntity::ResolveCollisions()
{
	if ( s_nDepth > 2 )
		printf( "[%s] [%d] collision resolution depth %d\n", ""+this GetFrameCount(), s_nDepth );

	if ( s_nDepth > 6 )
	{
		printf( "Entity%s is stuck!\n", ""+this );
		// TODO: unstuck
		return;
	}

	local vecNext = m_vecPosition + m_vecVelocity;

	local tr = TraceHullComplex( m_vecPosition, vecNext, m_vecHullMins, m_vecHullMaxs, m_pEntity, MASK_SOLID, COLLISION_GROUP_NONE );

	if ( tr.DidHit() )
	{
		local normal = tr.Plane().normal;

		m_vecPosition.Copy( tr.EndPos() );
		m_vecVelocity.Subtract( normal.Multiply( m_vecVelocity.Dot( normal ) ) );

		++s_nDepth;
		tr.Destroy();

		return ResolveCollisions();
	}

	s_nDepth = 0;
	tr.Destroy();

	m_vecPosition.Copy( vecNext );
	return m_pEntity.SetLocalOrigin( vecNext );
}
