//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//- v1.1.3 --------------------------------------------------------------
const _VER_ = "1.1.3";;

IncludeScript("vs_library");

class V
{
	constructor(_x=0,_y=0,_z=0)
	{
		x = _x;
		y = _y;
		z = _z;
	}

	function V(dx=0,dy=0,dz=0) return::Vector(x+dx,y+dy,z+dz);

	x = 0.0;
	y = 0.0;
	z = 0.0;
}

class Q
{
	constructor(_x=0,_y=0,_z=0,_w=0)
	{
		x = _x;
		y = _y;
		z = _z;
		w = _w;
	}

	function V(dx=0,dy=0,dz=0,dw=0) return::Quaternion(x+dx,y+dy,z+dz,w+dw);

	x = 0.0;
	y = 0.0;
	z = 0.0;
	w = 0.0;
}

try(IncludeScript("keyframes_data"))catch(e){}

if(!("__R"in::getroottable()))::__R<-false;;if(::__R)delete::__R;else{local _=function(){};::__R=true;return::DoIncludeScript(_.getinfos().src,this)};;
const FTIME = 0.015625;;
enum EF
{
	ON  = 88, // ((1<<4|1<<6)|(1<<3))|0
	OFF = 120 // ((1<<4|1<<6)|(1<<3))|(1<<5)
}

SendToConsole("alias kf_add\"script _kf82b3BZ1bBA()\";alias kf_remove\"script _kf82b38Z1bbA()\";alias kf_remove_undo\"script _kf8Zb3B2lbBA(1)\";alias kf_clear\"script _kf82b3BZ1Bb4()\";alias kf_insert\"script _kf82b3821bB4()\";alias kf_replace\"script _kf82b3821bBA()\";alias kf_replace_undo\"script _kf8Zb3B2lbBA(0)\";alias kf_removefov\"script _kf82b3BZ1bbA()\";alias kf_compile\"script _kfb28382lB64()\";alias kf_play\"script _kfB283B2lbBA()\";alias kf_stop\"script _kfB283B2lBbA()\";alias kf_save\"script _kf82b3B2lBb4()\";alias kf_savekeys\"script _kf82b3B2lBb4(1)\";alias kf_mode_angle\"script _kfb2838Z1Bba()\";alias kf_edit\"script _kfB2b3821bb4()\";alias kf_select\"script _kf82b3821bb4()\";alias kf_see\"script _kf82bE82lbBA()\";alias kf_next\"script _kfb283821bBx()\";alias kf_prev\"script _kfb283821bBp()\";alias kf_showkeys\"script _kfB283B21bBA(0)\";alias kf_showpath\"script _kfB283B21bBA(1)\";alias kf_cmd\"script _kfB2bEB21bba()\"");

SendToConsole("alias +kf_roll_R\"script _kf_roll_R(1)\";alias -kf_roll_R\"script _kf_roll_R(0)\";alias +kf_roll_L\"script _kf_roll_L(1)\";alias -kf_roll_L\"script _kf_roll_L(0)\";alias +kf_fov_U\"script _kf_fov_U(1)\";alias -kf_fov_U\"script _kf_fov_U(0)\";alias +kf_fov_D\"script _kf_fov_D(1)\";alias -kf_fov_D\"script _kf_fov_D(0)\"");

SendToConsole("clear;script OnPostSpawn()");

VS.GetLocalPlayer();
ROOT <- getroottable();
if( this != ROOT ) throw "Script not executed through console";;

// don't overwrite user settings
if( !("_kfb283821b6a" in this) ) _kfb283821b6a <- false;;
if( !("_kfb283821B6a" in this) ) _kfb283821B6a <- true;;
if( !("_kfb283821bBa" in this) ) _kfb283821bBa <- -1;;
if( !("_kfb283821bB4" in this) ) _kfb283821bB4 <- 0.01;;
if( !("_kfb2B3821bB4" in this) ) _kfb2B3821bB4 <- 25;;
if( !("_kfb283821BB4" in this) ) _kfb283821BB4 <- 0;;
if( !("_kfb283B21bB4" in this) ) _kfb283B21bB4 <- true;;
if( !("_kfb283B21bBa" in this) ) _kfb283B21bBa <- true;;
if( !("_kf82bE821bBA" in this) ) _kf82bE821bBA <- false;;
if( !("_kf82bEB2lbBA" in this) ) _kf82bEB2lbBA <- [];;
if( !("_kf8ZbEB2lbBA" in this) ) _kf8ZbEB2lbBA <- [];;
_db36Slt4ATef <- floor(1.0/_kfb283821bB4);

__roll_R <- false;
__roll_L <- false;
__fov_U <- false;
__fov_D <- false;
_kf82b38Z1BB4 <- 90;
if( Msg != printl ) Msg <-printl;;

_kfb283B21b8a <- FrameTime()*6;

local _ = function()
{
	if( !("_kfb283BZ1b8a" in this) )
	{
		// holds playback status
		_kfb283BZ1b8a <- VS.CreateTimer("", FTIME);
		VS.MakePermanent(_kfb283BZ1b8a);

		// holds edit mode status
		_kfb283B2lbBa <- VS.CreateTimer("", _kfb283B21b8a-FrameTime());
		VS.MakePermanent(_kfb283B2lbBa);

		_kfb283B2tbBa <- VS.CreateTimer("", FrameTime()*2.5);
		VS.MakePermanent(_kfb283B2tbBa);

		_kfB2B38Z1bBa <- VS.CreateGameText("",{
			channel = 1,
			color = Vector(255,138,0),
			holdtime = _kfb283B21b8a,
			x = 0.475,
			y = 0.55
		});
		_kfB2B38Z1bB4 <- VS.CreateGameText("",{
			channel = 2,
			color = Vector(255,138,0),
			holdtime = _kfb283B21b8a,
			x = 0.56,
			y = 0.485
		});
		VS.MakePermanent(_kfB2B38Z1bBa);
		VS.MakePermanent(_kfB2B38Z1bB4);

		_kfB2B38ZlbB4 <- VS.CreateHudHint("");
		VS.MakePermanent(_kfB2B38ZlbB4);

		HPlayerEye <- VS.CreateMeasure(HPlayer.GetName(),null,true);

		// holds compile status
		_kfB2B382lbB4 <- VS.CreateEntity("point_viewcontrol", null, { spawnflags = 1<<3 });

		// holds player noclip status
		_kfB2B3821bBA <- VS.CreateEntity("game_ui", null, { spawnflags = 1<<7, fieldofview = -1.0 });

		VS.AddOutput(_kfB2B3821bBA, "UnpressedAttack",  "dummy");
		VS.AddOutput(_kfB2B3821bBA, "UnpressedAttack2", "dummy");

		// VS.AddOutput(_kfB2B3821bBA, "PlayerOn",  "dummy");
		// VS.AddOutput(_kfB2B3821bBA, "PlayerOff", "dummy");

		VS.MakePermanent(_kfB2B3821bBA);

		PrecacheModel("keyframes/kf_circle_orange.vmt");

		_kfB2bEB2lbB4 <- VS.CreateEntity("env_sprite",null,
		{
			// only 8 works when spawned through script
			rendermode = 8,
			glowproxysize = 64.0, // MAX_GLOW_PROXY_SIZE
			effects = EF.OFF
		});

		_kfB2bEB2lbB4.SetModel("keyframes/kf_circle_orange.vmt");
		VS.MakePermanent(_kfB2bEB2lbB4);

// model EF
// ON  = 16392, // ((1<<14)|(1<<3))|0
// OFF = 16424  // ((1<<14)|(1<<3))|(1<<5)

//		PrecacheModel("models/tools/rotate_widget.mdl");
//		_kfB2bEB2lbB4 <- CreateProp("prop_dynamic_override",Vector(),"models/tools/rotate_widget.mdl",0);
//		VS.SetKeyInt(_kfB2bEB2lbB4, "effects", EF.OFF);
//		VS.SetKeyFloat(_kfB2bEB2lbB4, "modelscale", 2.0);
	};

	// build loading string
	if( !("_kf82b3821bbA" in this) )
		{
			local i1 = -1,
				  i2 = 0,
				  d = "●",
				  b = " ",
				  a = array(64,b);

			_kfbZ83B21b8a <- 0;
			_kf82b3821bbA <- [];

			for( local i = 0; i < 64; i++ )
			{
				++i1;
				++i2;
				i1 %= 64;
				i2 %= 64;

				a[i1] = b;
				a[i2] = d;

				local t = "";

				foreach(s in a) t += s;

				_kf82b3821bbA.append(t);
			}
		};

	// precache materials
	DebugDrawLine(Vector(),Vector(1,1,1),0,0,0,true,FrameTime());
	DebugDrawBox(Vector(),Vector(),Vector(1,1,1),0,0,0,1,FrameTime());
}();

function OnPostSpawn()
{
	if( HPlayer.GetTeam() != 2 && HPlayer.GetTeam() != 3 ) HPlayer.SetTeam(2);

	HPlayer.SetHealth(1337);

	// key listener
	EntFireByHandle(_kfB2B3821bBA, "activate", "", 0, HPlayer);

	// ListenMouse
	_kfB2BEB21bBA(1);

	PlaySound("Player.DrownStart");

	ClearChat();
	Chat(txt.blue+" -------------------------------- ");
	Chat(txt.orange+"> "+txt.lightgreen+"Loaded camera smoothing script");
	Chat(txt.orange+"> Use the console commands to control the script.");
	Chat(txt.orange+"> '"+txt.white+"kf_cmd" + txt.orange + "' to print all commands.");
	Chat(txt.blue+" -------------------------------- ");

	// print after Steamworks Msg
	if( GetDeveloperLevel() > 0 ) delay("SendToConsole(\"clear;script _kfB2bEB2lbba()\")", 0.75);
	else _kfB2bEB2lbba();
}

// welcome msg
function _kfB2bEB2lbba()
{
	Msg("\n\n\n   [v"+_VER_+"]     github.com/samisalreadytaken/keyframes\n\nkf_add                : Add new keyframe\nkf_remove             : Remove the selected key\nkf_remove_undo        : Undo last remove action\nkf_removefov          : Remove the FOV data from the selected key\nkf_clear              : Remove all keyframes\nkf_insert             : Insert new keyframe after the selected key\nkf_replace            : Replace the selected key\nkf_replace_undo       : Undo last replace action\n                      :\nkf_compile            : Compile the keyframe data\nkf_play               : Play the compiled data\nkf_stop               : Stop playback\nkf_save               : Save the compiled data\nkf_savekeys           : Save the keyframe data\n                      :\nkf_mode_angle         : Toggle stabilised angles algorithm\n                      :\nkf_edit               : Toggle edit mode\nkf_select             : In edit mode, hold the current selection\nkf_see                : In edit mode, see the current selection\nkf_next               : While holding a key, select the next one\nkf_prev               : While holding a key, select the previous one\nkf_showkeys           : In edit mode, toggle showing keyframes\nkf_showpath           : In edit mode, toggle showing the path\n                      :\nscript fov(val)       : Set FOV data on the selected key\nscript tilt(val)      : Set camera tilt on the selected key\n                      :\nscript load(input)    : Load new data from file\n                      :\nkf_cmd                : List all commands\n\n--- --- --- --- --- ---\n\nMOUSE1                : kf_add\nMOUSE2                : kf_remove\nE                     : kf_see\nA / D                 : (In see mode) Set camera tilt\nW / S                 : (In see mode) Set camera FOV\nMOUSE1                : (In see mode) kf_next\nMOUSE2                : (In see mode) kf_prev\n");

	local T = VS.GetTickrate();

	if( !VS.IsInteger( 128.0 / T ) )
	{
		Msg("[!] Invalid tickrate ( " + T + " )! Only 128 and 64 ticks are supported.");
		Chat(txt.red+"[!] "+txt.white+"Invalid tickrate ( " +txt.yellow+ T +txt.white+" )! Only 128 and 64 ticks are supported.");
	};
}

// kf_cmd
function _kfB2bEB21bba()
{
//	Msg(@"
//[i] See README.md for details.
//
//   [v1.0.0]     github.com/samisalreadytaken/keyframes
//
//kf_add                : Add new keyframe
//kf_remove             : Remove the selected key
//kf_remove_undo        : Undo last remove action
//kf_removefov          : Remove the FOV data from the selected key
//kf_clear              : Remove all keyframes
//kf_insert             : Insert new keyframe after the selected key
//kf_replace            : Replace the selected key
//kf_replace_undo       : Undo last replace action
//                      :
//kf_compile            : Compile the keyframe data
//kf_play               : Play the compiled data
//kf_stop               : Stop playback
//kf_save               : Save the compiled data
//kf_savekeys           : Save the keyframe data
//                      :
//kf_mode_angle         : Toggle stabilised angles algorithm
//                      :
//kf_edit               : Toggle edit mode
//kf_select             : In edit mode, hold the current selection
//kf_see                : In edit mode, see the current selection
//kf_next               : While holding a key, select the next one
//kf_prev               : While holding a key, select the previous one
//kf_showkeys           : In edit mode, toggle showing keyframes
//kf_showpath           : In edit mode, toggle showing the path
//                      :
//script fov(val)       : Set FOV data on the selected key
//script tilt(val)      : Set camera tilt on the selected key
//                      :
//script load(input)    : Load new data from file
//                      :
//kf_cmd                : List all commands
//
//--- --- --- --- --- ---
//
//MOUSE1                : kf_add
//MOUSE2                : kf_remove
//E                     : kf_see
//A / D                 : (In see mode) Set camera tilt
//W / S                 : (In see mode) Set camera FOV
//MOUSE1                : (In see mode) kf_next
//MOUSE2                : (In see mode) kf_prev
//");

	Msg("\n[i] See README.md for details.\n\n   [v"+_VER_+"]     github.com/samisalreadytaken/keyframes\n\nkf_add                : Add new keyframe\nkf_remove             : Remove the selected key\nkf_remove_undo        : Undo last remove action\nkf_removefov          : Remove the FOV data from the selected key\nkf_clear              : Remove all keyframes\nkf_insert             : Insert new keyframe after the selected key\nkf_replace            : Replace the selected key\nkf_replace_undo       : Undo last replace action\n                      :\nkf_compile            : Compile the keyframe data\nkf_play               : Play the compiled data\nkf_stop               : Stop playback\nkf_save               : Save the compiled data\nkf_savekeys           : Save the keyframe data\n                      :\nkf_mode_angle         : Toggle stabilised angles algorithm\n                      :\nkf_edit               : Toggle edit mode\nkf_select             : In edit mode, hold the current selection\nkf_see                : In edit mode, see the current selection\nkf_next               : While holding a key, select the next one\nkf_prev               : While holding a key, select the previous one\nkf_showkeys           : In edit mode, toggle showing keyframes\nkf_showpath           : In edit mode, toggle showing the path\n                      :\nscript fov(val)       : Set FOV data on the selected key\nscript tilt(val)      : Set camera tilt on the selected key\n                      :\nscript load(input)    : Load new data from file\n                      :\nkf_cmd                : List all commands\n\n--- --- --- --- --- ---\n\nMOUSE1                : kf_add\nMOUSE2                : kf_remove\nE                     : kf_see\nA / D                 : (In see mode) Set camera tilt\nW / S                 : (In see mode) Set camera FOV\nMOUSE1                : (In see mode) kf_next\nMOUSE2                : (In see mode) kf_prev\n");
}

function PlaySound(s)
{
	HPlayer.EmitSound(s);
}

function Hint(s)
{
	VS.ShowHudHint(_kfB2B38ZlbB4, HPlayer, s);
}

function Error(s)
{
	Msg(s);
	PlaySound("Bot.Stuck2");
}

function MsgFail(s)
{
	Msg(s);
	// PlaySound("Player.WeaponSelected");
	PlaySound("UIPanorama.buymenu_failure");
}

function MsgHint(s)
{
	Msg(s);
	Hint(s);
}

function DrawOverlay(i)
{
	if( i == 0 ) return SendToConsole("r_screenoverlay\"\"");
	if( i == 1 ) return SendToConsole("r_screenoverlay\"keyframes/kf_dot_orange\"");
	if( i == 2 ) return SendToConsole("r_screenoverlay\"keyframes/kf_dot_red\"");
}

function load(i)
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot load file while compiling!");

	if( typeof i != "table" )
		return MsgFail("Invalid input.");

	if( !("pos" in i) || !("ang" in i) )
	// {
		// if( ++nLoadCount > 1 )
		// {
			// nLoadCount = 0;
			return MsgFail("Invalid input.");
		// };

		// try(IncludeScript("keyframes_data"))catch(e){}

		// return delay("load.call(ROOT,"+VS.GetTableName(input)+")");
	// };

	// nLoadCount = 0;

	Msg("\nPreparing to load...");
	PlaySound("UIPanorama.container_countdown");

	// keyframe data
	if( "anq" in i )
	{
		if( !("__lp_c" in this) || !("__la_c" in this) )
		{
			__lp_c <- [];
			__la_c <- [];
			__la_q <- [];
			__la_f <- [];
		};

		__lp_o <- __lp_c;
		__la_o <- __la_c;
		__lq_o <- __la_q;
		__lf_o <- __la_f;

		__lq_o.resize(i.anq.len());
	}
	// path data
	else
	{
		if( !("__lp_k" in this) || !("__la_k" in this) || !("__la_v" in this) )
		{
			__lp_k <- [];
			__la_k <- [];
			__la_v <- [];
		};

		__lp_o <- __lp_k;
		__la_o <- __la_k;
		__lf_o <- __la_v;
	};

	if( __lp_o.len() != __la_o.len() )
		return Error("[ERROR] Corrupted data!");

	__lp_o.resize(i.pos.len());
	__la_o.resize(i.ang.len());

	if( "fov" in i )
		__lf_o.resize(i.fov.len());

	__ll_o <- i;

	_dBebSlTa4T3F <- i.pos.len();
	_dBebSlTa4t3F <- 1450;
	_dBebSlTa4tef <- 0;
	_dBebSlTa4teF <- clamp(_dBebSlTa4t3F, 0, _dBebSlTa4T3F);

	print("Loading data...\n>.");

	_kfB2bEB21bb4();
}

function _kfB2bEB21bb4()
{
	if( "pos" in __ll_o )
	{
		if( _dBebSlTa4tef >= _dBebSlTa4teF )
		{
			print("\n>.");

			delete::__lp_o;
			delete::__ll_o["pos"];

			_dBebSlTa4tef = 0;
			_dBebSlTa4teF = clamp(_dBebSlTa4t3F, 0, _dBebSlTa4T3F);
			return _kfB2bEB21bb4();
		};

		// if(!(_dBebSlTa4tef % 25))
		print(".");

		for( local i = _dBebSlTa4tef; i < _dBebSlTa4teF; i++ )
			__lp_o[i] = __ll_o["pos"][i].V();

		_dBebSlTa4tef += _dBebSlTa4t3F;
		_dBebSlTa4teF = clamp(_dBebSlTa4teF + _dBebSlTa4t3F, 0, _dBebSlTa4T3F);

		return delay( "_kfB2bEB21bb4.call(ROOT)", FTIME );
	};

	if( "ang" in __ll_o )
	{
		if( _dBebSlTa4tef >= _dBebSlTa4teF )
		{
			print("\n>.");

			delete::__la_o;
			delete::__ll_o["ang"];

			_dBebSlTa4tef = 0;
			_dBebSlTa4teF = clamp(_dBebSlTa4t3F, 0, _dBebSlTa4T3F);
			return _kfB2bEB21bb4();
		};

		// if(!(_dBebSlTa4tef % 25))
		print(".");

		for( local i = _dBebSlTa4tef; i < _dBebSlTa4teF; i++ )
			__la_o[i] = __ll_o["ang"][i].V();

		_dBebSlTa4tef += _dBebSlTa4t3F;
		_dBebSlTa4teF = clamp(_dBebSlTa4teF + _dBebSlTa4t3F, 0, _dBebSlTa4T3F);

		return delay( "_kfB2bEB21bb4.call(ROOT)", FTIME );
	};

	if( "anq" in __ll_o )
	{
		if( _dBebSlTa4tef >= _dBebSlTa4teF )
		{
			print("\n>.");

			delete::__lq_o;
			delete::__ll_o["anq"];

			_dBebSlTa4tef = 0;
			_dBebSlTa4teF = clamp(_dBebSlTa4t3F, 0, _dBebSlTa4T3F);
			return _kfB2bEB21bb4();
		};

		// if(!(_dBebSlTa4tef % 5))
		print(".");

		for( local i = _dBebSlTa4tef; i < _dBebSlTa4teF; i++ )
			__lq_o[i] = __ll_o["anq"][i].V();

		_dBebSlTa4tef += _dBebSlTa4t3F;
		_dBebSlTa4teF = clamp(_dBebSlTa4teF + _dBebSlTa4t3F, 0, _dBebSlTa4T3F);

		return delay( "_kfB2bEB21bb4.call(ROOT)", FTIME );
	};

	if( "fov" in __ll_o )
	{
		print(".");

		foreach( i, a in __ll_o["fov"] )
			__lf_o[i] = clone a;

		delete::__ll_o["fov"];

		return _kfB2bEB21bb4();
	};

	PlaySound("UIPanorama.container_countdown");
	return Msg("\n\nData loaded! " + VS.GetVarName(delete::__ll_o));
}

// see mode listen WASD
// ListenKeys
function _kfB2B3B21bBA(i)
{
	if(i)
	{
		_kfB2BEB21bBA(0);

		// kf_next
		VS.AddOutput(_kfB2B3821bBA, "PressedAttack", _kfb283821bBx);

		// kf_prev
		VS.AddOutput(_kfB2B3821bBA, "PressedAttack2", _kfb283821bBp);

		_kfB2B3821bBA.ConnectOutput("PressedMoveRight","PressedMoveRight");
		_kfB2B3821bBA.ConnectOutput("UnpressedMoveRight","UnpressedMoveRight");
		_kfB2B3821bBA.ConnectOutput("PressedMoveLeft","PressedMoveLeft");
		_kfB2B3821bBA.ConnectOutput("UnpressedMoveLeft","UnpressedMoveLeft");
		_kfB2B3821bBA.ConnectOutput("PressedForward","PressedForward");
		_kfB2B3821bBA.ConnectOutput("UnpressedForward","UnpressedForward");
		_kfB2B3821bBA.ConnectOutput("PressedBack","PressedBack");
		_kfB2B3821bBA.ConnectOutput("UnpressedBack","UnpressedBack");

		_kfB2B3821bBA.SetTeam(HPlayer.IsNoclipping().tointeger());

		// freeze player
		VS.SetKeyInt(HPlayer,"movetype",0);
	}
	else
	{
		_kfB2B3821bBA.DisconnectOutput("PressedAttack","PressedAttack");
		_kfB2B3821bBA.DisconnectOutput("PressedAttack2","PressedAttack2");
		_kfB2B3821bBA.DisconnectOutput("PressedMoveRight","PressedMoveRight");
		_kfB2B3821bBA.DisconnectOutput("UnpressedMoveRight","UnpressedMoveRight");
		_kfB2B3821bBA.DisconnectOutput("PressedMoveLeft","PressedMoveLeft");
		_kfB2B3821bBA.DisconnectOutput("UnpressedMoveLeft","UnpressedMoveLeft");
		_kfB2B3821bBA.DisconnectOutput("PressedForward","PressedForward");
		_kfB2B3821bBA.DisconnectOutput("UnpressedForward","UnpressedForward");
		_kfB2B3821bBA.DisconnectOutput("PressedBack","PressedBack");
		_kfB2B3821bBA.DisconnectOutput("UnpressedBack","UnpressedBack");

		VS.SetKeyInt(HPlayer,"movetype",_kfB2B3821bBA.GetTeam()?8:2);

		_kfB2B3821bBA.SetTeam(HPlayer.IsNoclipping().tointeger());
	};
}

// default listen MOUSE1, MOUSE2
// ListenMouse
function _kfB2BEB21bBA(i)
{
	if(i)
	{
		_kfB2B3B21bBA(0);

		// kf_add
		VS.AddOutput(_kfB2B3821bBA, "PressedAttack",  _kf82b3BZ1bBA);

		// kf_remove
		VS.AddOutput(_kfB2B3821bBA, "PressedAttack2", _kf82b38Z1bbA);

		VS.SetKeyInt(HPlayer,"movetype",_kfB2B3821bBA.GetTeam()?8:2);
	}
	else
	{
		_kfB2B3821bBA.DisconnectOutput("PressedAttack","PressedAttack");
		_kfB2B3821bBA.DisconnectOutput("PressedAttack2","PressedAttack2");
	};
}

// This exists only to be able to (dis)connect outputs, ultimately to have only one game_ui entity
VS.AddOutput(_kfB2B3821bBA, "PressedMoveRight",  function()_kf_roll_R(1));
VS.AddOutput(_kfB2B3821bBA, "UnpressedMoveRight",function()_kf_roll_R(0));
VS.AddOutput(_kfB2B3821bBA, "PressedMoveLeft",   function()_kf_roll_L(1));
VS.AddOutput(_kfB2B3821bBA, "UnpressedMoveLeft", function()_kf_roll_L(0));
VS.AddOutput(_kfB2B3821bBA, "PressedForward",    function()_kf_fov_U(1));
VS.AddOutput(_kfB2B3821bBA, "UnpressedForward",  function()_kf_fov_U(0));
VS.AddOutput(_kfB2B3821bBA, "PressedBack",       function()_kf_fov_D(1));
VS.AddOutput(_kfB2B3821bBA, "UnpressedBack",     function()_kf_fov_D(0));

// +use to see
VS.AddOutput(_kfB2B3821bBA, "PlayerOff", function(){_kf82bE82lbBA();EntFireByHandle(_kfb283B2tbBa,"disable");__fov_U=false;__fov_D=false;__roll_R=false;__roll_L=false;EntFireByHandle(_kfB2B3821bBA,"activate","",0,HPlayer)});

// Think keys roll
function _kf82bE8Z1BBA()
{
	if( __roll_R )
	{
		_kf82bE8Z1BB4.z = clamp(floor(_kf82bE8Z1BB4.z)+4, -180, 180);
		VS.SetAngles(_kfB2B382lbB4, _kf82bE8Z1BB4);
		Hint("Tilt "+_kf82bE8Z1BB4.z);
	}
	else if( __roll_L )
	{
		_kf82bE8Z1BB4.z = clamp(floor(_kf82bE8Z1BB4.z)-4, -180, 180);
		VS.SetAngles(_kfB2B382lbB4, _kf82bE8Z1BB4);
		Hint("Tilt "+_kf82bE8Z1BB4.z);
	};;

	PlaySound("UIPanorama.store_item_rollover");
}

// Think keys fov
function _kf82bE8Z1bBA()
{
	local f = FrameTime()*6;

	if( __fov_U )
	{
		_kf82b38Z1BB4 = clamp(_kf82b38Z1BB4-2,1,179);
		Hint("FOV "+_kf82b38Z1BB4);
		_kfB2B382lbB4.SetFov(_kf82b38Z1BB4,f);
	}
	else if( __fov_D )
	{
		_kf82b38Z1BB4 = clamp(_kf82b38Z1BB4+2,1,179);
		Hint("FOV "+_kf82b38Z1BB4);
		_kfB2B382lbB4.SetFov(_kf82b38Z1BB4,f);
	};;

	PlaySound("UIPanorama.store_item_rollover");
}

// roll clockwise
function _kf_roll_R(i)
{
	if(i)
	{
		if( !_kf82bE821bBA )
			return MsgFail("You need to be in see mode to use the key controls.");

		VS.OnTimer(_kfb283B2tbBa,_kf82bE8Z1BBA);
		_kf82bE8Z1BB4 <- VS.QuaternionAngles2(__la_q[_kfb283821BB4],Vector());

		__roll_R = true;
		EntFireByHandle(_kfb283B2tbBa, "enable");
	}
	else
	{
		if( !_kf82bE821bBA ) return;

		__roll_R = false;
		EntFireByHandle(_kfb283B2tbBa, "disable");

		// save last set data
		__la_q[_kfb283821BB4] = VS.AngleQuaternion(_kf82bE8Z1BB4,Quaternion());
	};
}

// roll counter-clockwise
function _kf_roll_L(i)
{
	if(i)
	{
		if( !_kf82bE821bBA )
			return MsgFail("You need to be in see mode to use the key controls.");

		VS.OnTimer(_kfb283B2tbBa,_kf82bE8Z1BBA);
		_kf82bE8Z1BB4 <- VS.QuaternionAngles2(__la_q[_kfb283821BB4],Vector());

		__roll_L = true;
		EntFireByHandle(_kfb283B2tbBa, "enable");
	}
	else
	{
		if( !_kf82bE821bBA ) return;

		__roll_L = false;
		EntFireByHandle(_kfb283B2tbBa, "disable");

		// save last set data
		__la_q[_kfb283821BB4] = VS.AngleQuaternion(_kf82bE8Z1BB4,Quaternion());
	};
}

// fov in
function _kf_fov_U(i)
{
	if(i)
	{
		if( !_kf82bE821bBA )
			return MsgFail("You need to be in see mode to use the key controls.");

		VS.OnTimer(_kfb283B2tbBa,_kf82bE8Z1bBA);
		_kf82b38Z1BB4 = 90;
		__fov_U = true;
		EntFireByHandle(_kfb283B2tbBa, "enable");

		// get current fov value
		foreach( i,v in __la_f ) if( v[0] == _kfb283821BB4 )
		{
			_kf82b38Z1BB4 = v[1] ? v[1] : 90;
			return;
		};

		// if the key doesnt have any fov data, create one
		__la_f.append([_kfb283821BB4,0,0]);
	}
	else
	{
		if( !_kf82bE821bBA ) return;

		__fov_U = false;
		EntFireByHandle(_kfb283B2tbBa, "disable");

		foreach( i,v in __la_f ) if( v[0] == _kfb283821BB4 )
			v[1] = _kf82b38Z1BB4;
	};
}

// fov out
function _kf_fov_D(i)
{
	if(i)
	{
		if( !_kf82bE821bBA )
			return MsgFail("You need to be in see mode to use the key controls.");

		VS.OnTimer(_kfb283B2tbBa,_kf82bE8Z1bBA);
		_kf82b38Z1BB4 = 90;
		__fov_D = true;
		EntFireByHandle(_kfb283B2tbBa, "enable");

		// get current fov value
		foreach( i,v in __la_f ) if( v[0] == _kfb283821BB4 )
		{
			_kf82b38Z1BB4 = v[1] ? v[1] : 90;
			return;
		};

		// if the key doesnt have any fov data, create one
		__la_f.append([_kfb283821BB4,0,0]); // -1
	}
	else
	{
		if( !_kf82bE821bBA ) return;

		__fov_D = false;
		EntFireByHandle(_kfb283B2tbBa, "disable");

		foreach( i,v in __la_f ) if( v[0] == _kfb283821BB4 )
			v[1] = _kf82b38Z1BB4;
	};
}

function _kfB283B21bBA(t)
{
	// kf_showpath
	if(t)
	{
		_kfb283B21bB4 = !_kfb283B21bB4;
		Msg(_kfb283B21bB4?"Showing path":"Hiding path");
	}
	// kf_showkeys
	else
	{
		_kfb283B21bBa = !_kfb283B21bBa;
		Msg(_kfb283B21bBa?"Showing keyframes":"Hiding keyframes");
	};

	SendToConsole("clear_debug_overlays");
	PlaySound("UIPanorama.container_countdown");
}

// kf_edit
function _kfB2b3821bb4()
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot "+(_kfb283B2lbBa.GetTeam()?"disable":"enable")+" edit mode while compiling!");

	local a,b;

	if( !("__lp_c" in this) || !("__la_c" in this) || !__lp_c.len() )
	{
		a = true;
		Msg("No keyframes found.");
		__lp_c <- [];
		__la_c <- [];
	};

	if( !("__lp_k" in this) || !("__la_k" in this) || !__lp_k.len() )
	{
		Msg("No path data found.");
		b = true;
		__lp_k <- [];
		__la_k <- [];
	};

	if( a&&b )
		return MsgFail("Cannot enable the edit mode!");

	// toggle
	_kfb283B2lbBa.SetTeam((!_kfb283B2lbBa.GetTeam()).tointeger());

	// on
	if( _kfb283B2lbBa.GetTeam() )
	{
		if( developer() > 1 )
		{
			Msg("Setting developer level to 1");
			SendToConsole("developer 1");
		};

		DrawOverlay(1);
		SendToConsole("cl_drawhud 1");
		VS.SetKeyInt(_kfB2bEB2lbB4, "effects", EF.ON);
		EntFireByHandle(_kfb283B2lbBa, "enable");

		Msg("Edit mode enabled.");
	}
	// off
	else
	{
		// unsee
		if( _kf82bE821bBA )
			_kf82bE82lbBA(1);

		DrawOverlay(0);
		VS.SetKeyInt(_kfB2bEB2lbB4, "effects", EF.OFF);
		EntFireByHandle(_kfb283B2lbBa, "disable");
		EntFireByHandle(_kfB2B38Z1bB4, "settext", "", 0, HPlayer);

		Msg("Edit mode disabled.");
	};

	SendToConsole("clear_debug_overlays");
	PlaySound("UIPanorama.container_countdown");
}

// kf_select
function _kf82b3821bb4()
{
	if( !_kfb283B2lbBa.GetTeam() )
		return MsgFail("You need to be in edit mode to select.");

	// ( _kfb283821bBa != _kfb283821BB4 )
	if( _kfb283821bBa == -1 )
	{
		_kfb283821bBa = _kfb283821BB4;

		MsgHint("Selected key #" + _kfb283821bBa);
	}
	else
	{
		MsgHint("Unselected key #" + _kfb283821bBa);

		// if seeing a selected key, unsee
		if( _kf82bE821bBA )
			_kf82bE82lbBA(1);

		_kfb283821bBa = -1;
	};

	PlaySound("UIPanorama.container_countdown");
}

// kf_next
function _kfb283821bBx()
{
	if( _kfb283821bBa == -1 )
		return MsgFail("You need to have a key selected to use kf_next.");

	local t = (_kfb283821bBa+1) % __lp_c.len(),
	      b = _kf82bE821bBA;

	// unsee silently
	if(b)
		_kf82bE82lbBA(1);

	_kfb283821bBa = t;
	_kfb283821BB4 = t;

	// then see again
	if(b)
		_kf82bE82lbBA();
}

// kf_prev
function _kfb283821bBp()
{
	if( _kfb283821bBa == -1 )
		return MsgFail("You need to have a key selected to use kf_prev.");

	// local t = clamp(_kfb283821bBa-1,0,__lp_c.len()-1),

	local n = _kfb283821bBa-1;

	if( n < 0 )
		n += __lp_c.len();

	local t = n % __lp_c.len(),
	      b = _kf82bE821bBA;

	// unsee silently
	if(b)
		_kf82bE82lbBA(1);

	_kfb283821bBa = t;
	_kfb283821BB4 = t;

	// then see again
	if(b)
		_kf82bE82lbBA();
}

// kf_see
// if i == true, unsee. NO error and safety checks
// TODO: a better method?
function _kf82bE82lbBA(i=0)
{
	if(i)
	{
		_kfB2B3821bB4();
		_kf82bE821bBA = false;
		if( _kfb283821bBa != -1 ) _kf82b3821bb4();
		VS.SetKeyInt(_kfB2bEB2lbB4, "effects", EF.ON);
		_kfB2B382lbB4.SetFov(0,0.1);
		EntFireByHandle(_kfB2B382lbB4, "disable", "", 0, HPlayer);
		_kfB2BEB21bBA(1);
		return;
	};

	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot modify keyframes while compiling!");

	if( _kfb283BZ1b8a.GetTeam() || _kfb283821b6a )
		return MsgFail("Cannot use see while in playback!");

	if( !_kfb283B2lbBa.GetTeam() )
		return MsgFail("You need to be in edit mode to use see.");

	_kf82bE821bBA = !_kf82bE821bBA;

	if( _kf82bE821bBA )
	{
		// if not selected, select
		if( _kfb283821bBa == -1 )
			_kf82b3821bb4();

		// hide the helper
		VS.SetKeyInt(_kfB2bEB2lbB4, "effects", EF.OFF);

		// set fov and pos to selected
		foreach( v in __la_f ) if( v[0] == _kfb283821bBa )
			_kfB2B382lbB4.SetFov(v[1],0.25);

		_kfB2B382lbB4.SetAbsOrigin(__lp_c[_kfb283821bBa]);
		VS.SetAngles(_kfB2B382lbB4, VS.QuaternionAngles2(__la_q[_kfb283821bBa]));
		EntFireByHandle(_kfB2B382lbB4, "enable", "", 0, HPlayer);

		// ListenKeys
		_kfB2B3B21bBA(1);

		MsgHint("Seeing key #"+_kfb283821bBa);
	}
	else
	{
		// compile fov
		_kfB2B3821bB4();

		// if selected, unselect
		if( _kfb283821bBa != -1 )
			_kf82b3821bb4();

		VS.SetKeyInt(_kfB2bEB2lbB4, "effects", EF.ON);
		_kfB2B382lbB4.SetFov(0,0.1);
		EntFireByHandle(_kfB2B382lbB4, "disable", "", 0, HPlayer);
		// _kfB2B3B21bBA(0);

		// ListenMouse
		_kfB2BEB21bBA(1);

		MsgHint("Stopped seeing.");
	};

	PlaySound("UIPanorama.container_countdown");
}

function tilt(v)
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot modify keyframes while compiling!");

	if( !_kfb283B2lbBa.GetTeam() )
		return MsgFail("You need to be in edit mode to use camera tilt.");

	v = VS.AngleNormalize(v.tofloat());

	local a = VS.QuaternionAngles2(__la_q[_kfb283821BB4]);

	a.z = v;

	__la_q[_kfb283821BB4] = VS.AngleQuaternion(a,Quaternion());

	// refresh
	if( _kf82bE821bBA )
	{
		if( _kfb283821bBa == -1 )
			return Error("[ERROR] Assertion failed. Seeing while no key is selected.");

		VS.SetAngles(_kfB2B382lbB4, VS.QuaternionAngles2(__la_q[_kfb283821bBa]));
	};

	MsgHint("Set key #" + _kfb283821BB4 + " tilt to " + v);
	PlaySound("UIPanorama.container_countdown");
}

// Think UI
VS.OnTimer(_kfb283B2lbBa,function()
{
	local keys = __lp_c,
	      time = _kfb283B21b8a;

	if(keys.len())
	{
		local h = "",
		      vi = Vector(-8,-8,-8),
		      vx = Vector(8,8,8);

		// look
		// not selected any key
		if( _kfb283821bBa == -1 )
		{
			local k = keys.len()-1,
			      b = 0.9, // threshold
			      E = HPlayer.EyePosition(),
			      D = HPlayerEye.GetForwardVector();

			foreach( i, v in keys )
			{
				local d = v - E;
				d.Norm();
				local d = D.Dot(d);

				if( d > b )
				{
					k = i;
					b = d;
				};

				if( _kfb283B21bBa )
					DebugDrawBox(v, vi, vx, 255, 0, 0, 0, time);
			}

			// selected
			_kfb283821BB4 = k;
		}
		else if( _kfb283B21bBa )
		{
			h = " (HOLD)";

			foreach( i, v in keys )
				DebugDrawBox(v, vi, vx, 255, 0, 0, 0, time);
		};;

		// proximity
//		else
//		{
//			local flMaxDistSqr = 262144;
//
//			foreach( i, v in keys )
//			{
//				local flDistSqr = (HPlayer.EyePosition()-v).LengthSqr();
//
//				if( flMaxDistSqr > flDistSqr )
//				{
//					k = i;
//					flMaxDistSqr = flDistSqr;
//				};
//
//				if( _kfb283B21bBa )
//					DebugDrawBox(v, Vector(-8,-8,-8), Vector(8,8,8), 255, 0, 0, 0, time);
//			}
//		};

		// show fov
		foreach( v in __la_f ) if( v[0] == _kfb283821BB4 )
			VS.SetKeyString(_kfB2B38Z1bB4, "message", "FOV: " + v[1]);

		VS.SetKeyString(_kfB2B38Z1bBa, "message", "KEY: " + _kfb283821BB4 + h);
		EntFireByHandle(_kfB2B38Z1bBa, "display", "", 0, HPlayer);
		EntFireByHandle(_kfB2B38Z1bB4, "display", "", 0, HPlayer);
		EntFireByHandle(_kfB2B38Z1bB4, "settext", "", 0, HPlayer);

		local k = keys[_kfb283821BB4];

		// selected key
		DebugDrawBox(k, vi, vx, 255, 138, 0, 255, time);
		_kfB2bEB2lbB4.SetOrigin(k);

//		if( !bMoveMode )
//		{
//		}
//		else
//		{
//			_kfB2bEB2lbB4.SetOrigin(Vector());
//			hHelperTranslate.SetOrigin(k);
//
//			local ORIG = HPlayer.EyePosition();
//			local tr = VS.TraceDir(ORIG, HPlayerEye.GetForwardVector()).Ray();
//
//			local origX = k; //+ Vector(32,0,0);
//			local minsX = Vector(-54,-3,-3);
//			local maxsX = Vector(54,3,3);
//
//			if( VS.IsBoxIntersectingRay(origX, minsX, maxsX, tr, 0.5) )
//			{
//				Hint("X")
//
//				DebugDrawLine(k, k - Vector(-128,0,0), 255, 255, 255, true, time);
//				DebugDrawBox(origX, minsX, maxsX, 255, 0, 0, 154, time);
//			}
//			else
//			{
//				local origY = k; //+ Vector(0,32,0);
//				local minsY = Vector(-3,-54,-3);
//				local maxsY = Vector(3,54,3);
//
//				if( VS.IsBoxIntersectingRay(origY, minsY, maxsY, tr, 0.5) )
//				{
//					Hint("Y")
//
//					DebugDrawLine(k, k - Vector(0,-128,0), 255, 255, 255, true, time);
//					DebugDrawBox(origY, minsY, maxsY, 0, 255, 0, 154, time);
//				}
//				else
//				{
//					local origZ = k; //+ Vector(0,0,32);
//					local minsZ = Vector(-3,-3,-54);
//					local maxsZ = Vector(3,3,54);
//
//					if( VS.IsBoxIntersectingRay(origZ, minsZ, maxsZ, tr, 0.5) )
//					{
//						Hint("Z")
//
//						DebugDrawLine(k, k + Vector(0,0,128),  255, 255, 255, true, time);
//						DebugDrawBox(origZ, minsZ, maxsZ, 0, 0, 255, 127, time);
//					};
//				};
//			};
//		};
	};

	// show path
	if( _kfb283B21bB4 )
	{
		local Y = _kfb2B3821bB4,
		      k = __lp_k,
		      a = __la_k,
		      L = DebugDrawLine,
		      A = VS.AngleVectors,
		      n = __lp_k.len()-Y;

		for( local i = 0; i < n; i+=Y )
		{
			local p = k[i];
			L(p, p + A(a[i]) * 16, 255, 128, 255, true, time);
			L(p, k[i+Y], 138, 255, 0, true, time);
		}
	};
});

// kf_replace
function _kf82b3821bBA()
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot modify keyframes while compiling!");

	if( !("__lp_c" in this) || !("__la_c" in this) || !__lp_c.len() )
		return MsgFail("No keyframes found.");

	if( !_kfb283B2lbBa.GetTeam() )
		return MsgFail("You need to be in edit mode to insert keyframes.");

	if( _kf82bE821bBA )
		return MsgFail("Cannot replace while seeing!");

	// undolast_replace
	_kf82bEB2lbBA = [_kfb283821BB4,
	                 __lp_c[_kfb283821BB4],
	                 __la_c[_kfb283821BB4],
	                 __la_q[_kfb283821BB4]];

	local pos = HPlayer.EyePosition(),
	      dir = HPlayerEye.GetForwardVector();

	__lp_c[_kfb283821BB4] = pos;
	__la_c[_kfb283821BB4] = dir;
	__la_q[_kfb283821BB4] = VS.AngleQuaternion(HPlayerEye.GetAngles(), Quaternion());

	DebugDrawLine(pos, pos + dir * 64, 138, 255, 0, true, 7);
	DebugDrawBox(pos, Vector(-4,-4,-4), Vector(4,4,4), 138, 255, 0, 127, 7);

	MsgHint("Replaced keyframe #" + _kfb283821BB4);
	PlaySound("UIPanorama.container_countdown");
}

// kf_insert
function _kf82b3821bB4()
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot modify keyframes while compiling!");

	if( !("__lp_c" in this) || !("__la_c" in this) || !__lp_c.len() )
		return MsgFail("No keyframes found.");

	if( !_kfb283B2lbBa.GetTeam() )
		return MsgFail("You need to be in edit mode to insert keyframes.");

	if( _kf82bE821bBA )
		return MsgFail("Cannot insert while seeing!");

	local pos = HPlayer.EyePosition(),
	      dir = HPlayerEye.GetForwardVector();

	local i = _kfb283821BB4+1;

	__lp_c.insert(i, pos);
	__la_c.insert(i, dir);
	__la_q.insert(i, VS.AngleQuaternion(HPlayerEye.GetAngles(), Quaternion()));

	DebugDrawLine(pos, pos + dir * 64, 138, 255, 0, true, 7);
	DebugDrawBox(pos, Vector(-4,-4,-4), Vector(4,4,4), 138, 255, 0, 127, 7);

	MsgHint("Inserted keyframe #" + i);
	PlaySound("UIPanorama.container_countdown");
}

// kf_remove
function _kf82b38Z1bbA()
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot modify keyframes while compiling!");

	if( !("__lp_c" in this) || !("__la_c" in this) || !__lp_c.len() )
		return MsgFail("No keyframes found.");

	if( !_kfb283B2lbBa.GetTeam() )
		return MsgFail("You need to be in edit mode to remove keyframes.");

	// unsee
	if( _kf82bE821bBA )
		_kf82bE82lbBA(1);

	// undolast_remove
	_kf8ZbEB2lbBA = [_kfb283821BB4,
	                 __lp_c.remove(_kfb283821BB4),
	                 __la_c.remove(_kfb283821BB4),
	                 __la_q.remove(_kfb283821BB4)];

	foreach( i,v in __la_f ) if( v[0] == _kfb283821BB4 )
	{
		_kf8ZbEB2lbBA.append(__la_f.remove(i));
		// compile fov
		_kfB2B3821bB4();
	};

	if( !__lp_c.len() )
	{
		MsgHint("Removed all keyframes.");

		// current
		_kfb283821BB4 = 0;

		// unselect
		_kfb283821bBa = -1;
	}
	else
	{
		MsgHint("Removed keyframe #" + _kfb283821BB4);

		if( !(_kfb283821BB4 in __lp_c) )
		{
			_kfb283821BB4 = 0;
			_kfb283821bBa = -1;
		};
	};

	PlaySound("UIPanorama.container_countdown");
}

// undolast
function _kf8Zb3B2lbBA(t)
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot modify keyframes while compiling!");

	// remove undo
	if(t)
	{
		if( !("_kf8ZbEB2lbBA" in this) || !_kf8ZbEB2lbBA.len() )
			return MsgFail("No removed key found.");

		local i = _kf8ZbEB2lbBA[0];

		__lp_c.insert(i,_kf8ZbEB2lbBA[1]);
		__la_c.insert(i,_kf8ZbEB2lbBA[2]);
		__la_q.insert(i,_kf8ZbEB2lbBA[3]);

		if( _kf8ZbEB2lbBA.len() > 4 )
			__la_f.append(_kf8ZbEB2lbBA[4]);

		if( _kf8ZbEB2lbBA.len() > 5 )
			Error("[ERROR] Assertion failed. Duplicated FOV data.");

		_kf8ZbEB2lbBA.clear();

		MsgHint("Undone remove #" + i);
	}
	// replace undo
	else
	{
		if( !("_kf82bEB2lbBA" in this) || !_kf82bEB2lbBA.len() )
			return MsgFail("No replaced key found.");

		local i = _kf82bEB2lbBA[0];

		__lp_c[i] = _kf82bEB2lbBA[1];
		__la_c[i] = _kf82bEB2lbBA[2];
		__la_q[i] = _kf82bEB2lbBA[3];

		_kf82bEB2lbBA.clear();

		MsgHint("Undone replace #" + i);
	};

	PlaySound("UIPanorama.container_countdown");
}

// kf_removefov
function _kf82b3BZ1bbA()
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot modify keyframes while compiling!");

	if( !("__lp_c" in this) || !("__la_c" in this) || !__lp_c.len() )
		return MsgFail("No keyframes found.");

	if( !_kfb283B2lbBa.GetTeam() )
		return MsgFail("You need to be in edit mode to remove FOV data.");

	// refresh
	if( _kf82bE821bBA )
		_kfB2B382lbB4.SetFov(0,0.1);

	foreach( i,v in __la_f ) if( v[0] == _kfb283821BB4 )
		__la_f.remove(i);

	// compile fov
	_kfB2B3821bB4();

	MsgHint("Removed FOV data at key #" + _kfb283821BB4);
	PlaySound("UIPanorama.container_countdown");
}

// set fov val and time
function fov(x)
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot modify keyframes while compiling!");

	if( !("__lp_c" in this) || !("__la_c" in this) || !__lp_c.len() )
		return MsgFail("No keyframes found.");

	if( !_kfb283B2lbBa.GetTeam() )
		return MsgFail("You need to be in edit mode to add new FOV data.");

	x = x.tofloat();

	// refresh
	if( _kf82bE821bBA )
		_kfB2B382lbB4.SetFov(x,0.25);

	local q = [_kfb283821BB4,x,0];

	foreach( i,v in __la_f ) if( v[0] == _kfb283821BB4 )
	{
		__la_f[i] = q;
		// compile fov
		_kfB2B3821bB4();

		MsgHint("Set key #" + _kfb283821BB4 + " FOV to " + x);
		// MsgHint("Replaced previous FOV key.");
		return;
	};

	__la_f.append(q);
	// compile fov
	_kfB2B3821bB4();

	MsgHint("Set key #" + _kfb283821BB4 + " FOV to " + x);
	PlaySound("UIPanorama.container_countdown");
}

// kf_add
function _kf82b3BZ1bBA()
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot modify keyframes while compiling!");

	if( _kf82bE821bBA )
		return MsgFail("Cannot add new keyframe while seeing!");

	if( !("__lp_c" in this) || !("__la_c" in this) || !("__la_q" in this) || !("__la_f" in this) )
	{
		__lp_c <- [];
		__la_c <- [];
		__la_q <- [];
		__la_f <- [];
	};

	local pos = HPlayer.EyePosition(),
	      dir = HPlayerEye.GetForwardVector();

	__lp_c.append(pos);
	__la_c.append(dir);
	__la_q.append(VS.AngleQuaternion(HPlayerEye.GetAngles(), Quaternion()));

	DebugDrawLine(pos, pos + dir * 64, 138, 255, 0, true, 7);
	DebugDrawBox(pos, Vector(-4,-4,-4), Vector(4,4,4), 138, 255, 0, 127, 7);

	MsgHint("Added keyframe #" + (__lp_c.len()-1));
	PlaySound("UIPanorama.container_countdown");
}

// kf_clear
function _kf82b3BZ1Bb4()
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot modify keyframes while compiling!");

	if( !("__lp_c" in this) || !("__la_c" in this) || !__lp_c.len() )
		return MsgFail("No keyframes found.");

	// unsee
	if( _kf82bE821bBA )
		_kf82bE82lbBA(1);

	// unselect
	_kfb283821bBa = -1;

	// current
	_kfb283821BB4 = 0;

	MsgHint("Cleared "+__lp_c.len()+" keyframes.");

	__lp_c.clear();
	__la_c.clear();
	__la_q.clear();
	__la_f.clear();

	// undolast
	_kf82bEB2lbBA.clear();
	_kf8ZbEB2lbBA.clear();

	PlaySound("UIPanorama.container_countdown");
}

// interp resolution
function res(f)
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot change resolution while compiling!");

	if( f < 0.001 || f > 0.5 )
		return MsgFail("Invalid resolution range. [0.001, 0.5]");

	_kfb283821bB4 = f.tofloat();
	_db36Slt4ATef = floor(1.0/_kfb283821bB4);
	Msg("Interpolation resolution set to: " + _kfb283821bB4);
	Msg("Time between 2 keyframes: " + (FTIME/_kfb283821bB4) + " second(s)");
	PlaySound("UIPanorama.container_countdown");
}

// kf_mode_angle
function _kfb2838Z1Bba()
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot change algorithm while compiling!");

	_kfb283821B6a = !_kfb283821B6a;

	Msg("\nNow using the "+(_kfb283821B6a?"default":"stabilised")+" algorithm.");
	PlaySound("UIPanorama.container_countdown");
}

// kf_compile
function _kfb28382lB64()
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Compilation in progress...");

	if( _kfb283BZ1b8a.GetTeam() || _kfb283821b6a )
		return MsgFail("Cannot compile while in playback!");

	if( !("__lp_c" in this) || !("__la_c" in this) || !__lp_c.len() )
		return MsgFail("No keyframes found.");

	if( __lp_c.len() < 4 )
		return MsgFail("Not enough keyframes to compile. (Required minimum amount: 4)");

	if( __lp_c.len() != __la_c.len() || __la_c.len() != __la_q.len() )
		return Error("[ERROR]\nAssertion failed: Corrupted keyframe data! [p" + __lp_c.len() + ",a" + __la_c.len() + ",q" + __la_q.len() + "]");

	// compiling
	_kfB2B382lbB4.SetTeam(1);

	// stop seeing
	_kf82bE82lbBA(1);

	// temporarily disable edit mode
	EntFireByHandle(_kfb283B2lbBa, "disable");
	SendToConsole("clear_debug_overlays");
	DrawOverlay(2);

	Msg("\nPreparing..." + "\nResolution          : " + _kfb283821bB4 + "\nTime between 2 keys : "+(FTIME/_kfb283821bB4)+"s\nAlgorithm           : "+(_kfb283821B6a?"default":"stabilised")+"\n");
	PlaySound("UIPanorama.container_countdown");

	return delay( "__kfb28382lB64.call(ROOT)", _kfb283B21b8a+FrameTime() );
}

// compile
// TODO: Implement consistent speed
function __kfb28382lB64()
{
	// an alternative to inserting would be calculating the future length of
	// the compiled data, and creating that sized empty arrays, and accessing those indices
	// but I'm fine with inserting
	__lp_k <- array(__lp_c.len());
	__la_k <- array(__la_c.len());

	RTIME <- FTIME; // FrameTime()*1.5;
	_db36SltAaTef <- 10;
	if( _kfb283821bB4 <= 0.025 )
	{
		_db36SltAaTef <- 2;
		RTIME *= 2;
	};
	_db36Slt4aTef <- 0;
	_db36Slt4ATef = floor(1.0/_kfb283821bB4);
	_db36SltA4T3f <- 0;
	_db36SltA473f <- clamp(_db36SltAaTef, 0, _db36Slt4ATef);

	_kfb2B3821bB4 = _db36Slt4ATef.tointeger() / 10;

	print("Compiling (1/3) ");
	return delay( "_kfb28EB21bB4.call(ROOT)", RTIME );
}

// spline origin
function _kfb28EB21bB4()
{
	// complete
	if( _db36SltA4T3f >= _db36SltA473f )
	{
		print("\n");
		__lp_k.pop();
		__lp_k.pop();
		__lp_k.remove(0);

		// next process
		_db36SltA4T3f = 0;
		_db36SltA473f = clamp(_db36SltAaTef, 0, _db36Slt4ATef);

		print("Compiling (2/3) ");
		return _kfb28EB2lbBA();
	};

	if(!(_db36SltA4T3f % 25)) print(".");

	// if(!(_db36SltA4T3f % 10))
	_kfbZ83B21b8a %= 63;
	Hint(_kf82b3821bbA[++_kfbZ83B21b8a]);

	local s = VS.Catmull_Rom_Spline.bindenv(VS),
	      c = __lp_c,
	      l = c.len()-3,
	      k = __lp_k,
	      v = Vector;

	for( local j = _db36SltA4T3f, f = _kfb283821bB4 * _db36SltA4T3f; j < _db36SltA473f; j++, f += _kfb283821bB4 )
		for( local i = 0; i < l; i++ )
			k.insert((j+2)+(i*(j+2)),s(c[i],c[i+1],c[i+2],c[i+3],f,v()));

	_db36SltA4T3f += _db36SltAaTef;
	_db36SltA473f = clamp(_db36SltA473f + _db36SltAaTef, 0, _db36Slt4ATef);

	return delay( "_kfb28EB21bB4.call(ROOT)", RTIME );
}

// spline angles
function _kfb28EB2lbBA()
{
	// complete
	if( _db36SltA4T3f >= _db36SltA473f )
	{
		print("\n");
		__la_k.pop();
		__la_k.pop();
		__la_k.remove(0);

		// next process
		_db36SltA4T3f = 0;
		_db36SltA473f = clamp(_db36SltAaTef, 0, _db36Slt4ATef);

		print("Compiling (3/3) ");
		return _kfb28EbZlbBA();
	};

	if(!(_db36SltA4T3f % 25)) print(".");

	// if(!(_db36SltA4T3f % 10))
	_kfbZ83B21b8a %= 63;
	Hint(_kf82b3821bbA[++_kfbZ83B21b8a]);

	if( _kfb283821B6a )
	{
		local a = VS.QAngleNormalize.bindenv(VS),
		      b = VS.QuaternionAngles2.bindenv(VS),
		      c = VS.Catmull_Rom_SplineQ.bindenv(VS),
		      q = __la_q,
		      l = q.len()-3,
		      k = __la_k,
		      v = Vector,
		      t = Quaternion;

		for( local j = _db36SltA4T3f, f = _kfb283821bB4 * _db36SltA4T3f; j < _db36SltA473f; j++, f += _kfb283821bB4 )
			for( local i = 0; i < l; i++ )
				k.insert((j+2)+(i*(j+2)),a(b(c(q[i],q[i+1],q[i+2],q[i+3],f,t()),v())));
	}
	else
	{
		local a = VS.QAngleNormalize.bindenv(VS),
		      b = VS.VectorAngles,
		      c = VS.Catmull_Rom_Spline.bindenv(VS),
		      e = __la_c,
		      l = e.len()-3,
		      k = __la_k,
		      v = Vector;

		for( local j = _db36SltA4T3f, f = _kfb283821bB4 * _db36SltA4T3f; j < _db36SltA473f; j++, f += _kfb283821bB4 )
			for( local i = 0; i < l; i++ )
				k.insert((j+2)+(i*(j+2)),a(b(c(e[i],e[i+1],e[i+2],e[i+3],f,v()))));
	};

	_db36SltA4T3f += _db36SltAaTef;
	_db36SltA473f = clamp(_db36SltA473f + _db36SltAaTef, 0, _db36Slt4ATef);

	return delay( "_kfb28EB2lbBA.call(ROOT)", RTIME );
}

// compile clear
function _kfb28EbZlbBA()
{
	if(!(_db36Slt4aTef % 175)) print(".");

	if(!(_db36Slt4aTef % 50))
	{
		_kfbZ83B21b8a %= 63;
		Hint(_kf82b3821bbA[++_kfbZ83B21b8a]);
	};

	for( local i = _db36Slt4aTef; i < __lp_k.len(); i++ )
		if( __lp_k[i] == null )
		{
			__lp_k.remove(i);
			__la_k.remove(i);

			_db36Slt4aTef = i;
			return delay( "_kfb28EbZlbBA.call(ROOT)", RTIME );
		};

	                    // compile fov           // finish compile
	delay( "print(\".\");_kfB2B3821bB4.call(ROOT);delay(\"_kfB2B3821b84.call(ROOT)\",RTIME)", RTIME );
}

// compile finish
function _kfB2B3821b84()
{
	// complete
	_kfB2B382lbB4.SetTeam(0);
	EntFireByHandle(_kfb283B2lbBa, _kfb283B2lbBa.GetTeam()?"enable":"disable");
	DrawOverlay(_kfb283B2lbBa.GetTeam()?1:0);
	Msg("\n\nCompiled keyframes: "+__lp_k.len() * FTIME+" seconds\n\n* Play the compiled data           kf_play\n* Toggle edit mode                 kf_edit\n* Save the compiled data           kf_save\n* Save the keyframes               kf_savekeys\n\n* List all commands                kf_cmd\n");
	Hint("Compilation complete!");
	PlaySound("UIPanorama.container_countdown");
}

// compile fov
function _kfB2B3821bB4()
{
	local _f = __la_f;

	if( !_f.len() )
	{
		__la_v <- [];
		return;
	};

	local s = function(x,y){
		if( x[0] > y[0] ) return  1;
		if( x[0] < y[0] ) return -1;
		return 0;
	}

	_f.sort(s);

	// FOV data at key 0 is invalid
	if( _f[0][0] == 0 ) _f.remove(0);

	if( !_f.len() ) return;

	// if key 1 doesn't have an FOV value, set to 90
	if( _f[0][0] != 1 ) _f.insert(0,[1,90,0]);

	__la_v <- array(_f.len()-1);

	local i  = -1,
	      t  = FTIME/_kfb283821bB4,
	      _v = __la_v,
	      l  = _f.len()-1;

	while( l>++i )
	{
		local v = _f[i],
		      c = _f[i+1];

		local d = (c[0]-v[0]) * t;

		_v[i] = [ (v[0]-1)*_db36Slt4ATef, c[1], d ];
	}

	// key 1
	if( _f[0][0] == 1 )
		_v.insert(0,[-_db36Slt4ATef,_f[0][1],0]);

	// to be safe
	// this shouldn't be necessary
	_v.sort(s);
}

// (0)kf_save, (1)kf_savekeys
function _kf82b3B2lBb4( i = 0 )
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot save while compiling!");

	if( !i )
	{
		if( !("__lp_k" in this) || !__lp_k.len() )
			return MsgFail("No compiled keyframes found.");
	}
	else
	{
		if( !("__lp_c" in this) || !__lp_c.len() )
			return MsgFail("No keyframes found.");
	};

	DrawOverlay(2);

	_kf82b3b2lBb4 <- VS.Log.L;

	VS.Log.Clear();
	VS.Log.filePrefix = "kf_data";
	VS.Log.condition = true;
	VS.Log.export = true;
	VS.Log.filter = "L ";

	                                          // strip the name from "workshop/##id##/" prefix
	_kf82b3b2lBb4.append("l_" + (i?"keys_":"") +        split(GetMapName(),"/").top()         + " <-{pos=[");

	__lp_s <- i ? __lp_c : __lp_k;
	__la_s <- i ? __la_c : __la_k;

	_dBebSlTa4T3F <- __lp_s.len();
	_dBebSlTa4t3F <- 1450;
	_dBebSlTa4tef <- 0;
	_dBebSlTa4teF <- clamp(_dBebSlTa4t3F, 0, _dBebSlTa4T3F);

	return _kf82b3B2lBb2(i);
}

// save run
function _kf82b3B2lBb8(i)
{
	local file = VS.Log.Run();
	Msg("\n* "+(i?"Keyframe":"Path")+" data is exported: /csgo/"+file+".log\n");

	PrecacheScriptSound("Survival.TabletUpgradeSuccess");
	PlaySound("Survival.TabletUpgradeSuccess");

	DrawOverlay(_kfb283B2lbBa.GetTeam()?1:0);
}

// save pos
function _kf82b3B2lBb2(i)
{
	if( _dBebSlTa4tef >= _dBebSlTa4teF )
	{
		_kf82b3b2lBb4.append("]ang=[");
		_dBebSlTa4tef = 0;
		_dBebSlTa4teF = clamp(_dBebSlTa4t3F, 0, _dBebSlTa4T3F );
		return _kf82b3B2lBb3(i);
	};

	for( local i = _dBebSlTa4tef; i < _dBebSlTa4teF; i++ )
		_kf82b3b2lBb4.append(VecToString(__lp_s[i],"V("));

	_dBebSlTa4tef += _dBebSlTa4t3F;
	_dBebSlTa4teF = clamp(_dBebSlTa4teF + _dBebSlTa4t3F, 0, _dBebSlTa4T3F);

	return delay( "_kf82b3B2lBb2.call(ROOT,"+i+")", FTIME );
}

// save ang, quat, fov
function _kf82b3B2lBb3(i)
{
	if( _dBebSlTa4tef >= _dBebSlTa4teF )
	{
		_kf82b3b2lBb4.pop();
		_kf82b3b2lBb4.append(VecToString(__la_s[__la_s.len()-1],"V(") + "]");

		local kf;

		// saving keys?
		if(i)
		{
			local l = __la_q.len();

			_kf82b3b2lBb4.append("anq=[");

			for( local i = 0; i < l; i++ )
			{
				local q = __la_q[i];
				_kf82b3b2lBb4.append("Q(" + q.x + ","+ q.y + "," + q.z + "," + q.w + ")");
			}

			_kf82b3b2lBb4.append("]");

			kf = __la_f;
		}
		else kf = __la_v;

		// save fov
		if(kf.len())
		{
			_kf82b3b2lBb4.append("fov=[");

			foreach( a in kf )
			{
				_kf82b3b2lBb4.append("[");

				foreach( v in a )
				{
					_kf82b3b2lBb4.append(v);
					_kf82b3b2lBb4.append(",");
				}

				_kf82b3b2lBb4.pop();
				_kf82b3b2lBb4.append("]");
				_kf82b3b2lBb4.append(",");
			}

			_kf82b3b2lBb4.pop();
			_kf82b3b2lBb4.append("]");
		};

		_kf82b3b2lBb4.append("}\n");

		return _kf82b3B2lBb8(i);
	};

	for( local i = _dBebSlTa4tef; i < _dBebSlTa4teF; i++ )
		_kf82b3b2lBb4.append(VecToString(__la_s[i],"V("));

	_dBebSlTa4tef += _dBebSlTa4t3F;
	_dBebSlTa4teF = clamp(_dBebSlTa4teF + _dBebSlTa4t3F, 0, _dBebSlTa4T3F);

	return delay( "_kf82b3B2lBb3.call(ROOT,"+i+")", FTIME );
}

// Think set
VS.OnTimer(_kfb283BZ1b8a, function()
{
	::_kfB2B382lbB4.SetAbsOrigin(__lp_p[_kfB283B2lbB4]);
	::VS.SetAngles(::_kfB2B382lbB4, __la_p[_kfB283B2lbB4]);

	foreach( x in ::__la_v ) if( x[0] == _kfB283B2lbB4 )
	{
		::_kfB2B382lbB4.SetFov(x[1],x[2]);
		break;
	};

	if( ++_kfB283B2lbB4 >= _kfB283B2lb84 )
		::_kfB283B2lBbA();
}, null, true);

// kf_play
function _kfB283B2lbBA()
{
	if( _kfB2B382lbB4.GetTeam() )
		return MsgFail("Cannot start playback while compiling!");

	if( _kfb283821b6a )
		return MsgFail("Playback has not started yet!");

	if( _kfb283BZ1b8a.GetTeam() )
		return MsgFail("Playback is already running.");

	// unsee
	if( _kf82bE821bBA )
		_kf82bE82lbBA(1);

	// if( !i )
	// {
		if( !("__lp_k" in this) || !("__la_k" in this) || !__lp_k.len() )
			return MsgFail("No compiled data found.");

		if( __lp_k.len() != __la_k.len() )
			return Error("Corrupted data! [" + __lp_k.len() + "," + __la_k.len() + "]");
	// }
	// else
	// {
		// if( !__lp_l.len() )
			// return MsgFail("No loaded data found.");

		// if( __lp_l.len() != __la_l.len() )
			// return Error("Corrupted data! [" + __lp_l.len() + "," + __la_l.len() + "]");
	// };

	if( developer() > 1 )
	{
		Msg("Setting developer level to 1");
		SendToConsole("developer 1");
	};

	// avoid unnecessary slots in the root
	// by putting exclusive timer variables in the timer's scope
	local s = _kfb283BZ1b8a.GetScriptScope();

	// play lists
	s.__lp_p <- __lp_k;
	s.__la_p <- __la_k;

	// len playback
	s._kfB283B2lb84 <- s.__lp_p.len();

	// set idx curr
	s._kfB283B2lbB4 <- 0;

	// initiate cam
	if( __la_v.len() )
		if( __la_v[0][0] == -100 )
			_kfB2B382lbB4.SetFov(__la_v[0][1],0);;

	_kfB2B382lbB4.SetAbsOrigin(s.__lp_p[0]);
	VS.SetAngles(_kfB2B382lbB4,s.__la_p[0]);
	EntFireByHandle(_kfB2B382lbB4, "enable", "", 0, HPlayer);
	EntFireByHandle(_kfb283BZ1b8a, "disable");

	delay( "MsgHint(\"Starting in 3...\");PlaySound(\"UI.CounterBeep\")", 0.0 );
	delay( "MsgHint(\"Starting in 2...\");PlaySound(\"UI.CounterBeep\")", 1.0 );
	delay( "MsgHint(\"Starting in 1...\");PlaySound(\"UI.CounterBeep\")", 2.0 );

	HPlayer.SetHealth(1337);
	VS.HideHudHint(_kfB2B38ZlbB4, HPlayer, 3.0-FrameTime());

	_kfb283821b6a = true;
	delay( "_kfb283821b6a=false;_kfb283BZ1b8a.SetTeam(1);Msg(\"Playback has started...\\n\");EntFireByHandle(_kfb283BZ1b8a,\"enable\")", 3.0 );
}

// kf_stop
function _kfB283B2lBbA()
{
	if( !_kfb283BZ1b8a.GetTeam() )
		return MsgFail("Playback is not running.");

	_kfb283BZ1b8a.SetTeam(0);

	EntFireByHandle(_kfB2B382lbB4, "disable", "", 0, HPlayer);
	EntFireByHandle(_kfb283BZ1b8a, "disable");

	_kfB2B382lbB4.SetFov(0,0);

	// if( bHoldLastFrame )
	// {
	// }

	Msg("Playback has ended.");
	PlaySound("UI.RankDown");
}
