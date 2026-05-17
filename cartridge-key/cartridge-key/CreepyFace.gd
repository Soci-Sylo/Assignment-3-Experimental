extends Sprite3D

@onready var creepy_face_audio: AudioStreamPlayer3D = $CreepyFaceAudio
var original_z := 0.95
var peeking := false
var has_been_seen := false
var horror2_sound = preload("res://TrainAssets/SoundEffects/Horror 2.mp3")

func on_looked_at(state: bool):
	if not peeking:
		return
	if has_been_seen:
		return
	if state:
		dive_away()

func peek():
	if has_been_seen:
		return
	peeking = true
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "position:z", 0.111, 1.5)

func dive_away():
	peeking = false
	has_been_seen = true
	creepy_face_audio.stream = horror2_sound
	creepy_face_audio.play()
	var t = create_tween()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "position:z", original_z, 0.3)

func reset_silent():
	peeking = false
	has_been_seen = true
	var t = create_tween()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "position:z", original_z, 0.3)
