//-----------------------------------------------------------------------
//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
//                     github.com/samisalreadytaken
//-----------------------------------------------------------------------
IncludeScript("vs_library")

class V
{
	constructor(x=0,y=0,z=0)
	{
		this.x = x
		this.y = y
		this.z = z
	}

	function V(dx=0,dy=0,dz=0){ return::Vector(this.x+dx,this.y+dy,this.z+dz) }

	x = 0.0
	y = 0.0
	z = 0.0
}

IncludeScript("benchmark_res")

SendToConsole("alias benchmark\"script _d83bS1t4a7ef()\";alias bm_stop\"script _d83bSlt4a7ef()\";alias bm_rec\"script _db3b51t4a7ef()\";alias bm_play\"script _d83bS1t4a7ef(1)\";alias bm_rec_pos\"script _d83bS1taA7ef()\";alias bm_play_pos\"script _d83bSltaA7ef()\";alias bm_save\"script _dBeb5lta47ef()\";alias bm_setup\"script _d8bb5ltAa7ef()\";alias bm_timer\"script _dBebSlt4a73f()\";alias bm_list\"script _d88bSlt4a7ef()\";alias bm_clear\"script _dB8d5lt4a7ef()\";alias bm_remove\"script _dB8b5lt4a7ef()\";alias bm_mdl\"script _d8Bb51t4a7ef()\";alias bm_mdl1\"script _d8Bb51t4a7ef(1)\";alias bm_flash\"script _d8Bp51t4a7ef()\";alias bm_flash1\"script _d8Bp51t4a7ef(1)\";alias bm_he\"script _dB8d51t4a7ef()\";alias bm_he1\"script _dB8d51t4a7ef(1)\";alias bm_molo\"script _dBBb5lt4a7ef()\";alias bm_molo1\"script _dBBb5lt4a7ef(1)\";alias bm_smoke\"script _d88b5lt4a7ef()\";alias bm_smoke1\"script _d88b5lt4a7ef(1)\";alias bm_expl\"script _d88b51t4aTef()\";alias bm_expl1\"script _d88b51t4aTef(1)\"")
SendToConsole("-duck;clear;script OnPostSpawn()")

ClearChat()
ClearChat()
Chat( txt.blue+" -------------------------------- " )
Chat( " " )
Chat( txt.lightgreen + "[Benchmark Script] "+txt.lightblue+"Loaded" )
Chat( txt.orange + "● "+txt.grey+"Instructions are printed onto the console." )

VS.GetLocalPlayer()

HPlayer.EmitSound("Player.DrownStart")

// bRecording
_d83bS1ta47ef <- false

// bRecordingPending
_d83bS1t4a73f <- false

// sec timer enabled
_d8bb5lta47ef <- false

// bStarted
_d83bS1ta4Tef <- false

// bStartedPending
_d83bSl7a4Tef <- false

// bRecordingPos Only
_d83b5lta4Tef <- false

_dB3bS1ta47ef <- null
_dB3b5lta47ef <- null
_dBebS1t4a7ef <- 0
_d83b51ta47ef <- 0
_d8ebSlta4Tef <- 0
_d8ebSlta47ef <- 0
_dB3bSlta47ef <- 0.0

// lists
if( !("_d8BbSlt4a7ef" in this) ) _d8BbSlt4a7ef <- []
if( !("_d8BdSlt4a7ef" in this) ) _d8BdSlt4a7ef <- []
// nRecLast
if( !("_d8Bd5lt4a7ef" in this) ) _d8Bd5lt4a7ef <- -1

if( !("_d83b5lta47ef" in this) ) _d83b5lta47ef <- false

if( !("_d8ebS1ta4Tef" in this) || !Ent("_d8ebS1ta4Tef") )
{
	_d8ebS1ta4Tef <- VS.CreateEntity( "game_player_equip", "_d8ebS1ta4Tef", {spawnflags = 2} )
	VS.MakePermanent( _d8ebS1ta4Tef )
}

if( !("_d83bSlta47ef" in this) || !Ent("_d83bSlta47ef") )
{
	_d83bSlta47ef <- VS.CreateTimer( "_d83bSlta47ef", 0.015625, 0, 0, 0, 1 )
	VS.MakePermanent( _d83bSlta47ef )
}

if( !("_d83bSlta41ef" in this) || !Ent("_d83bSlta41ef") )
	_d83bSlta41ef <- VS.CreateEntity( "info_target", "_d83bSlta41ef" )

if( !("_d83bSlta4lef" in this) || !Ent("_d83bSlta4lef") )
{
	_d83bSlta4lef <- VS.CreateHudHint( "_d83bSlta4lef" )
	VS.MakePermanent( _d83bSlta4lef )
}

EntFireHandle( _d83bSlta47ef, "disable" )
EntFire( "_d83b5l7a4Tef", "disable" )

fTickCurr <- -1.0

function OnPostSpawn()
{
	_d88bSlt4aTef();_d83d51ta4Tef();_ProcessData()
}

function _ProcessData()
{
	local l = this["lp_"+GetMapName()]

	foreach( i, v in l )
		VS.ReplaceArrayIndex( l, i, v.V() )
}

function Alert(s){ VS.ShowHudHint( _d83bSlta4lef, HPlayer, s ) }

// strip
function _d83bS174a7ef(){ EntFireHandle( _d8ebS1ta4Tef, "use", "", 0.0, HPlayer ) }

// sec timer
function _dBebSlt4a73f()
{
	_dBebS1t4a7ef = 0

	// sec timer enabled
	_d8bb5lta47ef = !_d8bb5lta47ef
	EntFire( "_d83b5l7a4Tef", _d8bb5lta47ef ? "enable" : "disable" )
}

// sec counter
function _dBebSlt4a7ef()
{
	Alert( ++_dBebS1t4a7ef )
	HPlayer.EmitSound("UIPanorama.container_countdown")
}

if(!Ent("_d83b5l7a4Tef"))
{
	VS.OnTimer( VS.CreateTimer( "_d83b5l7a4Tef", 1, 0, 0, 0, 1 ), "_dBebSlt4a7ef" )
	VS.MakePermanent( Ent("_d83b5l7a4Tef") )
}

// record
function _db3b51t4a7ef()
{
	// bRecordingPending
	if( _d83bS1t4a73f ) return printl("Recording hasn't started yet!")
	// bRecording
	if( _d83bS1ta47ef ) return _db3b5lt4a7ef()

	// not necessary anymore
	if( !("_d83bSlta47ef" in this) || !Ent("_d83bSlta47ef") )
		return SendToConsole( "exec benchmark;bm_rec" )

	HPlayer.SetHealth(1337)
	_dBebS1t4a7ef = 0

	// recording exists
	_d83b5lta47ef = true

	// bRecording
	_d83bS1ta47ef = true

	// bRecordingPending
	_d83bS1t4a73f = true

	VS.OnTimer( _d83bSlta47ef, "_d83b5lT4a9ef" )
	lp_r <- []
	la_r <- []

	_d8ebSlta47ef = GetDeveloperLevel()
	HPlayer.EmitSound("UIPanorama.popup_accept_match_person")
	HPlayer.EmitSound("UIPanorama.tab_mainmenu_overwatch")
	SendToConsole( "developer 0;echo Starting recording in 3 seconds..." )

	        Alert( "Starting recording in 3..." );HPlayer.EmitSound("Alert.WarmupTimeoutBeep")
	delay( "Alert(\"Starting recording in 2...\");HPlayer.EmitSound(\"Alert.WarmupTimeoutBeep\")", 1 )
	delay( "Alert(\"Starting recording in 1...\");HPlayer.EmitSound(\"Alert.WarmupTimeoutBeep\")", 2 )
	delay( "Alert(\"Recording...\");printl(\"Recording...\")", 2.9 )

	// bRecordingPending
	delay( "_d83bS1t4a73f=false", 3 )

	EntFireHandle( _d83bSlta47ef, "enable", "", 3 )
	EntFire( "_d83b5l7a4Tef", "enable", "", 3 )
}

// record end
function _db3b5lt4a7ef()
{
	if( !_d83bS1ta47ef ) return printl("Not recording.")

	_dBebS1t4a7ef = 0

	// recording exists
	_d83b5lta47ef = true

	// bRecording
	_d83bS1ta47ef = false

	EntFireHandle( _d83bSlta47ef, "disable" )
	EntFire( "_d83b5l7a4Tef", "disable" )
	HPlayer.EmitSound("UIPanorama.gameover_show")
	SendToConsole( "developer " + _d8ebSlta47ef )
	Chat( txt.orange + "● "+txt.grey+"Stopped recording." )
	printl("\n* Stopped recording.\n* To playback the recorded data: bm_play\n* To save the recorded data:     bm_save\n")
}

// record save
function _dBeb5lta47ef()
{
	// recording exists
	if( !_d83b5lta47ef ) return printl("No recording found.")
	VS.Log.Clear()
	VS.Log.filePrefix = "benchmark_rec"
	VS.Log.condition = true
	VS.Log.export = true
	VS.Log.filter = "L "
	local m = GetMapName()
	VS.Log.Add( "lp_" + m + "<-[" )
	foreach( v in lp_r ) VS.Log.Add( VecToString(v,"V(") )
	VS.Log.Add("];la_" + m + "<-[")
	foreach( v in la_r ) VS.Log.Add( v + "," )
	VS.Log.L.pop()
	VS.Log.Add( la_r[la_r.len()-1] + "];\n" )
	VS.Log.Run()
	HPlayer.PrecacheScriptSound("Survival.TabletUpgradeSuccess")
	HPlayer.EmitSound("Survival.TabletUpgradeSuccess")
	printl("\n* Recorded data is exported in /csgo/ with the prefix 'benchmark_rec_'.\n")
}

// play only pos
function _d83bSltaA7ef()
{
	if( !("lp_r" in this) || !lp_r.len() ) return printl("No recording found.")

	printl("\n[!] No safety implemented, do not execute any other code!\n[!] Reload the script to stop.\n")

	_d8ebSlta4Tef = lp_r.len()
	_d83b51ta47ef = 0
	VS.OnTimer( _d83bSlta47ef, "_d83b5ltaA7ef" )

	HPlayer.SetHealth(1337)
	delay( "VS.SetKeyInt(HPlayer,\"movetype\",8);SendToConsole(\"+duck\")", 2.9 )

	delay( "printl(\"Starting in 3...\")", 0.0 )
	delay( "printl(\"Starting in 2...\")", 1.0 )
	delay( "printl(\"Starting in 1...\")", 2.0 )
	delay( "printl(\"Started...\")", 3.0 )
	EntFireHandle( _d83bSlta47ef, "enable", "", 3.0 )
}

// rec only pos
function _d83bS1taA7ef()
{
	// bRecordingPosOnly
	if( _d83b5lta4Tef )
	{
		_d83b5lta4Tef = false
		EntFireHandle( _d83bSlta47ef, "disable" )
		Chat( txt.orange + "● "+txt.grey+"Stopped recording." )
		return printl("Stopped recording.")
	}

	printl("\n[!] No safety implemented, do not execute any other code!\n")

	// bRecordingPos Only
	_d83b5lta4Tef = true
	VS.OnTimer( _d83bSlta47ef, "_d83bSlta4Tef" )
	lp_r <- []

	        Alert( "Starting recording in 3..." );printl( "Starting recording in 3..." );HPlayer.EmitSound( "Alert.WarmupTimeoutBeep" )
	delay( "Alert(\"Starting recording in 2...\");printl(\"Starting recording in 2...\");HPlayer.EmitSound(\"Alert.WarmupTimeoutBeep\")", 1 )
	delay( "Alert(\"Starting recording in 1...\");printl(\"Starting recording in 1...\");HPlayer.EmitSound(\"Alert.WarmupTimeoutBeep\")", 2 )
	delay( "Alert(\"Recording...\");printl(\"Recording...\")", 2.9 )

	EntFireHandle( _d83bSlta47ef, "enable", "", 3 )
}

// rec pos
function _d83bSlta4Tef()
{
	local v = HPlayer.GetOrigin()
	v.z += 18.02

	lp_r.append( v )
}

// set pos
function _d83b5ltaA7ef()
{
	HPlayer.SetOrigin( lp_r[_d83b51ta47ef] )
	if( ++_d83b51ta47ef >= _d8ebSlta4Tef )
	{
		EntFireHandle( _d83bSlta47ef, "disable" )
		printl("[!] Finished.")
	}
}

// rec add
function _d83b5lT4a9ef()
{
	local v = HPlayer.GetOrigin()
	v.z += 18.02

	lp_r.append( v )
	la_r.append( HPlayer.GetAngles().y )
}

// set
function _d83bS1T4a9ef()
{
	HPlayer.SetOrigin( _dB3bS1ta47ef[_d83b51ta47ef] )
	HPlayer.SetAngles( 0, _dB3b5lta47ef[_d83b51ta47ef], 0 )
	if( ++_d83b51ta47ef >= _d8ebSlta4Tef )
		_d83bSlt4a7ef(1)
}

// start
function _d83bS1t4a7ef( r = 0 )
{
	if( _d83bSl7a4Tef ) return printl("Benchmark hasn't started yet!")
	if( _d83bS1ta4Tef ) return printl("Benchmark is already running!\nTo stop it: bm_stop")

	// not necessary anymore
	if( !("_d83bSlta47ef" in this) || !Ent("_d83bSlta47ef") )
		return SendToConsole( "exec benchmark;" + ( r ? "bm_play" : "benchmark" ) )

	VS.OnTimer( _d83bSlta47ef, "_d83bS1T4a9ef" )

	local m = r ? "r" : GetMapName()
	if( !("lp_" + m in this) || !("la_" + m in this) )
		return printl( r ? "No recording found." : (" *** Data not available for this map: " + m) )

	_dB3bS1ta47ef = this["lp_" + m]
	_dB3b5lta47ef = this["la_" + m]
	_d8ebSlta4Tef = _dB3bS1ta47ef.len()

	if( !_d8ebSlta4Tef || _d8ebSlta4Tef != _dB3b5lta47ef.len() )
		return printl(" *** Map data is corrupted!")

	_d83bS174a7ef()
	HPlayer.SetHealth(1337)
	delay( "VS.SetKeyInt(HPlayer,\"movetype\",8)", 2.9 )
	try( this["Setup_" + m]() )catch(e){}

	// bStartedPending
	_d83bSl7a4Tef = true

	_d8ebSlta47ef = GetDeveloperLevel()
	HPlayer.EmitSound("Weapon_AWP.BoltBack")
	delay( "HPlayer.EmitSound(\"Weapon_AWP.BoltForward\")", 0.5 )

	SendToConsole( "r_cleardecals;clear;echo;echo;echo;echo\"   Starting in 3 seconds.\";echo;echo\"   Keep the console closed for higher FPS\";echo;echo;echo;developer 0;toggleconsole;fadeout" )

	local _1 = "SendToConsole(\"+quickinv\")",_0 = "SendToConsole(\"-quickinv\")"
	delay( _1, 0.0 )
	delay( _0, 0.1 )
	delay( _1, 0.2 )
	delay( _0, 0.3 )
	delay( _1, 0.4 )
	delay( _0, 0.5 )

	delay( "Alert(\"Starting in 3...\");HPlayer.EmitSound(\"Alert.WarmupTimeoutBeep\")", 0.5 )
	delay( "Alert(\"Starting in 2...\");HPlayer.EmitSound(\"Alert.WarmupTimeoutBeep\")", 1.5 )
	delay( "Alert(\"Starting in 1...\");HPlayer.EmitSound(\"Alert.WarmupTimeoutBeep\")", 2.5 )
	delay( "Alert(\"Started...\")", 3.5 )
	// bStartedPending
	delay( "_d83bSl7a4Tef=false;_d83b51T4a9ef(" + r + ")", 3.5 )
}

// start core
function _d83b51T4a9ef( r )
{
	// bStarted
	_d83bS1ta4Tef = true
	_d83b51ta47ef = 0
	_dB3bSlta47ef = Time()
	EntFireHandle( _d83bSlta47ef, "enable" )
	SendToConsole( "+duck;fadein;fps_max 0;bench_start;bench_end;clear;echo;echo;echo;echo\"   Benchmark has started\";echo;echo\"   Keep the console closed for higher FPS\";echo;echo" )
}

// stop
function _d83bSlt4a7ef( i = 0 )
{
	// bStarted
	if( !_d83bS1ta4Tef ) return printl("Benchmark not running.")

	// bStarted
	_d83bS1ta4Tef = false

	Chat( txt.orange + "● "+txt.grey + "Results are printed onto the console." )
	Alert( "Results are printed onto the console." )

	EntFireHandle( _d83bSlta47ef, "disable" )

	if( _d8bb5lta47ef ) EntFire( "_d83b5l7a4Tef", "disable" )

	HPlayer.EmitSound("UIPanorama.gameover_show")
	if( i ) HPlayer.EmitSound("Buttons.snd9")

	SendToConsole( "-duck;host_timescale 1;clear;echo;echo;echo;echo\"----------------------------\";echo;echo " + ( i ? "Benchmark finished.;echo;echo\"Map: " + GetMapName() + "\";echo\"Tickrate: "+ fTickCurr + "\";echo;toggleconsole" : "Stopped benchmark.;echo;mp_restartgame 1" ) + ";echo\"Time: " + ( Time() - _dB3bSlta47ef ) + " seconds\";echo;bench_end;echo;echo\"----------------------------\";echo;echo;developer " + _d8ebSlta47ef )

/*
	   ----------

	Benchmark finished.

	Map: de_dust2
	Tickrate: 64

	Time: 49.0781 seconds

	Average framerate: 301.19

	   ----------
*/

/*
	----------------------------

	Benchmark finished.

	Map : de_dust2
	Tick: 64

	Time: 49.0781 seconds

	Average framerate: 301.19

	----------------------------
*/

/*
	----------------------------

	Benchmark finished.

	Map              : de_dust2
	Tickrate         : 64

	Benchmark ran for: 49.0781 seconds

	Average framerate: 301.19

	----------------------------
*/

	// SendToConsole( "-duck;host_timescale 1;clear;echo;echo;echo;echo\"   ------------\";echo;echo " + ( i ? "Benchmark finished.;echo;echo\"" + OutputFormat("Map: ") + GetMapName() + "\";echo\"" + OutputFormat("Tickrate: ") + fTickCurr + "\";echo;toggleconsole" : "Stopped benchmark.;echo;mp_restartgame 1" ) + ";echo\""+ OutputFormat("Benchmark time: ") + ( Time() - _dB3bSlta47ef ) + " seconds\";echo;bench_end;echo;echo\"   ------------\";echo;echo;developer " + _d8ebSlta47ef )

/*
	----------------------------

	Benchmark finished.

				  Map: de_dust2
			 Tickrate: 64

	   Benchmark time: 49.0781 seconds

	Average framerate: 301.19

	----------------------------
*/
}

// function OutputFormat( s ) { return VS.FormatWidth( " ", s, 19 ) }

// function Echo( s = "" ) { SendToConsole("echo\""+s+"\"") }

// bm_setup
function _d8bb5ltAa7ef()
{
	HPlayer.EmitSound("HudChat.Message")
/*
printl(@"
[i] See README.md for details.

                 github.com/samisalreadytaken/csgo-benchmark

bm_rec     : Start/stop recording new path
bm_play    : Play the recording, run benchmark
bm_save    : Save the recording
bm_timer   : Toggle counter
           :
bm_list    : Print saved setup data
bm_clear   : Clear saved setup data
bm_remove  : Remove the last added setup data
           :
bm_mdl     : Print SpawnMDL()
bm_flash   : Print SpawnFlash()
bm_he      : Print SpawnHE()
bm_molo    : Print SpawnMolotov()
bm_smoke   : Print SpawnSmoke()
bm_expl    : Print SpawnExplosion()
           :
bm_mdl1    : SpawnMDL()
bm_flash1  : SpawnFlash()
bm_he1     : SpawnHE()
bm_molo1   : SpawnMolotov()
bm_smoke1  : SpawnSmoke()
bm_expl1   : SpawnExplosion()
")
*/
	printl("\n[i] See README for details.\n\n                 github.com/samisalreadytaken/csgo-benchmark\n\nbm_rec     : Start/stop recording new path\nbm_play    : Play the recording, run benchmark\nbm_save    : Save the recording\nbm_timer   : Toggle counter\n           :\nbm_list    : Print saved setup data\nbm_clear   : Clear saved setup data\nbm_remove  : Remove the last added setup data\n           :\nbm_mdl     : Print SpawnMDL()\nbm_flash   : Print SpawnFlash()\nbm_he      : Print SpawnHE()\nbm_molo    : Print SpawnMolotov()\nbm_smoke   : Print SpawnSmoke()\nbm_expl    : Print SpawnExplosion()\n           :\nbm_mdl1    : SpawnMDL()\nbm_flash1  : SpawnFlash()\nbm_he1     : SpawnHE()\nbm_molo1   : SpawnMolotov()\nbm_smoke1  : SpawnSmoke()\nbm_expl1   : SpawnExplosion()\n\n")
}

function _d88bSlt4aTef()
{
/*
printl(@"

 Benchmark script loaded.

                 github.com/samisalreadytaken/csgo-benchmark

 Console commands:

benchmark  : Run the benchmark
bm_stop    : Force stop the ongoing benchmark
           :
           :
bm_rec     : Start/stop recording new path
bm_play    : Play the recording, run benchmark
           :
           :
bm_setup   : Print setup related commands

 ----------

 Commands to display FPS:

cl_showfps 1
net_graph 1

 ----------

[i] The benchmark sets your fps_max to 0
")
*/
	printl("\n\n\n Benchmark script loaded.\n\n                 github.com/samisalreadytaken/csgo-benchmark\n\n Console commands:\n\nbenchmark  : Run the benchmark\nbm_stop    : Force stop the ongoing benchmark\n           :\n           :\nbm_rec     : Start/stop recording new path\nbm_play    : Play the recording, run benchmark\n           :\n           :\nbm_setup   : Print setup related commands\n\n ----------\n\n Commands to display FPS:\n\ncl_showfps 1\nnet_graph 1\n\n ----------\n\n[i] The benchmark sets your fps_max to 0\n")
}

function _d83d51ta4Tef()
{
	fTickCurr = VS.GetTickrate()

	if( !VS.IsInteger( 128.0 / fTickCurr ) )
		return printl("[!] Invalid tickrate ( " + fTickCurr + " )! Only 128 and 64 ticks are supported.")

	printl("[i] Map: " + GetMapName())
	printl("[i] Server tickrate: " + fTickCurr+"\n\n")
	Chat( txt.orange + "● " + txt.grey +"Server tickrate: " + txt.yellow + fTickCurr )
	Chat( " " )
	Chat( txt.blue+" -------------------------------- " )

	if( !HPlayer ) throw "NO PLAYER FOUND"
	if( HPlayer.GetTeam() != 2 && HPlayer.GetTeam() != 3 ) HPlayer.SetTeam(2)
}

// bm_clear
function _dB8d5lt4a7ef()
{
	HPlayer.EmitSound("UIPanorama.XP.Ticker")
	_d8BbSlt4a7ef.clear()
	_d8BdSlt4a7ef.clear()
	printl("Cleared saved setup data.")
}

// bm_remove
function _dB8b5lt4a7ef()
{
	HPlayer.EmitSound("UIPanorama.XP.Ticker")
	if( !_d8Bd5lt4a7ef )
	{
		if( !_d8BbSlt4a7ef.len() ) return printl("No saved data found.")
		_d8BbSlt4a7ef.pop()
		printl("Removed the last added setup data. (model)")
	}
	else
	{
		if( !_d8BdSlt4a7ef.len() ) return printl("No saved data found.")
		_d8BdSlt4a7ef.pop()
		printl("Removed the last added setup data. (nade)")
	}
}

// bm_list
function _d88bSlt4a7ef()
{
	HPlayer.EmitSound("UIPanorama.XP.Ticker")
	if( !_d8BdSlt4a7ef.len() && !_d8BbSlt4a7ef.len() ) return printl("No saved data found.")

	printl("//------------------------\n// Copy the lines below:\n\n");printl("function Setup_"+GetMapName()+"()\n{");foreach(k in _d8BbSlt4a7ef)print("\t"+k);print("\n");foreach(k in _d8BdSlt4a7ef)print("\t"+k);printl("}\n");printl("\n//------------------------")
}

// bm_mdl
function _d8Bb51t4a7ef( i = 0 )
{
	HPlayer.EmitSound("UIPanorama.XP.Ticker")
	local a = "SpawnMDL( "+VecToString(HPlayer.GetOrigin())+","+HPlayer.GetAngles().y+", MDL."+sCurrMDL+" )\n"

	if(i)
	{
		local p = HPlayer.GetOrigin()
		p.z += 72
		HPlayer.SetOrigin(p)
		return compilestring(a)()
	}

	_d8BbSlt4a7ef.append(a)
	printl("\n"+a)
	_d8Bd5lt4a7ef = 0
}

// bm_flash
function _d8Bp51t4a7ef( i = 0 )
{
	HPlayer.EmitSound("UIPanorama.XP.Ticker")
	local a = "SpawnFlash( "+VecToString(HPlayer.GetOrigin())+", 0.0 )\n"

	if(i)
	{
		local p = HPlayer.GetOrigin()
		if( !HPlayer.IsNoclipping() ) p.z += 32
		HPlayer.SetOrigin(p)
		return compilestring(a)()
	}

	_d8BdSlt4a7ef.append(a)
	printl("\n"+a)
	_d8Bd5lt4a7ef = 1
}

// bm_he
function _dB8d51t4a7ef( i = 0 )
{
	HPlayer.EmitSound("UIPanorama.XP.Ticker")
	local a = "SpawnHE( "+VecToString(HPlayer.GetOrigin())+", 0.0 )\n"

	if(i)
	{
		local p = HPlayer.GetOrigin()
		if( !HPlayer.IsNoclipping() ) p.z += 32
		HPlayer.SetOrigin(p)
		return compilestring(a)()
	}

	_d8BdSlt4a7ef.append(a)
	printl("\n"+a)
	_d8Bd5lt4a7ef = 1
}

// bm_molo
function _dBBb5lt4a7ef( i = 0 )
{
	HPlayer.EmitSound("UIPanorama.XP.Ticker")
	local a = "SpawnMolotov( "+VecToString(HPlayer.GetOrigin())+", 0.0 )\n"

	if(i)
	{
		local p = HPlayer.GetOrigin()
		if( !HPlayer.IsNoclipping() ) p.z += 32
		HPlayer.SetOrigin(p)
		return compilestring(a)()
	}

	_d8BdSlt4a7ef.append(a)
	printl("\n"+a)
	_d8Bd5lt4a7ef = 1
}

// bm_smoke
function _d88b5lt4a7ef( i = 0 )
{
	HPlayer.EmitSound("UIPanorama.XP.Ticker")
	local a = "SpawnSmoke( "+VecToString(HPlayer.GetOrigin())+", 0.0 )\n"

	if(i) return compilestring(a)()

	_d8BdSlt4a7ef.append(a)
	printl("\n"+a)
	_d8Bd5lt4a7ef = 1
}

// bm_expl
function _d88b51t4aTef( i = 0 )
{
	HPlayer.EmitSound("UIPanorama.XP.Ticker")
	local a = "SpawnExplosion( "+VecToString(HPlayer.GetOrigin())+", 0.0 )\n"

	if(i) return compilestring(a)()

	_d8BdSlt4a7ef.append(a)
	printl("\n"+a)
	_d8Bd5lt4a7ef = 1
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
	delay("local v=" + VecToString(v) + ";DispatchParticleEffect(\"explosion_smokegrenade\",v,Vector(1,0,0));_d83bSlta41ef.SetOrigin(v);_d83bSlta41ef.EmitSound(\"BaseSmokeEffect.Sound\")", d)
}

function SpawnExplosion( v, d )
{
	delay("local v=" + VecToString(v) + ";DispatchParticleEffect(\"explosion_c4_500\",v,Vector());_d83bSlta41ef.SetOrigin(v);_d83bSlta41ef.EmitSound(\"c4.explode\")", d)
}

function SpawnMDL( v, a, m )
{
	if( !Entities.FindByClassnameNearest( "prop_*", v, 1 ) )
	{
		PrecacheModel( m )
		local h = VS.CreateProp( v, m )
		h.SetAngles( 0, a, 0 )
		VS.SetKeyInt( h, "solid", 2 )
	}
}

sCurrMDL <- "BALKg"

function SetMDL(s)
{
	if( typeof s != "string" ) return printl("Invalid input")

	local t = ""

	for( local i = 0; i < s.len(); i++ )
	{
		local c = s[i].tochar()

		if( i == (s.len() - 1) ) c = c.tolower()
		else c = c.toupper()

		t += c
	}

	sCurrMDL = t
}
