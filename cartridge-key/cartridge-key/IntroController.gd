extends Node

var fade
var fade2
var started = false
var active_tween

@onready var cams = [
	get_parent().get_node("Camera_Floor"),
	get_parent().get_node("Camera_Wall"),
	get_parent().get_node("Camera_Desk"),
	get_parent().get_node("Camera_Door")
]


# ─────────────────────────────
# SETUP REFERENCES ONLY
# ─────────────────────────────
func _enter_tree():
	fade = get_parent().get_node("CanvasLayer/Fade")


# ─────────────────────────────
# SAFE START
# ─────────────────────────────
func _ready():
	print("READY CALLED")

	# OLD SYSTEM STARTS NORMAL
	set_all_cameras_off()
	fade.visible = true
	fade.modulate.a = 1.0

	await get_tree().process_frame

	start_intro()

	# NEW SYSTEM RUNS COMPLETELY SEPARATE (NO IMPACT ON GAME FLOW)
	run_fade2_intro()


func run_fade2_intro():
	fade2 = get_parent().get_node("CanvasLayer2/Fade2")

	fade2.visible = true
	fade2.modulate.a = 1.0

	await get_tree().create_timer(3.0).timeout

	var t = create_tween()
	t.tween_property(fade2, "modulate:a", 0.0, 3.0)


# ─────────────────────────────
# MAIN SEQUENCE (SAFE FROM DOUBLE RUNS)
# ─────────────────────────────
func start_intro():
	if started:
		return

	started = true
	print("START INTRO CALLED")

	await fade_to_black()
	await play_camera_sequence()
	await fade_to_black()

	start_game()


# ─────────────────────────────
# FADE IN (BLACK → GAME)
# ─────────────────────────────
func fade_from_black():
	fade.visible = true

	if active_tween:
		active_tween.kill()

	fade.modulate.a = 1.0

	active_tween = create_tween()
	active_tween.tween_property(fade, "modulate:a", 0.0, 1.2)

	await active_tween.finished


# ─────────────────────────────
# FADE OUT (GAME → BLACK)
# ─────────────────────────────
func fade_to_black():
	fade.visible = true

	if active_tween:
		active_tween.kill()

	fade.modulate.a = 0.0

	active_tween = create_tween()
	active_tween.tween_property(fade, "modulate:a", 1.0, 1.2)

	await active_tween.finished


# ─────────────────────────────
# CAMERA SEQUENCE
# ─────────────────────────────
func play_camera_sequence():

	for i in range(cams.size()):

		await fade_to_black()

		set_all_cameras_off()
		var cam = cams[i]
		cam.current = true

		await get_tree().process_frame

		var start_pos = cam.position
		var tween = create_tween()

		# smoother motion only
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)

		if cam.name == "Camera_Floor":
			tween.parallel().tween_property(cam, "position:y", start_pos.y - 3.0, 10.0)
			tween.parallel().tween_property(cam, "rotation:y", cam.rotation.y + 0.3, 10.0)

		elif cam.name == "Camera_Wall":
			tween.parallel().tween_property(cam, "position:x", start_pos.x - 2.0, 6.0)

		elif cam.name == "Camera_Desk":
			tween.parallel().tween_property(cam, "position:z", start_pos.z - 2.5, 6.0)

		elif cam.name == "Camera_Door":
			tween.parallel().tween_property(cam, "position:z", start_pos.z + 2.5, 6.0)

		await fade_from_black()

		await tween.finished

		await get_tree().create_timer(0.1).timeout


# ─────────────────────────────
# CAMERA CONTROL
# ─────────────────────────────
func set_all_cameras_off():
	for c in cams:
		c.current = false


# ─────────────────────────────
# END
# ─────────────────────────────
func start_game():
	get_tree().change_scene_to_file("res://game_scene.tscn")
