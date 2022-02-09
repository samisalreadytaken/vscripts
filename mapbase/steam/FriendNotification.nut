//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// server:
//		SendSteamFriendNotification_Online( CBasePlayer player, string szImage, string szSender )
//		SendSteamFriendNotification_InGame( CBasePlayer player, string szImage, string szSender, string szGame )
//		SendSteamFriendNotification_InApp( CBasePlayer player, string szImage, string szSender, string szGame )
//		SendSteamFriendNotification_ChatMsg( CBasePlayer player, enum PersonaState nSenderState, string szImage, string szSender, string szMsg )
//		SendSteamFriendNotification_GameInvite( CBasePlayer player, string szImage, string szSender, string szGame )
//		SendSteamFriendNotification_FriendInvitation( CBasePlayer player, string szImage, string szSender )
//
// client:
//		CreateSteamFriendNotification_Online( string szImage, string szSender )
//		CreateSteamFriendNotification_InGame( string szImage, string szSender, string szGame )
//		CreateSteamFriendNotification_InApp( string szImage, string szSender, string szGame )
//		CreateSteamFriendNotification_ChatMsg( string szImage, enum PersonaState nSenderState, string szSender, string szMsg )
//		CreateSteamFriendNotification_GameInvite( string szImage, string szSender, string szGame )
//		CreateSteamFriendNotification_FriendInvitation( string szImage, string szSender )
//
//

if ( SERVER_DLL )
{
	function SendSteamFriendNotification_Online( player, szImage, szSender )
	{
		NetMsg.Start( "SteamFriendNotification.Online" );
			NetMsg.WriteString( szImage );
			NetMsg.WriteString( szSender );
		NetMsg.Send( player, true );
	}

	function SendSteamFriendNotification_InGame( player, szImage, szSender, szGame )
	{
		NetMsg.Start( "SteamFriendNotification.InGame" );
			NetMsg.WriteString( szImage );
			NetMsg.WriteString( szSender );
			NetMsg.WriteString( szGame );
		NetMsg.Send( player, true );
	}

	function SendSteamFriendNotification_InApp( player, szImage, szSender, szGame )
	{
		NetMsg.Start( "SteamFriendNotification.InApp" );
			NetMsg.WriteString( szImage );
			NetMsg.WriteString( szSender );
			NetMsg.WriteString( szGame );
		NetMsg.Send( player, true );
	}

	function SendSteamFriendNotification_ChatMsg( player, nSenderState, szImage, szSender, szMsg )
	{
		NetMsg.Start( "SteamFriendNotification.ChatMsg" );
			NetMsg.WriteByte( nSenderState );
			NetMsg.WriteString( szImage );
			NetMsg.WriteString( szSender );
			NetMsg.WriteString( szMsg );
		NetMsg.Send( player, true );
	}

	function SendSteamFriendNotification_GameInvite( player, szImage, szSender, szGame )
	{
		NetMsg.Start( "SteamFriendNotification.GameInvite" );
			NetMsg.WriteString( szImage );
			NetMsg.WriteString( szSender );
			NetMsg.WriteString( szGame );
		NetMsg.Send( player, true );
	}

	function SendSteamFriendNotification_FriendInvitation( player, szImage, szSender )
	{
		NetMsg.Start( "SteamFriendNotification.FriendInvitation" );
			NetMsg.WriteString( szImage );
			NetMsg.WriteString( szSender );
		NetMsg.Send( player, true );
	}

	return;
}

//--------------------------------------------------------------
//--------------------------------------------------------------

enum SteamFriendNotification
{
	Online,
	InGame,
	InApp,
	ChatMsg,
	GameInvite,
	FriendInvitation
}

enum PersonaState
{
	Offline,
	Online,
	// Busy,
	// Away,
	// Snooze,
	// LookingToTrade,
	// LookingToPlay
	InGame
}

//--------------------------------------------------------------
//--------------------------------------------------------------


function CreateSteamFriendNotification_Online( szImage, szSender )
{
	local panel = CSteamFriendNotification( szImage.find("STEAM") == 0, SteamFriendNotification.Online );

	panel.SetAvatarImage( szImage );
	panel.SetSenderText( szSender );
}

function CreateSteamFriendNotification_InGame( szImage, szSender, szGame )
{
	local panel = CSteamFriendNotification( szImage.find("STEAM") == 0, SteamFriendNotification.InGame );

	panel.SetAvatarImage( szImage );
	panel.SetSenderText( szSender );
	panel.SetMessageText( szGame );
}

function CreateSteamFriendNotification_InApp( szImage, szSender, szGame )
{
	local panel = CSteamFriendNotification( szImage.find("STEAM") == 0, SteamFriendNotification.InApp );

	panel.SetAvatarImage( szImage );
	panel.SetSenderText( szSender );
	panel.SetMessageText( szGame );
}

function CreateSteamFriendNotification_ChatMsg( nSenderState, szImage, szSender, szMsg )
{
	local panel = CSteamFriendNotification( szImage.find("STEAM") == 0,
		SteamFriendNotification.ChatMsg,
		nSenderState );

	panel.SetAvatarImage( szImage );
	panel.SetSenderText( szSender );
	panel.SetMessageText( szMsg );
}

function CreateSteamFriendNotification_GameInvite( szImage, szSender, szGame )
{
	local panel = CSteamFriendNotification( szImage.find("STEAM") == 0,
		SteamFriendNotification.GameInvite,
		PersonaState.InGame );

	panel.SetAvatarImage( szImage );
	panel.SetSenderText( szSender );
	panel.SetMessageText( szGame );
}

function CreateSteamFriendNotification_FriendInvitation( szImage, szSender )
{
	local panel = CSteamFriendNotification( szImage.find("STEAM") == 0,
		SteamFriendNotification.FriendInvitation,
		PersonaState.Offline );

	panel.SetAvatarImage( szImage );
	panel.SetSenderText( szSender );
}


//--------------------------------------------------------------
//--------------------------------------------------------------


local Fmt = format;

local GetLocalisation = function( txt )
{
	txt = Localize.GetTokenAsUTF8( txt );
	if ( txt[0] != '#' )
		return txt;

	switch ( txt )
	{
		case "#Friends_ChatNotification_Hotkey":
			txt = Fmt( "Press %s to reply", SteamNotificationManager.m_szHotkey );
			break;

		case "#Friends_OnlineNotification_Hotkey":
			txt = Fmt( "Press %s to view", SteamNotificationManager.m_szHotkey );
			break;

		case "#Friends_InviteNotification_Hotkey":
			txt = Fmt( "Press %s to view", SteamNotificationManager.m_szHotkey );
			break;

		case "#Friends_OnlineNotification_Info":
			txt = "is now online";
			break;

		case "#Friends_InGameNotification_Info":
			txt = "is now playing";
			break;

		case "#Friends_InAppNotification_Info":
			txt = "is now using";
			break;

		case "#Friends_GameInvitation_Info":
			txt = "has invited you to play";
			break;

		case "#Friends_InviteInfo_HasAdded":
			txt = "has added you to their";
			break;

		case "#Friends_InviteInfo_FriendsList":
			txt = "Friends List";
			break;

		case "#Friends_ChatNotification_Info":
			txt = "says:";
			break;

		case "#Friends_ChatNoTextNotification_Info":
			txt = "sent you a message";
			break;
	}
	return txt;
}


class CSteamFriendNotification extends SteamNotificationManager.CBaseNotification
{
	m_ImageAvatar = null
	m_IconBorder = null
	m_LabelSender = null
	m_clrLabelSender = null
	m_LabelInfo = null
	m_szLabelInfo = null
	m_clrLabelInfo = null
	m_LabelMessage = null
	m_clrLabelMessage = null
	m_LabelHotkey = null
}

function CSteamFriendNotification::constructor( bSteamAvatar, msgType, senderState = -1 )
{
	base.constructor( "FriendNotification" );

	m_ImageAvatar = vgui.CreatePanel( bSteamAvatar ? "AvatarImage" : "ImagePanel", self, "ImageAvatar" );
	m_ImageAvatar.MakeReadyForUse();
	m_ImageAvatar.SetZPos( 0 );
	m_ImageAvatar.SetVisible( true );
	m_ImageAvatar.SetShouldScaleImage( false );
	if ( bSteamAvatar )
		m_ImageAvatar.SetDefaultAvatar( "steam/graphics/avatar_32blank" );

	m_IconBorder = vgui.CreatePanel( "ImagePanel", self, "IconBorder" );
	m_IconBorder.MakeReadyForUse();
	m_IconBorder.SetZPos( 1 );
	m_IconBorder.SetVisible( true );
	m_IconBorder.SetShouldScaleImage( false );

	m_LabelSender = vgui.CreatePanel( "Label", self, "LabelSender" );
	m_LabelSender.MakeReadyForUse();
	m_LabelSender.SetVisible( true );
	m_LabelSender.SetContentAlignment( Alignment.northwest );
	m_LabelSender.SetFont( surface.GetFont( "SteamScheme.FriendsSmall", false ) );

	local szHotkeyText = "", szMsgText, szInfoText = "";
	switch ( msgType )
	{
		case SteamFriendNotification.Online:
			szInfoText = "#Friends_OnlineNotification_Info";
			szHotkeyText = "#Friends_OnlineNotification_Hotkey";
			m_clrLabelInfo = SteamScheme["Label"];
			senderState = PersonaState.Online;
			break;

		case SteamFriendNotification.InGame:
			szInfoText = "#Friends_InGameNotification_Info";
			szHotkeyText = "#Friends_OnlineNotification_Hotkey";
			m_clrLabelMessage = SteamScheme["Friends.InGameColor"];
			m_clrLabelInfo = SteamScheme["Label2"];
			senderState = PersonaState.InGame;
			break;

		case SteamFriendNotification.InApp:
			szInfoText = "#Friends_InAppNotification_Info";
			szHotkeyText = "#Friends_OnlineNotification_Hotkey";
			m_clrLabelMessage = SteamScheme["Friends.InGameColor"];
			m_clrLabelInfo = SteamScheme["Label2"];
			senderState = PersonaState.InGame;
			break;

		case SteamFriendNotification.GameInvite:
			szInfoText = "#Friends_GameInvitation_Info";
			szHotkeyText = "#Friends_InviteNotification_Hotkey";
			m_clrLabelMessage = SteamScheme["Friends.InGameColor"];
			m_clrLabelInfo = SteamScheme["Label2"];
			break;

		case SteamFriendNotification.FriendInvitation:
			szInfoText = "#Friends_InviteInfo_HasAdded";
			szHotkeyText = "#Friends_InviteNotification_Hotkey";
			szMsgText = "#Friends_InviteInfo_FriendsList";
			m_clrLabelMessage = SteamScheme["Label"];
			m_clrLabelInfo = SteamScheme["Label2"];
			if ( senderState == -1 )
				senderState = PersonaState.Offline;
			break;

		case SteamFriendNotification.ChatMsg:
			szInfoText = "#Friends_ChatNotification_Info";
			szHotkeyText = "#Friends_ChatNotification_Hotkey";
			m_clrLabelMessage = SteamScheme["Label"];
			m_clrLabelInfo = SteamScheme["Label2"];
			break;
	}

	switch ( senderState )
	{
		case PersonaState.InGame:
			m_clrLabelSender = SteamScheme["Friends.InGameColor"];
			m_IconBorder.SetImage( "steam/graphics/avatarBorderInGame", false );
			break;

		case PersonaState.Offline:
			m_clrLabelSender = SteamScheme["Friends.OnlineColor"];
			m_IconBorder.SetImage( "steam/graphics/avatarBorderOffline", false );
			break;

		case PersonaState.Online:
		default:
			m_clrLabelSender = SteamScheme["Friends.OnlineColor"];
			m_IconBorder.SetImage( "steam/graphics/avatarBorderOnline", false );
	}

	if ( szInfoText[0] == '#' )
		szInfoText = GetLocalisation( szInfoText );

	if ( msgType == SteamFriendNotification.ChatMsg )
	{
		m_szLabelInfo = szInfoText;
	}
	else
	{
		m_LabelInfo = vgui.CreatePanel( "Label", self, "LabelInfo" );
		m_LabelInfo.MakeReadyForUse();
		m_LabelInfo.SetVisible( true );
		m_LabelInfo.SetContentAlignment( Alignment.northwest );
		m_LabelInfo.SetFont( surface.GetFont( "SteamScheme.FriendsSmall", false ) );

		m_LabelInfo.SetText( szInfoText );
	}

	if ( msgType != SteamFriendNotification.Online )
	{
		m_LabelMessage = vgui.CreatePanel( "Label", self, "LabelMessage" );
		m_LabelMessage.MakeReadyForUse();
		m_LabelMessage.SetVisible( true );
		m_LabelMessage.SetContentAlignment( Alignment.northwest );
		m_LabelMessage.SetFont( surface.GetFont( "SteamScheme.FriendsSmall", false ) );

		if ( msgType != SteamFriendNotification.InGame && msgType != SteamFriendNotification.GameInvite )
		{
			m_LabelMessage.SetWrap( true );
		}

		if ( szMsgText )
		{
			if ( szMsgText[0] == '#' )
				szMsgText = GetLocalisation( szMsgText );
			m_LabelMessage.SetText( szMsgText );
		}
	}

	// includes DarkenedRegion as background
	m_LabelHotkey = vgui.CreatePanel( "Label", self, "LabelHotkey" );
	m_LabelHotkey.MakeReadyForUse();
	m_LabelHotkey.SetVisible( true );
	m_LabelHotkey.SetContentAlignment( Alignment.center );
	m_LabelHotkey.SetFont( surface.GetFont( "SteamScheme.FriendsSmall", false ) );

	if ( szHotkeyText[0] == '#' )
		szHotkeyText = GetLocalisation( szHotkeyText );
	m_LabelHotkey.SetText( szHotkeyText );

	PerformLayout();

	if ( msgType == SteamFriendNotification.ChatMsg ||
		msgType == SteamFriendNotification.GameInvite )
	{
		surface.PlaySound( "steam/friends/message.wav" );
	}
}

function CSteamFriendNotification::PerformLayout()
{
	// "friends/FriendNotification.res"
	base.PerformLayout( 240, 98 );

	m_IconBorder.SetPos( 18, 18 );
	m_IconBorder.SetSize( 40, 40 );

	m_ImageAvatar.SetPos( 22, 22 );
	m_ImageAvatar.SetSize( 32, 32 );

	m_LabelSender.SetPos( 64, 16 );
	m_LabelSender.SetSize( 172, 14 );
	m_LabelSender.SetFgColor(
		m_clrLabelSender[0],
		m_clrLabelSender[1],
		m_clrLabelSender[2],
		m_clrLabelSender[3] );

	if ( m_LabelInfo )
	{
		m_LabelInfo.SetPos( 64, 30 );
		m_LabelInfo.SetSize( 172, 14 );
		m_LabelInfo.SetFgColor(
			m_clrLabelInfo[0],
			m_clrLabelInfo[1],
			m_clrLabelInfo[2],
			m_clrLabelInfo[3] );
	}

	if ( m_LabelMessage )
	{
		m_LabelMessage.SetPos( 64, 44 );
		m_LabelMessage.SetSize( 172, 30 );
		m_LabelMessage.SetFgColor(
			m_clrLabelMessage[0],
			m_clrLabelMessage[1],
			m_clrLabelMessage[2],
			m_clrLabelMessage[3] );
	}

	m_LabelHotkey.SetPos( 0, 74 );
	m_LabelHotkey.SetSize( 240, 24 );
	m_LabelHotkey.SetBgColor( 0, 0, 0, 255 );
	local clr = SteamScheme["Label2"];
	m_LabelHotkey.SetFgColor( clr[0], clr[1], clr[2], clr[3] );
}

function CSteamFriendNotification::SetAvatarImage( img )
{
	if ( "SetPlayer" in m_ImageAvatar )
		return m_ImageAvatar.SetPlayer( img, 0 );

	if ( !img || !(0 in img) )
		return m_ImageAvatar.SetImage( "steam/graphics/avatar_32blank", false );

	return m_ImageAvatar.SetImage( img, false );
}

function CSteamFriendNotification::SetSenderText( text )
{
	// Chat message info text is next to the sender name
	if ( !m_LabelInfo )
	{
		m_LabelSender.AddColorChange(
			m_clrLabelInfo[0],
			m_clrLabelInfo[1],
			m_clrLabelInfo[2],
			m_clrLabelInfo[3],
			text.len() );

		text += " " + m_szLabelInfo;
	}
	return m_LabelSender.SetText( text );
}

function CSteamFriendNotification::SetMessageText( text )
{
	if ( m_LabelMessage )
		return m_LabelMessage.SetText( text );
	Warning("Failed to set message text\n");
}

//--------------------------------------------------

function CSteamFriendNotification::Init()
{
	NetMsg.Receive( "SteamFriendNotification.Online", function()
	{
		local p1 = NetMsg.ReadString();
		local p2 = NetMsg.ReadString();
		return CreateSteamFriendNotification_Online( p1, p2 );
	} );

	NetMsg.Receive( "SteamFriendNotification.InGame", function()
	{
		local p1 = NetMsg.ReadString();
		local p2 = NetMsg.ReadString();
		local p3 = NetMsg.ReadString();
		return CreateSteamFriendNotification_InGame( p1, p2, p3 );
	} );

	NetMsg.Receive( "SteamFriendNotification.ChatMsg", function()
	{
		local p1 = NetMsg.ReadByte();
		local p2 = NetMsg.ReadString();
		local p3 = NetMsg.ReadString();
		local p4 = NetMsg.ReadString();
		return CreateSteamFriendNotification_ChatMsg( p1, p2, p3, p4 );
	} );

	NetMsg.Receive( "SteamFriendNotification.GameInvite", function()
	{
		local p1 = NetMsg.ReadString();
		local p2 = NetMsg.ReadString();
		local p3 = NetMsg.ReadString();
		return CreateSteamFriendNotification_GameInvite( p1, p2, p3 );
	} );

	NetMsg.Receive( "SteamFriendNotification.FriendInvitation", function()
	{
		local p1 = NetMsg.ReadString();
		local p2 = NetMsg.ReadString();
		return CreateSteamFriendNotification_FriendInvitation( p1, p2 );
	} );
}
