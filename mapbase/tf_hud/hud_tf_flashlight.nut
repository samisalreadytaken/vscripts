//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;


class CTFHudFlashlight
{
	self = null
	m_hEffectMeter = null
	m_hEffectMeterBG = null
	m_hEffectMeterLabel = null
	m_flFlashlight = 0.0
}

function CTFHudFlashlight::Init()
{
	self = vgui.CreatePanel( "ImagePanel", TFHud.GetRootPanel(), "ItemEffectMeterBG" )
	self.SetZPos( 0 );
	self.SetVisible( false );
	self.SetShouldScaleImage( true );
	// self.SetImage( "hud/misc_ammo_area_horiz1_red", true );

	m_hEffectMeterLabel = vgui.CreatePanel( "Label", self, "ItemEffectMeterLabel" )
	m_hEffectMeterLabel.SetZPos( 2 );
	m_hEffectMeterLabel.SetVisible( true );
	m_hEffectMeterLabel.SetContentAlignment( Alignment.center );
	m_hEffectMeterLabel.SetFont( surface.GetFont( "TFFontSmall", true ) );
	m_hEffectMeterLabel.SetText( "TORCH" );

	m_hEffectMeter = vgui.CreatePanel( "Panel", self, "ItemEffectMeter" )
	m_hEffectMeter.SetZPos( 2 );
	m_hEffectMeter.SetVisible( true );
	m_hEffectMeter.SetPaintEnabled( true );
	m_hEffectMeter.SetPaintBackgroundEnabled( false );
	m_hEffectMeter.SetCallback( "Paint", PaintProgressBar.bindenv(this) );
	m_hEffectMeter.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );

	m_flFlashlight = 1.0;
}

function CTFHudFlashlight::PaintProgressBar()
{
	local w = m_hEffectMeter.GetWide();
	local t = m_hEffectMeter.GetTall();

	surface.SetColor( 0xff, 0xff, 0xff, 0x1f );
	surface.DrawFilledRect( 0, 0, w, t );

	if ( m_flFlashlight > 0.25 )
	{
		surface.SetColor( 0xff, 0xff, 0xff, 0xff );
	}
	else
	{
		surface.SetColor( 0xff, 0x33, 0, 0xff );
	}

	surface.DrawFilledRect( 0, 0, w * m_flFlashlight, t );
}

function CTFHudFlashlight::PerformLayout()
{
	// "Resource/UI/HudItemEffectMeter.res"

	// Uses the ImagePanel as the base
	local offX = YRES(12);
	local offY = YRES(6);

	self.SetPos( ScreenWidth() - YRES(174) + offX, ScreenHeight() - YRES(62) + offY );
	self.SetSize( YRES(100), YRES(50) );

	m_hEffectMeterLabel.SetPos( YRES(42) - offX, YRES(30) - offY );
	m_hEffectMeterLabel.SetSize( YRES(41), YRES(15) );

	m_hEffectMeter.SetPos( YRES(47) - offX, YRES(28) - offY );
	m_hEffectMeter.SetSize( YRES(30), YRES(5) );
}
