//-----------------------------------------------------------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
//
// panel system demo
//
// unfinished
//


IncludeScript("vs_library");
IncludeScript("panel");

const TEAM_TERRORIST = 2;;
const TEAM_CT = 3;;

enum WEAPON
{
	GLOCK		= "weapon_glock",
	HKP2000		= "weapon_hkp2000",
	USP_SILENCER		= "weapon_usp_silencer",
	ELITE		= "weapon_elite",
	P250		= "weapon_p250",
	TEC9		= "weapon_tec9",
	FN57		= "weapon_fiveseven",
	DEAGLE		= "weapon_deagle",
	GALILAR		= "weapon_galilar",
	FAMAS		= "weapon_famas",
	AK47		= "weapon_ak47",
	M4A1		= "weapon_m4a1",
	M4A1_SILENCER		= "weapon_m4a1_silencer",
	SSG08		= "weapon_ssg08",
	AUG			= "weapon_aug",
	SG556		= "weapon_sg556",
	AWP			= "weapon_awp",
	SCAR20		= "weapon_scar20",
	G3SG1		= "weapon_g3sg1",
	NOVA		= "weapon_nova",
	XM1014		= "weapon_xm1014",
	MAG7		= "weapon_mag7",
	M249		= "weapon_m249",
	NEGEV		= "weapon_negev",
	MAC10		= "weapon_mac10",
	MP9			= "weapon_mp9",
	MP7			= "weapon_mp7",
	UMP45		= "weapon_ump45",
	P90			= "weapon_p90",
	BIZON		= "weapon_bizon",
	MP5SD		= "weapon_mp5sd",
	SAWEDOFF	= "weapon_sawedoff",
	CZ75A		= "weapon_cz75a"
}


//
//
//	BuyMenu : CBaseScreen
//		m_base
//			m_cursor
//			background
//			teamLabel
//			slot1_wedge
//				label
//				slot1_rifle
//				slot1_smg
//			slot2_wedge
//				label
//				slot2_rifle
//				slot2_smg
//			slot3_wedge
//				label
//				slot3_rifle
//				slot3_smg
//		m_children	// calc collision against these
//			teamLabel
//			slot1_wedge
//			slot2_wedge
//			slot3_wedge
//
//



const SND_BUYMENU_MOUSEOVER = "UIPanorama.buymenu_mouseover";;
const SND_BUYMENU_SELECT = "UIPanorama.container_countdown";;
const SND_BUYMENU_PURCHASE = "UIPanorama.buymenu_purchase";;



class Wedge extends CBasePanel
{
	// BaseClass = CBasePanel;

	m_base = null;
	m_hTextureToggle = null;
	m_nSlot = -1;
}

local BaseClass = CBasePanel;

function Wedge::constructor( baseManager, debugName = null ) : (BaseClass)
{
	BaseClass.constructor( baseManager.m_base, debugName );

	m_base = baseManager;

	if ( !m_hTextureToggle )
	{
		m_hTextureToggle = Entities.CreateByClassname("env_texturetoggle");
		VS.MakePersistent( m_hTextureToggle );
	};
}

function Wedge::SetSlot( i )
{
	m_nSlot = clamp( i.tointeger(), 1, 6 );
	m_hTextureToggle.__KeyValueFromString( "target", "inventory_wedge" + m_nSlot );
}

function Wedge::OnCursorEntered()
{
	if ( _ent )
		m_base.m_hOwner.EmitSound( SND_BUYMENU_MOUSEOVER );

	return EntFireByHandle( m_hTextureToggle, "SetTextureIndex", "1" );
}

function Wedge::OnCursorExited()
{
	return EntFireByHandle( m_hTextureToggle, "SetTextureIndex", "0" );
}

function Wedge::OnMousePressed()
{
	return m_base.PressedSlot( m_nSlot );
}

function Wedge::OnMouseReleased()
{
}





class ExitButton extends CBasePanel
{
	m_base = null;
	m_hTextureToggle = null;
	m_target = null;

	function OnCursorEntered()
	{
		if ( !m_hTextureToggle )
		{
			m_hTextureToggle = Entities.CreateByClassname("env_texturetoggle");
			VS.MakePersistent( m_hTextureToggle );
			m_hTextureToggle.__KeyValueFromString( "target", m_target );
		};

		return EntFireByHandle( m_hTextureToggle, "SetTextureIndex", "1" );
	}

	function OnCursorExited()
	{
		return EntFireByHandle( m_hTextureToggle, "SetTextureIndex", "0" );
	}

	function OnMousePressed()
	{
		return m_base.Disable();
	}
}

class TeamCoin extends CBasePanel
{
	m_base = null;

	function OnMousePressed()
	{
		return m_base.SwapTeams();
	}
}




enum SubMenu
{
	None = -1,
	Main = 0,
	Pistol = 1,
	Heavy = 2,
	SMG = 3,
	Rifle = 4,
	Equipment = 5,
	Grenade = 6
}


class ::BuyMenu extends CBaseScreen
{
	// BaseClass = CBaseScreen;

	// m_hCamera = null;

	m_nTeam = -1;
	m_hTeamCoin = null;
	m_hCoinTexture = null;
	m_coinTexTarget = null;
	// m_hExit = null;
	m_BackgroundPanel = null;
	m_Wedges = null;
	m_WeaponPanelsPistol = null;
	m_WeaponPanelsSMG = null;
	m_WeaponPanelsRifle = null;
	m_WeaponPanelsHeavy = null;
	m_Labels = null;

	m_nCurSubMenu = SubMenu.None;

	m_bBought = false;

	m_flDisableDist = 0.0;
}

local BaseClass = CBaseScreen;

function BuyMenu::constructor() : ( BaseClass, CBasePanel, ExitButton, TeamCoin )
{
	BaseClass.constructor();

	m_flDisableDist = 128.0;

	SetSize( 56.0, 32.0 );

	// m_hCamera = Entities.CreateByClassname("point_viewcontrol");
	// m_hCamera.__KeyValueFromInt( "solid", 0 );
	// m_hCamera.__KeyValueFromInt( "movetype", 8 );
	// m_hCamera.__KeyValueFromInt( "renderamt", 0 );
	// m_hCamera.__KeyValueFromInt( "rendermode", 2 );
	// m_hCamera.__KeyValueFromInt( "spawnflags", 1|8 );

	m_Wedges = array(7);
	m_WeaponPanelsPistol = [];
	m_WeaponPanelsSMG = [];
	m_WeaponPanelsRifle = [];
	m_WeaponPanelsHeavy = [];

	// m_hExit = ExitButton( m_base, "exit" );
	// m_hExit.m_base = this;
	// m_hExit.SetVisible( false );
	// m_hExit.SetSize( 2.0, 2.0 );
	// m_hExit.SetPos( 32.0, 10.0 );
	// m_hExit.SetWorldEntity( Ent("hud_exit") );
	// AddMember( m_hExit );

	m_hTeamCoin = TeamCoin( m_base, "teamcoin" );
	m_hTeamCoin.m_base = this;
	m_hTeamCoin.SetVisible( false );
	m_hTeamCoin.SetSize( 3.0, 3.0 );
	m_hTeamCoin.SetPos( (m_base.wide - m_hTeamCoin.wide) * 0.5, (m_base.tall - m_hTeamCoin.tall) * 0.5 );
	m_hTeamCoin.SetWorldEntity( Ent("buymenu_coin") );
	AddMember( m_hTeamCoin );

	m_coinTexTarget = "buymenu_coin";

	m_BackgroundPanel = CBasePanel( m_base, "background" );
	m_BackgroundPanel.SetVisible( false );
	m_BackgroundPanel.SetZPos( -1.5 );
	m_BackgroundPanel.SetWorldEntity( Ent("inventory_background") );
	m_BackgroundPanel._ent.__KeyValueFromString( "rendercolor", "255 255 255 127" )

	m_cursor.SetZPos( 0.25 );
	m_cursor.SetVisible( false );
	m_cursor.SetWorldEntity( Ent("cursor") );

	CreateWedges();

	// AddItemWeapon( SubMenu.Rifle, 1, WEAPON.FAMAS );
	AddItemWeapon( SubMenu.Rifle, 1, WEAPON.GALILAR );
	AddItemWeapon( SubMenu.Rifle, 2, WEAPON.AK47 );
	// AddItemWeapon( SubMenu.Rifle, 2, WEAPON.M4A1 );
	AddItemWeapon( SubMenu.Rifle, 3, WEAPON.SSG08 );
	AddItemWeapon( SubMenu.Rifle, 4, WEAPON.SG556 );
	// AddItemWeapon( SubMenu.Rifle, 4, WEAPON.AUG );
	AddItemWeapon( SubMenu.Rifle, 5, WEAPON.AWP );
	AddItemWeapon( SubMenu.Rifle, 6, WEAPON.G3SG1 );
	// AddItemWeapon( SubMenu.Rifle, 6, WEAPON.SCAR20 );

	// AddItemWeapon( SubMenu.SMG, 1, WEAPON.MP9 );
	AddItemWeapon( SubMenu.SMG, 1, WEAPON.MAC10 );
	AddItemWeapon( SubMenu.SMG, 2, WEAPON.MP5SD );
	AddItemWeapon( SubMenu.SMG, 3, WEAPON.UMP45 );
	AddItemWeapon( SubMenu.SMG, 4, WEAPON.P90 );
	AddItemWeapon( SubMenu.SMG, 5, WEAPON.BIZON );

	// AddItemWeapon( SubMenu.Pistol, 1, WEAPON.GLOCK );
	AddItemWeapon( SubMenu.Pistol, 1, WEAPON.USP_SILENCER );
	AddItemWeapon( SubMenu.Pistol, 2, WEAPON.ELITE );
	AddItemWeapon( SubMenu.Pistol, 3, WEAPON.P250 );
	AddItemWeapon( SubMenu.Pistol, 4, WEAPON.TEC9 );
	// AddItemWeapon( SubMenu.Pistol, 4, WEAPON.FN57 );
	AddItemWeapon( SubMenu.Pistol, 5, WEAPON.DEAGLE );

	AddItemWeapon( SubMenu.Heavy, 1, WEAPON.NOVA );
	AddItemWeapon( SubMenu.Heavy, 2, WEAPON.XM1014 );
	// AddItemWeapon( SubMenu.Heavy, 3, WEAPON.MAG7 );
	AddItemWeapon( SubMenu.Heavy, 3, WEAPON.SAWEDOFF );
	AddItemWeapon( SubMenu.Heavy, 4, WEAPON.M249 );
	AddItemWeapon( SubMenu.Heavy, 5, WEAPON.NEGEV );

	local label;
	m_Labels = {};

	label = CBasePanel( m_Wedges[1], "label_pistol" );
	m_Labels[SubMenu.Pistol] <- label;
	label.SetPos( -3.0, -3.5 );
	label.SetVisible( false );
	label.SetWorldEntity( Ent("inventory_label_pistol") );

	label = CBasePanel( m_Wedges[2], "label_heavy" );
	m_Labels[SubMenu.Heavy] <- label;
	label.SetPos( 2.0, -3.5 );
	label.SetZPos( 0.25 );
	label.SetVisible( false );
	label.SetWorldEntity( Ent("inventory_label_heavy") );

	label = CBasePanel( m_Wedges[3], "label_smg" );
	m_Labels[SubMenu.SMG] <- label;
	label.SetPos( 4.5, 0.5 );
	label.SetZPos( 0.25 );
	label.SetVisible( false );
	label.SetWorldEntity( Ent("inventory_label_smg") );

	label = CBasePanel( m_Wedges[4], "label_rifle" );
	m_Labels[SubMenu.Rifle] <- label;
	label.SetPos( 2.0, 4.5 );
	label.SetZPos( 0.25 );
	label.SetVisible( false );
	label.SetWorldEntity( Ent("inventory_label_rifle") );
}

function BuyMenu::CreateWedges()	: (Wedge)
{
	local xpos = m_base.wide * 0.5;
	local ypos = m_base.tall * 0.5;

	for ( local slot = 1; slot <= 6; ++slot )
	{
		local newWedge = Wedge( this, "slot"+slot );
		AddMember( newWedge );

		newWedge.SetSlot( slot );
		newWedge.SetVisible( false );
		newWedge.SetPos( xpos, ypos );
		newWedge.SetZPos( 0.0 );
		newWedge.SetWorldEntity( Ent( "inventory_wedge"+slot ) );

		const INV_WHEEL_PAD = 0.1;
		const INV_WHEEL_SIZE = 8.0;
		const INV_WHEEL_SIZE_SQR = 64.0;
		local ang;
		switch ( slot )
		{
			case 1: ang = -150.0; break;
			case 2: ang = -90.0; break;
			case 3: ang = -30.0; break;
			case 4: ang = 30.0; break;
			case 5: ang = 90.0; break;
			case 6: ang = 150.0; break;
		}

		newWedge._tri0 = Vector( INV_WHEEL_PAD, INV_WHEEL_PAD );
		newWedge._tri1 = Vector( INV_WHEEL_SIZE - INV_WHEEL_PAD, INV_WHEEL_PAD );
		// 1.75 degree padding, roughly equal to 0.1 units (INV_WHEEL_PAD)
		newWedge._tri2 = VS.VectorYawRotate( newWedge._tri1, 58.25 ) * 1;

		newWedge._tri0 = VS.VectorYawRotate( newWedge._tri0, ang ) * 1;
		newWedge._tri1 = VS.VectorYawRotate( newWedge._tri1, ang ) * 1;
		newWedge._tri2 = VS.VectorYawRotate( newWedge._tri2, ang ) * 1;

		m_Wedges[ slot ] = newWedge;
	}
}

function BuyMenu::AddItemWeapon( type, slot, name )
{
	Assert( m_Wedges[ slot ] );

	local panel = CBasePanel( m_Wedges[ slot ], name );
	panel.SetEnabled( true );
	panel.SetVisible( false );
	panel.SetZPos( 1.0 );
	panel.SetWorldEntity( Ent( "inventory_" + name ) );

	switch ( slot )
	{
		case 1: panel.SetPos( -2.5, -3.5 ); break;
		case 2: panel.SetPos( 2.5, -3.5 ); break;
		case 3: panel.SetPos( 4.5, 0.5 ); break;
		case 4: panel.SetPos( 2.5, 4.5 ); break;
		case 5: panel.SetPos( -2.5, 4.5 ); break;
		case 6: panel.SetPos( -4.5, 0.5 ); break;
		default: throw "invalid slot"
	}

	switch ( type )
	{
		case SubMenu.Pistol:
			m_WeaponPanelsPistol.append( panel );
			break;
		case SubMenu.SMG:
			m_WeaponPanelsSMG.append( panel );
			break;
		case SubMenu.Rifle:
			m_WeaponPanelsRifle.append( panel );
			break;
		case SubMenu.Heavy:
			m_WeaponPanelsHeavy.append( panel );
			break;

		default: throw "invalid weapon type"
	}

	return panel;
}

function BuyMenu::CursorThink() : (BaseClass)
{
	if ( !BaseClass.CursorThink() || ( m_hOwner.EyePosition()-m_cursor._absPos ).Length() > m_flDisableDist )
	{
		Disable();
		return false;
	};
	return true;
}

/*
// UNDONE: Radial wedge collision instead of triangles
function BuyMenu::Think()
{
	BaseClass.Think();

	local curx = m_cursor.xpos;
	local cury = m_cursor.ypos;

	local centreX = m_Wedges[1].xpos;
	local centreY = m_Wedges[1].ypos;

	local dx = curx - centreX;
	local dy = cury - centreY;

	local distSqr = dx * dx + dy * dy;

	if ( distSqr < 2.0 || distSqr > INV_WHEEL_SIZE_SQR )
		return;

	local curAng = RAD2DEG * atan2( dx, dy ) + 180.0;
	local hMouseOver;

	if ( curAng < 60.0 )
	{
		hMouseOver = m_Wedges[1];
	}
	else if ( curAng < 120.0 )
	{
		hMouseOver = m_Wedges[6];
	}
	else if ( curAng < 180.0 )
	{
		hMouseOver = m_Wedges[5];
	}
	else if ( curAng < 240.0 )
	{
		hMouseOver = m_Wedges[4];
	}
	else if ( curAng < 300.0 )
	{
		hMouseOver = m_Wedges[3];
	}
	else if ( curAng < 360.0 )
	{
		hMouseOver = m_Wedges[2];
	};;;;;;
}
*/
function BuyMenu::Activate( owner ) : (BaseClass)
{
	owner = ToExtendedPlayer( owner );

	if ( !BaseClass.Activate( owner ) )
		return false;

	SetTeam( owner.GetTeam() );

	VS.SetInputCallback( owner, "+attack2", OnMouse2Pressed.bindenv(this), this.tostring() );

	local viewForward = owner.EyeForward();
	local eyePos = owner.EyePosition();

	// Look at player
	SetPlane(
		eyePos + viewForward * 16.0,
		owner.EyeRight(),
		owner.EyeUp() * -1,
		viewForward * -1 );

	Offset( m_base.wide * -0.5, m_base.tall * -0.5 );

	m_cursor.SetVisible( true );
	m_BackgroundPanel.SetVisible( true );
	// m_hExit.SetVisible( true );
	m_hTeamCoin.SetVisible( true );

	// Pistol, SMG, Rifle
	m_Wedges[1].SetEnabled( true );
	m_Wedges[2].SetEnabled( true );
	m_Wedges[3].SetEnabled( true );
	m_Wedges[4].SetEnabled( true );
	m_Wedges[5].SetEnabled( false );
	m_Wedges[6].SetEnabled( false );

	m_Wedges[1].SetVisible( true );
	m_Wedges[2].SetVisible( true );
	m_Wedges[3].SetVisible( true );
	m_Wedges[4].SetVisible( true );
	m_Wedges[5].SetVisible( true );
	m_Wedges[6].SetVisible( true );

	foreach( v in m_Labels )
		v.SetVisible( true );

	m_nCurSubMenu = SubMenu.Main;

	// m_hCamera.SetOrigin( eyePos );
	// m_hCamera.SetForwardVector( viewForward );

	// EntFireByHandle( m_hCamera, "Enable", "", 0, m_hOwner.self );

	return true;
}

function BuyMenu::Disable() : (BaseClass)
{
	if ( m_hOwner )
		VS.SetInputCallback( m_hOwner, "+attack2", null, this.tostring() );

	m_cursor.SetVisible( false );
	m_BackgroundPanel.SetVisible( false );
	// m_hExit.SetVisible( false );
	m_hTeamCoin.SetVisible( false );

	// Disable wedges and its children (weapons)
	m_Wedges[1].SetVisibleRecurse( false );
	m_Wedges[1].SetEnabled( false );

	m_Wedges[2].SetVisibleRecurse( false );
	m_Wedges[2].SetEnabled( false );

	m_Wedges[3].SetVisibleRecurse( false );
	m_Wedges[3].SetEnabled( false );

	m_Wedges[4].SetVisibleRecurse( false );
	m_Wedges[4].SetEnabled( false );

	m_Wedges[5].SetVisibleRecurse( false );
	m_Wedges[5].SetEnabled( false );

	m_Wedges[6].SetVisibleRecurse( false );
	m_Wedges[6].SetEnabled( false );

	foreach( v in m_Labels )
		v.SetVisible( false );

	// EntFireByHandle( m_hCamera, "Disable" );

	return BaseClass.Disable();
}

function BuyMenu::OnMouse2Pressed( player )
{
	return MenuBack();
}

//
// basic buy menu logic
//
function BuyMenu::PressedSlot( slot )
{
	if ( m_nCurSubMenu == SubMenu.Main )
		m_hOwner.EmitSound( SND_BUYMENU_SELECT );

	switch ( slot )
	{
	case 1:
	{
		switch ( m_nCurSubMenu )
		{
		case SubMenu.Main:
			m_nCurSubMenu = SubMenu.Pistol;

			m_Wedges[1].SetEnabled( true );
			m_Wedges[2].SetEnabled( true );
			m_Wedges[3].SetEnabled( true );
			m_Wedges[4].SetEnabled( true );
			m_Wedges[5].SetEnabled( true );
			m_Wedges[6].SetEnabled( false );

			foreach( p in m_WeaponPanelsPistol )
			{
				if ( p._enabled )
					p.SetVisible( true );
			}
			break;

		case SubMenu.Pistol:
			switch ( m_nTeam )
			{
			case TEAM_TERRORIST:	Buy( WEAPON.GLOCK ); break;
			case TEAM_CT:			Buy( WEAPON.USP_SILENCER ); break;
			}
			break;

		case SubMenu.SMG:
			switch ( m_nTeam )
			{
			case TEAM_TERRORIST:	Buy( WEAPON.MAC10 ); break;
			case TEAM_CT:			Buy( WEAPON.MP9 ); break;
			}
			break;

		case SubMenu.Rifle:
			switch ( m_nTeam )
			{
			case TEAM_TERRORIST:	Buy( WEAPON.GALILAR ); break;
			case TEAM_CT:			Buy( WEAPON.FAMAS ); break;
			}
			break;

		case SubMenu.Heavy:
			Buy( WEAPON.NOVA );
			break;
		}
		break;
	}
	case 2:
	{
		switch ( m_nCurSubMenu )
		{
		case SubMenu.Main:
			m_nCurSubMenu = SubMenu.Heavy;

			m_Wedges[1].SetEnabled( true );
			m_Wedges[2].SetEnabled( true );
			m_Wedges[3].SetEnabled( true );
			m_Wedges[4].SetEnabled( true );
			m_Wedges[5].SetEnabled( true );
			m_Wedges[6].SetEnabled( false );

			foreach( p in m_WeaponPanelsHeavy )
			{
				if ( p._enabled )
					p.SetVisible( true );
			}
			break;

		case SubMenu.Pistol:
			Buy( WEAPON.ELITE );
			break;

		case SubMenu.SMG:
			Buy( WEAPON.MP5SD );
			break;

		case SubMenu.Rifle:
			switch ( m_nTeam )
			{
			case TEAM_TERRORIST:	Buy( WEAPON.AK47 ); break;
			case TEAM_CT:			Buy( WEAPON.M4A1 ); break;
			}
			break;

		case SubMenu.Heavy:
			Buy( WEAPON.XM1014 );
			break;
		}
		break;
	}
	case 3:
	{
		switch ( m_nCurSubMenu )
		{
		case SubMenu.Main:
			m_nCurSubMenu = SubMenu.SMG;

			m_Wedges[1].SetEnabled( true );
			m_Wedges[2].SetEnabled( true );
			m_Wedges[3].SetEnabled( true );
			m_Wedges[4].SetEnabled( true );
			m_Wedges[5].SetEnabled( true );
			m_Wedges[6].SetEnabled( false );

			foreach( p in m_WeaponPanelsSMG )
			{
				if ( p._enabled )
					p.SetVisible( true );
			}
			break;

		case SubMenu.Pistol:
			Buy( WEAPON.P250 );
			break;

		case SubMenu.SMG:
			Buy( WEAPON.UMP45 );
			break;

		case SubMenu.Rifle:
			Buy( WEAPON.SSG08 );
			break;

		case SubMenu.Heavy:
			switch ( m_nTeam )
			{
			case TEAM_TERRORIST:	Buy( WEAPON.SAWEDOFF ); break;
			case TEAM_CT:			Buy( WEAPON.MAG7 ); break;
			}
			break;
		}
		break;
	}
	case 4:
	{
		switch ( m_nCurSubMenu )
		{
		case SubMenu.Main:
			m_nCurSubMenu = SubMenu.Rifle;

			m_Wedges[1].SetEnabled( true );
			m_Wedges[2].SetEnabled( true );
			m_Wedges[3].SetEnabled( true );
			m_Wedges[4].SetEnabled( true );
			m_Wedges[5].SetEnabled( true );
			m_Wedges[6].SetEnabled( true );

			foreach( p in m_WeaponPanelsRifle )
			{
				if ( p._enabled )
					p.SetVisible( true );
			}
			break;

		case SubMenu.Pistol:
			switch ( m_nTeam )
			{
			case TEAM_TERRORIST:	Buy( WEAPON.TEC9 ); break;
			case TEAM_CT:			Buy( WEAPON.FN57 ); break;
			}
			break;

		case SubMenu.SMG:
			Buy( WEAPON.P90 );
			break;

		case SubMenu.Rifle:
			switch ( m_nTeam )
			{
			case TEAM_TERRORIST:	Buy( WEAPON.SG556 ); break;
			case TEAM_CT:			Buy( WEAPON.AUG ); break;
			}
			break;

		case SubMenu.Heavy:
			Buy( WEAPON.M249 );
			break;
		}
		break;
	}
	case 5:
	{
		switch ( m_nCurSubMenu )
		{
		case SubMenu.Pistol:
			Buy( WEAPON.DEAGLE );
			break;

		case SubMenu.SMG:
			Buy( WEAPON.BIZON );
			break;

		case SubMenu.Rifle:
			Buy( WEAPON.AWP );
			break;

		case SubMenu.Heavy:
			Buy( WEAPON.NEGEV );
			break;
		}
		break;
	}
	case 6:
	{
		switch ( m_nCurSubMenu )
		{
		case SubMenu.Rifle:
			switch ( m_nTeam )
			{
			case TEAM_TERRORIST:	Buy( WEAPON.G3SG1 ); break;
			case TEAM_CT:			Buy( WEAPON.SCAR20 ); break;
			}
			break;
		}
		break;
	}
	default: throw "invalid slot"
	}

	if ( m_nCurSubMenu != SubMenu.Main )
	{
		foreach( v in m_Labels )
			v.SetVisible( false );
	};

	if ( m_bBought )
	{
		m_bBought = false;
		MenuBack();
	};
}

function BuyMenu::MenuBack()
{
	switch ( m_nCurSubMenu )
	{
	case SubMenu.Main:
		return Disable();

	case SubMenu.Pistol:
		foreach( p in m_WeaponPanelsPistol )
			p.SetVisible( false );
		break;

	case SubMenu.SMG:
		foreach( p in m_WeaponPanelsSMG )
			p.SetVisible( false );
		break;

	case SubMenu.Rifle:
		foreach( p in m_WeaponPanelsRifle )
			p.SetVisible( false );
		break;

	case SubMenu.Heavy:
		foreach( p in m_WeaponPanelsHeavy )
			p.SetVisible( false );
		break;
	}

	// There's only 1 sub menu depth,
	// just roll back to main buy menu if it was not already there
	m_Wedges[1].SetEnabled( true );
	m_Wedges[2].SetEnabled( true );
	m_Wedges[3].SetEnabled( true );
	m_Wedges[4].SetEnabled( true );
	m_Wedges[5].SetEnabled( false );
	m_Wedges[6].SetEnabled( false );

	foreach( v in m_Labels )
		v.SetVisible( true );

	m_nCurSubMenu = SubMenu.Main;
}

function BuyMenu::Buy( szWeapon )
{
	m_hOwner.EmitSound( SND_BUYMENU_PURCHASE );

	local wep;
	while ( wep = Entities.FindByClassname( wep, "weapon_*" ) )
	{
		if ( wep.GetClassname() == "weapon_knife" )
			continue;

		if ( wep.GetOwner() == m_hOwner.self )
		{
			wep.Destroy();
		};
	}

	SendToConsole("give " + szWeapon);

	local curteam = m_hOwner.GetTeam();

	if ( curteam != m_nTeam )
	{
		m_hOwner.__KeyValueFromInt( "teamnumber", m_nTeam );
		VS.EventQueue.AddEvent( m_hOwner.__KeyValueFromInt, 0.01, [ m_hOwner, "teamnumber", curteam ] );
	};
}

function BuyMenu::SwapTeams()
{
	switch ( m_nTeam )
	{
		case TEAM_TERRORIST:	return SetTeam(TEAM_CT);
		case TEAM_CT:			return SetTeam(TEAM_TERRORIST);
	}
}

function BuyMenu::SetTeam( teamnum )
{
	if ( !m_hCoinTexture )
	{
		m_hCoinTexture = Entities.CreateByClassname("env_texturetoggle");
		VS.MakePersistent( m_hCoinTexture );
		m_hCoinTexture.__KeyValueFromString( "target", m_coinTexTarget );
	};

	m_nTeam = teamnum;

	switch ( teamnum )
	{
		case TEAM_TERRORIST:
		{
			EntFireByHandle( m_hCoinTexture, "SetTextureIndex", "1" );
			break;
		}
		case TEAM_CT:
		{
			EntFireByHandle( m_hCoinTexture, "SetTextureIndex", "0" );
			break;
		}
	}
}







class WedgeMoveable extends Wedge
{
}

function WedgeMoveable::OnMousePressed()
{
	if ( m_base.m_bDebug )
		SetParent( m_base.m_cursor );

	return m_base.PressedSlot( m_nSlot );
}

function WedgeMoveable::OnMouseReleased()
{
	if ( m_base.m_bDebug )
	{
		if ( _parent )
			SetParent( m_base.m_base );
	}
}



// Set different sizes and positions
class BuyMenuWorld extends BuyMenu
{
	m_bDebug = false;
}

local BaseClass = BuyMenu;

//
// Inheriting from 'hud' version is an ugly hack.
// Preferably they would both be based on one, and set their planes and sizes each on their own.
//
function BuyMenuWorld::constructor() : (BaseClass)
{
	BaseClass.constructor();

	m_flDisableDist = 256.0;

	SetSize( 112.0, 64.0 );
	SetPlaneFromEntity( Ent("buymenu") );

	local xpos = m_base.wide * 0.5;
	local ypos = m_base.tall * 0.5;
	foreach( v in m_Wedges )
	{
		if ( v )
		{
			v.SetPos( xpos, ypos );
		}
	}

	m_hTeamCoin.SetSize( 8.0, 8.0 );
	m_hTeamCoin.SetPos( (m_base.wide - m_hTeamCoin.wide) * 0.5, (m_base.tall - m_hTeamCoin.tall) * 0.5 );
	m_hTeamCoin.SetWorldEntity( Ent("buymenu_coin_wall") );
	m_coinTexTarget = "buymenu_coin_wall";

	m_BackgroundPanel.SetWorldEntity( Ent("inventory_background_wall") );
	m_BackgroundPanel._ent.__KeyValueFromString( "rendercolor", "255 255 255 127" )

	local label;
	label = m_Labels[SubMenu.Pistol];
	label.SetPos( -11.5, -13.0 );
	label.SetWorldEntity( Ent("inventory_label_pistol_wall") );

	label = m_Labels[SubMenu.Heavy];
	label.SetPos( 3.5, -13.0 );
	label.SetWorldEntity( Ent("inventory_label_heavy_wall") );

	label = m_Labels[SubMenu.SMG];
	label.SetPos( 11.0, 0.0 );
	label.SetWorldEntity( Ent("inventory_label_smg_wall") );

	label = m_Labels[SubMenu.Rifle];
	label.SetPos( 3.5, 13.0 );
	label.SetWorldEntity( Ent("inventory_label_rifle_wall") );

	// World panel is visible at all times

	m_BackgroundPanel.SetVisible( true );
	m_hTeamCoin.SetVisible( true );

	m_Wedges[1].SetVisible( true );
	m_Wedges[2].SetVisible( true );
	m_Wedges[3].SetVisible( true );
	m_Wedges[4].SetVisible( true );
	m_Wedges[5].SetVisible( true );
	m_Wedges[6].SetVisible( true );

	foreach( v in m_Labels )
		v.SetVisible( true );
}

function BuyMenuWorld::CreateWedges()	: (WedgeMoveable)
{
	local xpos = m_base.wide * 0.5;
	local ypos = m_base.tall * 0.5;

	for ( local slot = 1; slot <= 6; ++slot )
	{
		local newWedge = WedgeMoveable( this, "slot"+slot );
		AddMember( newWedge );

		newWedge.SetSlot( slot );
		newWedge.SetVisible( false );
		newWedge.SetPos( xpos, ypos );
		newWedge.SetZPos( 0.0 );
		newWedge.SetWorldEntity( Ent( "inventory_wedge"+slot + "_wall" ) );

		const INV_WHEEL_PAD = 0.25;
		const INV_WHEEL_SIZE = 24.0;
		const INV_WHEEL_SIZE_SQR = 576.0;
		local ang;
		switch ( slot )
		{
			case 1: ang = -150.0; break;
			case 2: ang = -90.0; break;
			case 3: ang = -30.0; break;
			case 4: ang = 30.0; break;
			case 5: ang = 90.0; break;
			case 6: ang = 150.0; break;
		}

		newWedge._tri0 = Vector( INV_WHEEL_PAD, INV_WHEEL_PAD );
		newWedge._tri1 = Vector( INV_WHEEL_SIZE - INV_WHEEL_PAD, INV_WHEEL_PAD );
		newWedge._tri2 = VS.VectorYawRotate( newWedge._tri1, 59.0 ) * 1;

		newWedge._tri0 = VS.VectorYawRotate( newWedge._tri0, ang ) * 1;
		newWedge._tri1 = VS.VectorYawRotate( newWedge._tri1, ang ) * 1;
		newWedge._tri2 = VS.VectorYawRotate( newWedge._tri2, ang ) * 1;

		m_Wedges[ slot ] = newWedge;
	}
}

function BuyMenuWorld::AddItemWeapon( type, slot, name )
{
	Assert( m_Wedges[ slot ] );

	local panel = CBasePanel( m_Wedges[ slot ], name );
	panel.SetEnabled( true );
	panel.SetVisible( false );
	panel.SetZPos( 1.0 );
	panel.SetWorldEntity( Ent( "inventory_" + name + "_wall" ) );

	switch ( slot )
	{
		case 1: panel.SetPos( -7.0, -11.5 ); break;
		case 2: panel.SetPos( 7.0, -11.5 ); break;
		case 3: panel.SetPos( 13.0, 1.0 ); break;
		case 4: panel.SetPos( 7.0, 13.0 ); break;
		case 5: panel.SetPos( -7.0, 13.0 ); break;
		case 6: panel.SetPos( -13.0, 1.0 ); break;
		default: throw "invalid slot"
	}

	switch ( type )
	{
		case SubMenu.Pistol:
			m_WeaponPanelsPistol.append( panel );
			break;
		case SubMenu.SMG:
			m_WeaponPanelsSMG.append( panel );
			break;
		case SubMenu.Rifle:
			m_WeaponPanelsRifle.append( panel );
			break;
		case SubMenu.Heavy:
			m_WeaponPanelsHeavy.append( panel );
			break;

		default: throw "invalid weapon type"
	}

	return panel;
}

function BuyMenuWorld::Activate( owner ) : (BaseClass)
{
	owner = ToExtendedPlayer( owner );

	if ( !BaseClass.Activate( owner ) )
		return false;

	SetPlaneFromEntity( Ent("buymenu") );

	return true;
}

function BuyMenuWorld::Disable() : (BaseClass)
{
	BaseClass.Disable();

	// m_cursor.SetVisible( false );
	m_BackgroundPanel.SetVisible( true );
	m_hTeamCoin.SetVisible( true );

	m_Wedges[1].SetVisible( true );
	m_Wedges[2].SetVisible( true );
	m_Wedges[3].SetVisible( true );
	m_Wedges[4].SetVisible( true );
	m_Wedges[5].SetVisible( true );
	m_Wedges[6].SetVisible( true );

	foreach( v in m_Labels )
		v.SetVisible( true );
}

function BuyMenuWorld::Think() : (BaseClass)
{
	// Think func is unrolled because BaseClass.Think does not call overwritten this.ThinkInternalRecursive

	if ( !CursorThink() )
		return;

	foreach( obj in m_children )
	{
		if ( !obj._enabled )
			continue;

		if ( m_bDebug )
			CScreenDebug.ThinkInternalRecursive( obj );
		else
			ThinkInternalRecursive( obj );
	}
}







::CreateBuyMenu <- function( player )
{
	if ( !(player = ToExtendedPlayer( player )) )
		return;

	if ( "m_hBuyMenu" in player.m_ScriptScope )
		return player.m_ScriptScope.m_hBuyMenu;

	return player.m_ScriptScope.m_hBuyMenu <- BuyMenu();
}


function SpawnBuyMenuHud()
{
	local player = VS.GetPlayerByIndex(1);
	local buymenu = CreateBuyMenu( player );
	if ( buymenu )
	{
		player.SetVelocity( Vector() );
		buymenu.Activate( player );
	};
}

function SpawnBuyMenuWorld()
{
	local player = VS.GetPlayerByIndex(1);
	if ( g_hBuyMenuWorld )
		g_hBuyMenuWorld.Activate( player );
}

function ToggleDebug()
{
	g_hBuyMenuWorld.m_bDebug = !g_hBuyMenuWorld.m_bDebug;
	printl( g_hBuyMenuWorld.m_bDebug );

	if ( g_hBuyMenuWorld.m_bDebug )
		CenterPrintAll( "debug <font color='#00ff00'>on</font>" )
	else
		CenterPrintAll( "debug <font color='#ff0000'>off</font>" )
}

::g_hBuyMenuWorld <- null;

function OnPostSpawn()
{
	::g_hBuyMenuWorld = BuyMenuWorld();
}

