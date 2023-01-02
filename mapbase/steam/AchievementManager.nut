//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Achievements are always serverside.
// User/player parameters on server take CBasePlayer entity instance, not Steam ID.
//
// Client cannot fetch other users' stats,
// serverside functions are named identical to their clientside counterparts without `User`,
// even though they take an extra user parameter.
//
// Achievement info (name, max val, icon paths & images) are expected to be loaded on client.
//
// Client needs to call SteamAchievements.RequestCurrentStats() to update local cache with the latest stats.
// "SteamAchievements.UserStatsReceived" hook is called when client cache is updated.
//
// "SteamAchievementsPostInit" hook is called post initialisation to allow
// users load custom achievements as early as possible.
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

if ( SERVER_DLL )
{
	local MAX_PLAYERS = MaxPlayers();

	SteamAchievements <-
	{
		m_Achievements = null

		m_mapID = null
		m_AchievementState = null
		m_pbStatsChangedSinceLastRequest = array( MAX_PLAYERS+1, true )
	}

	class SteamAchievements.Achievement_t
	{
		m_nMaxProgress = 0
		m_rgchAchievementID = null
	}
}
else if ( CLIENT_DLL )
{
	SteamAchievements <-
	{
		m_Achievements = null

		m_bRequestedStats = false
	}

	class SteamAchievements.Achievement_t
	{
		m_rgchAchievementID = null
		m_rgchName = null
		m_rgchDescription = null
		m_szIconImageAchieved = null
		m_szIconImageUnachieved = null
		m_nCurProgress = 0
		m_nMaxProgress = 0
		m_unUnlockTime = 0
	}
}

local Fmt = format, time = time, date = date;

//
//	bool bLocalTime - use local system time (true), or UTC
//	bool bISO8601 - ISO 8601 compliant RFC 3339 specification date format (true), or the format used in Steam Community (false)
//
// TODO: Localisation
//
local function _ConvertTimeToDate( unUnlockTime, bLocalTime, bISO8601 )
{
	local unlockDate = date( unUnlockTime, bLocalTime ? 'l' : 'u' );

	// ISO 8601 compliant RFC 3339 specification date format
	if ( bISO8601 )
	{
		++unlockDate.month;

		if ( bLocalTime )
		{
			// calculate time zone
			local localDate = date( 0, 'l' );
			local utcDate = date( 0, 'u' );
			local hourDiff = localDate.hour - utcDate.hour;
			local minDiff = localDate.min - utcDate.min;

			return Fmt( "%d-%02d-%02d %02d:%02d:%02d%s%02d%02d",
				unlockDate.year, unlockDate.month, unlockDate.day, unlockDate.hour, unlockDate.min, unlockDate.sec,
				( hourDiff >= 0 ) ? "+" : "-", hourDiff, minDiff );
		}
		else
		{
			return Fmt( "%d-%02d-%02d %02d:%02d:%02d+0000",
				unlockDate.year, unlockDate.month, unlockDate.day, unlockDate.hour, unlockDate.min, unlockDate.sec );
		}
	}
	else
	{
		local hour = unlockDate.hour;
		local postmeridiem = ( hour >= 12 );
		if ( hour >= 13 )
		{
			hour -= 12;
		}
		else if ( hour == 0 )
		{
			hour = 12;
		}

		local month = "";
		switch ( unlockDate.month )
		{
			case 0: month = "Jan";	break;
			case 1: month = "Feb";	break;
			case 2: month = "Mar";	break;
			case 3: month = "Apr";	break;
			case 4: month = "May";	break;
			case 5: month = "Jun";	break;
			case 6: month = "Jul";	break;
			case 7: month = "Aug";	break;
			case 8: month = "Sep";	break;
			case 9: month = "Oct";	break;
			case 10: month = "Nov";	break;
			case 11: month = "Dec";	break;
		}

		return Fmt( "%d %s, %d @ %d:%02d%s",
			unlockDate.day, month, unlockDate.year, hour, unlockDate.min, postmeridiem ? "pm" : "am" );
	}
}

// Persistent database key names.
// Changing these will break reading old logs.
const key_data = "value";
const key_UnlockTime = "unlockTime";

function SteamAchievements::Init()
{
	print("SteamAchievements::Init()\n");

	if ( !m_Achievements )
	{
		m_Achievements = {}

		if ( SERVER_DLL )
		{
			m_AchievementState = {}
			m_mapID = {}

			LoadFromFile( "achievements_" + GetMapName().tolower() + ".txt" );

			// Hook logic_achievement entities to support unlocking custom achievements with them
			{
				local p, tmp = {}, InputFireEvent = function()
				{
					if ( !self.GetKeyValue( "StartDisabled" ).tointeger() )
						return !SteamAchievements.SetAchievement( Entities.GetLocalPlayer(), m_szAchievementID );
					return true;
				}
				while ( p = Entities.FindByClassname( p, "logic_achievement" ) )
				{
					local sc = p.GetOrCreatePrivateScriptScope();
					SaveEntityKVToTable( p, tmp );
					sc.m_szAchievementID <- tmp["AchievementEvent"];
					sc.InputFireEvent <- InputFireEvent;
				}
			}
		}
		else // CLIENT_DLL
		{
			local mapname = split( GetMapName(), "/" ).top().tolower();
			local i = mapname.find( ".bsp" );
			if ( i != null )
				mapname = mapname.slice( 0, i );
			LoadFromFile( "achievements_" + mapname + ".txt" );
		}
	}

	NetMsg.Receive( "SteamAchievements.RequestStats", NET_RequestStats.bindenv(this) );

	if ( SERVER_DLL )
	{
		NetMsg.Receive( "SteamAchievements.Init", NET_Init.bindenv(this) );
	}
	else // CLIENT_DLL
	{
		NetMsg.Receive( "SteamAchievements.UserStatsReceived", NET_UserStatsReceived.bindenv(this) );
		NetMsg.Receive( "SteamAchievements.AchievementUnlocked", NET_AchievementUnlocked.bindenv(this) );
		NetMsg.Receive( "SteamAchievements.IndicateProgress", NET_IndicateProgress.bindenv(this) );

		NetMsg.Start( "SteamAchievements.Init" );
			local id = steam.GetSteam2ID();
			if ( id )
			{
				// steam2id to accountid
				local p = split( id, ":" );
				NetMsg.WriteLong( p[2].tointeger() * 2 + p[1].tointeger() );
			}
			else
			{
				NetMsg.WriteLong( 0 );
			}
		NetMsg.Send();
	}
}

function SteamAchievements::LoadFromFile( fileName )
{
	local achCount = m_Achievements.len();

	local pKV = FileToKeyValues( fileName );
	if ( pKV && pKV.GetName().tolower() == "achievements" )
	{
		for ( pKV = pKV.GetFirstSubKey(); pKV; pKV = pKV.GetNextKey() )
		{
			local id = pKV.GetName();
			if ( !(0 in id) )
				return;

			if ( id.len() > 127 ) // k_cchStatNameMax
				id = id.slice( 0, 127 );

			local ach = m_Achievements[ id ] <- Achievement_t();
			ach.m_rgchAchievementID = id;
			ach.m_nMaxProgress = pKV.GetKeyInt( "maxVal" );
if ( CLIENT_DLL ){
			ach.m_rgchName = pKV.GetKeyString( "name" );
			ach.m_rgchDescription = pKV.GetKeyString( "desc" );
			ach.m_szIconImageAchieved = pKV.GetKeyString( "iconAchieved" );
			ach.m_szIconImageUnachieved = pKV.GetKeyString( "iconUnachieved" );

			if ( !(0 in ach.m_szIconImageAchieved) )
				ach.m_szIconImageAchieved = null;

			if ( !(0 in ach.m_szIconImageUnachieved) )
				ach.m_szIconImageUnachieved = ach.m_szIconImageAchieved;
} // CLIENT_DLL
		}
	}

	achCount = m_Achievements.len() - achCount;
	Msg(Fmt( "Loaded %d achievements from '%s'\n", achCount, fileName ));
	return achCount;
}

if ( SERVER_DLL )
{
	// Achievement ID hashing adds a little bit of encryption to prevent manipulation of achievement stats.
	local _hashstr = _hashstr;
	local _hashID = function( tag )
	{
		return Fmt( "%u", _hashstr(tag) );
	}

	const LOG_FILE_NAME = "ach_%u.db1";

	//
	// Unlocks an achievement for the specified user.
	//
	function SteamAchievements::SetAchievement( player, tag )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local achState = m_AchievementState[ m_mapID[ player ] ][ _hashID(tag) ];
		local maxProgress = m_Achievements[tag].m_nMaxProgress;

		if ( !maxProgress )
			maxProgress = 1;

		if ( achState[ key_data ] >= maxProgress )
			return;

		achState[ key_data ] = maxProgress;
		achState[ key_UnlockTime ] = time();

		NetMsg.Start( "SteamAchievements.AchievementUnlocked" );
			NetMsg.WriteString( tag );
		NetMsg.Send( player, true );

		m_pbStatsChangedSinceLastRequest[ player.entindex() ] = true;

		return true;
	}

	//
	// Gets the unlock status of the Achievement.
	//
	function SteamAchievements::GetAchievement( player, tag )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local achState = m_AchievementState[ m_mapID[ player ] ][ _hashID(tag) ];
		local nMaxProgress = m_Achievements[tag].m_nMaxProgress;

		if ( nMaxProgress )
			return ( achState[ key_data ] == nMaxProgress );

		return ( achState[ key_data ] == 1 );
	}

	//
	// Gets the current value of the a stat for the specified user.
	//
	function SteamAchievements::GetStat( player, tag )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local achState = m_AchievementState[ m_mapID[ player ] ][ _hashID(tag) ];

		return achState[ key_data ];
	}

	function SteamAchievements::GetAchievementUnlockTime( player, tag )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local achState = m_AchievementState[ m_mapID[ player ] ][ _hashID(tag) ];

		return achState[ key_UnlockTime ];
	}

	//
	// Returns the date of the time specified achievement was unlocked.
	// Returns null if achievement or player was not found.
	//
	function SteamAchievements::GetAchievementUnlockDateString( player, tag, bLocalTime, bISO8601 )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local achState = m_AchievementState[ m_mapID[ player ] ][ _hashID(tag) ];

		return _ConvertTimeToDate( achState[ key_UnlockTime ], bLocalTime, bISO8601 );
	}

	//
	// Sets / updates the value of a given stat for the specified user.
	//
	function SteamAchievements::SetStat( player, tag, nData )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local achState = m_AchievementState[ m_mapID[ player ] ][ _hashID(tag) ];
		local maxProgress = m_Achievements[tag].m_nMaxProgress;

		if ( !maxProgress )
			maxProgress = 1;

		if ( achState[ key_data ] >= maxProgress )
			return;

		if ( nData < maxProgress )
		{
			achState[ key_data ] = nData;
		}
		else
		{
			achState[ key_data ] = maxProgress;
			achState[ key_UnlockTime ] = time();

			NetMsg.Start( "SteamAchievements.AchievementUnlocked" );
				NetMsg.WriteString( tag );
			NetMsg.Send( player, true );
		}

		m_pbStatsChangedSinceLastRequest[ player.entindex() ] = true;

		return true;
	}

	function SteamAchievements::IncrementStat( player, tag, nAmount )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local achState = m_AchievementState[ m_mapID[ player ] ][ _hashID(tag) ];
		local nData = achState[ key_data ];
		local maxProgress = m_Achievements[tag].m_nMaxProgress;

		if ( !maxProgress )
			maxProgress = 1;

		if ( nData >= maxProgress )
			return;

		nData += nAmount;

		if ( nData < maxProgress )
		{
			achState[ key_data ] = nData;
		}
		else
		{
			achState[ key_data ] = maxProgress;
			achState[ key_UnlockTime ] = time();

			NetMsg.Start( "SteamAchievements.AchievementUnlocked" );
				NetMsg.WriteString( tag );
			NetMsg.Send( player, true );
		}

		m_pbStatsChangedSinceLastRequest[ player.entindex() ] = true;

		return true;
	}

	function SteamAchievements::IndicateAchievementProgress( player, tag )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local achState = m_AchievementState[ m_mapID[ player ] ][ _hashID(tag) ];
		local nData = achState[ key_data ];
		local maxProgress = m_Achievements[tag].m_nMaxProgress;

		if ( !maxProgress )
			return Msg( "Achievement '"+tag+"' has no progress to indicate\n" );

		if ( nData >= maxProgress )
			return;

		NetMsg.Start( "SteamAchievements.IndicateProgress" );
			NetMsg.WriteString( tag );
			NetMsg.WriteLong( nData );
		return NetMsg.Send( player, true );
	}

	//
	// Write cached achievement results
	// Automatically called on player disconnect
	//
	function SteamAchievements::StoreStats( player )
	{
		Msg(Fmt( "SteamAchievements::StoreStats(%d)\n", player.entindex() ));

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local playerID = m_mapID[ player ];
		local fileName = Fmt( LOG_FILE_NAME, playerID );

		local pKV = FileToKeyValues( fileName );
		if ( !pKV )
			return Warning( "Achievement log file is missing!\n" );

		local kv = m_AchievementState[ playerID ];
		// pKV.TableToSubKeys( kv );
		foreach( achID, achState in kv )
		{
			local pSubKey = pKV.FindOrCreateKey(achID);
			pSubKey.SetKeyInt( key_data, achState[key_data] );
			pSubKey.SetKeyInt( key_UnlockTime, achState[key_UnlockTime] );
		}

		return KeyValuesToFile( fileName, pKV );
	}

	//
	// Reset achievement
	//
	function SteamAchievements::ClearAchievement( player, tag )
	{
		if ( !(tag in m_Achievements) )
			return;

		if ( !(player in m_mapID) )
			return;

		local achState = m_AchievementState[ m_mapID[ player ] ][ _hashID(tag) ];
		achState[ key_data ] = 0;
		achState[ key_UnlockTime ] = 0;

		m_pbStatsChangedSinceLastRequest[ player.entindex() ] = true;
	}

	local UpdateOnRemove = function()
	{
		SteamAchievements.StoreStats( self );
		SteamAchievements.m_pbStatsChangedSinceLastRequest[ self.entindex() ] = true;
	}

	function SteamAchievements::NET_Init( player )
	{
		printf( "SteamAchievements::NET_Init(%d)\n", player.entindex() );

		local id = NetMsg.ReadLong();
		m_mapID[ player ] <- id;
		local fileName = Fmt( LOG_FILE_NAME, id );
		local bAlloc = false;

		// init and load logs
		local pKV = FileToKeyValues( fileName );
		if ( !pKV )
		{
			pKV = CScriptKeyValues();
			pKV.SetName( "AchievementLog" );
			bAlloc = true;
		}

		local kv = {}
		m_AchievementState[ id ] <- kv;

		// read
		//pKV.SubKeysToTable( kv );
		for ( local key = pKV.GetFirstSubKey(); key; key = key.GetNextKey() )
		{
			if ( !key.GetFirstSubKey() )
				Warning( "SteamAchievements invalid log '"+fileName+"'\n" );

			kv[ key.GetName() ] <-
			{
				[key_data] = key.GetKeyInt( key_data ),
				[key_UnlockTime] = key.GetKeyInt( key_UnlockTime )
			}
		}

		local count = kv.len();

		// get missing
		foreach( apiName, ach in m_Achievements )
		{
			local achID = _hashID(apiName);
			if ( achID in kv )
				continue;

			kv[ achID ] <-
			{
				[key_data] = 0,
				[key_UnlockTime] = 0
			}
		}

		if ( kv.len() != count )
		{
			// write missing
			//pKV.TableToSubKeys( kv );
			foreach( achID, achState in kv )
			{
				if ( pKV.FindKey(achID) )
					continue;

				local pSubKey = pKV.FindOrCreateKey(achID);
				pSubKey.SetKeyInt( key_data, achState[key_data] );
				pSubKey.SetKeyInt( key_UnlockTime, achState[key_UnlockTime] );
			}

			KeyValuesToFile( fileName, pKV );
		}

		if ( bAlloc )
			pKV.ReleaseKeyValues();

		return Hooks.Add( player.GetOrCreatePrivateScriptScope(),
			"UpdateOnRemove",
			UpdateOnRemove,
			"SteamAchievements.UpdateOnRemove" );
	}

	function SteamAchievements::NET_RequestStats( player )
	{
		local playerIdx = player.entindex();
		if ( m_pbStatsChangedSinceLastRequest[ playerIdx ] )
		{
			m_pbStatsChangedSinceLastRequest[ playerIdx ] = null;

			local userAchState = m_AchievementState[ m_mapID[ player ] ];

			// UNDONE: multiple stats per message
			foreach ( achName, ach in m_Achievements )
			{
				local achState = userAchState[ _hashID(achName) ];

				NetMsg.Start( "SteamAchievements.RequestStats" );
					NetMsg.WriteString( achName );
					NetMsg.WriteLong( achState[ key_data ] );
					NetMsg.WriteLong( achState[ key_UnlockTime ] );
				NetMsg.Send( player, true );
			}
		}

		// FIXME: Is this sequential?
		NetMsg.Start( "SteamAchievements.UserStatsReceived" );
		NetMsg.Send( player, true );
	}
}

if ( CLIENT_DLL )
{
	// Asynchronously request the user's current stats and achievements from the server.
	// You must always call this first to get the initial status of stats and achievements.
	// Only after the resulting callback comes back can you start calling the rest of the
	// stats and achievement functions for the current user.
	function SteamAchievements::RequestCurrentStats()
	{
		if ( m_bRequestedStats )
			return;

		Msg( "SteamAchievements::RequestCurrentStats()\n" );
		NetMsg.Start( "SteamAchievements.RequestStats" );
		NetMsg.Send();
	}

	function SteamAchievements::GetAchievement( tag )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		local ach = m_Achievements[tag];
		local nMaxProgress = ach.m_nMaxProgress;

		if ( nMaxProgress )
			return ( ach.m_nCurProgress == nMaxProgress );

		return ( ach.m_nCurProgress == 1 );
	}

	function SteamAchievements::GetStat( tag )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		return m_Achievements[tag].m_nCurProgress;
	}

	function SteamAchievements::GetAchievementUnlockTime( tag )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		return m_Achievements[tag].m_unUnlockTime;
	}

	function SteamAchievements::GetAchievementUnlockDateString( tag, bLocalTime, bISO8601 )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		return _ConvertTimeToDate( m_Achievements[tag].m_unUnlockTime, bLocalTime, bISO8601 );
	}

	// Incoming stat data
	function SteamAchievements::NET_RequestStats()
	{
		local achName = NetMsg.ReadString();
		local nData = NetMsg.ReadLong();
		local nUnlockTime = NetMsg.ReadLong();

		if ( !(achName in m_Achievements) )
			return Warning(Fmt( "Achievement '%s' is not found\n", achName ));

		local ach = m_Achievements[achName];
		ach.m_nCurProgress = nData;
		ach.m_unUnlockTime = nUnlockTime;
	}

	function SteamAchievements::NET_UserStatsReceived()
	{
		Msg( "SteamAchievements::UserStatsReceived\n" );

		m_bRequestedStats = false;

		Hooks.Call( "SteamAchievements.UserStatsReceived", null );
	}

	function SteamAchievements::NET_AchievementUnlocked()
	{
		local tag = NetMsg.ReadString();

		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		local ach = m_Achievements[tag];

		// Update local cache while we're here
		ach.m_nCurProgress = ach.m_nMaxProgress ? ach.m_nMaxProgress : 1;

		return CreateAchievementNotification_Unlocked( ach.m_rgchName, ach.m_szIconImageAchieved );
	}

	function SteamAchievements::NET_IndicateProgress()
	{
		local tag = NetMsg.ReadString();
		local nData = NetMsg.ReadLong();

		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		local ach = m_Achievements[tag];

		// Update local cache while we're here
		ach.m_nCurProgress = nData;

		return CreateAchievementNotification_Progress( nData, ach.m_nMaxProgress, ach.m_rgchName, ach.m_szIconImageUnachieved );
	}
}

// Cleanup local consts
local K = getconsttable();
delete K.key_data;
delete K.key_UnlockTime;
delete K.LOG_FILE_NAME;
