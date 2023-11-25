//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;
local surface = surface, Time = Time, cos = cos;


class CSGOHudPoisonDamageIndicator
{
	self = null

	m_nState = 0
	m_flFadeStart = 0.0;
	m_nLastAlpha = 0;
	m_hTexture = null
}

function CSGOHudPoisonDamageIndicator::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudPoisonDamageIndicator" );
	self.SetZPos( -2 );
	self.SetSize( XRES(640), YRES(480) );
	self.SetVisible( false );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "Paint", Paint.bindenv(this) );

	m_hTexture = surface.ValidateTexture( "panorama/images/masks/bottom-top-fade_additive", true );
}

function CSGOHudPoisonDamageIndicator::Paint()
{
	local a = 0.0;
	switch ( m_nState )
	{
		// Pulse
		case 0:
		{
			a = ( cos( ( Time() - m_flFadeStart ) * PI * 2.0 ) * 0.5 + 0.5 ) * ( 14.0 - 7.0 ) + 7.0;
			break;
		}
		// Fade in
		case 1:
		{
			local t = ( Time() - m_flFadeStart ) / 0.5;
			a = t * 14.0;
			if ( a >= 14.0 )
			{
				m_nState = 0;
				m_flFadeStart = Time();
			}
			break;
		}
		// Fade out
		case 2:
		{
			local t = 1.0 - ( Time() - m_flFadeStart ) / 0.5;
			a = t * m_nLastAlpha;
			if ( a <= 0.0 )
			{
				self.SetVisible( false );
				return;
			}
			break;
		}
	}

	surface.DrawTexturedBox( m_hTexture, 0, YRES(320), XRES(640), YRES(160), 255, 236, 128, a );
}

function CSGOHudPoisonDamageIndicator::SetVisible( state )
{
	if ( state )
	{
		m_nState = 1;
		m_flFadeStart = Time();
		self.SetVisible( true );
	}
	else
	{
		m_nLastAlpha = ( cos( ( Time() - m_flFadeStart ) * PI * 2.0 ) * 0.5 + 0.5 ) * ( 14.0 - 7.0 ) + 7.0;
		m_nState = 2;
		m_flFadeStart = Time();
	}
}
