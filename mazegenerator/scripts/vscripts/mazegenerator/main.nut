//-----------------------------------------------------------------------
//----------------------- Copyright (C) 2019 Sam ------------------------
//                     github.com/samisalreadytaken
//
// This project is licensed under the terms of the GNU GPL license,
// see <https://www.gnu.org/licenses/> for details.
//-----------------------------------------------------------------------
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

IncludeScript("vs_library")

// debug
FINAL <- false
DEBUG <- false

// debug : maze generation delay
fGenDelay <- 0.0

// Dynamically spawn cell walls to allow incredibly large mazes
// Type in chat to toggle: "/dyn"
// Currently only works single player
maze_dynamic_spawning <- true

IncludeScript("/mazegenerator/resources.nut")
IncludeScript("/mazegenerator/core.nut")
IncludeScript("/mazegenerator/input.nut")
