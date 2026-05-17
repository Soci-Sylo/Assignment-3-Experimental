extends Node3D
@onready var mesh: MeshInstance3D = $DoorButton
var original_material: Material
var glow_material: Material
var is_locked := true
var is_pressed := false
var press_timer := 0.0
var press_duration := 10.0
var lever_ref: Node = null
var train_ref: Node = null
var original_position: Vector3
var pressed_position: Vector3

func _ready():
	if mesh:
		original_material = mesh.material_override
		glow_material = null
	original_position = mesh.position
	pressed_position = original_position + Vector3(0, -0.03, 0)


func on_looked_at(state: bool):
	if is_locked or is_pressed:
		return
	if state:
		_enable_glow()
	else:
		_disable_glow()


func toggle():
	if is_locked or is_pressed:
		return
	print("door button pressed!")
	is_pressed = true
	press_timer = 0.0
	is_locked = true
	_disable_glow()

	if lever_ref:
		lever_ref.lock()
	if train_ref:
		train_ref.on_door_button_pressed()

	var t = create_tween()
	t.tween_property(mesh, "position", pressed_position, 0.15)


func _process(delta):
	if not is_pressed:
		return
	press_timer += delta
	if press_timer >= press_duration:
		is_pressed = false
		_release_button()


func _release_button():
	is_locked = true  # button stays locked after use, until next station
	var t = create_tween()
	t.tween_property(mesh, "position", original_position, 0.15)
	if lever_ref:
		lever_ref.unlock()
		print("lever unlocked — ready to depart")


func lock():
	is_locked = true
	is_pressed = false
	press_timer = 0.0
	_disable_glow()
	var t = create_tween()
	t.tween_property(mesh, "position", original_position, 0.15)


func unlock():
	is_locked = false


func _enable_glow():
	if mesh == null or original_material == null:
		return
	if glow_material == null:
		glow_material = original_material.duplicate()
		if glow_material is StandardMaterial3D:
			glow_material.emission_enabled = true
			glow_material.emission = Color(1, 1, 1)
			glow_material.emission_energy_multiplier = 3.0
	mesh.material_override = glow_material


func _disable_glow():
	if mesh == null:
		return
	mesh.material_override = original_material
	

