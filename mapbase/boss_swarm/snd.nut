//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// A bit of a hacked solution that limits the amount of sounds played at once
// and plays specific type of sounds at specific entities.
//

local Swarm = this;

enum SwarmSound
{
	PlayerWeapon,
	BossWeapon,
}

m_SoundQueue <-
{
	[SwarmSound.PlayerWeapon] = {},
	[SwarmSound.BossWeapon] = {},
}

function PlaySound( chan, sound )
{
	local pChan = m_SoundQueue[ chan ];

	if ( sound in pChan )
	{
		local ref = pChan[ sound ];
		if ( ref >= 2 )
			return;

		++pChan[ sound ];
		return;
	}

	pChan[ sound ] <- 1;
}

function SoundFrame()
{
	local queue = m_SoundQueue[SwarmSound.PlayerWeapon];
	local target = Swarm.m_Players[0].m_pEntity;

	foreach ( sound, ref in queue )
	{
		if ( ref )
		{
			do {
				target.EmitSound( sound );
			} while ( --ref );
			queue[sound] = 0;
		}
	}

	queue = m_SoundQueue[SwarmSound.BossWeapon];
	target = Swarm.m_hBigBoss;
	if ( target )
	{
		target = target.m_pEntity;

		foreach ( sound, ref in queue )
		{
			if ( ref )
			{
				do {
					target.EmitSound( sound );
				} while ( --ref );
				queue[sound] = 0;
			}
		}
	}
}
