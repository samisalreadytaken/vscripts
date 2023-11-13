//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// Register callbacks for any key at all.
//
// server:
//		SetKeyListener( CBasePlayer player, string keyName, closure fnPressed, closure fnReleased = null )
//
// client:
//		SetKeyListener( string keyName, closure fnPressed, closure fnReleased = null )
//		KeyListener_SendInput( bool state, enum ButtonCode button )
//
//


local NetMsg = NetMsg;

local g_OnPressed = {}
local g_OnReleased = {}

local Init;

if ( SERVER_DLL )
{
	local g_KeyLookup = {}
	local bQ = true;

	local ClientRegister = function(...)
	{
		local c = g_KeyLookup.len();
		if ( c )
		{
			NetMsg.Start( "KeyListener.Reg" );
				NetMsg.WriteByte( c );
				foreach( k, v in g_KeyLookup )
				{
					NetMsg.WriteString( k );
					NetMsg.WriteBool( v[0] != null );
					NetMsg.WriteBool( v[1] != null );
				}
			NetMsg.Send( player, true );
		}
	}

	function SetKeyListener( player, keyName, fnPressed, fnReleased = null )
	{
		g_KeyLookup[ keyName.toupper() ] <- [ fnPressed, fnReleased ];

		if ( bQ )
		{
			bQ = false;
			Entities.First().SetContextThink( "KeyListener.Reg", ClientRegister, IntervalPerTick()+0.001 );
		}
	}

	Init = function(...)
	{
		NetMsg.Receive( "KeyListener.Reg", function( player )
		{
			bQ = true;

			local c = NetMsg.ReadByte();
			while ( c-- )
			{
				local button = NetMsg.ReadByte();
				local key = NetMsg.ReadString().toupper();
				if ( key in g_KeyLookup )
				{
					local callbacks = delete g_KeyLookup[ key ];

					g_OnPressed[ button ] <- callbacks[0];
					g_OnReleased[ button ] <- callbacks[1];

					printf( "KeyListener.Register: %s[%d]\n", key, button );
				}
			}
		} );

		NetMsg.Receive( "KeyListener.InputDown", function( player )
		{
			return g_OnPressed[ NetMsg.ReadByte() ]();
		} );

		NetMsg.Receive( "KeyListener.InputRelease", function( player )
		{
			return g_OnReleased[ NetMsg.ReadByte() ]();
		} );

		return Entities.First().SetContextThink( "KeyListener_", function(_)
		{
			return StopListeningToAllGameEvents( "KeyListener" );
		}, 0.1 );
	}
}

if ( CLIENT_DLL )
{
	local input = input;

	local g_KeyState = {}
	local g_ReleasedSV = {}
	local g_PressedSV = {}

	function KeyListener_SendInput( state, button )
	{
		if ( state )
		{
			if ( button in g_OnPressed )
				g_OnPressed[ button ]();

			if ( button in g_PressedSV )
			{
				NetMsg.Start( "KeyListener.InputDown" );
					NetMsg.WriteByte( button );
				return NetMsg.Send();
			}
		}
		else
		{
			if ( button in g_OnReleased )
				g_OnReleased[ button ]();

			if ( button in g_ReleasedSV )
			{
				NetMsg.Start( "KeyListener.InputRelease" );
					NetMsg.WriteByte( button );
				return NetMsg.Send();
			}
		}
	}

	function SetKeyListener( keyName, fnPressed, fnReleased = null )
	{
		local button = input.StringToButtonCode( keyName );
		if ( button <= 0 )
			return Warning( "SetKeyListener: Invalid key name '"+keyName+"'\n" );

		g_KeyState[ button ] <- false;

		if ( fnPressed )
		{
			g_OnPressed[ button ] <- fnPressed;
		}
		else if ( button in g_OnPressed )
		{
			delete g_OnPressed[button];
		}

		if ( fnReleased )
		{
			g_OnReleased[ button ] <- fnReleased;
		}
		else if ( button in g_OnPressed )
		{
			delete g_OnPressed[button];
		}

		local bind = input.BindingForKey( button );
		if ( bind )
			printf( "KeyListener.Register: %s[%d] (bind '%s')\n", keyName, button, bind );
		else
			printf( "KeyListener.Register: %s[%d]\n", keyName, button );
	}

	local KeyListenerThink = function(_)
	{
		foreach ( button, bWasDown in g_KeyState )
		{
			if ( input.IsButtonDown( button ) )
			{
				if ( !bWasDown )
				{
					g_KeyState[ button ] = true;

					if ( button in g_PressedSV )
					{
						NetMsg.Start( "KeyListener.InputDown" );
							NetMsg.WriteByte( button );
						NetMsg.Send();
					}

					if ( button in g_OnPressed )
					{
						g_OnPressed[ button ]();
					}
				}
			}
			else if ( bWasDown )
			{
				g_KeyState[ button ] = false;

				if ( button in g_ReleasedSV )
				{
					NetMsg.Start( "KeyListener.InputRelease" );
						NetMsg.WriteByte( button );
					NetMsg.Send();
				}

				if ( button in g_OnReleased )
				{
					g_OnReleased[ button ]();
				}
			}
		}
		return 0.0;
	}

	Init = function(...)
	{
		NetMsg.Receive( "KeyListener.Reg", function()
		{
			local c = NetMsg.ReadByte();
			local i = c;
			NetMsg.Start( "KeyListener.Reg" );
				NetMsg.WriteByte( c );
				while ( i-- )
				{
					local key = NetMsg.ReadString();
					local button = input.StringToButtonCode( key );
					if ( button <= 0 )
						Warning( "Invalid key name '"+key+"'\n" );

					g_KeyState[ button ] <- false;

					if ( NetMsg.ReadBool() )
						g_PressedSV[ button ] <- true;

					if ( NetMsg.ReadBool() )
						g_ReleasedSV[ button ] <- true;

					NetMsg.WriteByte( button );
					NetMsg.WriteString( key );

					local bind = input.BindingForKey( button );
					if ( bind )
						printf( "KeyListener.Register: %s[%d] (bind '%s')\n", key, button, bind );
					else
						printf( "KeyListener.Register: %s[%d]\n", key, button );
				}
			NetMsg.Send();
		} );

		Entities.First().SetContextThink( "KeyListener", KeyListenerThink, 0.1 );

		return Entities.First().SetContextThink( "KeyListener_", function(_)
		{
			return StopListeningToAllGameEvents( "KeyListener" );
		}, 0.1 );
	}
}

ListenToGameEvent( "player_spawn", Init, "KeyListener" );
Hooks.Add( this, "OnRestore", Init, "KeyListener" );

KeyListener_Init <- Init;
