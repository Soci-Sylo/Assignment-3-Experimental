extends Node3D

@onready var mesh: MeshInstance3D = $LeverShaft

var original_material: Material
var glow_material: Material
var is_locked := false
var original_rotation_x := 0.0
var is_up := false


func _ready():
	if mesh:
		original_material = mesh.get_active_material(0)
	original_rotation_x = rotation.x


func on_looked_at(state: bool):
	if is_locked:
		return
	if state:
		_enable_glow()
	else:
		_disable_glow()


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


func toggle():
	if is_locked:
		return
	is_up = !is_up
	_disable_glow()
	is_locked = true
	var t = create_tween()
	if is_up:
		t.tween_property(self, "rotation:x", deg_to_rad(-20), 0.3)
	else:
		t.tween_property(self, "rotation:x", original_rotation_x, 0.3)


func lock():
	is_locked = true
	_disable_glow()


func unlock():
	is_locked = false


func reset():
	is_locked = false
	is_up = false
	_disable_glow()
	var t = create_tween()
	t.tween_property(self, "rotation:x", original_rotation_x, 0.3)
