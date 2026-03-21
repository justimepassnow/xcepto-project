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
@onready var health_label = $HealthLabel

# The NetworkManager will automatically find this and run it!
func update_health_ui(new_health: int):
	if health_label != null:
		health_label.text = "Ship Health: " + str(new_health) + "%"
		
		if new_health <= 30:
			health_label.add_theme_color_override("font_color", Color.RED)
		else:
			health_label.add_theme_color_override("font_color", Color.WHITE)
