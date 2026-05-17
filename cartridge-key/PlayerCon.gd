extends CharacterBody3D

# ── SPEEDS ──────────────────────────────────────────────────────────────────
const WALK_SPEED   = 2.5
const SPRINT_SPEED = 5.0
const CROUCH_SPEED = 1.1
const GRAVITY      = 9.8

# ── MOUSE ───────────────────────────────────────────────────────────────────
var mouse_sensitivity := 0.002

# ── CAMERA BOB ──────────────────────────────────────────────────────────────
var bob_time   := 0.0
var bob_speed  := 8.0
var bob_amount := 0.05
var base_cam_y := 0.0

# ── CROUCH ──────────────────────────────────────────────────────────────────
const CROUCH_OFFSET = 0.6
const CROUCH_LERP   = 5.0
var is_crouching := false

# ── STAMINA ─────────────────────────────────────────────────────────────────
const STAMINA_MAX         = 100.0
const STAMINA_DRAIN_RATE  = 20.0
const STAMINA_REFILL_RATE = 15.0
const FROST_FILL_RATE     =  4.0

var stamina_current : float = STAMINA_MAX
var frost_current   : float = 0.0
var is_sprinting    := false

# ── INTERACTION ──────────────────────────────────────────────────────────────
var last_target = null

# ── LOCK ─────────────────────────────────────────────────────────────────────
var locked := false

# ── NODES ────────────────────────────────────────────────────────────────────
@onready var camera : Camera3D = $Camera3D
@onready var ray    : RayCast3D = $RayCast3D

@onready var stamina_bar = get_parent().get_node_or_null("CanvasLayer/HUD/StaminaBar")
@onready var frost_bar   = get_parent().get_node_or_null("CanvasLayer/HUD/FrostBar")


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_cam_y = camera.position.y
	add_to_group("player")


# ── INPUT ────────────────────────────────────────────────────────────────────
func _input(event):
	if locked:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))


# ── MAIN LOOP ────────────────────────────────────────────────────────────────
func _physics_process(delta):
	if locked:
		return
	_handle_gravity(delta)
	_handle_stamina(delta)
	_handle_movement(delta)
	_handle_camera_bob(delta)
	_update_hud()
	_handle_interaction()
	move_and_slide()


# ── GRAVITY ──────────────────────────────────────────────────────────────────
func _handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0


# ── STAMINA & FROST ───────────────────────────────────────────────────────────
func _handle_stamina(delta):
	is_crouching = Input.is_action_pressed("crouch")

	var usable = _usable_stamina()
	var wants_sprint = Input.is_action_pressed("sprint") and _is_moving() and not is_crouching

	if wants_sprint and usable > 0.0:
		is_sprinting = true
		stamina_current -= STAMINA_DRAIN_RATE * delta
		stamina_current  = max(stamina_current, frost_current)
		frost_current   += FROST_FILL_RATE * delta
		frost_current    = min(frost_current, STAMINA_MAX)
	else:
		is_sprinting = false
		if stamina_current < STAMINA_MAX:
			stamina_current += STAMINA_REFILL_RATE * delta
			stamina_current  = min(stamina_current, STAMINA_MAX)


func _usable_stamina() -> float:
	return max(stamina_current - frost_current, 0.0)


# ── MOVEMENT ─────────────────────────────────────────────────────────────────
func _handle_movement(delta):
	var input_dir = Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var move_speed = SPRINT_SPEED if is_sprinting else (CROUCH_SPEED if is_crouching else WALK_SPEED)

	if direction.length() > 0.1:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)


func _is_moving() -> bool:
	return Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up").length() > 0.1


# ── CAMERA BOB ───────────────────────────────────────────────────────────────
func _handle_camera_bob(delta):
	var target_y = base_cam_y

	if is_crouching:
		target_y -= CROUCH_OFFSET
	elif is_on_floor() and _is_moving():
		var speed_mult = 1.4 if is_sprinting else 1.0
		bob_time += delta * bob_speed * speed_mult
		target_y += sin(bob_time) * bob_amount * speed_mult

	camera.position.y = lerp(camera.position.y, target_y, CROUCH_LERP * delta)


# ── INTERACTION ──────────────────────────────────────────────────────────────
func _handle_interaction():
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_transform.origin
	var to = from + -camera.global_transform.basis.z * 3.0

	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	var target = null
	if result:
		var obj = result.collider
		while obj:
			if obj.has_method("on_looked_at") or obj.has_method("interact"):
				target = obj
				break
			obj = obj.get_parent()

	if target != last_target:
		if last_target and last_target.has_method("on_looked_at"):
			last_target.on_looked_at(false)
		last_target = target

	if target:
		if target.has_method("on_looked_at"):
			target.on_looked_at(true)
		if Input.is_action_just_pressed("interact") and target.has_method("interact"):
			target.interact()


# ── HUD ───────────────────────────────────────────────────────────────────────
func _update_hud():
	if stamina_bar:
		stamina_bar.value = stamina_current
	if frost_bar:
		frost_bar.value   = frost_current
