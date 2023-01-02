//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;
local surface = surface;

local kClrNormal = [ surface, 0xe7, 0xe7, 0xe7, 0xdd ];
local kClrLow = [ surface, 0xff, 0x00, 0x00, 0xdd ];


class CSGOHudHealthArmor
{
	CSHud = null;
	constructor( CSHud )
	{
		this.CSHud = CSHud;
	}

	self = null

	m_flMaxHealth = 100.0
	m_nHealth = -1
	m_flHealth = 0.0
	m_szHealth = "0"

	m_flMaxArmor = 100.0
	m_nArmor = -1
	m_flArmor = 0.0
	m_szArmor = "0"

	m_clrHealthBar = null

	m_nHealthWarningThreshold = 0

	m_hFont = null
	m_hFontBlur = null
	m_hFontIcon = null
	m_hFontIconBlur = null

	m_nOffsetArmorLabel = 0
	m_nOffsetHealthLabel = 0
	m_nHealthLabelWide = 0
}

function CSGOHudHealthArmor::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudHealthArmor" );
	self.SetSize( XRES(640), YRES(480) );
	self.SetZPos( 2 );
	self.SetVisible( true );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );
	self.SetCallback( "OnTick", OnTick.bindenv(this) );
	self.SetCallback( "Paint", Paint.bindenv(this) );
	self.AddTickSignal( 100 );

	m_hFont = surface.GetFont( "hud-HA-text", true );
	m_hFontBlur = surface.GetFont( "hud-HA-text-blur", true );
	m_hFontIcon = surface.GetFont( "hud-HA-icon", true );
	m_hFontIconBlur = surface.GetFont( "hud-HA-icon-blur", true );

	m_clrHealthBar = kClrNormal;
}

function CSGOHudHealthArmor::SetArmor( nArmor )
{
	m_nArmor = nArmor;
	m_flArmor = nArmor / m_flMaxArmor;
	local text = m_szArmor = "" + nArmor;
	m_nOffsetArmorLabel = (m_nHealthLabelWide - surface.GetTextWidth( m_hFont, text ))/2;

	if ( m_flArmor > 1.0 )
		m_flArmor = 1.0;
}

function CSGOHudHealthArmor::PerformLayout()
{
	m_nHealthLabelWide = surface.GetCharacterWidth( m_hFont, '0' ) * 3;

	// Recalculate
	m_nHealth = m_nArmor = -1;
	OnTick();
}

function CSGOHudHealthArmor::ThinkRestoreColour(_)
{
	m_clrHealthBar = kClrNormal;
}

function CSGOHudHealthArmor::OnTick()
{
	local nHealth = player.GetHealth();

	if ( nHealth < 0 )
		nHealth = 0;

	if ( nHealth == m_nHealth )
		return;

	// flash the health bar red when hurt
	if ( nHealth < m_nHealth && nHealth > m_nHealthWarningThreshold )
	{
		m_clrHealthBar = kClrLow;
		// use a think func instead of keeping time
		Entities.First().SetContextThink( "CSGOHudHealthArmor", ThinkRestoreColour.bindenv(this), 1.0 );
	}

	m_nHealth = nHealth;
	m_flHealth = nHealth / m_flMaxHealth;
	local text = m_szHealth = "" + nHealth;

	m_nOffsetHealthLabel = (m_nHealthLabelWide - surface.GetTextWidth( m_hFont, text ))/2;

	if ( m_flHealth > 1.0 )
		m_flHealth = 1.0;
}

function CSGOHudHealthArmor::DrawBackground( bHealthThreshold, flAlpha, height, y0 )
{
	if ( bHealthThreshold )
	{
		surface.SetColor( 0x77, 0, 0, 0xEE * flAlpha );

		if ( CSHud.m_bSuitEquipped )
		{
			local w = YRES(12);
			local x = w;
			surface.DrawFilledRectFade( 0, y0, w, height, 0x00, 0xff, true );
			w = YRES(79);
			surface.DrawFilledRect( x, y0, w, height );
			surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );
			x += w;
			w = YRES(32);
			surface.DrawFilledRect( x, y0, w, height );
			surface.DrawFilledRectFade( x + w, y0, YRES(50), height, 0xff, 0x00, true );
		}
		else
		{
			local w = YRES(12);
			local x = w;
			surface.DrawFilledRectFade( 0, y0, w, height, 0x00, 0xff, true );
			w = YRES(32);
			surface.DrawFilledRect( x, y0, w, height );
			surface.DrawFilledRectFade( x + w, y0, YRES(46), height, 0xff, 0x00, true );
		}
	}
	else
	{
		surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );

		if ( CSHud.m_bSuitEquipped )
		{
			local w = YRES(12);
			local x = w;
			surface.DrawFilledRectFade( 0, y0, w, height, 0x00, 0xff, true );
			w = YRES(110);
			surface.DrawFilledRect( x, y0, w, height );
			surface.DrawFilledRectFade( x + w, y0, YRES(50), height, 0xff, 0x00, true );
		}
		else
		{
			local w = YRES(12);
			local x = w;
			surface.DrawFilledRectFade( 0, y0, w, height, 0x00, 0xff, true );
			w = YRES(32);
			surface.DrawFilledRect( x, y0, w, height );
			surface.DrawFilledRectFade( x + w, y0, YRES(46), height, 0xff, 0x00, true );
		}
	}
}

function CSGOHudHealthArmor::Paint()
{
	if ( m_nHealth > 0 )
	{
		local flAlpha = CSHud.m_flBackgroundAlpha;

		// local width = YRES(172);
		local height = YRES(22);
		local y0 = YRES(480) - height;

		local bar_w = YRES(32.5);
		local bar_h = YRES(3.75);
		{
			local icon_x = YRES(12);
			local bar_x = YRES(51);
			local bar_progress = (bar_w * m_flHealth).tointeger();

			if ( m_nHealth <= m_nHealthWarningThreshold )
			{
				DrawBackground( true, flAlpha, height, y0 );

				// health bar
				surface.SetColor.acall( kClrLow );
				surface.DrawFilledRect( bar_x, y0 + YRES(10), bar_progress, bar_h );

				// health icon
				surface.SetTextFont( m_hFontIcon );
				surface.SetTextColor( 0xff, 0x00, 0x00, 0xdd );
				surface.SetTextPos( icon_x, y0 );
				surface.DrawUnicodeChar( '+', 0 );

				// blur
				surface.DrawColoredText( m_hFontBlur, YRES(21) + m_nOffsetHealthLabel, y0, 0xdd, 0x00, 0x00, 0xff, m_szHealth );
			}
			else
			{
				DrawBackground( false, flAlpha, height, y0 );

				// health bar
				surface.SetColor.acall( m_clrHealthBar );
				surface.DrawFilledRect( bar_x, y0 + YRES(10), bar_progress, bar_h );

				// health icon blur
				surface.SetTextFont( m_hFontIconBlur );
				surface.SetTextColor( 0x00, 0x00, 0x00, 0xff );
				surface.SetTextPos( icon_x, y0 );
				surface.DrawUnicodeChar( '+', 0 );

				// health icon
				surface.SetTextFont( m_hFontIcon );
				surface.SetTextColor( 0xcc, 0xcc, 0xcc, 0xcc );
				surface.SetTextPos( icon_x, y0 );
				surface.DrawUnicodeChar( '+', 0 );

				// blur
				surface.DrawColoredText( m_hFontBlur, YRES(21) + m_nOffsetHealthLabel, y0, 0x00, 0x00, 0x00, 0xff, m_szHealth );
			}

			// health bar
			if ( m_flHealth < 1.0 )
			{
				surface.SetColor( 0x66, 0x66, 0x66, 0xdd );
				surface.DrawFilledRect( bar_x + bar_progress, y0 + YRES(10), bar_w - bar_progress, bar_h );
			}

			// bar outline
			surface.SetColor( 0x33, 0x33, 0x33, 0x66 );
			surface.DrawOutlinedRect( bar_x - 1, y0 + YRES(10) - 1, bar_w + 2, bar_h + 2, 1 );

			// health label
			surface.DrawColoredText( m_hFont, YRES(21) + m_nOffsetHealthLabel, y0, 0xff, 0xff, 0xff, 0xff, m_szHealth );
		}

		if ( CSHud.m_bSuitEquipped )
		{
			local icon_x = YRES(96);
			local bar_x = YRES(136);
			local bar_progress = (bar_w * m_flArmor).tointeger();

			// armour bar
			surface.SetColor( 0xe7, 0xe7, 0xe7, 0xdd );
			surface.DrawFilledRect( bar_x, y0 + YRES(10), bar_progress, bar_h );

			if ( m_flArmor < 1.0 )
			{
				surface.SetColor( 0x66, 0x66, 0x66, 0xdd );
				surface.DrawFilledRect( bar_x + bar_progress, y0 + YRES(10), bar_w - bar_progress, bar_h );
			}

			// bar outline
			surface.SetColor( 0x33, 0x33, 0x33, 0x66 );
			surface.DrawOutlinedRect( bar_x - 1, y0 + YRES(10) - 1, bar_w + 2, bar_h + 2, 1 );

			// armour icon blur
			surface.SetTextFont( m_hFontIconBlur );
			surface.SetTextColor( 0x00, 0x00, 0x00, 0xff );
			surface.SetTextPos( icon_x, y0 );
			surface.DrawUnicodeChar( '*', 0 );

			// armour icon
			surface.SetTextFont( m_hFontIcon );
			surface.SetTextColor( 0xcc, 0xcc, 0xcc, 0xcc );
			surface.SetTextPos( icon_x, y0 );
			surface.DrawUnicodeChar( '*', 0 );

			// blur
			surface.DrawColoredText( m_hFontBlur, YRES(105) + m_nOffsetArmorLabel, y0, 0x00, 0x00, 0x00, 0xff, m_szArmor );

			// armour label
			surface.DrawColoredText( m_hFont, YRES(105) + m_nOffsetArmorLabel, y0, 0xff, 0xff, 0xff, 0xff, m_szArmor );
		}
	}
}
