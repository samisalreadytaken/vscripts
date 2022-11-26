//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;


class CTFHudPlayerClass
{
	self = null
	m_hClassImage = null
	m_hClassImageBG = null
}

function CTFHudPlayerClass::Init()
{
	self = vgui.CreatePanel( "Panel", TFHud.m_pPlayerStatus.self, "HudPlayerClass" );
	self.SetZPos( 1 );
	self.SetVisible( true );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );

	m_hClassImage = vgui.CreatePanel( "ImagePanel", self, "PlayerStatusClassImage" )
	m_hClassImage.SetZPos( 2 );
	m_hClassImage.SetVisible( true );
	m_hClassImage.SetShouldScaleImage( true );
	// m_hClassImage.SetImage( "hud/class_spyred", true );

	m_hClassImageBG = vgui.CreatePanel( "ImagePanel", self, "PlayerStatusClassImageBG" )
	m_hClassImageBG.SetZPos( 1 );
	m_hClassImageBG.SetVisible( true );
	m_hClassImageBG.SetShouldScaleImage( true );
	// m_hClassImageBG.SetImage( "hud/character_red_bg", true );
}

function CTFHudPlayerClass::PerformLayout()
{
	// "Resource/UI/HudPlayerClass.res"
	self.SetPos( 0, 0 );
	self.SetSize( YRES(480), YRES(480) );

	m_hClassImage.SetPos( YRES(25), self.GetTall() - YRES(88) );
	m_hClassImage.SetSize( YRES(75), YRES(75) );

	m_hClassImageBG.SetPos( YRES(9), self.GetTall() - YRES(60) );
	m_hClassImageBG.SetSize( YRES(100), YRES(50) );
}
