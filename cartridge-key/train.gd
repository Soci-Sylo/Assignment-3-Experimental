extends Node3D

# ─────────────────────────
# NODE REFERENCES
# ─────────────────────────
@onready var camera = $Camera3D

# Tunnel
@onready var tunnel = $Tunnel
@onready var tunnel_walls = $Tunnel/TunnelWalls
@onready var gravel_floor = $Tunnel/GravelFloor
@onready var rail1 = $Tunnel/Rail1
@onready var rail2 = $Tunnel/Rail2

# TunnelDark
@onready var tunnel_dark = $TunnelDark
@onready var void_mesh = $TunnelDark/Void

# Station
@onready var station = $Station
@onready var tunnel_triple = $Station/TunnelTriple
@onready var station2 = $Station/Station2

# Train
@onready var train = $Train

# Controls
@onready var cctv_monitor = $"CCTV monitor/CCTVmonitor"
@onready var display_box = $DistanceDisplayBox
@onready var door_button = $"Door Button/DoorButton"
@onready var lever = $Lever

@onready var clock_label = $CanvasLayer/Clock
@onready var meter_display = $MeterDisplay


# ─────────────────────────
# GAME STATE
# ─────────────────────────
var is_travelling := false
var is_at_station := false
var throttle_engaged := false
var slowdown_engaged := false
var doors_open := false
var tutorial_complete := false
var game_started := false
var station_missed := false

# SCORING
var score := 6000
var current_station := 0
var total_stations := 6

# TIMER
var clock_time := 0.0
var clock_paused := false
var station_pause_timer := 0.0
var door_timer := 0.0
var door_time_limit := 10.0

# DISTANCE
var distance_to_station := 500.0
var slowdown_threshold := 100.0
var station_approach := false
var distance_speed := 0.0
var target_distance_speed := 0.2

# TUNNEL SCROLL
var scroll_speed := 0.0
var target_scroll_speed := 1.5
var is_scrolling := false

# STATION SLIDE
var station_sliding := false
var station_start_pos := Vector3.ZERO
var station_stop_pos := Vector3.ZERO

# CAMERA LOOK
var cam_yaw := 0.0
var cam_pitch := 0.0
var cam_yaw_limit := deg_to_rad(90)
var cam_pitch_min := deg_to_rad(-40)
var cam_pitch_max := deg_to_rad(40)
var cam_sensitivity := 0.0008

# LOOK TARGET
var last_target = null


# ─────────────────────────
# READY
# ─────────────────────────
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_scene()
	start_tutorial()
	game_started = true
	clock_label.text = "00:00"


func setup_scene():
	station.visible = false
	tunnel.visible = true
	void_mesh.transparency = 0.0
	station_start_pos = station.global_position
	station_stop_pos = station_start_pos + Vector3(0, 0, 71.5)

	var mat_walls = tunnel_walls.get_active_material(0).duplicate()
	var mat_gravel = gravel_floor.get_active_material(0).duplicate()
	var mat_rail1 = rail1.get_active_material(0).duplicate()
	var mat_rail2 = rail2.get_active_material(0).duplicate()

	tunnel_walls.mesh = tunnel_walls.mesh.duplicate()
	gravel_floor.mesh = gravel_floor.mesh.duplicate()
	rail1.mesh = rail1.mesh.duplicate()
	rail2.mesh = rail2.mesh.duplicate()

	tunnel_walls.mesh.surface_set_material(0, mat_walls)
	gravel_floor.mesh.surface_set_material(0, mat_gravel)
	rail1.mesh.surface_set_material(0, mat_rail1)
	rail2.mesh.surface_set_material(0, mat_rail2)


# ─────────────────────────
# INPUT
# ─────────────────────────
func _input(event):
	if event is InputEventMouseMotion:
		cam_yaw -= event.relative.x * cam_sensitivity
		cam_yaw = clamp(cam_yaw, -cam_yaw_limit, cam_yaw_limit)
		cam_pitch -= event.relative.y * cam_sensitivity
		cam_pitch = clamp(cam_pitch, cam_pitch_min, cam_pitch_max)
		camera.rotation.y = cam_yaw
		camera.rotation.x = cam_pitch

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var target = get_look_target()
			if target and target.has_method("toggle"):
				if not throttle_engaged:
					target.toggle()
					engage_throttle()
				elif station_approach and not slowdown_engaged:
					target.toggle()
					slowdown_engaged = true
					print("Station checkpoint hit!")


# ─────────────────────────
# LOOK TARGET
# ─────────────────────────
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
			obj = obj.get_parent()

	return null


func update_look_target():
	var target = get_look_target()

	if last_target and last_target != target:
		if last_target.has_method("on_looked_at"):
			last_target.on_looked_at(false)

	last_target = target

	if target and target.has_method("on_looked_at"):
		target.on_looked_at(true)


# ─────────────────────────
# THROTTLE
# ─────────────────────────
func engage_throttle():
	if throttle_engaged:
		return
	throttle_engaged = true
	is_scrolling = true
	is_travelling = true
	station_approach = false
	station_missed = false

	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "scroll_speed", target_scroll_speed, 3.0)
	t.parallel().tween_property(self, "distance_speed", target_distance_speed, 3.0)

	resume_timer()


# ─────────────────────────
# STATION TRANSITION
# ─────────────────────────
func show_station(missed: bool):
	station.global_position = station_start_pos
	station.visible = true
	await get_tree().process_frame
	tunnel.visible = false

	var fade_time = 0.3 if missed else 1.5
	var t = create_tween()
	t.tween_property(void_mesh, "transparency", 1.0, fade_time)

	station_sliding = true
	var t2 = create_tween()

	if missed:
		t2.set_trans(Tween.TRANS_LINEAR)
		t2.tween_property(station, "global_position", station_stop_pos, 2.0)
	else:
		t2.set_ease(Tween.EASE_OUT)
		t2.set_trans(Tween.TRANS_CUBIC)
		t2.tween_property(station, "global_position", station_stop_pos, 8.0)

	t2.tween_callback(func():
		station_sliding = false
		if missed:
			_on_station_missed_complete()
		else:
			_on_station_reached()
	)


func _on_station_reached():
	tunnel.visible = true
	station.visible = false
	void_mesh.transparency = 0.0
	is_at_station = true
	pause_timer()
	lever.reset()
	stop_at_station()


func _on_station_missed_complete():
	tunnel.visible = true
	station.visible = false
	void_mesh.transparency = 0.0
	current_station += 1
	_update_clock_to_station()
	deduct_points(1000)
	print("Missed station! Now on station: ", current_station)
	_reset_for_next_station()


func _reset_for_next_station():
	is_travelling = true
	is_scrolling = true
	slowdown_engaged = false
	station_approach = false
	station_missed = false
	distance_to_station = 500.0
	scroll_speed = target_scroll_speed
	distance_speed = target_distance_speed
	lever.lock()
	resume_timer()


func start_travel():
	is_at_station = false
	is_travelling = true
	is_scrolling = true
	distance_to_station = 500.0
	station_approach = false
	throttle_engaged = false
	slowdown_engaged = false
	station_missed = false
	scroll_speed = 0.0
	distance_speed = 0.0
	lever.reset()
	resume_timer()


# ─────────────────────────
# TUNNEL SCROLL
# ─────────────────────────
func scroll_tunnel(delta):
	if not is_scrolling:
		return

	var mat_walls = tunnel_walls.get_active_material(0)
	var mat_gravel = gravel_floor.get_active_material(0)
	var mat_rail1 = rail1.get_active_material(0)
	var mat_rail2 = rail2.get_active_material(0)

	if mat_walls:
		mat_walls.uv1_offset.y += scroll_speed * delta
	if mat_gravel:
		mat_gravel.uv1_offset.x += scroll_speed * 0.2 * delta
	if mat_rail1:
		mat_rail1.uv1_offset.x -= scroll_speed * 0.3 * delta
	if mat_rail2:
		mat_rail2.uv1_offset.x -= scroll_speed * 0.3 * delta


# ─────────────────────────
# DISTANCE
# ─────────────────────────
func distance_tick(delta):
	if not is_travelling:
		return

	distance_to_station -= distance_speed * 100 * delta
	distance_to_station = max(distance_to_station, 0)
	meter_display.text = str(int(distance_to_station)) + "m"

	if distance_to_station <= slowdown_threshold and not station_approach:
		station_approach = true
		lever.unlock()
		print("100m — toggle lever!")

	if distance_to_station <= 0 and not station_sliding:
		is_travelling = false
		is_scrolling = false
		if slowdown_engaged:
			show_station(false)
		else:
			station_missed = true
			lever.lock()
			show_station(true)


# ─────────────────────────
# TIMER
# ─────────────────────────
func start_timer():
	clock_time = 0.0
	clock_paused = false


func pause_timer():
	clock_paused = true


func resume_timer():
	clock_paused = false


func _update_clock_to_station():
	clock_time = 0.0
	clock_paused = true
	clock_label.text = "%02d:00" % [current_station]


func timer_tick(delta):
	if clock_paused:
		return
	if not game_started:
		return

	clock_time += delta

	var display_minutes = int(clock_time)
	clock_label.text = "%02d:%02d" % [current_station, display_minutes]

	if clock_time >= 60.0:
		clock_time = 0.0
		clock_paused = true
		clock_label.text = "Failed to meet current time. Wait for next."
		deduct_points(500)


# ─────────────────────────
# SCORING
# ─────────────────────────
func add_points(amount: int):
	score += amount
	print("Score: ", score)


func deduct_points(amount: int):
	score -= amount
	print("Score: ", score)


# ─────────────────────────
# STOP AT STATION
# ─────────────────────────
func stop_at_station():
	station_pause_timer = 0.0
	door_timer = 0.0
	doors_open = false
	current_station += 1
	_update_clock_to_station()
	print("Arrived at station: ", current_station)
	start_travel()


# ─────────────────────────
# PHYSICS PROCESS
# ─────────────────────────
func _physics_process(delta):
	timer_tick(delta)
	scroll_tunnel(delta)
	distance_tick(delta)
	update_look_target()


# ─────────────────────────
# TUTORIAL STUB
# ─────────────────────────
func start_tutorial():
	pass
