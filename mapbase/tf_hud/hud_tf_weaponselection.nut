//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;


const MAX_WEAPONS = 48;
const MAX_WEAPON_SLOTS = 6;
const MAX_WEAPON_POSITIONS = 4;

class CTFHudWeaponSelection
{
	self = null
	m_ItemPanels = null
	m_IconChars = null

	m_iActiveSlot = 0
	m_iActivePos = 0
	m_hLastWeapon = null

	m_flRightMargin = 32
	m_flSmallBoxWide = 72
	m_flSmallBoxTall = 54
	m_flLargeBoxWide = 110
	m_flLargeBoxTall = 77
	m_flBoxGap = 4

	m_bFading = false
	m_flHideTime = 1.e+38
}

class CTFHudWeaponSelection.CItemPanel
{
	m_pBase = null
	m_pBackground = null
	m_pBorder = null
	m_pNumberLabel = null
	m_pWeaponIcon = null
	m_pWeaponIconBlur = null

	m_bSelected = false

	m_hNumberFont = 0
	m_hNameFontLarge = 0
	m_hNameFontSmall = 0
	m_hNameFontSmaller = 0

	m_hMyWeapon = null

	m_flSelectionNumberXPos = 12
	m_flSelectionNumberYPos = 4
}

function CTFHudWeaponSelection::CItemPanel::constructor( slot, pParent )
{
	m_hNumberFont = surface.GetFont( "HudSelectionText", false );
	m_hNameFontLarge = surface.GetFont( "ItemFontNameLarge", true );
	m_hNameFontSmall = surface.GetFont( "ItemFontNameSmall", true );
	m_hNameFontSmaller = surface.GetFont( "ItemFontNameSmallest", true );

	m_pBase = vgui.CreatePanel( "Panel", pParent, "ItemPanel" );
	m_pBase.SetVisible( true );

	m_pBackground = vgui.CreatePanel( "ImagePanel", m_pBase, "background" );
	m_pBackground.SetVisible( true );
	m_pBackground.SetZPos( 0 );
	m_pBackground.SetShouldScaleImage( true );

	if ( slot != null )
	{
		m_pNumberLabel = vgui.CreatePanel( "Label", m_pBackground, "NumberLabel" );
		m_pNumberLabel.SetVisible( true );
		m_pNumberLabel.SetZPos( 2 );
		m_pNumberLabel.SetFont( m_hNumberFont );
		m_pNumberLabel.SetText( ""+(slot+1) );
	}

	// m_pNameLabel = vgui.CreatePanel( "Label", m_pBackground, "NameLabel" );
	// m_pNameLabel.SetVisible( true );
	// m_pNameLabel.SetZPos( 3 );
	// m_pNameLabel.SetContentAlignment( Alignment.south );
	// m_pNameLabel.SetCenterWrap( true );

	m_pWeaponIcon = vgui.CreatePanel( "Label", m_pBackground, "Icon" );
	m_pWeaponIcon.SetVisible( true );
	m_pWeaponIcon.SetZPos( 2 );
	m_pWeaponIcon.SetFont( surface.GetFont( "WeaponIcons", true ) );
	m_pWeaponIcon.SetContentAlignment( Alignment.center );

	m_pWeaponIconBlur = vgui.CreatePanel( "Label", m_pBackground, "IconBlur" );
	m_pWeaponIconBlur.SetVisible( true );
	m_pWeaponIconBlur.SetZPos( 1 );
	m_pWeaponIconBlur.SetFont( surface.GetFont( "WeaponIconsSelected", true ) );
	m_pWeaponIconBlur.SetContentAlignment( Alignment.center );
}

function CTFHudWeaponSelection::CItemPanel::SetPos( x, y )
{
	return m_pBase.SetPos( x, y );
}

function CTFHudWeaponSelection::CItemPanel::SetSize( w, t )
{
	m_pBase.SetSize( w, t );
	m_pBackground.SetSize( w, t );
	return PerformLayout();
}

function CTFHudWeaponSelection::CItemPanel::SetItemName( name )
{
	return m_pNameLabel.SetText( name );
}

function CTFHudWeaponSelection::CItemPanel::SetIconText( ch )
{
	m_pWeaponIcon.SetText( ch );
	m_pWeaponIconBlur.SetText( ch );
}

function CTFHudWeaponSelection::CItemPanel::PerformLayout()
{
	local w = m_pBase.GetWide();
	local t = m_pBase.GetTall();

	if ( m_pNumberLabel )
	{
		m_pNumberLabel.SetFgColor( 251, 235, 202, 255 );
		m_pNumberLabel.SetPos( w - m_flSelectionNumberXPos - XRES(5), m_flSelectionNumberYPos + YRES(5) );
		m_pNumberLabel.SizeToContents();
	}

	if ( !m_hMyWeapon || !m_hMyWeapon.IsValid() || m_hMyWeapon.GetOwner() != player )
	{
		m_pBackground.SetImage( "hud/weapon_selection_unselected", true );
		m_pWeaponIcon.SetVisible( false );
		m_pWeaponIconBlur.SetVisible( false );

		return;
	}

	if ( !m_pWeaponIcon.IsVisible() )
	{
		m_pWeaponIcon.SetVisible( true );
		m_pWeaponIconBlur.SetVisible( true );
	}

		m_pWeaponIcon.SetSize( w, t );

	if ( m_bSelected )
	{
		local img;
		switch ( TFHud.m_nPlayerTeam )
		{
			case TFTEAM.RED:	img = "hud/weapon_selection_red"; break;
			case TFTEAM.BLUE:	img = "hud/weapon_selection_blue"; break;
		}
		m_pBackground.SetImage( img, true );

		m_pWeaponIconBlur.SetVisible( true );
		m_pWeaponIconBlur.SetSize( w, t );
	}
	else
	{
		m_pBackground.SetImage( "hud/weapon_selection_unselected", true );

		m_pWeaponIconBlur.SetVisible( false );
	}
}

function CTFHudWeaponSelection::Init()
{
	self = vgui.CreatePanel( "Panel", TFHud.GetRootPanel(), "TFHudWeaponSelection" );
	self.SetPos( 0, 0 );
	self.SetSize( ScreenWidth(), ScreenHeight() );
	self.SetVisible( false );
	self.SetPaintEnabled( false );
	self.SetPaintBackgroundEnabled( false );
	self.AddTickSignal( 50 );
	self.SetCallback( "OnTick", OnTick.bindenv(this) );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );

	m_IconChars =
	{
		["weapon_physcannon"] = "m",
		["weapon_crowbar"] = "c",
		["weapon_stunstick"] = "n",
		["weapon_pistol"] = "d",
		["weapon_357"] = "e",
		["weapon_smg1"] = "a",
		["weapon_ar2"] = "l",
		["weapon_shotgun"] = "b",
		["weapon_crossbow"] = "g",
		["weapon_frag"] = "k",
		["weapon_rpg"] = "i",
		["weapon_slam"] = "o",
		["weapon_bugbait"] = "j",
	}

	m_ItemPanels = array( MAX_WEAPON_SLOTS );

	for ( local i = 0; i < MAX_WEAPON_SLOTS; ++i )
	{
		m_ItemPanels[i] = [ CItemPanel( i, self ) ];
	}
}

function CTFHudWeaponSelection::RegisterCommands()
{
	Convars.RegisterCommand( "lastinv", LastWeapon.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "phys_swap", PhysSwap.bindenv( this ), "", FCVAR_GAMEDLL );
	Convars.RegisterCommand( "invnext", CycleToPrevWeapon.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "invprev", CycleToNextWeapon.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot1", function(...) { return SelectSlot( 1 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot2", function(...) { return SelectSlot( 2 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot3", function(...) { return SelectSlot( 3 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot4", function(...) { return SelectSlot( 4 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot5", function(...) { return SelectSlot( 5 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot6", function(...) { return SelectSlot( 6 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
}

function CTFHudWeaponSelection::UnregisterCommands()
{
	Convars.RegisterCommand( "lastinv", null, "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "phys_swap", null, "", FCVAR_GAMEDLL );
	Convars.RegisterCommand( "invnext", null, "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "invprev", null, "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot1", null, "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot2", null, "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot3", null, "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot4", null, "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot5", null, "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot6", null, "", FCVAR_CLIENTDLL );
}

function CTFHudWeaponSelection::OnTick()
{
	if ( m_bFading )
	{
		local a = self.GetAlpha();
		if ( a > 32 )
		{
			self.SetAlpha( a - 32 );
		}
		else
		{
			self.SetVisible( false );
		}
	}
	else
	{
		if ( self.IsVisible() && ( m_flHideTime <= Time() || input.IsButtonDown( ButtonCode.MOUSE_LEFT ) ) )
		{
			m_bFading = true;
		//	player.EmitSound( "Player.WeaponSelectionClose" )
		}
	}
}

function CTFHudWeaponSelection::PerformLayout()
{
	// "Resource/HudLayout.res"

	m_flBoxGap = XRES(4);
	m_flRightMargin = 0;
	m_flSmallBoxWide = YRES(72);
	m_flSmallBoxTall = YRES(54);
	m_flLargeBoxWide = YRES(110);
	m_flLargeBoxTall = YRES(77);

	return PerformLayoutInternal();
}

// TODO: Weapons can be cached to reduce all these loops.
function CTFHudWeaponSelection::FindNextWeapon( iSlot, iPos )
{
	local nextSlot = MAX_WEAPON_SLOTS;
	local nextPosition = MAX_WEAPON_POSITIONS;
	local bestWep;

	for ( local i = 0; i < MAX_WEAPONS; ++i )
	{
		local wep = player.GetWeapon(i);
		if ( wep )
		{
			local wepSlot = wep.GetSlot();
			local wepPos = wep.GetPosition();

			if ( ( wepSlot > iSlot || (wepSlot == iSlot && wepPos > iPos) ) &&
				( wepSlot < nextSlot || (wepSlot == nextSlot && wepPos < nextPosition) ) &&
				wep.HasAnyAmmo() )
			{
				nextSlot = wepSlot;
				nextPosition = wepPos;
				bestWep = wep;
			}
		}
	}
	return bestWep;
}

function CTFHudWeaponSelection::FindPrevWeapon( iSlot, iPos )
{
	local prevSlot = -1;
	local prevPosition = -1;
	local bestWep;

	for ( local i = 0; i < MAX_WEAPONS; ++i )
	{
		local wep = player.GetWeapon(i);
		if ( wep )
		{
			local wepSlot = wep.GetSlot();
			local wepPos = wep.GetPosition();

			if ( ( wepSlot < iSlot || (wepSlot == iSlot && wepPos < iPos) ) &&
				( wepSlot > prevSlot || (wepSlot == prevSlot && wepPos > prevPosition) )
				&& wep.HasAnyAmmo() )
			{
				prevSlot = wepSlot;
				prevPosition = wepPos;
				bestWep = wep;
			}
		}
	}
	return bestWep;
}

function CTFHudWeaponSelection::GetNextActivePos( iSlot, iPos )
{
	local nextPos = MAX_WEAPON_POSITIONS;
	local bestWep;

	for ( local i = 0; i < MAX_WEAPONS; ++i )
	{
		local wep = player.GetWeapon(i);
		if ( wep )
		{
			local wepPos = wep.GetPosition();
			if ( wep.GetSlot() == iSlot && wepPos >= iPos && wepPos <= nextPos && wep.HasAnyAmmo() )
			{
				nextPos = wepPos;
				bestWep = wep;
			}
		}
	}
	return bestWep;
}

function CTFHudWeaponSelection::GetWeapon( iSlot, iPos )
{
	for ( local i = 0; i < MAX_WEAPONS; ++i )
	{
		local wep = player.GetWeapon(i);
		if ( wep )
		{
			if ( wep.GetSlot() == iSlot && wep.GetPosition() == iPos )
				return wep;
		}
	}
}

function CTFHudWeaponSelection::PerformLayoutInternal()
{
	local baseWide = self.GetWide();
	local baseTall = self.GetTall();

	local xpos = baseWide - m_flRightMargin - m_flBoxGap;
	local ypos = ( baseTall - ( (MAX_WEAPON_SLOTS-1) * (m_flSmallBoxTall + m_flBoxGap) + m_flLargeBoxTall ) ) / 2

	for ( local slot = 0; slot < MAX_WEAPON_SLOTS; ++slot )
	{
		local wide, tall = m_flSmallBoxTall;

		for ( local pos = 0; pos < MAX_WEAPON_POSITIONS; ++pos )
		{
			local panel;
			if ( pos in m_ItemPanels[slot] )
				panel = m_ItemPanels[slot][pos];

			local wep = GetWeapon( slot, pos );
			if ( wep )
			{
				if ( !(pos in m_ItemPanels[slot]) )
				{
					m_ItemPanels[slot].resize( pos+1 );
					foreach( i, v in m_ItemPanels[slot] )
					{
						if ( !v )
							m_ItemPanels[slot][i] = CItemPanel( null, self );
					}
				}

				panel = m_ItemPanels[slot][pos];
				panel.m_hMyWeapon = wep;
				panel.SetIconText( m_IconChars[ wep.GetClassname() ] );
				panel.m_pWeaponIcon.SetVisible( true );

				if ( wep.HasAnyAmmo() )
				{
					panel.m_pWeaponIcon.SetFgColor( 255, 255, 255, 255 );
				}
				else
				{
					panel.m_pWeaponIcon.SetFgColor( 255, 25, 0, 255 );
				}

				panel.m_bSelected = ( slot == m_iActiveSlot && pos == m_iActivePos );

				wide = m_flSmallBoxWide;
				tall = m_flSmallBoxTall;

				panel.SetSize( wide, tall );
			}
			else
			{
				if ( panel )
				{
					wide = m_flSmallBoxWide;
					tall = m_flSmallBoxTall;

					panel.m_bSelected = false;
					panel.SetSize( wide, tall );
					panel.m_pWeaponIcon.SetVisible( false );
				}
			}

			if ( panel )
				panel.SetPos( xpos - wide - m_flBoxGap - pos * wide, ypos );
		}

		ypos += tall + m_flBoxGap;
	}
}

function CTFHudWeaponSelection::CycleToNextWeapon(...)
{
	local activeWep = player.GetActiveWeapon();
	if ( !activeWep )
		return;

	local wep = FindNextWeapon( activeWep.GetSlot(), activeWep.GetPosition() );
	if ( !wep )
		wep = FindNextWeapon( -1, -1 );

	if ( wep )
		return SelectWeapon( wep );
}

function CTFHudWeaponSelection::CycleToPrevWeapon(...)
{
	local activeWep = player.GetActiveWeapon();
	if ( !activeWep )
		return;

	local wep = FindPrevWeapon( activeWep.GetSlot(), activeWep.GetPosition() );
	if ( !wep )
		wep = FindPrevWeapon( MAX_WEAPON_SLOTS, MAX_WEAPON_POSITIONS );

	if ( wep )
		return SelectWeapon( wep );
}

function CTFHudWeaponSelection::SelectWeapon( weapon )
{
	if ( m_bFading )
	{
		m_bFading = false;
		self.SetAlpha( 255 );
	}

	m_flHideTime = Time() + 1.0;
	self.SetVisible( true );

	m_iActiveSlot = weapon.GetSlot();
	m_iActivePos = weapon.GetPosition();

	local hCurWep = player.GetActiveWeapon();
	if ( weapon != hCurWep )
	{
		m_hLastWeapon = hCurWep;
	}
	input.MakeWeaponSelection( weapon );

	player.EmitSound( "Player.WeaponSelectionMoveSlot" );

	TFHud.OnSelectWeapon( weapon );

	return PerformLayoutInternal();
}

function CTFHudWeaponSelection::SelectSlot( slot )
{
	--slot;

	if ( m_bFading )
	{
		m_bFading = false;
		self.SetAlpha( 255 );
	}

	m_flHideTime = Time() + 1.0;
	self.SetVisible( true );

	local pos = 0;

	if ( slot == m_iActiveSlot )
	{
		pos = m_iActivePos+1;
	}

	local wep = GetNextActivePos( slot, pos );
	if ( !wep )
		wep = GetNextActivePos( slot, 0 );

	if ( wep )
	{
		m_iActiveSlot = slot;
		m_iActivePos = wep.GetPosition();

		local hCurWep = player.GetActiveWeapon();
		if ( wep != hCurWep )
		{
			m_hLastWeapon = hCurWep;
		}
		input.MakeWeaponSelection( wep );

		player.EmitSound( "Player.WeaponSelectionMoveSlot" );

		TFHud.OnSelectWeapon( wep );
	}
	else
	{
		player.EmitSound( "Player.DenyWeaponSelection" );
	}

	return PerformLayoutInternal();
}

// NOTE: Does not account for conditions when weapons cannot be switched!
function CTFHudWeaponSelection::LastWeapon(...)
{
	if ( m_hLastWeapon && m_hLastWeapon.IsValid() )
	{
		input.MakeWeaponSelection( m_hLastWeapon );
	}

	m_hLastWeapon = player.GetActiveWeapon();
}

// NOTE: Does not account for conditions when weapons cannot be switched!
function CTFHudWeaponSelection::PhysSwap(...)
{
	local hCurWep = player.GetActiveWeapon();
	if ( hCurWep )
	{
		local bPlayerOwnsGravityGun = false;
		for ( local i = 0; i < MAX_WEAPONS; ++i )
		{
			local wep = player.GetWeapon(i);
			if ( wep && wep.GetClassname() == "weapon_physcannon" )
			{
				bPlayerOwnsGravityGun = true;
				break;
			}
		}

		if ( bPlayerOwnsGravityGun )
			m_hLastWeapon = hCurWep;
	}

	m_iActiveSlot = m_iActivePos = -1;
	return true;
}
