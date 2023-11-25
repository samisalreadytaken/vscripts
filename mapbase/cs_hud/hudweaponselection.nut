//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local CSHud = this;
local XRES = XRES, YRES = YRES;
local surface = surface, Localize = Localize, input = input, Time = Time,
	NetProps = NetProps, Convars = Convars, dummy = dummy;


const MAX_WEAPONS = 48;
const MAX_WEAPON_SLOTS = 6;
const MAX_WEAPON_POSITIONS = 4;


class CSGOHudWeaponSelection
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
	player = null
	m_bHidden = false

	m_IconChars = null
	m_ItemPanels = null

	m_iSelectedSlot = -1
	m_iSelectedPos = -1

	m_bFading = false
	m_flHideTime = FLT_MAX

	m_iAttackButton = input.StringToButtonCode( input.LookupBinding( "+attack" ) );
	m_iAttack2Button = input.StringToButtonCode( input.LookupBinding( "+attack2" ) );
	hud_fastswitch = Convars.GetInt( "hud_fastswitch" );
}

class CSGOHudWeaponSelection.CItemPanel
{
	m_chNumber = '\0'
	m_chIcon = '\0'
	m_szName = ""
	m_bHasAnyAmmo = false

	m_bSelected = false
	m_hFontIcon = 0
	m_hFontIconBlur = 0
	m_hFontLabel = 0

	m_xposIcon = 0
	m_yposIcon = 0

	m_xposLabel = 0
	m_yposLabel = 0

	m_xposNumber = 0
	m_yposNumber = 0

	m_nPos = -1

	m_index = 0
}

function CSGOHudWeaponSelection::CItemPanel::constructor( slot )
{
	m_chNumber = '0'+(slot+1);

	m_hFontLabel = surface.GetFont( "weapon-selection-item-name-text", true );
	m_hFontIcon = surface.GetFont( "weapon-selection-item-icon", true );
	m_hFontIconBlur = surface.GetFont( "weapon-selection-item-icon-blur", true );
}

function CSGOHudWeaponSelection::CItemPanel::Paint()
{
	// Draw the number if this is the first position in a slot
	if ( m_index )
	{
		// background
		local flAlpha = CSHud.m_flBackgroundAlpha;
		surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );

		local w = XRES(140), h = YRES(34);
		local x = XRES(640-24) - w, y = m_yposNumber-YRES(1);

		surface.DrawFilledRectFade( x, y, w, h, 0x00, 0xff, true );
		surface.DrawFilledRect( x + w, y, XRES(24), h );

		// number label shadow
		surface.SetTextFont( m_hFontLabel );
		surface.SetTextColor( 0x00, 0x00, 0x00, 0x88 );
		surface.SetTextPos( m_xposNumber+1, m_yposNumber+1 );
		surface.DrawUnicodeChar( m_chNumber, 0 );

		// number label
		surface.SetTextColor( 0xcc, 0xcc, 0xcc, 0xcc );
		surface.SetTextPos( m_xposNumber, m_yposNumber );
		surface.DrawUnicodeChar( m_chNumber, 0 );
	}

	if ( !m_chIcon )
		return;

	if ( m_bSelected )
	{
		// Draw a darker background if this is the selected slot
		local flAlpha = CSHud.m_flBackgroundAlpha;
		surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );

		local w = XRES(140), h = YRES(34);
		local x = XRES(640-24) - w, y = m_yposNumber-YRES(1);

		surface.DrawFilledRectFade( x, y, w, h, 0x00, 0xff, true );
		surface.DrawFilledRect( x + w, y, XRES(24), h );

		// borders
		w += XRES(24);
		surface.DrawFilledRectFade( x, y, w, 1, 0x00, 0xff, true );
		surface.DrawFilledRectFade( x, y + h-1, w, 1, 0x00, 0xff, true );

		// icon blur
		surface.SetTextFont( m_hFontIconBlur );
		surface.SetTextColor( 0xb9, 0x94, 0x00, 0xff );
		surface.SetTextPos( m_xposIcon, m_yposIcon );
		surface.DrawUnicodeChar( m_chIcon, 0 );

		// icon
		surface.SetTextColor( 0xff, 0xff, 0xff, 0xff );
		surface.SetTextFont( m_hFontIcon );
		surface.SetTextPos( m_xposIcon, m_yposIcon );
		surface.DrawUnicodeChar( m_chIcon, 2 );

		// name label shadow
		surface.DrawColoredText( m_hFontLabel, m_xposLabel+1, m_yposLabel+1, 0x00, 0x00, 0x00, 0x88, m_szName );

		// name label
		surface.DrawColoredText( m_hFontLabel, m_xposLabel, m_yposLabel, 0xcc, 0xcc, 0xcc, 0xcc, m_szName );
	}
	else
	{
		// icon blur
		surface.SetTextFont( m_hFontIconBlur );
		surface.SetTextColor( 0x00, 0x00, 0x00, 0xff );
		surface.SetTextPos( m_xposIcon, m_yposIcon );
		surface.DrawUnicodeChar( m_chIcon, 0 );

		if ( m_bHasAnyAmmo )
		{
			// icon
			surface.SetTextColor( 0xcc, 0xcc, 0xcc, 0xff );
			surface.SetTextFont( m_hFontIcon );
			surface.SetTextPos( m_xposIcon, m_yposIcon );
			surface.DrawUnicodeChar( m_chIcon, 2 );
		}
		else
		{
			// icon
			surface.SetTextColor( 0xcc, 0, 0, 0xff );
			surface.SetTextFont( m_hFontIcon );
			surface.SetTextPos( m_xposIcon, m_yposIcon );
			surface.DrawUnicodeChar( m_chIcon, 2 );
		}
	}
}

function CSGOHudWeaponSelection::CItemPanel::SetPos( x, y )
{
	m_xposNumber = x - surface.GetCharacterWidth( m_hFontLabel, m_chNumber ) - YRES(2);
	m_yposNumber = y + YRES(5);

	if ( !m_chIcon )
		return;

	local xOffset = x - YRES(70) * m_nPos - YRES(8);

	m_xposIcon = xOffset - surface.GetCharacterWidth( m_hFontIcon, m_chIcon );
	m_yposIcon = y + YRES(2);

	local width = 0;

	if ( m_szName.find("\n") == null )
	{
		width = surface.GetTextWidth( m_hFontLabel, m_szName );
	}
	else
	{
		local p = split( m_szName, "\n" );
		foreach ( s in p )
			width += surface.GetTextWidth( m_hFontLabel, s );
	}

	m_xposLabel = xOffset - width;
	m_yposLabel = y + YRES(37) - surface.GetFontTall( m_hFontLabel ); // m_yposNumber - YRES(1) + YRES(34) - surface.GetFontTall( m_hFontLabel ) - YRES(1);
}

function CSGOHudWeaponSelection::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudWeaponSelection" );
	self.SetSize( XRES(640), YRES(480) );
	self.SetVisible( false );
	self.SetPaintBackgroundEnabled( false );
	self.SetCallback( "OnTick", OnTick.bindenv(this) );
	self.SetCallback( "Paint", Paint.bindenv(this) );
	self.SetCallback( "PerformLayout", PerformLayoutInternal.bindenv(this) );

	m_IconChars =
	{
		["weapon_physcannon"] = 'm',
		["weapon_crowbar"] = 'c',
		["weapon_stunstick"] = 'n',
		["weapon_pistol"] = 'd',
		["weapon_357"] = 'e',
		["weapon_smg1"] = 'a',
		["weapon_ar2"] = 'l',
		["weapon_shotgun"] = 'b',
		["weapon_crossbow"] = 'g',
		["weapon_frag"] = 'k',
		["weapon_rpg"] = 'i',
		["weapon_slam"] = 'o',
		["weapon_bugbait"] = 'j',
	}

	m_ItemPanels = array( MAX_WEAPON_SLOTS );

	for ( local i = 0; i < MAX_WEAPON_SLOTS; ++i )
	{
		local p = CItemPanel( i );
		p.m_index = 1;
		m_ItemPanels[i] = [ p ];
	}
}

function CSGOHudWeaponSelection::RegisterCommands()
{
	Convars.RegisterCommand( "lastinv", LastWeapon.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "phys_swap", PhysSwap.bindenv( this ), "", FCVAR_GAMEDLL );
	// Next and prev are reversed so that invprev (scroll down by default) moves down the weapon list and vice versa
	Convars.RegisterCommand( "invnext", CycleToPrevWeapon.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "invprev", CycleToNextWeapon.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot1", function(...) { return SelectSlot( 1 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot2", function(...) { return SelectSlot( 2 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot3", function(...) { return SelectSlot( 3 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot4", function(...) { return SelectSlot( 4 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot5", function(...) { return SelectSlot( 5 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
	Convars.RegisterCommand( "slot6", function(...) { return SelectSlot( 6 ); }.bindenv( this ), "", FCVAR_CLIENTDLL );
}

function CSGOHudWeaponSelection::UnregisterCommands()
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

function CSGOHudWeaponSelection::Paint()
{
	if ( m_bHidden )
		return;

	foreach ( slot in m_ItemPanels )
		foreach ( panel in slot )
			panel.Paint();
}

function CSGOHudWeaponSelection::OnTick()
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

// TODO: Weapons can be cached to reduce all these loops.
function CSGOHudWeaponSelection::FindNextWeapon( iSlot, iPos )
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

function CSGOHudWeaponSelection::FindPrevWeapon( iSlot, iPos )
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

function CSGOHudWeaponSelection::GetNextActivePos( iSlot, iPos )
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

function CSGOHudWeaponSelection::GetWeapon( iSlot, iPos )
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

function CSGOHudWeaponSelection::PerformLayoutInternal()
{
	local m_nSmallBoxTall = YRES(34);
	local baseWide = XRES(640);
	local ypos = ( YRES(480) - YRES(22) - ( (MAX_WEAPON_SLOTS) * (m_nSmallBoxTall) ) - YRES(2 * MAX_WEAPON_SLOTS) )

	for ( local slot = 0; slot < MAX_WEAPON_SLOTS; ++slot )
	{
		local wide, tall = m_nSmallBoxTall;
		local curpos = 0;

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
							m_ItemPanels[slot][i] = CItemPanel( slot );
					}
				}

				panel = m_ItemPanels[slot][pos];
				panel.m_szName = Localize.GetTokenAsUTF8( wep.GetPrintName() );
				panel.m_chIcon = m_IconChars[ wep.GetClassname() ];
				panel.m_bHasAnyAmmo = wep.HasAnyAmmo();
				panel.m_bSelected = ( slot == m_iSelectedSlot && pos == m_iSelectedPos );
				panel.m_nPos = curpos++;

				tall = m_nSmallBoxTall;
			}
			else
			{
				if ( panel )
				{
					panel.m_chIcon = 0;
					panel.m_bSelected = false;
					tall = m_nSmallBoxTall;
				}
			}

			if ( panel )
				panel.SetPos( baseWide, ypos );
		}

		ypos += tall + YRES(1);
	}
}

function CSGOHudWeaponSelection::CycleToNextWeapon(...)
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

function CSGOHudWeaponSelection::CycleToPrevWeapon(...)
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

function CSGOHudWeaponSelection::SelectSlot( slot )
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

function CSGOHudWeaponSelection::SelectWeapon( wep )
{
	input.MakeWeaponSelection( wep );
	return CSHud.OnSelectWeapon( wep );
}

function CSGOHudWeaponSelection::OpenSelection()
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

function CSGOHudWeaponSelection::LastWeapon(...)
{
	local hLastWeapon = NetProps.GetPropEntity( player, "m_hLastWeapon" );
	if ( hLastWeapon )
	{
		input.MakeWeaponSelection( hLastWeapon );
		CSHud.OnSelectWeapon( hLastWeapon );

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

function CSGOHudWeaponSelection::PhysSwap(...)
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
