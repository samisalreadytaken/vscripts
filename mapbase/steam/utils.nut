
local Fmt = format;
::prettifynum <- function( val )
{
	local out = "";
	local div = 1;

	if ( val < 0 )
	{
		out += "-";
		val = -val;
	}

	for ( local i = 6; i--; )
	{
		if ( val < div * 1000 )
			break;
		div *= 1000;
	}

	local prt = val / div;
	out += prt;

	for (;;)
	{
		val -= prt * div;
		div /= 1000;
		if ( !div )
			break;
		prt = val / div;
		out += Fmt( ",%03d", prt );
	}

	return out;
}

::_hashstr <- function( s )
{
	local l = s.len(), h = l, t = (l >> 5) | 1, i = 0;
	for ( ; l >= t; l -= t )
		h = h ^ ( (h<<5)+(h>>2)+s[i++] );
	return h;
}

if ( CLIENT_DLL )
{
	SteamScheme <-
	{
		"Highlight5"				: [ 24 53 82 255 ]

		"ClientBG"					: [ 18 26 42 255 ]
		"DialogBG"					: [ 42 46 51 255 ]

		"Label"						: [ 168 172 179 255 ]
		"Label2"					: [ 107 112 123 255 ]

		"Friends.InGameColor"		: [ 144 186 60 255 ]
		"Friends.OnlineColor"		: [ 84 165 196 255 ]
		"Friends.OfflineColor"		: [ 127 127 127 255 ]

		"AchievementPopup.TitleColor"		: [ 200 208 220 255 ]
		"AchievementPopup.DescriptionColor"	: [ 180 180 180 255 ]
	}
}
