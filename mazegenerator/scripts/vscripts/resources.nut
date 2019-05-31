//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------

::SMain <- this
function printd(i){if(DEBUG)printl(i)}
function prints(i){if(FINAL)printl(i)}

//--- Predefined user inputs ---

// default settings:
// maze size
_MAZE_X <- 150
_MAZE_Y <- 150

// start position and direction
_POS_START_X <- 8
_POS_START_Y <- 1
_ENTRYDIR <- 1

// exit position and direction
_POS_EXIT_X <- 8
_POS_EXIT_Y <- 150
_EXITDIR <- 3

// model settings, see the reference file
// min EXT is WALL
// EXT = WALL means there's no gap in the void
_EXT <-  4
_WALL <- 4
_CELL_SIZE <- 112

// [1,1] top left cell
pos_worldstart <- Vector(-10176,10176,0)

// every model is separate because spawned props cannot be rotated
const mdl_o_1 = "models/maze_generator/wall_o_1.mdl"
const mdl_o_2 = "models/maze_generator/wall_o_2.mdl"
const mdl_o_3 = "models/maze_generator/wall_o_3.mdl"
const mdl_o_4 = "models/maze_generator/wall_o_4.mdl"

const mdl_v_1 = "models/maze_generator/wall_v_1.mdl"
const mdl_v_2 = "models/maze_generator/wall_v_2.mdl"
const mdl_v_3 = "models/maze_generator/wall_v_3.mdl"
const mdl_v_4 = "models/maze_generator/wall_v_4.mdl"

const mdl_s_h = "models/maze_generator/wall_s_h.mdl"
const mdl_s_v = "models/maze_generator/wall_s_v.mdl"

const mdl_t_1 = "models/maze_generator/wall_t_1.mdl"
const mdl_t_2 = "models/maze_generator/wall_t_2.mdl"
const mdl_t_3 = "models/maze_generator/wall_t_3.mdl"
const mdl_t_4 = "models/maze_generator/wall_t_4.mdl"

const pxl_rev = "models/maze_generator/pixel_rev.mdl"
const mdl_player = "models/maze_generator/player_24.mdl"

//------------------------------

if( _WALL > _EXT)
	throw("WALL cannot be smaller than EXT")

//------------------------------

EXT <- (delete _EXT) - _WALL
CELL_DIST <- (delete _WALL) * 2 + (delete EXT) * 2 + (delete _CELL_SIZE)

breakwalls_amt <- 0
toggle_breakw <- 0
d_override <- 0
d_reverse <- 0
m_path <- array(1,0)

c_start <- null
c_exit <- null
c_previous <- null
c_next <- null

MAZE_YX <- null
