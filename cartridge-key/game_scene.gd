extends Node3D

@onready var fade = $CanvasLayer/Fade

func _ready():
	fade.visible = true
	fade.modulate.a = 2.0

	# wait one frame so scene loads
	await get_tree().process_frame

	fade_in()


func fade_in():
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 2.0)  # 1 second fade

	await tween.finished

	fade.visible = false
