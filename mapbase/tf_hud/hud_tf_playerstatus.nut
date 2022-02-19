//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;


class CTFHudPlayerStatus
{
	self = null
}

function CTFHudPlayerStatus::Init()
{
	self = vgui.CreatePanel( "Panel", TFHud.GetRootPanel(), "TFHudPlayerStatus" );
	self.SetVisible( true );
	self.SetZPos( -100 );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );
}

function CTFHudPlayerStatus::PerformLayout()
{
	// "Resource/HudLayout.res"
	self.SetPos( 0, 0 );
	self.SetSize( YRES(480), YRES(480) );
}
