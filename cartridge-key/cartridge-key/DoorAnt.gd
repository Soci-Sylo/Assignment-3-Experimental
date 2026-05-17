extends StaticBody3D

# ─────────────────────────
# NODE REFERENCES
# ─────────────────────────
@onready var mesh : MeshInstance3D = get_parent() as MeshInstance3D

# ─────────────────────────
# DOOR STATE
# ─────────────────────────
var is_open      := false
var is_animating := false

const OPEN_ROTATION  = -158.7
const CLOSE_ROTATION = 0.0
const DOOR_SPEED     = 1.5

# ─────────────────────────
# GLOW
# ─────────────────────────
var original_material : Material = null
var glow_material     : Material = null


func _ready():
	if mesh == null:
		return
	original_material = mesh.material_override

func _enable_glow():
	if mesh == null:
		return
	if glow_material == null:
		if original_material == null:
			return
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


# ─────────────────────────
# CALLED BY PLAYER RAYCAST
# ─────────────────────────
func on_looked_at(is_looking: bool):
	if is_animating:
		return
	if is_looking:
		_enable_glow()
	else:
		_disable_glow()


# ─────────────────────────
# CALLED BY PLAYER ON E
# ─────────────────────────
func interact():
	if is_animating:
		return

	is_animating = true
	_disable_glow()

	var target_rot = OPEN_ROTATION if not is_open else CLOSE_ROTATION

	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(mesh, "rotation_degrees:z", target_rot, DOOR_SPEED)
	t.tween_callback(func():
		is_open = not is_open
		is_animating = false
	)
