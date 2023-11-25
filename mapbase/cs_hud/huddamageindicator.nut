//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;
local surface = surface, FrameTime = FrameTime,
	CurrentViewForward = CurrentViewForward,
	CurrentViewRight = CurrentViewRight;

const CSGOHUD_DMG_INDICATOR_BURN = 1;
const CSGOHUD_DMG_INDICATOR_POISON = 2;
const CSGOHUD_DMG_INDICATOR_RADIATION = 3;
const CSGOHUD_DMG_INDICATOR_DEATH = 10;

class CSGOHudDamageIndicator
{
	constructor( player )
	{
		this.player = player;
	}

	self = null
	player = null

	m_hTexVert = null
	m_hTexHorz = null

	m_nAlphaTop = 0
	m_nAlphaBottom = 0
	m_nAlphaLeft = 0
	m_nAlphaRight = 0

	m_nFlash = 0
	m_nFlashAlpha = 0
	m_hGradient = null
}

function CSGOHudDamageIndicator::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudDamageIndicator" );
	self.SetSize( XRES(640), YRES(480) );
	self.SetZPos( -1 );
	self.SetVisible( false );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "Paint", Paint.bindenv(this) );

	m_hTexVert = surface.ValidateTexture( "panorama/images/hud/damageindicator/damage-segment_vert", true );
	m_hTexHorz = surface.ValidateTexture( "panorama/images/hud/damageindicator/damage-segment_horz", true );
	m_hGradient = surface.ValidateTexture( "panorama/images/masks/bottom-top-fade_additive", true );
}

// NOTE: Matches SFUI, not Panorama. Panorama seems to use a different scaling
function CSGOHudDamageIndicator::Paint()
{
	local decay = ( FrameTime() * 255.0 ).tointeger();

	local cx = XRES(320);
	local cy = YRES(240);

	if ( m_nFlash ) switch ( m_nFlash )
	{
		case CSGOHUD_DMG_INDICATOR_BURN:
		{
			surface.DrawTexturedBox( m_hGradient, 0, cy, cx<<1, cy, 255, 0, 0, m_nFlashAlpha );
			if ( ( m_nFlashAlpha -= decay ) <= 0 )
				m_nFlash = 0;
			break;
		}
		case CSGOHUD_DMG_INDICATOR_POISON:
		{
			surface.DrawTexturedBox( m_hGradient, 0, cy, cx<<1, cy, 255, 236, 128, m_nFlashAlpha );
			if ( ( m_nFlashAlpha -= decay ) <= 0 )
				m_nFlash = 0;
			break;
		}
		case CSGOHUD_DMG_INDICATOR_RADIATION:
		{
			surface.DrawTexturedBox( m_hGradient, 0, cy, cx<<1, cy, 255, 255, 255, m_nFlashAlpha );
			if ( ( m_nFlashAlpha -= decay ) <= 0 )
				m_nFlash = 0;
			break;
		}
		case CSGOHUD_DMG_INDICATOR_DEATH:
		{
			// Lazy, but it works.
			surface.SetColor( 255, 0, 0, 50 );
			surface.DrawFilledRect( 0, 0, cx<<1, cy<<1 );
			return;
		}
	}

	local sh = YRES(64);
	local sw = sh << 1;

	surface.SetTexture( m_hTexVert );

	// top
	local x = cx - sh;
	local y = cy - sh;
	if ( m_nAlphaTop )
	{
		surface.SetColor( 255, 255, 255, m_nAlphaTop );
		surface.DrawTexturedRect( x, y, sw, sh );

		if ( ( m_nAlphaTop -= decay ) < 0 )
			m_nAlphaTop = 0;
	}

	// bottom
	y = cy;
	if ( m_nAlphaBottom )
	{
		surface.SetColor( 255, 255, 255, m_nAlphaBottom );
		surface.DrawTexturedSubRect( x, y, x + sw, y + sh, 0., 1., 1., 0. );

		if ( ( m_nAlphaBottom -= decay ) < 0 )
			m_nAlphaBottom = 0;
	}

	surface.SetTexture( m_hTexHorz );

	// left
	y = cy - sh;
	if ( m_nAlphaLeft )
	{
		surface.SetColor( 255, 255, 255, m_nAlphaLeft );
		surface.DrawTexturedRect( x, y, sh, sw );

		if ( ( m_nAlphaLeft -= decay ) < 0 )
			m_nAlphaLeft = 0;
	}

	// right
	x = cx;
	if ( m_nAlphaRight )
	{
		surface.SetColor( 255, 255, 255, m_nAlphaRight );
		surface.DrawTexturedSubRect( x, y, x + sh, y + sw, 1., 0., 0., 1. );

		if ( ( m_nAlphaRight -= decay ) < 0 )
			m_nAlphaRight = 0;
	}

	if ( !(m_nAlphaTop|m_nAlphaBottom|m_nAlphaLeft|m_nAlphaRight|m_nFlash) )
	{
		self.SetVisible( false );
	}
}

function CSGOHudDamageIndicator::DamageTaken( bits, origin )
{
	if ( player.GetHealth() <= 0 )
	{
		m_nFlash = CSGOHUD_DMG_INDICATOR_DEATH;
	}
	// Single time impact effect. HL2 specific, doesn't exist in CSGO
	// DROWN/CRUSH/PLASMA are handled in CBasePlayer::DamageEffect()
	else if ( bits & CSGOHUD_DMG_SCR_FX )
	{
		if ( bits & DMG_BURN )
		{
			m_nFlash = CSGOHUD_DMG_INDICATOR_BURN;
			m_nFlashAlpha = 127;
		}
		else if ( bits & DMG_POISON )
		{
			m_nFlash = CSGOHUD_DMG_INDICATOR_POISON;
			m_nFlashAlpha = 127;
		}
		else if ( bits & DMG_RADIATION )
		{
			m_nFlash = CSGOHUD_DMG_INDICATOR_RADIATION;
			m_nFlashAlpha = 127;
		}
	}

	local vecDelta = origin.Subtract( player.GetOrigin() );
	local flDist = vecDelta.Norm();

	if ( flDist < 42.0 )
	{
		m_nAlphaTop = m_nAlphaBottom = m_nAlphaRight = m_nAlphaLeft = 255;
		return self.SetVisible( true );
	}

	local viewForward = CurrentViewForward(), viewRight = CurrentViewRight();
	// Keep for displaying damage from above
	//viewForward.z = 0.0;

	local dot = vecDelta.Dot( viewForward );
	if ( dot > 0.32 )
	{
		dot = ( dot * 255.0 ).tointeger();
		if ( m_nAlphaTop < dot )
			m_nAlphaTop = dot;
	}
	else if ( dot < -0.32 )
	{
		dot = ( dot * -255.0 ).tointeger();
		if ( m_nAlphaBottom < dot )
			m_nAlphaBottom = dot;
	}

	dot = vecDelta.Dot( viewRight );
	if ( dot > 0.32 )
	{
		dot = ( dot * 255.0 ).tointeger();
		if ( m_nAlphaRight < dot )
			m_nAlphaRight = dot;
	}
	else if ( dot < -0.32 )
	{
		dot = ( dot * -255.0 ).tointeger();
		if ( m_nAlphaLeft < dot )
			m_nAlphaLeft = dot;
	}

	return self.SetVisible( true );
}
