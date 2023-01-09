//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// SteamAchievements ------------------------------------------
//
//	"SteamAchievementsPostInit" hook is called post init.
//
// server:
//		SteamAchievements::LoadFromFile( string fileName )
//		SteamAchievements::SetAchievement( player, string ID )
//		SteamAchievements::SetStat( player, string ID, int progress )
//		SteamAchievements::IncrementStat( player, string ID, int amount )
//		SteamAchievements::IndicateAchievementProgress( player, string ID )
//		SteamAchievements::GetAchievement( player, string ID )
//		SteamAchievements::GetStat( player, string ID )
//		SteamAchievements::GetAchievementUnlockTime( player, string ID ) // unix time, 0 if not unlocked
//		SteamAchievements::GetAchievementUnlockDateString( player, string ID, bool bLocalTime, bool bISO8601 )
//		SteamAchievements::StoreStats( player ) // write to permanent storage, automatically called on player disconnect
//		SteamAchievements::ClearAchievement( player, string ID )
//
// client:
//		SteamAchievements::LoadFromFile( string fileName )
//		SteamAchievements::RequestCurrentStats()
//		SteamAchievements::GetAchievement( string ID )
//		SteamAchievements::GetStat( string ID )
//		SteamAchievements::GetAchievementUnlockTime( string ID )
//		SteamAchievements::GetAchievementUnlockDateString( string ID, bool bLocalTime, bool bISO8601 )
//
//
// if 'AchievementDisplay.nut' is included, use 'display_achievements' console command to view all loaded achievements.
//
//
// AchievementNotification ------------------------------------
//
// client:
//		CreateAchievementNotification_Unlocked( string description, string image )
//		CreateAchievementNotification_Progress( int cur, int max, string description, string image )
//
//
//
// FriendNotification -----------------------------------------
//
//	szImage can also take Steam2ID string "STEAM_0:0:0"
//
// server:
//		SendSteamFriendNotification_Online( CBasePlayer player, string szImage, string szSender )
//		SendSteamFriendNotification_InGame( CBasePlayer player, string szImage, string szSender, string szGame )
//		SendSteamFriendNotification_InApp( CBasePlayer player, string szImage, string szSender, string szGame )
//		SendSteamFriendNotification_ChatMsg( CBasePlayer player, string szImage, string szSender, enum PersonaState nSenderState, string szMsg )
//		SendSteamFriendNotification_GameInvite( CBasePlayer player, string szImage, string szSender, string szGame )
//		SendSteamFriendNotification_FriendInvitation( CBasePlayer player, string szImage, string szSender )
//
// client:
//		CreateSteamFriendNotification_Online( string szImage, string szSender )
//		CreateSteamFriendNotification_InGame( string szImage, string szSender, string szGame )
//		CreateSteamFriendNotification_InApp( string szImage, string szSender, string szGame )
//		CreateSteamFriendNotification_ChatMsg( enum PersonaState nSenderState, string szImage, string szSender, string szMsg )
//		CreateSteamFriendNotification_GameInvite( string szImage, string szSender, string szGame )
//		CreateSteamFriendNotification_FriendInvitation( string szImage, string szSender )
//
//
//
// NotificationManager ----------------------------------------
//
// server:
//		SetSteamNotificationPosition( player, enum SteamNotificationPosition )
//
// client:
//		SetSteamNotificationPosition( enum SteamNotificationPosition )
//
//-------------------------------------------------------------
// Resource files: [steam]
//	Avatar border images are resized to 64x64 from 40x40 without scaling
//		"sound/steam/friends/message.wav"
//		"materials/steam/graphics/avatar_32blank"
//		"materials/steam/graphics/avatarBorderInGame"
//		"materials/steam/graphics/avatarBorderOffline"
//		"materials/steam/graphics/avatarBorderOnline"
//-------------------------------------------------------------


enum SteamNotificationPosition
{
	TopLeft, TopRight, BottomLeft, BottomRight
}

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
	InGame
}


local Init = function(...)
{
	if ( CLIENT_DLL )
		IncludeScript( "steam/fonts.nut" );

	if ( !("SteamNotificationManager" in this) ) // Level transition (OnRestore)
	{
		IncludeScript( "steam/utils.nut" );

		IncludeScript( "steam/NotificationManager.nut" );

		IncludeScript( "steam/FriendNotification.nut" );
		IncludeScript( "steam/AchievementNotification.nut" );

		if ( CLIENT_DLL )
			IncludeScript( "steam/AchievementDisplay.nut" );
	}

	// always redefine classes. saverestore bug. see mapbase-source#221
	IncludeScript( "steam/AchievementManager.nut" );

	SteamAchievements.Init();

	if ( CLIENT_DLL )
		SteamNotificationManager.Init();

	if ( CLIENT_DLL )
		SteamAchievementsDisplay.Init();

	Hooks.Call( "SteamAchievementsPostInit", null );
}

local InitRestore = function(...)
{
	if ( SERVER_DLL )
	{
		Init();
	}

	if ( CLIENT_DLL )
	{
		// Level transition hack
		Entities.First().SetContextThink( "SteamUtils", Init, 0.0 );
	}
}

ListenToGameEvent( "player_spawn", function( event )
{
	// server: entities have spawned, collect and setup logic_achievements
	// client: local player spawned, tell the server
	// TODO: uncomment for multiplayer
	// if ( SERVER_DLL || GetPlayerByUserID( event.userid ) == Entities.GetLocalPlayer() )
	{
		Init();
		Entities.First().SetContextThink( "SteamUtils", function(_) { StopListeningToAllGameEvents( "SteamUtils" ); }, 0.0 );
	}
}, "SteamUtils" );

Hooks.Add( this, "OnRestore", InitRestore, "SteamUtils" );
