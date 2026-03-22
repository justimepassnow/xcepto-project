extends Node2D

@onready var gun_pivot = $GunPivot
@onready var muzzle = $GunPivot/Muzzile
@onready var fire_sfx = $GunPivot/Muzzile/FireSFX
var bullet_scene = preload("res://scenes/bullet.tscn")

var rotation_step = deg_to_rad(10)
var min_angle = deg_to_rad(-45)
var max_angle = deg_to_rad(45)

func _ready():
	var ui = get_tree().get_root().find_child("GunnerUi", true, false)
	gun_pivot.rotation = 0
	if ui:
		ui.connect("gunner_fired", _on_gunner_fired)

func _on_gunner_fired(direction):
	match direction:
		"left":
			_rotate_left()
		"right":
			_rotate_right()
		"fire":
			_fire()

func _rotate_left():
	gun_pivot.rotation -= rotation_step
	gun_pivot.rotation = clamp(gun_pivot.rotation, min_angle, max_angle)

func _rotate_right():
	gun_pivot.rotation += rotation_step
	gun_pivot.rotation = clamp(gun_pivot.rotation, min_angle, max_angle)
func _fire():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = gun_pivot.global_rotation
	get_tree().current_scene.add_child(bullet)
	if is_instance_valid(fire_sfx):
		# We use play(0) to ensure it starts from the beginning every time
		fire_sfx.play() 
		
		# Pro Tip: Slightly randomize the pitch so it doesn't sound repetitive
		fire_sfx.pitch_scale = randf_range(0.9, 1.1)
