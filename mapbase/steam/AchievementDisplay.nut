//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// 'display_achievements'
//
// Display all loaded achievements conveniently.
// Achievements are ordered randomly.
// Used for debugging purposes.
//

local surface = surface, clock = clock;

SteamAchievementsDisplay <-
{
	m_pMainFrame = null
	m_pEmbedded = null
	m_pClose = null
	m_pTitle = null
	m_pTopGrip = null
	m_pClipper = null
	m_pLabel = null

	m_vert = 0
	m_vertCur = 0
	m_flScrollStart = 0.0
	m_bDragging = false
	m_nDragX = 0
	m_nDragY = 0
	m_bTopFade = false
	m_bBottomFade = false
	m_bDisplayID = false

	m_SortedPanels = null
}

function SteamAchievementsDisplay::Init()
{
	CreatePanelClass();

	Convars.RegisterCommand( "display_achievements", function(_)
	{
		Hooks.Add( this, "SteamAchievements.UserStatsReceived", UserStatsReceived, "SteamAchievementsDisplay" );
		SteamAchievementsDisplay.CreatePanels();
		SteamAchievements.RequestCurrentStats();
	}.bindenv(this), "", FCVAR_CLIENTDLL );
}

function SteamAchievementsDisplay::Close()
{
	m_pMainFrame.Destroy();
	m_SortedPanels.clear();
}

function SteamAchievementsDisplay::CreatePanels()
{
	if ( m_pMainFrame && m_pMainFrame.IsValid() )
		m_pMainFrame.Destroy();

	m_pMainFrame = vgui.CreatePanel( "Panel", vgui.GetRootPanel(), "Achievements" );
	m_pMainFrame.MakePopup();
	m_pMainFrame.SetVisible( true );
	m_pMainFrame.SetMouseInputEnabled( true );
	m_pMainFrame.SetKeyBoardInputEnabled( true );
	m_pMainFrame.SetPaintEnabled( false );
	m_pMainFrame.SetPaintBackgroundEnabled( true );
	m_pMainFrame.SetCallback( "PerformLayout", PerformLayout.bindenv(this) );
	m_pMainFrame.SetCallback( "OnMouseWheeled", OnMouseWheeled.bindenv(this) );
	m_pMainFrame.SetCallback( "OnKeyCodeTyped", OnKeyCodeTyped.bindenv(this) );

	m_pClose = vgui.CreatePanel( "Button", m_pMainFrame, "close" );
	m_pClose.SetVisible( true );
	m_pClose.SetPaintEnabled( true );
	m_pClose.SetPaintBackgroundEnabled( false );
	m_pClose.SetPaintBorderEnabled( false );
	m_pClose.SetFont( surface.GetFont( "Marlett", false, "Tracker" ) );
	m_pClose.SetText( "r" );
	m_pClose.SetTextInset( 1, 0 );
	m_pClose.SetContentAlignment( Alignment.northwest );
	m_pClose.SetCallback( "DoClick", Close.bindenv(this) );

	m_pTitle = vgui.CreatePanel( "Label", m_pMainFrame, "title" );
	m_pTitle.SetVisible( true );
	m_pTitle.SetPaintEnabled( true );
	m_pTitle.SetPaintBackgroundEnabled( false );
	m_pTitle.SetFont( surface.GetFont( "DefaultSmall", false, "Tracker" ) );
	m_pTitle.SetText( "Achievements" );

	m_pTopGrip = vgui.CreatePanel( "Panel", m_pMainFrame, "topgrip" );
	m_pTopGrip.SetVisible( true );
	m_pTopGrip.SetPaintEnabled( false );
	m_pTopGrip.SetPaintBackgroundEnabled( false );
	// m_pTopGrip.SetCursor( CursorCode.dc_sizeall );
	m_pTopGrip.AddTickSignal( 0 );
	m_pTopGrip.SetCallback( "OnTick", TopGripOnTick.bindenv(this) );
	m_pTopGrip.SetCallback( "OnMousePressed", TopGripOnPressed.bindenv(this) );

	// Instead of manually setting the size of the embedded panel, let the system clip it with another panel
	m_pClipper = vgui.CreatePanel( "Panel", m_pMainFrame, "listview" );
	m_pClipper.SetVisible( true );
	m_pClipper.SetPaintEnabled( false );
	m_pClipper.SetPaintBackgroundEnabled( false );
	m_pClipper.SetPostChildPaintEnabled( true );
	m_pClipper.SetMouseInputEnabled( false );
	m_pClipper.SetCallback( "PostChildPaint", PaintListBoundsFade.bindenv(this) );

	m_pEmbedded = vgui.CreatePanel( "Panel", m_pClipper, "panellist" );
	m_pEmbedded.SetVisible( true );
	m_pEmbedded.SetPaintEnabled( false );
	m_pEmbedded.SetPaintBackgroundEnabled( false );
	m_pEmbedded.AddTickSignal( 0 );
	m_pEmbedded.SetCallback( "OnMouseWheeled", OnMouseWheeled.bindenv(this) );
	m_pEmbedded.SetCallback( "OnKeyCodeTyped", OnKeyCodeTyped.bindenv(this) );
	m_pEmbedded.SetCallback( "OnTick", SmoothScroll.bindenv(this) );

	if ( m_SortedPanels )
	{
		foreach( panel in m_SortedPanels )
			if ( panel.m_base.IsValid() )
				panel.m_base.Destroy();
		m_SortedPanels.clear();
	}
	else
	{
		m_SortedPanels = [];
	}

	if ( SteamAchievements.m_Achievements.len() )
	{
		foreach ( achName, ach in SteamAchievements.m_Achievements )
		{
			m_SortedPanels.append( CAchievementPanel( m_pEmbedded, ach ) );
		}
	}
	else
	{
		m_pLabel = vgui.CreatePanel( "Label", m_pClipper, "" );
		m_pLabel.SetVisible( true );
		m_pLabel.SetPaintEnabled( true );
		m_pLabel.SetPaintBackgroundEnabled( false );
		m_pLabel.SetFont( surface.GetFont( "DefaultSmall", false, "Tracker" ) );
		m_pLabel.SetText( "empty..." );
		m_pLabel.SetContentAlignment( Alignment.center );
	}
}

function SteamAchievementsDisplay::CreatePanelClass()
{
	class CAchievementPanel
	{
		m_achievement = null;
		m_bAchieved = null;
		m_base = null;
		m_icon = null;
		m_textHolder = null;
		m_name = null;
		m_desc = null;
		m_unlockDate = null;
		m_progressBarBG = null;
		m_progressBar = null;
		m_progressLabel = null;

		constructor( pParent, ach )
		{
			local h5 = surface.GetFont( "SteamScheme.FriendsSmall", false );
			local h3 = surface.GetFont( "AchievementItemTitleLarge", false, "Tracker" );

			m_achievement = ach;
			m_bAchieved = SteamAchievements.GetAchievement( ach.m_rgchAchievementID );

			m_base = vgui.CreatePanel( "Panel", pParent, "" );
			m_base.SetVisible( true );
			m_base.SetPaintEnabled( false );
			m_base.SetPaintBackgroundEnabled( false );

			m_icon = vgui.CreatePanel( "ImagePanel", m_base, "icon" );
			m_icon.SetVisible( true );
			m_icon.SetPaintEnabled( true );
			m_icon.SetPaintBackgroundEnabled( true );
			m_icon.SetShouldScaleImage( true );

			m_textHolder = vgui.CreatePanel( "Panel", m_base, "textHolder" );
			m_textHolder.SetVisible( true );
			m_textHolder.SetPaintEnabled( false );
			m_textHolder.SetPaintBackgroundEnabled( true );

			m_name = vgui.CreatePanel( "Label", m_textHolder, "name" );
			m_name.SetVisible( true );
			m_name.SetPaintEnabled( true );
			m_name.SetPaintBackgroundEnabled( false );
			m_name.SetFont( h3 );
			m_name.SetText( ach.m_rgchName );

			m_desc = vgui.CreatePanel( "Label", m_textHolder, "desc" );
			m_desc.SetVisible( true );
			m_desc.SetPaintEnabled( true );
			m_desc.SetPaintBackgroundEnabled( false );
			m_desc.SetFont( h5 );
			m_desc.SetText( ach.m_rgchDescription );

			if ( m_bAchieved )
			{
				m_unlockDate = vgui.CreatePanel( "Label", m_textHolder, "unlockdate" );
				m_unlockDate.SetVisible( true );
				m_unlockDate.SetPaintEnabled( true );
				m_unlockDate.SetPaintBackgroundEnabled( false );
				m_unlockDate.SetFont( h5 );
				m_unlockDate.SetContentAlignment( Alignment.east );
			}
			else if ( ach.m_nMaxProgress )
			{
				m_progressBarBG = vgui.CreatePanel( "Panel", m_textHolder, "progress_bar_bg" );
				m_progressBarBG.SetVisible( true );
				m_progressBarBG.SetPaintEnabled( false );
				m_progressBarBG.SetPaintBackgroundEnabled( true );
				m_progressBarBG.SetPaintBackgroundType( 0 );

				m_progressBar = vgui.CreatePanel( "Panel", m_textHolder, "progress_bar_fg" );
				m_progressBar.SetVisible( true );
				m_progressBar.SetPaintEnabled( false );
				m_progressBar.SetPaintBackgroundEnabled( true );
				m_progressBar.SetPaintBackgroundType( 0 );

				m_progressLabel = vgui.CreatePanel( "Label", m_textHolder, "progress_label" );
				m_progressLabel.SetVisible( true );
				m_progressLabel.SetPaintEnabled( true );
				m_progressLabel.SetPaintBackgroundEnabled( false );
				m_progressLabel.SetFont( h5 );
			}
		}

		function Update()
		{
			local pParent = m_base.GetParent();
			m_base.Destroy();
			constructor( pParent, m_achievement );
			m_base.MakeReadyForUse();
		}
	}
}

function SteamAchievementsDisplay::TopGripOnTick()
{
	if ( m_bDragging )
	{
		if ( input.IsButtonDown( ButtonCode.MOUSE_LEFT ) )
		{
			local x = input.GetAnalogValue( AnalogCode.MOUSE_X );
			local y = input.GetAnalogValue( AnalogCode.MOUSE_Y );
			m_pMainFrame.SetPos( x+m_nDragX, y+m_nDragY );
		}
		else
		{
			m_bDragging = false;
		}
	}
}

function SteamAchievementsDisplay::TopGripOnPressed( code )
{
	if ( code == ButtonCode.MOUSE_LEFT )
	{
		m_bDragging = true;
		local x = input.GetAnalogValue( AnalogCode.MOUSE_X );
		local y = input.GetAnalogValue( AnalogCode.MOUSE_Y );
		m_nDragX = m_pMainFrame.GetXPos() - x;
		m_nDragY = m_pMainFrame.GetYPos() - y;
	}
}

function SteamAchievementsDisplay::PaintListBoundsFade()
{
	if ( m_bTopFade )
	{
		surface.SetColor( 0x1e, 0x1e, 0x1e, 0xff );
		surface.DrawFilledRectFade( 0, 0, m_pClipper.GetWide(), 16, 0xff, 0x00, false );
	}

	if ( m_bBottomFade )
	{
		surface.SetColor( 0x1e, 0x1e, 0x1e, 0xff );
		surface.DrawFilledRectFade( 0, m_pClipper.GetTall() - 16, m_pClipper.GetWide(), 16, 0x00, 0xff, false );
	}
}

function SteamAchievementsDisplay::UserStatsReceived()
{
	if ( m_SortedPanels )
	{
		foreach ( panel in m_SortedPanels )
			panel.Update();
		return PerformLayoutList();
	}
}

function SteamAchievementsDisplay::PerformLayout()
{
	m_pMainFrame.SetPaintBackgroundType( 2 );
	m_pMainFrame.SetSize( 747 + 64 + 9 + 36, 18 + 16 + 66 * 6 );
	m_pMainFrame.SetPos( (ScreenWidth() - m_pMainFrame.GetWide())/2,  (ScreenHeight() - m_pMainFrame.GetTall())/2 );
	m_pMainFrame.SetBgColor( 0x1e, 0x1e, 0x1e, 0xff );

	m_pTopGrip.SetPos( 0, 0 );
	m_pTopGrip.SetSize( m_pMainFrame.GetWide() - 16 - 8, 24 );

	m_pTitle.SetPos( 16, 8 );
	m_pTitle.SizeToContents();
	m_pTitle.SetTall( 16 );

	m_pClose.SetSize( 16, 16 );
	m_pClose.SetPos( m_pMainFrame.GetWide() - 16 - 8, 8 );

	m_pClipper.SetPos( 18, 32 );
	m_pClipper.SetSize( 747 + 64 + 9, m_pMainFrame.GetTall() - m_pClipper.GetYPos() - 16 );

	m_pEmbedded.SetPos( 0, 0 );
	m_pEmbedded.SetSize( m_pClipper.GetWide(), 0 );

	// TODO: scrollbar
	//m_pScrollBar.SetBgColor( 0x89, 0x89, 0x89, 0xff );
	//m_pScrollBar.SetPos( m_pClipper.GetXPos() + m_pClipper.GetWide() + 2, m_pClipper.GetYPos() );

	if ( m_pLabel && m_pLabel.IsValid() )
	{
		m_pLabel.SetPos( 0, 16 );
		m_pLabel.SetSize( m_pClipper.GetWide(), 32 );
	}

	return PerformLayoutList();
}

function SteamAchievementsDisplay::PerformLayoutList()
{
	m_SortedPanels.sort( __SortAchievements );

	local achieved = 0;
	local listHeight = 0;
	local ypos = 0;

	foreach ( panel in m_SortedPanels )
	{
		local ach = panel.m_achievement;

		panel.m_base.SetPos( 0, ypos );
		panel.m_base.SetSize( m_pEmbedded.GetWide(), 66 );

		panel.m_icon.SetImage( panel.m_bAchieved ? ach.m_szIconImageAchieved : ach.m_szIconImageUnachieved, true );
		panel.m_icon.SetPos( 0, 1 );
		panel.m_icon.SetSize( 64, 64 );

		panel.m_textHolder.SetPos( panel.m_icon.GetXPos() + 64 + 9, 0 );
		panel.m_textHolder.SetSize( 747, 66 );
		panel.m_textHolder.SetBgColor( 0x38, 0x38, 0x38, 0xff );
		panel.m_textHolder.SetPaintBackgroundType( 2 );

		panel.m_name.SetPos( 6, (ach.m_nMaxProgress && !panel.m_bAchieved) ? 6 : 17 );
		panel.m_desc.SetPos( panel.m_name.GetXPos(), panel.m_name.GetYPos() + 19 );

		panel.m_name.SetSize( 730, 18 );
		panel.m_name.SetFgColor( 0xff, 0xff, 0xff, 0xff );

		panel.m_desc.SetSize( panel.m_name.GetWide(), panel.m_name.GetTall() );
		panel.m_desc.SetFgColor( 0x89, 0x89, 0x89, 0xff );

		if ( panel.m_bAchieved )
		{
			++achieved;

			panel.m_unlockDate.SetText( SteamAchievements.GetAchievementUnlockDateString( ach.m_rgchAchievementID, true, false ) );
			panel.m_unlockDate.SetPos( panel.m_name.GetXPos(), panel.m_name.GetYPos() );
			panel.m_unlockDate.SetSize( panel.m_name.GetWide(), panel.m_name.GetTall() );
			panel.m_unlockDate.SetFgColor( 0x89, 0x89, 0x89, 0xff );
		}
		else if ( ach.m_nMaxProgress )
		{
			panel.m_progressBarBG.SetBgColor( 0x30, 0x30, 0x2f, 0xff );
			panel.m_progressBarBG.SetPos( panel.m_desc.GetXPos(), panel.m_desc.GetYPos() + panel.m_desc.GetTall() + 2 );

			panel.m_progressBar.SetBgColor( 0x8d, 0xb3, 0x52, 0xff );
			panel.m_progressBar.SetPos( panel.m_progressBarBG.GetXPos(), panel.m_progressBarBG.GetYPos() );

			local progress = ach.m_nCurProgress.tofloat() / ach.m_nMaxProgress.tofloat();
			panel.m_progressBarBG.SetSize( 500, 14 );
			panel.m_progressBar.SetSize( 500 * progress, 14 );

			panel.m_progressLabel.SetText( format( "%d / %d" , ach.m_nCurProgress, ach.m_nMaxProgress ) );
			panel.m_progressLabel.SetFgColor( 0x89, 0x89, 0x89, 0xff );
			panel.m_progressLabel.SetPos( panel.m_progressBarBG.GetXPos() + panel.m_progressBarBG.GetWide() + 12, panel.m_progressBarBG.GetYPos() );
			panel.m_progressLabel.SetSize( 220, 14 );
		}

		ypos += 66 + 4; // + 4 buffer
		listHeight += 66 + 4;
	}

	m_pEmbedded.SetTall( listHeight );

	local count = m_SortedPanels.len();
	if ( count )
		m_pTitle.SetText( format( "Achievements (%d / %d)", achieved, m_SortedPanels.len() ) );

	return OnMouseWheeled( 0 );
}

function SteamAchievementsDisplay::OnMouseWheeled( delta )
{
	local diff = m_pEmbedded.GetTall() - m_pClipper.GetTall();
	if ( diff <= 0 )
		return;

	m_vert -= delta * 35;

	if ( m_vert <= 0 )
	{
		m_vert = 0;
		m_bTopFade = false;
		m_bBottomFade = true;
	}
	else if ( m_vert >= diff )
	{
		m_vert = diff;
		m_bTopFade = true;
		m_bBottomFade = false;
	}
	else
	{
		m_bTopFade = true;
		m_bBottomFade = true;
	}

	m_vertCur = m_pEmbedded.GetYPos();
	m_flScrollStart = clock();
}

function SteamAchievementsDisplay::OnKeyCodeTyped( code )
{
	switch ( code )
	{
		case ButtonCode.KEY_ESCAPE:
			return Close();

		case ButtonCode.KEY_TAB:

			m_bDisplayID = !m_bDisplayID;

			foreach ( panel in m_SortedPanels )
			{
				if ( m_bDisplayID )
				{
					panel.m_name.SetText( panel.m_achievement.m_rgchAchievementID );

					if ( panel.m_unlockDate )
						panel.m_unlockDate.SetText( SteamAchievements.GetAchievementUnlockDateString( panel.m_achievement.m_rgchAchievementID, true, true ) );
				}
				else
				{
					panel.m_name.SetText( panel.m_achievement.m_rgchName );

					if ( panel.m_unlockDate )
						panel.m_unlockDate.SetText( SteamAchievements.GetAchievementUnlockDateString( panel.m_achievement.m_rgchAchievementID, true, false ) );
				}
			}
			return;
	}

	local diff = m_pEmbedded.GetTall() - m_pClipper.GetTall();
	if ( diff <= 0 )
		return;

	switch ( code )
	{
		case ButtonCode.KEY_UP:
			m_vert -= 24;
			break;
		case ButtonCode.KEY_DOWN:
			m_vert += 24;
			break;
		case ButtonCode.KEY_PAGEUP:
			m_vert -= 66 * 5;
			break;
		case ButtonCode.KEY_PAGEDOWN:
			m_vert += 66 * 5;
			break;
		case ButtonCode.KEY_HOME:
			m_vert = 0;
			break;
		case ButtonCode.KEY_END:
			m_vert = diff;
			break;
		default: return;
	}

	if ( m_vert <= 0 )
	{
		m_vert = 0;
		m_bTopFade = false;
		m_bBottomFade = true;
	}
	else if ( m_vert >= diff )
	{
		m_vert = diff;
		m_bTopFade = true;
		m_bBottomFade = false;
	}
	else
	{
		m_bTopFade = true;
		m_bBottomFade = true;
	}

	m_vertCur = m_pEmbedded.GetYPos();
	m_flScrollStart = clock();
}

// not very good
function SteamAchievementsDisplay::SmoothScroll()
{
	if ( m_flScrollStart )
	{
		local t = ( clock() - m_flScrollStart ) / 0.075;
		if ( t < 1.0 )
		{
			local dt = m_vert + m_vertCur;
			m_pEmbedded.SetPos( m_pEmbedded.GetXPos(), m_vertCur-dt*t );
		}
		else
		{
			m_flScrollStart = 0.0;
			m_pEmbedded.SetPos( m_pEmbedded.GetXPos(), -m_vert );
		}
	}
}

function SteamAchievementsDisplay::__SortAchievements( a, b )
{
	return -( a.m_bAchieved <=> b.m_bAchieved );
}
