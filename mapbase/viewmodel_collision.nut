//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// A very basic script that moves the viewmodel when the player is close to a wall, faking viewmodel collisions.
//
// NOTE: Does not work for RPG, and gravity gun right click animation flickers for one frame
//

if ( SERVER_DLL )
	return;

// These distances make visual sense, but some may feel too much.
// For example the gravity gun and shotgun are HUGE, but they have lower values to at least be able to see them.
local m_WeaponLength =
{
	weapon_crowbar = 32.0,
	weapon_pistol = 32.0,
	weapon_357 = 32.0,
	weapon_smg = 32.0,
	weapon_ar2 = 36.0,
	weapon_crossbow = 42.0,
	weapon_shotgun = 50.0,
	weapon_rpg = 0.0,
	weapon_physcannon = 64.0,
}

const kTimeToCollision = 0.15;
const kTimeToNoCollision = 0.2;

local m_flLastFrac = 0.0;
local m_flStartTime = 0.0;

// 0: no collision
// 1: in collision
// 2: in transition to collision
// 3: in transition to no collision
local m_nState = 0;

local Time = Time,
	Entities = Entities,
	RemapVal = RemapVal,
	TraceLineComplex = TraceLineComplex,
	MainViewOrigin = MainViewOrigin,
	MainViewForward = MainViewForward,
	MainViewRight = MainViewRight,
	MainViewUp = MainViewUp;

local function Think(_)
{
	local weapon = player.GetActiveWeapon();
	if ( weapon )
	{
		local flDist = 32.0;
		local weaponclass = weapon.GetClassname();

		if ( weaponclass in m_WeaponLength )
			flDist = m_WeaponLength[ weaponclass ];

		if ( flDist )
		{
			local vm = Entities.FindByClassname( null, "viewmodel" );
			if ( vm )
			{
				//local side = 0.25;
				//if ( !Convars.GetInt("cl_righthand") )
				//	side = -0.25;

				local viewOrigin = MainViewOrigin();
				local rayDelta =
					MainViewForward()
						.Add( MainViewRight().Multiply(0.25) )
						.Subtract( MainViewUp().Multiply(0.25) )
						.Multiply( flDist );
				local tr = TraceLineComplex( viewOrigin, rayDelta.Add( viewOrigin ), player, MASK_SHOT_HULL, COLLISION_GROUP_NONE );
				local frac = tr.Fraction();
				tr.Destroy();

				if ( frac != 1.0 )
				{
					m_flLastFrac = frac;

					switch ( m_nState )
					{
						case 0:
						case 3:
						{
							m_nState = 2;
							m_flStartTime = Time();
						}
					}
				}
				else
				{
					switch ( m_nState )
					{
						case 1:
						case 2:
						{
							m_nState = 3;
							m_flStartTime = Time();
						}
					}
				}

				// NOTE: Transition to transition does not lerp from the last real position,
				// but that's fine because transition times are quick.
				switch ( m_nState )
				{
					// in collision
					case 1:
					{
						local vecDelta = vm.GetForwardVector().Multiply( flDist * ( m_flLastFrac - 1.0 ) );
						vm.SetLocalOrigin( vecDelta.Add( vm.GetLocalOrigin() ) );

						break;
					}
					// in transition to collision
					case 2:
					{
						local t = (Time() - m_flStartTime) / kTimeToCollision;
						if ( t < 1.0 )
						{
							t = RemapVal( t, 0.0, 1.0, 1.0, m_flLastFrac );
						}
						else
						{
							m_nState = 1;
							t = m_flLastFrac;
						}

						local vecDelta = vm.GetForwardVector().Multiply( flDist * ( t - 1.0 ) );
						vm.SetLocalOrigin( vecDelta.Add( vm.GetLocalOrigin() ) );

						break;
					}
					// in transition to no collision
					case 3:
					{
						local t = (Time() - m_flStartTime) / kTimeToNoCollision;
						if ( t < 1.0 )
						{
							t = RemapVal( t, 0.0, 1.0, m_flLastFrac, 1.0 );

							local vecDelta = vm.GetForwardVector().Multiply( flDist * ( t - 1.0 ) );
							vm.SetLocalOrigin( vecDelta.Add( vm.GetLocalOrigin() ) );
						}
						else
						{
							m_nState = 0;
						}
					}
				}
			}
		}
	}

	return 0.0;
}


local Init = function(...)
{
	Entities.First().SetContextThink( "ViewModelCollision", Think, 0.25 );
}

ListenToGameEvent( "player_spawn", Init, "ViewModelCollision" );
Hooks.Add( this, "OnRestore", Init, "ViewModelCollision" );
