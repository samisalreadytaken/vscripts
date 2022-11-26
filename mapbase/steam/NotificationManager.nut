//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// server:
//		SetSteamNotificationPosition( player, enum SteamNotificationPosition )
//
// client:
//		SetSteamNotificationPosition( enum SteamNotificationPosition )
//
//

enum SteamNotificationPosition
{
	TopLeft, TopRight, BottomLeft, BottomRight
}

if ( SERVER_DLL )
{
	function SetSteamNotificationPosition( player, i )
	{
		NetMsg.Start( "SteamNotificationPosition" );
		NetMsg.WriteByte( i );
		NetMsg.Send( player, true );
	}

	return;
}


local Fmt = format;
local SteamScheme = SteamScheme;
local g_SteamNotificationPosition = SteamNotificationPosition.BottomRight;
local XRES = XRES, YRES = YRES;

function SetSteamNotificationPosition( i )
{
	g_SteamNotificationPosition = clamp( i, 0, 3 );
}

SteamNotificationManager <-
{
	m_pManager = null
	m_Queue = null
	m_Stack = null

	m_szHotkey = null

	CBaseNotification = class
	{
		m_flDisplayStart = 0.0
		m_StartYPos = 0;
		m_EndYPos = 0;
		m_wide = 0;
		m_tall = 0;

		self = null

		constructor( name )
		{
			self = vgui.CreatePanel( "Panel", vgui.GetRootPanel(), name );
			self.MakeReadyForUse();
			self.SetZPos( 0 );
			self.SetVisible( false );
			self.SetPaintEnabled( false );
			self.SetPaintBackgroundEnabled( true );
			self.SetCallback( "PaintBackground", PaintBackground.bindenv(this) );

			SteamNotificationManager.AddNotification( this );
		}

		function PerformLayout( w, t )
		{
			m_wide = w;
			m_tall = t;

			self.SetSize( w, t );

			switch ( g_SteamNotificationPosition )
			{
				case SteamNotificationPosition.BottomRight:
					m_EndYPos = YRES(480) - t;
					m_StartYPos = YRES(480);
					self.SetPos( XRES(640) - w, m_StartYPos );
					break;

				case SteamNotificationPosition.TopRight:
					m_EndYPos = 0;
					m_StartYPos = -t;
					self.SetPos( XRES(640) - w, m_StartYPos );
					break;

				case SteamNotificationPosition.TopLeft:
					m_EndYPos = 0;
					m_StartYPos = -t;
					self.SetPos( 0, m_StartYPos );
					break;

				case SteamNotificationPosition.BottomLeft:
					m_EndYPos = YRES(480) - t;
					m_StartYPos = YRES(480);
					self.SetPos( 0, m_StartYPos );
					break;
			}
		}

		function Display()
		{
			if ( !self.IsValid() )
				return Warning("CBaseNotification::Display() on dead panel\n");

			m_flDisplayStart = clock();
			self.SetVisible( true );
			self.MakePopup();
			self.SetMouseInputEnabled( false );
			self.SetKeyBoardInputEnabled( false );
		}

		function PaintBackground()
		{
			// steam.styles : Notification
			local w = m_wide;
			local t = m_tall;

			local clr = SteamScheme["DialogBG"];
			surface.SetColor( clr[0], clr[1], clr[2], clr[3] );
			surface.DrawFilledRect( 0, 0, w, t );

			clr = SteamScheme["ClientBG"];
			surface.SetColor( clr[0], clr[1], clr[2], clr[3] );
			surface.DrawFilledRectFade( 0, 0, w, 80, 0, 255, false );

			surface.DrawOutlinedRect( 0, 0, w, t, 1 );

			clr = SteamScheme["Highlight5"];
			surface.SetColor( clr[0], clr[1], clr[2], clr[3] );
			surface.DrawFilledRectFade( w-1, 0, w, t, 0, 255, false );
		}

		//
		// Slide animation.
		// TODO: This is not _exactly_ how Steam notifications move, but this isn't something
		// that anyone would notice unless they've inspected them closely before.
		//
		function OnTick( t )
		{
			const FadeInTime = 0.15;
			const FadeOutTime = 0.15;
			const DisplayTime = 6.0;

			if ( !m_flDisplayStart )
				return;

			local dt = t - m_flDisplayStart;

			if ( dt >= DisplayTime + FadeInTime + FadeOutTime )
				return SteamNotificationManager.RemoveNotification( this );

			if ( dt <= FadeInTime )
			{
				self.SetPos( self.GetXPos(), m_StartYPos + GetAnimYPos( 1, dt ) );
			}
			else if ( dt >= DisplayTime + FadeOutTime )
			{
				self.SetPos( self.GetXPos(), m_EndYPos + GetAnimYPos( 0, dt ) );
				self.SetAlpha( RemapVal( dt-(DisplayTime+FadeOutTime), 0.0, FadeOutTime, 255.0, 127.0 ) );
			}
			// Fixup end pos
			else if ( self.GetYPos() != m_EndYPos )
			{
				self.SetPos( self.GetXPos(), m_EndYPos );
			}
		}

		function GetAnimYPos( dir, dt )
		{
			if ( dir )
			{
				local v = ( dt / FadeInTime ) * m_tall;

				switch ( g_SteamNotificationPosition )
				{
					case SteamNotificationPosition.BottomLeft:
					case SteamNotificationPosition.BottomRight:
						return -v + 0.5;

					case SteamNotificationPosition.TopLeft:
					case SteamNotificationPosition.TopRight:
						return v + 0.5;
				}
			}
			else
			{
				local v = ( (dt-(DisplayTime+FadeOutTime)) / FadeOutTime ) * m_tall;

				switch ( g_SteamNotificationPosition )
				{
					case SteamNotificationPosition.BottomLeft:
					case SteamNotificationPosition.BottomRight:
						return v + 0.5;

					case SteamNotificationPosition.TopLeft:
					case SteamNotificationPosition.TopRight:
						return -v + 0.5;
				}
			}
		}
	}
}

function SteamNotificationManager::Init()
{
	print("SteamNotificationManager::Init()\n")

	if ( !m_pManager || !m_pManager.IsValid() )
	{
/*
		local l = { time = -1 }
		RestoreTable( "SteamGameOverlay.Time", l );
		if ( l.time == -1 )
		{
			l.time = time();
			SaveTable( "SteamGameOverlay.Time", l );
		}
		m_nInitTime = l.time;
*/
		m_Stack = [];
		m_Queue = [];

		SetHotkey( ButtonCode.KEY_LSHIFT, ButtonCode.KEY_TAB );

		m_pManager = vgui.CreatePanel( "Panel", vgui.GetRootPanel(), "SteamNotifications" );
		//m_pManager.SetPos( 0, 0 );
		//m_pManager.SetSize( ScreenWidth(), ScreenHeight() );
		m_pManager.SetAlpha( 0 );
		m_pManager.SetVisible( false );
		m_pManager.SetPaintEnabled( false );
		m_pManager.SetPaintBackgroundEnabled( false );
		m_pManager.SetCallback( "OnTick", OnTick.bindenv(this) );
		m_pManager.AddTickSignal( 0 );
	}

	NetMsg.Receive( "SteamNotificationPosition", function()
	{
		return SetSteamNotificationPosition( NetMsg.ReadByte() );
	} );

	CSteamFriendNotification.Init();
}

function SteamNotificationManager::SetHotkey( keyAccel, key )
{
	keyAccel = input.ButtonCodeToString( keyAccel ).tolower();
	keyAccel = keyAccel[0].tochar().toupper() + keyAccel.slice(1);

	key = input.ButtonCodeToString( key ).tolower();
	key = key[0].tochar().toupper() + key.slice(1);

	m_szHotkey = Fmt( "%s+%s", keyAccel, key );
}
/*
//
// "resource/layout/overlaydashboard.layout"
// "resource/layout/overlaytaskbar.layout"
// "resource/layout/overlaydesktop.layout"
//
function SteamGameOverlay::CreateOverlayPanels()
{
	if ( m_pGameName && m_pGameName.IsValid() )
		return;

	m_pGameName = vgui.CreatePanel( "Label", m_pManager, "GameName" );
	m_pGameName.SetContentAlignment( Alignment.east );
	m_pGameName.SetText( "Source SDK Base 2013 Singleplayer" ); // "%gamename%"
	m_pGameName.SetFont( surface.GetFont( "SteamScheme.topbar", false ) );

	//m_pPowerMeterDim = vgui.CreatePanel( "ImagePanel", m_pManager, "PowerMeterDim" );
	//m_pPowerMeterDim.SetImage( "steam/resource/battery_dim", true );
	//m_pPowerMeterBright = vgui.CreatePanel( "ImagePanel", m_pManager, "PowerMeterBright" );
	//m_pPowerMeterBright.SetImage( "steam/resource/battery_bright", true );

	m_pCloseButton = vgui.CreatePanel( "Button", m_pManager, "CloseButton" );
	m_pCloseButton.SetTextInset( 0, 0 );
	m_pCloseButton.SetContentAlignment( Alignment.north );
	m_pCloseButton.SetPaintBackgroundEnabled( false );
	m_pCloseButton.SetPaintBorderEnabled( false );
	m_pCloseButton.SetCallback( "DoClick", function()
	{
		SteamGameOverlay.TurnOffGameOverlay();
	} );
	m_pCloseButton.SetCursor( CursorCode.dc_hand );
	m_pCloseButton.SetText( "Click here to return to the game" ); // "#Overlay_Taskbar_Close"
	m_pCloseButton.SetFont( surface.GetFont( "SteamScheme.OverlayURLLabel", false ) );

	m_pHotkeyLabel = vgui.CreatePanel( "Label", m_pManager, "HotkeyLabel" );
	m_pHotkeyLabel.SetContentAlignment( Alignment.north );
	m_pHotkeyLabel.SetText( m_szHotkey.toupper() + "  also closes the overlay" );
	m_pHotkeyLabel.SetFont( surface.GetFont( "SteamScheme.FriendsSmall", false ) );

	//m_pHotkeyExplain = vgui.CreatePanel( "Label", m_pManager, "HotkeyExplain" );
	//m_pHotkeyExplain.SetContentAlignment( Alignment.north );
	//m_pHotkeyExplain.SetText( "#Overlay_Hotkey_Explain" );
	//m_pHotkeyExplain.SetFont( surface.GetFont( "SteamScheme.FriendsSmall", false ) );

	//
	// Taskbar
	//
	m_pSteamLogo = vgui.CreatePanel( "ImagePanel", m_pManager, "SteamLogo" );
	m_pSteamLogo.SetZPos( 1 );
	m_pSteamLogo.SetImage( "steam/resource/steam_logo_big", true );
	m_pSteamLogo.SetShouldScaleImage( true );

	m_pWebBrowserButton = vgui.CreatePanel( "Button", m_pManager, "WebBrowserButton" );
	m_pWebBrowserButton.SetPaintBackgroundEnabled( false );
	m_pWebBrowserButton.SetPaintBorderEnabled( false );
	m_pWebBrowserButton.SetTextInset( 0, 0 );
	m_pWebBrowserButton.SetCursor( CursorCode.dc_hand );
	m_pWebBrowserButton.SetText( "WEB BROWSER" ); // "#Overlay_Taskbar_WebBrowser"
	m_pWebBrowserButton.SetFont( surface.GetFont( "SteamScheme.taskbar", false ) );

	m_pMusicPlayerButton = vgui.CreatePanel( "Button", m_pManager, "MusicPlayerButton" );
	m_pMusicPlayerButton.SetPaintBackgroundEnabled( false );
	m_pMusicPlayerButton.SetPaintBorderEnabled( false );
	m_pMusicPlayerButton.SetTextInset( 0, 0 );
	m_pMusicPlayerButton.SetCursor( CursorCode.dc_hand );
	m_pMusicPlayerButton.SetText( "MUSIC" ); // "#Overlay_Taskbar_Music"
	m_pMusicPlayerButton.SetFont( surface.GetFont( "SteamScheme.taskbar", false ) );

	m_pSettingsButton = vgui.CreatePanel( "Button", m_pManager, "SettingsButton" );
	m_pSettingsButton.SetPaintBackgroundEnabled( false );
	m_pSettingsButton.SetPaintBorderEnabled( false );
	m_pSettingsButton.SetTextInset( 0, 0 );
	m_pSettingsButton.SetCursor( CursorCode.dc_hand );
	m_pSettingsButton.SetText( "SETTINGS" ); // "#Overlay_Taskbar_Settings"
	m_pSettingsButton.SetFont( surface.GetFont( "SteamScheme.taskbar", false ) );

	m_pViewFriends = vgui.CreatePanel( "Button", m_pManager, "view_friends" );
	m_pViewFriends.SetPaintBackgroundEnabled( false );
	m_pViewFriends.SetPaintBorderEnabled( false );
	m_pViewFriends.SetTextInset( 0, 0 );
	m_pViewFriends.SetCursor( CursorCode.dc_hand );
	m_pViewFriends.SetContentAlignment( Alignment.west );
	m_pViewFriends.SetText( "View Friends" ); // "#Steam_ViewFriends"
	m_pViewFriends.SetFont( surface.GetFont( "SteamScheme.taskbar", false ) );

	//
	// Clock
	//
	m_pClock = vgui.CreatePanel( "Label", m_pManager, "Clock" );
	m_pClock.SetContentAlignment( Alignment.west );
	m_pClock.SetFont( surface.GetFont( "SteamScheme.topbar", false ) );

	m_pSessionText = vgui.CreatePanel( "Label", m_pManager, "Clock" ); // "#Overlay_Playtime_Session"
	m_pSessionText.SetFont( surface.GetFont( "SteamScheme.TimeStrings", false ) );

	//m_pTwoWeeksText = vgui.CreatePanel( "Label", m_pManager, "TwoWeeksText" );
	//m_pTwoWeeksText.SetText( Fmt("%d minutes - past two weeks", (time()-m_nInitTime)/60)) );
	//m_pTwoWeeksText.SetFont( surface.GetFont( "SteamScheme.TimeStrings", false ) );

	//m_pForeverText = vgui.CreatePanel( "Label", m_pManager, "ForeverText" );
	//m_pForeverText.SetText( Fmt("0 hours - total") );
	//m_pForeverText.SetFont( surface.GetFont( "SteamScheme.TimeStrings", false ) );

	SetClock(null);

	m_pForceQuitButton = vgui.CreatePanel( "Button", m_pManager, "ForceQuitButton" );
	m_pForceQuitButton.SetTextInset( 0, 0 );
	m_pForceQuitButton.SetContentAlignment( Alignment.east );
	m_pForceQuitButton.SetPaintBackgroundEnabled( false );
	m_pForceQuitButton.SetPaintBorderEnabled( false );
	m_pForceQuitButton.SetCallback( "DoClick", function()
	{
		SteamGameOverlay.TurnOffGameOverlay();
	} );
	m_pForceQuitButton.SetCursor( CursorCode.dc_hand );
	m_pForceQuitButton.SetText( "Force quit" ); // "#Overlay_Taskbar_ForceQuit"
	m_pForceQuitButton.SetFont( surface.GetFont( "SteamScheme.OverlayURLLabel", false ) );
}

function SteamGameOverlay::PerformLayout()
{
	// overlaydashboard.layout
	local screen_width = ScreenWidth();
	local overlay_width = 1010;
	local overlay_height = ScreenHeight();
	local wide = 400;

	if ( screen_width < 1024 )
	{
		overlay_width = screen_width - 10;
		wide = (overlay_width / 2.5).tointeger();
	}

	local margin_x = (screen_width - overlay_width) / 2;
	local margin_top = 10;

	local col = SteamScheme["Text"];

	m_pCloseButton.SetDefaultColor( col[0], col[1], col[2], col[3], 0, 0, 0, 0 );
	m_pCloseButton.SetSelectedColor( 255, 255, 255, 255, 0, 0, 0, 0 );
	m_pCloseButton.SetSize( wide, overlay_height );
	m_pCloseButton.SetPos( (screen_width - wide) / 2, margin_top+2 );

	m_pGameName.SetFgColor( col[0], col[1], col[2], col[3] );
	m_pGameName.SetSize( wide, 40 );
	m_pGameName.SetPos( screen_width - margin_x - wide, margin_top );

	//m_pPowerMeterDim.SetSize( 200, 110 );
	//m_pPowerMeterDim.SetPos( screen_width - margin_x - 200, margin_top );
	//m_pPowerMeterBright.SetSize( 200, 110 );
	//m_pPowerMeterBright.SetPos( screen_width - margin_x - 200, margin_top );

	m_pHotkeyLabel.SetFgColor( col[0], col[1], col[2], col[3] );
	m_pHotkeyLabel.SetSize( wide, overlay_height );
	m_pHotkeyLabel.SetPos( (screen_width - wide) / 2, margin_top + 14 );

	//
	// Taskbar
	//
	col = SteamScheme["Label"];
	local col2 = SteamScheme["Label2"];

	local y = overlay_height - 64;

	m_pSteamLogo.SetPos( margin_x, y - 18 );
	m_pSteamLogo.SetSize( 200, 52 );

	m_pWebBrowserButton.SetDefaultColor( col[0], col[1], col[2], col[3], 0, 0, 0, 0 );
	m_pWebBrowserButton.SetSelectedColor( col2[0], col2[1], col2[2], col2[3], 0, 0, 0, 0 );
	m_pWebBrowserButton.SetPos( margin_x + 225, y - margin_top );
	m_pWebBrowserButton.SetSize( surface.GetTextWidth( surface.GetFont( "SteamScheme.taskbar", false ), "WEB BROWSER" ), 32 );

	m_pMusicPlayerButton.SetDefaultColor( col[0], col[1], col[2], col[3], 0, 0, 0, 0 );
	m_pMusicPlayerButton.SetSelectedColor( col2[0], col2[1], col2[2], col2[3], 0, 0, 0, 0 );
	m_pMusicPlayerButton.SetPos( m_pWebBrowserButton.GetXPos() + m_pWebBrowserButton.GetWide() + 30, y - margin_top );
	m_pMusicPlayerButton.SetSize( surface.GetTextWidth( surface.GetFont( "SteamScheme.taskbar", false ), "MUSIC" ), 32 );

	m_pSettingsButton.SetDefaultColor( col[0], col[1], col[2], col[3], 0, 0, 0, 0 );
	m_pSettingsButton.SetSelectedColor( col2[0], col2[1], col2[2], col2[3], 0, 0, 0, 0 );
	m_pSettingsButton.SetPos( m_pMusicPlayerButton.GetXPos() + m_pMusicPlayerButton.GetWide() + 30, y - margin_top );
	m_pSettingsButton.SetSize( surface.GetTextWidth( surface.GetFont( "SteamScheme.taskbar", false ), "SETTINGS" ), 32 );

	m_pViewFriends.SetDefaultColor( col[0], col[1], col[2], col[3], 0, 0, 0, 0 );
	m_pViewFriends.SetSelectedColor( col2[0], col2[1], col2[2], col2[3], 0, 0, 0, 0 );
	m_pViewFriends.SetPos( screen_width - margin_x - 16 - 96, y - margin_top );
	m_pViewFriends.SetSize( 96, 84 );

	//
	// Clock
	//
	col = SteamScheme["Text"];

	m_pClock.SetFgColor( col[0], col[1], col[2], col[3] );
	m_pClock.SetPos( margin_x, margin_top );
	m_pClock.SetSize( wide, surface.GetFontTall( surface.GetFont( "SteamScheme.topbar", false ) ) );

	local tall = surface.GetFontTall( surface.GetFont( "SteamScheme.TimeStrings", false ) );
	m_pSessionText.SetFgColor( col[0], col[1], col[2], col[3] );
	m_pSessionText.SetPos( margin_x, m_pClock.GetYPos() + m_pClock.GetTall() );
	m_pSessionText.SetSize( wide, tall );

	//m_pTwoWeeksText.SetFgColor( col[0], col[1], col[2], col[3] );
	//m_pTwoWeeksText.SetPos( margin_x, m_pSessionText.GetYPos() + m_pSessionText.GetTall() );
	//m_pTwoWeeksText.SetSize( wide, tall );

	//m_pForeverText.SetFgColor( col[0], col[1], col[2], col[3] );
	//m_pForeverText.SetPos( margin_x, m_pTwoWeeksText.GetYPos() + m_pTwoWeeksText.GetTall() );
	//m_pForeverText.SetSize( wide, tall );

	m_pForceQuitButton.SetFgColor( col[0], col[1], col[2], col[3] );
	m_pForceQuitButton.SizeToContents();
	m_pForceQuitButton.SetPos( screen_width - margin_x - m_pForceQuitButton.GetWide(), 50 );
}

function SteamGameOverlay::PaintBackground()
{
	local wmax = ScreenWidth();
	local hmax = ScreenHeight();

	// overlaymain
	surface.SetColor( 43, 43, 43, 96 );
	surface.DrawFilledRect( 0, 0, wmax, hmax );

	// TopFadePanel - topfade
	surface.SetColor( 38, 37, 35, 140 );
	surface.DrawFilledRectFade( 0, 0, wmax, 600, 255, 0, false );

	// BottomFadePanel - bottomfade
	surface.SetColor( 0, 0, 0, 255 );
	surface.DrawFilledRectFade( 0, hmax - 130, wmax, 130, 0, 255, false );
}

function SteamGameOverlay::TurnOffGameOverlay()
{
	m_pManager.SetMouseInputEnabled( false );

	m_flFadeStart = clock();
	Entities.First().SetContextThink( "SteamGameOverlay.Fade", FadeOut.bindenv(this), 0.0 );
	Entities.First().SetContextThink( "SteamGameOverlay.Clock", null, 0.0 );
}

function SteamGameOverlay::ActivateGameOverlay( szContext = "" )
{
	CreateOverlayPanels();

	m_pManager.MakePopup();
	m_pManager.SetVisible( true );
	m_pManager.SetMouseInputEnabled( true );
	m_pManager.SetPaintBackgroundEnabled( true );
	m_pManager.SetCallback( "PaintBackground", PaintBackground.bindenv(this) );
	m_pManager.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );

	m_flFadeStart = clock();
	Entities.First().SetContextThink( "SteamGameOverlay.Fade", FadeIn.bindenv(this), 0.0 );
	Entities.First().SetContextThink( "SteamGameOverlay.Clock", SetClock.bindenv(this), 0.0 );
}

function SteamGameOverlay::FadeIn(_)
{
	local t = (clock() - m_flFadeStart) / 0.25;
	if ( t < 1.0 )
	{
		m_pManager.SetAlpha( t * 255.0 );
		return 0.0;
	}

	m_pManager.SetAlpha( 255 );

	return -1;
}

function SteamGameOverlay::FadeOut(_)
{
	local t = (clock() - m_flFadeStart) / 0.25;
	if ( t < 1.0 )
	{
		m_pManager.SetAlpha( (1.0 - t) * 255.0 );
		return 0.0;
	}

	m_pManager.SetAlpha( 0 );
	m_pManager.SetVisible( false );
	m_pManager.SetPaintBackgroundEnabled( false );
	m_pManager.SetCallback( "PaintBackground", null );
	m_pManager.SetCallback( "PerformLayout", null );

	return -1;
}

function SteamGameOverlay::SetClock(_)
{
	local l = date();
	m_pClock.SetText( Fmt( "%d:%02d:%02d", l.hour, l.min, l.sec ) );

	m_pSessionText.SetText( Fmt("%d minutes - current session", (time()-m_nInitTime)/60) );

	return 1.0;
}
*/
//
// TODO: Fix stack offsets, panel lag
//
function SteamNotificationManager::OnTick()
{
/*
	if ( !m_bHotkeyDown && input.IsButtonDown( m_HotkeyAccel ) && input.IsButtonDown( m_Hotkey ) )
	{
		m_bHotkeyDown = true;
		Entities.First().SetContextThink( "SteamGameOverlay", function(_) { m_bHotkeyDown = false; }.bindenv(this), 1.0 );

		if ( m_pManager.IsVisible() )
		{
			TurnOffGameOverlay();
		}
		else
		{
			ActivateGameOverlay();
		}
	}
*/
	if ( !(0 in m_Stack) )
		return;

	if ( 2 in m_Stack )
	{
		local prevPanel = m_Stack[1].self;
		local curPanel = m_Stack[2];

		local anchorY = prevPanel.GetYPos();
		curPanel.m_StartYPos = anchorY;

		switch ( g_SteamNotificationPosition )
		{
			case SteamNotificationPosition.BottomRight:
			case SteamNotificationPosition.BottomLeft:
				curPanel.m_EndYPos = anchorY - curPanel.m_tall;
				break;

			case SteamNotificationPosition.TopRight:
			case SteamNotificationPosition.TopLeft:
				curPanel.m_EndYPos = anchorY + curPanel.m_tall;
				break;
		}

		if ( Con_IsVisible() )
			curPanel.self.MoveToFront();
	}

	if ( 1 in m_Stack )
	{
		local prevPanel = m_Stack[0].self;
		local curPanel = m_Stack[1];

		local anchorY = prevPanel.GetYPos();
		curPanel.m_StartYPos = anchorY;

		switch ( g_SteamNotificationPosition )
		{
			case SteamNotificationPosition.BottomRight:
			case SteamNotificationPosition.BottomLeft:
				curPanel.m_EndYPos = anchorY - curPanel.m_tall;
				break;

			case SteamNotificationPosition.TopRight:
			case SteamNotificationPosition.TopLeft:
				curPanel.m_EndYPos = anchorY + curPanel.m_tall;
				break;
		}

		if ( Con_IsVisible() )
			curPanel.self.MoveToFront();
	}

	if ( 0 in m_Stack )
	{
		local curPanel = m_Stack[0];
		if ( Con_IsVisible() )
			curPanel.self.MoveToFront();

		local t = clock();
		foreach ( p in m_Stack )
			p.OnTick( t );
	}
}

function SteamNotificationManager::AddNotification( pNotification )
{
	if ( m_Stack.len() < 3 )
	{
		m_Stack.insert( 0, pNotification );
		pNotification.Display();
		// Put it one behind other notifications
		pNotification.self.SetZPos( -m_Stack.len() );
	}
	else
	{
		m_Queue.append( pNotification );
	}
}

function SteamNotificationManager::RemoveNotification( pNotification )
{
	local i = m_Stack.find( pNotification );
	if ( i != null )
	{
		m_Stack.remove( i ).self.Destroy();
	}

	while ( m_Queue.len() && m_Stack.len() < 3 )
	{
		local p = m_Queue.remove(0);
		m_Stack.insert( 0, p );
		p.Display();
		// Put it one behind other notifications
		p.self.SetZPos( -m_Stack.len() );
	}
}
