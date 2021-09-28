//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//- v0.1.0 --------------------------------------------------------------
//
// UI panel framework that allows mouse input.
// Drawing is done with world entities.
//
// Everything is subject to change.
//
// See buymenu.nut for an example
//
//
//	CBasePanel::CBasePanel( CBasePanel parentPanel = null, string debugName = null )
//	void CBasePanel::SetEnabled( bool state )
//	void CBasePanel::SetVisible( bool state )
//	void CBasePanel::SetVisibleRecurse( bool state )
//	void CBasePanel::SetParent( CBasePanel newParent )
//	void CBasePanel::AddChild( CBasePanel p )
//	void CBasePanel::SetSize( float w, float t )
//	void CBasePanel::SetPos( float x, float y )
//	void CBasePanel::SetPosRadial( float angleDegrees, float radius )
//	void CBasePanel::SetZPos( float z )
//	void CBasePanel::SetAbsPos( Vector vec )
//	void CBasePanel::Offset( float ix, float iy, float iz = 0.0 )
//	void CBasePanel::SetLocalAxes( Vector vx, Vector vy, Vector vz )
//	void CBasePanel::SetWorldEntity( CBaseEntity pEnt )
//	bool CBasePanel::IsOverlapping( CBasePanel otherPanel )
//	Vector CBasePanel::WorldToLocal( Vector vecWorld )
//	Vector CBasePanel::LocalToWorld( float x, float y )
//	void CBasePanel::DebugDraw( matrix3x4_t mat, int r = 255, int g = 127, int b = 0, int a = 2, float tm = 1.0 )
//	void CBasePanel::OnCursorEntered()
//	void CBasePanel::OnCursorExited()
//	void CBasePanel::OnMousePressed()
//	void CBasePanel::OnMouseReleased()
//
//	CBaseScreen::CBaseScreen( CTimerEntity pThink = null )
//	void CBaseScreen::SetPlane( Vector vecOrigin, Vector x, Vector y, Vector z )
//	void CBaseScreen::SetPlaneFromEntity( CBaseEntity pEnt )
//	void CBaseScreen::SetSize( float w, float t )
//	void CBaseScreen::SetAbsPos( Vector vec )
//	void CBaseScreen::Offset( float ix, float iy, float iz = 0.0 )
//	CBasePanel CBaseScreen::AddMember( CBasePanel|string input )
//	bool CBaseScreen::Activate( CBasePlayer owner )
//	bool CBaseScreen::Disable()
//	void CBaseScreen::ThinkInternalRecursive( CBasePanel obj )
//	bool CBaseScreen::CursorThink()
//	void CBaseScreen::Think()
//


// uses CExtendedPlayer
// uses vs_math
IncludeScript("vs_library");


const PLANE_X = 0;;
const PLANE_Y = 1;;
const PLANE_Z = 2;;

if ( !("g_nPanelCount" in getroottable()) )
	::g_nPanelCount <- 0;;

const PANEL_TYPEOF = "IPanel";;

//
// Basic lowest level of panel element.
//
class CBasePanel
{
	_index = 0xFFFFFFFF;

	// _pos
	xpos = 0.0;
	ypos = 0.0;
	zpos = 0.0;

	// _size
	wide = 0.0;
	tall = 0.0;

	// _radius = null;
	_tri0 = null;
	_tri1 = null;
	_tri2 = null;

	_enabled = true;
	_visible = true;

	_name = null;
	_parent = null;
	_children = null;
	// _clipRect = null;	// x, y, x+wide, y+tall

	// World vectors
	_absPos = null;
	_basisX = null;
	_basisY = null;
	_basisZ = null;

	_ent = null;

	_mouseOver = false;
	_mousePressed = false;

	// Overridables
	OnCursorEntered = dummy;
	OnCursorExited = dummy;
	OnMousePressed = dummy;
	OnMouseReleased = dummy;

	function _tostring() : (format)
	{
		if ( _name )
			return format( "(%s [0x%X] : \"%s\")", PANEL_TYPEOF, _index, _name );
		return format( "(%s [0x%X])", PANEL_TYPEOF, _index );
	}

	function _typeof()
	{
		return PANEL_TYPEOF;
	}
}

function CBasePanel::constructor( parentPanel = null, debugName = null )
{
	_index = ++::g_nPanelCount;

	if ( typeof parentPanel == PANEL_TYPEOF )
	{
		parentPanel.AddChild( this );
		_parent = parentPanel;
		_absPos = parentPanel._absPos * 1;

		_basisX = parentPanel._basisX * 1;
		_basisY = parentPanel._basisY * 1;
		_basisZ = parentPanel._basisZ * 1;
	}
	else
	{
		_absPos = Vector();

		_basisX = Vector(1,0,0);
		_basisY = Vector(0,1,0);
		_basisZ = Vector(0,0,1);
	};

	if ( debugName )
	{
		_name = debugName.tostring();
	};
}

function CBasePanel::SetEnabled( state )
{
	_enabled = !!state;

	if ( !state )
	{
		if ( _mouseOver )
		{
			_mouseOver = false;
			OnCursorExited();
		};

		if ( _mousePressed )
		{
			_mousePressed = false;
			OnMouseReleased();
		};
	};
}

function CBasePanel::SetVisible( state )
{
	_visible = !!state;

	if ( _ent )
	{
		if ( state )
		{
			_ent.__KeyValueFromInt( "effects", 0 );
		}
		else
		{
			_ent.__KeyValueFromInt( "effects", 32 );
		};
	};
}

function CBasePanel::SetVisibleRecurse( state )
{
	_visible = !!state;

	if ( _ent )
	{
		if ( state )
		{
			_ent.__KeyValueFromInt( "effects", 0 );
		}
		else
		{
			_ent.__KeyValueFromInt( "effects", 32 );
		};
	};

	if ( _children )
	{
		foreach( panel in _children )
		{
			panel.SetVisibleRecurse( state );
		}
	};
}

function CBasePanel::SetParent( newParent )
{
	// Clear parent
	if ( !newParent && _parent )
	{
		foreach( i, panel in _parent._children )
		{
			if ( panel == this )
			{
				_parent._children.remove(i);
				_parent = null;

				xpos = _absPos.Dot( _basisX );
				ypos = _absPos.Dot( _basisY );
				zpos = _absPos.Dot( _basisZ );

				return;
			};
		}
		// unreachable
		return Msg("BUGBUG!!! CBasePanel::SetParent()\n");
	};

	if ( typeof newParent != PANEL_TYPEOF || newParent == this || newParent == _parent )
		return;

	if ( _parent )
	{
		foreach( i, panel in _parent._children )
		{
			if ( panel == this )
			{
				_parent._children.remove(i);
				break;
			};
		}
	};

	newParent.AddChild( this );
	_parent = newParent;

	_basisX = _parent._basisX;
	_basisY = _parent._basisY;
	_basisZ = _parent._basisZ;

	// Resolve position in new local space.
	local vDelta = _absPos - _parent._absPos;
	xpos = vDelta.Dot( _basisX );
	ypos = vDelta.Dot( _basisY );
	zpos = vDelta.Dot( _basisZ );
}

function CBasePanel::AddChild( p )
{
	if ( p._parent == this )
		return;

	if ( !_children )
		_children = [];

	_children.append(p);
}

function CBasePanel::SetSize( w, t )
{
	wide = w;
	tall = t;
}

function CBasePanel::SetPos( ix, iy )
{
	xpos = ix;
	ypos = iy;

	if ( _parent )
	{
		_absPos = _parent._absPos + _basisX * ix + _basisY * iy + _basisZ * zpos;
	}
	else
	{
		_absPos = _basisX * ix + _basisY * iy + _basisZ * zpos;
	};

	if ( _children )
	{
		foreach( panel in _children )
		{
			// update children _absPos
			panel.SetPos( panel.xpos, panel.ypos );
		}
	};

	if ( _ent )
		_ent.SetAbsOrigin( _absPos );
}

function CBasePanel::SetPosRadial( angle, radius ) : (sin, cos)
{
	local th = DEG2RAD * angle;
	return SetPos( cos( th ) * radius, sin( th ) * radius );
}

function CBasePanel::SetZPos( iz )
{
	zpos = iz;
	return SetPos( xpos, ypos );
}

function CBasePanel::SetAbsPos( vec )
{
	zpos = vec.Dot( _basisZ );
	return SetPos(
		vec.Dot( _basisX ),
		vec.Dot( _basisY ) );
}

function CBasePanel::Offset( ix, iy, iz = 0.0 )
{
	zpos += iz;
	return SetPos( xpos + ix, ypos + iy );
}

function CBasePanel::SetLocalAxes( vx, vy, vz )
{
	vx *= 1; vy *= 1; vz *= 1;

	_basisX = vx;
	_basisY = vy;
	_basisZ = vz;

	if ( _parent )
	{
		_absPos = _parent._absPos + _basisX * xpos + _basisY * ypos + _basisZ * zpos;
	}
	else
	{
		_absPos = _basisX * xpos + _basisY * ypos + _basisZ * zpos;
	};

	if ( _children )
	{
		foreach( panel in _children )
		{
			panel.SetLocalAxes( vx, vy, vz );
		}
	};

	if ( _ent )
	{
		local ang = Vector();
		local transform = matrix3x4_t(
			_basisZ.x, -_basisX.x, -_basisY.x, 0.0,
			_basisZ.y, -_basisX.y, -_basisY.y, 0.0,
			_basisZ.z, -_basisX.z, -_basisY.z, 0.0 );
		VS.MatrixAngles( transform, ang );
		_ent.SetAngles( ang.x, ang.y, ang.z );
		_ent.SetAbsOrigin( _absPos );
	};
}
/*
//
// TODO: Proper rotation for all types
//
function CBasePanel::RotateZ( ang )
{
	if ( _ent )
	{
		local vForward = _ent.GetForwardVector();
		local vRight = _ent.GetLeftVector();
		local vUp = _ent.GetUpVector();

		local transform = matrix3x4_t(
			vForward.x, -vRight.x, vUp.x, 0.0,
			vForward.y, -vRight.y, vUp.y, 0.0,
			vForward.z, -vRight.z, vUp.z, 0.0 );

		local rot = matrix3x4_t();
		VS.MatrixBuildRotationAboutAxis( _basisZ, 360.0 - VS.AngleNormalize( ang.tofloat() ), rot );

		local matOut = matrix3x4_t();
		VS.ConcatRotations( transform, rot, matOut );

		local ang = Vector();
		VS.MatrixAngles( matOut, ang );

		_ent.SetAngles( ang.x, ang.y, ang.z );
	};

	if ( _tri0 )
	{
		_tri0 = VS.VectorYawRotate( _tri0, ang ) * 1;
		_tri1 = VS.VectorYawRotate( _tri1, ang ) * 1;
		_tri2 = VS.VectorYawRotate( _tri2, ang ) * 1;
	};
}
*/
function CBasePanel::SetWorldEntity( pEnt )
{
	if ( !pEnt )
		return;
	_ent = pEnt.weakref();

	local ang = Vector();
	// TODO: cache this?
	local transform = matrix3x4_t(
		_basisZ.x, -_basisX.x, -_basisY.x, 0.0,
		_basisZ.y, -_basisX.y, -_basisY.y, 0.0,
		_basisZ.z, -_basisX.z, -_basisY.z, 0.0 );
	VS.MatrixAngles( transform, ang );
	pEnt.SetAngles( ang.x, ang.y, ang.z );
	pEnt.SetAbsOrigin( _absPos );

	if ( _visible )
	{
		pEnt.__KeyValueFromInt( "effects", 0 );
	}
	else
	{
		pEnt.__KeyValueFromInt( "effects", 32 );
	};
}

//
// TODO: Collision type separation
// TODO: rect v tri
// TODO: circle
//
function CBasePanel::IsOverlapping( otherPanel )
{
	// point v triangle
	if ( otherPanel._tri0 )
	{
		local tx = otherPanel.xpos;
		local ty = otherPanel.ypos;

		local t0x = tx + otherPanel._tri0.x;
		local t0y = ty + otherPanel._tri0.y;

		local t1x = tx + otherPanel._tri1.x;
		local t1y = ty + otherPanel._tri1.y;

		local t2x = tx + otherPanel._tri2.x;
		local t2y = ty + otherPanel._tri2.y;

		local v12 = t1y - t2y;
		local v21 = t2x - t1x;
		local v02 = t0x - t2x;
		local dx2 = xpos - t2x;
		local dy2 = ypos - t2y;
		local d02 = t2y - t0y;

		local d = 1.0 / ( v12 * v02 - v21 * d02 );
		local u = ( v12 * dx2 + v21 * dy2 ) * d;
		local v = ( d02 * dx2 + v02 * dy2 ) * d;
		local t = 1.0 - u - v;

		return ( 0.0 <= u && u <= 1.0 && 0.0 <= v && v <= 1.0 && 0.0 <= t && t <= 1.0 );
	};

	local px = xpos;
	local py = ypos;

	local ox = otherPanel.xpos;
	local oy = otherPanel.ypos;

	// point v rect
	if ( !wide && !tall )
		return	( px >= ox ) &&
				( py >= oy ) &&
				( px <= ox + otherPanel.wide ) &&
				( py <= oy + otherPanel.tall );

	// rect v rect
	return	( px + wide > ox ) &&
			( py + tall > oy ) &&
			( px < ox + otherPanel.wide ) &&
			( py < oy + otherPanel.tall );
}

function CBasePanel::WorldToLocal( vecWorld ) : (Vector)
{
	local vDelta = _absPos - vecWorld;
	return Vector(
		vDelta.Dot( _basisX ),
		vDelta.Dot( _basisY ),
		vDelta.Dot( _basisZ ) );
}

function CBasePanel::LocalToWorld( x, y )
{
	return _absPos + _basisX * x + _basisY * y + _basisZ * zpos;
}

function CBasePanel::DebugDraw( mat, r = 255, g = 127, b = 0, a = 2, tm = 1.0 ) : (DebugDrawLine, DebugDrawBox)
{
	if ( !mat )
		return;

	// triangle
	if ( _tri0 )
	{
		local v0 = Vector( 0, -_tri0.x, -_tri0.y );
		local v1 = Vector( 0, -_tri1.x, -_tri1.y );
		local v2 = Vector( 0, -_tri2.x, -_tri2.y );

		VS.VectorRotate( v0, mat, v0 );
		VS.VectorRotate( v1, mat, v1 );
		VS.VectorRotate( v2, mat, v2 );

		VS.VectorAdd( v0, _absPos, v0 );
		VS.VectorAdd( v1, _absPos, v1 );
		VS.VectorAdd( v2, _absPos, v2 );

		DebugDrawLine( v0, v1, r, g, b, false, tm );
		DebugDrawLine( v1, v2, r, g, b, false, tm );
		DebugDrawLine( v0, v2, r, g, b, false, tm );

		local v = Vector(0.1,0.1,0.1);
		DebugDrawBox( v0, v*-1, v, r, g, b, 255, tm );
		DebugDrawBox( v1, v*-1, v, r, g, b, 255, tm );
		DebugDrawBox( v2, v*-1, v, r, g, b, 255, tm );

		DebugDrawBox( _absPos, v*-1, v, r, g, b, 255, tm );
		return;
	};

	local w = wide;
	local t = tall;

	// point
	if ( !w && !t )
	{
		local v = Vector(0.1,0.1,0.1);
		DebugDrawBox( _absPos, v*-1, v, r, g, b, a, tm );
		return;
	};

	// rect
	local verts = array(7);
	for ( local i = 7; i--; )
	{
		local v = verts[i] = Vector(
			0.0,
			( i & 2 ) ? -w : 0.0,
			( i & 4 ) ? -t : 0.0 );
		VS.VectorRotate( v, mat, v );
		VS.VectorAdd( v, _absPos, v );
	}

	DebugDrawLine( verts[0], verts[4], r, g, b, false, tm );
	DebugDrawLine( verts[4], verts[6], r, g, b, false, tm );
	DebugDrawLine( verts[6], verts[2], r, g, b, false, tm );
	DebugDrawLine( verts[2], verts[0], r, g, b, false, tm );
}



//
// A screen of panels with mouse logic for the activator.
// Calls member panel callbacks and passes themselves to them.
//
class CBaseScreen
{
	m_bActive = false;

	m_cursor = null;
	m_base = null;
	m_traceRay = null;

	m_Edges = null;
	m_Basis = null;
	m_thisToWorld = null;

	m_children = null;

	m_hThink = null;

	m_hOwner = null;

	m_bMouseDown = false;
	m_hSelectedPanel = null;
}

function CBaseScreen::constructor( pThink = null ) : (CBasePanel)
{
	if ( !pThink && !m_hThink )
	{
		pThink = Entities.CreateByClassname("logic_timer");
		VS.MakePersistent( pThink );
	};

	m_hThink = pThink.weakref();
	m_hThink.__KeyValueFromFloat( "refiretime", 1.0 / 64.0 );
	m_hThink.__KeyValueFromInt( "userandomtime", 0 );
	m_hThink.__KeyValueFromInt( "nextthink", 0xFFFFFFFF );
	m_hThink.ValidateScriptScope();
	m_hThink.GetScriptScope().PanelThink <- Think.bindenv(this);
	m_hThink.ConnectOutput( "OnTimer", "PanelThink" );

	if ( !m_base )
		m_base = CBasePanel( null, "base" );

	if ( !m_cursor )
		m_cursor = CBasePanel( m_base, "cursor" );

	m_children = [];

	local v3 = Vector();
	m_Edges = [ v3, v3, v3 ];
	m_Basis = [ Vector(1,0,0), Vector(0,1,0), Vector(0,0,1) ];
	m_traceRay = Ray_t();
}

function CBaseScreen::SetPlane( vecOrigin, x, y, z )
{
	m_Basis[PLANE_X] = x * 1;
	m_Basis[PLANE_Y] = y * 1;
	m_Basis[PLANE_Z] = z * 1;

	// top left, top right, bottom left
	m_Edges[0] = vecOrigin * 1;
	m_Edges[1] = m_Edges[0] + m_Basis[PLANE_X] * m_base.wide;
	m_Edges[2] = m_Edges[0] + m_Basis[PLANE_Y] * m_base.tall;

	m_thisToWorld = matrix3x4_t(
		m_Basis[PLANE_Z].x, -m_Basis[PLANE_X].x, -m_Basis[PLANE_Y].x, 0.0,
		m_Basis[PLANE_Z].y, -m_Basis[PLANE_X].y, -m_Basis[PLANE_Y].y, 0.0,
		m_Basis[PLANE_Z].z, -m_Basis[PLANE_X].z, -m_Basis[PLANE_Y].z, 0.0 );

	m_base.SetLocalAxes( m_Basis[PLANE_X], m_Basis[PLANE_Y], m_Basis[PLANE_Z] );
	m_base.SetAbsPos( m_Edges[0] );

	foreach( v in m_children )
		v.SetLocalAxes( m_Basis[PLANE_X], m_Basis[PLANE_Y], m_Basis[PLANE_Z] );
}

//
// Entity origin at top left
//
function CBaseScreen::SetPlaneFromEntity( pEnt )
{
	if ( !pEnt || !pEnt.IsValid() )
		return;

	return SetPlane(
		pEnt.GetOrigin(),
		pEnt.GetLeftVector() * -1,
		pEnt.GetUpVector() * -1,
		pEnt.GetForwardVector() );
}

function CBaseScreen::SetSize( w, t )
{
	m_base.SetSize( w, t );

	// update edges
	m_Edges[1] = m_Edges[0] + m_Basis[PLANE_X] * m_base.wide;
	m_Edges[2] = m_Edges[0] + m_Basis[PLANE_Y] * m_base.tall;
}

function CBaseScreen::SetAbsPos( vec )
{
	m_Edges[0] = vec * 1;
	m_Edges[1] = m_Edges[0] + m_Basis[PLANE_X] * m_base.wide;
	m_Edges[2] = m_Edges[0] + m_Basis[PLANE_Y] * m_base.tall;

	return m_base.SetAbsPos( vec );
}

function CBaseScreen::Offset( ix, iy, iz = 0.0 )
{
	m_base.Offset( ix, iy, iz );

	m_Edges[0] = m_base._absPos;
	m_Edges[1] = m_Edges[0] + m_Basis[PLANE_X] * m_base.wide;
	m_Edges[2] = m_Edges[0] + m_Basis[PLANE_Y] * m_base.tall;
}

//
// Create new or add an existing panel
//
function CBaseScreen::AddMember( input )
	: (CBasePanel)
{
	local p;

	switch ( typeof input )
	{
		case PANEL_TYPEOF:
		{
			foreach( panel in m_children )
			{
				if ( panel._name == input._name )
					return;
			}

			p = input;
			p.SetParent( m_base );
			break;
		}
		case "string":
		{
			foreach( panel in m_children )
			{
				if ( panel._name == input )
					return;
			}

			p = CBasePanel( m_base, input );
			break;
		}
		default: throw "invalid parameter"
	}

	p.SetLocalAxes( m_Basis[PLANE_X], m_Basis[PLANE_Y], m_Basis[PLANE_Z] );
	m_children.append( p );

	return p;
}

function CBaseScreen::InternalMousePressed( owner )
{
	m_bMouseDown = true;
}

function CBaseScreen::InternalMouseRelease( owner )
{
	m_bMouseDown = false;
}

function CBaseScreen::Activate( owner )
{
	m_hOwner = ToExtendedPlayer( owner );

	if ( !m_hOwner )
		return false;

	local uid = this.tostring();

	VS.SetInputCallback( m_hOwner, "+attack", InternalMousePressed.bindenv(this), uid );
	VS.SetInputCallback( m_hOwner, "-attack", InternalMouseRelease.bindenv(this), uid );

	EntFireByHandle( m_hThink, "Enable" );

	m_bActive = true;

	return true;
}

function CBaseScreen::Disable()
{
	m_bActive = false;

	if ( m_hOwner )
	{
		local uid = this.tostring();
		VS.SetInputCallback( m_hOwner, "+attack", null, uid );
		VS.SetInputCallback( m_hOwner, "-attack", null, uid );

		// m_hOwner = null;
		VS.EventQueue.AddEvent( function() { m_hOwner = null; }, 0.001, this );
	};

	m_hThink.__KeyValueFromInt( "nextthink", 0xFFFFFFFF );
	EntFireByHandle( m_hThink, "Disable" );
}

function CBaseScreen::CursorThink()
{
	local traceOrigin = m_hOwner.EyePosition();
	local viewRay = m_hOwner.EyeForward() * MAX_COORD_FLOAT;
	m_traceRay.Init( traceOrigin, traceOrigin + viewRay );

	local uvt = [null,null,null];

	if ( !VS.ComputeIntersectionBarycentricCoordinates( m_traceRay, m_Edges[0], m_Edges[1], m_Edges[2], uvt ) ||
		uvt[2] < 0.0 )
	{
		if ( m_cursor._visible )
			m_cursor.SetVisible( false );
		return false;
	};

	local u = uvt[0];
	local v = uvt[1];

	if ( (u < 0.0) || (v < 0.0) || (u > 1.0) || (v > 1.0) )
	{
		if ( m_cursor._visible )
			m_cursor.SetVisible( false );
	}
	else if ( !m_cursor._visible && m_bActive )
	{
		m_cursor.SetVisible( true );
	};;

	m_cursor.SetPos( u * m_base.wide, v * m_base.tall );

	return true;
}

//
// Collision check input and its children against the cursor, fire off outputs
//
function CBaseScreen::ThinkInternalRecursive( obj )
{
	if ( m_cursor.IsOverlapping( obj ) )
	{
		if ( !obj._mouseOver )
		{
			obj._mouseOver = true;
			obj.OnCursorEntered();
		};

		// m_hSelectedPanel allows keeping only 1 panel selected while holding down mouse 1.
		// Remove this check to enable 'drag and select' type of behaviour
		if ( m_bMouseDown && !m_hSelectedPanel && !obj._mousePressed )
		{
			m_hSelectedPanel = obj;
			obj._mousePressed = true;
			obj.OnMousePressed();
		};
	}
	else if ( obj._mouseOver )
	{
		obj._mouseOver = false;
		obj.OnCursorExited();
	};;

	if ( !m_bMouseDown && obj._mousePressed )
	{
		m_hSelectedPanel = null;
		obj._mousePressed = false;
		obj.OnMouseReleased();
	};

	if ( obj._children )
	{
		foreach ( p in obj._children )
		{
			if ( p._enabled )
				ThinkInternalRecursive( p );
		}
	};
}

function CBaseScreen::Think()
{
	// don't calc collision if cursor is not on screen plane
	if ( !CursorThink() )
		return;

	foreach( obj in m_children )
	{
		if ( obj._enabled )
			ThinkInternalRecursive( obj );
	}
}




class CScreenDebug extends CBaseScreen
{
}

local BaseClass = CBaseScreen;

function CScreenDebug::Think() : (BaseClass)
{
	BaseClass.Think();

	local x = m_Edges[0] + m_Basis[PLANE_X] * m_cursor.xpos;
	local y = m_Edges[0] + m_Basis[PLANE_Y] * m_cursor.ypos;

	local maxs = Vector(0.2,0.2,0.2);
	local mins = maxs*-1;

	DebugDrawBox( x, mins, maxs, 255,0,0,255, -1 );
	DebugDrawBox( y, mins, maxs, 0,255,0,255, -1 );

	DebugDrawLine( m_Edges[0], m_Edges[1], 255,0,0,true,-1 );
	DebugDrawLine( m_Edges[0], m_Edges[2], 0,255,0,true,-1 );
	DebugDrawLine( m_Edges[0], m_Edges[0] + m_Basis[PLANE_Z] * 16.0, 0,0,255,true,-1 );

	// m_cursor.DebugDraw( m_thisToWorld, 255, 255, 255, 255, -1 );
	VS.DrawVertArrow( m_cursor._absPos + m_cursor._basisY * 4 + m_cursor._basisX * 2, m_cursor._absPos, 0.75, 255,255,255,true,-1 );
	VS.DrawHorzArrow( m_cursor._absPos + m_cursor._basisY * 4 + m_cursor._basisX * 2, m_cursor._absPos, 0.75, 255,255,255,true,-1 );
}

function CScreenDebug::ThinkInternalRecursive( obj ) : (BaseClass)
{
	BaseClass.ThinkInternalRecursive( obj );

	if ( obj._mousePressed )
		obj.DebugDraw( m_thisToWorld, 0, 255, 255, 16, 0.1 );

	else if ( obj._mouseOver )
		obj.DebugDraw( m_thisToWorld, 0, 255, 0, 2, 0.1 );

	else
		obj.DebugDraw( m_thisToWorld, 255, 255, 255, 2, -1 );
}


::CBasePanel <- CBasePanel;
::CBaseScreen <- CBaseScreen;
::CScreenDebug <- CScreenDebug;

