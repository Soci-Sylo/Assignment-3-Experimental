extends SpotLight3D

func _ready():
	set_red()

func set_red():
	light_color = Color(1, 0, 0)

func set_green():
	light_color = Color(0, 1, 0)

func set_yellow():
	light_color = Color(1, 0.8, 0)
