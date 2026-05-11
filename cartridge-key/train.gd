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
@onready var door_button = $"Door Button"
@onready var lever = $Lever

@onready var clock_label = $CanvasLayer/Clock
@onready var meter_display = $MeterDisplay

@onready var door_light = $"Door Button/ButtonLight"

@onready var fade_rect = $CanvasLayer2/ColorRect

@onready var radio = $Radio

@onready var station_events = $StationEvents

@onready var overhead = $Overhead

@onready var creepy_face = $Train/CreepyFace

@onready var sounds1: AudioStreamPlayer3D = $Sounds1
@onready var sounds2: AudioStreamPlayer3D = $Sounds2
@onready var sounds3: AudioStreamPlayer3D = $Sounds3
@onready var sounds4: AudioStreamPlayer3D = $Sounds4
@onready var sounds5: AudioStreamPlayer3D = $Sounds5
@onready var music_player: AudioStreamPlayer3D = $Radio/Radio2/MusicPlayer

@onready var tutorial_panel = $CanvasLayer2/TutorialPanel
@onready var tutorial_text = $CanvasLayer2/TutorialPanel/VBoxContainer/TutorialText
@onready var continue_label = $CanvasLayer2/TutorialPanel/VBoxContainer/ContinueLabel
@onready var choice_buttons = $CanvasLayer2/TutorialPanel/VBoxContainer/ChoiceButtons
@onready var yes_button = $CanvasLayer2/TutorialPanel/VBoxContainer/ChoiceButtons/YesButton
@onready var no_button = $CanvasLayer2/TutorialPanel/VBoxContainer/ChoiceButtons/NoButton

@onready var monster = $Train/Monster
@onready var audio_player = $AudioStreamPlayer
@onready var endings = $Endings
@onready var game_over = $Endings/GameOver
@onready var successful = $Endings/Successful
@onready var retry_button = $Endings/GameOver/Retry
@onready var exit_button = $Endings/GameOver/Exit
@onready var continue_button = $Endings/Successful/Continue



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
var door_button_pressed := false

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

var horror_tense = preload("res://TrainAssets/SoundEffects/HorrorTense.mp3")
var success_sound = preload("res://TrainAssets/SoundEffects/Success.mp3")
var ambience_sound = preload("res://TrainAssets/SoundEffects/Ambience.mp3")
var button_sound = preload("res://TrainAssets/SoundEffects/Button.mp3")
var horror1_sound = preload("res://TrainAssets/SoundEffects/Horror 1.mp3")
var horror3_sound = preload("res://TrainAssets/SoundEffects/Horror 3.mp3")
var metal_sound = preload("res://TrainAssets/SoundEffects/Metal.mp3")
var train_loop_sound = preload("res://TrainAssets/SoundEffects/TrainLoop.mp3")
var window_sound = preload("res://TrainAssets/SoundEffects/Window.mp3")
var train_arrive_sound = preload("res://TrainAssets/SoundEffects/TrainArrive.mp3")
var train_pass_sound = preload("res://TrainAssets/SoundEffects/TrainPass.mp3")

# LOOK TARGET
var last_target = null

var passengers: Array = []

# Hardcoded hidden passengers per station (by number)
var station_hidden := {
	1: [],
	2: [],
	3: [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32],
	4: [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 26, 28, 30, 32, 2, 4, 6, 8, 10, 12, 14, 16],
	5: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27],
	6: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]
}

# EventPassenger hidden lists per station
var event_hidden := {
	1: [],
	2: [],
	3: [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31],
	4: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24],
	5: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27],
	6: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]
}

# 4 speed groups for EventPassengers
var event_groups := {
	"A": {"passengers": [1,2,3,4,5,6,7,8], "duration": 6.0},
	"B": {"passengers": [9,10,11,12,13,14,15,16], "duration": 5.0},
	"C": {"passengers": [17,18,19,20,21,22,23,24], "duration": 4.0},
	"D": {"passengers": [25,26,27,28,29,30,31,32], "duration": 3.0}
}

var event_original_positions := {}

# ─────────────────────────
# READY
# ─────────────────────────
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_scene()
	game_started = false
	clock_label.text = "00:00"
	door_button.lever_ref = lever
	door_button.train_ref = self
	radio.train_ref = self
	lever.lock()

	fade_rect.color = Color(0, 0, 0, 1)
	var t = create_tween()
	t.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 2.0)

	sounds4.stream = ambience_sound
	sounds4.play()


func setup_scene():
	station.visible = false
	tunnel.visible = true
	tutorial_panel.visible = false
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

	for i in range(1, 33):
		var p = station.get_node_or_null("Passenger%d" % i)
		if p:
			passengers.append(p)


# ─────────────────────────
# PASSENGER VISIBILITY
# ─────────────────────────
func apply_passenger_visibility(station_num: int):
	for i in range(1, 33):
		var p = station.get_node_or_null("Passenger%d" % i)
		if p:
			p.visible = true

	if station_hidden.has(station_num):
		for num in station_hidden[station_num]:
			var p = station.get_node_or_null("Passenger%d" % num)
			if p:
				p.visible = false


func setup_event_passengers(station_num: int):
	if event_original_positions.is_empty():
		for i in range(1, 33):
			var p = station_events.get_node_or_null("EventPassenger%d" % i)
			if p:
				event_original_positions[i] = p.position

	for i in range(1, 33):
		var p = station_events.get_node_or_null("EventPassenger%d" % i)
		if p:
			p.position = event_original_positions[i]

	for i in range(1, 33):
		var p = station_events.get_node_or_null("EventPassenger%d" % i)
		if p:
			p.visible = true

	if event_hidden.has(station_num):
		for num in event_hidden[station_num]:
			var p = station_events.get_node_or_null("EventPassenger%d" % num)
			if p:
				p.visible = false

	var wp = station_events.get_node_or_null("WatchingPassenger")
	if wp:
		wp.visible = (station_num == 3)


func tween_event_passengers(station_num: int):
	if station_num == 6:
		return

	for group_name in event_groups:
		var group = event_groups[group_name]
		var duration = group["duration"]

		for num in group["passengers"]:
			if event_hidden.has(station_num) and num in event_hidden[station_num]:
				continue

			var p = station_events.get_node_or_null("EventPassenger%d" % num)
			if p and p.visible:
				var t = create_tween()
				t.set_ease(Tween.EASE_IN)
				t.set_trans(Tween.TRANS_CUBIC)
				t.tween_property(p, "position:z", -2.0, duration)


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
			if in_tutorial and tutorial_started:
				advance_tutorial()
				return
			var target = get_look_target()
			if target == lever:
				if not game_started:
					return
				if is_at_station:
					target.toggle()
					_depart_from_station()
				elif not throttle_engaged:
					target.toggle()
					engage_throttle()
				elif station_approach and not slowdown_engaged:
					target.toggle()
					slowdown_engaged = true
					print("Station checkpoint hit!")
			elif target == door_button:
				target.toggle()
			elif target == radio:
				target.toggle()


# ─────────────────────────
# DEPART FROM STATION
# ─────────────────────────
func _depart_from_station():
	if door_button.is_pressed:
		return
	if not door_button_pressed:
		deduct_points(500)
		print("Left without opening doors! -500")
	door_button.lock()
	door_light.set_red()
	start_travel()
	cctv_monitor.turn_off()


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
# STATION TRANSITION
# ─────────────────────────
func show_station(missed: bool):
	if not missed:
		apply_passenger_visibility(current_station + 1)
		setup_event_passengers(current_station + 1)
		sounds5.stream = train_arrive_sound
		sounds5.play()
	else:
		sounds5.stream = train_pass_sound
		sounds5.play()

	station.global_position = station_start_pos
	station.visible = true
	# ... rest stays the same
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
	throttle_engaged = false
	lever.reset()
	door_button.unlock()
	door_button_pressed = false
	current_station += 1
	_update_clock_to_station()
	resume_timer()
	print("Arrived at station: ", current_station)
	door_light.set_green()
	cctv_monitor.turn_on()
	sounds2.stop()
	tween_event_passengers(current_station)
	if current_station == 3:
		trigger_creepy_face()
	if current_station == 5:
		trigger_horror_face()
		creepy_face.reset_silent()
		radio.stop_music()
		radio.play_nightmare()
		overhead.light_color = Color(1, 0, 0)
	


func _on_station_missed_complete():
	tunnel.visible = true
	station.visible = false
	void_mesh.transparency = 0.0
	current_station += 1
	_update_clock_to_station()
	deduct_points(1000)
	print("Missed station! Now on station: ", current_station)
	if current_station == 3:
		trigger_creepy_face()
	if current_station == 5:
		radio.stop_music()
		radio.play_nightmare()
		overhead.light_color = Color(1, 0, 0)
	

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
	if current_station == 6:
		if score > 3000:
			trigger_good_ending()
		else:
			trigger_bad_ending()


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
	door_button.lock()
	resume_timer()
	sounds2.stream = train_loop_sound
	sounds2.play()
	engage_throttle()
	if current_station == 2:
		trigger_horror1()
	if current_station == 4:
		trigger_window_sound(5.0)
	if current_station == 5:
		trigger_window_sound(7.0)
		trigger_metal_sound()
	if current_station == 6:
		if score > 3000:
			trigger_good_ending()
		else:
			trigger_bad_ending()


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
# THROTTLE
# ─────────────────────────
func engage_throttle():
	if throttle_engaged:
		return
	throttle_engaged = true
	is_at_station = false
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
	sounds2.stream = train_loop_sound
	sounds2.play()


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


func on_door_button_pressed():
	door_button_pressed = true
	door_light.set_yellow()
	sounds1.stream = button_sound
	sounds1.play()


# ─────────────────────────
# STOP AT STATION (kept for reference)
# ─────────────────────────
func stop_at_station():
	station_pause_timer = 0.0
	door_timer = 0.0
	doors_open = false


# ─────────────────────────
# PHYSICS PROCESS
# ─────────────────────────
func _physics_process(delta):
	timer_tick(delta)
	scroll_tunnel(delta)
	distance_tick(delta)
	update_look_target()


# ─────────────────────────
# TUTORIAL
# ─────────────────────────
var tutorial_slides := [
	"Jeez, took you long enough... Aren't you the new guy? Or am I thinking of someone else? (Tutorial?)",
	"Surprised nobody taught you. Let's get started.",
	"A lot of the systems are automated luckily, so there's only two things you need to even look at.",
	"On your left, the Lever. Interacting (Left Mouse) toggles the lever up, sending the subway into action.",
	"When you're about 100 meters from a station, that big lever will unlock, allowing you to pull it back.",
	"Doing so will send the subway into an automatic arrival system, slowing down to reach the station. So try not to miss stations.",
	"Yeah we don't expect you to manually track your distance, so that small box will give your exact distance to the next station.",
	"On your right? That big button opens the doors to your subway, allowing passengers in.",
	"Obviously you have to let passengers in, so don't forget to.",
	"When it's red, the button is disabled. Green is good to press, and yellow just means you've pressed it and done a good job.",
	"Pressing the button disables the lever for 10 seconds, to let your passengers on. Then it becomes available again to drive off.",
	"Oh that big monitor? That connects to CCTV of the station, just so you can see your passengers when you arrive.",
	"Uh what else... oh right, make sure to reach each station within the hour. Gotta keep this schedule on 'track' haha... get it...?",
	"You don't care do you... Fine, see this speaker you used to speak to me? Interact with it again once I stop speaking to you.",
	"Speaking of which. That's about it. Pretty easy, right? Good luck out there."
]

var current_slide := 0
var in_tutorial := false
var tutorial_started := false


func start_tutorial():
	if in_tutorial:
		return
	in_tutorial = true
	tutorial_started = false
	current_slide = 0
	tutorial_panel.visible = true
	continue_label.text = "Left click to continue"
	choice_buttons.visible = true
	continue_label.visible = false
	tutorial_text.text = tutorial_slides[0]
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	lever.lock()
	door_button.lock()
	clock_paused = true

	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)


var just_chose := false

func _on_yes_pressed():
	choice_buttons.visible = false
	continue_label.visible = true
	current_slide = 1
	tutorial_text.text = tutorial_slides[current_slide]
	await get_tree().create_timer(0.2).timeout
	tutorial_started = true


func _on_no_pressed():
	_end_tutorial(false)


func advance_tutorial():
	if not in_tutorial:
		return
	if not tutorial_started:
		if just_chose:
			just_chose = false
			tutorial_started = true
		return

	current_slide += 1

	if current_slide >= tutorial_slides.size():
		_end_tutorial(true)
		return

	tutorial_text.text = tutorial_slides[current_slide]

	if current_slide == tutorial_slides.size() - 1:
		continue_label.text = "Left click to close communications"


func _end_tutorial(completed: bool):
	in_tutorial = false
	tutorial_panel.visible = false
	choice_buttons.visible = false
	game_started = true
	clock_paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	music_player.stop()
	lever.reset()
	door_button.lock()

	if completed:
		print("Tutorial completed!")
	else:
		print("Tutorial skipped!")


# ─────────────────────────
# HORROR EVENTS
# ─────────────────────────
func trigger_horror_face():
	var hf = station_events.get_node_or_null("HorrorFace")
	if not hf:
		return

	hf.position = Vector3(-19.997, 1.0, -7.875)
	hf.visible = true

	# Wait 6 seconds THEN play sound and slam up
	await get_tree().create_timer(6.0).timeout
	sounds3.stream = horror3_sound
	sounds3.play()

	var slam = create_tween()
	slam.set_trans(Tween.TRANS_LINEAR)
	slam.tween_property(hf, "position:y", 5.212, 0.2)
	await slam.finished

	var shake_time := 0.0
	while shake_time < 3.0:
		var rx = randf_range(-0.05, 0.05)
		var rz = randf_range(-0.05, 0.05)
		hf.position.x = -19.997 + rx
		hf.position.z = -7.875 + rz
		await get_tree().create_timer(0.05).timeout
		shake_time += 0.05

	cctv_monitor.turn_off()
	hf.visible = false


func trigger_creepy_face():
	await get_tree().create_timer(30.0).timeout
	if current_station == 3:
		creepy_face.peek()


func trigger_horror1():
	await get_tree().create_timer(15.0).timeout
	if current_station >= 2:
		sounds3.stream = horror1_sound
		sounds3.play()


func trigger_window_sound(delay: float):
	await get_tree().create_timer(delay).timeout
	sounds3.stream = window_sound
	sounds3.play()


func trigger_metal_sound():
	await get_tree().create_timer(12.0).timeout
	sounds3.stream = metal_sound
	sounds3.play()


# ─────────────────────────
# ENDINGS
# ─────────────────────────
func trigger_bad_ending():
	clock_label.visible = false
	meter_display.visible = false
	lever.lock()
	door_button.lock()
	sounds4.stop()
	sounds2.stop()
	radio.stop_music()
	radio.tutorial_triggered = true  # locks it so it can't be restarted
	music_player.stop()
	overhead.visible = false

	audio_player.stream = horror_tense
	audio_player.play()
	is_scrolling = true
	scroll_speed = target_scroll_speed
	await get_tree().create_timer(15.0).timeout

	monster.visible = true
	var t = create_tween()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_LINEAR)
	t.tween_property(monster, "position:z", -3.682, 0.5)
	await t.finished

	var shake_time := 0.0
	while shake_time < 1.0:
		camera.position.x = randf_range(-1.073, -	1.082)
		camera.position.y = randf_range(1.85, 1.95)
		await get_tree().create_timer(0.05).timeout
		shake_time += 0.05
	camera.position.x = -1.077
	camera.position.y = 1.9

	fade_rect.visible = true
	var fade = create_tween()
	fade.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
	await fade.finished

	endings.visible = true
	game_over.visible = true
	successful.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	retry_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://game_train.tscn")
	)
	exit_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://game_scene.tscn")
	)


func trigger_good_ending():
	clock_label.visible = false
	meter_display.visible = false
	lever.lock()
	door_button.lock()
	sounds4.stop()
	sounds2.stop()
	radio.stop_music()
	radio.tutorial_triggered = true  # locks it so it can't be restarted
	music_player.stop()
	overhead.visible = false

	audio_player.stream = horror_tense
	audio_player.play()
	is_scrolling = true
	scroll_speed = target_scroll_speed
	await get_tree().create_timer(15.0).timeout

	audio_player.stream = success_sound
	audio_player.play()

	fade_rect.visible = true
	var fade = create_tween()
	fade.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
	await fade.finished

	endings.visible = true
	successful.visible = true
	game_over.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	continue_button.pressed.connect(func():
		GameState.completed_games.append("train")
		get_tree().change_scene_to_file("res://game_scene.tscn")
)
