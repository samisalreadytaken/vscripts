//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local TFHud = this;
local XRES = XRES, YRES = YRES;
local input = input, Time = Time,
	NetProps = NetProps, Convars = Convars, dummy = dummy;


const MAX_WEAPONS = 48;
const MAX_WEAPON_SLOTS = 6;
const MAX_WEAPON_POSITIONS = 4;

class CTFHudWeaponSelection
{
	constructor( player )
	{
		this.player = player;

		if ( NetProps.GetPropArraySize( player, "m_hMyWeapons" ) != MAX_WEAPONS )
		{
			printf( "Player max weapon count mismatch! %d != %d\n",
				MAX_WEAPONS, NetProps.GetPropArraySize( player, "m_hMyWeapons" ) );
		}
	}

	self = null
	m_ItemPanels = null
	m_IconChars = null

	m_iSelectedSlot = -1
	m_iSelectedPos = -1

	m_flRightMargin = 32
	m_flSmallBoxWide = 72
	m_flSmallBoxTall = 54
	m_flLargeBoxWide = 110
	m_flLargeBoxTall = 77
	m_flBoxGap = 4

	m_bFading = false
	m_flHideTime = 1.e+38

	m_iAttackButton = input.StringToButtonCode( input.LookupBinding( "+attack" ) );
	m_iAttack2Button = input.StringToButtonCode( input.LookupBinding( "+attack2" ) );
	hud_fastswitch = Convars.GetInt( "hud_fastswitch" );
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
	m_pBase.SetPaintBackgroundEnabled( false );

	m_pBackground = vgui.CreatePanel( "ImagePanel", m_pBase, "background" );
	m_pBackground.SetVisible( true );
	m_pBackground.SetZPos( 0 );
	m_pBackground.SetShouldScaleImage( true );

	if ( slot != null )
	{
		m_pNumberLabel = vgui.CreatePanel( "Label", m_pBackground, "NumberLabel" );
		m_pNumberLabel.SetVisible( true );
		m_pNumberLabel.SetPaintBackgroundEnabled( false );
		m_pNumberLabel.SetZPos( 2 );
		m_pNumberLabel.SetFont( m_hNumberFont );
		m_pNumberLabel.SetText( ""+(slot+1) );
	}

	// m_pNameLabel = vgui.CreatePanel( "Label", m_pBackground, "NameLabel" );
	// m_pNameLabel.SetVisible( true );
	// m_pNameLabel.SetPaintBackgroundEnabled( false );
	// m_pNameLabel.SetZPos( 3 );
	// m_pNameLabel.SetContentAlignment( Alignment.south );
	// m_pNameLabel.SetCenterWrap( true );

	m_pWeaponIcon = vgui.CreatePanel( "Label", m_pBackground, "Icon" );
	m_pWeaponIcon.SetVisible( true );
	m_pWeaponIcon.SetPaintBackgroundEnabled( false );
	m_pWeaponIcon.SetZPos( 2 );
	m_pWeaponIcon.SetFont( surface.GetFont( "WeaponIcons", true ) );
	m_pWeaponIcon.SetContentAlignment( Alignment.center );

	m_pWeaponIconBlur = vgui.CreatePanel( "Label", m_pBackground, "IconBlur" );
	m_pWeaponIconBlur.SetVisible( true );
	m_pWeaponIconBlur.SetPaintBackgroundEnabled( false );
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
	return m_pWeaponIconBlur.SetText( ch );
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
		return m_pWeaponIconBlur.SetVisible( false );
	}

	if ( !m_pWeaponIcon.IsVisible() )
	{
		m_pWeaponIcon.SetVisible( true );
		m_pWeaponIconBlur.SetVisible( true );
	}

		m_pWeaponIcon.SetSize( w, t );

	if ( m_bSelected )
	{
		switch ( TFHud.m_nPlayerTeam )
		{
			case TFTEAM.RED:	m_pBackground.SetImage( "hud/weapon_selection_red", true ); break;
			case TFTEAM.BLUE:	m_pBackground.SetImage( "hud/weapon_selection_blue", true ); break;
		}

		m_pWeaponIconBlur.SetSize( w, t );
		return m_pWeaponIconBlur.SetVisible( true );
	}
	else
	{
		m_pBackground.SetImage( "hud/weapon_selection_unselected", true );

		return m_pWeaponIconBlur.SetVisible( false );
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
	self.AddTickSignal( 25 );
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
	Convars.UnregisterCommand( "lastinv" );
	Convars.UnregisterCommand( "phys_swap" );
	Convars.UnregisterCommand( "invnext" );
	Convars.UnregisterCommand( "invprev" );
	Convars.UnregisterCommand( "slot1" );
	Convars.UnregisterCommand( "slot2" );
	Convars.UnregisterCommand( "slot3" );
	Convars.UnregisterCommand( "slot4" );
	Convars.UnregisterCommand( "slot5" );
	Convars.UnregisterCommand( "slot6" );
	Convars.UnregisterCommand( "+attack" );
	Convars.UnregisterCommand( "+attack2" );
}

function CTFHudWeaponSelection::OnTick()
{
	local curtime = Time();

	if ( m_bFading )
	{
		local t = (curtime - m_flHideTime) / 0.5;
		if ( t < 1.0 )
		{
			self.SetAlpha( (1.0 - t) * 255.0 );
		}
		else if ( self.IsVisible() )
		{
			m_bFading = false;
			self.SetAlpha( 255 );
			self.SetVisible( false );

			m_iSelectedSlot = m_iSelectedPos = -1;

			if ( !hud_fastswitch )
			{
				Convars.UnregisterCommand( "+attack" );
				Convars.UnregisterCommand( "+attack2" );
			}
		}
	}
	else
	{
		local mousepressed = ( input.IsButtonDown( m_iAttackButton ) || input.IsButtonDown( m_iAttack2Button ) );

		if ( self.IsVisible() && ( m_flHideTime <= curtime || mousepressed ) )
		{
			m_flHideTime = curtime;
			m_bFading = true;
		}

		// Select weapon
		if ( mousepressed && !hud_fastswitch )
		{
			local weapon = GetWeapon( m_iSelectedSlot, m_iSelectedPos );
			if ( weapon )
			{
				SelectWeapon( weapon );

				m_iSelectedSlot = m_iSelectedPos = -1;
				Convars.UnregisterCommand( "+attack" );
				Convars.UnregisterCommand( "+attack2" );

				player.EmitSound( "Player.WeaponSelectionClose" );
			}
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
				( wepSlot > prevSlot || (wepSlot == prevSlot && wepPos > prevPosition) ) &&
				wep.HasAnyAmmo() )
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

				panel.m_bSelected = ( slot == m_iSelectedSlot && pos == m_iSelectedPos );

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
	local slot, pos;

	if ( self.IsVisible() )
	{
		slot = m_iSelectedSlot;
		pos = m_iSelectedPos;
	}
	else
	{
		local wep = player.GetActiveWeapon();
		if ( !wep )
			return;

		slot = wep.GetSlot();
		pos = wep.GetPosition();
	}

	local wep = FindNextWeapon( slot, pos );
	if ( !wep )
		wep = FindNextWeapon( -1, -1 );

	if ( wep )
	{
		m_iSelectedSlot = wep.GetSlot();
		m_iSelectedPos = wep.GetPosition();

		if ( hud_fastswitch )
		{
			SelectWeapon( wep );
		}

		player.EmitSound( "Player.WeaponSelectionMoveSlot" );

		OpenSelection();
	}

	return PerformLayoutInternal();
}

function CTFHudWeaponSelection::CycleToPrevWeapon(...)
{
	local slot, pos;

	if ( self.IsVisible() )
	{
		slot = m_iSelectedSlot;
		pos = m_iSelectedPos;
	}
	else
	{
		local wep = player.GetActiveWeapon();
		if ( !wep )
			return;

		slot = wep.GetSlot();
		pos = wep.GetPosition();
	}

	local wep = FindPrevWeapon( slot, pos );
	if ( !wep )
		wep = FindPrevWeapon( MAX_WEAPON_SLOTS, MAX_WEAPON_POSITIONS );

	if ( wep )
	{
		m_iSelectedSlot = wep.GetSlot();
		m_iSelectedPos = wep.GetPosition();

		if ( hud_fastswitch )
		{
			SelectWeapon( wep );
		}

		player.EmitSound( "Player.WeaponSelectionMoveSlot" );

		OpenSelection();
	}

	return PerformLayoutInternal();
}

function CTFHudWeaponSelection::SelectSlot( slot )
{
	--slot;

	local pos = 0;

	if ( slot == m_iSelectedSlot )
	{
		pos = m_iSelectedPos+1;
	}

	local wep = GetNextActivePos( slot, pos );
	if ( !wep )
		wep = GetNextActivePos( slot, 0 );

	if ( wep )
	{
		m_iSelectedSlot = slot;
		m_iSelectedPos = wep.GetPosition();

		if ( hud_fastswitch )
		{
			SelectWeapon( wep );
		}

		player.EmitSound( "Player.WeaponSelectionMoveSlot" );
	}
	else
	{
		player.EmitSound( "Player.DenyWeaponSelection" );
	}

	// Show empty weapon selection as well
	OpenSelection();

	return PerformLayoutInternal();
}

function CTFHudWeaponSelection::SelectWeapon( wep )
{
	input.MakeWeaponSelection( wep );
	return TFHud.OnSelectWeapon( wep );
}

function CTFHudWeaponSelection::OpenSelection()
{
	m_flHideTime = Time() + 1.0;

	if ( m_bFading )
	{
		// HACKHACK: Disable +attack
		// It may have been unregistered on weapon select
		if ( !hud_fastswitch )
		{
			Convars.RegisterCommand( "+attack", dummy, "", FCVAR_CLIENTDLL );
			Convars.RegisterCommand( "+attack2", dummy, "", FCVAR_CLIENTDLL );
		}

		m_bFading = false;
		return self.SetAlpha( 255 );
	}
	else if ( !self.IsVisible() )
	{
		// HACKHACK: Disable +attack when weapon selection becomes visible
		if ( !hud_fastswitch )
		{
			Convars.RegisterCommand( "+attack", dummy, "", FCVAR_CLIENTDLL );
			Convars.RegisterCommand( "+attack2", dummy, "", FCVAR_CLIENTDLL );
		}

		return self.SetVisible( true );
	}
}

function CTFHudWeaponSelection::LastWeapon(...)
{
	local hLastWeapon = NetProps.GetPropEntity( player, "m_hLastWeapon" );
	if ( hLastWeapon )
	{
		input.MakeWeaponSelection( hLastWeapon );
		TFHud.OnSelectWeapon( hLastWeapon );

		// Update selection box if weapon selection is visible
		if ( self.IsVisible() )
		{
			m_iSelectedSlot = hLastWeapon.GetSlot();
			m_iSelectedPos = hLastWeapon.GetPosition();

			m_flHideTime = Time() + 1.0;
			m_bFading = false;
			self.SetAlpha( 255 );

			PerformLayoutInternal();
		}
	}
}

function CTFHudWeaponSelection::PhysSwap(...)
{
	if ( self.IsVisible() )
	{
		// Hide selection now
		m_flHideTime = 0.0;
		player.EmitSound( "Player.WeaponSelectionClose" );
	}

	m_iSelectedSlot = m_iSelectedPos = -1;
	return true;
}
