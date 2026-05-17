extends Node3D

@onready var mesh: MeshInstance3D = $Cube008

var original_position: Vector3
var original_transform: Transform3D
var tween: Tween

@export var slide_distance := 0.1
@export var slide_speed := 0.15

var original_material: Material
var glow_material: Material

# INSPECT
var is_inspecting := false
var inspect_sensitivity := 0.005
var inspect_distance := 0.45
var inspect_min_distance := 0.25
var inspect_base_position := Vector3.ZERO
var inspect_base_rotation := Vector3.ZERO
var inspect_zoom_speed := 0.05
var zoom_tween: Tween

# TEXT PANEL
var text_panel_visible := false
@export var cartridge_title := ""
@export var cartridge_body := ""

# INSERT
var insert_panel = null
var is_confirming := false
var is_inserted := false
@export var game_scene: String = ""


func _ready():
	if mesh:
		original_material = mesh.get_active_material(0)
	original_position = position
	original_transform = global_transform


# ─────────────────────────
# LOOK GLOW + SLIDE
# ─────────────────────────
func on_looked_at(state: bool):
	if is_inspecting or is_inserted:
		return
	if state:
		_enable_glow()
		_slide_out()
	else:
		_disable_glow()
		_slide_in()


func _enable_glow():
	if mesh == null or original_material == null:
		return
	if glow_material == null:
		glow_material = original_material.duplicate()
		if glow_material is StandardMaterial3D:
			glow_material.emission_enabled = true
			glow_material.emission = Color(1, 1, 1)
			glow_material.emission_energy_multiplier = 3.0
	mesh.set_surface_override_material(0, glow_material)


func _disable_glow():
	if mesh == null:
		return
	mesh.set_surface_override_material(0, original_material)


func _slide_out():
	if tween:
		tween.kill()
	tween = create_tween()
	var forward = -transform.basis.x.normalized()
	var target_pos = original_position + forward * slide_distance
	tween.tween_property(self, "position", target_pos, slide_speed)


func _slide_in():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", original_position, slide_speed)


# ─────────────────────────
# TEXT PANEL
# ─────────────────────────
func _get_text_panel() -> Control:
	return get_tree().get_root().find_child("CartridgeTextPanel", true, false)

func _show_text_panel():
	var panel = _get_text_panel()
	if panel == null:
		return
	panel.get_node("PanelContainer/MarginContainer/VBoxContainer/CartridgeTitle").text = cartridge_title
	panel.get_node("PanelContainer/MarginContainer/VBoxContainer/CartridgeBody").text = cartridge_body
	panel.visible = true
	panel.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(panel, "modulate:a", 1.0, 0.2)
	text_panel_visible = true

func _hide_text_panel():
	var panel = _get_text_panel()
	if panel == null:
		return
	var t = create_tween()
	t.tween_property(panel, "modulate:a", 0.0, 0.2)
	t.tween_callback(func(): panel.visible = false)
	text_panel_visible = false


# ─────────────────────────
# INSERT CONFIRMATION
# ─────────────────────────
func _get_insert_panel() -> Control:
	return get_tree().get_root().find_child("InsertPanel", true, false)

func _disconnect_buttons():
	var panel = _get_insert_panel()
	if panel == null:
		return
	var yes = panel.get_node("VBoxContainer/HBoxContainer/YesButton")
	var no = panel.get_node("VBoxContainer/HBoxContainer/NoButton")
	if yes.pressed.is_connected(_on_insert_confirmed):
		yes.pressed.disconnect(_on_insert_confirmed)
	if no.pressed.is_connected(_on_insert_cancelled):
		no.pressed.disconnect(_on_insert_cancelled)

func show_insert_confirmation():
	if is_confirming:
		return
	is_confirming = true

	if text_panel_visible:
		_hide_text_panel()

	var panel = _get_insert_panel()
	if panel == null:
		return

	panel.get_node("VBoxContainer/InsertLabel").text = "Insert \"" + cartridge_title + "\" into the computer?\nDoing so will start the game."

	_disconnect_buttons()

	var yes = panel.get_node("VBoxContainer/HBoxContainer/YesButton")
	var no = panel.get_node("VBoxContainer/HBoxContainer/NoButton")
	yes.pressed.connect(_on_insert_confirmed)
	no.pressed.connect(_on_insert_cancelled)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	panel.visible = true
	panel.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(panel, "modulate:a", 1.0, 0.2)


func _hide_insert_panel():
	var panel = _get_insert_panel()
	if panel == null:
		return
	var t = create_tween()
	t.tween_property(panel, "modulate:a", 0.0, 0.2)
	t.tween_callback(func(): panel.visible = false)


func _on_insert_confirmed():
	_disconnect_buttons()
	is_confirming = false
	_hide_insert_panel()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_do_insert()


func _on_insert_cancelled():
	_disconnect_buttons()
	is_confirming = false
	_hide_insert_panel()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _do_insert():
	var slot = get_tree().get_root().find_child("CartridgeSlot", true, false)
	if slot == null:
		return

	is_inserted = true
	GameState.inserted_cartridge = self
	is_inspecting = false
	GameState.is_inspecting = false

	var fade = get_tree().get_first_node_in_group("fade")

	# fly to slot position
	var t = create_tween()
	t.tween_property(self, "global_position", slot.global_position, 0.4)
	t.parallel().tween_property(self, "global_rotation", slot.global_rotation, 0.4)

	# wait a beat
	t.tween_interval(2.0)

	# slide backwards into the hole
	t.tween_callback(func():
		var insert_target = slot.global_position + slot.global_transform.basis.x * -0.15
		var t2 = create_tween()
		t2.tween_property(self, "global_position", insert_target, 0.8)
	)

	# wait for slide then lock everything and fade
	t.tween_interval(0.9)
	t.tween_callback(func():
		GameState.is_cutscene = true
		var t3 = create_tween()
		t3.tween_property(fade, "modulate:a", 1.0, 1.2)
		t3.tween_callback(func():
			get_tree().change_scene_to_file(game_scene)
		)
	)


# ─────────────────────────
# INSPECT SYSTEM
# ─────────────────────────
func _get_inspect_position(cam: Camera3D) -> Vector3:
	var center_offset = cam.global_transform.basis.x * 0.03
	return cam.global_transform.origin + cam.global_transform.basis.z * -inspect_distance + center_offset


func start_inspect(camera: Camera3D, fade: CanvasItem):
	if is_inspecting:
		return
	is_inspecting = true
	GameState.is_inspecting = true
	_disable_glow()

	var t = create_tween()
	t.tween_property(fade, "modulate:a", 0.5, 0.2)
	t.tween_callback(func():
		inspect_distance = 0.45
		var target_pos = _get_inspect_position(camera)
		inspect_base_position = target_pos
		inspect_base_rotation = camera.global_rotation + Vector3(deg_to_rad(90), 0, 0)
		var t2 = create_tween()
		t2.tween_property(self, "global_position", target_pos, 0.25)
		t2.parallel().tween_property(self, "global_rotation", inspect_base_rotation, 0.25)
	)


func end_inspect(fade: CanvasItem):
	if not is_inspecting:
		return

	is_inspecting = false
	GameState.is_inspecting = false

	if text_panel_visible:
		_hide_text_panel()

	var t = create_tween()
	t.tween_property(self, "global_transform", original_transform, 0.25)
	t.tween_property(fade, "modulate:a", 0.0, 0.2)


func _input(event):
	if not is_inspecting and not is_confirming:
		return
	if is_inserted:
		return
	if is_confirming:
		return

	# LEFT CLICK — show insert confirmation
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			show_insert_confirmation()
			get_viewport().set_input_as_handled()
			return

	# spin with mouse
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * inspect_sensitivity)
		var cam = get_tree().get_first_node_in_group("player").get_node("Camera3D")
		rotate(cam.global_transform.basis.x, -event.relative.y * inspect_sensitivity)
		get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.pressed:
		var cam = get_tree().get_first_node_in_group("player").get_node("Camera3D")

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			inspect_distance = max(inspect_min_distance, inspect_distance - inspect_zoom_speed)
			var target_pos = _get_inspect_position(cam)
			if zoom_tween:
				zoom_tween.kill()
			zoom_tween = create_tween()
			zoom_tween.set_ease(Tween.EASE_OUT)
			zoom_tween.set_trans(Tween.TRANS_CUBIC)
			zoom_tween.tween_property(self, "global_position", target_pos, 0.15)
			get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			inspect_distance = min(0.45, inspect_distance + inspect_zoom_speed)
			var target_pos = _get_inspect_position(cam)
			if zoom_tween:
				zoom_tween.kill()
			zoom_tween = create_tween()
			zoom_tween.set_ease(Tween.EASE_OUT)
			zoom_tween.set_trans(Tween.TRANS_CUBIC)
			zoom_tween.tween_property(self, "global_position", target_pos, 0.15)
			get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var fade = get_tree().get_first_node_in_group("fade")
			end_inspect(fade)
			get_viewport().set_input_as_handled()

	# TAB to toggle text panel
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB:
			if text_panel_visible:
				_hide_text_panel()
			else:
				_show_text_panel()
			get_viewport().set_input_as_handled()

		if event.keycode == KEY_R:
			var cam = get_tree().get_first_node_in_group("player").get_node("Camera3D")
			inspect_distance = 0.45
			var reset_pos = _get_inspect_position(cam)
			var t = create_tween()
			t.tween_property(self, "global_position", reset_pos, 0.2)
			t.parallel().tween_property(self, "global_rotation", inspect_base_rotation, 0.2)
			get_viewport().set_input_as_handled()
