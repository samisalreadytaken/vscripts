//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local CSHud = this;
local XRES = XRES, YRES = YRES;
local surface = surface, Entities = Entities;

local kClrNormal = [ surface, 0xe7, 0xe7, 0xe7, 0xff ];
local kClrLow = [ surface, 0xff, 0x00, 0x00, 0xdd ];

const kHudHealthPanelHeight = 22;


class CSGOHudHealthArmor
{
	constructor( player )
	{
		this.player = player;
	}

	self = null
	player = null

	m_bDrawArmor = true

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

	m_hFontLarge = null
	m_hFontLargeBlur = null
	m_hFontSm = null
	m_hFontSmBlur = null

	m_hFontHealth = null
	m_hFontHealthBlur = null
	m_hFontArmor = null
	m_hFontArmorBlur = null

	m_hTexHealth = null
	m_hTexArmor = null

	m_nOffsetHealthLabelX = 0
	m_nOffsetHealthLabelY = 0
	m_nOffsetArmorLabelX = 0
	m_nOffsetArmorLabelY = 0
	m_nLabelWide = 0
}

function CSGOHudHealthArmor::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudHealthArmor" );
	self.SetVisible( false );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );
	self.SetCallback( "OnTick", OnTick.bindenv(this) );
	self.SetCallback( "Paint", Paint.bindenv(this) );
	self.AddTickSignal( 100 );

	m_hFontLarge = surface.GetFont( "hud-HA-text", true );
	m_hFontLargeBlur = surface.GetFont( "hud-HA-text-blur", true );

	m_hFontSm = surface.GetFont( "hud-HA-text-medium", true );
	m_hFontSmBlur = surface.GetFont( "hud-HA-text-medium-blur", true );

	m_hTexHealth = surface.ValidateTexture( "panorama/images/icons/ui/health", true );
	m_hTexArmor = surface.ValidateTexture( "panorama/images/icons/ui/shield", true );

	m_clrHealthBar = kClrNormal;
}

function CSGOHudHealthArmor::PerformLayout()
{
	// margin-left
	self.SetPos( YRES(3.15), 0 );
	self.SetSize( XRES(640) - self.GetXPos(), YRES(480) );

	m_nLabelWide = surface.GetCharacterWidth( m_hFontLarge, '0' ) * 3;

	// Recalculate
	m_nHealth = m_hFontHealth = m_hFontArmor = -1;
	OnTick();
	SetArmor( m_nArmor );
}

local ThinkRestoreColour = function(_)
{
	m_clrHealthBar = kClrNormal;
}

function CSGOHudHealthArmor::SetArmor( nArmor )
{
	m_nArmor = nArmor;
	m_flArmor = nArmor / m_flMaxArmor;

	if ( m_flArmor > 1.0 )
		m_flArmor = 1.0;

	if ( nArmor < 1000 )
	{
		if ( m_hFontArmor != m_hFontLarge )
		{
			m_hFontArmor = m_hFontLarge;
			m_hFontArmorBlur = m_hFontLargeBlur;
			m_nOffsetArmorLabelY = ( YRES(kHudHealthPanelHeight) - surface.GetFontTall( m_hFontArmor ) ) >> 1;
		}
	}
	else
	{
		if ( m_hFontArmor != m_hFontSm )
		{
			m_hFontArmor = m_hFontSm;
			m_hFontArmorBlur = m_hFontSmBlur;
			m_nOffsetArmorLabelY = ( YRES(kHudHealthPanelHeight) - surface.GetFontTall( m_hFontArmor ) ) >> 1;
		}
	}

	local text = m_szArmor = "" + nArmor;
	m_nOffsetArmorLabelX = ( m_nLabelWide - surface.GetTextWidth( m_hFontArmor, text ) ) >> 1;
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
		Entities.First().SetContextThink( "CSGOHudHealthArmor", ThinkRestoreColour.bindenv(this), 1.0 );
	}

	m_nHealth = nHealth;
	m_flHealth = nHealth / m_flMaxHealth;

	if ( m_flHealth > 1.0 )
		m_flHealth = 1.0;

	if ( nHealth < 1000 )
	{
		if ( m_hFontHealth != m_hFontLarge )
		{
			m_hFontHealth = m_hFontLarge;
			m_hFontHealthBlur = m_hFontLargeBlur;
			m_nOffsetHealthLabelY = ( YRES(kHudHealthPanelHeight) - surface.GetFontTall( m_hFontHealth ) ) >> 1;
		}
	}
	else
	{
		if ( m_hFontHealth != m_hFontSm )
		{
			m_hFontHealth = m_hFontSm;
			m_hFontHealthBlur = m_hFontSmBlur;
			m_nOffsetHealthLabelY = ( YRES(kHudHealthPanelHeight) - surface.GetFontTall( m_hFontHealth ) ) >> 1;
		}
	}

	local text = m_szHealth = "" + nHealth;
	m_nOffsetHealthLabelX = ( m_nLabelWide - surface.GetTextWidth( m_hFontHealth, text ) ) >> 1;
}

function CSGOHudHealthArmor::DrawBackground( bHealthThreshold, height, y0 )
{
	local flAlpha = CSHud.m_flBackgroundAlpha;

	if ( m_bDrawArmor )
	{
		local width_a = YRES(82);
		local width_h = YRES(87);
		local x = 0;
		local w = width_h / 10;

		if ( bHealthThreshold )
		{
			// health
			surface.SetColor( 0x77, 0x00, 0x00, flAlpha * 0xEE );

			surface.DrawFilledRectFade( x, y0, w, height, 0x00, 0xFF, true );
			x += w;
			w = width_h - w;
			surface.DrawFilledRectFade( x, y0, w, height, 0xFF, 0xFF, true );

			// armor
			surface.SetColor( 0x00, 0x00, 0x00, flAlpha * 0xcc );

			x += w;
			w = width_a * 40 / 100;
			surface.DrawFilledRect( x, y0, w, height );
			x += w;
			w = width_a - w;
			return surface.DrawFilledRectFade( x, y0, w, height, 0xFF, 0x00, true );
		}
		else
		{
			surface.SetColor( 0x00, 0x00, 0x00, flAlpha * 0xcc );

			// health
			surface.DrawFilledRectFade( x, y0, w, height, 0x00, 0xEE, true );
			x += w;
			w = width_h - w;
			surface.DrawFilledRectFade( x, y0, w, height, 0xEE, 0xFF, true );

			// armor
			x += w;
			w = width_a * 40 / 100;
			surface.DrawFilledRect( x, y0, w, height );
			x += w;
			w = width_a - w;
			return surface.DrawFilledRectFade( x, y0, w, height, 0xFF, 0x00, true );
		}
	}
	else
	{
		if ( bHealthThreshold )
		{
			surface.SetColor( 0x77, 0x00, 0x00, flAlpha * 0xEE );
		}
		else
		{
			surface.SetColor( 0x00, 0x00, 0x00, flAlpha * 0xcc );
		}

		local x = 0;
		local w = YRES(8.7);
		surface.DrawFilledRectFade( x, y0, w, height, 0x00, 0xff, true );
		x += w;
		w = YRES(32.8);
		surface.DrawFilledRect( x, y0, w, height );
		x += w;
		w = YRES(49.2);
		return surface.DrawFilledRectFade( x, y0, w, height, 0xff, 0x00, true );
	}
}

//
// NOTE:
// There is no progress bar drop shadow
// Positions are not pixel perfect on every resolution
//
function CSGOHudHealthArmor::Paint()
{
	local height = YRES(kHudHealthPanelHeight);
	local y0 = YRES(480) - height;

	local bar_w = YRES(32.9);
	local bar_h = YRES(4.25);
	local bar_y = YRES(10) + y0;
	local icon_y = YRES(7) + y0;
	{
		local icon_s = YRES(8.75);
		local icon_x = YRES(8.5);
		local bar_x = YRES(48);
		local bar_progress = (bar_w * m_flHealth + 0.71).tointeger();
		local label_x = YRES(19) + m_nOffsetHealthLabelX;
		local label_y = m_nOffsetHealthLabelY + y0;

		if ( m_nHealth > m_nHealthWarningThreshold )
		{
			DrawBackground( false, height, y0 );

			// health bar
			surface.SetColor.acall( m_clrHealthBar );
			surface.DrawFilledRect( bar_x, bar_y, bar_progress, bar_h );

			// health icon
			surface.DrawTexturedBox( m_hTexHealth, icon_x, icon_y, icon_s, icon_s, 0xcc, 0xcc, 0xcc, 165 );

			// health label blur
			surface.DrawColoredText( m_hFontHealthBlur, label_x, label_y, 0x00, 0x00, 0x00, 0xff, m_szHealth );
		}
		else
		{
			DrawBackground( true, height, y0 );

			// health bar
			surface.SetColor.acall( kClrLow );
			surface.DrawFilledRect( bar_x, bar_y, bar_progress, bar_h );

			// health icon
			surface.DrawTexturedBox( m_hTexHealth, icon_x, icon_y, icon_s, icon_s, 0xff, 0x00, 0x00, 165 );

			// label blur
			// NOTE: Glow is too weak, draw it twice
			surface.DrawColoredText( m_hFontHealthBlur, label_x, label_y, 0xff, 0x00, 0x00, 0xff, m_szHealth );
			surface.DrawColoredText( m_hFontHealthBlur, label_x, label_y, 0xff, 0x00, 0x00, 0xff, m_szHealth );
		}

		// health bar
		if ( m_flHealth < 1.0 )
		{
			surface.SetColor( 0x66, 0x66, 0x66, 0x99 );
			surface.DrawFilledRect( bar_x + bar_progress, bar_y, bar_w - bar_progress, bar_h );
		}

		// bar outline
		surface.SetColor( 0x88, 0x88, 0x88, 0x7f );
		surface.DrawOutlinedRect( bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2, 1 );

		// health label
		surface.DrawColoredText( m_hFontHealth, label_x, label_y, 0xe7, 0xe7, 0xe7, 0xff, m_szHealth );
	}

	if ( m_bDrawArmor )
	{
		local icon_s = YRES(8);
		local icon_x = YRES(93.5);
		local bar_x = YRES(133.25);
		local bar_progress = (bar_w * m_flArmor + 0.71).tointeger();
		local label_x = YRES(104) + m_nOffsetArmorLabelX;
		local label_y = m_nOffsetArmorLabelY + y0;

		// armour bar
		surface.SetColor( 0xe7, 0xe7, 0xe7, 0xff );
		surface.DrawFilledRect( bar_x, bar_y, bar_progress, bar_h );

		if ( m_flArmor < 1.0 )
		{
			surface.SetColor( 0x66, 0x66, 0x66, 0x99 );
			surface.DrawFilledRect( bar_x + bar_progress, bar_y, bar_w - bar_progress, bar_h );
		}

		// bar outline
		surface.SetColor( 0x88, 0x88, 0x88, 0x7f );
		surface.DrawOutlinedRect( bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2, 1 );

		// armour icon
		surface.DrawTexturedBox( m_hTexArmor, icon_x, icon_y, icon_s, icon_s, 0xcc, 0xcc, 0xcc, 165 );

		// armour label blur
		surface.DrawColoredText( m_hFontArmorBlur, label_x, label_y, 0x00, 0x00, 0x00, 0xff, m_szArmor );

		// armour label
		surface.DrawColoredText( m_hFontArmor, label_x, label_y, 0xe7, 0xe7, 0xe7, 0xff, m_szArmor );
	}
}

local CONST = getconsttable();
{
	delete CONST.kHudHealthPanelHeight;
}
