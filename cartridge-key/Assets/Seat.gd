extends Node3D

@onready var mesh: MeshInstance3D = $Cube003

@export var slide_distance := 0.1
@export var slide_speed := 0.15

var original_material: Material
var glow_material: Material

func _ready():
	if mesh:
		original_material = mesh.get_active_material(0)

func on_looked_at(state: bool):   # ✅ THIS WAS MISSING
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
