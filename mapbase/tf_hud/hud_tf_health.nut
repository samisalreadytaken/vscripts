//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;


class CTFHudPlayerHealth
{
	self = null
	m_hBleedImage = null
	m_hHealthImageBG = null
	m_hHealthBonusImage = null
	m_hHealthImage = null
	m_hHealthValue = null
	m_hArmorValue = null

	m_iHealthTex = null
	m_iDeadTex = null

	m_flMaxHealth = 0.0
	m_nHealth = 0
	m_flHealth = 0.0
	m_nArmor = 0

	m_nHealthWarningThreshold = 0

	m_iHealthFlash = 1
	m_iHealthFlashAlpha = 255
	m_flFlashStartTime = 0.0

	m_bBleeding = false
}

function CTFHudPlayerHealth::Init()
{
	self = vgui.CreatePanel( "Panel", TFHud.m_pPlayerStatus.self, "HudPlayerHealth" );
	self.SetZPos( 2 );
	self.SetVisible( true );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );
	self.SetCallback( "OnTick", OnTick.bindenv(this) );
	self.AddTickSignal( 100 );

	m_hBleedImage = vgui.CreatePanel( "ImagePanel", self, "PlayerStatusBleedImage" );
	m_hBleedImage.SetVisible( false );
	m_hBleedImage.SetShouldScaleImage( true );
	m_hBleedImage.SetZPos( 7 );
	m_hBleedImage.SetImage( "vgui/bleed_drop", true );

	m_hHealthImageBG = vgui.CreatePanel( "ImagePanel", self, "PlayerStatusHealthImageBG" );
	m_hHealthImageBG.SetVisible( true );
	m_hHealthImageBG.SetShouldScaleImage( true );
	m_hHealthImageBG.SetZPos( 3 );
	m_hHealthImageBG.SetImage( "hud/health_bg", true );

	m_hHealthBonusImage = vgui.CreatePanel( "ImagePanel", self, "PlayerStatusHealthBonusImage" );
	m_hHealthBonusImage.SetVisible( false );
	m_hHealthBonusImage.SetShouldScaleImage( true );
	m_hHealthBonusImage.SetZPos( 2 );
	m_hHealthBonusImage.SetImage( "hud/health_over_bg", true );

	m_hHealthImage = vgui.CreatePanel( "Panel", self, "PlayerStatusHealthImage" );
	m_hHealthImage.SetVisible( true );
	m_hHealthImage.SetPaintBackgroundEnabled( false );
	m_hHealthImage.SetZPos( 4 );
	m_hHealthImage.SetCallback( "Paint", HealthPaint.bindenv(this) );

	m_iHealthTex = surface.ValidateTexture( "hud/health_color", true );
	m_iDeadTex = surface.ValidateTexture( "hud/health_dead", true );

	m_hHealthValue = vgui.CreatePanel( "Label", self, "PlayerStatusHealthValue" );
	m_hHealthValue.SetVisible( true );
	m_hHealthValue.SetPaintBackgroundEnabled( false );
	m_hHealthValue.SetFont( surface.GetFont( "HudClassHealth", true ) );
	m_hHealthValue.SetContentAlignment( Alignment.center );
	m_hHealthValue.SetZPos( 5 );

	m_hArmorValue = vgui.CreatePanel( "Label", self, "PlayerStatusArmorValue" );
	m_hArmorValue.SetVisible( true );
	m_hArmorValue.SetPaintBackgroundEnabled( false );
	m_hArmorValue.SetFont( surface.GetFont( "HudClassHealth", true ) );
	m_hArmorValue.SetContentAlignment( Alignment.center );
	m_hArmorValue.SetZPos( 5 );
}

function CTFHudPlayerHealth::PerformLayout()
{
	TFHud.m_hCrosshair.SetSize( 32, 32 );
	TFHud.m_hCrosshair.SetPos( XRES(320) - 16, YRES(240) - 16 );

	// "Resource/UI/HudPlayerHealth.res"
	self.SetPos( 0, ScreenHeight() - YRES(120) );
	self.SetSize( YRES(250), YRES(120) );

	m_hBleedImage.SetPos( YRES(85), YRES(0) );
	m_hBleedImage.SetSize( YRES(32), YRES(32) );

	m_hHealthImageBG.SetPos( YRES(73), YRES(33) );
	m_hHealthImageBG.SetSize( YRES(55), YRES(55) );

	m_hHealthBonusImage.SetPos( YRES(73), YRES(33) );
	m_hHealthBonusImage.SetSize( YRES(55), YRES(55) );

	m_hHealthImage.SetPos( YRES(75), YRES(35) );
	m_hHealthImage.SetSize( YRES(51), YRES(51) );

	m_hHealthValue.SetPos( YRES(76), YRES(52) );
	m_hHealthValue.SetSize( YRES(50), YRES(18) );
	m_hHealthValue.SetFgColor( 117, 107, 94, 255 );

	m_hArmorValue.SetPos( YRES(76), m_hHealthImage.GetYPos() - YRES(18) - YRES(2) );
	m_hArmorValue.SetSize( YRES(50), YRES(18) );
	m_hArmorValue.SetFgColor( 117, 107, 94, 255 );

	// Update visibility
	OnTick();
}

function CTFHudPlayerHealth::OnTick()
{
	local nHealth = player.GetHealth();

	if ( nHealth < 0 )
	{
		nHealth = 0;
	}
	else
	{
		m_hArmorValue.SetText( "" + m_nArmor );
	}

	if ( nHealth == m_nHealth )
		return;

	m_nHealth = nHealth;
	m_flHealth = 1.0 - nHealth / m_flMaxHealth;

	if ( nHealth > 0 )
	{
		if ( nHealth < m_nHealthWarningThreshold )
		{
			m_hHealthBonusImage.SetDrawColor( 255, 0, 0, 255 );

			local offsetPos = 35.0 * m_flHealth * m_flHealth;
			local offsetSize = 2.0 * offsetPos;

			m_hHealthBonusImage.SetPos(
				m_hHealthImageBG.GetXPos() - offsetPos,
				m_hHealthImageBG.GetYPos() - offsetPos );
			m_hHealthBonusImage.SetSize(
				m_hHealthImageBG.GetWide() + offsetSize,
				m_hHealthImageBG.GetTall() + offsetSize );

			if ( !m_hHealthBonusImage.IsVisible() )
			{
				m_flFlashStartTime = Time();

				m_hHealthBonusImage.SetVisible( true );
				m_iHealthFlashAlpha = 255;
				m_iHealthFlash = 1;
			}
		}
		else
		{
			m_hHealthBonusImage.SetVisible( false );
		}

		m_hHealthValue.SetText( "" + nHealth );
	}
	else
	{
		m_hHealthImageBG.SetVisible( false );
		m_hHealthBonusImage.SetVisible( false );
		m_hHealthValue.SetText( "" );
	}
}

function CTFHudPlayerHealth::HealthPaint()
{
	local w = m_hHealthImage.GetWide();
	local h = m_hHealthImage.GetTall();

	if ( m_nHealth > 0 )
	{
		if ( m_nHealth < m_nHealthWarningThreshold )
		{
			surface.SetColor( 255, 0, 0, 255 );
		}
		else
		{
			surface.SetColor( 255, 255, 255, 255 );
		}

		surface.SetTexture( m_iHealthTex );

		local fh = m_flHealth;
		surface.DrawTexturedSubRect( 0, fh * h, w, h, 0.0, fh, 1.0, 1.0 );
	}
	else
	{
		surface.SetColor( 255, 255, 255, 255 );
		surface.SetTexture( m_iDeadTex );
		surface.DrawTexturedRect( 0, 0, w, h );
	}
}

function CTFHudPlayerHealth::AnimThink()
{
	if ( m_nHealth < m_nHealthWarningThreshold )
	{
		if ( m_iHealthFlash )
		{
			local a = m_iHealthFlashAlpha -= 64;
			m_hHealthBonusImage.SetAlpha( a );

			if ( a <= 0 )
			{
				m_iHealthFlash = 0;
			}
		}
		else
		{
			local a = m_iHealthFlashAlpha += 64;
			m_hHealthBonusImage.SetAlpha( a );

			if ( a >= 255 )
			{
				m_iHealthFlash = 1;
			}
		}
	}

	if ( m_bBleeding )
	{
		local pulse = ( ( Time() * 10.0 ).tointeger() % 5 ) * 10;
		m_hBleedImage.SetDrawColor( 125 + pulse, 0, 0, 255 );
	}
}
