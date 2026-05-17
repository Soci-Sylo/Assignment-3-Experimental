extends Area3D

@export var checkpoint_id : int = 1

var triggered := false

signal checkpoint_reached(id: int)

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if triggered:
		return
	if body.is_in_group("player"):
		triggered = true
		checkpoint_reached.emit(checkpoint_id)
