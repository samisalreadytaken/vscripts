//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;
local surface = surface, NetProps = NetProps;


class CTFHudScope
{
	self = null

	m_bVisible = false

	m_hScopeTex0 = null
	m_hScopeTex1 = null
	m_hScopeTex2 = null
	m_hScopeTex3 = null

	m_bSuitZoom = false
}

function CTFHudScope::Init()
{
	self = vgui.CreatePanel( "Panel", TFHud.GetRootPanel(), "TFHudScope" );
	self.SetSize( ScreenWidth(), ScreenHeight() );
	self.SetZPos( -101 );
	self.SetVisible( m_bVisible );
	self.SetPaintEnabled( true );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "Paint", Paint.bindenv(this) );

	m_hScopeTex0 = surface.ValidateTexture( "hud/scope_sniper_lr", true );
	m_hScopeTex1 = surface.ValidateTexture( "hud/scope_sniper_ll", true );
	m_hScopeTex2 = surface.ValidateTexture( "hud/scope_sniper_ul", true );
	m_hScopeTex3 = surface.ValidateTexture( "hud/scope_sniper_ur", true );
}

function CTFHudScope::RegisterCommands()
{
	Entities.First().SetContextThink( "TFHudScopeThink", OnThink.bindenv(this), 0.0 );

	// HACKHACK: hook commands as NetProps does not work
	Convars.RegisterCommand( "+zoom", SuitZoom.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "-zoom", SuitZoom.bindenv( this ), "", FCVAR_CLIENTDLL );
}

function CTFHudScope::UnregisterCommands()
{
	Entities.First().SetContextThink( "TFHudScopeThink", null, 0.0 );

	Convars.UnregisterCommand( "+zoom" );
	Convars.UnregisterCommand( "-zoom" );
}

function CTFHudScope::SuitZoom( cmd, _ )
{
	m_bSuitZoom = ( cmd[0] == '+' );
	return true;
}

function CTFHudScope::OnThink(_)
{
	if ( m_bSuitZoom )
		return 0.1;

	local fov = NetProps.GetPropInt( player, "m_iFOV" );
	if ( !fov && m_bVisible )
	{
		m_bVisible = false;
		self.SetVisible( false );
		TFHud.SetCrosshairVisible( true );

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
				TFHud.SetCrosshairVisible( false );

				surface.PlaySound( "ui/weapon/zoom.wav" );
			}
		}
	}

	return 0.1;
}

function CTFHudScope::Paint()
{
	local wide = XRES(640);
	local tall = YRES(480);
	local wideHalf = wide / 2;
	local tallHalf = tall / 2;
	local texTall = tallHalf;

	local texWide = texTall * 4.0 / 3.0;
	local x0 = wideHalf - texWide;

	surface.SetColor( 0, 0, 0, 255 );
	surface.SetTexture( m_hScopeTex0 );
	surface.DrawTexturedRect( wideHalf, tallHalf, texWide, texTall );

	surface.SetTexture( m_hScopeTex1 );
	surface.DrawTexturedRect( x0, tallHalf, texWide, texTall );

	surface.SetTexture( m_hScopeTex2 );
	surface.DrawTexturedRect( x0, 0, texWide, texTall );

	surface.SetTexture( m_hScopeTex3 );
	surface.DrawTexturedRect( wideHalf, 0, texWide, texTall );

	surface.DrawFilledRect( 0, 0, x0, tall );
	surface.DrawFilledRect( wideHalf + texWide, 0, x0, tall );
}
