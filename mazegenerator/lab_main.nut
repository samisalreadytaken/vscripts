//-----------------------------------------------------------------------
//------------ Copyright (C) 2019 Sam - STEAM_0:1:26669608 --------------
// https://github.com/samisalreadytaken
//
// This project is licensed under the terms of the GNU GPL license,
// see <https://www.gnu.org/licenses/> for details.
//-----------------------------------------------------------------------
//------------------------------
//
// Depth-first search maze generator in CS:GO
//
// Messy code because I didn't expect it to become this large,
// it started as a little experiment.
//
// See this code in action:
//  	https://www.youtube.com/watch?v=2yNebauZGSg
//  	https://www.youtube.com/watch?v=6Vmb2GzbtHs
//
//------------------------------

IncludeScript("/vs_library/vs_include.nut")

// debug
FINAL <- 0
DEBUG <- 0

// to do: remove the need for 2 variables
showprocess <- false
fGenDelay <- 0.0

// dynamically spawn cell walls to allow incredibly large mazes
// currently only works single player
maze_dynamic_spawning <- true

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

if( _WALL > _EXT)
	throw("WALL cannot be smaller than EXT")

if( showprocess && fGenDelay == 0.0 )
	throw("Cannot show process without a delay!")

// [1,1] top left cell
VS.Console.pos_worldstart <- Vector(-10176,10176,0)

// every model is separate because spawned props cannot be rotated
mdl_o_1 <- "models/maze_generator/wall_o_1.mdl"
mdl_o_2 <- "models/maze_generator/wall_o_2.mdl"
mdl_o_3 <- "models/maze_generator/wall_o_3.mdl"
mdl_o_4 <- "models/maze_generator/wall_o_4.mdl"

mdl_v_1 <- "models/maze_generator/wall_v_1.mdl"
mdl_v_2 <- "models/maze_generator/wall_v_2.mdl"
mdl_v_3 <- "models/maze_generator/wall_v_3.mdl"
mdl_v_4 <- "models/maze_generator/wall_v_4.mdl"

mdl_s_h <- "models/maze_generator/wall_s_h.mdl"
mdl_s_v <- "models/maze_generator/wall_s_v.mdl"

mdl_t_1 <- "models/maze_generator/wall_t_1.mdl"
mdl_t_2 <- "models/maze_generator/wall_t_2.mdl"
mdl_t_3 <- "models/maze_generator/wall_t_3.mdl"
mdl_t_4 <- "models/maze_generator/wall_t_4.mdl"

pxl_rev <- "models/maze_generator/pixel_rev.mdl"
mdl_player <- "models/maze_generator/player_24.mdl"

IncludeScript("/mazegenerator/lab_core.nut")
IncludeScript("/mazegenerator/lab_input.nut")