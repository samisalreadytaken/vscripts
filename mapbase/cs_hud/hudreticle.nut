//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;
local surface = surface, FrameTime = FrameTime, NetProps = NetProps,
	Approach = Approach, RemapValClamped = RemapValClamped;


class CSGOHudReticle
{
	constructor( player )
	{
		this.player = player;
	}

	self = null
	player = null

	m_bVisible = false
	m_bGunCrosshair = false
	m_bUnableToFire = false
	m_flAspectRatio = 1.0

	m_nGap = 0
	m_nMuzzleFlashParity = -1
	m_flMaxspeed = 0.0

	m_hTexCircle = null
	m_hTexPipUp = null
	m_hTexPipLeft = null
	m_hTexStyle2 = null
	m_hTexFriend = null

	m_nPipWidth = 0
	m_nPipHeight = 0

	m_cx = XRES(320)
	m_cy = YRES(240)

	//crosshairColor1: #82b116;
	//crosshairColor2: #ffcc00;
	//crosshairColor3: #00ffff;
	//crosshairColor4: #96ffff;
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
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudReticle" );
	self.SetSize( XRES(640), YRES(480) );
	self.SetZPos( 1 );
	self.SetVisible( m_bVisible );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );

	m_hTexCircle = surface.ValidateTexture( "panorama/images/hud/reticle/reticlecircle", true );
	m_hTexPipUp = surface.ValidateTexture( "panorama/images/hud/reticle/crosshairpip2_up", true );
	m_hTexPipLeft = surface.ValidateTexture( "panorama/images/hud/reticle/crosshairpip2_lf", true );
	m_hTexStyle2 = surface.ValidateTexture( "panorama/images/hud/reticle/crosshair", true );
	m_hTexFriend = surface.ValidateTexture( "panorama/images/hud/reticle/reticlefriend_additive", true );

	m_nPipWidth = surface.GetTextureWide( m_hTexPipUp );
	m_nPipHeight = surface.GetTextureTall( m_hTexPipUp );

	m_flMaxspeed = NetProps.GetPropFloat( player, "m_flMaxspeed" );

	local f = FCVAR_CLIENTDLL | FCVAR_ARCHIVE;

	Convars.RegisterConvar( "cl_crosshairstyle", "0", "", f );
	Convars.SetChangeCallback( "cl_crosshairstyle", function(...)
	{
		CSHud.m_bCvarChange = true;

		switch ( Convars.GetInt("cl_crosshairstyle") )
		{
		case 0:
			CSHud.m_pCrosshair.self.SetCallback( "Paint", CSHud.m_pCrosshair.PaintStyle0.bindenv( CSHud.m_pCrosshair ) );
			return;
		case 1:
			CSHud.m_pCrosshair.self.SetCallback( "Paint", CSHud.m_pCrosshair.PaintStyle1.bindenv( CSHud.m_pCrosshair ) );
			return;
		case 3:
			CSHud.m_pCrosshair.self.SetCallback( "Paint", CSHud.m_pCrosshair.PaintStyle3.bindenv( CSHud.m_pCrosshair ) );
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

function CSGOHudReticle::PerformLayout()
{
	m_cx = XRES(320);
	m_cy = YRES(240);

	m_flAspectRatio = m_cx / m_cy.tofloat();
}

function CSGOHudReticle::SetVehicleCrosshair( state )
{
	m_bGunCrosshair = state;

	if ( !state )
	{
		m_cx = XRES(320);
		m_cy = YRES(240);

		m_bUnableToFire = false;
	}
}

local CSHud = this;
local VS = VS;
local MainViewOrigin = MainViewOrigin,
	MainViewForward = MainViewForward,
	MainViewRight = MainViewRight,
	MainViewUp = MainViewUp,
	ScreenWidth = ScreenWidth,
	ScreenHeight = ScreenHeight;

function CSGOHudReticle::UpdateGunCrosshair()
{
	local vehicle = CSHud.m_hVehicle;
	local vecCrosshair = NetProps.GetPropVector( vehicle, "m_vecGunCrosshair" );
	local fov = NetProps.GetPropFloat( vehicle, "m_ViewSmoothingData.flFOV" );

	local worldToScreen = VS.VMatrix();
	VS.WorldToScreenMatrix( worldToScreen,
			MainViewOrigin(),
			MainViewForward(),
			MainViewRight(),
			MainViewUp(),
			VS.CalcFovX( fov, m_flAspectRatio * 0.75 ),
			m_flAspectRatio,
			7.0,
			30000.0 );

	local screen = VS.WorldToScreen( vecCrosshair, worldToScreen );
	local x = screen.x, y = screen.y;

	if ( x < 0.0 )
		x = 0.0;
	else if ( x > 1.0 )
		x = 1.0;

	if ( y < 0.0 )
		y = 0.0;
	else if ( y > 1.0 )
		y = 1.0;

	local cx = m_cx = ScreenWidth() * x;
	local cy = m_cy = ScreenHeight() * y;

	m_bUnableToFire = NetProps.GetPropInt( vehicle, "m_bUnableToFire" );
}

function CSGOHudReticle::PaintStyle0()
{
	local gapTarget = 6;
	local gap = gapTarget;

	if ( CSHud.m_hVehicle )
	{
		if ( m_bGunCrosshair )
			UpdateGunCrosshair();
	}
	else
	{
		local speed = NetProps.GetPropVector( player, "m_vecVelocity" ).Length();
		gap += RemapValClamped( speed, 0.0, m_flMaxspeed, 0.0, YRES(20) );
		local weapon = CSHud.m_hWeapon;
		if ( weapon )
		{
			local nMuzzleFlashParity = NetProps.GetPropInt( weapon, "m_nMuzzleFlashParity" );
			if ( m_nMuzzleFlashParity != nMuzzleFlashParity )
			{
				m_nMuzzleFlashParity = nMuzzleFlashParity;
				gap += YRES(20);
			}
		}

		if ( m_nGap > gap )
			gap = m_nGap;

		m_nGap = gap = Approach( gapTarget, gap, FrameTime() * 150.0 );
	}

	local cx = m_cx, cy = m_cy;

	surface.DrawTexturedBox( m_hTexCircle, cx - 3, cy - 3, 7, 7, 0xff, 0xff, 0xff, 0xcc );

	surface.SetColor( m_r, m_g, m_b, 0xff );
	surface.DrawLine( cx, cy, cx+1, cy+1 );

	// top
	local x = cx-4;
	local y = cy-gap;
	surface.DrawLine( x, y, x+9, y );

	// bottom
	y = cy+gap;
	surface.DrawLine( x, y, x+9, y );

	// left
	x = cx-gap;
	y = cy-4;
	surface.DrawLine( x, y, x, y+9 );

	// right
	x = cx+gap;
	surface.DrawLine( x, y, x, y+9 );

	gap = YRES(4);
	local size = m_nPipHeight;
	local thickness = m_nPipWidth;
	local thicknessHalf = thickness >> 1;

	// top
	x = cx - thicknessHalf;
	y = cy - gap - size;
	surface.SetTexture( m_hTexPipUp );
	surface.DrawTexturedRect( x, y, thickness, size );

	// bottom
	y = cy + gap + 1;
	surface.DrawTexturedSubRect( x, y, x + thickness, y + size, 0., 1., 1., 0. );

	// left
	x = cx - gap - size;
	y = cy - thicknessHalf;
	surface.SetTexture( m_hTexPipLeft );
	surface.DrawTexturedRect( x, y, size, thickness );

	// right
	x = cx + gap + 1;
	surface.DrawTexturedSubRect( x, y, x + size, y + thickness, 1., 0., 0., 1. );

	if ( m_bUnableToFire )
	{
		surface.DrawTexturedBox( m_hTexFriend, cx - 15, cy - 15, 32, 32, 0xc9, 0x31, 0x21, 0xff );
	}
}

function CSGOHudReticle::PaintStyle1()
{
	if ( CSHud.m_hVehicle )
	{
		if ( m_bGunCrosshair )
			UpdateGunCrosshair();
	}

	local cx = m_cx, cy = m_cy;
	surface.DrawTexturedBox( m_hTexStyle2, cx - 16, cy - 16, 32, 32, m_r, m_g, m_b, 0xff );

	if ( m_bUnableToFire )
	{
		surface.DrawTexturedBox( m_hTexFriend, cx - 15, cy - 15, 32, 32, 0xc9, 0x31, 0x21, 0xff );
	}
}

function CSGOHudReticle::PaintStyle3()
{
	local gapTarget = YRES(m_gap);
	local gap = gapTarget;

	if ( CSHud.m_hVehicle )
	{
		if ( m_bGunCrosshair )
			UpdateGunCrosshair();
	}
	else
	{
		if ( NetProps.GetPropInt( player, "m_Local.m_bDucked" ) )
		{
			if ( ( gapTarget -= YRES(7) ) < 0 )
			{
				gapTarget = 0;
			}
		}

		local speed = NetProps.GetPropVector( player, "m_vecVelocity" ).Length();
		gap += RemapValClamped( speed, 0.0, m_flMaxspeed, 0.0, YRES(20) );
		local weapon = CSHud.m_hWeapon;
		if ( weapon )
		{
			local nMuzzleFlashParity = NetProps.GetPropInt( weapon, "m_nMuzzleFlashParity" );
			if ( m_nMuzzleFlashParity != nMuzzleFlashParity )
			{
				m_nMuzzleFlashParity = nMuzzleFlashParity;
				gap += YRES(20);
			}
		}

		if ( m_nGap > gap )
			gap = m_nGap;

		m_nGap = gap = Approach( gapTarget, gap, FrameTime() * 150.0 );
	}

	surface.SetColor( m_r, m_g, m_b, m_a );

	local cx = m_cx, cy = m_cy;

	local size = YRES(m_size);
	local thickness = YRES(m_thickness);
	local thicknessHalf = thickness >> 1;
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

	if ( m_bUnableToFire )
	{
		surface.DrawTexturedBox( m_hTexFriend, cx - 15, cy - 15, 32, 32, 0xc9, 0x31, 0x21, 0xff );
	}
}

function CSGOHudReticle::PaintStyle4()
{
	if ( CSHud.m_hVehicle )
	{
		if ( m_bGunCrosshair )
			UpdateGunCrosshair();
	}

	surface.SetColor( m_r, m_g, m_b, m_a );

	local cx = m_cx, cy = m_cy;

	local size = YRES(m_size);
	local gap = YRES(m_gap);
	local thickness = YRES(m_thickness);
	local thicknessHalf = thickness >> 1;
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

	if ( m_bUnableToFire )
	{
		surface.DrawTexturedBox( m_hTexFriend, cx - 15, cy - 15, 32, 32, 0xc9, 0x31, 0x21, 0xff );
	}
}

function CSGOHudReticle::SetVisible( state )
{
	m_bVisible = state;
	return self.SetVisible( state );
}
