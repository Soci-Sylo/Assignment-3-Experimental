# GameState.gd
# Add this as an Autoload in Project > Project Settings > Autoload
# Name it exactly: GameState
extends Node

var is_inspecting := false
var inserted_cartridge = null
var is_cutscene := false
var completed_games: Array = []
