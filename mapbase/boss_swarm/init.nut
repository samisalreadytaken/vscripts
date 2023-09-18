//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

{
	CONST.TICK_INTERVAL <- IntervalPerTick();
	if ( SERVER_DLL )
		CONST.MAX_PLAYERS <- MaxPlayers();

	const MASK_ALL = -1;

	CONST.vec3_origin <- Vector();
	CONST.vec3_invalid <- Vector( FLT_MAX, FLT_MAX, FLT_MAX );

	if ( !("Init" in Vector) )
		Vector.Init <- Vector.Set;

	if ( !("Copy" in Vector) )
		Vector.Copy <- Vector.Set;

	if ( !("Negate" in Vector) )
		Vector.Negate <- function()
		{
			x = -x; y = -y; z = -z;
		}

	if ( !("Replicate" in Vector) )
		Vector.Replicate <- function( f )
		{
			x = y = z = f;
		}

	if ( !("Zero" in Vector) )
		Vector.Zero <- function()
		{
			x = y = z = 0.0;
		}

	const FLT_MAX_N			= -3.402823466e+38;
	if ( !("IsValidVector" in Vector) )
		Vector.IsValidVector <- function()
		{
			return ( x > FLT_MAX_N && x < FLT_MAX ) &&
				( y > FLT_MAX_N && y < FLT_MAX ) &&
				( z > FLT_MAX_N && z < FLT_MAX );
		}
}

if ( CLIENT_DLL )
{
	local printc = printc, format = format;

	::print = function(s)
	{
		return printc( 230, 218, 115, s );
	}

	::printf = function(...)
	{
		return printc( 230, 218, 115, format.acall(vargv.insert(0,null)) );
	}
}

Assert <- assert;

function DPrint( s )
{
	if ( Convars.GetInt("developer") >= 1 )
		return print(s);
}

function DPrintf(...)
{
	if ( Convars.GetInt("developer") >= 1 )
		return print(format.acall(vargv.insert(0,null)));
}

function __typeofclass( o )
{
	local c = o;
	if ( typeof c == "instance" )
		c = c.getclass();

	foreach ( k, v in Swarm )
	{
		if ( (typeof v == "class") && (v == c) )
		{
			return k;
		}
	}

	return "unknown";
}

function ECHO_FUNC( params = "" )
{
	local level = 0;
	if ( (0 in params) && params[0] >= '0' && params[0] <= '9' )
	{
		if ( Convars.GetStr("developer")[0] < params[0] )
			return;
	}

	local si = getstackinfos(2);
	local env = si.locals["this"];
	local klass = "unknown";

	switch ( typeof env )
	{
		case "instance":
			klass = __typeofclass( env );
			break;
		case "table":
			if ( env == Swarm )
			{
				klass = "Swarm";
				break;
			}
	}

	if ( params.find("c") != null )
	{
		local si = getstackinfos(3);
		printf( "[%s()", si.func );
		printc( 255, 255, 255, format("%d", si.line) );
		printf( "] -> " );
	}

	if ( params.find("f") != null )
	{
		printf( "[%d] ", GetFrameCount() );
	}

	if ( params.find("t") != null )
	{
		printf( "[%.4f] ", Time() );
	}

	print( klass );

	if ( params.find("a") != null )
	{
		local address = env.tostring().slice( env.tostring().find( "0x" ), env.tostring().len() - 1 );
		printc( 255, 255, 255, format("[%s]", address) );
	}

	if ( params.find("p") != null )
	{
		// TODO: print parameters
	}

	printf( "::%s()\n", si.func );

	if ( params.find("s") != null )
	{
		PrintStack();
	}
}

local Init = function(...)
{
	IncludeScript( "boss_swarm/swarm.nut" );

	if ( SERVER_DLL )
	{
		if ( vargv[0] == Entities.GetLocalPlayer() )
		{
			Swarm.ServerInit();
		}

		Swarm.Init( vargv[0] );
	}
	else // CLIENT_DLL
	{
		Swarm.Init();
	}
}

ListenToGameEvent( "player_spawn", function( event )
{
	if ( SERVER_DLL )
	{
		Init( GetPlayerByUserID( event.userid ) );
	}
	else // CLIENT_DLL
	{
		Init();
		Entities.First().SetContextThink( "Swarm", function(_) { StopListeningToAllGameEvents( "Swarm" ); }, 0.01 );
	}
}, "Swarm" );


if ( !("GetPlayerByUserID" in this) )
{
	function GetPlayerByUserID(i)
	{
		for ( local p; p = Entities.FindByClassname( p, "player" ); )
			if ( p.GetUserID() == i )
				return p;
	}
}
