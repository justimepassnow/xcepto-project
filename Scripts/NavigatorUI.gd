extends Control

@onready var snd_missile = $SndMissile
@onready var snd_asteroid = $SndAsteroid

func play_hazard(hazard_type: String, direction: String):
	# Hackathon trick for quick audio panning: 
	# Panning in Godot 4 UI is tricky without 2D nodes, so we use a simple pitch/volume trick 
	# or rely on pre-panned audio files your Director (Member 3) provides.
	
	if hazard_type == "Missile":
		snd_missile.play()
	elif hazard_type == "Asteroid":
		snd_asteroid.play()
