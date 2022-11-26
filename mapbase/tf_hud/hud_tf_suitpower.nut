//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;


class CTFHudSuitPower
{
	self = null
	m_hEffectMeter = null
	m_hEffectMeterBG = null
	m_hEffectMeterLabel = null
	m_flPower = 0.0
}

function CTFHudSuitPower::Init()
{
	self = vgui.CreatePanel( "ImagePanel", TFHud.GetRootPanel(), "SuitPowerMeterBG" )
	self.SetZPos( 0 );
	self.SetVisible( false );
	self.SetShouldScaleImage( true );
	// self.SetImage( "hud/misc_ammo_area_red", true );

	m_hEffectMeterLabel = vgui.CreatePanel( "Label", self, "ItemEffectMeterLabel" )
	m_hEffectMeterLabel.SetZPos( 2 );
	m_hEffectMeterLabel.SetVisible( true );
	m_hEffectMeterLabel.SetPaintBackgroundEnabled( false );
	m_hEffectMeterLabel.SetContentAlignment( Alignment.center );
	m_hEffectMeterLabel.SetFont( surface.GetFont( "TFFontSmall", true ) );
	m_hEffectMeterLabel.SetText( "AUX" );

	m_hEffectMeter = vgui.CreatePanel( "Panel", self, "ItemEffectMeter" )
	m_hEffectMeter.SetZPos( 2 );
	m_hEffectMeter.SetVisible( true );
	m_hEffectMeter.SetPaintEnabled( true );
	m_hEffectMeter.SetPaintBackgroundEnabled( false );
	m_hEffectMeter.SetCallback( "Paint", PaintProgressBar.bindenv(this) );
	m_hEffectMeter.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );

	m_flPower = 1.0;
}

function CTFHudSuitPower::PaintProgressBar()
{
	local w = m_hEffectMeter.GetWide();
	local t = m_hEffectMeter.GetTall();

	surface.SetColor( 0xff, 0xff, 0xff, 0x1f );
	surface.DrawFilledRect( 0, 0, w, t );

	if ( m_flPower > 0.25 )
	{
		surface.SetColor( 0xff, 0xff, 0xff, 0xff );
	}
	else
	{
		surface.SetColor( 0xff, 0x33, 0, 0xff );
	}

	surface.DrawFilledRect( 0, 0, w * m_flPower, t );
}

function CTFHudSuitPower::PerformLayout()
{
	local offX = YRES(12);

	self.SetPos( YRES(128), ScreenHeight() - YRES(62) + YRES(6) );
	self.SetSize( YRES(76), YRES(44) );

	m_hEffectMeterLabel.SetPos( YRES(25) - offX, YRES(27) );
	m_hEffectMeterLabel.SetSize( YRES(41), YRES(15) );

	m_hEffectMeter.SetPos( YRES(25) - offX, YRES(23) );
	m_hEffectMeter.SetSize( YRES(40), YRES(6) );
}
