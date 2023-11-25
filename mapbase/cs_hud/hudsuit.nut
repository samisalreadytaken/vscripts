//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local CSHud = this;
local XRES = XRES, YRES = YRES;
local surface = surface;


class CSGOHudFlashlight
{
	self = null
	m_flFlashlight = 0.0

	m_bFading = false
}

function CSGOHudFlashlight::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudFlashlight" )
	self.SetSize( XRES(640), YRES(480) );
	self.SetVisible( false );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "Paint", Paint.bindenv(this) );

	m_flFlashlight = 1.0;

	m_bFading = true;
}

function CSGOHudFlashlight::FadeOut()
{
	if ( m_bFading )
		return;

	m_bFading = true;
	CSHud.PanelFadeOut( "CSGOHudFlashlight", self, 0.25 );
}

function CSGOHudFlashlight::SetVisible()
{
	self.SetAlpha( 255 );
	self.SetVisible( true );

	if ( m_bFading )
	{
		m_bFading = false;
		CSHud.StopPanelFadeOut( "CSGOHudFlashlight" );
	}
}

function CSGOHudFlashlight::Paint()
{
	local width = YRES(20);
	local height = YRES(22);

	local x0 = YRES(286);
	local y0 = YRES(480) - height;

	// bg
	{
		local flAlpha = CSHud.m_flBackgroundAlpha;

		local w = width / 2;
		surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );
		surface.DrawFilledRectFade( x0, y0, w, height, 0x00, 0xff, true );
		local x = x0 + w;
		surface.DrawFilledRect( x, y0, w, height );
		surface.DrawFilledRectFade( x + w, y0, w, height, 0xff, 0x00, true );
	}

	// bar
	local bar_h = YRES(4.5);
	local bar_w = width;
	local bar_x = x0 + width / 4;
	local bar_y = y0 + YRES(10);

	surface.SetColor( 0x66, 0x66, 0x66, 0x99 );
	surface.DrawFilledRect( bar_x, bar_y, bar_w, bar_h );

	if ( m_flFlashlight > 0.25 )
	{
		surface.SetColor( 0xe7, 0xe7, 0xe7, 0xff );
	}
	else
	{
		surface.SetColor( 0xff, 0x00, 0x00, 0xff );
	}

	surface.DrawFilledRect( bar_x, bar_y, bar_w * m_flFlashlight, bar_h );

	// outline
	surface.SetColor( 0x88, 0x88, 0x88, 0x7f );
	surface.DrawOutlinedRect( bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2, 1 );

	// icon
	//surface.SetTextFont( surface.GetFont( "weapon-selection-item-icon", true ) );
	//surface.SetTextColor( 0xe7, 0xe7, 0xe7, 0xdd );
	//surface.SetTextPos( x0 + YRES(3), y0 - YRES(15) );
	//surface.DrawUnicodeChar( 174, 0 );
}


//---------------------------------------------------------------------
//---------------------------------------------------------------------


class CSGOHudSuitPower
{
	self = null
	m_flPower = 0.0

	m_bFading = false
}

function CSGOHudSuitPower::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudSuitPower" )
	self.SetSize( XRES(640), YRES(480) );
	self.SetVisible( false );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "Paint", Paint.bindenv(this) );

	m_flPower = 1.0;

	m_bFading = true;
}

function CSGOHudSuitPower::FadeOut()
{
	if ( m_bFading )
		return;

	m_bFading = true;
	CSHud.PanelFadeOut( "CSGOHudSuitPower", self, 0.25 );
}

function CSGOHudSuitPower::SetVisible()
{
	self.SetAlpha( 255 );
	self.SetVisible( true );

	if ( m_bFading )
	{
		m_bFading = false;
		CSHud.StopPanelFadeOut( "CSGOHudSuitPower" );
	}
}

function CSGOHudSuitPower::Paint()
{
	local width = YRES(50);
	local height = YRES(22);

	local x0 = YRES(204);
	local y0 = YRES(480) - height;

	// bg
	{
		local flAlpha = CSHud.m_flBackgroundAlpha;

		local w = width / 2;
		surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );
		surface.DrawFilledRectFade( x0, y0, w, height, 0x00, 0xff, true );
		local x = x0 + w;
		surface.DrawFilledRect( x, y0, w, height );
		surface.DrawFilledRectFade( x + w, y0, w, height, 0xff, 0x00, true );
	}

	// bar
	local bar_h = YRES(4.5);
	local bar_w = width;
	local bar_x = x0 + width / 4;
	local bar_y = y0 + YRES(10);

	surface.SetColor( 0x66, 0x66, 0x66, 0x99 );
	surface.DrawFilledRect( bar_x, bar_y, bar_w, bar_h );

	if ( m_flPower > 0.25 )
	{
		surface.SetColor( 0xe7, 0xe7, 0xe7, 0xff );
	}
	else
	{
		surface.SetColor( 0xff, 0x00, 0x00, 0xff );
	}

	surface.DrawFilledRect( bar_x, bar_y, bar_w * m_flPower, bar_h );

	// outline
	surface.SetColor( 0x88, 0x88, 0x88, 0x7f );
	surface.DrawOutlinedRect( bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2, 1 );
}
