//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
local XRES = XRES, YRES = YRES;
local surface = surface;
local Localize = Localize;
local input = input;


const MAX_WEAPONS = 48;
const MAX_WEAPON_SLOTS = 6;
const MAX_WEAPON_POSITIONS = 4;


class CSGOHudWeaponSelection
{
	CSHud = null;
	constructor( CSHud )
	{
		this.CSHud = CSHud;
	}

	self = null
	m_IconChars = null
	m_ItemPanels = null

	m_iActiveSlot = 0
	m_iActivePos = 0
	m_hLastWeapon = null

	m_bFading = false
	m_flHideTime = 1.e+38
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
}

function CSGOHudWeaponSelection::CItemPanel::constructor( slot, pos )
{
	m_chNumber = '0'+(slot+1);
	m_nPos = pos;

	m_hFontLabel = surface.GetFont( "weapon-selection-item-name-text", true );
	m_hFontIcon = surface.GetFont( "weapon-selection-item-icon", true );
	m_hFontIconBlur = surface.GetFont( "weapon-selection-item-icon-blur", true );
}

function CSGOHudWeaponSelection::CItemPanel::Paint()
{
	// Draw the number if this is the first position in a slot
	if ( !m_nPos )
	{
		// background
		local flAlpha = CSHud.m_flBackgroundAlpha;
		surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );
		surface.DrawFilledRectFade( XRES(640-140-24), m_yposNumber-YRES(1), XRES(140), YRES(34), 0x00, 0xff, true );
		surface.DrawFilledRect( XRES(640-24), m_yposNumber-YRES(1), XRES(24), YRES(34) );

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

	// Draw a darker background if this is the selected slot
	if ( m_bSelected )
	{
		local flAlpha = CSHud.m_flBackgroundAlpha;
		surface.SetColor( 0x00, 0x00, 0x00, 0xcc * flAlpha );
		surface.DrawFilledRectFade( XRES(640-140-24), m_yposNumber-YRES(1), XRES(140), YRES(34), 0x00, 0xff, true );
		surface.DrawFilledRect( XRES(640-24), m_yposNumber-YRES(1), XRES(24), YRES(34) );
	}

	if ( m_bSelected )
	{
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

	m_xposIcon = x - surface.GetCharacterWidth( m_hFontIcon, m_chIcon ) - YRES(70) * m_nPos - YRES(8);
	m_yposIcon = y;

	m_xposLabel = x - surface.GetTextWidth( m_hFontLabel, m_szName ) - YRES(70) * m_nPos - YRES(8);
	m_yposLabel = y + surface.GetFontTall( m_hFontIcon ) - YRES(4);
}

function CSGOHudWeaponSelection::Init()
{
	self = vgui.CreatePanel( "Panel", CSHud.GetRootPanel(), "CSGOHudWeaponSelection" );
	self.SetPos( 0, 0 );
	self.SetSize( ScreenWidth(), ScreenHeight() );
	self.SetVisible( false );
	self.SetPaintEnabled( true );
	self.SetPaintBackgroundEnabled( false );
	self.AddTickSignal( 50 );
	self.SetCallback( "OnTick", OnTick.bindenv(this) );
	self.SetCallback( "Paint", Paint.bindenv(this) );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );

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
		m_ItemPanels[i] = [ CItemPanel( i, 0 ) ];
	}
}

function CSGOHudWeaponSelection::RegisterCommands()
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

function CSGOHudWeaponSelection::UnregisterCommands()
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

function CSGOHudWeaponSelection::Paint()
{
	foreach ( slot in m_ItemPanels )
		foreach ( panel in slot )
			panel.Paint();
}

function CSGOHudWeaponSelection::OnTick()
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

function CSGOHudWeaponSelection::PerformLayout()
{
	return PerformLayoutInternal();
}

function CSGOHudWeaponSelection::PerformLayoutInternal()
{
	local m_nSmallBoxTall = YRES(34);
	local baseWide = XRES(640);
	local ypos = ( YRES(480) - YRES(22) - ( (MAX_WEAPON_SLOTS) * (m_nSmallBoxTall) ) - YRES(2 * MAX_WEAPON_SLOTS) )

	for ( local slot = 0; slot < MAX_WEAPON_SLOTS; ++slot )
	{
		local wide, tall = m_nSmallBoxTall;

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
							m_ItemPanels[slot][i] = CItemPanel( slot, i );
					}
				}

				panel = m_ItemPanels[slot][pos];
				panel.m_szName = Localize.GetTokenAsUTF8( wep.GetPrintName() );
				panel.m_chIcon = m_IconChars[ wep.GetClassname() ];
				panel.m_bHasAnyAmmo = wep.HasAnyAmmo();
				panel.m_bSelected = ( slot == m_iActiveSlot && pos == m_iActivePos );

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
	local activeWep = player.GetActiveWeapon();
	if ( !activeWep )
		return;

	local wep = FindNextWeapon( activeWep.GetSlot(), activeWep.GetPosition() );
	if ( !wep )
		wep = FindNextWeapon( -1, -1 );

	if ( wep )
		return SelectWeapon( wep );
}

function CSGOHudWeaponSelection::CycleToPrevWeapon(...)
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

function CSGOHudWeaponSelection::SelectWeapon( weapon )
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

	CSHud.OnSelectWeapon( weapon );

	return PerformLayoutInternal();
}

function CSGOHudWeaponSelection::SelectSlot( slot )
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

		CSHud.OnSelectWeapon( wep );
	}
	else
	{
		player.EmitSound( "Player.DenyWeaponSelection" );
	}

	return PerformLayoutInternal();
}

// NOTE: Does not account for conditions when weapons cannot be switched!
function CSGOHudWeaponSelection::LastWeapon(...)
{
	if ( m_hLastWeapon && m_hLastWeapon.IsValid() )
	{
		input.MakeWeaponSelection( m_hLastWeapon );
	}

	m_hLastWeapon = player.GetActiveWeapon();
}

// NOTE: Does not account for conditions when weapons cannot be switched!
function CSGOHudWeaponSelection::PhysSwap(...)
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