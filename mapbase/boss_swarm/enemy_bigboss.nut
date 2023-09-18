//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//

enum ArmAttack
{
	None,
	Type1,
	Type2,
	Type3,
}

IncludeScript( "boss_swarm/projectile_simple.nut", this );
IncludeScript( "boss_swarm/shield.nut", this );
IncludeScript( "boss_swarm/enemy_bigboss_arm.nut", this );

local Swarm = this;
local Time = Time, NetMsg = NetMsg, RandomFloat = RandomFloat;

PrecacheModel( "swarm/boss1.vmt" );

local SUB_RestoreColour = function( ent )
{
	if ( ent )
		ent.SetRenderColor( 255, 0, 0 );
}

class CBigBoss extends CEntity
{
	CBossArm = CBossArm;
	CShield = CShield;

	m_nHealth = 500;
	m_flTotalHealth = 0.0;
	m_flTotalShield = 0.0;
	m_flCurHealth = 0.0;
	m_flCurShield = 0.0;

	m_nTeam = 2;

	m_flRotation = 0.0;

	m_pShieldRotator = null;

	m_Shields = null;
	m_Arms = null;
	m_nArmCount = 0;

	m_attack = 0;
	m_stage = 0;
	m_fnAttack = null;
}

function CBigBoss::constructor( position )
{
	base.constructor();

	Swarm.m_HurtableEntities.append( this );

	m_Shields = [];
	m_Arms = [];

	position.z = 0.0;
	m_vecPosition.Copy( position );
	m_vecHullMins.Init( -50, -50, 0 );
	m_vecHullMaxs.Init( 50, 50, 4 );

	m_pEntity = Swarm.SpriteCreate( "swarm/boss1.vmt", 0.9,
		MOVETYPE_FLY, position, vec3_origin,
		m_vecHullMins, m_vecHullMaxs );

	m_pEntity.SetSolid( 2 );
	m_pEntity.RemoveSolidFlags( FSOLID_NOT_SOLID );
	m_pEntity.SetRenderColor( 255, 0, 0 );

	m_pShieldRotator = Entities.CreateByClassname( "info_null" );
	//m_pShieldRotator.SetParent( m_pEntity, "" );
	m_pShieldRotator.SetLocalOrigin( position );
	m_pShieldRotator.SetLocalAngles( vec3_origin );
	m_pShieldRotator.SetMoveType( MOVETYPE_NOCLIP );

	for ( local ang = 0.0; ang < 360.0; ang += 30.0 )
	{
		local dir = VS.VectorYawRotate( m_vecForward, ang );
		local obj = CShield( this, m_pShieldRotator, position + dir * 70, dir );
		m_Shields.append( obj );
		m_flTotalShield += obj.m_nHealth.tofloat();
	}

	local i = -1;
	for ( local ang = 0.0; ang < 360.0; ang += 45.0 )
	{
		local dir = VS.VectorYawRotate( m_vecForward, ang );
		local obj = CBossArm( this, position + dir * 70, dir );
		m_Arms.append( obj );
		obj.m_index = ++i;
		m_flTotalHealth += obj.m_nHealth.tofloat();
	}

	m_flTotalHealth += m_nHealth;
}

function CBigBoss::UpdateHealthStats()
{
	local curHealth = m_nHealth, curShield = 0.0;

	foreach( v in m_Arms )
	{
		curHealth += v.m_nHealth;
	}

	foreach( v in m_Shields )
	{
		curShield += v.m_nHealth;
	}

	m_flCurHealth = curHealth;
	m_flCurShield = curShield;
}

function CBigBoss::Spawn()
{
	base.Spawn();

	m_flRotation = 360.0 * 0.1 * TICK_INTERVAL;
	m_attack = 0;
	m_stage = 0;

	m_pEntity.SetContextThink( "AttackThink", AttackThink.bindenv(this), 0.0 );
	UpdateHealthStats();
}

function CBigBoss::Destroy( bKilledByPlayer = false )
{
	local x = Swarm.m_HurtableEntities.find( this );
	if ( x != null )
		Swarm.m_HurtableEntities.remove( x );

	foreach ( obj in m_Shields )
	{
		if ( obj.m_nHealth > 0 )
			obj.Destroy();
	}

	foreach ( obj in m_Arms )
	{
		if ( obj.m_nHealth > 0 )
			obj.Destroy();
	}

	m_Shields.clear();
	m_Arms.clear();

	if ( bKilledByPlayer && Swarm.m_Players[0].m_nHealth > 0 )
	{
		local basePlayer = Swarm.m_Players[0].m_pBasePlayer;
		SteamAchievements.IncrementStat( basePlayer, "STAT_BEAT_BIGBOSS", 1 );

		printf( "STAT_BEAT_BIGBOSS = %d\n", SteamAchievements.GetStat( basePlayer, "STAT_BEAT_BIGBOSS" ) );

		NetMsg.Start( "Swarm.CBigBoss.Dead" );
		NetMsg.Send( basePlayer, true );
	}

	Swarm.m_hBigBoss = null;

	m_pEntity.SetContextThink( "", null, 0.0 );
	return m_pEntity.Destroy();
}

// Hacks all around, no time left for proper solutions
function CBigBoss::Attack1()
{
	local restTime = 1.0;
	local curtime = Time() + restTime;
	local sw = RandomInt( 0, 1 );

	foreach ( i, arm in m_Arms )
	{
		arm.m_flRefireTime = 0.25;
		arm.m_nCurAttack = ArmAttack.Type1;

		if ( (i & 1)^sw )
		{
			arm.m_flNextAttackTime = curtime;
		}
		else
		{
			arm.m_flNextAttackTime = curtime + arm.m_flRefireTime * 0.5;
		}
	}

	if ( RandomInt( 0, 1 ) )
	{
		m_flRotation = 360.0 * 0.5 * TICK_INTERVAL;
	}
	else
	{
		m_flRotation = -360.0 * 0.5 * TICK_INTERVAL;
	}

	return RandomFloat( 5.0, 8.0 );
}

function CBigBoss::Attack2()
{
	local restTime = 1.5;
	local curtime = Time() + restTime;

	foreach ( i, arm in m_Arms )
	{
		arm.m_flRefireTime = 0.1;
		arm.m_nCurAttack = ArmAttack.Type2;
		arm.m_flNextAttackTime = curtime;
	}

	if ( RandomInt( 0, 1 ) )
	{
		m_flRotation = 360.0 * 0.25 * TICK_INTERVAL;
	}
	else
	{
		m_flRotation = -360.0 * 0.25 * TICK_INTERVAL;
	}

	return RandomFloat( 5.0, 8.0 );
}

function CBigBoss::Attack3()
{
	local switchTime = 0.75;

	switch ( m_stage )
	{
	case 0:
	{
		local restTime = 0.75;
		local curtime = Time() + restTime;
		local sw = RandomInt( 0, 1 );

		foreach ( i, arm in m_Arms )
		{
			if ( (i & 1)^sw )
			{
				arm.m_nCurAttack = ArmAttack.Type3;
				arm.m_flRefireTime = TICK_INTERVAL;
				arm.m_flNextAttackTime = curtime;
			}
			else
			{
				arm.m_nCurAttack = ArmAttack.None;
			}
		}

		// Any less than 65% will leave gaps in between the projectiles where the player can sit still
		if ( RandomInt( 0, 1 ) )
		{
			m_flRotation = 360.0 * 0.65 * TICK_INTERVAL;
		}
		else
		{
			m_flRotation = -360.0 * 0.65 * TICK_INTERVAL;
		}

		++m_stage;
		m_fnAttack = Attack3;

		return restTime + switchTime * 0.25;
	}

	// Final swing
	case 12:
		m_stage = 0;
		m_attack = 0;
		return switchTime;

	// Rotation change
	default:
		m_flRotation = -m_flRotation;
		++m_stage;
		return switchTime;
	}
}

function CBigBoss::ChooseRandomAttack()
{
	const BOSS_ATTACK_COUNT = 3;

	local i = RandomInt( 1, BOSS_ATTACK_COUNT );
	return this["Attack"+i]();
}

function CBigBoss::AttackThink( m_pEntity )
{
	if ( m_stage )
		return m_fnAttack();

	return ChooseRandomAttack();
}

function CBigBoss::Frame( m_pEntity )
{
	if ( m_flRotation )
		RotateByAngle( m_flRotation );

	m_pShieldRotator.SetLocalOrigin( m_vecPosition );
	RotateBaseEntityByAngle( m_pShieldRotator, -3.0 );

	// NOTE: If there are no shields, (0 div 0 = -nan) will write 1 to the net msg
	NetMsg.Start( "Swarm.CBigBoss.Update" );
		NetMsg.WriteNormal( m_flCurHealth / m_flTotalHealth );
		NetMsg.WriteNormal( m_flCurShield / m_flTotalShield );
	NetMsg.Send( Swarm.m_Players[0].m_pBasePlayer, true );

	DebugDrawBBox();

	return 0.0;
}

function CBigBoss::TakeProjectileDamage( projectile )
{
	local damage = projectile.m_nDamage;
	// TODO: Take x10 damage until independent weapons are added to the boss
	if ( !m_nArmCount )
	{
		damage *= 10;
	}

	m_nHealth -= damage;

	if ( m_nHealth < 0 )
		m_nHealth = 0;

	UpdateHealthStats();

	m_pEntity.SetRenderColor( 255, 255, 255 );
	m_pEntity.SetContextThink( "RestoreColour", SUB_RestoreColour, 0.2 );

	if ( m_nHealth == 0 )
	{
		Destroy( true );
	}
}
