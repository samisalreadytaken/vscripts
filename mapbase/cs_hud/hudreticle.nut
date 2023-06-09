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

	m_r = 0xff
	m_g = 0xcc
	m_b = 0x00
	m_a = 0xcc
	m_size = 5
	m_gap = 3
	m_thickness = 1
	m_outlinethickness = 1
	m_dot = 0
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

	local f = FCVAR_CLIENTDLL | FCVAR_ARCHIVE;

	Convars.RegisterConvar( "cl_crosshairstyle", "1", "", f );
	Convars.SetChangeCallback( "cl_crosshairstyle", function(...)
	{
		CSHud.m_bCvarChange = true;

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

	Convars.RegisterConvar( "cl_crosshaircolor_r", ""+m_r, "", f );
	Convars.SetChangeCallback( "cl_crosshaircolor_r", function(...)
	{
		CSHud.m_bCvarChange = true;
		CSHud.m_pCrosshair.m_r = clamp( Convars.GetInt("cl_crosshaircolor_r"), 0, 255 );
	} );

	Convars.RegisterConvar( "cl_crosshaircolor_g", ""+m_g, "", f );
	Convars.SetChangeCallback( "cl_crosshaircolor_g", function(...)
	{
		CSHud.m_bCvarChange = true;
		CSHud.m_pCrosshair.m_g = clamp( Convars.GetInt("cl_crosshaircolor_g"), 0, 255 );
	} );

	Convars.RegisterConvar( "cl_crosshaircolor_b", ""+m_b, "", f );
	Convars.SetChangeCallback( "cl_crosshaircolor_b", function(...)
	{
		CSHud.m_bCvarChange = true;
		CSHud.m_pCrosshair.m_b = clamp( Convars.GetInt("cl_crosshaircolor_b"), 0, 255 );
	} );

	Convars.RegisterConvar( "cl_crosshairalpha", ""+m_a, "", f );
	Convars.SetChangeCallback( "cl_crosshairalpha", function(...)
	{
		CSHud.m_bCvarChange = true;
		CSHud.m_pCrosshair.m_a = clamp( Convars.GetInt("cl_crosshairalpha"), 0, 255 );
	} );

	Convars.RegisterConvar( "cl_crosshairsize", ""+m_size, "", f );
	Convars.SetChangeCallback( "cl_crosshairsize", function(...)
	{
		CSHud.m_bCvarChange = true;
		CSHud.m_pCrosshair.m_size = max( Convars.GetInt("cl_crosshairsize"), 0 );
	} );

	Convars.RegisterConvar( "cl_crosshairgap", ""+m_gap, "", f );
	Convars.SetChangeCallback( "cl_crosshairgap", function(...)
	{
		CSHud.m_bCvarChange = true;
		CSHud.m_pCrosshair.m_gap = Convars.GetInt("cl_crosshairgap");
	} );

	Convars.RegisterConvar( "cl_crosshairthickness", ""+m_thickness, "", f );
	Convars.SetChangeCallback( "cl_crosshairthickness", function(...)
	{
		CSHud.m_bCvarChange = true;
		CSHud.m_pCrosshair.m_thickness = Convars.GetInt("cl_crosshairthickness");
	} );

	Convars.RegisterConvar( "cl_crosshair_outlinethickness", ""+m_outlinethickness, "", f );
	Convars.SetChangeCallback( "cl_crosshair_outlinethickness", function(...)
	{
		CSHud.m_bCvarChange = true;
		CSHud.m_pCrosshair.m_outlinethickness = Convars.GetInt("cl_crosshair_outlinethickness");
	} );

	Convars.RegisterConvar( "cl_crosshairdot", ""+m_dot, "", f );
	Convars.SetChangeCallback( "cl_crosshairdot", function(...)
	{
		CSHud.m_bCvarChange = true;
		CSHud.m_pCrosshair.m_dot = Convars.GetInt("cl_crosshairdot");
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

	local cx = XRES(320);
	local cy = YRES(240);

	surface.DrawTexturedBox( m_hTexCircle,
		cx - m_nCircleWidthHalf, cy - m_nCircleHeightHalf, m_nCircleWidth, m_nCircleHeight,
		0xff, 0xff, 0xff, 0xcc );

	surface.SetColor( m_r, m_g, m_b, 0xff );
	surface.DrawLine( cx, cy, cx+1, cy+1 );

	local size = m_nPipHeight;
	local gap = m_nGap;
	local thickness = m_nPipWidth;
	local thicknessHalf = m_nPipWidthHalf;

	// top
	local x = cx - thicknessHalf;
	local y = cy - gap - size;
	surface.SetTexture( m_hTexPipUp );
	surface.DrawTexturedRect( x, y, thickness, size );

	// bottom
	y = cy + gap;
	surface.SetTexture( m_hTexPipDown );
	surface.DrawTexturedRect( x, y, thickness, size );

	// left
	x = cx - gap - size;
	y = cy - thicknessHalf;
	surface.SetTexture( m_hTexPipLeft );
	surface.DrawTexturedRect( x, y, size, thickness );

	// right
	x = cx + gap;
	surface.SetTexture( m_hTexPipRight );
	surface.DrawTexturedRect( x, y, size, thickness );
}

function CSGOHudReticle::PaintStyle2()
{
	surface.DrawTexturedBox( m_hTexStyle2, XRES(320) - 16, YRES(240) - 16, 32, 32, m_r, m_g, m_b, 0xff );
}

function CSGOHudReticle::PaintStyle4()
{
	surface.SetColor( m_r, m_g, m_b, m_a );

	local cx = XRES(320);
	local cy = YRES(240);

	local size = m_size;
	local gap = m_gap;
	local thickness = m_thickness;
	local thicknessHalf = thickness / 2;
	local offset1 = gap + thicknessHalf + size;
	local offset2 = size + thickness + gap + gap;

	// top
	local x0 = cx - thicknessHalf;
	local y0 = cy - offset1;
	surface.DrawFilledRect( x0, y0, thickness, size );

	// bottom
	local y3 = y0 + offset2;
	surface.DrawFilledRect( x0, y3, thickness, size );

	// left
	local x1 = cx - offset1;
	local y1 = cy - thicknessHalf;
	surface.DrawFilledRect( x1, y1, size, thickness );

	// right
	local x2 = x1 + offset2;
	surface.DrawFilledRect( x2, y1, size, thickness );

	if ( m_dot )
	{
		surface.DrawFilledRect( x0, y1, thickness, thickness );
	}

	local outline = m_outlinethickness;
	{
		thickness += outline+outline;
		size += outline+outline;

		surface.SetColor( 0x00, 0x00, 0x00, m_a );
		surface.DrawOutlinedRect( x0-outline, y0-outline, thickness, size, outline );
		surface.DrawOutlinedRect( x1-outline, y1-outline, size, thickness, outline );
		surface.DrawOutlinedRect( x2-outline, y1-outline, size, thickness, outline );
		surface.DrawOutlinedRect( x0-outline, y3-outline, thickness, size, outline );

		if ( m_dot )
		{
			surface.DrawOutlinedRect( x0-outline, y1-outline, thickness, thickness, outline );
		}
	}
}

function CSGOHudReticle::SetVisible( state )
{
	m_bVisible = state;
	return self.SetVisible( state );
}
