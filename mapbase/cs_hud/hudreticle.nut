//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;
local surface = surface, Time = Time;


class CSGOHudReticle
{
	self = null

	m_bVisible = true

	m_nGapTarget = 0
	m_flStartTime = 0.0
	m_nGap = 0

	m_hTexCircle = null
	m_hTexPipUp = null
	m_hTexPipLeft = null
	m_hTexPipRight = null
	m_hTexPipDown = null
	m_hTexStyle2 = null

	m_nPipWidth = 0
	m_nPipHeight = 0

	m_nPipWidthHalf = 0
	m_nPipHeightHalf = 0

	m_nCircleWidth = 0
	m_nCircleHeight = 0

	m_nCircleWidthHalf = 0
	m_nCircleHeightHalf = 0
}

function CSGOHudReticle::Init()
{
	// "layout/hud/hudreticle.xml"
	// "styles/hud/hudreticle.css"
	//crosshairColor1: #82b116;
	//crosshairColor2: #ffcc00;
	//crosshairColor3: #00ffff;
	//crosshairColor4: #96ffff;
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudReticle" );
	self.SetPos( 0, 0 );
	self.SetSize( ScreenWidth(), ScreenHeight() );
	self.SetZPos( 1 );
	self.SetVisible( m_bVisible );
	self.SetPaintBackgroundEnabled( false );

	m_hTexCircle = surface.ValidateTexture( "panorama/images/hud/reticle/reticlecircle", true );
	m_hTexPipUp = surface.ValidateTexture( "panorama/images/hud/reticle/crosshairpip2_up", true );
	m_hTexPipLeft = surface.ValidateTexture( "panorama/images/hud/reticle/crosshairpip2_lf", true );
	m_hTexPipRight = surface.ValidateTexture( "panorama/images/hud/reticle/crosshairpip2_rt", true );
	m_hTexPipDown = surface.ValidateTexture( "panorama/images/hud/reticle/crosshairpip2_dn", true );
	m_hTexStyle2 = surface.ValidateTexture( "panorama/images/hud/reticle/crosshair", true );

	m_nPipWidth = surface.GetTextureWide( m_hTexPipUp );
	m_nPipHeight = surface.GetTextureTall( m_hTexPipUp );

	m_nPipWidthHalf = m_nPipWidth / 2;
	m_nPipHeightHalf = m_nPipHeight / 2;

	m_nCircleWidth = surface.GetTextureWide( m_hTexCircle ) + 1;
	m_nCircleHeight = surface.GetTextureTall( m_hTexCircle ) + 1;

	m_nCircleWidthHalf = m_nCircleWidth / 2;
	m_nCircleHeightHalf = m_nCircleHeight / 2;

	Convars.RegisterConvar( "cl_crosshairstyle", "2", "", FCVAR_CLIENTDLL );
	Convars.SetChangeCallback( "cl_crosshairstyle", function(...)
	{
		switch ( Convars.GetInt("cl_crosshairstyle") )
		{
		case 1:
			CSHud.m_pCrosshair.self.SetCallback( "Paint", CSHud.m_pCrosshair.PaintStyle1.bindenv( CSHud.m_pCrosshair ) );
			return;
		case 2:
			CSHud.m_pCrosshair.self.SetCallback( "Paint", CSHud.m_pCrosshair.PaintStyle2.bindenv( CSHud.m_pCrosshair ) );
			return;
		case 4:
			CSHud.m_pCrosshair.self.SetCallback( "Paint", CSHud.m_pCrosshair.PaintStyle4.bindenv( CSHud.m_pCrosshair ) );
			return;
		default:
			CSHud.m_pCrosshair.self.SetCallback( "Paint", null );
		}
	} );
}

function CSGOHudReticle::PaintStyle1()
{
	if ( m_nGapTarget )
	{
		local t = ( Time() - m_flStartTime ) / 0.25;
		if ( t < 1.0 )
		{
			m_nGap += ( m_nGapTarget - m_nGap ) * t;
		}
		else
		{
			m_nGap = m_nGapTarget;
			m_nGapTarget = 0;
		}
	}

	local ww = XRES(320);
	local hh = YRES(240);

	surface.DrawTexturedBox( m_hTexCircle,
		ww - m_nCircleWidthHalf, hh - m_nCircleHeightHalf, m_nCircleWidth, m_nCircleHeight,
		0xff, 0xff, 0xff, 0xcc );

	surface.SetColor( 0xff, 0xcc, 0x00, 0xff );
	surface.DrawLine( ww, hh, ww+1, hh+1 );

	local size = m_nPipHeight;
	local gap = m_nGap;
	local thickness = m_nPipWidth;
	local thicknessHalf = m_nPipWidthHalf;

	// top
	local x = ww - thicknessHalf;
	local y = hh - gap - size;
	surface.SetTexture( m_hTexPipUp );
	surface.DrawTexturedRect( x, y, thickness, size );

	// left
	y = hh - thicknessHalf;
	x = ww - gap - size;
	surface.SetTexture( m_hTexPipLeft );
	surface.DrawTexturedRect( x, y, size, thickness );

	// right
	y = hh - thicknessHalf;
	x = ww + gap;
	surface.SetTexture( m_hTexPipRight );
	surface.DrawTexturedRect( x, y, size, thickness );

	// bottom
	x = ww - thicknessHalf;
	y = hh + gap;
	surface.SetTexture( m_hTexPipDown );
	surface.DrawTexturedRect( x, y, thickness, size );
}

function CSGOHudReticle::PaintStyle2()
{
	return surface.DrawTexturedBox( m_hTexStyle2, XRES(320) - 16, YRES(240) - 16, 32, 32, 0xff, 0xcc, 0x00, 0xff );
}

function CSGOHudReticle::PaintStyle4()
{
	surface.SetColor( 0x82, 0xb1, 0x16, 0xcc );

	local ww = XRES(320);
	local hh = YRES(240);

	local size = 8;
	local gap = 6;
	local thickness = 2;
	local thicknessHalf = thickness / 2;

	// top
	local x0 = ww - thicknessHalf;
	local y0 = hh - gap - size;
	surface.DrawFilledRect( x0, y0, thickness, size );

	// left
	local y1 = hh - thicknessHalf;
	local x1 = ww - gap - size;
	surface.DrawFilledRect( x1, y1, size, thickness );

	// right
	local y2 = hh - thicknessHalf;
	local x2 = ww + gap;
	surface.DrawFilledRect( x2, y2, size, thickness );

	// bottom
	local x3 = ww - thicknessHalf;
	local y3 = hh + gap;
	surface.DrawFilledRect( x3, y3, thickness, size );

	local outline = 1;
	{
		thickness += outline+outline;
		size += outline+outline;

		surface.SetColor( 0x00, 0x00, 0x00, 0xcc );
		surface.DrawOutlinedRect( x0-outline, y0-outline, thickness, size, outline );
		surface.DrawOutlinedRect( x1-outline, y1-outline, size, thickness, outline );
		surface.DrawOutlinedRect( x2-outline, y2-outline, size, thickness, outline );
		surface.DrawOutlinedRect( x3-outline, y3-outline, thickness, size, outline );
	}
}

function CSGOHudReticle::SetVisible( state )
{
	m_bVisible = state;
	self.SetVisible( state );
}
