//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;
local surface = surface, Time = Time, SimpleSpline = SimpleSpline, split = split,
	Entities = Entities, Localize = Localize;

const kHudHintDisplayTime = 4.0;
const kHudHintEndYPos = 91;
const kHudHintIconSize = 13;
const kHudHintIconMargin = 3;
const kHudHintTextPad = 2;

class CSGOHudHintText
{
	self = null

	m_bFading = false

	m_flStartTime = 0.0
	m_nYPos = 0
	m_nTextWidth = 0
	m_nTotalHeight = 0
	m_nEndYPos = 0
	m_Lines = null

	m_hFont = null
	m_hIcon = null
	m_hIconInfo = null
	m_hIconAlert = null
}

function CSGOHudHintText::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudHintText" );
	self.SetSize( XRES(640), YRES(480) );
	self.SetZPos( 10 );
	self.SetVisible( false );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "Paint", Paint.bindenv(this) );

	m_hFont = surface.GetFont( "hud-hint__text", true );
	m_hIconInfo = surface.ValidateTexture( "panorama/images/icons/ui/info", true );
	m_hIconAlert = surface.ValidateTexture( "panorama/images/icons/ui/alert", true );

	m_Lines = [];

	ListenToGameEvent( "player_hintmessage", FireGameEvent.bindenv(this), "CSGOHudHintText" );
}

function CSGOHudHintText::FireGameEvent( event )
{
	Display( event.hintmessage );
}

function CSGOHudHintText::Display( msg )
{
	if ( !( 0 in msg ) )
		return SetVisible( false );

	if ( msg[0] == '#' )
		msg = Localize.Find( msg );

	local width = 0;
	local height = 1;

	if ( msg.find("\n") == null )
	{
		width = surface.GetTextWidth( m_hFont, msg );

		m_Lines.clear();
		m_Lines.append( msg );
	}
	else
	{
		local lines = split( msg, "\n" );
		foreach ( s in lines )
		{
			local w = surface.GetTextWidth( m_hFont, s );
			if ( w > width )
			{
				width = w;
			}
		}

		height = lines.len();
		m_Lines = lines;
	}

	height *= surface.GetFontTall( m_hFont );
	height += YRES(kHudHintIconSize + kHudHintIconMargin + kHudHintTextPad*2);

	m_nTextWidth = width;
	m_nTotalHeight = height;

	// This isn't adjusted in csgo, the text beyond is not visible there
	if ( YRES(kHudHintEndYPos) + height < YRES(240) )
	{
		m_nEndYPos = YRES(kHudHintEndYPos);
	}
	else
	{
		m_nEndYPos = YRES(240) - height - surface.GetFontTall( m_hFont );
	}

	return SetVisible( true );
}

function CSGOHudHintText::Paint()
{
	local width = YRES(304);
	local cx = XRES(320);
	local x0 = cx - ( width >> 1 ) - YRES(1);
	local y0 = m_nYPos;
	local height = m_nTotalHeight;

	// background
	{
		surface.SetColor( 0x00, 0x00, 0x00, 0xff );

		local w10 = width / 10;
		local w50 = width / 4;
		local w25 = w50 - w10;
		local x = x0;

		surface.DrawFilledRectFade( x       , y0, w10, height, 0x00, 0x0d, true );
		surface.DrawFilledRectFade( x += w10, y0, w25, height, 0x0d, 0x99, true );
		surface.DrawFilledRectFade( x += w25, y0, w50, height, 0x99, 0x80, true );
		surface.DrawFilledRectFade( x += w50, y0, w50, height, 0x80, 0x99, true );
		surface.DrawFilledRectFade( x += w50, y0, w25, height, 0x99, 0x0d, true );
		surface.DrawFilledRectFade( x +  w25, y0, w10, height, 0x0d, 0x00, true );
	}

	{
		// hrTop
		local w05 = width / 20;
		local w50 = width / 2 - w05;
		local x = x0;

		surface.DrawFilledRectFade( x       , y0, w05, 1, 0x00, 0x12, true );
		surface.DrawFilledRectFade( x += w05, y0, w50, 1, 0x12, 0x80, true );
		surface.DrawFilledRectFade( x += w50, y0, w50, 1, 0x80, 0x12, true );
		surface.DrawFilledRectFade( x +  w50, y0, w05, 1, 0x12, 0x00, true );

		// hrBot
		x = x0;
		local y = y0 + height - 1;

		surface.DrawFilledRectFade( x       , y, w05, 1, 0x00, 0x12, true );
		surface.DrawFilledRectFade( x += w05, y, w50, 1, 0x12, 0x80, true );
		surface.DrawFilledRectFade( x += w50, y, w50, 1, 0x80, 0x12, true );
		surface.DrawFilledRectFade( x +  w50, y, w05, 1, 0x12, 0x00, true );
	}

	// icon
	local iconSize = YRES(kHudHintIconSize);
	local y = y0 + YRES(kHudHintIconMargin);
	{
		// This is centered unlike in CSGO
		local x = cx - ( iconSize >> 1 );
		// No shadow in csgo
		surface.DrawTexturedBox( m_hIcon, x, y, iconSize, iconSize, 0xff, 0xff, 0xff, 0xff );
	}

	// text
	{
		local x = cx - ( m_nTextWidth >> 1 );
		y += iconSize + YRES(kHudHintTextPad);

		surface.SetTextFont( m_hFont );
		local tall = surface.GetFontTall( m_hFont );
		foreach ( line in m_Lines )
		{
			// shadow
			surface.SetTextPos( x+1, y+1 );
			surface.SetTextColor( 0x00, 0x00, 0x00, 0x88 );
			surface.DrawText( line, 0 );

			// text
			surface.SetTextPos( x, y );
			surface.SetTextColor( 0xff, 0xff, 0xff, 0xff );
			surface.DrawText( line, 0 );

			y += tall;
		}
	}
}

function CSGOHudHintText::Think(_)
{
	local dt = ( Time() - m_flStartTime );

	if ( m_bFading )
	{
		local startpos = YRES(kHudHintEndYPos << 1);

		local t = dt / 0.2;
		if ( t < 1.0 )
		{
			m_nYPos = YRES(240) + startpos + ( m_nEndYPos - startpos ) * SimpleSpline(t);
			self.SetAlpha( 255 * t );
		}
		else
		{
			m_nYPos = YRES(240) + m_nEndYPos;
			self.SetAlpha( 255 );
			m_bFading = false;
		}
	}
	else
	{
		if ( dt > kHudHintDisplayTime )
		{
			self.SetVisible( false );
			return -1;
		}
	}

	return 0.0;
}

function CSGOHudHintText::SetVisible( state, priority = false )
{
	if ( state )
	{
		if ( priority )
		{
			// TODO: Set colour and the "Alert" text
			m_hIcon = m_hIconAlert;
		}
		else
		{
			m_hIcon = m_hIconInfo;
		}

		m_flStartTime = Time();

		if ( !m_bFading && !self.IsVisible() )
		{
			m_bFading = true;
			self.SetVisible( true );
			self.SetAlpha( 0 );
			m_nYPos = YRES(240 + (kHudHintEndYPos << 1));
			return Entities.First().SetContextThink( "CSGOHudHintText.FadeIn", Think.bindenv(this), 0.0 );
		}
	}
	else
	{
		self.SetVisible( false );
		return Entities.First().SetContextThink( "CSGOHudHintText.FadeIn", null, 0.0 );
	}
}

{
	local CONST = getconsttable();
	delete CONST.kHudHintDisplayTime;
	delete CONST.kHudHintEndYPos;
	delete CONST.kHudHintIconSize;
	delete CONST.kHudHintIconMargin;
	delete CONST.kHudHintTextPad;
}
