//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// client:
//		CreateAchievementNotification_Unlocked( string description, string image )
//		CreateAchievementNotification_Progress( int cur, int max, string description, string image )
//
//

if ( SERVER_DLL )
	return;

local Fmt = format;

function CreateAchievementNotification_Unlocked( description, image )
{
	CSteamAchievementNotification(
		"#Friends_AchievementUnlocked_Headline",
		description,
		image );
}

function CreateAchievementNotification_Progress( cur, max, description, image )
{
	CSteamAchievementNotification(
		"#Friends_AchievementProgress_Headline",
		Fmt( "%s (%s/%s)", description, prettifynum(cur), prettifynum(max) ),
		image );
}

//--------------------------------------------------------------
//--------------------------------------------------------------

local GetLocalisation = function( txt )
{
	txt = Localize.GetTokenAsUTF8( txt );
	if ( txt[0] != '#' )
		return txt;

	switch ( txt )
	{
		case "#Friends_AchievementUnlocked_Headline":
			txt = "Achievement Unlocked!";
			break;

		case "#Friends_AchievementProgress_Headline":
			txt = "Achievement Progress";
			break;
	}
	return txt;
}


class CSteamAchievementNotification extends SteamNotificationManager.CBaseNotification
{
	m_DarkenedRegion = null
	m_AchievementIcon = null
	m_LabelTitle = null
	m_LabelDescription = null
}

function CSteamAchievementNotification::constructor( title, description, image )
{
	base.constructor( "AchievementNotification" );

	m_DarkenedRegion = vgui.CreatePanel( "Panel", self, "DarkenedRegion" );
	m_DarkenedRegion.MakeReadyForUse();
	m_DarkenedRegion.SetZPos( -1 );
	m_DarkenedRegion.SetVisible( true );
	m_DarkenedRegion.SetPaintEnabled( false );
	m_DarkenedRegion.SetPaintBackgroundEnabled( true );

	m_AchievementIcon = vgui.CreatePanel( "ImagePanel", self, "AchievementIcon" );
	m_AchievementIcon.MakeReadyForUse();
	m_AchievementIcon.SetVisible( true );
	m_AchievementIcon.SetShouldScaleImage( false );
	m_AchievementIcon.SetImage( image, false );

	//m_IconBorder = vgui.CreatePanel( "ImagePanel", self, "IconBorder" );
	//m_IconBorder.MakeReadyForUse();
	//m_IconBorder.SetZPos( 1 );
	//m_IconBorder.SetVisible( true );
	//m_IconBorder.SetShouldScaleImage( true );
	//m_IconBorder.SetImage( "steam/graphics/achievementbg", false );

	if ( title[0] == '#' )
		title = GetLocalisation( title );

	if ( description[0] == '#' )
		description = GetLocalisation( description );

	m_LabelTitle = vgui.CreatePanel( "Label", self, "LabelTitle" );
	m_LabelTitle.MakeReadyForUse();
	m_LabelTitle.SetVisible( true );
	m_LabelTitle.SetPaintBackgroundEnabled( false );
	m_LabelTitle.SetContentAlignment( Alignment.northwest );
	m_LabelTitle.SetFont( surface.GetFont( "SteamScheme.FriendsSmall", false ) );
	m_LabelTitle.SetWrap( true );
	m_LabelTitle.SetText( title );

	m_LabelDescription = vgui.CreatePanel( "Label", self, "LabelDescription" );
	m_LabelDescription.MakeReadyForUse();
	m_LabelDescription.SetVisible( true );
	m_LabelDescription.SetPaintBackgroundEnabled( false );
	m_LabelDescription.SetContentAlignment( Alignment.northwest );
	m_LabelDescription.SetFont( surface.GetFont( "SteamScheme.FriendsSmall", false ) );
	m_LabelDescription.SetWrap( true );
	m_LabelDescription.SetText( description );

	PerformLayout();
}

function CSteamAchievementNotification::PerformLayout()
{
	// "friends/AchievementNotification.res"
	base.PerformLayout( 240, 94 );

	m_DarkenedRegion.SetPos( 1, 74 );
	m_DarkenedRegion.SetSize( 238, 23 );
	local clr = SteamScheme["ClientBG"];
	m_DarkenedRegion.SetBgColor( clr[0], clr[1], clr[2], clr[3] );

	m_AchievementIcon.SetPos( 14, 14 );
	m_AchievementIcon.SetSize( 64, 64 );

	//m_IconBorder.SetPos( 13, 13 );
	//m_IconBorder.SetSize( 66, 66 );

	m_LabelTitle.SetPos( 88, 25 );
	m_LabelTitle.SetSize( 144, 28 );
	clr = SteamScheme["AchievementPopup.TitleColor"];
	m_LabelTitle.SetFgColor( clr[0], clr[1], clr[2], clr[3] );

	m_LabelDescription.SetPos( 88, 53 );
	m_LabelDescription.SetSize( 144, 28 );
	clr = SteamScheme["AchievementPopup.DescriptionColor"];
	m_LabelDescription.SetFgColor( clr[0], clr[1], clr[2], clr[3] );
}
