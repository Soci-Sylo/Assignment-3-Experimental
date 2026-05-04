# Cartridge.gd
extends "res://cartridge_base.gd"

@export var game_id: String = "drone"

func _ready():
	super._ready()
	if game_id in GameState.completed_games:
		queue_free()
