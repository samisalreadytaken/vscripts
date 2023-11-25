
surface.AddCustomFontFile( "resources/stratum2bold.ttf" );

local stratum = IsLinux() ? "Stratum2" : "Stratum2 Bold";

surface.CreateFont( "hud-HA-text",
{
	"name"			: stratum
	"tall"			: 20
	"weight"		: 500
	"antialias" 	: true
	"proportional" 	: true
} );

surface.CreateFont( "hud-HA-text-blur",
{
	"name"			: stratum
	"blur"			: 3
	"tall"			: 20
	"weight"		: 500
	"antialias" 	: true
	"proportional" 	: true
} );

surface.CreateFont( "hud-HA-text-medium",
{
	"name"			: stratum
	"tall"			: 16
	"weight"		: 500
	"antialias" 	: true
	"proportional" 	: true
} );

surface.CreateFont( "hud-HA-text-medium-blur",
{
	"name"			: stratum
	"blur"			: 2
	"tall"			: 16
	"weight"		: 500
	"antialias" 	: true
	"proportional" 	: true
} );

surface.CreateFont( "hud-HA-text-sm",
{
	"name"			: stratum
	"tall"			: 10
	"weight"		: 500
	"antialias" 	: true
	"proportional" 	: true
} );

surface.CreateFont( "hud-HA-text-sm-blur",
{
	"name"			: stratum
	"blur"			: 2
	"tall"			: 10
	"weight"		: 500
	"antialias" 	: true
	"proportional" 	: true
} );

surface.CreateFont( "hud-HA-icon",
{
	"name"			: "HalfLife2"
	"tall"			: 18
	"weight"		: 0
	"antialias" 	: true
	"proportional" 	: true
} );

surface.CreateFont( "hud-HA-icon-blur",
{
	"name"			: "HalfLife2"
	"blur"			: 2
	"tall"			: 18
	"weight"		: 0
	"dropshadow" 	: true
	"proportional" 	: true
} );

surface.CreateFont( "weapon-selection-item-name-text",
{
	"name"			: stratum
	"tall"			: 6
	"weight"		: 500
	"additive"		: false
	"antialias" 	: true
	"dropshadow" 	: false
	"proportional" 	: true
} );

surface.CreateFont( "weapon-selection-item-icon",
{
	"name"			: "HalfLife2"
	"tall"			: 36
	"weight"		: 0
	"antialias" 	: true
	"additive"		: false
	"custom"		: true
	"dropshadow" 	: true
	"proportional"	: true
} );

surface.CreateFont( "weapon-selection-item-icon-blur",
{
	"name"			: "HalfLife2"
	"blur"			: 2
	"tall"			: 36
	"weight"		: 0
	"antialias" 	: true
	"additive"		: false
	"custom"		: true
	"dropshadow"	: true
	"proportional"	: true
} );

surface.CreateFont( "hud-hint__text",
{
	"name"			: stratum // monospace doesn't work
	"tall"			: 9
	"weight"		: 500
	"antialias" 	: true
	"proportional" 	: true
} );
