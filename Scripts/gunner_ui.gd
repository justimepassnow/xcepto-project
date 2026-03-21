extends Control

signal gunner_fired(direction)

@onready var health_label = $HealthLabel
@onready var gun_pivot = $Turret/GunPivot

# ✅ NEW: obstacle scene
@export var obstacle_scene: PackedScene

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

	# ✅ START SPAWNING
	spawn_loop()

# ✅ LEFT with limit
func _on_left_pressed():
	gun_pivot.rotation -= rotation_step
	gun_pivot.rotation = max(gun_pivot.rotation, min_angle)
	emit_signal("gunner_fired", "left")

# ✅ RIGHT with limit
func _on_right_pressed():
	gun_pivot.rotation += rotation_step
	gun_pivot.rotation = min(gun_pivot.rotation, max_angle)
	emit_signal("gunner_fired", "right")

# ✅ FIRE
func _on_fire_pressed():
	emit_signal("gunner_fired", "fire")

# ✅ Health UI
func update_health_ui(new_health: int):
	if health_label != null:
		health_label.text = "Ship Health: " + str(new_health) + "%"
		if new_health <= 30:
			health_label.add_theme_color_override("font_color", Color.RED)
		else:
			health_label.add_theme_color_override("font_color", Color.WHITE)

# =========================
# 🔥 SPAWNING SYSTEM
# =========================

func spawn_loop():
	while true:
		spawn_obstacle()
		await get_tree().create_timer(1.0).timeout
func spawn_obstacle():
	var obs = obstacle_scene.instantiate()

	# 👇 REPLACE position line with this
	var screen_width = get_viewport_rect().size.x
	obs.position = Vector2(randi_range(50, int(screen_width - 50)), 50)

	# 👇 ADD this line (for visibility test)
	obs.scale = Vector2(3, 3)

	# 👇 keep this
	get_tree().root.add_child.call_deferred(obs)
