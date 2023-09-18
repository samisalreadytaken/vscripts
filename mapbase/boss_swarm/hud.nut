//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//

local Swarm = this;
local XRES = XRES, YRES = YRES, surface = surface, input = input, Fmt = format, Time = Time;

class CTooltipEnabled
{
	m_item = null;
	m_tooltipHeight = 0;
	m_tooltipWidth = 0;
	m_tooltipLeftSide = 1;

	constructor( maxwide, maxlines )
	{
		m_tooltipHeight = surface.GetFontTall( Swarm.m_hTooltipFont ) * maxlines
		m_tooltipWidth = surface.GetTextWidth( Swarm.m_hTooltipFont, maxwide );
	}

	function IsCursorOver()
	{
		local x = input.GetAnalogValue( AnalogCode.MOUSE_X );
		local y = input.GetAnalogValue( AnalogCode.MOUSE_Y );
		return self.IsWithin( x, y );
	}

	function DrawTooltip()
	{
		if ( !m_item.id )
			return;

		local xo = input.GetAnalogValue( AnalogCode.MOUSE_X );
		local yo = input.GetAnalogValue( AnalogCode.MOUSE_Y );
		local w = m_tooltipWidth;
		local h = m_tooltipHeight;
		local x = xo, y = yo;
		if ( m_tooltipLeftSide )
		{
			x = xo - w;
			y = yo - h;
		}

		Swarm.m_pHUD.DrawBox( x, y, w, h, 0, 0, 0, 225, false );
		return surface.DrawColoredTextRect( Swarm.m_hTooltipFont, x+6, y+6, w, h, 255, 255, 255, 255, m_item.tooltip );
	}
}

class CItemOffer extends CTooltipEnabled
{
	self = null;
	m_item = null;
	m_slot = null;

	constructor( pParent, x, y, size, item, slot )
	{
		base.constructor( "WWWWWWWWWWWWWWWWWWWW", 2 );

		m_tooltipLeftSide = 0;
		m_item = item;
		m_slot = slot;

		self = vgui.CreatePanel( "Button", pParent, "" );
		self.SetPos( x, y );
		self.SetSize( size, size );
		self.SetVisible( true );
		self.SetPaintEnabled( true );
		self.SetPaintBackgroundEnabled( false );
		self.SetPaintBorderEnabled( false );
		self.SetCallback( "Paint", Paint.bindenv(this) );
		self.SetCallback( "DoClick", DoClick.bindenv(this) );
		self.SetDepressedSound( "ui/buttonclick.wav" );
		self.SetArmedSound( "ui/buttonrollover.wav" );
		self.SetCursor( CursorCode.dc_blank );
	}

	function DoClick()
	{
		if ( !m_item.id )
			return;

		NetMsg.Start( "Swarm.AcceptOffer" );
			NetMsg.WriteByte( m_slot );
		NetMsg.Send();

		m_item.id = SwarmEquipment.None;
	}
}

class CHudWeaponSlot extends CTooltipEnabled
{
	self = null;
	m_item = null;
	m_letter = "W";
	m_font = 0;
	m_textHalfWidth = 0;

	constructor( pParent, x, y, size, item, letter )
	{
		base.constructor( "WWW: 000000000", 6 );

		m_font = surface.GetFont( "DefaultSmall", true, "Tracker" );
		m_textHalfWidth = surface.GetCharacterWidth( m_font, 'W' ) >> 1;
		m_item = item;
		m_letter = letter;

		self = vgui.CreatePanel( "Panel", pParent, "" );
		self.SetPos( x, y );
		self.SetSize( size, size + surface.GetFontTall( m_font ) + 2 );
		self.SetVisible( true );
		self.SetPaintEnabled( true );
		self.SetPaintBackgroundEnabled( false );
		self.SetPaintBorderEnabled( false );
		self.SetCallback( "Paint", Paint.bindenv(this) );
		self.SetMouseInputEnabled( false );
	}
}

class CHudEquipmentSlot extends CTooltipEnabled
{
	self = null;
	m_item = null;
	m_slot = null;

	constructor( pParent, x, y, size, item, slot )
	{
		base.constructor( "WWWWWWWWWWWWWWWWWWWW", 2 );

		m_item = item;
		m_slot = slot;

		self = vgui.CreatePanel( "Button", pParent, "" );
		self.SetPos( x, y );
		self.SetSize( size, size );
		self.SetVisible( true );
		self.SetPaintEnabled( true );
		self.SetPaintBackgroundEnabled( false );
		self.SetPaintBorderEnabled( false );
		self.SetCallback( "Paint", Paint.bindenv(this) );
		self.SetCallback( "DoClick", DoClick.bindenv(this) );
		self.SetDepressedSound( "ui/buttonclick.wav" );
		self.SetArmedSound( "ui/buttonrollover.wav" );
		self.SetCursor( CursorCode.dc_blank );
	}

	function DoClick()
	{
		if ( !m_item.id )
			return;

		NetMsg.Start( "Swarm.RefundEquipment" );
			NetMsg.WriteByte( m_slot );
		NetMsg.Send();

		m_item.id = SwarmEquipment.None;
	}
}


function InitHUD()
{
	m_hTooltipFont = surface.GetFont( "DefaultSmall", true, "ClientScheme" );
	m_hControlsFont = surface.GetFont( "DebugFixed", true, "Tracker" );

	m_pHUD = vgui.CreatePanel( "Panel", GetRootPanel(), "" );
	m_pHUD.SetPos( 0, 0 );
	m_pHUD.SetSize( ScreenWidth(), ScreenHeight() );
	m_pHUD.SetPaintEnabled( true );
	m_pHUD.SetPaintBackgroundEnabled( false );
	m_pHUD.SetCallback( "PerformLayout", HUD_PerformLayout.bindenv(this) );
	m_pHUD.SetCallback( "Paint", HUD_Paint.bindenv(this) );
	m_pHUD.SetCallback( "OnTick", HUD_OnTick.bindenv(this) );
	m_pHUD.AddTickSignal( 50 );

	m_pLetterBox = vgui.CreatePanel( "Panel", GetRootPanel(), "" );
	m_pLetterBox.SetPos( 0, 0 );
	m_pLetterBox.SetSize( ScreenWidth(), ScreenHeight() );
	m_pLetterBox.SetZPos( 101 );
	m_pLetterBox.SetVisible( false );
	m_pLetterBox.SetPaintEnabled( true );
	m_pLetterBox.SetPaintBackgroundEnabled( false );
	m_pLetterBox.SetCallback( "Paint", PaintLetterBox.bindenv(this) );

	m_pControls = vgui.CreatePanel( "Panel", m_Cursor.m_pMenu, "controls" );
	m_pControls.SetVisible( true );
	m_pControls.SetPaintEnabled( true );
	m_pControls.SetPaintBackgroundEnabled( true );
	m_pControls.SetCallback( "Paint", PaintControls.bindenv(this) );
	m_pControls.SetMouseInputEnabled( false );

	m_iHeartTex = surface.ValidateTexture( "swarm/heart", true );

	// TODO: Move these to PerformLayout!!

	// Weapon slots
	local size = YRES(42);
	local gap = YRES(2) + size;
	local x = XRES(640 - 40) - gap * (MAX_SLOTS + 1);
	local y = YRES(480 - 65);

	foreach ( slot, item in m_Slots )
	{
		local elem = CHudWeaponSlot( m_pHUD, x + gap * slot, y, size, item, ""+(slot+1) );
		m_ToolTipHudElements.append( elem );
		m_EquipmentDisplay.append( elem );
	}

	// HACKHACK: squeeze it in
	local elem = CHudWeaponSlot( m_pHUD, x + gap * MAX_SLOTS, y, size, m_AltWeapon, "Q" );
	m_ToolTipHudElements.append( elem );
	m_EquipmentDisplay.append( elem );

	// Item slots
	size = YRES(26);
	gap = YRES(2) + size;
	x = XRES(640 - 40) - size;
	y = YRES(480 - 95) - gap * MAX_ITEMS;

	foreach ( slot, item in m_Items )
	{
		local elem = CHudEquipmentSlot( m_Cursor.m_pMenu, x, y + gap * slot, size, item, slot );
		m_ToolTipHudElements.append( elem );
		m_EquipmentDisplay.append( elem );
	}

	// Item offers
	size = YRES(42);
	gap = YRES(2) + size;
	x = XRES(40);
	y = YRES(480 - 95) - gap * MAX_ITEM_OFFERS;

	foreach ( slot, panel in m_ItemOffers )
	{
		local elem = CItemOffer( m_Cursor.m_pMenu, x, y + gap * slot, size, item_t(), slot );
		m_ToolTipHudElements.append( elem );
		m_ItemOffers[slot] = elem;
	}
}

function HUD_PerformLayout()
{
}

function HUD_OnTick()
{
	local health = player.GetHealth();

	if ( m_nHealth != health )
	{
		m_nHealth = health;
		// TODO: play animations
	}
}

function CHudWeaponSlot::Paint()
{
	local size = self.GetWide();
	local x = 0, y = 0;
	local outline = 2;

	surface.SetColor( 0, 0, 0, 255 );
	surface.DrawOutlinedRect( x, y, size, size, outline );

	size -= outline+outline;
	x += outline;
	y += outline;

	if ( m_item.id )
	{
		if ( m_item.status )
		{
			if ( m_item.status & SwarmEquipmentStatus.Active )
			{
				// active and reloading
				if ( m_item.status & SwarmEquipmentStatus.Reloading )
				{
					surface.SetColor( 63, 63, 63, 255 );
					surface.DrawFilledRect( x, y, size, size );

					local t = ( m_item.reload_end_time - Time() ) / m_item.reload_time;
					if ( t > 0.0 )
					{
						surface.SetColor( 127, 127, 127, 255 );
						surface.DrawFilledRect( x, y+size*t, size, size-size*t );
					}
					// end of reload
					else
					{
						m_item.status = m_item.status & ~(SwarmEquipmentStatus.Reloading);
					}
				}
				// active and not reloading
				else
				{
					surface.SetColor( 127, 127, 127, 255 );
					surface.DrawFilledRect( x, y, size, size );
				}
			}
			// inactive and reloading
			else //if ( m_item.status & SwarmEquipmentStatus.Reloading )
			{
				surface.SetColor( 63, 63, 63, 225 );
				surface.DrawFilledRect( x, y, size, size );

				local t = ( m_item.reload_end_time - Time() ) / m_item.reload_time;
				if ( t > 0.0 )
				{
					surface.SetColor( 95, 95, 95, 255 );
					surface.DrawFilledRect( x, y+size*t, size, size-size*t );
				}
				// end of reload
				else
				{
					m_item.status = m_item.status & ~(SwarmEquipmentStatus.Reloading);
				}
			}
		}
		// inactive and not reloading
		else
		{
			surface.SetColor( 63, 63, 63, 225 );
			surface.DrawFilledRect( x, y, size, size );
		}

		local tex = surface.ValidateTexture( Swarm.m_EquipmentTextureMap[ m_item.id ], true );
		surface.DrawTexturedBox( tex, x, y, size, size, 255, 255, 255, 255 );

		// Weapon modifier indicators
		// TODO: Display modifier icons
		for ( local mod = m_item.modifiers; mod; --mod )
		{
			local font = surface.GetFont( "DefaultSmall", true, "Tracker" );
			local w = surface.GetCharacterWidth( font, '^' );
			local h = surface.GetFontTall( font ) / 3;
			surface.DrawColoredText( font, x + size - w, y + h*mod, 100, 255, 255, 255, "^" );
		}
	}
	// no item
	else
	{
		surface.SetColor( 63, 63, 63, 127 );
		surface.DrawFilledRect( x, y, size, size );
	}

	return surface.DrawColoredText( m_font, x+size/2-m_textHalfWidth, y+size+2, 195, 195, 195, 255, m_letter );
}

function CHudEquipmentSlot::Paint()
{
	local size = self.GetWide();
	local x = 0, y = 0;
	local outline = 2;
	if ( m_item.id )
	{
		switch ( m_item.rarity )
		{
			case 0: surface.SetColor( 200, 200, 200, 255 ); break;
			case 1: surface.SetColor( 145, 240, 60, 255 ); break;
			case 2: surface.SetColor( 64, 112, 240, 255 ); break;
			case 3: surface.SetColor( 120, 60, 240, 255 ); break;
			default: surface.SetColor( 0, 0, 0, 255 );
		}
		surface.DrawOutlinedRect( x, y, size, size, outline );

		size -= outline+outline;
		x += outline;
		y += outline;

		surface.SetColor( 127, 127, 127, 225 );
		surface.DrawFilledRect( x, y, size, size );

		local tex = surface.ValidateTexture( Swarm.m_EquipmentTextureMap[ m_item.id ], true );
		return surface.DrawTexturedBox( tex, x, y, size, size, 255, 255, 255, 255 );
	}
	// no item
	else
	{
		surface.SetColor( 0, 0, 0, 127 );
		surface.DrawOutlinedRect( x, y, size, size, outline );

		size -= outline+outline;
		x += outline;
		y += outline;

		surface.SetColor( 63, 63, 63, 127 );
		return surface.DrawFilledRect( x, y, size, size );
	}
}

function CItemOffer::Paint()
{
	local size = self.GetWide();
	local x = 0, y = 0;
	local outline = 2;
	if ( m_item.id )
	{
		switch ( m_item.rarity )
		{
			case 0: surface.SetColor( 200, 200, 200, 255 ); break;
			case 1: surface.SetColor( 145, 240, 60, 255 ); break;
			case 2: surface.SetColor( 64, 112, 240, 255 ); break;
			case 3: surface.SetColor( 120, 60, 240, 255 ); break;
			default: surface.SetColor( 255, 0, 255, 255 );
		}
		surface.DrawOutlinedRect( x, y, size, size, outline );

		size -= outline+outline;
		x += outline;
		y += outline;

		surface.SetColor( 127, 127, 127, 225 );
		surface.DrawFilledRect( x, y, size, size );

		local tex = surface.ValidateTexture( Swarm.m_EquipmentTextureMap[ m_item.id ], true );
		return surface.DrawTexturedBox( tex, x, y, size, size, 255, 255, 255, 255 );
	}
	// no item
	else
	{
		surface.SetColor( 0, 0, 0, 127 );
		surface.DrawOutlinedRect( x, y, size, size, outline );

		size -= outline+outline;
		x += outline;
		y += outline;

		surface.SetColor( 63, 63, 63, 127 );
		return surface.DrawFilledRect( x, y, size, size );
	}
}

function HUD_Paint()
{
	// Health
	{
		local x = XRES(32);
		local y = YRES(42);
		local s = YRES(16);
		local m = YRES(2);

		surface.SetColor( 255, 255, 255, 255 );
		surface.SetTexture( m_iHeartTex );

		local hp = m_nHealth;
		local dt = m_nMaxHealth - hp;
		while ( hp-- )
		{
			surface.DrawTexturedRect( x, y, s, s );
			x += s + m;
		}
		surface.SetColor( 70, 70, 70, 200 );
		while ( dt --> 0 )
		{
			surface.DrawTexturedRect( x, y, s, s );
			x += s + m;
		}
	}

	// Boss health
	if ( Swarm.m_flBossHealth )
	{
		local width = YRES(290);
		local height = YRES(10);

		local x = XRES(320) - (width >> 1);
		local y = YRES(480 - 80) - height;
		local outline = 2;

		surface.SetColor( 0, 0, 0, 255 );
		surface.DrawOutlinedRect( x-outline, y-outline, width+outline+outline, height+outline+outline, outline );
		surface.SetColor( 41, 41, 41, 255 );
		surface.DrawFilledRect( x, y, width, height );
		surface.SetColor( 200, 20, 20, 255 );
		surface.DrawFilledRect( x, y, Swarm.m_flBossHealth * width, height );
		surface.SetColor( 225, 80, 80, 255 );
		surface.DrawFilledRectFade( x, y, Swarm.m_flBossHealth * width, height >> 1, 255, 0, false );
	}

	// Boss shield
	if ( Swarm.m_flBossShield )
	{
		local width = YRES(290);
		local height = YRES(5);

		local x = XRES(320) - (width >> 1);
		local y = YRES(480 - 80) - height - YRES(10) - 2;
		local outline = 2;

		surface.SetColor( 0, 0, 0, 255 );
		surface.DrawOutlinedRect( x-outline, y-outline, width+outline+outline, height+outline+outline, outline );
		surface.SetColor( 41, 41, 41, 255 );
		surface.DrawFilledRect( x, y, width, height );
		surface.SetColor( 60, 100, 200, 255 );
		surface.DrawFilledRect( x, y, Swarm.m_flBossShield * width, height );
		surface.SetColor( 100, 120, 225, 255 );
		surface.DrawFilledRectFade( x, y, Swarm.m_flBossShield * width, height >> 1, 255, 0, false );
	}
}

local function ApertureFadeThink(_)
{
	if ( m_Cursor.m_bEnginePaused )
		return 0.0;

	local curtime = Time();
	local t = ( curtime - m_flFadeStartTime ) / m_flFadeFadeTime;

	if ( m_bFadeIn )
	{
		t = 1.0 - t;
		if ( t < 0.0 )
		{
			m_Cursor.m_pFade.SetVisible( false );
			m_pAperture.SetLocalOrigin( Vector(0,0,768) );
			if ( m_fnFadeCallback )
			{
				m_fnFadeCallback();
				m_fnFadeCallback = null;
			}
			return -1;
		}
	}
	else
	{
		if ( t >= 1.0 )
		{
			m_Cursor.m_pFade.SetAlpha( 255 );
			m_pAperture.SetLocalOrigin( Vector(0,0,768) );
			if ( m_fnFadeCallback )
			{
				m_fnFadeCallback();
				m_fnFadeCallback = null;
			}
			return -1;
		}
	}

	local viewOrigin = CurrentViewOrigin();
	local pos = m_pEntity.GetLocalOrigin()
		.Subtract( viewOrigin ).Multiply( Bias( t, 0.2 ) ).Add( viewOrigin );
	m_pAperture.SetLocalOrigin( pos );
	m_Cursor.m_pFade.SetAlpha( Bias( t, 0.35 ) * 255.0 );
	return 0.0;
}

function ApertureFade( dir, time, delay, callback )
{
	m_flFadeStartTime = Time() + delay;
	m_flFadeFadeTime = time;
	m_bFadeIn = dir;
	m_fnFadeCallback = callback;

	m_Cursor.m_pFade.SetVisible( true );

	if ( dir )
	{
		m_Cursor.m_pFade.SetAlpha( 255 );
	}
	else
	{
		m_Cursor.m_pFade.SetAlpha( 0 );
	}

	// TODO: Use material switches instead of separate entities
	if ( RandomFloat( 0.0, 1.0 ) < 0.1 )
	{
		m_pAperture = Entities.FindByName( null, ".aperture2" );
		// Hide the other
		Entities.FindByName( null, ".aperture" ).SetLocalOrigin( Vector(0,0,768) );
	}
	else
	{
		m_pAperture = Entities.FindByName( null, ".aperture" );
		Entities.FindByName( null, ".aperture2" ).SetLocalOrigin( Vector(0,0,768) );
	}

	return Entities.First().SetContextThink( "Swarm.Fade", ApertureFadeThink.bindenv(this), delay );
}

function PaintLetterBox()
{
	local curtime = Time();
	local t = 1.0;
	if ( m_flCutsceneStartTime < curtime )
	{
		t = ( curtime - m_flCutsceneStartTime ) / m_flCutsceneTransTime;

		if ( m_bCutsceneIn )
		{
			if ( t >= 1.0 )
			{
				m_bCutsceneIn = false;
				m_flCutsceneStartTime = curtime + m_flCutsceneHoldTime;
			}
		}
		else
		{
			if ( t >= 1.0 )
			{
				m_pLetterBox.SetVisible( false );
				m_flCutsceneStartTime = FLT_MAX;
			}
			t = 1.0 - t;
		}
	}
	else if ( m_bCutsceneIn )
	{
		t = 0.0;
	}

	local tex = surface.ValidateTexture( "swarm/bigbosslabel", true );
	local w = YRES(196), h = w >> 1;
	surface.DrawTexturedBox( tex, (ScreenWidth() - w) / 2, (ScreenHeight() - h) / 2, w, h, 255, 255, 255, 255 * VS.SmoothCurve( t ) );

	t = VS.SmoothCurve( t );
	// letterbox size
	local h = YRES(120) * t;

	surface.SetColor( 0, 0, 0, 255 );
	surface.DrawFilledRect( 0, 0, ScreenWidth(), h + 0.5 );
	surface.DrawFilledRect( 0, ScreenHeight() - h, ScreenWidth(), h + 0.5 );
}

function PaintControls()
{
	local lineTall = surface.GetFontTall( m_hControlsFont );
	local w = m_pControls.GetWide();
	local h = m_pControls.GetTall();
	// margin
	local x = 8;
	local y = 6;
	local mx = input.GetAnalogValue( AnalogCode.MOUSE_X );
	local my = input.GetAnalogValue( AnalogCode.MOUSE_Y );

	if ( m_pControls.IsWithin( mx, my ) )
	{
		local l10 = "MOVE";
		local l11 = "         W A S D    | ARROW KEYS";
		local l20 = "SHOOT";
		local l21 = "         MOUSE LEFT | SPACE";
		local l40 = "RESTART";
		local l41 = "         DELETE";
		local l30 = "WEAPONS";
		local l31 = "         1 | 2 | 3 | Q";

		m_pControls.DrawBox( 0, 0, w, h, 0, 0, 0, 235, false );
		surface.DrawColoredText( m_hControlsFont, x, y, 200, 200, 100, 255, l10 );
		surface.DrawColoredText( m_hControlsFont, x, y, 200, 200, 200, 255, l11 );
		surface.DrawColoredText( m_hControlsFont, x, y + lineTall, 200, 200, 100, 255, l20 );
		surface.DrawColoredText( m_hControlsFont, x, y + lineTall, 200, 200, 200, 255, l21 );
		surface.DrawColoredText( m_hControlsFont, x, y + lineTall + lineTall, 200, 200, 100, 255, l30 );
		surface.DrawColoredText( m_hControlsFont, x, y + lineTall + lineTall, 200, 200, 200, 255, l31 );
		surface.DrawColoredText( m_hControlsFont, x, y + lineTall + lineTall + lineTall, 200, 200, 100, 255, l40 );
		surface.DrawColoredText( m_hControlsFont, x, y + lineTall + lineTall + lineTall, 200, 200, 200, 255, l41 );
	}
	else
	{
		m_pControls.DrawBox( 0, 0, w, h, 15, 15, 15, 125, false );
		surface.DrawColoredText( m_hControlsFont, x + (w-surface.GetTextWidth(m_hControlsFont, "CONTROLS")) / 2, y + (h-lineTall) / 2, 200, 200, 200, 255, "CONTROLS" );
	}
}
