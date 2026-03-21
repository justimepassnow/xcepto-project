extends Control

signal gunner_fired(direction)

@onready var health_label = $HealthLabel
@onready var gun_pivot = $Turret/GunPivot
@onready var ship_body = $Turret/shipbody 
@onready var parallax_bg = $ParallaxBackground
@export var obstacle_scene: PackedScene

var rotation_step = deg_to_rad(10)
var min_angle = deg_to_rad(-45)
var max_angle = deg_to_rad(45)

func _ready():
	spawn_loop()
func _process(delta):
	# --- 1. INFINITE PARALLAX SCROLLING ---
	if is_instance_valid(parallax_bg):
		parallax_bg.scroll_offset.y += 100.0 * delta # 100.0 is your "Ship Speed"
	
func _input(event):
	# Left mouse button -> rotate left
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_pressed()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_on_right_pressed()

	# Space key -> fire
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			_on_fire_pressed()

func _on_left_pressed():
	gun_pivot.rotation -= rotation_step
	gun_pivot.rotation = max(gun_pivot.rotation, min_angle)
	emit_signal("gunner_fired", "left")

func _on_right_pressed():
	gun_pivot.rotation += rotation_step
	gun_pivot.rotation = min(gun_pivot.rotation, max_angle)
	emit_signal("gunner_fired", "right")

func _on_fire_pressed():
	emit_signal("gunner_fired", "fire")

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
		await get_tree().create_timer(2.0).timeout

func spawn_obstacle():
	if obstacle_scene == null:
		print("❌ obstacle_scene is not assigned")
		return

	var obs = obstacle_scene.instantiate()

	var screen_width = get_viewport_rect().size.x
	obs.position = Vector2(randi_range(50, int(screen_width - 50)), 50)

	obs.target_node = ship_body
	obs.scale = Vector2(3, 3)

	get_tree().root.add_child.call_deferred(obs)
