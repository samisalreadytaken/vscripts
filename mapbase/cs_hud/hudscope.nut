//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local CSHud = this;
local XRES = XRES, YRES = YRES;
local surface = surface, NetProps = NetProps,
	RemapValClamped = RemapValClamped, SimpleSplineRemapValClamped = SimpleSplineRemapValClamped;


class CCSHudScope
{
	constructor( player )
	{
		this.player = player;
	}

	self = null
	player = null

	m_bVisible = false

	m_hScopeArc = null
	m_hScopeLens = null
	m_hScopeBlur = null
	m_hScopeBlurHorz = null

	m_nBlurWidth = 0
}

function CCSHudScope::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSHudScope" );
	self.SetSize( XRES(640), YRES(480) );
	self.SetZPos( -101 );
	self.SetVisible( m_bVisible );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "Paint", Paint.bindenv(this) );

	m_hScopeArc = surface.ValidateTexture( "sprites/scope_arc", true );
	m_hScopeLens = surface.ValidateTexture( "overlays/scope_lens", true );
	m_hScopeBlur = surface.ValidateTexture( "sprites/scope_line_blur", true );
	m_hScopeBlurHorz = surface.ValidateTexture( "sprites/scope_line_blur_horz", true );

	m_nBlurWidth = surface.GetTextureWide( m_hScopeBlur );
}

// NOTE: Blur logic is a rough approximation, and view bob doesn't exist
// There is no inaccuracy in HL2 anyway, this is all visual
function CCSHudScope::Paint()
{
	local wide = XRES(640);
	local tall = YRES(480);
	local wideHalf = wide >> 1;
	local tallHalf = tall >> 1;
	local texTall = tallHalf;
	local texWide = texTall;
	local x0 = wideHalf - texWide;

	surface.DrawTexturedBox( m_hScopeLens, x0, 0, tall, tall, 0, 0, 0, 195 );

	// Draw the crosshair
	local speed = NetProps.GetPropVector( player, "m_vecVelocity" ).Length();
	if ( speed > 8.0 )
	{
		local a = 0.0, w = 0.0;

		if ( speed > 48.0 )
		{
			a = RemapValClamped( speed, 48.0, 150.0, 160.0, 95.0 );
			w = SimpleSplineRemapValClamped( speed, 48.0, 150.0, m_nBlurWidth, m_nBlurWidth * 2 );
		}
		else
		{
			a = RemapValClamped( speed, 8.0, 48.0, 200.0, 160.0 );
			w = SimpleSplineRemapValClamped( speed, 8.0, 48.0, 2.0, m_nBlurWidth );
		}

		surface.SetColor( 0, 0, 0, a );

		surface.SetTexture( m_hScopeBlur );
		surface.DrawTexturedRect( wideHalf - w * 0.5, 0, w, tall );
		surface.SetTexture( m_hScopeBlurHorz );
		surface.DrawTexturedRect( 0, tallHalf - w * 0.5, wide, w );

		surface.SetColor( 0, 0, 0, 255 );
	}
	// Lines only
	else
	{
		surface.SetColor( 0, 0, 0, 255 );
		surface.DrawLine( wideHalf, 0, wideHalf, tall );
		surface.DrawLine( 0, tallHalf, wide, tallHalf );
	}

	// Draw the scope
	surface.SetTexture( m_hScopeArc );

	// lower right
	surface.DrawTexturedRect( wideHalf, tallHalf, texWide, texTall );

	// lower left
	surface.DrawTexturedSubRect( x0, tallHalf, x0+texWide, tallHalf+texTall, 1., 0., 0., 1. );

	// upper left
	surface.DrawTexturedSubRect( x0, 0, x0+texWide, texTall, 1., 1., 0., 0. );

	// upper right
	surface.DrawTexturedSubRect( wideHalf, 0, wideHalf+texWide, texTall, 0., 1., 1., 0. );

	// left
	surface.DrawFilledRect( 0, 0, x0, tall );

	// right
	surface.DrawFilledRect( wideHalf + texWide, 0, x0, tall );
}

function CCSHudScope::SetVisible( state )
{
	m_bVisible = state;
	return self.SetVisible( state );
}
