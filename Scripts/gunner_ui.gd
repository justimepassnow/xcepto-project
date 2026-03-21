extends Control

signal gunner_fired(direction)

@onready var health_label = $HealthLabel
@onready var gun_pivot = $Turret/GunPivot

var rotation_step = deg_to_rad(10)

# ✅ LIMITS
var min_angle = deg_to_rad(-45)
var max_angle = deg_to_rad(45)

func _ready():
	var left = $HBoxContainer/"Button(left)"
	var fire = $HBoxContainer/"Button(fire)"
	var right = $HBoxContainer/"Button(right)"

	left.pressed.connect(_on_left_pressed)
	fire.pressed.connect(_on_fire_pressed)
	right.pressed.connect(_on_right_pressed)

# ✅ LEFT with limit
func _on_left_pressed():
	gun_pivot.rotation -= rotation_step
	
	# Clamp to min limit
	gun_pivot.rotation = max(gun_pivot.rotation, min_angle)
	
	emit_signal("gunner_fired", "left")

# ✅ RIGHT with limit
func _on_right_pressed():
	gun_pivot.rotation += rotation_step
	
	# Clamp to max limit
	gun_pivot.rotation = min(gun_pivot.rotation, max_angle)
	
	emit_signal("gunner_fired", "right")

# ✅ FIRE
func _on_fire_pressed():
	emit_signal("gunner_fired", "fire")

# Health UI
func update_health_ui(new_health: int):
	if health_label != null:
		health_label.text = "Ship Health: " + str(new_health) + "%"
		
		if new_health <= 30:
			health_label.add_theme_color_override("font_color", Color.RED)
		else:
			health_label.add_theme_color_override("font_color", Color.WHITE)
