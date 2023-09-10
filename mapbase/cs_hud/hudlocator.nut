//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local CSHud = this;
local XRES = XRES, YRES = YRES;
local surface = surface;
local MainViewOrigin = MainViewOrigin, MainViewAngles = MainViewAngles,
	cos = cos, atan2 = atan2, AngleDiff = AngleDiff, fabs = fabs;


class CSGOHudLocator
{
	self = null
	m_bVisible = false

	m_hTarget = null
	m_hTargetTex = null
}

function CSGOHudLocator::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudLocator" )
	self.SetSize( ScreenWidth(), ScreenHeight() );
	self.SetZPos( 0 );
	self.SetAlpha( 0 );
	self.SetVisible( m_bVisible );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "Paint", Paint.bindenv(this) );
}

function CSGOHudLocator::Paint()
{
	local width = YRES(64);
	local height = YRES(22);

	local scrh = YRES(480);

	local x0 = XRES(326);
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

	local viewYaw = MainViewAngles().y;

	// Compass ticks
	{
		surface.SetColor( 0xe7, 0xe7, 0xe7, 0x40 );

		viewYaw = -viewYaw; // flip for compass

		local longTick = YRES(16);
		local shortTick = YRES(18);
		local flStep = 22.5;
		local flLimit = 100.;
		local flStart = -180.;
		local flEnd = 180.;

		local tall = true;
		for ( local ang = flStart; ang <= flEnd; ang += flStep )
		{
			tall = !tall;

			local dt = AngleDiff( viewYaw, ang ) / 2.0;
			if ( dt > flLimit || dt < -flLimit )
				continue;

			local xpos = x0 + ( cos((dt+90.0)*DEG2RAD) + 1.0 ) * ( width / 2 );

			if ( tall )
			{
				surface.DrawLine( xpos, y0+longTick, xpos, scrh );
			}
			else
			{
				surface.DrawLine( xpos, y0+shortTick, xpos, scrh );
			}
		}
	}

	if ( m_hTarget.IsValid() )
	{
		viewYaw = -viewYaw; // flip back

		local vecDelta = m_hTarget.GetCenter().Subtract( MainViewOrigin() );
		local yawDelta = atan2( vecDelta.y, vecDelta.x ) * RAD2DEG;
		local yawDiff = AngleDiff( viewYaw, yawDelta ) / 2.0;

		// Make it look like it's floating in front of the compass
		local margin = YRES(4);

		// Texture is assumed square
		local texTall = YRES(38);
		local texWide = ( 1.0 - fabs(yawDiff) / 90.0 ) * texTall;
		local xpos = x0 + ( cos((yawDiff-90.0)*DEG2RAD) + 1.0 ) * ( width / 2 + margin ) - texWide / 2.0;

		surface.DrawTexturedBox( m_hTargetTex, xpos-margin, y0-YRES(12), texWide, texTall, 0xe7, 0xe7, 0xe7, 0x99 );
	}
}

function CSGOHudLocator::SetVisible( state, target, texture )
{
	m_bVisible = state;
	m_hTarget = target;
	m_hTargetTex = texture;

	return self.SetVisible( state );
}
