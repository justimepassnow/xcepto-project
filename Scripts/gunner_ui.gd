extends Control

signal gunner_fired(direction)

func _ready():
	var left = $HBoxContainer/"Button(left)"
	var fire = $HBoxContainer/"Button(fire)"
	var right = $HBoxContainer/"Button(right)"

	left.pressed.connect(_on_left_pressed)
	fire.pressed.connect(_on_fire_pressed)
	right.pressed.connect(_on_right_pressed)

func _on_left_pressed():
	print("LEFT")
	emit_signal("gunner_fired", "left")

func _on_fire_pressed():
	print("FIRE")
	emit_signal("gunner_fired", "fire")

func _on_right_pressed():
	print("RIGHT")
	emit_signal("gunner_fired", "right")
