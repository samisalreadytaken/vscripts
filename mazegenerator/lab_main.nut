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

IncludeScript("/mazegenerator/lab_resources.nut")
IncludeScript("/mazegenerator/lab_core.nut")
IncludeScript("/mazegenerator/lab_input.nut")
