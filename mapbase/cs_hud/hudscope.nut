//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;
local surface = surface;


class CCSHudScope
{
	self = null

	m_bVisible = false

	m_hScopeLens = null
	m_hScopeTex = null

	m_bSuitZoom = false
}

function CCSHudScope::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSHudScope" );
	self.SetSize( ScreenWidth(), ScreenHeight() );
	self.SetZPos( -101 );
	self.SetVisible( m_bVisible );
	self.SetPaintEnabled( true );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );
	self.SetCallback( "Paint", Paint.bindenv(this) );

	m_hScopeLens = surface.ValidateTexture( "overlays/scope_lens", true );
	m_hScopeTex = surface.ValidateTexture( "sprites/scope_arc", true );
}

function CCSHudScope::RegisterCommands()
{
	Entities.First().SetContextThink( "CSHudScopeThink", OnThink.bindenv(this), 0.0 );

	// HACKHACK: hook commands as NetProps does not work
	Convars.RegisterCommand( "+zoom", SuitZoom.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "-zoom", SuitZoom.bindenv( this ), "", FCVAR_CLIENTDLL );
}

function CCSHudScope::UnregisterCommands()
{
	Entities.First().SetContextThink( "CSHudScopeThink", null, 0.0 );

	Convars.RegisterCommand( "+zoom", null, "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "-zoom", null, "", FCVAR_CLIENTDLL );
}

function CCSHudScope::SuitZoom( cmd, _ )
{
	m_bSuitZoom = ( cmd[0] == '+' );
	return true;
}

function CCSHudScope::OnThink(_)
{
	if ( m_bSuitZoom )
		return 0.1;

	local fov = NetProps.GetPropInt( player, "m_iFOV" );
	if ( !fov && m_bVisible )
	{
		m_bVisible = false;
		self.SetVisible( false );

		if ( CSHud.m_pCrosshair.m_bVisible )
			CSHud.m_pCrosshair.self.SetVisible( true );

		surface.PlaySound( "ui/weapon/zoom.wav" );
	}
	else
	{
		local wep = player.GetActiveWeapon();
		if ( wep && wep.GetClassname() == "weapon_crossbow" )
		{
			if ( fov && !m_bVisible )
			{
				m_bVisible = true;
				self.SetVisible( true );
				CSHud.m_pCrosshair.self.SetVisible( false );

				surface.PlaySound( "ui/weapon/zoom.wav" );
			}
		}
	}

	return 0.1;
}

local wide = ScreenWidth();
local tall = ScreenHeight();

function CCSHudScope::PerformLayout()
{
	wide = ScreenWidth();
	tall = ScreenHeight();
}

function CCSHudScope::Paint()
{
	local wideHalf = wide / 2;
	local tallHalf = tall / 2;
	local texTall = tallHalf;

	local texWide = texTall;
	local x0 = wideHalf - texWide;

	surface.SetColor( 0, 0, 0, 255 );
	surface.SetTexture( m_hScopeLens );
	surface.DrawTexturedRect( x0, 0, tall, tall );
	surface.DrawLine( wideHalf, 0, wideHalf, tall );
	surface.DrawLine( 0, tallHalf, wide, tallHalf );

	// Draw the scope
	surface.SetTexture( m_hScopeTex );

	// lower right
	surface.DrawTexturedRect( wideHalf, tallHalf, texWide, texTall );

	// lower left
	surface.DrawTexturedSubRect( x0, tallHalf, x0+texWide, tallHalf+texTall, 1., 0., 0., 1. );

	// upper left
	surface.DrawTexturedSubRect( x0, 0, x0+texWide, texTall, 1., 1., 0., 0. );

	// upper right
	surface.DrawTexturedSubRect( wideHalf, 0, wideHalf+texWide, texTall, 0., 1., 1., 0. );

	// left
	surface.DrawFilledRect( 0, 0, x0, tall );

	// right
	surface.DrawFilledRect( wideHalf + texWide, 0, x0, tall );
}
