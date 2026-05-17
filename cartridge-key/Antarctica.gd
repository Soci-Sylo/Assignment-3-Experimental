extends Node3D

# ─────────────────────────
# NODE REFERENCES
# ─────────────────────────
@onready var fade = $AntScene/CanvasLayer/Fade
@onready var radio_image = $AntScene/CanvasLayer/RadioImage
@onready var tutorial_panel = $AntScene/CanvasLayer/TutorialPanel
@onready var tutorial_text = $AntScene/CanvasLayer/TutorialPanel/VBoxContainer/TutorialText
@onready var continue_label = $AntScene/CanvasLayer/TutorialPanel/VBoxContainer/ContinueLabel
@onready var choice_buttons = $AntScene/CanvasLayer/TutorialPanel/VBoxContainer/ChoiceButtons
@onready var yes_button = $AntScene/CanvasLayer/TutorialPanel/VBoxContainer/ChoiceButtons/YesButton
@onready var no_button = $AntScene/CanvasLayer/TutorialPanel/VBoxContainer/ChoiceButtons/NoButton

@onready var player = $AntScene/CharacterBody3D
@onready var world_env = $AntScene/WorldEnvironment
@onready var figure = $AntScene/Creatures/Figure
@onready var ghost = $AntScene/Creatures/Ghost


# ─────────────────────────
# TUTORIAL STATE
# ─────────────────────────
var tutorial_slides := [
	"Yeah so we've had a report that satellite Kilo has gone down.",
	"Since you are the closest physically to it, naturally we'd like you to go down and repair it.",
	"You know the drill. Follow the poles, all the way.",
	"Inside the satellite looks to be the problem, one of the servers are down. Tch.",
	"New equipment they said, whatever.",
	"That's about it anyway.",
	"Oh... Wait... by the way, Control said to keep your eyes peeled for animals.",
	"We've had an uprising in recent reports of animal sightings in the plains.",
	"Nothing dangerous, no polar bears, probably just foxes...",
	"Goodluck, report in when you're finished."
]

var current_slide := 0
var in_tutorial := false
var tutorial_started := false


# ─────────────────────────
# READY
# ─────────────────────────
func _ready():
	if fade:
		fade.modulate.a = 1.0
		var t = create_tween()
		t.tween_property(fade, "modulate:a", 0.0, 2.0)

	tutorial_panel.visible = false
	continue_label.visible = false
	radio_image.visible = false
	ghost.visible = false

	for node in get_tree().get_nodes_in_group("checkpoint"):
		node.checkpoint_reached.connect(_on_checkpoint_reached)

	await get_tree().create_timer(5.0).timeout
	_start_tutorial()


# ─────────────────────────
# CHECKPOINT EVENTS
# ─────────────────────────
func _on_checkpoint_reached(id: int):
	match id:
		1:
			pass
		2:
			_event_figure_disappear()
			_event_fog_stage_one()
		3:
			_event_fog_stage_two()
		4:
			_event_fog_stage_two()
			_event_ghost()


# CHECKPOINT 2 — Figure waits 5s then fades out
func _event_figure_disappear():
	await get_tree().create_timer(5.0).timeout
	var t = create_tween()
	t.tween_property(figure, "modulate:a", 0.0, 1.5)
	await t.finished
	figure.visible = false


# CHECKPOINT 2 — Fog shifts to a mild warm orange over 30 seconds
func _event_fog_stage_one():
	var env = world_env.environment
	var start_color = env.fog_light_color
	var mid_color = Color(1.0, 0.75, 0.45)  # soft warm orange

	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_method(func(c: Color): env.fog_light_color = c, start_color, mid_color, 30.0)


# CHECKPOINT 3 — Fog shifts to full deep sunset orange over 60 seconds
func _event_fog_stage_two():
	var env = world_env.environment
	var start_color = env.fog_light_color  # picks up wherever stage one left off
	var end_color = Color(1.0, 0.45, 0.1)  # deep sunset orange

	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_method(func(c: Color): env.fog_light_color = c, start_color, end_color, 60.0)


# CHECKPOINT 4 — Ghost fades in, drifts toward player, fades out
func _event_ghost():
	ghost.visible = true
	ghost.modulate.a = 0.0

	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(ghost, "modulate:a", 1.0, 2.0)
	await t.finished

	var target_pos = player.global_transform.origin
	var t2 = create_tween()
	t2.set_ease(Tween.EASE_IN)
	t2.set_trans(Tween.TRANS_CUBIC)
	t2.tween_property(ghost, "global_position", target_pos, 4.0)
	await t2.finished

	var t3 = create_tween()
	t3.tween_property(ghost, "modulate:a", 0.0, 1.5)
	await t3.finished
	ghost.visible = false


# ─────────────────────────
# LOCK / UNLOCK PLAYER
# ─────────────────────────
func _set_player_locked(locked: bool):
	if not player:
		return
	player.locked = locked
	if locked:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# ─────────────────────────
# START TUTORIAL
# ─────────────────────────
func _start_tutorial():
	in_tutorial = true
	tutorial_started = false
	current_slide = 0
	_set_player_locked(true)

	radio_image.visible = true
	var screen_h = get_viewport().get_visible_rect().size.y
	radio_image.position.y = screen_h
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(radio_image, "position:y", screen_h - radio_image.size.y - 40, 0.6)

	await t.finished

	tutorial_panel.visible = true
	tutorial_text.text = tutorial_slides[0]
	choice_buttons.visible = true
	continue_label.visible = false

	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)


# ─────────────────────────
# BUTTON CALLBACKS
# ─────────────────────────
func _on_yes_pressed():
	choice_buttons.visible = false
	continue_label.visible = true
	continue_label.text = "Left click to continue"
	current_slide = 1
	tutorial_text.text = tutorial_slides[current_slide]
	await get_tree().create_timer(0.2).timeout
	tutorial_started = true


func _on_no_pressed():
	_end_tutorial()


# ─────────────────────────
# INPUT
# ─────────────────────────
func _input(event):
	if not in_tutorial or not tutorial_started:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_advance_tutorial()


# ─────────────────────────
# ADVANCE TUTORIAL
# ─────────────────────────
func _advance_tutorial():
	current_slide += 1

	if current_slide >= tutorial_slides.size():
		_end_tutorial()
		return

	tutorial_text.text = tutorial_slides[current_slide]

	if current_slide == tutorial_slides.size() - 1:
		continue_label.text = "Left click to close comms"


# ─────────────────────────
# END TUTORIAL
# ─────────────────────────
func _end_tutorial():
	in_tutorial = false
	tutorial_started = false

	var screen_h = get_viewport().get_visible_rect().size.y
	var t = create_tween()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(radio_image, "position:y", screen_h, 0.5)
	t.parallel().tween_property(tutorial_panel, "modulate:a", 0.0, 0.3)

	await t.finished

	tutorial_panel.visible = false
	tutorial_panel.modulate.a = 1.0
	radio_image.visible = false

	_set_player_locked(false)
