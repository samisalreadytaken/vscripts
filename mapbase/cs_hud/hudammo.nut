//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local CSHud = this;
local XRES = XRES, YRES = YRES;
local surface = surface;
local Fmt = format, NetProps = NetProps;


class CSGOHudWeaponAmmo
{
	constructor( player )
	{
		this.player = player;
	}

	self = null
	player = null

	m_szAmmoClip = ""
	m_szAmmoReserve = ""
	m_szAmmoSecondary = ""

	m_bVisible = false
	m_bVisibleReserve = false
	m_bVisibleClip = false

	m_hWeapon = null
	m_nAmmo1 = -1
	m_nAmmo2 = -1
	m_nAmmoSecondary = -1

	m_hFont = null
	m_hFontBlur = null
	m_hFontSmall = null
	m_hFontSmallBlur = null
	m_hFontIcon = null
	m_hFontIconBlur = null

	m_TextureDataAmmo = null
	m_TextureDataAmmo2 = null
	m_chCurTextureDataAmmo = '\0'
	m_chCurTextureDataAmmo2 = '\0'

	m_nOffsetSecondaryIcon = 0
	m_nOffsetClipIcon = 0
	m_nOffsetClipLabel = 0
	m_nClipLabelWide = 0
}

// TODO: Use native RemoveTickSignal when added
function CSGOHudWeaponAmmo::RemoveTickSignal()
{
	self.SetCallback( "OnTick", null );
}

function CSGOHudWeaponAmmo::AddTickSignal()
{
	self.SetCallback( "OnTick", OnTick.bindenv(this) );
}

function CSGOHudWeaponAmmo::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudWeaponAmmo" );
	self.SetSize( XRES(640), YRES(480) );
	self.SetZPos( 0 );
	self.SetVisible( false );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );
	self.SetCallback( "Paint", Paint.bindenv(this) );
	self.SetCallback( "OnTick", OnTick.bindenv(this) );
	self.AddTickSignal( 50 );

	m_hFont = surface.GetFont( "hud-HA-text", true );
	m_hFontBlur = surface.GetFont( "hud-HA-text-blur", true );

	m_hFontSmall = surface.GetFont( "hud-HA-text-sm", true );
	m_hFontSmallBlur = surface.GetFont( "hud-HA-text-sm-blur", true );

	m_hFontIcon = surface.GetFont( "hud-HA-icon", true );
	m_hFontIconBlur = surface.GetFont( "hud-HA-icon-blur", true );

	m_TextureDataAmmo =
	{
		["weapon_crowbar"] = 'c',
		["weapon_stunstick"] = 'n',
		["weapon_pistol"] = 'r',
		["weapon_357"] = 'q',
		["weapon_smg1"] = 'r',
		["weapon_ar2"] = 'u',
		["weapon_shotgun"] = 's',
		["weapon_crossbow"] = 'w',
		["weapon_frag"] = 'v',
		["weapon_rpg"] = 'x',
	}

	m_TextureDataAmmo2 =
	{
		["weapon_smg1"] = 't',
		["weapon_ar2"] = 'z',
		["weapon_slam"] = 'o',
	}
}

function CSGOHudWeaponAmmo::PerformLayout()
{
	m_nOffsetSecondaryIcon = surface.GetCharacterWidth( m_hFont, 'W' );
	m_nOffsetClipIcon = surface.GetCharacterWidth( m_hFontSmall, 'W' ) * 3 + YRES(32);
	m_nClipLabelWide = surface.GetCharacterWidth( m_hFont, '0' ) * 3 - YRES(4);

	// Recalculate
	m_hWeapon = null;
	OnTick();
}

function CSGOHudWeaponAmmo::SetVehicle( type )
{
	switch ( type )
	{
		case "APC":
			return self.SetCallback( "OnTick", OnTickAPC.bindenv(this) );

		case null:
			return self.SetCallback( "OnTick", OnTick.bindenv(this) );
	}
}

function CSGOHudWeaponAmmo::OnTick()
{
	local weapon = player.GetActiveWeapon();

	if ( !weapon )
	{
		if ( m_hWeapon )
		{
			m_bVisible = false;
			self.SetVisible( false );

			SetVisibleInClip( false );
			SetVisibleInReserve( false );

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
		local szClassname = weapon.GetClassname();

		m_hWeapon = weapon;
		m_nAmmo1 = nAmmo1;
		m_nAmmo2 = nAmmo2;

		if ( nAmmoSecondary != -1 )
		{
			m_nAmmoSecondary = nAmmoSecondary;
			m_szAmmoSecondary = "" + nAmmoSecondary;
			m_chCurTextureDataAmmo2 = m_TextureDataAmmo2[ szClassname ];
		}
		else
		{
			m_szAmmoSecondary = "";
		}

		if ( weapon.UsesPrimaryAmmo() )
		{
			m_chCurTextureDataAmmo = m_TextureDataAmmo[ szClassname ];

			if ( weapon.UsesClipsForAmmo1() )
			{
				SetAmmoInClip( nAmmo1 );
				SetAmmoInReserve( nAmmo2 );

				if ( !m_bVisibleClip )
				{
					SetVisibleInClip( true );
				}

				if ( !m_bVisibleReserve )
				{
					SetVisibleInReserve( true );
				}
			}
			else
			{
				SetAmmoInClip( nAmmo1 );

				if ( !m_bVisibleClip )
				{
					SetVisibleInClip( true );
				}

				if ( m_bVisibleReserve )
				{
					SetVisibleInReserve( false );
				}
			}

			if ( !m_bVisible )
			{
				m_bVisible = true;
				self.SetVisible( true );
			}
		}
		// Only uses secondary ammo, set primary ammo invisible, draw secondary ammo if it's not invalid.
		// weapon_slam does this...
		else if ( nAmmoSecondary != -1 )
		{
			m_chCurTextureDataAmmo = m_TextureDataAmmo2[ szClassname ];

			if ( m_bVisibleClip )
			{
				SetVisibleInClip( false );
			}

			if ( m_bVisibleReserve )
			{
				SetVisibleInReserve( false );
			}

			if ( !m_bVisible )
			{
				m_bVisible = true;
				self.SetVisible( true );
			}
		}
		else
		{
			if ( m_bVisible )
			{
				m_bVisible = false;
				self.SetVisible( false );

				SetVisibleInClip( false );
				SetVisibleInReserve( false );
			}
		}
	}
}

function CSGOHudWeaponAmmo::OnTickAPC()
{
	local nAmmo1 = NetProps.GetPropInt( CSHud.m_hVehicle, "m_iMachineGunBurstLeft" );
	local nAmmoSecondary = NetProps.GetPropInt( CSHud.m_hVehicle, "m_iRocketSalvoLeft" );

	// update on change
	if ( nAmmo1 != m_nAmmo1 || nAmmoSecondary != m_nAmmoSecondary )
	{
		m_nAmmo1 = nAmmo1;
		m_nAmmoSecondary = nAmmoSecondary;
		m_szAmmoSecondary = "" + nAmmoSecondary;

		m_chCurTextureDataAmmo2 = m_TextureDataAmmo[ "weapon_rpg" ];
		m_chCurTextureDataAmmo = m_TextureDataAmmo[ "weapon_ar2" ];

		SetAmmoInClip( nAmmo1 );

		if ( !m_bVisibleClip )
		{
			SetVisibleInClip( true );
		}

		if ( m_bVisibleReserve )
		{
			SetVisibleInReserve( false );
		}

		if ( !m_bVisible )
		{
			m_bVisible = true;
			self.SetVisible( true );
		}
	}
}

function CSGOHudWeaponAmmo::Paint()
{
	local width = YRES(143);
	local height = YRES(22);

	local x0 = XRES(640) - width;
	local y0 = YRES(480) - height;

	// bg
	{
		local flAlpha = CSHud.m_flBackgroundAlpha;

		local w = YRES(44);
		local x = x0;
		surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );
		surface.DrawFilledRectFade( x, y0, w, height, 0x00, 0xff, true );
		x += w;
		w = YRES(85);
		surface.DrawFilledRect( x, y0, w, height );
		surface.DrawFilledRectFade( x + w, y0, YRES(14), height, 0xff, 0x00, true );
	}

	if ( m_bVisibleClip )
	{
		local x = x0 + YRES(59.5);

		// icon blur
		surface.SetTextFont( m_hFontIconBlur );
		surface.SetTextColor( 0x00, 0x00, 0x00, 0xff );
		surface.SetTextPos( x + m_nOffsetClipIcon, y0 + YRES(4) );
		surface.DrawUnicodeChar( m_chCurTextureDataAmmo, 0 );

		// icon
		surface.SetTextFont( m_hFontIcon );
		surface.SetTextColor( 0xcc, 0xcc, 0xcc, 0xcc );
		surface.SetTextPos( x + m_nOffsetClipIcon, y0 + YRES(4) );
		surface.DrawUnicodeChar( m_chCurTextureDataAmmo, 0 );

		// blur
		surface.DrawColoredText( m_hFontBlur, x + m_nOffsetClipLabel, y0 + YRES(1), 0x00, 0x00, 0x00, 0xff, m_szAmmoClip );

		// label
		surface.DrawColoredText( m_hFont, x + m_nOffsetClipLabel, y0 + YRES(1), 0xe7, 0xe7, 0xe7, 0xff, m_szAmmoClip );

		if ( m_bVisibleReserve )
		{
			x = x0 + YRES(84);
			local y = y0 + YRES(8.5);

			// blur
			surface.DrawColoredText( m_hFontSmallBlur, x, y, 0x00, 0x00, 0x00, 0xff, m_szAmmoReserve );

			// label
			surface.DrawColoredText( m_hFontSmall, x, y, 0xcc, 0xcc, 0xcc, 0xff, m_szAmmoReserve );
		}
	}

	if ( m_szAmmoSecondary != "" )
	{
		local x = x0 + YRES(18);

		// icon blur
		surface.SetTextFont( m_hFontIconBlur );
		surface.SetTextColor( 0x00, 0x00, 0x00, 0xff );
		surface.SetTextPos( x + m_nOffsetSecondaryIcon, y0 + YRES(4) );
		surface.DrawUnicodeChar( m_chCurTextureDataAmmo2, 0 );

		// icon
		surface.SetTextFont( m_hFontIcon );
		surface.SetTextColor( 0xcc, 0xcc, 0xcc, 0xcc );
		surface.SetTextPos( x + m_nOffsetSecondaryIcon, y0 + YRES(4) );
		surface.DrawUnicodeChar( m_chCurTextureDataAmmo2, 0 );

		// blur
		surface.DrawColoredText( m_hFontBlur, x, y0 + YRES(1), 0x00, 0x00, 0x00, 0xff, m_szAmmoSecondary );

		// label
		surface.DrawColoredText( m_hFont, x, y0 + YRES(1), 0xe7, 0xe7, 0xe7, 0xff, m_szAmmoSecondary );
	}
}

function CSGOHudWeaponAmmo::SetAmmoInClip( nAmt )
{
	local text = "" + nAmt;
	m_szAmmoClip = text;

	m_nOffsetClipLabel = m_nClipLabelWide - surface.GetTextWidth( m_hFont, text );
}

// NOTE: In CSGO this is "/ %d" right aligned, but "/ %3d" left aligned looks good too,
// also keeps the '/' in the same position
function CSGOHudWeaponAmmo::SetAmmoInReserve( nAmt )
{
	m_szAmmoReserve = Fmt( "/ %3d", nAmt );
}

function CSGOHudWeaponAmmo::SetVisibleInClip( state )
{
	m_bVisibleClip = state;
}

function CSGOHudWeaponAmmo::SetVisibleInReserve( state )
{
	m_bVisibleReserve = state;
}
