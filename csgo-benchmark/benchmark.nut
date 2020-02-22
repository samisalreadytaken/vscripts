//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------

//
// This thing became a real mess. But it still works.
//

IncludeScript("vs_library");

class V
{
	constructor(_x=0,_y=0,_z=0)
	{
		x = _x;
		y = _y;
		z = _z;
	}

	function V(dx=0,dy=0,dz=0)return::Vector(x+dx,y+dy,z+dz);

	x = 0.0;
	y = 0.0;
	z = 0.0;
}

IncludeScript("benchmark_res");

if(!("__R"in::getroottable()))::__R<-false;;if(::__R)delete::__R;else{local _=function(){};::__R=true;return::DoIncludeScript(_.getinfos().src,this)};;

const FTIME = 0.015625;;

SendToConsole("alias benchmark\"script _d83bS1t4a7ef()\";alias bm_stop\"script _d83bSlt4a7ef()\";alias bm_rec\"script _db3b51t4a7ef()\";alias bm_play\"script _d83bS1t4a7ef(1)\";alias bm_show\"script _d83b5lt4alef()\";alias bm_save\"script _dBeb5lta47ef()\";alias bm_trim\"script _db3b51tAa7ef(0,0)\";alias bm_trim_undo\"script _db3b51tAa7ef(1,0)\";alias bm_setup\"script _d8bb5ltAa7ef()\";alias bm_timer\"script _dBebSlt4a73f()\";alias bm_list\"script _d88bSlt4a7ef()\";alias bm_clear\"script _dB8d5lt4a7ef()\";alias bm_remove\"script _dB8b5lt4a7ef()\"");

SendToConsole("alias bm_mdl\"script _d8Bb51t4a7ef()\";alias bm_mdl1\"script _d8Bb51t4a7ef(1)\";alias bm_flash\"script _d8Bp51t4a7ef()\";alias bm_flash1\"script _d8Bp51t4a7ef(1)\";alias bm_he\"script _dB8d51t4a7ef()\";alias bm_he1\"script _dB8d51t4a7ef(1)\";alias bm_molo\"script _dBBb5lt4a7ef()\";alias bm_molo1\"script _dBBb5lt4a7ef(1)\";alias bm_smoke\"script _d88b5lt4a7ef()\";alias bm_smoke1\"script _d88b5lt4a7ef(1)\";alias bm_expl\"script _d88b51t4aTef()\";alias bm_expl1\"script _d88b51t4aTef(1)\"\"");

SendToConsole("clear;script OnPostSpawn()");

VS.GetLocalPlayer();

// bRecording
if( !("_d83bS1ta47ef" in this) ) _d83bS1ta47ef <- false;;

// bRecordingPending
if( !("_d83bS1t4a73f" in this) ) _d83bS1t4a73f <- false;;

// sec timer enabled
if( !("_d8bb5lta47ef" in this) ) _d8bb5lta47ef <- false;;

// bStarted
if( !("_d83bS1ta4Tef" in this) ) _d83bS1ta4Tef <- false;;

// bStartedPending
if( !("_d83bSl7a4Tef" in this) ) _d83bSl7a4Tef <- false;;

// trimmed
if( !("_d83Bb517a47ef" in this) ) _d83Bb517a47ef <- false;;

_dB3bS1ta47ef <- null;
_dB3b5lta47ef <- null;
_dBebS1t4a7ef <- 0;
_d83b51ta47ef <- 0;
_d8ebSlta4Tef <- 0;
_d8ebSlta47ef <- 0;
_dB3bSlta47ef <- 0.0;

fTickrate <- VS.GetTickrate();
sMapName <- split(GetMapName(),"/").top();

// lists
if( !("_d8BbSlt4a7ef" in this) ) _d8BbSlt4a7ef <- [];;
if( !("_d8BdSlt4a7ef" in this) ) _d8BdSlt4a7ef <- [];;
// nRecLast
if( !("_d8Bd5lt4a7ef" in this) ) _d8Bd5lt4a7ef <- -1;;

local _ = function()
{
	if( !("_d8ebS1ta4Tef" in this) || !Ent("_d8ebS1ta4Tef") )
	{
		_d8ebS1ta4Tef <- VS.CreateEntity( "game_player_equip", "_d8ebS1ta4Tef", {spawnflags = 2} );
		VS.MakePermanent( _d8ebS1ta4Tef );
	};

	if( !("_d83bSlta47ef" in this) || !Ent("_d83bSlta47ef") )
	{
		_d83bSlta47ef <- VS.CreateTimer( "_d83bSlta47ef", FTIME, 0, 0, 0, 1 );
		VS.MakePermanent( _d83bSlta47ef );
	};

	if( !("_d83bSlta4lef" in this) || !Ent("_d83bSlta4lef") )
	{
		_d83bSlta4lef <- VS.CreateHudHint( "_d83bSlta4lef" );
		VS.MakePermanent( _d83bSlta4lef );
	};

	if( !("HPlayerEye" in this) || !Ent("vs_ref_*") )
		HPlayerEye <- VS.CreateMeasure(HPlayer.GetName(),null,true);

	if( !("_d83b5lt4a7ef" in this) || !Ent("_d83b5lt4a7ef") )
	{
		_d83b5lt4a7ef <- VS.CreateEntity( "point_viewcontrol", "_d83b5lt4a7ef", { spawnflags = 8 } );
		VS.MakePermanent( _d83b5lt4a7ef );
	};

	if( !Ent("_d83b5l7a4Tef") )
	{
		VS.OnTimer( VS.CreateTimer( "_d83b5l7a4Tef", 1, 0, 0, 0, 1 ), _dBebSlt4a7ef );
		VS.MakePermanent( Ent("_d83b5l7a4Tef") );
	};

	// EntFireByHandle( _d83b5lt4a7ef, "disable", "", 0, HPlayer );
	// EntFireByHandle( _d83bSlta47ef, "disable" );
	// EntFire( "_d83b5l7a4Tef", "disable" );
}

::Msg <-::printl;

function OnPostSpawn()
{
	if( HPlayer.GetTeam() != 2 && HPlayer.GetTeam() != 3 ) HPlayer.SetTeam(2);

	PlaySound("Player.DrownStart");

	_ProcessData();

	ClearChat();
	ClearChat();
	Chat( txt.blue+" -------------------------------- " );
	Chat( " " );
	Chat( txt.lightgreen + "[Benchmark Script] "+txt.lightblue+"Loaded" );
	Chat( txt.orange + "● "+txt.grey+"Instructions are printed onto the console." );
	Chat( txt.orange + "● " + txt.grey +"Server tickrate: " + txt.yellow + fTickrate );
	Chat( " " );
	Chat( txt.blue+" -------------------------------- " );

	// print after Steamworks Msg
	if( GetDeveloperLevel() > 0 ) delay("SendToConsole(\"clear;script _d88bSlt4aTef()\")", 0.75);
	else _d88bSlt4aTef();
}

function PlaySound(s)
{
	HPlayer.EmitSound(s);
}

// todo: refactor
function _ProcessData()
{
	local l = "l_"+sMapName;

	if( !(l in this) ) return;

	l_p <- this[l];

	if( "pos" in l_p )
	{
		lp_p <- l_p.pos;

		if( type(lp_p[0]) == "instance" )
			if( lp_p[0] instanceof V )
			{
				::_d8ebSltA4Tef <- lp_p.len();
				::_d8eBSltA4Tef <- 1450;
				::_d8eBS1tA4Tef <- 0;
				::_d8ebS1tA4Tef <- clamp( _d8eBSltA4Tef, 0, _d8ebSltA4Tef );

				_ProcessData_p();
			};
	};
	if( "ang" in l_p )
	{
		la_p <- l_p.ang;

		if( type(la_p[0]) == "instance" )
			if( la_p[0] instanceof V )
				if( IsKeyframeRecording( l ) )
				{
					::_dBebS1t4aTeF <- la_p.len();
					::_dBebS1t4aTef <- 1450;
					::_dBebSlt4aTef <- 0;
					::_d8ebSlt4aTef <- clamp( _dBebS1t4aTef, 0, _dBebS1t4aTeF );

					_ProcessData_a();
				};
	};
}

function _ProcessData_p()
{
	if( _d8eBS1tA4Tef >= _d8ebS1tA4Tef )
	{
		delete ::_d8ebSltA4Tef;
		delete ::_d8eBSltA4Tef;
		delete ::_d8eBS1tA4Tef;
		delete ::_d8ebS1tA4Tef;
		delete ::lp_p;
		return;
	};

	for( local i = _d8eBS1tA4Tef; i < _d8ebS1tA4Tef; i++ )
		lp_p[i] = lp_p[i].V();

	_d8eBS1tA4Tef += _d8eBSltA4Tef;
	_d8ebS1tA4Tef = clamp( _d8ebS1tA4Tef + _d8eBSltA4Tef, 0, _d8ebSltA4Tef );

	return delay( "_ProcessData_p()", FTIME );
}

function _ProcessData_a()
{
	if( _dBebSlt4aTef >= _d8ebSlt4aTef )
	{
		delete ::_dBebS1t4aTeF;
		delete ::_dBebS1t4aTef;
		delete ::_dBebSlt4aTef;
		delete ::_d8ebSlt4aTef;
		delete ::la_p;
		return;
	};

	for( local i = _dBebSlt4aTef; i < _d8ebSlt4aTef; i++ )
		la_p[i] = la_p[i].V();

	_dBebSlt4aTef += _dBebS1t4aTef;
	_d8ebSlt4aTef = clamp( _d8ebSlt4aTef + _dBebS1t4aTef, 0, _dBebS1t4aTeF );

	return delay( "_ProcessData_a()", FTIME );
}

function Hint(s){ VS.ShowHudHint( _d83bSlta4lef, HPlayer, s ) }

// sec timer
function _dBebSlt4a73f()
{
	_dBebS1t4a7ef = 0;

	// sec timer enabled
	_d8bb5lta47ef = !_d8bb5lta47ef;
	EntFire( "_d83b5l7a4Tef", _d8bb5lta47ef ? "enable" : "disable" )
}

// sec counter
function _dBebSlt4a7ef()
{
	Hint( ++_dBebS1t4a7ef );
	PlaySound("UIPanorama.container_countdown");
}

_();

// trim
function _db3b51tAa7ef( i = 0, k = 0 )
{
	local lpt, lat, lp, la;

	if( !k )
	{
		if( !("lp_r" in this) || !("la_r" in this) )
			return Msg("No recording found.");

		lp = lp_r;
		la = la_r;

		if( !("lp_r_trim" in this) )
		{
			lp_r_trim <- [];
			la_r_trim <- [];
		};

		lpt = lp_r_trim;
		lat = la_r_trim;
	}
	else
	{
		return Msg("KEYFRAMES UNAVAILABLE");
	};

	if( !i )
	{
		local full = lp.len() * FTIME,
			  dec = full - floor(full),
			  unit = dec / FTIME;

		if( !VS.IsInteger(unit) )
			return Msg("An error occured while trimming! ["+lp.len()+","+full+","+dec+","+unit+"]\n");

		if( unit == lp.len() )
			return Msg("The recording is too short! " + full + " seconds\n");

		if( unit == 0.0 )
			return Msg("Cannot trim, recording is already at an integer length! [" + full + " seconds]\n");

		for( local i = 0; i < unit; i++ )
		{
			lpt.append(lp.pop());
			lat.append(la.pop());
		};

		// trimmed
		_d83Bb517a47ef = true;

		Msg("Trimmed "+dec+" seconds. New: "+lp.len() * FTIME+" seconds.");
		Msg("* Undo this trimming action: " + (k ? "bm_trim2_undo\n" : "bm_trim_undo\n"));
	}
	else
	{
		if( !_d83Bb517a47ef ) return Msg("Could not find trimmed data.\n");
		lpt.reverse();
		lat.reverse();
		lp.extend(lpt);
		la.extend(lat);
		lpt.clear();
		lat.clear();

		_d83Bb517a47ef = false;

		Msg("Undone trimming. New: " + lp.len() * FTIME + " seconds.");
	};
}

function _d83b5lt4aTeF()
{
	if( _d83b5lt4aTef )
	{
		if( !("lp_r" in this) || !("la_r" in this) )
		return Msg("No recording found.");

		local t = 1.5+FrameTime();

		for( local i = 0; i < lp_r.len()-5; i+=5 )
		{
			local p = lp_r[i];
			DebugDrawLine( p, p + VS.YawToVector(la_r[i]) * 16, 255, 128, 255, true, t );
			DebugDrawLine( p, lp_r[i+5], 138, 255, 0, true, t );
		}
	};
}

_d83b5lt4aTef <- false;

function _d83b5lt4alef()
{
	if( _d83bS1ta47ef )
		return Msg("Cannot show while recording!");
	if( _d83bS1ta4Tef || _d83bSl7a4Tef )
		return Msg("Cannot show while playing!");

	_d83b5lt4aTef = !_d83b5lt4aTef;

	if( _d83b5lt4aTef )
	{
		VS.SetKeyFloat( _d83bSlta47ef, "refiretime", 1.5 );
		VS.OnTimer( _d83bSlta47ef, _d83b5lt4aTeF );
		EntFireByHandle( _d83bSlta47ef, "enable" );
		_d83b5lt4aTeF();
	}
	else
	{
		EntFireByHandle( _d83bSlta47ef, "disable" );
		SendToConsole("clear_debug_overlays");
	};

	Msg("Show toggle: " + _d83b5lt4aTef);
}

// IsKeyframeRecording
function IsKeyframeRecording(m)
{
	// fixme ducttape
	if( type(this[m]) == "table" )
	{
		if( type(this[m].ang[0]) == "instance" )
			return true;
		return false;
	};

	if( type(this[m][0]) == "instance" )
		return true;
	return false;
}

// record
function _db3b51t4a7ef()
{
	Msg("\n[=======]\nPlease use the standalone 'keyframes' script to record paths.\nGet it here: github.com/samisalreadytaken/keyframes\n[=======]\n");

	// bRecordingPending
	if( _d83bS1t4a73f ) return Msg("Recording hasn't started yet!");
	// bRecording
	if( _d83bS1ta47ef ) return _db3b5lt4a7ef();

	// not necessary anymore
	if( !("_d83bSlta47ef" in this) || !Ent("_d83bSlta47ef") )
		return SendToConsole( "exec benchmark;bm_rec" );

	HPlayer.SetHealth(1337);
	_dBebS1t4a7ef = 0;

	// bRecording
	_d83bS1ta47ef = true;

	// bRecordingPending
	_d83bS1t4a73f = true;

	// trimmed
	_d83Bb517a47ef = false;

	_d83b5lt4aTef = false;
	EntFireByHandle( _d83bSlta47ef, "disable" );
	VS.SetKeyFloat( _d83bSlta47ef, "refiretime", FTIME );
	VS.OnTimer( _d83bSlta47ef, _d83b5lT4a9ef );
	lp_r <- [];
	la_r <- [];

	_d8ebSlta47ef = GetDeveloperLevel();
	PlaySound("UIPanorama.popup_accept_match_person");
	PlaySound("UIPanorama.tab_mainmenu_overwatch");
	SendToConsole( "developer 0;echo Starting recording in 3 seconds..." );

	        Hint( "Starting recording in 3..." );PlaySound( "Alert.WarmupTimeoutBeep");
	delay( "Hint(\"Starting recording in 2...\");PlaySound(\"Alert.WarmupTimeoutBeep\")", 1 );
	delay( "Hint(\"Starting recording in 1...\");PlaySound(\"Alert.WarmupTimeoutBeep\")", 2 );
	delay( "Hint(\"Recording...\");Msg(\"Recording...\")", 2.9 );

	// bRecordingPending
	delay( "_d83bS1t4a73f=false", 3 );

	EntFireByHandle( _d83bSlta47ef, "enable", "", 3 );
	EntFire( "_d83b5l7a4Tef", "enable", "", 3 );
}

// record end
function _db3b5lt4a7ef()
{
	if( !_d83bS1ta47ef ) return Msg("Not recording.");

	_dBebS1t4a7ef = 0;

	// bRecording
	_d83bS1ta47ef = false;

	EntFireByHandle( _d83bSlta47ef, "disable" );
	EntFire( "_d83b5l7a4Tef", "disable" );
	PlaySound("UIPanorama.gameover_show");
	SendToConsole( "developer " + _d8ebSlta47ef );
	Chat( txt.orange + "● "+txt.grey+"Stopped recording." );
	Msg("\nStopped recording: "+lp_r.len() * FTIME+" seconds.\n\n* Trim the data down to the nearest integer: bm_trim\n* Playback the recorded data:           bm_play\n* Save the recorded data:               bm_save\n");
}

// record save
function _dBeb5lta47ef()
{
	Msg("\n[=======]\nPlease use the standalone 'keyframes' script to record paths.\nGet it here: github.com/samisalreadytaken/keyframes\n[=======]\n");

	// recording exists
	if( !("lp_r" in this) || !lp_r.len() ) return Msg("No recording found.");

	_kf82b3b2lBb4 <- VS.Log.L;

	VS.Log.Clear();
	VS.Log.filePrefix = "benchmark_rec";
	VS.Log.condition = true;
	VS.Log.export = true;
	VS.Log.filter = "L ";
	_kf82b3b2lBb4.append( "l_" + sMapName + "<-{pos=[" );

	_dBebSlTa4T3F <- lp_r.len();
	_dBebSlTa4t3F <- 1450;
	_dBebSlTa4tef <- 0;
	_dBebSlTa4teF <- clamp( _dBebSlTa4t3F, 0, _dBebSlTa4T3F );

	return _dBeb5lta47ef2();
}

// save run
function _dBeb5lta47ef4()
{
	local file = VS.Log.Run();
	PrecacheScriptSound("Survival.TabletUpgradeSuccess");
	PlaySound("Survival.TabletUpgradeSuccess");
	Msg("\n* Recorded data is exported: /csgo/"+file+".log\n");
}

// save pos
function _dBeb5lta47ef2()
{
	if( _dBebSlTa4tef >= _dBebSlTa4teF )
	{
		_kf82b3b2lBb4.append("]ang=[");
		_dBebSlTa4tef = 0;
		_dBebSlTa4teF = clamp( _dBebSlTa4t3F, 0, _dBebSlTa4T3F );
		return _dBeb5lta47ef3();
	};

	for( local i = _dBebSlTa4tef; i < _dBebSlTa4teF; i++ )
		_kf82b3b2lBb4.append( VecToString(lp_r[i],"V(") );

	_dBebSlTa4tef += _dBebSlTa4t3F;
	_dBebSlTa4teF = clamp( _dBebSlTa4teF + _dBebSlTa4t3F, 0, _dBebSlTa4T3F );

	return delay( "_dBeb5lta47ef2()", FTIME );
}

// save ang
function _dBeb5lta47ef3()
{
	if( _dBebSlTa4tef >= _dBebSlTa4teF )
	{
		_kf82b3b2lBb4.pop();
		if( type(la_r[0]) == "instance" )
			_kf82b3b2lBb4.append( VecToString(la_r[la_r.len()-1],"V(") + "]}\n" );
		else
			_kf82b3b2lBb4.append( la_r[la_r.len()-1] + "]}\n" );
		return _dBeb5lta47ef4();
	};

	if( type(la_r[0]) == "instance" )
		for( local i = _dBebSlTa4tef; i < _dBebSlTa4teF; i++ )
			_kf82b3b2lBb4.append( VecToString(la_r[i],"V(") );
	else
		for( local i = _dBebSlTa4tef; i < _dBebSlTa4teF; i++ )
			_kf82b3b2lBb4.append( la_r[i] + "," );

	_dBebSlTa4tef += _dBebSlTa4t3F;
	_dBebSlTa4teF = clamp( _dBebSlTa4teF + _dBebSlTa4t3F, 0, _dBebSlTa4T3F );

	return delay( "_dBeb5lta47ef3()", FTIME );
}

function IsCrouching()
{
	return HPlayer.GetBoundingMaxs().z == 54 ? true : false;
}

// rec add
function _d83b5lT4a9ef()
{
	local v = HPlayer.GetOrigin();
	v.z += IsCrouching() ? 45.98 : 64.0;

	lp_r.append( v );
	la_r.append( VS.AngleNormalize(HPlayer.GetAngles().y) );
}

// set
function _d83bS1T4a9ef()
{
	_d83b5lt4a7ef.SetAbsOrigin( _dB3bS1ta47ef[_d83b51ta47ef] );
	_d83b5lt4a7ef.SetAngles( 0, _dB3b5lta47ef[_d83b51ta47ef], 0 );
	if( ++_d83b51ta47ef >= _d8ebSlta4Tef )
		_d83bSlt4a7ef(1);
}

// set_keyframes
function _d83bS1TAabef()
{
	_d83b5lt4a7ef.SetAbsOrigin( _dB3bS1ta47ef[_d83b51ta47ef] );
	VS.SetAngles( _d83b5lt4a7ef, _dB3b5lta47ef[_d83b51ta47ef] );
	if( ++_d83b51ta47ef >= _d8ebSlta4Tef )
		_d83bSlt4a7ef(1);
}

// start
function _d83bS1t4a7ef( r = 0 )
{
	if( _d83bSl7a4Tef ) return Msg("Benchmark hasn't started yet!");
	if( _d83bS1ta4Tef ) return Msg("Benchmark is already running!\nTo stop it: bm_stop");

	// not necessary anymore
	if( !("_d83bSlta47ef" in this) || !Ent("_d83bSlta47ef") )
		return SendToConsole( "exec benchmark;" + ( r ? "bm_play" : "benchmark" ) );

	local m, c1, c2;

	nPlayMode <- r;


// FIXME
// THIS IS A MESS!!!


	// default
	if( r == 0 )
	{
		c1 = "l_" + sMapName;
		c2 = "l_" + sMapName;
		m = sMapName;
	}
	// rec playback
	else if( r == 1 )
	{
		c1 = "lp_r";
		c2 = "la_r";
		m = "r";
	}
	else throw "Invalid value";;

	if( !(c1 in this) || !(c2 in this) )
		return Msg( r ? "No recording found." : (" *** Data not available for this map: " + sMapName) );

	if( r )
	{
		_dB3bS1ta47ef = this[c1];
		_dB3b5lta47ef = this[c2];
	}
	else
	{
		_dB3bS1ta47ef = this[c1].pos;
		_dB3b5lta47ef = this[c2].ang;
	};

	_d8ebSlta4Tef = _dB3bS1ta47ef.len();

	if( !_d8ebSlta4Tef || _d8ebSlta4Tef != _dB3b5lta47ef.len() )
		return Msg(" *** Map data is corrupted! [" + _dB3bS1ta47ef.len() + "," + _dB3b5lta47ef.len() + "]");

	_d83b5lt4aTef = false;
	EntFireByHandle( _d83bSlta47ef, "disable" );
	VS.SetKeyFloat( _d83bSlta47ef, "refiretime", FTIME );

	// IsKeyframeRecording
	if( IsKeyframeRecording(c2) )
		VS.OnTimer( _d83bSlta47ef, _d83bS1TAabef );
	else
		VS.OnTimer( _d83bSlta47ef, _d83bS1T4a9ef );

	// strip
	EntFireByHandle( _d8ebS1ta4Tef, "use", "", 0.0, HPlayer );
	HPlayer.SetHealth(1337);
	if( "Setup_" + m in this ) this["Setup_" + m]();

	// bStartedPending
	_d83bSl7a4Tef = true;

	_d8ebSlta47ef = GetDeveloperLevel();
	PlaySound("Weapon_AWP.BoltBack");
	delay( "PlaySound(\"Weapon_AWP.BoltForward\")", 0.5 );

	SendToConsole( "r_cleardecals;clear;echo;echo;echo;echo\"   Starting in 3 seconds.\";echo;echo\"   Keep the console closed for higher FPS\";echo;echo;echo;developer 0;toggleconsole;fadeout" );

	local _1 = "SendToConsole(\"+quickinv\")",_0 = "SendToConsole(\"-quickinv\")";
	delay( _1, 0.0 );delay( _0, 0.1 );
	delay( _1, 0.2 );delay( _0, 0.3 );
	delay( _1, 0.4 );delay( _0, 0.5 );

	delay( "Hint(\"Starting in 3...\");PlaySound(\"Alert.WarmupTimeoutBeep\")", 0.5 );
	delay( "Hint(\"Starting in 2...\");PlaySound(\"Alert.WarmupTimeoutBeep\")", 1.5 );
	delay( "Hint(\"Starting in 1...\");PlaySound(\"Alert.WarmupTimeoutBeep\")", 2.5 );
	delay( "Hint(\"Started...\")", 3.5 );

	// start core
	delay( "_d83b51T4a9ef(" + r + ")", 3.5 );
}

// start core
function _d83b51T4a9ef(r)
{
	_d83bSl7a4Tef=false;
	// bStarted
	_d83bS1ta4Tef = true;
	_d83b51ta47ef = 0;
	_dB3bSlta47ef = Time();
	EntFireByHandle( _d83b5lt4a7ef, "enable", "", 0, HPlayer );
	EntFireByHandle( _d83bSlta47ef, "enable" );
	SendToConsole( "fadein;fps_max 0;bench_start;bench_end;clear;echo;echo;echo;echo\"   Benchmark has started\";echo;echo\"   Keep the console closed for higher FPS\";echo;echo" );
}

// stop
function _d83bSlt4a7ef( i = 0 )
{
	// bStarted
	if( !_d83bS1ta4Tef ) return Msg("Benchmark not running.");

	// bStarted
	_d83bS1ta4Tef = false;

	Chat( txt.orange + "● "+txt.grey + "Results are printed onto the console." );
	Hint( "Results are printed onto the console." );

	EntFireByHandle( _d83b5lt4a7ef, "disable", "", 0, HPlayer );
	EntFireByHandle( _d83bSlta47ef, "disable" );

	if( _d8bb5lta47ef ) EntFire( "_d83b5l7a4Tef", "disable" );

	PlaySound("UIPanorama.gameover_show");
	if( i ) PlaySound("Buttons.snd9");

	SendToConsole( "host_timescale 1;clear;echo;echo;echo;echo\"----------------------------\";echo;echo " + ( i ? "Benchmark finished.;echo;echo\"Map: " + sMapName + "\";echo\"Tickrate: "+ fTickrate + "\";echo;toggleconsole" : (nPlayMode?"Stopped playback.;echo":"Stopped benchmark.;echo;mp_restartgame 1") ) + ";echo\"Time: " + ( Time() - _dB3bSlta47ef ) + " seconds\";echo;bench_end;echo;echo\"----------------------------\";echo;echo;developer " + _d8ebSlta47ef );
}

// bm_setup
function _d8bb5ltAa7ef()
{
	PlaySound("HudChat.Message");

//Msg(@"
//[i] See README.md for details.
//
//                 github.com/samisalreadytaken/csgo-benchmark
//
//bm_rec     : Start/stop recording new path
//bm_play    : Play the recording, run benchmark
//bm_save    : Save the recording
//bm_timer   : Toggle counter
//           :
//bm_list    : Print saved setup data
//bm_clear   : Clear saved setup data
//bm_remove  : Remove the last added setup data
//           :
//bm_mdl     : Print SpawnMDL()
//bm_flash   : Print SpawnFlash()
//bm_he      : Print SpawnHE()
//bm_molo    : Print SpawnMolotov()
//bm_smoke   : Print SpawnSmoke()
//bm_expl    : Print SpawnExplosion()
//           :
//bm_mdl1    : SpawnMDL()
//bm_flash1  : SpawnFlash()
//bm_he1     : SpawnHE()
//bm_molo1   : SpawnMolotov()
//bm_smoke1  : SpawnSmoke()
//bm_expl1   : SpawnExplosion()
//")

	Msg("\n[i] See README for details.\n\n                 github.com/samisalreadytaken/csgo-benchmark\n\nbm_rec     : Start/stop recording new path\nbm_play    : Play the recording, run benchmark\nbm_save    : Save the recording\nbm_timer   : Toggle counter\n           :\nbm_list    : Print saved setup data\nbm_clear   : Clear saved setup data\nbm_remove  : Remove the last added setup data\n           :\nbm_mdl     : Print SpawnMDL()\nbm_flash   : Print SpawnFlash()\nbm_he      : Print SpawnHE()\nbm_molo    : Print SpawnMolotov()\nbm_smoke   : Print SpawnSmoke()\nbm_expl    : Print SpawnExplosion()\n           :\nbm_mdl1    : SpawnMDL()\nbm_flash1  : SpawnFlash()\nbm_he1     : SpawnHE()\nbm_molo1   : SpawnMolotov()\nbm_smoke1  : SpawnSmoke()\nbm_expl1   : SpawnExplosion()\n\n");
}

function _d88bSlt4aTef()
{
//Msg(@"
//
//                 github.com/samisalreadytaken/csgo-benchmark
//
// Console commands:
//
//benchmark  : Run the benchmark
//bm_stop    : Force stop the ongoing benchmark
//           :
//           :
//bm_rec     : Start/stop recording new path
//bm_play    : Play the recording, run benchmark
//           :
//           :
//bm_setup   : Print setup related commands
//
// ----------
//
// Commands to display FPS:
//
//cl_showfps 1
//net_graph 1
//
// ----------
//
//[i] The benchmark sets your fps_max to 0
//")

	Msg("\n\n\n                 github.com/samisalreadytaken/csgo-benchmark\n\n Console commands:\n\nbenchmark  : Run the benchmark\nbm_stop    : Force stop the ongoing benchmark\n           :\n           :\nbm_rec     : Start/stop recording new path\nbm_play    : Play the recording, run benchmark\n           :\n           :\nbm_setup   : Print setup related commands\n\n ----------\n\n Commands to display FPS:\n\ncl_showfps 1\nnet_graph 1\n\n ----------\n\n[i] The benchmark sets your fps_max to 0\n");
	Msg("[i] Map: " + sMapName);
	Msg("[i] Server tickrate: " + fTickrate + "\n\n");

	if( !VS.IsInteger( 128.0 / fTickrate ) )
	{
		Msg("[!] Invalid tickrate ( " + fTickrate + " )! Only 128 and 64 ticks are supported.");
		Chat(txt.red+"[!] "+txt.white+"Invalid tickrate ( " +txt.yellow+ fTickrate +txt.white+" )! Only 128 and 64 ticks are supported.");
	};
}

// bm_clear
function _dB8d5lt4a7ef()
{
	PlaySound("UIPanorama.XP.Ticker");
	_d8BbSlt4a7ef.clear();
	_d8BdSlt4a7ef.clear();
	Msg("Cleared saved setup data.");
}

// bm_remove
function _dB8b5lt4a7ef()
{
	PlaySound("UIPanorama.XP.Ticker");
	if( !_d8Bd5lt4a7ef )
	{
		if( !_d8BbSlt4a7ef.len() ) return Msg("No saved data found.");
		_d8BbSlt4a7ef.pop();
		Msg("Removed the last added setup data. (model)");
	}
	else
	{
		if( !_d8BdSlt4a7ef.len() ) return Msg("No saved data found.");
		_d8BdSlt4a7ef.pop();
		Msg("Removed the last added setup data. (nade)");
	};
}

// bm_list
function _d88bSlt4a7ef()
{
	PlaySound("UIPanorama.XP.Ticker");
	if( !_d8BdSlt4a7ef.len() && !_d8BbSlt4a7ef.len() ) return Msg("No saved data found.");

	Msg("//------------------------\n// Copy the lines below:\n\n");Msg("function Setup_"+sMapName+"()\n{");foreach(k in _d8BbSlt4a7ef)print("\t"+k);print("\n");foreach(k in _d8BdSlt4a7ef)print("\t"+k);Msg("}\n");Msg("\n//------------------------");
}

// bm_mdl
function _d8Bb51t4a7ef( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnMDL( "+VecToString(HPlayer.GetOrigin())+","+HPlayer.GetAngles().y+", MDL."+sCurrMDL+" )\n";

	if(i)
	{
		local p = HPlayer.GetOrigin();
		p.z += 72;
		HPlayer.SetOrigin(p);
		return compilestring(a)();
	};

	_d8BbSlt4a7ef.append(a);
	Msg("\n"+a);
	_d8Bd5lt4a7ef = 0;
}

// bm_flash
function _d8Bp51t4a7ef( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnFlash( "+VecToString(HPlayer.GetOrigin())+", 0.0 )\n";

	if(i)
	{
		local p = HPlayer.GetOrigin();
		if( !HPlayer.IsNoclipping() ) p.z += 32;
		HPlayer.SetOrigin(p);
		return compilestring(a)();
	};

	_d8BdSlt4a7ef.append(a);
	Msg("\n"+a);
	_d8Bd5lt4a7ef = 1;
}

// bm_he
function _dB8d51t4a7ef( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnHE( "+VecToString(HPlayer.GetOrigin())+", 0.0 )\n";

	if(i)
	{
		local p = HPlayer.GetOrigin();
		if( !HPlayer.IsNoclipping() ) p.z += 32;
		HPlayer.SetOrigin(p);
		return compilestring(a)();
	};

	_d8BdSlt4a7ef.append(a);
	Msg("\n"+a);
	_d8Bd5lt4a7ef = 1;
}

// bm_molo
function _dBBb5lt4a7ef( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnMolotov( "+VecToString(HPlayer.GetOrigin())+", 0.0 )\n";

	if(i)
	{
		local p = HPlayer.GetOrigin();
		if( !HPlayer.IsNoclipping() ) p.z += 32;
		HPlayer.SetOrigin(p);
		return compilestring(a)();
	};

	_d8BdSlt4a7ef.append(a);
	Msg("\n"+a);
	_d8Bd5lt4a7ef = 1;
}

// bm_smoke
function _d88b5lt4a7ef( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnSmoke( "+VecToString(HPlayer.GetOrigin())+", 0.0 )\n";

	if(i) return compilestring(a)();

	_d8BdSlt4a7ef.append(a);
	Msg("\n"+a);
	_d8Bd5lt4a7ef = 1;
}

// bm_expl
function _d88b51t4aTef( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnExplosion( "+VecToString(HPlayer.GetOrigin())+", 0.0 )\n";

	if(i) return compilestring(a)();

	_d8BdSlt4a7ef.append(a);
	Msg("\n"+a);
	_d8Bd5lt4a7ef = 1;
}

function SpawnFlash( v, d )
{
	delay("SendToConsole(\"ent_create flashbang_projectile;ent_fire flashbang_projectile setlocalorigin\\\"" + VecToString( v, "", " ", "" ) + "\\\"\")", d)
}

function SpawnHE( v, d )
{
	delay("SendToConsole(\"ent_create hegrenade_projectile;ent_fire hegrenade_projectile setlocalorigin\\\"" + VecToString( v, "", " ", "" ) + "\\\";ent_fire hegrenade_projectile initializespawnfromworld\")", d)
}

function SpawnMolotov( v, d )
{
	delay("SendToConsole(\"ent_create molotov_projectile;ent_fire molotov_projectile setlocalorigin\\\"" + VecToString( v, "", " ", "" ) + "\\\";ent_fire molotov_projectile initializespawnfromworld\")", d)
}

function SpawnSmoke( v, d )
{
	delay("local v=" + VecToString(v) + ";DispatchParticleEffect(\"explosion_smokegrenade\",v,Vector(1,0,0));_d8ebS1ta4Tef.SetOrigin(v);_d8ebS1ta4Tef.EmitSound(\"BaseSmokeEffect.Sound\")", d)
}

function SpawnExplosion( v, d )
{
	delay("local v=" + VecToString(v) + ";DispatchParticleEffect(\"explosion_c4_500\",v,Vector());_d8ebS1ta4Tef.SetOrigin(v);_d8ebS1ta4Tef.EmitSound(\"c4.explode\")", d)
}

function SpawnMDL( v, a, m, p = POSE.DEFAULT )
{
	if( !Entities.FindByClassnameNearest( "prop_dynamic_override", v, 1 ) )
	{
		PrecacheModel( m );
		local h = ::CreateProp( "prop_dynamic_override", v, m, 0 );
		h.SetAngles( 0, a, 0 );
		VS.SetKeyInt( h, "solid", 2 );
		VS.SetKeyInt( h, "disablebonefollowers", 1 );
		VS.SetKeyInt( h, "holdanimation", 1 );
		VS.SetKeyString( h, "defaultanim", "grenade_deploy_03" );

		switch( p )
		{
			case POSE.ROM:
				EntFireByHandle( h, "setanimation", "rom" );
				break;
			case POSE.A:
				h.SetAngles( 0, a + 90, 90 );
				EntFireByHandle( h, "setanimation", "additive_posebreaker" );
				break;
			case POSE.PISTOL:
				EntFireByHandle( h, "setanimation", "pistol_deploy_02" );
				break;
			case POSE.RIFLE:
				EntFireByHandle( h, "setanimation", "rifle_deploy" );
				break;
			default:
				EntFireByHandle( h, "setanimation", "grenade_deploy_03" );
				EntFireByHandle( h, "setplaybackrate", "0" );
		};
	};
}

sCurrMDL <- "BALKg";

function SetMDL(s)
{
	if( typeof s != "string" ) return Msg("Invalid input");

	local t = "";

	for( local i = 0; i < s.len(); i++ )
	{
		local c = s[i].tochar();

		if( i == (s.len() - 1) ) c = c.tolower();
		else c = c.toupper();

		t += c;
	};

	sCurrMDL = t;
}
