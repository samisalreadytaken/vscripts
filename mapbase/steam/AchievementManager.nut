//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// server:
//		SteamAchievements::SetAchievement( player, string ID )
//		SteamAchievements::SetStat( player, string ID, int progress, bool notify )
//		SteamAchievements::IncrementStat( player, string ID, int amount, bool notify )
//		SteamAchievements::GetStat( player, string ID )
//		SteamAchievements::IndicateAchievementProgress( player, string ID )
//		SteamAchievements::LoadFromFile( string fileName )
//		SteamAchievements::StoreStats( player ) // write to permanent storage, automatically called on player disconnect
//		SteamAchievements::ClearAchievement( player, string ID )
//
// client:
//		SteamAchievements::LoadFromFile( string fileName )
//
//


SteamAchievements <-
{
	m_Achievements = null
}

if ( SERVER_DLL )
{
	SteamAchievements.m_AchievementState <- null
	SteamAchievements.m_mapID <- null

	class SteamAchievements.Achievement_t
	{
		m_rgchAchievementID = null
		m_nMaxProgress = null
	}
}
else if ( CLIENT_DLL )
{
	class SteamAchievements.Achievement_t
	{
		m_rgchAchievementID = null
		m_rgchName = null
		m_rgchDescription = null
		m_nMaxProgress = null
		m_szIconImageAchieved = null
		m_szIconImageUnachieved = null
	}
}

local InputFireEvent = function()
{
	if ( !self.GetKeyValue( "StartDisabled" ).tointeger() )
		return !SteamAchievements.SetAchievement( Entities.GetLocalPlayer(), m_szAchievementID );
	return true;
}

function SteamAchievements::Init()
{
	print("SteamAchievements::Init()\n");

	m_Achievements = {}

	if ( SERVER_DLL )
	{
		NetMsg.Receive( "SteamAchievements.Init", NET_Init.bindenv(this) );

		m_AchievementState = {}
		m_mapID = {}

		LoadFromFile( "achievements_" + GetMapName().tolower() + ".txt" );

		local tmp = {}
		for ( local p; p = Entities.FindByClassname( p, "logic_achievement" ); )
		{
			local sc = p.GetOrCreatePrivateScriptScope();
			SaveEntityKVToTable( p, tmp );
			sc.m_szAchievementID <- tmp["AchievementEvent"];
			sc.InputFireEvent <- InputFireEvent;
		}
	}
	else
	{
		NetMsg.Receive( "SteamAchievements.SetAchievement", NET_SetAchievement.bindenv(this) );
		NetMsg.Receive( "SteamAchievements.SetStat", NET_SetStat.bindenv(this) );

		local mapname = split( GetMapName(), "/" ).top().tolower();
		local i = mapname.find( ".bsp" );
		if ( i != null )
			mapname = mapname.slice( 0, i );
		LoadFromFile( "achievements_" + mapname + ".txt" );

		NetMsg.Start( "SteamAchievements.Init" );
			local id = steam.GetSteam2ID();
			if ( !id ) id = "STEAM_0:0:0";
			NetMsg.WriteString( id );
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

			if ( id.len() > 127 )
				id = id.slice( 0, 127 );

			local ach = m_Achievements[ id ] <- Achievement_t();
			ach.m_rgchAchievementID = id;
			ach.m_nMaxProgress = pKV.GetKeyInt( "maxVal" );
if ( CLIENT_DLL ){
			ach.m_rgchName = pKV.GetKeyString("name")
			ach.m_rgchDescription = pKV.GetKeyString("desc")
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
	printf( "Loaded %d achievements from '%s'\n", achCount, fileName );
	return achCount;
}

if ( SERVER_DLL )
{
	// Achievement ID hashing adds a little bit of encryption to prevent manipulation of achievement stats.
	local Fmt = format, _hashstr = _hashstr;
	local _hashID = function( tag )
	{
		return Fmt( "%u", _hashstr(tag) );
	}

	local GetLogFileName = function( playerID )
	{
		local p = split( playerID, ":" );
		return Fmt( "ach_%s%s.db", p[1], p[2] );
	}

	function SteamAchievements::SetAchievement( player, tag )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local playerID = m_mapID[ player ];
		local achID = _hashID(tag);

		if ( m_AchievementState[ playerID ][ achID ] != 0 )
			return Msg( "Achievement '"+tag+"' is already achieved\n" );

		m_AchievementState[ playerID ][ achID ] = 1;

		NetMsg.Start( "SteamAchievements.SetAchievement" );
			NetMsg.WriteString( tag );
		NetMsg.Send( player, true );

		return true;
	}

	function SteamAchievements::GetStat( player, tag )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local playerID = m_mapID[ player ];
		local achID = _hashID(tag);

		return m_AchievementState[ playerID ][ achID ];
	}

	function SteamAchievements::SetStat( player, tag, nData )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local playerID = m_mapID[ player ];
		local achID = _hashID(tag);
		local curData = m_AchievementState[ playerID ][ achID ];
		local ach = m_Achievements[tag];

		if ( curData >= ach.m_nMaxProgress )
			return Msg( "Achievement '"+tag+"' is already achieved\n" );

		if ( nData < ach.m_nMaxProgress )
		{
			m_AchievementState[ playerID ][ achID ] = nData;
		}
		else
		{
			nData = ach.m_nMaxProgress;
			if ( nData == 0 )
				nData = 1;

			m_AchievementState[ playerID ][ achID ] = nData;

			NetMsg.Start( "SteamAchievements.SetAchievement" );
				NetMsg.WriteString( tag );
			NetMsg.Send( player, true );
		}

		return true;
	}

	function SteamAchievements::IncrementStat( player, tag, nAmount )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local playerID = m_mapID[ player ];
		local achID = _hashID(tag);
		local nData = m_AchievementState[ playerID ][ achID ];
		local ach = m_Achievements[tag];

		if ( nData >= ach.m_nMaxProgress )
			return Msg( "Achievement '"+tag+"' is already achieved\n" );

		nData += nAmount;

		if ( nData < ach.m_nMaxProgress )
		{
			m_AchievementState[ playerID ][ achID ] = nData;
		}
		else
		{
			nData = ach.m_nMaxProgress;
			if ( nData == 0 )
				nData = 1;

			m_AchievementState[ playerID ][ achID ] = nData;

			NetMsg.Start( "SteamAchievements.SetAchievement" );
				NetMsg.WriteString( tag );
			NetMsg.Send( player, true );
		}

		return true;
	}

	function SteamAchievements::IndicateAchievementProgress( player, tag )
	{
		if ( !(tag in m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local playerID = m_mapID[ player ];
		local achID = _hashID(tag);
		local nData = m_AchievementState[ playerID ][ achID ];
		local ach = m_Achievements[tag];

		if ( nData >= ach.m_nMaxProgress )
			return Msg( "Achievement '"+tag+"' is already achieved, cancelled indication\n" );

		NetMsg.Start( "SteamAchievements.SetStat" );
			NetMsg.WriteString( tag );
			NetMsg.WriteLong( nData );
		NetMsg.Send( player, true );
	}

	// write cached achievement results
	function SteamAchievements::StoreStats( player )
	{
		if ( !(player in m_mapID) )
			return Warning( "Player "+player.entindex()+" is not found in ID map\n" );

		local playerID = m_mapID[ player ];
		local fileName = GetLogFileName( playerID );

		local pKV = FileToKeyValues( fileName );
		if ( !pKV )
			return Warning( "Achievement log file is missing!\n" );

		local kv = m_AchievementState[ playerID ];
		pKV.TableToSubKeys( kv );
		KeyValuesToFile( fileName, pKV );
	}

	function SteamAchievements::ClearAchievement( player, tag )
	{
		if ( !(player in m_mapID) )
			return;

		local playerID = m_mapID[ player ];
		local achID = _hashID(tag);
		m_AchievementState[ playerID ][ achID ] = 0;
	}

	local StoreOnDisconnect = function()
	{
		return SteamAchievements.StoreStats( self );
	}

	function SteamAchievements::NET_Init( player )
	{
		printf("SteamAchievements::NET_Init(%d)\n", player.entindex());

		local id = NetMsg.ReadString();
		m_mapID[ player ] <- id;
		local fileName = GetLogFileName( id );

		// init and load logs
		local pKV = FileToKeyValues( fileName );
		if ( !pKV )
		{
			pKV = CScriptKeyValues();
			pKV.SetName( "AchievementLog" );
			KeyValuesToFile( fileName, pKV );
		}

		local kv = {}
		m_AchievementState[ id ] <- kv;

		// read
		pKV.SubKeysToTable( kv );

		local count = kv.len();

		// get missing
		foreach( apiName, ach in m_Achievements )
		{
			local achID = _hashID(apiName);
			if ( achID in kv )
				continue;
			kv[ achID ] <- 0;
		}

		if ( kv.len() != count )
		{
			// write missing
			pKV.TableToSubKeys( kv );
			KeyValuesToFile( fileName, pKV );
		}

		Hooks.Add( player.GetOrCreatePrivateScriptScope(),
			"UpdateOnRemove",
			StoreOnDisconnect,
			"SteamAchievements.UpdateOnRemove" );
	}
}

if ( CLIENT_DLL )
{
	function SteamAchievements::NET_SetAchievement()
	{
		local tag = NetMsg.ReadString();

		if ( !(tag in SteamAchievements.m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		local ach = SteamAchievements.m_Achievements[tag];

		return CreateAchievementNotification_Unlocked( ach.m_rgchName, ach.m_szIconImageAchieved );
	}

	function SteamAchievements::NET_SetStat()
	{
		local tag = NetMsg.ReadString();
		local nData = NetMsg.ReadLong();

		if ( !(tag in SteamAchievements.m_Achievements) )
			return Warning( "Achievement '"+tag+"' is not found\n" );

		local ach = SteamAchievements.m_Achievements[tag];
		local img = nData == ach.m_nMaxProgress ? ach.m_szIconImageAchieved : ach.m_szIconImageUnachieved;

		return CreateAchievementNotification_Progress( nData, ach.m_nMaxProgress, ach.m_rgchName, img );
	}
}
