//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;


class CTFHudWeaponAmmo
{
	self = null

	m_hAmmoBG = null
	//m_hLowAmmo = null

	m_hInClip = null
	m_hInClipShadow = null

	m_hInReserve = null
	m_hInReserveShadow = null

	m_hNoClip = null
	m_hNoClipShadow = null

	m_hSecondaryBG = null
	m_hSecondary = null
	m_hSecondaryShadow = null

	m_hWeapon = null
	m_nAmmo1 = -1
	m_nAmmo2 = -1
	m_nAmmoSecondary = -1
}

function CTFHudWeaponAmmo::Init()
{
	self = vgui.CreatePanel( "Panel", TFHud.GetRootPanel(), "TFHudWeaponAmmo" );
	self.SetZPos( 0 );
	self.SetVisible( true );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );
	self.SetCallback( "OnTick", OnTick.bindenv(this) );
	self.AddTickSignal( 50 );

	m_hAmmoBG = vgui.CreatePanel( "ImagePanel", self, "HudWeaponAmmoBG" );
	m_hAmmoBG.SetVisible( true );
	m_hAmmoBG.SetShouldScaleImage( true );
	m_hAmmoBG.SetZPos( 1 );
	// m_hAmmoBG.SetImage( "hud/ammo_red_bg", true );

	//m_hLowAmmo = vgui.CreatePanel( "ImagePanel", self, "HudWeaponLowAmmoImage" );
	//m_hLowAmmo.SetVisible( false );
	//m_hLowAmmo.SetShouldScaleImage( true );
	//m_hLowAmmo.SetZPos( 0 );
	//m_hLowAmmo.SetImage( "hud/ammo_red_bg", true );

	m_hInClip = vgui.CreatePanel( "Label", self, "AmmoInClip" );
	m_hInClip.SetVisible( false );
	m_hInClip.SetZPos( 5 );
	m_hInClip.SetFont( surface.GetFont( "HudFontGiantBold", true ) );
	m_hInClip.SetContentAlignment( Alignment.southeast );

	m_hInClipShadow = vgui.CreatePanel( "Label", self, "AmmoInClipShadow" );
	m_hInClipShadow.SetVisible( false );
	m_hInClipShadow.SetZPos( 5 );
	m_hInClipShadow.SetFont( surface.GetFont( "HudFontGiantBold", true ) );
	m_hInClipShadow.SetContentAlignment( Alignment.southeast );

	m_hInReserve = vgui.CreatePanel( "Label", self, "AmmoInReserve" );
	m_hInReserve.SetVisible( false );
	m_hInReserve.SetZPos( 7 );
	m_hInReserve.SetFont( surface.GetFont( "HudFontMediumSmall", true ) );
	m_hInReserve.SetContentAlignment( Alignment.southwest );

	m_hInReserveShadow = vgui.CreatePanel( "Label", self, "AmmoInReserveShadow" );
	m_hInReserveShadow.SetVisible( false );
	m_hInReserveShadow.SetZPos( 7 );
	m_hInReserveShadow.SetFont( surface.GetFont( "HudFontMediumSmall", true ) );
	m_hInReserveShadow.SetContentAlignment( Alignment.southwest );

	m_hNoClip = vgui.CreatePanel( "Label", self, "AmmoNoClip" );
	m_hNoClip.SetVisible( false );
	m_hNoClip.SetZPos( 5 );
	m_hNoClip.SetFont( surface.GetFont( "HudFontGiantBold", true ) );
	m_hNoClip.SetContentAlignment( Alignment.southeast );

	m_hNoClipShadow = vgui.CreatePanel( "Label", self, "AmmoNoClipShadow" );
	m_hNoClipShadow.SetVisible( false );
	m_hNoClipShadow.SetZPos( 5 );
	m_hNoClipShadow.SetFont( surface.GetFont( "HudFontGiantBold", true ) );
	m_hNoClipShadow.SetContentAlignment( Alignment.southeast );

	m_hSecondaryBG = vgui.CreatePanel( "ImagePanel", TFHud.GetRootPanel(), "HudWeaponSecondaryAmmoBG" );
	m_hSecondaryBG.SetVisible( false );
	m_hSecondaryBG.SetShouldScaleImage( true );
	m_hSecondaryBG.SetZPos( 1 );

	m_hSecondary = vgui.CreatePanel( "Label", m_hSecondaryBG, "AmmoSecondary" );
	m_hSecondary.SetVisible( true );
	m_hSecondary.SetZPos( 5 );
	m_hSecondary.SetFont( surface.GetFont( "HudFontMediumSmall", true ) );
	m_hSecondary.SetContentAlignment( Alignment.center );

	m_hSecondaryShadow = vgui.CreatePanel( "Label", m_hSecondaryBG, "AmmoSecondaryShadow" );
	m_hSecondaryShadow.SetVisible( true );
	m_hSecondaryShadow.SetZPos( 5 );
	m_hSecondaryShadow.SetFont( surface.GetFont( "HudFontMediumSmall", true ) );
	m_hSecondaryShadow.SetContentAlignment( Alignment.center );
}

function CTFHudWeaponAmmo::PerformLayout()
{
	// "Resource/HudLayout.res"
	self.SetPos( ScreenWidth() - YRES(95), ScreenHeight() - YRES(55) );
	self.SetSize( YRES(94), YRES(45) );

	// "Resource/UI/HudAmmoWeapons.res"
	m_hAmmoBG.SetPos( YRES(4), 0 );
	m_hAmmoBG.SetSize( YRES(90), YRES(45) );

	//m_hLowAmmo.SetPos( YRES(4), 0 );
	//m_hLowAmmo.SetSize( YRES(90), YRES(45) );
	//m_hLowAmmo.SetDrawColor( 255, 0, 0, 255 );

	// Must be set-up to set colours of invisible panels
	m_hInClip.MakeReadyForUse();
	m_hInClipShadow.MakeReadyForUse();
	m_hInReserve.MakeReadyForUse();
	m_hInReserveShadow.MakeReadyForUse();
	m_hNoClip.MakeReadyForUse();
	m_hNoClipShadow.MakeReadyForUse();
	m_hSecondary.MakeReadyForUse();
	m_hSecondaryShadow.MakeReadyForUse();

	m_hInClip.SetPos( YRES(4), 0 );
	m_hInClip.SetSize( YRES(55), YRES(40) );
	m_hInClip.SetFgColor( 235, 226, 202, 255 );

	m_hInClipShadow.SetPos( YRES(5), YRES(1) );
	m_hInClipShadow.SetSize( YRES(55), YRES(40) );
	m_hInClipShadow.SetFgColor( 46, 43, 42, 255 );

	m_hInReserve.SetPos( YRES(59), YRES(8) );
	m_hInReserve.SetSize( YRES(40), YRES(27) );
	m_hInReserve.SetFgColor( 235, 226, 202, 255 );

	m_hInReserveShadow.SetPos( YRES(60), YRES(9) );
	m_hInReserveShadow.SetSize( YRES(40), YRES(27) );
	m_hInReserveShadow.SetFgColor( 0, 0, 0, 196 );

	m_hNoClip.SetPos( 0, YRES(2) );
	m_hNoClip.SetSize( YRES(84), YRES(40) );
	m_hNoClip.SetFgColor( 235, 226, 202, 255 );

	m_hNoClipShadow.SetPos( YRES(1), YRES(3) );
	m_hNoClipShadow.SetSize( YRES(84), YRES(40) );
	m_hNoClipShadow.SetFgColor( 46, 43, 42, 255 );

	// Custom hud element
	// small secondary ammo display
	m_hSecondaryBG.SetSize( YRES(90*0.66), YRES(45*0.66) );
	m_hSecondaryBG.SetPos( ScreenWidth() - YRES(45 + 4), ScreenHeight() - YRES(100 - 45*0.33) );

	m_hSecondary.SetPos( 0, YRES(2) );
	m_hSecondary.SetSize( YRES(84*0.66), YRES(40*0.66) );
	m_hSecondary.SetFgColor( 235, 226, 202, 255 );

	m_hSecondaryShadow.SetPos( YRES(1), YRES(3) );
	m_hSecondaryShadow.SetSize( YRES(84*0.66), YRES(40*0.66) );
	m_hSecondaryShadow.SetFgColor( 46, 43, 42, 255 );
}

function CTFHudWeaponAmmo::OnTick()
{
	local weapon = player.GetActiveWeapon();

	if ( !weapon )
	{
		if ( m_hWeapon )
		{
			SetVisibleInClip( false );
			SetVisibleInReserve( false );
			SetVisibleNoClip( false );
			SetVisibleSecondary( false );
			// m_hLowAmmo.SetVisible( false );

			m_nAmmo1 = m_nAmmo2 = -1;
			m_hWeapon = null;
		}
		return;
	}

	local nAmmo1 = weapon.Clip1();
	local nAmmo2 = 0;
	if ( nAmmo1 == -1 )
	{
		nAmmo1 = player.GetAmmoCount( weapon.GetPrimaryAmmoType() );
	}
	else
	{
		nAmmo2 = player.GetAmmoCount( weapon.GetPrimaryAmmoType() );
	}

	local nAmmoSecondary = -1;
	if ( weapon.UsesSecondaryAmmo() )
	{
		nAmmoSecondary = player.GetAmmoCount( weapon.GetSecondaryAmmoType() );
	}

	// update on change
	if ( m_hWeapon != weapon || nAmmo1 != m_nAmmo1 || nAmmo2 != m_nAmmo2 || nAmmoSecondary != m_nAmmoSecondary )
	{
		m_hWeapon = weapon;
		m_nAmmo1 = nAmmo1;
		m_nAmmo2 = nAmmo2;
		m_nAmmoSecondary = nAmmoSecondary;

		if ( weapon.UsesPrimaryAmmo() )
		{
			if ( weapon.UsesClipsForAmmo1() )
			{
				SetAmmoInClip( nAmmo1 );
				SetAmmoInReserve( nAmmo2 );

				if ( !m_hInClip.IsVisible() )
				{
					SetVisibleInClip( true );
					SetVisibleInReserve( true );
					SetVisibleNoClip( false );
				}
			}
			else
			{
				SetAmmoNoClip( nAmmo1 );

				if ( !m_hNoClip.IsVisible() )
				{
					SetVisibleInClip( false );
					SetVisibleInReserve( false );
					SetVisibleNoClip( true );
				}
			}

			if ( nAmmoSecondary != -1 )
			{
				SetAmmoSecondary( nAmmoSecondary );

				if ( !m_hSecondaryBG.IsVisible() )
				{
					SetVisibleSecondary( true );
				}
			}
			else
			{
				if ( m_hSecondaryBG.IsVisible() )
				{
					SetVisibleSecondary( false );
				}
			}
		}
		// Only uses secondary ammo, set primary ammo invisible, draw secondary ammo if it's not invalid.
		// weapon_slam does this...
		else if ( nAmmoSecondary != -1 )
		{
			SetAmmoSecondary( nAmmoSecondary );

			if ( !m_hSecondaryBG.IsVisible() )
			{
				SetVisibleSecondary( true );
			}

			if ( m_hInClip.IsVisible() || m_hNoClip.IsVisible() )
			{
				SetVisibleInClip( false );
				SetVisibleInReserve( false );
				SetVisibleNoClip( false );
			}
		}
		else
		{
			if ( m_hInClip.IsVisible() || m_hNoClip.IsVisible() || m_hSecondaryBG.IsVisible() )
			{
				SetVisibleInClip( false );
				SetVisibleInReserve( false );
				SetVisibleNoClip( false );
				SetVisibleSecondary( false );
			}
		}
	}
}

function CTFHudWeaponAmmo::SetAmmoInClip( nAmt )
{
	local text = "" + nAmt;
	m_hInClip.SetText( text );
	m_hInClipShadow.SetText( text );
}

function CTFHudWeaponAmmo::SetAmmoInReserve( nAmt )
{
	local text = "" + nAmt;
	m_hInReserve.SetText( text );
	m_hInReserveShadow.SetText( text );
}

function CTFHudWeaponAmmo::SetAmmoNoClip( nAmt )
{
	local text = "" + nAmt;
	m_hNoClip.SetText( text );
	m_hNoClipShadow.SetText( text );
}

function CTFHudWeaponAmmo::SetAmmoSecondary( nAmt )
{
	local text = "" + nAmt;
	m_hSecondary.SetText( text );
	m_hSecondaryShadow.SetText( text );
}

function CTFHudWeaponAmmo::SetVisibleInClip( state )
{
	m_hInClip.SetVisible( state );
	m_hInClipShadow.SetVisible( state );
}

function CTFHudWeaponAmmo::SetVisibleInReserve( state )
{
	m_hInReserve.SetVisible( state );
	m_hInReserveShadow.SetVisible( state );
}

function CTFHudWeaponAmmo::SetVisibleNoClip( state )
{
	m_hNoClip.SetVisible( state );
	m_hNoClipShadow.SetVisible( state );
}

function CTFHudWeaponAmmo::SetVisibleSecondary( state )
{
	m_hSecondaryBG.SetVisible( state );
}
