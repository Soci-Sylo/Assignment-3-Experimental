extends Node3D
@onready var mesh: MeshInstance3D = $Radio2
@onready var music_player: AudioStreamPlayer3D = $Radio2/MusicPlayer
var nightmare_sound = preload("res://TrainAssets/Music/Nightmare.mp3")
var radio_interact_sound = preload("res://TrainAssets/SoundEffects/Radio Interact.mp3")
var radio_repeat_sound = preload("res://TrainAssets/SoundEffects/Radio Repeat.mp3")
var original_material: Material
var glow_material: Material
var tutorial_triggered := false
var train_ref: Node = null
var is_playing := false
var songs: Array = []
var current_song := -1

func _ready():
	if mesh:
		original_material = mesh.get_active_material(0)
	
	for i in range(1, 11):
		var song = load("res://TrainAssets/Music/Song %d.mp3" % i)
		if song:
			songs.append(song)
	
	if music_player:
		music_player.finished.connect(_on_song_finished)
	else:
		print("ERROR: MusicPlayer node not found!")

	await get_tree().create_timer(3.0).timeout
	music_player.stream = radio_repeat_sound
	music_player.play()

func on_looked_at(state: bool):
	if state:
		_enable_glow()
	else:
		_disable_glow()

func toggle():
	if not train_ref:
		return

	if not train_ref.game_started:
		if not tutorial_triggered:
			tutorial_triggered = true
			_disable_glow()
			music_player.stop()
			music_player.stream = radio_interact_sound
			music_player.play()
			train_ref.start_tutorial()
		return

	# Post tutorial — play interact sound then toggle music
	music_player.stop()
	music_player.stream = radio_interact_sound
	music_player.play()

	if is_playing:
		stop_music()
	else:
		await get_tree().create_timer(0.3).timeout
		play_random_song()

func play_random_song():
	if songs.is_empty():
		print("No songs loaded!")
		return
	
	if train_ref and train_ref.current_station >= 5:
		music_player.stream = nightmare_sound
		music_player.play()
		is_playing = true
		return
	
	var next_song := current_song
	while next_song == current_song and songs.size() > 1:
		next_song = randi() % songs.size()
	
	current_song = next_song
	music_player.stream = songs[current_song]
	music_player.play()
	is_playing = true
	print("Now playing: Song ", current_song + 1)

func stop_music():
	music_player.stop()
	is_playing = false

func _on_song_finished():
	if not train_ref or not train_ref.game_started:
		return
	if is_playing:
		play_random_song()

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


func play_nightmare():
	music_player.stream = nightmare_sound
	music_player.play()
	is_playing = true
