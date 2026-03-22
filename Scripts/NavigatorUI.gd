extends Control

# --- RADAR & GAME SETTINGS ---
const FOV_MIN = -140.0 
const FOV_MAX = -40.0  
const RADAR_RANGE = 500.0
const COLLISION_RADIUS = 40.0 
const SHIP_SPEED = 250.0 

@onready var radar_center = $RadarCenter
@onready var health_label = $HealthLabel
@onready var parallax_bg = $ParallaxBackground

var sfx_asteroid = preload("res://assets/sounds/astroids.wav")
var sfx_ship_hit = preload("res://assets/sounds/ship hit.wav")

var active_hazards = [] # The master list of all incoming threats
var last_known_health = 100 
var can_take_damage = true # Invincibility gatekeeper

func _ready():
	# Solo test mode
	if get_parent() == get_tree().root:
		var test_timer = Timer.new()
		test_timer.wait_time = 4.0 
		test_timer.autostart = true
		test_timer.timeout.connect(_on_test_timer_fired)
		add_child(test_timer)

func _on_test_timer_fired():
	play_hazard("Asteroid", ["Left", "Right"].pick_random())

func _process(delta):
	# 1. Background Scroll
	if is_instance_valid(parallax_bg):
		parallax_bg.scroll_offset.y += 100.0 * delta 
	
	# 2. Ship Movement
	var move_dir = Input.get_axis("ui_left", "ui_right")
	radar_center.position.x += move_dir * SHIP_SPEED * delta
	radar_center.position.x = clamp(radar_center.position.x, 100, 1052)
	
	# 3. Process All Hazards (Loop backwards to allow safe removal)
	for i in range(active_hazards.size() - 1, -1, -1):
		var hazard = active_hazards[i]
		_move_and_check_collision(hazard, delta, 15, i)
		
	queue_redraw()

func _move_and_check_collision(hazard: Dictionary, delta: float, damage: int, index: int):
	if not is_instance_valid(hazard.visual):
		active_hazards.remove_at(index)
		return
		
	# Update Position & Rotation
	hazard.visual.rotation += 2.0 * delta 
	hazard.visual.position += hazard.velocity * delta
	
	if is_instance_valid(hazard.audio):
		hazard.audio.position += hazard.velocity * delta
	
	# Collision logic
	var current_dist = hazard.visual.position.distance_to(radar_center.position)
	if current_dist < COLLISION_RADIUS:
		_take_damage(damage)
		_remove_hazard_at(index)
		return

	# Out of bounds logic
	if hazard.visual.position.y > radar_center.position.y + 120.0:
		_remove_hazard_at(index)

func _remove_hazard_at(index: int):
	var h = active_hazards[index]
	if is_instance_valid(h.visual): h.visual.queue_free()
	if is_instance_valid(h.audio): h.audio.queue_free()
	active_hazards.remove_at(index)

func _take_damage(amount: int):
	if not can_take_damage: return
	
	can_take_damage = false
	get_tree().create_timer(0.5).timeout.connect(func(): can_take_damage = true)

	print("💥 ASTEROID HIT THE SHIP! Deducting ", amount, " health.")
	
	# Local UI Sync
	last_known_health -= amount
	last_known_health = max(last_known_health, 0)
	update_health_ui(last_known_health)

	# Sound & Visuals
	var hit_player = AudioStreamPlayer.new()
	hit_player.stream = sfx_ship_hit
	add_child(hit_player)
	hit_player.play()
	hit_player.finished.connect(func(): hit_player.queue_free())

	var flash = ColorRect.new()
	flash.set_anchors_preset(PRESET_FULL_RECT)
	flash.color = Color(1, 0, 0, 0.4) 
	add_child(flash)
	get_tree().create_timer(0.2).timeout.connect(func(): if is_instance_valid(flash): flash.queue_free())

	# Server Sync
	if get_parent().has_method("apply_damage"):
		get_parent().apply_damage.rpc_id(1, amount)

func _draw():
	# (Your existing drawing code is perfect as is)
	var center = radar_center.position
	var fov_min_rad = deg_to_rad(FOV_MIN)
	var fov_max_rad = deg_to_rad(FOV_MAX)
	var neon_green = Color(0.1, 0.9, 0.4, 0.7)
	var faint_green = Color(0.1, 0.9, 0.4, 0.15)
	var ghost_green = Color(0.1, 0.9, 0.4, 0.04) 
	var danger_red = Color(1.0, 0.2, 0.2, 0.5)
	var bg_hue = Color(0.0, 0.1, 0.05, 0.4)
	
	for r in range(100, 2000, 100): 
		draw_arc(center, r, 0, TAU, 64, ghost_green, 1.0)
	for angle in range(-180, 180, 15): 
		var rads = deg_to_rad(angle)
		var end = center + Vector2(cos(rads) * 2000, sin(rads) * 2000)
		draw_line(center, end, ghost_green, 1.0)
	for angle in range(int(FOV_MIN), int(FOV_MAX) + 1, 1):
		var r = deg_to_rad(angle)
		var end = center + Vector2(cos(r) * RADAR_RANGE, sin(r) * RADAR_RANGE)
		draw_line(center, end, bg_hue, 3.0)
	draw_arc(center, COLLISION_RADIUS, fov_min_rad, fov_max_rad, 32, danger_red, 3.0) 
	draw_circle(center, COLLISION_RADIUS, Color(1, 0, 0, 0.1)) 
	for r in range(100, int(RADAR_RANGE) + 1, 100):
		var color = neon_green if r == int(RADAR_RANGE) else faint_green
		draw_arc(center, r, fov_min_rad, fov_max_rad, 64, color, 2.0)
	var left_end = center + Vector2(cos(fov_min_rad) * RADAR_RANGE, sin(fov_min_rad) * RADAR_RANGE)
	var right_end = center + Vector2(cos(fov_max_rad) * RADAR_RANGE, sin(fov_max_rad) * RADAR_RANGE)
	draw_line(center, left_end, neon_green, 3.0)
	draw_line(center, right_end, neon_green, 3.0)
	var p_top = center + Vector2(0, -25)
	var p_left = center + Vector2(-15, 10)
	var p_inner = center + Vector2(0, 0)
	var p_right = center + Vector2(15, 10)
	draw_polygon(PackedVector2Array([p_top, p_left, p_inner, p_right]), PackedColorArray([neon_green]))

func play_hazard(hazard_type: String, direction: String):
	var spawn_angle_deg = randf_range(FOV_MIN, -95.0) if direction == "Left" else randf_range(-85.0, FOV_MAX)
	var distance = randf_range(400.0, RADAR_RANGE)
	var rads = deg_to_rad(spawn_angle_deg)
	var spawn_pos = radar_center.position + Vector2(cos(rads) * distance, sin(rads) * distance)
	
	var speed = 80.0
	var vel = (radar_center.position - spawn_pos).normalized() * speed
	
	var vis = ColorRect.new()
	vis.size = Vector2(20, 20)
	vis.position = spawn_pos - Vector2(10, 10)
	vis.color = Color(1.0, 0.6, 0.1)
	vis.pivot_offset = Vector2(10, 10)
	add_child(vis)
	
	var aud = AudioStreamPlayer2D.new()
	aud.position = spawn_pos
	aud.stream = sfx_asteroid
	aud.max_distance = 1200.0 
	aud.panning_strength = 4.0 
	aud.attenuation = 2.5 
	add_child(aud)
	aud.play()
	
	# THE FIX: Store the new hazard in the list
	var hazard_data = {"type": hazard_type, "visual": vis, "audio": aud, "velocity": vel}
	active_hazards.append(hazard_data)

func update_health_ui(new_health: int):
	if health_label != null:
		health_label.text = "Ship Health: " + str(new_health) + "%"
		health_label.add_theme_color_override("font_color", Color.RED if new_health <= 30 else Color.WHITE)

	var msg = ""
	if new_health <= 0: msg = "Ship destroyed. Game over."
	elif new_health > last_known_health: msg = "Mechanic repaired ship. Health " + str(new_health) + " percent."
	elif new_health <= 30: msg = "Critical damage! Ship health " + str(new_health) + " percent."
	else: msg = "Ship has been hit. Current integrity " + str(new_health) + " percent."

	DisplayServer.tts_stop()
	var voices = DisplayServer.tts_get_voices_for_language("en")
	var voice_id = voices[0] if voices.size() > 0 else ""
	DisplayServer.tts_speak(msg, voice_id)

	last_known_health = new_health
