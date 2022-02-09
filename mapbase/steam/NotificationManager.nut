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
//		SteamNotificationManager::SetHotkey( enum ButtonCode keyAccelerator, enum ButtonCode key )
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

	m_HotkeyAccel = null
	m_Hotkey = null
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

			self.MakePopup();
			self.SetMouseInputEnabled( false );
			self.SetKeyBoardInputEnabled( false );
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

	if ( m_pManager && m_pManager.IsValid() )
		return;

	m_Stack = [];
	m_Queue = [];

	SetHotkey( ButtonCode.KEY_LSHIFT, ButtonCode.KEY_TAB );

	m_pManager = vgui.CreatePanel( "Panel", vgui.GetRootPanel(), "SteamNotifications" );
	m_pManager.SetVisible( false );
	m_pManager.SetPaintEnabled( false );
	m_pManager.SetPaintBackgroundEnabled( false );
	m_pManager.SetCallback( "OnTick", OnTick.bindenv(this) );
	m_pManager.AddTickSignal( 0 );

	NetMsg.Receive( "SteamNotificationPosition", function()
	{
		return SetSteamNotificationPosition( NetMsg.ReadByte() );
	} );

	CSteamFriendNotification.Init();
}

function SteamNotificationManager::SetHotkey( keyAccel, key )
{
	m_HotkeyAccel = keyAccel;
	m_Hotkey = key;

	keyAccel = input.ButtonCodeToString( keyAccel ).tolower();
	keyAccel = keyAccel[0].tochar().toupper() + keyAccel.slice(1);

	key = input.ButtonCodeToString( key ).tolower();
	key = key[0].tochar().toupper() + key.slice(1);

	m_szHotkey = Fmt( "%s+%s", keyAccel, key );
}

//
// TODO: Fix stack offsets, panel lag
//
function SteamNotificationManager::OnTick()
{
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

	// TODO:
	//if ( m_fnHotkeyCallback && input.IsButtonDown( m_HotkeyAccel ) && input.IsButtonDown( m_Hotkey ) )
	//	m_fnHotkeyCallback();
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
