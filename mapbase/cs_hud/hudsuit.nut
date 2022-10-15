//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;
local surface = surface;


class CSGOHudFlashlight
{
	CSHud = null;
	constructor( CSHud )
	{
		this.CSHud = CSHud;
	}

	self = null
	m_flFlashlight = 0.0

	m_bFade = false
}

function CSGOHudFlashlight::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudFlashlight" )
	self.SetSize( XRES(640), YRES(480) );
	self.SetZPos( 0 );
	self.SetAlpha( 0 );
	self.SetVisible( false );
	self.SetCallback( "Paint", Paint.bindenv(this) );

	m_flFlashlight = 1.0;

	m_bFade = true;
}

function CSGOHudFlashlight::FadeThink(_)
{
	local a = self.GetAlpha();
	if ( a <= 0 )
	{
		self.SetVisible( false );
		return -1;
	}

	self.SetAlpha( a - 15 );
	return 0.015;
}

function CSGOHudFlashlight::StartFade()
{
	if ( m_bFade )
		return;

	m_bFade = true;
	Entities.First().SetContextThink( "CSGOHudFlashlight::FadeOut", FadeThink.bindenv(this), 0.25 );
}

function CSGOHudFlashlight::StopFade()
{
	self.SetAlpha( 255 );
	self.SetVisible( true );

	if ( m_bFade )
	{
		m_bFade = false;
		Entities.First().SetContextThink( "CSGOHudFlashlight::FadeOut", null, 0.0 );
	}
}

function CSGOHudFlashlight::Paint()
{
	local flAlpha = CSHud.m_flBackgroundAlpha;

	local width = YRES(20);
	local height = YRES(22);

	local x0 = YRES(286);
	local y0 = YRES(480) - height;

	// bg
	{
		local w = width / 2;
		surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );
		surface.DrawFilledRectFade( x0, y0, w, height, 0x00, 0xff, true );
		local x = x0 + w;
		surface.DrawFilledRect( x, y0, w, height );
		surface.DrawFilledRectFade( x + w, y0, w, height, 0xff, 0x00, true );
	}

	// bar
	local bar_h = YRES(3.75);
	local bar_w = width;
	local bar_x = x0 + width / 4;
	local bar_y = y0 + YRES(10);

	surface.SetColor( 0x66, 0x66, 0x66, 0xdd );
	surface.DrawFilledRect( bar_x, bar_y, bar_w, bar_h );

	if ( m_flFlashlight > 0.25 )
	{
		surface.SetColor( 0xe7, 0xe7, 0xe7, 0xdd );
	}
	else
	{
		surface.SetColor( 0xff, 0x00, 0x00, 0xdd );
	}

	surface.DrawFilledRect( bar_x, bar_y, bar_w * m_flFlashlight, bar_h );

	// outline
	surface.SetColor( 0x33, 0x33, 0x33, 0x66 );
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
	CSHud = null;
	constructor( CSHud )
	{
		this.CSHud = CSHud;
	}

	self = null
	m_flPower = 0.0

	m_bFade = false
}

function CSGOHudSuitPower::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudSuitPower" )
	self.SetSize( XRES(640), YRES(480) );
	self.SetZPos( 0 );
	self.SetAlpha( 0 );
	self.SetVisible( false );
	self.SetCallback( "Paint", Paint.bindenv(this) );

	m_flPower = 1.0;

	m_bFade = true;
}

function CSGOHudSuitPower::FadeThink(_)
{
	local a = self.GetAlpha();
	if ( a <= 0 )
	{
		self.SetVisible( false );
		return -1;
	}

	self.SetAlpha( a - 15 );
	return 0.015;
}

function CSGOHudSuitPower::StartFade()
{
	if ( m_bFade )
		return;

	m_bFade = true;
	Entities.First().SetContextThink( "CSGOHudSuitPower::FadeOut", FadeThink.bindenv(this), 0.25 );
}

function CSGOHudSuitPower::StopFade()
{
	self.SetAlpha( 255 );
	self.SetVisible( true );

	if ( m_bFade )
	{
		m_bFade = false;
		Entities.First().SetContextThink( "CSGOHudSuitPower::FadeOut", null, 0.0 );
	}
}

function CSGOHudSuitPower::Paint()
{
	local flAlpha = CSHud.m_flBackgroundAlpha;

	local width = YRES(50);
	local height = YRES(22);

	local x0 = YRES(204);
	local y0 = YRES(480) - height;

	// bg
	{
		local w = width / 2;
		surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );
		surface.DrawFilledRectFade( x0, y0, w, height, 0x00, 0xff, true );
		local x = x0 + w;
		surface.DrawFilledRect( x, y0, w, height );
		surface.DrawFilledRectFade( x + w, y0, w, height, 0xff, 0x00, true );
	}

	// bar
	local bar_h = YRES(3.75);
	local bar_w = width;
	local bar_x = x0 + width / 4;
	local bar_y = y0 + YRES(10);

	surface.SetColor( 0x66, 0x66, 0x66, 0xdd );
	surface.DrawFilledRect( bar_x, bar_y, bar_w, bar_h );

	if ( m_flPower > 0.25 )
	{
		surface.SetColor( 0xe7, 0xe7, 0xe7, 0xdd );
	}
	else
	{
		surface.SetColor( 0xff, 0x00, 0x00, 0xdd );
	}

	surface.DrawFilledRect( bar_x, bar_y, bar_w * m_flPower, bar_h );

	// outline
	surface.SetColor( 0x33, 0x33, 0x33, 0x66 );
	surface.DrawOutlinedRect( bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2, 1 );
}
