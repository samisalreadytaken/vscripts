//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local CSHud = this;
local XRES = XRES, YRES = YRES;
local surface = surface;

class CSGOHudSquadStatus
{
	self = null
	m_iSquadMembers = 0
	m_hFont = null
	m_hFontIcon = null
	m_iIconWidth = 0
	m_iIconHeight = 0
	m_bVisible = false
}

function CSGOHudSquadStatus::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudSquadStatus" )
	self.SetSize( ScreenWidth(), ScreenHeight() );
	self.SetZPos( 0 );
	self.SetAlpha( 0 );
	self.SetVisible( m_bVisible );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "Paint", Paint.bindenv(this) );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );

	m_hFont = surface.GetFont( "hud-HA-text-sm", true );
	m_hFontIcon = surface.GetFont( "SquadIcon", true, "ClientScheme" );
}

function CSGOHudSquadStatus::PerformLayout()
{
	m_iIconWidth = surface.GetCharacterWidth( m_hFontIcon, 'C' );
	m_iIconHeight = surface.GetFontTall( m_hFontIcon ) / 3;
}

function CSGOHudSquadStatus::Paint()
{
	local width = YRES(64);
	local height = YRES(22);

	local scrh = YRES(480);

	local x0 = XRES(394);
	local y0 = scrh - height;

	// bg
	{
		local flAlpha = CSHud.m_flBackgroundAlpha;

		local w = width / 4;
		surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );
		surface.DrawFilledRectFade( x0, y0, w, height, 0x00, 0xff, true );
		local x = x0 + w;
		surface.DrawFilledRect( x, y0, w + w, height );
		surface.DrawFilledRectFade( x + w + w, y0, w, height, 0xff, 0x00, true );
	}

	surface.SetTextFont( m_hFontIcon );
	surface.SetTextColor( 0xe7, 0xe7, 0xe7, 0x99 );

	local iconWidth = m_iIconWidth;
	local iconWidthHalf = iconWidth / 2;
	local y = y0 - m_iIconHeight;

	local c = m_iSquadMembers;
	if ( c < 6 )
	{
		local spacing = iconWidth + YRES(2);
		local totalWidth = (c-1) * spacing;
		local x = x0 + ( width - totalWidth ) / 2 - iconWidthHalf;

		while ( c-- )
		{
			surface.SetTextPos( x, y );
			surface.DrawUnicodeChar( 'C', 0 );
			x += spacing;
		}
	}
	else
	{
		local x = x0 + ( width ) / 2 - iconWidthHalf;

		surface.SetTextPos( x, y );
		surface.DrawUnicodeChar( 'C', 0 );

		surface.SetTextFont( m_hFont );
		surface.SetTextColor( 0xcc, 0xcc, 0xcc, 0xff );
		surface.SetTextPos( x + iconWidth, y0 + YRES(8.5) );
		surface.DrawUnicodeChar( 'x', 0 );
		surface.DrawText( ""+c, 0 );
	}
}

function CSGOHudSquadStatus::SetVisible( state )
{
	m_bVisible = state;
	return self.SetVisible( state );
}
