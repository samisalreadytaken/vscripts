//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//

enum SwarmInput
{
	FORWARD = 8,
	LEFT = 128,
	RIGHT = 256,
	BACK = 16,
	JUMP = 2,
	ATTACK = 1,
	ATTACK2 = 2048,
	USE = 32,
	RELOAD = 8192,
	INVENTORY = 65536,
}

// After adding a new item: V][^A
// After removing an item:  V][^X
enum SwarmEquipment
{
	None = 0,

	WEAPON_START = 1,
		BasicGun = 1,
		Shotgun = 2,
		BurstGun = 3,
	WEAPON_END = 3,

		Blast = 4,

	ITEM_START = 5,
		Shield = 5,
		ExtraLife = 6,
		DamageBoost = 7,
		FastShoot = 8,
		SpeedBoost = 9,
		Penetration = 10,
		NoReload = 11,
	ITEM_END = 11,

	//Test = 12,
	MAX = 12
}

Assert( SwarmEquipment.MAX < 256 );

// TODO: Make these dynamic
const MAX_SLOTS = 3;
const MAX_ITEMS = 4;
const MAX_ITEM_OFFERS = 6;

const NULL_SLOT = 255; // (byte)-1

// HACKHACK
const ALT_WEP_SLOT = 250;

const BIG_BOSS_INTRO_HOLD_TIME = 0.25;
const BIG_BOSS_INTRO_TRANS_TIME = 1.35;

local Time = Time, NetMsg = NetMsg;

if ( SERVER_DLL )
{
	Swarm <-
	{
		m_Players = []
		m_PlayerMap = {}
		m_HurtableEntities = []
		m_Projectiles = []
		m_Pickups = []
		m_hBigBoss = null

		m_EquipmentMap = array( SwarmEquipment.MAX )

		m_EE = false
	}

	local g_Time = ::Time;
	local s_curtime = g_Time();
	function Swarm::Time()
	{
		return s_curtime;
	}

	function PrecacheSoundScript( sound )
	{
		return Entities.First().PrecacheSoundScript( sound );
	}

	IncludeScript( "boss_swarm/snd.nut", Swarm );
	IncludeScript( "boss_swarm/object.nut", Swarm );
	IncludeScript( "boss_swarm/baseweapon.nut", Swarm );
	IncludeScript( "boss_swarm/weapon_basic.nut", Swarm );
	IncludeScript( "boss_swarm/weapon_shotgun.nut", Swarm );
	IncludeScript( "boss_swarm/weapon_burstgun.nut", Swarm );
	IncludeScript( "boss_swarm/weapon_blast.nut", Swarm );
	IncludeScript( "boss_swarm/items.nut", Swarm );
	IncludeScript( "boss_swarm/item_pickup.nut", Swarm );
	IncludeScript( "boss_swarm/player.nut", Swarm );
	IncludeScript( "boss_swarm/enemy_bigboss.nut", Swarm );

	function Swarm::ServerInit()
	{
		// Ensure player input is received every server frame
		// FIXME: Input feels delayed
		Entities.First().SetContextThink( "Swarm.QueryPlayers", function(_)
		{
			s_curtime = g_Time();

			local basePlayer = m_Players[0].m_pBasePlayer;
			{
				NetMsg.Start( "Swarm.QueryPlayers" );
				NetMsg.Send( basePlayer, true );
			}

			SoundFrame();

			return 0.0;
		}.bindenv(this), 0.0 );

		NetMsg.Receive( "Swarm.UserInput", function( basePlayer )
		{
			local player = m_PlayerMap[ basePlayer ];

			player.m_Buttons = NetMsg.ReadLong();

			local vecCursorRay = player.m_vecCursorRay;
			vecCursorRay.x = NetMsg.ReadFloat();
			vecCursorRay.y = NetMsg.ReadFloat();
			vecCursorRay.z = NetMsg.ReadFloat();

			local slot = NetMsg.ReadByte();
			if ( slot != NULL_SLOT )
			{
				player.SelectSlot( slot );
			}
		}.bindenv(this) );

		NetMsg.Receive( "Swarm.ClientAck", ClientReady.bindenv(this) );
		NetMsg.Receive( "Swarm.ResetGame", ResetGame.bindenv(this) );
		NetMsg.Receive( "Swarm.AcceptOffer", NET_AcceptOffer.bindenv(this) );
		NetMsg.Receive( "Swarm.RefundEquipment", NET_RefundEquipment.bindenv(this) );

		NetMsg.Receive( "ClientCommand", function( basePlayer )
		{
			SendToConsole( NetMsg.ReadString() );
		} );

		Convars.RegisterConvar( "swarm_debugdraw", "0", "", FCVAR_REPLICATED|FCVAR_GAMEDLL );
		Convars.RegisterCommand( "swarm_god", function(...)
		{
			local basePlayer = Convars.GetCommandClient();
			local player = m_PlayerMap[ basePlayer ];
			player.m_bGodMode = !player.m_bGodMode;

			printf( "god mode %d\n", player.m_bGodMode );
		}.bindenv(this), "", FCVAR_GAMEDLL|FCVAR_CHEAT );
	}

	function Swarm::Init( basePlayer )
	{
		if ( !basePlayer )
			return;

		if ( basePlayer in m_PlayerMap )
			return Warning( "Player was already registered!\n" );

		basePlayer.SetSolid( 0 );
		basePlayer.AddSolidFlags( FSOLID_NOT_SOLID );
		basePlayer.SetMoveType( MOVETYPE_NONE );
		basePlayer.DisableButtons( -1 );

		CPlayer( basePlayer );

		basePlayer.SetContextThink( "ACH_PLAYTIME15", function( basePlayer )
		{
			if ( SteamAchievements.GetAchievement( basePlayer, "ACH_PLAYTIME15" ) )
				return -1;

			SteamAchievements.IncrementStat( basePlayer, "ACH_PLAYTIME15", 10.0 );
			return 10.0;
		}, 10.0 );


		local alternateticks = Convars.GetInt( "sv_alternateticks" );
		Convars.SetInt( "sv_alternateticks", 1 );

		local tm = ::time();
		Hooks.Add( basePlayer.GetOrCreatePrivateScriptScope(), "UpdateOnRemove", function()
		{
			Convars.SetInt( "sv_alternateticks", alternateticks );

			local s = ::time() - tm;
			local m = s / 60;
			s -= m * 60;
			local h = m / 60;
			m -= h * 60;
			if ( h )
				printf( "Session length: %dh%dm%ds\n", h, m, s );
			else
				printf( "Session length: %dm%ds\n", m, s );
		}, "Swarm" );
	}

	function Swarm::ClientReady( basePlayer )
	{
		local t = { rainbow = 0 }
		RestoreTable( "Swarm.EE", t );
		if ( t.rainbow )
		{
			// Reset, only turn it on in redirect from the background map.
			t.rainbow = 0;
			SaveTable( "Swarm.EE", t );

			m_EE = true;
			NetMsg.Start( "Swarm.EE" );
			NetMsg.Send( basePlayer, true );

			local player = m_PlayerMap[ basePlayer ];
			player.m_pEntity.SetModel( "swarm/player2_rainbow.vmt" );
		}
		StartSpawnRoom( basePlayer );
	}

	function Swarm::CountItemTypeInOffers( list, id )
	{
		local i = 0;
		foreach ( item in list )
			item && (item.m_ID == id) && ++i;
		return i;
	}

	function Swarm::GetNewOffer( player, ignore = 0 )
	{
		local id = 0;
		do
		{
			id = RandomInt( SwarmEquipment.ITEM_START, SwarmEquipment.ITEM_END );
		} while ( id == ignore );

		// Offer limits
		switch ( id )
		{
			case SwarmEquipment.Shield:
			case SwarmEquipment.SpeedBoost:
				if ( CountItemTypeInOffers( player.m_ItemOffers, id ) >= 1 )
				{
					return GetNewOffer( player, id );
				}
				break;
			case SwarmEquipment.NoReload:
				if ( CountItemTypeInOffers( player.m_ItemOffers, id ) >= 2 )
				{
					return GetNewOffer( player, id );
				}
				break;
		}

		return id;
	}

	function Swarm::OfferNewItems( player )
	{
		NetMsg.Start( "Swarm.OfferNewItems" );
		foreach ( idx, elem in player.m_ItemOffers )
		{
			local id = GetNewOffer( player );
			local item = m_EquipmentMap[ id ]( player );
			NetMsg.WriteByte( id );
			item.NET_WriteData();
			player.m_ItemOffers[idx] = item;
			item.m_iSlot = idx;
		}
		NetMsg.Send( player.m_pBasePlayer, true );
	}

	function Swarm::NET_AcceptOffer( basePlayer )
	{
		local player = m_PlayerMap[ basePlayer ];

		local idx = NetMsg.ReadByte();
		local item = player.m_ItemOffers[idx];
		player.m_ItemOffers[idx] = null;
		player.EquipItem( item, true );
	}

	function Swarm::NET_RefundEquipment( basePlayer )
	{
		local player = m_PlayerMap[ basePlayer ];

		local idx = NetMsg.ReadByte();
		local item = player.m_Items[idx];
		item.Deactivate();
		player.m_Items[idx] = null;
		player.m_ItemOffers[ item.m_iSlot ] = item;

		local ordercache = player.m_ItemOrderCache.find( idx );
		if ( ordercache != null )
		{
			player.m_ItemOrderCache.remove( ordercache );
		}

		NetMsg.Start( "Swarm.UpdateItemOffer" );
			NetMsg.WriteByte( item.m_iSlot );
			NetMsg.WriteByte( item.m_ID );
			item.NET_WriteData();
		NetMsg.Send( basePlayer, true );

		// Update equipment to reset clientside modifiers
		// This could be more efficient though.
		player.UpdateEquipment();
	}

	function Swarm::StartSpawnRoom( basePlayer )
	{
		for ( local i = m_Pickups.len(); i--; )
		{
			m_Pickups[i].Destroy();
		}
		m_Pickups.clear();

		local trigger = Entities.FindByName( null, ".boss_door_trigger" );
		trigger.Enable();
		Entities.FindByName( null, ".boss_door" ).AcceptInput( "Disable", "", null, null );
		Entities.FindByName( null, ".spawn_room_shadow" ).AcceptInput( "Disable", "", null, null );
		trigger.SetContextThink( "", SpawnRoomTriggerThink.bindenv(this), 0.0 );

		local player = m_PlayerMap[ basePlayer ];
		player.m_Buttons = 0;
		player.Spawn();
		player.SetPosition( Vector( 0, 128, 0 ) );
		player.EquipWeapon( SwarmEquipment.BasicGun );
		player.EquipAltWeapon( SwarmEquipment.Blast );
		OfferNewItems( player );

		// TODO: offer weapons!
		local item1 = 0, item2 = 0;

		local weaponCache = array( MAX_SLOTS, 0 );
		weaponCache[0] = SwarmEquipment.BasicGun;

		do
		{
			item1 = RandomInt( SwarmEquipment.WEAPON_START, SwarmEquipment.WEAPON_END );
		} while ( weaponCache.find( item1 ) != null );
		weaponCache[1] = item1;
		do
		{
			item2 = RandomInt( SwarmEquipment.WEAPON_START, SwarmEquipment.WEAPON_END );
		} while ( weaponCache.find( item2 ) != null );
		weaponCache[2] = item1;

		player.EquipItem( item1 );
		player.EquipItem( item2 );

		// Delay a bit so player doesn't see the teleport
		basePlayer.SetContextThink( "SpawnRoomStart", function( basePlayer )
		{
			NetMsg.Start( "Swarm.SpawnRoomStart" );
			NetMsg.Send( basePlayer, true );
		}, 0.25 );
	}

	function Swarm::StartGame()
	{
		local player = m_Players[0];
		player.m_ItemOffers.clear();
		player.m_ItemOffers.resize( MAX_ITEM_OFFERS );
		// HACKHACK: Force reload since it takes long
		if ( player.m_AltWeapon )
		{
			player.m_AltWeapon.m_bInReload = false;
			player.m_AltWeapon.m_flNextAttackTime = Time();
			player.m_AltWeapon.m_nClip = player.m_AltWeapon.m_nMaxClip;
		}

		m_hBigBoss = CBigBoss( Entities.FindByName( null, ".bigboss_spawn" ).GetOrigin() );

		player.StartCutsceneBigBoss( StartGamePostCutscene.bindenv(this) );

		NetMsg.Start( "Swarm.GameStart" );
		NetMsg.Send( player.m_pBasePlayer, true );
	}

	function Swarm::StartGamePostCutscene()
	{
		local player = m_Players[0];

		player.m_vecVelocity.x += 500.0;
		player.m_vecPosition.y += 32.0;

		Entities.FindByName( null, ".boss_door" ).AcceptInput( "Enable", "", null, null );

		local shadow = Entities.FindByName( null, ".spawn_room_shadow" );
		shadow.AcceptInput( "Enable", "", null, null );
		shadow.SetRenderMode( 2 );
		shadow.SetRenderAlpha( 0 );
		local starttime = Time();
		shadow.SetContextThink( "FadeIn", function(self)
		{
			local a = 225 * (Time() - starttime);
			if ( a > 225 )
				return -1;
			self.SetRenderAlpha( a );
			return 0.0;
		}, 0.0 );

		m_hBigBoss.Spawn();
	}

	function Swarm::ResetGame( basePlayer )
	{
		for ( local i = m_Projectiles.len(); i--; )
		{
			local p = m_Projectiles[i];
			p.Destroy();
		}

		if ( m_hBigBoss )
		{
			m_hBigBoss.Destroy();
			m_hBigBoss = null;
		}

		StartSpawnRoom( basePlayer );
	}

	function Swarm::SpawnRoomTriggerThink( self )
	{
		local player = m_Players[0];
		{
			if ( self.PointIsWithin( player.m_vecPosition ) )
			{
				self.Disable();
				StartGame();
				return -1;
			}
		}
		return 0.0;
	}
} // SERVER_DLL

if ( CLIENT_DLL )
{
	Swarm <-
	{
		[0] = false
		m_Cursor = null

		m_pHUD = null
		m_pControls = null
		m_ToolTipHudElements = []
		m_ItemOffers = array( MAX_ITEM_OFFERS )
		m_EquipmentDisplay = []

		//m_pTooltip = null
		m_hTooltipFont = 0
		m_hControlsFont = 0

		m_pLetterBox = null
		m_iHeartTex = 0

		m_flBossHealth = 0.0
		m_flBossShield = 0.0

		m_nHealth = 0
		m_nMaxHealth = 0

		m_AltWeapon = null
		m_Items = array( MAX_ITEMS )
		m_Slots = array( MAX_SLOTS )
		m_iActiveSlot = 0
		m_iSlotSelection = NULL_SLOT

		m_EquipmentMap = array( SwarmEquipment.MAX )
		m_EquipmentTextureMap = array( SwarmEquipment.MAX )

		m_pAperture = null
		m_pEntity = null

		m_flFadeStartTime = 0.0
		m_flFadeFadeTime = 0.0
		m_fnFadeCallback = null
		m_bFadeIn = false

		m_flCutsceneStartTime = 0.0
		m_flCutsceneHoldTime = 0.0
		m_flCutsceneTransTime = 0.0
		m_bCutsceneIn = true

		m_EE = false
		m_SessionData = { deathcount = 0 }
	}

	enum SwarmEquipmentStatus
	{
		Inactive = 0x0,
		Active = 0x1,
		Reloading = 0x2
	}

	class Swarm.item_t
	{
		id = SwarmEquipment.None;
		status = SwarmEquipmentStatus.Inactive;
		modifiers = 0;
		rarity = 0;
		reload_time = 0.0;
		reload_end_time = 0.0;
		tooltip = "";

		function Reset()
		{
			local item_t = getclass();
			id = item_t.id;
			status = item_t.status;
			modifiers = item_t.modifiers;
			rarity = item_t.rarity;
			reload_time = item_t.reload_time;
			reload_end_time = item_t.reload_end_time;
			tooltip = item_t.tooltip;
		}
	}

	Swarm.m_EquipmentTextureMap[SwarmEquipment.BasicGun] = "swarm/hud_weapon_test";
	Swarm.m_EquipmentTextureMap[SwarmEquipment.Shotgun] = "swarm/hud_weapon_test";
	Swarm.m_EquipmentTextureMap[SwarmEquipment.BurstGun] = "swarm/hud_weapon_test";
	Swarm.m_EquipmentTextureMap[SwarmEquipment.Blast] = "swarm/hud_weapon_blast";
	Swarm.m_EquipmentTextureMap[SwarmEquipment.DamageBoost] = "swarm/item_damage";
	Swarm.m_EquipmentTextureMap[SwarmEquipment.SpeedBoost] = "swarm/item_speed";
	Swarm.m_EquipmentTextureMap[SwarmEquipment.Penetration] = "swarm/item_penetration";
	Swarm.m_EquipmentTextureMap[SwarmEquipment.Shield] = "swarm/item_shield";
	Swarm.m_EquipmentTextureMap[SwarmEquipment.ExtraLife] = "swarm/item_extralife";
	Swarm.m_EquipmentTextureMap[SwarmEquipment.FastShoot] = "swarm/item_fastshoot";
	Swarm.m_EquipmentTextureMap[SwarmEquipment.NoReload] = "swarm/item_noreload";

	IncludeScript( "boss_swarm/cursor.nut", Swarm );
	IncludeScript( "boss_swarm/hud.nut", Swarm );

	IncludeScript( "boss_swarm/weapon_basic.nut", Swarm );
	IncludeScript( "boss_swarm/weapon_shotgun.nut", Swarm );
	IncludeScript( "boss_swarm/weapon_burstgun.nut", Swarm );
	IncludeScript( "boss_swarm/weapon_blast.nut", Swarm );
	IncludeScript( "boss_swarm/items.nut", Swarm );

	function Swarm::GetRootPanel()
	{
		return vgui.GetClientDLLRootPanel();
	}

	function Swarm::Init()
	{
		if ( this[0] )
			return;
		this[0] = true;

		SteamAchievements.RequestCurrentStats();

		Convars.RegisterCommand( "save", Save, "", FCVAR_CLIENTDLL );
		Convars.RegisterCommand( "load", Save, "", FCVAR_CLIENTDLL );

		RestoreTable( "SwarmSession", m_SessionData );

		foreach ( i, v in m_Slots )
			m_Slots[i] = item_t();

		foreach ( i, v in m_Items )
			m_Items[i] = item_t();

		m_AltWeapon = item_t();

		m_Cursor = CCursor();
		m_Cursor.Init();

		InitHUD();
		SendToConsole( "r_screenoverlay swarm/vignette" );

		input.SetCursorPos( XRES(320), YRES(210) );

		NetMsg.Receive( "Swarm.EE", function()
		{
			Swarm.m_EE = true;
		} );
		NetMsg.Receive( "Swarm.QueryPlayers", function() { UserInput(null); }.bindenv(this) );
		NetMsg.Receive( "Swarm.OfferNewItems", OfferNewItems.bindenv(this) );
		NetMsg.Receive( "Swarm.UpdateItemOffer", UpdateItemOffer.bindenv(this) );
		NetMsg.Receive( "Swarm.CPlayer.Reload", WeaponReload.bindenv(this) );
		NetMsg.Receive( "Swarm.CPlayer.Update", PlayerUpdate.bindenv(this) );
		NetMsg.Receive( "Swarm.CPlayer.UpdateEquipment", PlayerUpdateEquipment.bindenv(this) );
		NetMsg.Receive( "Swarm.CPlayer.SelectSlot", NET_SelectSlot.bindenv(this) );
		NetMsg.Receive( "Swarm.CPlayer.OnDeath", PlayerOnDeath.bindenv(this) );
		NetMsg.Receive( "Swarm.CBigBoss.Update", BigBossUpdate.bindenv(this) );
		NetMsg.Receive( "Swarm.CBigBoss.Dead", BigBossDead.bindenv(this) );
		NetMsg.Receive( "Swarm.GameStart", GameStart.bindenv(this) );
		NetMsg.Receive( "Swarm.SpawnRoomStart", SpawnRoomStart.bindenv(this) );
		NetMsg.Receive( "Swarm.CutsceneBigBossIntro", CutsceneBigBossIntro.bindenv(this) );

		Convars.RegisterConvar( "swarm_drawtime", "1", "", FCVAR_CLIENTDLL );
		Convars.SetChangeCallback( "swarm_drawtime", function(...)
		{
			Swarm.m_Cursor.m_bDrawTime = Convars.GetBool( "swarm_drawtime" );
		} );

		NetMsg.Start( "Swarm.ClientAck" );
		NetMsg.Send();
	}

	function Swarm::CutsceneBigBossIntro()
	{
		m_flCutsceneStartTime = Time();
		m_flCutsceneHoldTime = BIG_BOSS_INTRO_HOLD_TIME;
		m_flCutsceneTransTime = BIG_BOSS_INTRO_TRANS_TIME;
		m_bCutsceneIn = true;

		m_pLetterBox.SetVisible( true );
	}

	function Swarm::PlayerOnDeath()
	{
		m_SessionData.deathcount += 1;
		SaveTable( "SwarmSession", m_SessionData );
		FadeAndResetGame( 1.5, 0.5 );
	}

	function Swarm::FadeAndResetGame( time = 1.0, delay = 0.0 )
	{
		ApertureFade( false, time, delay, ResetGame );
	}

	function Swarm::ResetGame()
	{
		NetMsg.Start( "Swarm.ResetGame" );
		NetMsg.Send();
	}

	function Swarm::SpawnRoomStart()
	{
		ApertureFade( true, 1.0, 0.0, null );
		m_Cursor.m_pMenu.SetVisible( true );
		m_Cursor.m_Input = 0;
		m_Cursor.m_pDeathCount.SetText( format( "Deaths: %d", m_SessionData.deathcount ) );
		m_flBossHealth = m_flBossShield = 0.0;
	}

	function Swarm::OfferNewItems()
	{
		foreach ( idx, elem in m_ItemOffers )
		{
			elem.self.SetVisible( true );
			elem.m_item.Reset();
			elem.m_item.id = NetMsg.ReadByte();
			m_EquipmentMap[ elem.m_item.id ].NET_ReadDataIntoItem( elem.m_item );
		}

		foreach ( elem in m_EquipmentDisplay )
		{
			elem.self.SetVisible( true );
		}
	}

	function Swarm::UpdateItemOffer()
	{
		local idx = NetMsg.ReadByte();
		local elem = m_ItemOffers[idx];
		elem.m_item.Reset();
		elem.m_item.id = NetMsg.ReadByte();
		m_EquipmentMap[ elem.m_item.id ].NET_ReadDataIntoItem( elem.m_item );
	}

	function Swarm::GameStart()
	{
		// Show the controls only once
		if ( m_pControls )
		{
			m_pControls.Destroy();
			m_pControls = null;
		}

		m_Cursor.m_pMenu.SetVisible( false );

		foreach ( elem in m_ItemOffers )
		{
			elem.self.SetVisible( false );
		}

		foreach ( elem in m_EquipmentDisplay )
		{
			if ( !elem.m_item.id )
				elem.self.SetVisible( false );
		}

		// HACKHACK: Force reload since it takes long
		if ( m_AltWeapon )
		{
			m_AltWeapon.reload_end_time = 0.0;
		}
	}

	function Swarm::PlayerUpdate()
	{
		m_nMaxHealth = NetMsg.ReadByte();
		m_pEntity = NetMsg.ReadEntity();
	}

	function Swarm::PlayerUpdateEquipment()
	{
		// FIXME: Resets reload status!
		m_AltWeapon.Reset();
		m_AltWeapon.id = NetMsg.ReadByte();
		if ( m_AltWeapon.id )
		{
			m_AltWeapon.status = SwarmEquipmentStatus.Active;
			m_EquipmentMap[ m_AltWeapon.id ].NET_ReadDataIntoItem( m_AltWeapon );
		}

		foreach ( i, item in m_Slots )
		{
			local id = NetMsg.ReadByte();
			item.id = id;
			if ( id )
			{
				item.modifiers = NetMsg.ReadByte();
				m_EquipmentMap[ id ].NET_ReadDataIntoItem( item );
			}
		}

		foreach ( i, item in m_Items )
		{
			item.Reset();
			local id = NetMsg.ReadByte();
			item.id = id;
			if ( id )
			{
				m_EquipmentMap[ id ].NET_ReadDataIntoItem( item );
			}
		}

		return NET_SelectSlot();
	}

	function Swarm::BigBossUpdate()
	{
		m_flBossHealth = NetMsg.ReadNormal();
		m_flBossShield = NetMsg.ReadNormal();
	}

	function Swarm::BigBossDead()
	{
		m_flBossHealth = m_flBossShield = 0.0;

		local panel = vgui.CreatePanel( "Label", m_pHUD, "" );
		panel.MakeReadyForUse();
		panel.SetVisible( true );
		panel.SetPaintEnabled( true );
		panel.SetPaintBackgroundEnabled( true );
		panel.SetPaintBackgroundType( 2 );
		panel.SetSize( YRES(84), YRES(42) );
		panel.SetPos( XRES(320) - panel.GetWide() / 2, YRES(240) - panel.GetTall() / 2 );
		panel.SetFgColor( 255, 255, 255, 255 );
		panel.SetBgColor( 0, 0, 0, 200 );
		panel.SetContentAlignment( Alignment.center );
		panel.SetFont( surface.GetFont( "InstructorTitle", true, "ClientScheme" ) );
		panel.SetText( "you win" );

		return FadeToDisconnect( 2.5, 1.5 );
	}

	function Swarm::FadeToDisconnect( time, delay )
	{
		return ApertureFade( false, time, delay, function()
		{
			SendToConsole( "disconnect;map_background background_boss_swarm_a" );
		} );
	}

	function Swarm::WeaponReload()
	{
		local slot = NetMsg.ReadByte();
		local item;

		if ( slot == ALT_WEP_SLOT )
		{
			item = m_AltWeapon;
		}
		else
		{
			item = m_Slots[slot];
		}

		// HUD clears this flag
		item.status = item.status | SwarmEquipmentStatus.Reloading;
		local flReloadTime = NetMsg.ReadFloat();
		item.reload_time = flReloadTime;
		item.reload_end_time = Time() + flReloadTime;
	}

	function Swarm::NET_SelectSlot()
	{
		return SelectSlot( NetMsg.ReadByte() );
	}

	function Swarm::SelectSlot( slot )
	{
		if ( m_iActiveSlot == slot )
			return;

		local item = m_Slots[m_iActiveSlot];
		item.status = item.status & ~(SwarmEquipmentStatus.Active);

		m_iSlotSelection = slot;
		m_iActiveSlot = slot;

		item = m_Slots[slot];
		item.status = item.status | SwarmEquipmentStatus.Active;

		player.EmitSound( "Player.WeaponSelected" );
	}

	function Swarm::SelectSlot0()
	{
		local item = m_Slots[0];
		if ( item.id != SwarmEquipment.None )
			return SelectSlot( 0 );
	}

	function Swarm::SelectSlot1()
	{
		local item = m_Slots[1];
		if ( item.id != SwarmEquipment.None )
			return SelectSlot( 1 );
	}

	function Swarm::SelectSlot2()
	{
		local item = m_Slots[2];
		if ( item.id != SwarmEquipment.None )
			return SelectSlot( 2 );
	}

	function Swarm::SelectSpecial1()
	{
	}

	function Swarm::UserInput(_)
	{
		NetMsg.Start( "Swarm.UserInput" );

		local buttons = m_Cursor.m_Input;
		NetMsg.WriteLong( buttons );
		m_Cursor.m_Input = buttons & ~(SwarmInput.USE | SwarmInput.ATTACK2);

		local vecCursor = ScreenToRay( m_Cursor.m_x, m_Cursor.m_y );
		if ( !vecCursor.z )
		{
			Warning(format( "INVALID CURSOR RAY %d %d (%s) (%s)\n",
				m_Cursor.m_x, m_Cursor.m_y, vecCursor.ToKVString(), CurrentViewOrigin().ToKVString() ));
			vecCursor.Init( 0, 0, -1 );
		}

		NetMsg.WriteFloat( vecCursor.x );
		NetMsg.WriteFloat( vecCursor.y );
		NetMsg.WriteFloat( vecCursor.z );

		NetMsg.WriteByte( m_iSlotSelection );
		m_iSlotSelection = NULL_SLOT;

		NetMsg.Send();

		return TICK_INTERVAL;
	}

	function Swarm::Save(...)
	{
		Msg("Saves are disabled.\n");
	}

	function SendToConsole( str )
	{
		NetMsg.Start( "ClientCommand" );
			NetMsg.WriteString( str );
		return NetMsg.Send();
	}
} // CLIENT_DLL


Swarm.m_EquipmentMap[SwarmEquipment.BasicGun] = Swarm.CWeapon_Basic;
Swarm.m_EquipmentMap[SwarmEquipment.Shotgun] = Swarm.CWeapon_Shotgun;
Swarm.m_EquipmentMap[SwarmEquipment.BurstGun] = Swarm.CWeapon_BurstGun;
Swarm.m_EquipmentMap[SwarmEquipment.Blast] = Swarm.CWeapon_Blast;
Swarm.m_EquipmentMap[SwarmEquipment.DamageBoost] = Swarm.CItemDamageBoost;
Swarm.m_EquipmentMap[SwarmEquipment.SpeedBoost] = Swarm.CItemSpeedBoost;
Swarm.m_EquipmentMap[SwarmEquipment.Penetration] = Swarm.CItemPenetration;
Swarm.m_EquipmentMap[SwarmEquipment.Shield] = Swarm.CItemShield;
Swarm.m_EquipmentMap[SwarmEquipment.ExtraLife] = Swarm.CItemExtraLife;
Swarm.m_EquipmentMap[SwarmEquipment.FastShoot] = Swarm.CItemFastShoot;
Swarm.m_EquipmentMap[SwarmEquipment.NoReload] = Swarm.CItemNoReload;


// Assertion
foreach ( i, v in Swarm.m_EquipmentMap )
	if ( i && !v )
		throw "Missing Equipment " + i;

if ( CLIENT_DLL ){
foreach ( i, v in Swarm.m_EquipmentTextureMap )
	if ( i && !v )
		throw "Missing Equipment Texture " + i;
}



function Swarm::EquipmentEnumToString( val )
{
	foreach ( k, v in CONST.SwarmEquipment )
	{
		if ( v == val && k.find("_START") == null && k.find("_END") == null )
		{
			return k;
		}
	}
}
