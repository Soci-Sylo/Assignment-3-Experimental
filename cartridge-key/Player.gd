extends CharacterBody3D

const WALK_SPEED = 2.5
const CROUCH_SPEED = 1.1
const GRAVITY = 9.8

var mouse_sensitivity := 0.002
var sit_mouse_sensitivity := 0.0008

@onready var camera = $Camera3D
@onready var ui_text = get_parent().get_node("CanvasLayer2/InteractionText")
@onready var fade = get_parent().get_node("CanvasLayer3/Fade")
@onready var sit_fade_overlay = get_parent().get_node("CanvasLayer3/Fade")

var sit_base_yaw := 0.0
var sit_yaw := 0.0
var sit_yaw_limit := deg_to_rad(50)

var current_target = null
var last_target = null

var bob_time := 0.0
var bob_speed := 8.0
var bob_amount := 0.05
var base_cam_y := 0.0

var is_crouching := false
var crouch_offset := 0.6
var crouch_speed := 5.0

var crouch_tilt := 0.08
var crouch_tilt_speed := 6.0
var tilt_time := 0.0

# SIT SYSTEM
var is_sitting := false
var sit_target = null


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_cam_y = camera.position.y
	ui_text.visible = false
	add_to_group("player")

	if fade:
		fade.visible = true
		fade.modulate.a = 0.0
		fade.add_to_group("fade")


func _input(event):
	if GameState.is_cutscene:
		return

	# SIT EXIT
	if is_sitting and not GameState.is_inspecting and event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			stand_up()

	# START INSPECT (left click on cartridge)
	if is_sitting and not GameState.is_inspecting and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var target = get_look_target()
			if target and target.has_method("start_inspect"):
				target.start_inspect(camera, fade)


	# MOUSE LOOK — locked during inspect
	if event is InputEventMouseMotion:
		if GameState.is_inspecting:
			return

		var sens = sit_mouse_sensitivity if is_sitting else mouse_sensitivity

		if is_sitting:
			sit_yaw -= event.relative.x * sens
			sit_yaw = clamp(sit_yaw, -sit_yaw_limit, sit_yaw_limit)
			rotation.y = sit_base_yaw + sit_yaw

			camera.rotation.x -= event.relative.y * sens
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(20))

			update_sit_edge_fade()

		else:
			rotate_y(-event.relative.x * sens)
			camera.rotate_x(-event.relative.y * sens)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))


func get_look_target():
	var space_state = get_world_3d().direct_space_state

	var from = camera.global_transform.origin
	var to = from + -camera.global_transform.basis.z * 3.0

	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		var obj = result.collider

		while obj:
			if obj.has_method("on_looked_at"):
				return obj
			if obj.name == "Seat":
				return obj
			obj = obj.get_parent()

	return null


func start_sit(target):
	if is_sitting:
		return

	sit_target = target
	is_sitting = true

	ui_text.visible = false
	current_target = null

	sit_base_yaw = target.global_transform.basis.get_euler().y + deg_to_rad(90)
	sit_yaw = 0.0

	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.25)
	tween.tween_callback(func():
		global_transform.origin = sit_target.global_transform.origin - Vector3(-0.5, 0.3, 0)
		velocity = Vector3.ZERO
		rotation.y = sit_base_yaw
		camera.rotation.x = 0
	)
	tween.tween_property(fade, "modulate:a", 0.0, 0.25)


func stand_up():
	if not is_sitting:
		return

	var seat = sit_target
	var t = create_tween()

	t.tween_property(fade, "modulate:a", 1.0, 0.25)
	t.tween_callback(func():
		if seat:
			global_transform.origin = seat.global_transform.origin + Vector3(0.5, -0.5, -0.5)
		velocity = Vector3.ZERO
		rotation.y = sit_base_yaw
		sit_yaw = 0.0
		camera.rotation.x = 0
		is_sitting = false
	)
	t.tween_property(fade, "modulate:a", 0.0, 0.25)


func update_sit_edge_fade():
	if not is_sitting:
		return

	var t = abs(sit_yaw) / sit_yaw_limit
	t = clamp(t, 0.0, 1.0)

	sit_fade_overlay.modulate.a = lerp(0.0, 0.45, t)





func _physics_process(delta):

	# SITTING MODE
	if is_sitting:
		velocity = Vector3.ZERO
		is_crouching = false

		var target = get_look_target()

		if last_target and last_target != target:
			if last_target.has_method("on_looked_at"):
				last_target.on_looked_at(false)

		last_target = target

		if target and target.name.begins_with("Cartridge"):
			if target.has_method("on_looked_at"):
				target.on_looked_at(true)

		ui_text.visible = false
		current_target = null
		return

	# NORMAL MODE
	is_crouching = Input.is_action_pressed("crouch")

	var target = get_look_target()

	if last_target and last_target != target:
		if last_target.has_method("on_looked_at"):
			last_target.on_looked_at(false)

	last_target = target

	current_target = null
	ui_text.visible = false

	# SEAT INTERACTION
	if target and target.name == "Seat":
		current_target = target
		ui_text.visible = true

		if Input.is_action_just_pressed("interact"):
			start_sit(target)

	# GRAVITY
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0

	# MOVEMENT
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var is_moving := direction.length() > 0.1
	var move_speed = WALK_SPEED if not is_crouching else CROUCH_SPEED

	if is_moving:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	# CAMERA BOB / CROUCH
	var target_y = base_cam_y

	if is_crouching:
		target_y -= crouch_offset
	else:
		if is_on_floor() and is_moving:
			bob_time += delta * bob_speed
			target_y += sin(bob_time) * bob_amount

	camera.position.y = lerp(camera.position.y, target_y, crouch_speed * delta)

	# TILT
	var target_roll = 0.0

	if is_crouching and is_moving:
		tilt_time += delta * 2.5
		target_roll = sin(tilt_time) * crouch_tilt
	else:
		tilt_time = lerp(tilt_time, 0.0, 5.0 * delta)

	camera.rotation.z = lerp(camera.rotation.z, target_roll, crouch_tilt_speed * delta)

	move_and_slide()
