extends MeshInstance3D

var screen_material: StandardMaterial3D
var is_on := false


func _ready():
	screen_material = get_active_material(0).duplicate()
	set_surface_override_material(0, screen_material)
	screen_material.albedo_color = Color(0, 0, 0)


func turn_on():
	if is_on:
		return
	is_on = true  # <-- was wrongly set to false
	var t = create_tween()
	t.tween_property(screen_material, "albedo_color", Color(1, 1, 1), 1.5)


func turn_off():
	if not is_on:
		return
	is_on = false
	var t = create_tween()
	t.tween_property(screen_material, "albedo_color", Color(0, 0, 0), 1.0)
