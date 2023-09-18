//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// NOTE: dc_blank changes mouse sensitivity. I don't know if this is a Linux only issue or not.
//


local Swarm = this;
local surface = surface, input = input, FrameTime = FrameTime;
local Fmt = format, date = date, Time = Time;

class CImageButton
{
	self = null;
	m_iTexture = 0;
	m_r = 0;
	m_g = 0;
	m_b = 0;
	m_a = 0;

	SetPos = null;
	SetSize = null;
	SetVisible = null;
	SetCallback = null;

	constructor( pParent, tex, r = 255, g = 255, b = 255, a = 255 )
	{
		self = vgui.CreatePanel( "Button", pParent, "" );
		self.SetVisible( true );
		self.SetPaintEnabled( true );
		self.SetPaintBackgroundEnabled( false );
		self.SetPaintBorderEnabled( false );
		self.SetCallback( "Paint", Paint.bindenv(this) );
		self.SetDepressedSound( "ui/buttonclick.wav" );
		self.SetArmedSound( "ui/buttonrollover.wav" );
		self.SetCursor( CursorCode.dc_blank );

		m_iTexture = surface.ValidateTexture( tex, true );
		m_r = r;
		m_g = g;
		m_b = b;
		m_a = a;

		SetPos = self.SetPos.bindenv(self);
		SetSize = self.SetSize.bindenv(self);
		SetVisible = self.SetVisible.bindenv(self);
		SetCallback = self.SetCallback.bindenv(self);
	}

	function Paint()
	{
		local w = self.GetWide(), t = self.GetTall();

		if ( self.IsArmed() )
		{
			surface.SetColor( 195, 195, 195, 255 );
			surface.DrawFilledRect( 2, 2, w-2, t-2 );
		}
		else
		{
			surface.SetColor( 127, 127, 127, 225 );
			surface.DrawFilledRect( 2, 2, w-2, t-2 );
		}

		surface.DrawTexturedBox( m_iTexture, 0, 0, w, t, m_r, m_g, m_b, m_a );

		surface.SetColor( 0, 0, 0, 255 );
		surface.DrawOutlinedRect( 1, 1, w-1, t-1, 2 );
	}
}

class CCursor
{
	self = null;
	m_pMenu = null;
	m_pQuit = null;
	m_pFade = null;
	m_pDeathCount = null;
	m_pButtonXhair1 = null;
	m_pButtonXhair2 = null;
	m_pButtonXhair3 = null;
	m_pButtonXhair4 = null;

	m_x = 0;
	m_y = 0;
	m_iTexture = null;

	m_Buttons = null;
	m_CmdKeys = null;

	m_Input = 0;

	m_bEnginePaused = false;
	m_bDrawTime = false;
}

function CCursor::Init()
{
	self = vgui.CreatePanel( "Panel", Swarm.GetRootPanel(), "cursor" );
	self.MakePopup();
	self.SetPos( 0, 0 );
	self.SetSize( ScreenWidth(), ScreenHeight() );
	self.SetZPos( 100 );
	self.SetPaintEnabled( false );
	self.SetPaintBackgroundEnabled( false );
	self.SetPostChildPaintEnabled( true );
	self.SetMouseInputEnabled( true );
	self.SetKeyBoardInputEnabled( true );
	self.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );
	self.SetCallback( "PostChildPaint", PostChildPaint.bindenv(this) );
	self.SetCallback( "OnCursorEntered", OnCursorEntered.bindenv(this) );
	self.SetCallback( "OnMousePressed", OnKeyCodePressed.bindenv(this) );
	self.SetCallback( "OnMouseReleased", OnKeyCodeReleased.bindenv(this) );
	self.SetCallback( "OnMouseDoublePressed", OnKeyCodePressed.bindenv(this) );
	self.SetCallback( "OnKeyCodePressed", OnKeyCodePressed.bindenv(this) );
	self.SetCallback( "OnKeyCodeReleased", OnKeyCodeReleased.bindenv(this) );
	self.SetCallback( "OnTick", OnTick.bindenv(this) );
	self.AddTickSignal( 0 );
	self.SetCursor( CursorCode.dc_blank );
	m_iTexture = surface.ValidateTexture( "swarm/xhair1", true );

	m_pFade = vgui.CreatePanel( "Panel", self, "fade" );
	m_pFade.SetPos( 0, 0 );
	m_pFade.SetSize( ScreenWidth(), ScreenHeight() );
	m_pFade.SetZPos( 100 );
	m_pFade.SetVisible( true );
	m_pFade.SetPaintEnabled( false );
	m_pFade.SetPaintBackgroundEnabled( true );
	m_pFade.SetPaintBackgroundType( 0 );
	m_pFade.MakeReadyForUse();
	m_pFade.SetBgColor( 0, 0, 0, 255 );
	m_pFade.SetMouseInputEnabled( false );

	m_pMenu = vgui.CreatePanel( "Panel", self, "menu" );
	m_pMenu.SetPos( 0, 0 );
	m_pMenu.SetSize( ScreenWidth(), ScreenHeight() );
	m_pMenu.SetVisible( false );
	m_pMenu.SetPaintEnabled( false );
	m_pMenu.SetPaintBackgroundEnabled( false );
	m_pMenu.SetMouseInputEnabled( true );
	m_pMenu.SetKeyBoardInputEnabled( false );
	m_pMenu.SetCallback( "OnMousePressed", OnKeyCodePressed.bindenv(this) );
	m_pMenu.SetCallback( "OnMouseReleased", OnKeyCodeReleased.bindenv(this) );
	m_pMenu.SetCallback( "OnMouseDoublePressed", OnKeyCodePressed.bindenv(this) );
	m_pMenu.SetCursor( CursorCode.dc_blank );

	m_pQuit = vgui.CreatePanel( "Button", m_pMenu, "quit" );
	m_pQuit.SetZPos( 100 );
	m_pQuit.SetVisible( true );
	m_pQuit.SetPaintEnabled( true );
	m_pQuit.SetPaintBackgroundEnabled( true );
	m_pQuit.SetPaintBackgroundType( 2 );
	m_pQuit.SetCursor( CursorCode.dc_blank );
	m_pQuit.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
	m_pQuit.SetText( "r" );
	m_pQuit.SetContentAlignment( Alignment.center );
	m_pQuit.SetCallback( "DoClick", function()
	{
		Swarm.m_Cursor.m_pQuit.SetEnabled( false );
		Swarm.FadeToDisconnect( 1.0, 0.0 );
	} );

	m_pDeathCount = vgui.CreatePanel( "Label", m_pMenu, "deathcount" );
	m_pDeathCount.SetVisible( true );
	m_pDeathCount.SetPaintEnabled( true );
	m_pDeathCount.SetPaintBackgroundEnabled( false );
	m_pDeathCount.SetMouseInputEnabled( false );
	m_pDeathCount.SetFont( surface.GetFont( "DefaultSmall", false, "Tracker" ) );
	m_pDeathCount.SetContentAlignment( Alignment.center );

	m_pButtonXhair1 = Swarm.CImageButton( m_pMenu, "swarm/xhair1" );
	m_pButtonXhair2 = Swarm.CImageButton( m_pMenu, "swarm/xhair2" );
	m_pButtonXhair3 = Swarm.CImageButton( m_pMenu, "swarm/xhair3" );
	m_pButtonXhair4 = Swarm.CImageButton( m_pMenu, "vgui/cursors/crosshair" );

	m_pButtonXhair1.SetCallback( "DoClick", function()
	{
		m_iTexture = surface.ValidateTexture( "swarm/xhair1", true );
	}.bindenv(this) );

	m_pButtonXhair2.SetCallback( "DoClick", function()
	{
		m_iTexture = surface.ValidateTexture( "swarm/xhair2", true );
	}.bindenv(this) );

	m_pButtonXhair3.SetCallback( "DoClick", function()
	{
		m_iTexture = surface.ValidateTexture( "swarm/xhair3", true );
	}.bindenv(this) );

	m_pButtonXhair4.SetCallback( "DoClick", function()
	{
		m_iTexture = surface.ValidateTexture( "vgui/cursors/crosshair", true );
	}.bindenv(this) );


	m_Buttons =
	{
		[ButtonCode.MOUSE_LEFT] = SwarmInput.ATTACK,
		[ButtonCode.MOUSE_RIGHT] = SwarmInput.ATTACK2,
		[ButtonCode.KEY_Q] = SwarmInput.ATTACK2,
		[ButtonCode.KEY_W] = SwarmInput.FORWARD,
		[ButtonCode.KEY_A] = SwarmInput.LEFT,
		[ButtonCode.KEY_S] = SwarmInput.BACK,
		[ButtonCode.KEY_D] = SwarmInput.RIGHT,
		[ButtonCode.KEY_E] = SwarmInput.USE,
		[ButtonCode.KEY_SPACE] = SwarmInput.ATTACK,

		[ButtonCode.KEY_UP] = SwarmInput.FORWARD,
		[ButtonCode.KEY_LEFT] = SwarmInput.LEFT,
		[ButtonCode.KEY_DOWN] = SwarmInput.BACK,
		[ButtonCode.KEY_RIGHT] = SwarmInput.RIGHT,

		[ButtonCode.KEY_PAD_0] = SwarmInput.ATTACK,

		[ButtonCode.KEY_TAB] = SwarmInput.INVENTORY,
	}

	m_CmdKeys =
	{
		[ButtonCode.KEY_1] = "SelectSlot0",
		[ButtonCode.KEY_2] = "SelectSlot1",
		[ButtonCode.KEY_3] = "SelectSlot2",
		[ButtonCode.KEY_DELETE] = "FadeAndResetGame",
	}
}

function CCursor::PerformLayout()
{
	m_pFade.SetPos( 0, 0 );
	m_pFade.SetSize( ScreenWidth(), ScreenHeight() );

	m_pQuit.SetSize( YRES(12), YRES(12) );
	m_pQuit.SetPos( ScreenWidth() - m_pQuit.GetWide(), 0 );
	m_pQuit.SetDefaultColor( 255, 255, 255, 255, 200, 30, 30, 255 );
	m_pQuit.SetArmedColor( 255, 255, 255, 255, 225, 90, 90, 255 );
	m_pQuit.SetDepressedColor( 255, 255, 255, 255, 225, 90, 90, 255 );

	m_pDeathCount.SetPos( 1, 1 );

	// Crosshair buttons
	{
		local s = (32);
		local x = XRES(640 - 52);
		local y = YRES(42);

		m_pButtonXhair4.SetPos( x, y );
		m_pButtonXhair4.SetSize( s, s );

		m_pButtonXhair3.SetPos( x - s - 2, y );
		m_pButtonXhair3.SetSize( s, s );

		m_pButtonXhair2.SetPos( x - s - s - 4, y );
		m_pButtonXhair2.SetSize( s, s );

		m_pButtonXhair1.SetPos( x - s - s - s - 6, y );
		m_pButtonXhair1.SetSize( s, s );
	}

	if ( Swarm.m_pControls )
	{
		local lineCount = 4;
		local longestLine = "MOVE:    W A S D    | ARROW KEYS";
		local w = surface.GetTextWidth( Swarm.m_hControlsFont, longestLine ) + 16;
		local lineTall = surface.GetFontTall( Swarm.m_hControlsFont );
		local h = lineTall * lineCount + 12;
		local x = XRES(320) - w / 2;
		local y = YRES(240) + h * 2;

		Swarm.m_pControls.SetPos( x, y );
		Swarm.m_pControls.SetSize( w, h );
	}
}

function CCursor::OnTick()
{
	m_x = input.GetAnalogValue( AnalogCode.MOUSE_X );
	m_y = input.GetAnalogValue( AnalogCode.MOUSE_Y );

	if ( FrameTime() )
	{
		if ( m_bEnginePaused )
		{
			local dt = date();
			printf( "[%2d:%02d:%02d] ENGINE RESUMED\n", dt.hour, dt.min, dt.sec );

			m_bEnginePaused = false;
		}
	}
	else
	{
		if ( !m_bEnginePaused )
		{
			local dt = date();
			printf( "[%2d:%02d:%02d] ENGINE PAUSED\n", dt.hour, dt.min, dt.sec );

			m_bEnginePaused = true;
			m_Input = 0;
		}
	}
}

function CCursor::OnCursorEntered()
{
	input.SetCursorPos( m_x, m_y );
}

function CCursor::OnKeyCodePressed( code )
{
	if ( code in m_Buttons )
	{
		m_Input = m_Input | m_Buttons[code];
	}
	else if ( code in m_CmdKeys )
	{
		Swarm[ m_CmdKeys[code] ]();
	}
}

function CCursor::OnKeyCodeReleased( code )
{
	if ( code in m_Buttons )
	{
		m_Input = m_Input & ~(m_Buttons[code]);
	}
}

local version = "2308191749-3fb3e4ff";

function CCursor::PostChildPaint()
{
	if ( m_bDrawTime && (m_Input & SwarmInput.INVENTORY) )
	{
		local dt = date();
		local font = surface.GetFont( "DebugFixedSmall", true, "Tracker" );
		local h = surface.GetFontTall( font );

		local text = Fmt( "%d-%02d-%02d", dt.year, dt.month+1, dt.day );
		local w = surface.GetTextWidth( font, text );
		surface.DrawColoredText( font, (XRES(640) - w) / 2, 4, 200, 200, 200, 255, text );

		text = Fmt( "%02d:%02d:%02d", dt.hour, dt.min, dt.sec );
		w = surface.GetTextWidth( font, text );
		surface.DrawColoredText( font, (XRES(640) - w) / 2, 4 + h, 200, 200, 200, 255, text );

		surface.DrawColoredText( font, 0, YRES(480)-h, 200, 200, 200, 255, version );
	}

	// Cursor
	local curitem = Swarm.m_Slots[ Swarm.m_iActiveSlot ];
	if ( curitem.status & SwarmEquipmentStatus.Reloading )
	{
		local t = ( curitem.reload_end_time - Time() ) / curitem.reload_time;
		if ( t > 0.0 )
		{
			surface.SetTexture( m_iTexture );
			surface.SetColor( 195, 195, 195, 255 );
			surface.DrawTexturedRectRotated( m_x-16, m_y-16, 32, 32, 360.0 * t );
		}
	}
	else
	{
		surface.DrawTexturedBox( m_iTexture, m_x-16, m_y-16, 32, 32, 255, 255, 255, 255 );
	}

	// Tooltips
	if ( m_pMenu.IsVisible() )
	{
		foreach ( elem in Swarm.m_ToolTipHudElements )
		{
			if ( elem.IsCursorOver() )
			{
				elem.DrawTooltip();
				break;
			}
		}
	}
}

function CCursor::SetCursor( cursor )
{
	switch ( cursor )
	{
		case CursorCode.dc_arrow:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/arrow", true );
			break;
		case CursorCode.dc_ibeam:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/ibeam", true );
			break;
		case CursorCode.dc_hourglass:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/hourglass", true );
			break;
		case CursorCode.dc_waitarrow:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/waitarrow", true );
			break;
		case CursorCode.dc_crosshair:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/crosshair", true );
			break;
		case CursorCode.dc_up:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/up", true );
			break;
		case CursorCode.dc_sizenwse:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/sizenwse", true );
			break;
		case CursorCode.dc_sizenesw:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/sizenesw", true );
			break;
		case CursorCode.dc_sizewe:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/sizewe", true );
			break;
		case CursorCode.dc_sizens:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/sizens", true );
			break;
		case CursorCode.dc_sizeall:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/sizeall", true );
			break;
		case CursorCode.dc_no:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/no", true );
			break;
		case CursorCode.dc_hand:
			m_iTexture = surface.ValidateTexture( "vgui/cursors/hand", true );
			break;
		case CursorCode.dc_none:
		case CursorCode.dc_blank:
		default:
			m_iTexture = 0;
	}
}
