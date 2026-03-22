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
var scroll_speed = 150.0 # Speed of the "ship" moving forward

# var sfx_missile = preload("res://assets/sounds/missileincoming.wav")
var sfx_asteroid = preload("res://assets/sounds/astroids.wav")
var sfx_ship_hit = preload("res://assets/sounds/ship hit.wav")

# var active_missile = null
var active_asteroid = null
var last_known_health = 100 # To track if health went up or down

func _ready():
	# Solo test mode remains for your local F6 testing
	if get_parent() == get_tree().root:
		var test_timer = Timer.new()
		test_timer.wait_time = 4.0 # Spawns slower so you can track them
		test_timer.autostart = true
		test_timer.timeout.connect(_on_test_timer_fired)
		add_child(test_timer)

func _on_test_timer_fired():
	# play_hazard(["Asteroid", "Missile"].pick_random(), ["Left", "Right"].pick_random())
	play_hazard("Asteroid", ["Left", "Right"].pick_random())

func _process(delta):
	# --- 1. INFINITE PARALLAX SCROLLING ---
	if is_instance_valid(parallax_bg):
		parallax_bg.scroll_offset.y += 100.0 * delta # 100.0 is your "Ship Speed"
	
	# --- 2. DODGING (A/D or Arrows) ---
	var move_dir = Input.get_axis("ui_left", "ui_right")
	radar_center.position.x += move_dir * SHIP_SPEED * delta
	radar_center.position.x = clamp(radar_center.position.x, 100, 1052)
	
	# --- 3. MOVE HAZARDS ---
	# if active_missile != null:
	# 	_move_and_check_collision(active_missile, delta, 25)

	if active_asteroid != null:
		_move_and_check_collision(active_asteroid, delta, 15)
		
	# Redraw the radar UI lines and ship every frame
	queue_redraw()

func _move_and_check_collision(hazard: Dictionary, delta: float, damage: int):
	if not is_instance_valid(hazard.visual) or not is_instance_valid(hazard.audio):
		return
		
	# 1. MOVEMENT LOGIC
	# if hazard.type == "Missile":
	# 	# RELENTLESS HOMING: Always aim for the current ship position
	# 	var target_pos = radar_center.position - Vector2(0, 15)
	# 	var current_speed = hazard.velocity.length()
	# 	hazard.velocity = (target_pos - hazard.visual.position).normalized() * current_speed
	# 	hazard.visual.rotation = hazard.velocity.angle() + (PI / 2.0)
	# elif hazard.type == "Asteroid" and is_instance_valid(hazard.visual):
	if hazard.type == "Asteroid" and is_instance_valid(hazard.visual):
		# DUMB ROCK: Keep original velocity, just spin
		hazard.visual.rotation += 2.0 * delta 
		
	hazard.visual.position += hazard.velocity * delta
	hazard.audio.position += hazard.velocity * delta
	
	# 2. COLLISION CHECK (THE SHIP)
	var current_dist = hazard.visual.position.distance_to(radar_center.position)
	if current_dist < COLLISION_RADIUS:
		_take_damage(damage)
		_cleanup_hazard(hazard.type)
		return
		
	# 3. DODGE LINE CHECK (ASTEROIDS ONLY)
	if hazard.type == "Asteroid":
		# Line is physically relative to the ship's Y position
		var invisible_line_y = radar_center.position.y + 80.0
		if hazard.visual.position.y > invisible_line_y:
			print("SAFE: Asteroid passed ship line.")
			_cleanup_hazard(hazard.type)
	
	# 4. MISSILE FAIL-SAFE (Only if it flies thousands of pixels away)
	# if hazard.type == "Missile":
	# 	if hazard.visual.position.distance_to(radar_center.position) > 2500.0:
	# 		_cleanup_hazard(hazard.type)

# --- CLEANUP & DAMAGE ---
func _cleanup_hazard(type: String):
	# if type == "Missile" and active_missile != null:
	# 	if is_instance_valid(active_missile.visual): active_missile.visual.queue_free()
	# 	if is_instance_valid(active_missile.audio): active_missile.audio.queue_free()
	# 	active_missile = null
	# elif type == "Asteroid" and active_asteroid != null:
	if type == "Asteroid" and active_asteroid != null:
		if is_instance_valid(active_asteroid.visual): active_asteroid.visual.queue_free()
		if is_instance_valid(active_asteroid.audio): active_asteroid.audio.queue_free()
		active_asteroid = null

func _take_damage(amount: int):
	print("💥 ASTEROID HIT THE SHIP! Deducting ", amount, " health.")
	
	# 1. FORCE THE UI TO UPDATE LOCALLY IMMEDIATELY
	last_known_health -= amount
	last_known_health = max(last_known_health, 0) # Prevent negative numbers
	update_health_ui(last_known_health)

	# 2. PLAY SOUND
	var hit_player = AudioStreamPlayer.new()
	hit_player.stream = sfx_ship_hit
	add_child(hit_player)
	hit_player.play()
	hit_player.finished.connect(func(): hit_player.queue_free())

	# 3. NOTIFY SERVER (Keep this for your multiplayer logic)
	if get_parent().has_method("apply_damage"):
		get_parent().apply_damage.rpc_id(1, amount)
	
	# 4. VISUAL FLASH
	var flash = ColorRect.new()
	flash.set_anchors_preset(PRESET_FULL_RECT)
	flash.color = Color(1, 0, 0, 0.4) 
	add_child(flash)
	get_tree().create_timer(0.2).timeout.connect(func(): 
		if is_instance_valid(flash): flash.queue_free()
	)
# --- THE UI DRAWING ---
func _draw():
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

# --- HAZARD SPAWNING ---
func play_hazard(hazard_type: String, direction: String):
	# if hazard_type == "Missile" and active_missile != null: return
	if hazard_type == "Asteroid" and active_asteroid != null: return

	var spawn_angle_deg = randf_range(FOV_MIN, -95.0) if direction == "Left" else randf_range(-85.0, FOV_MAX)
	var distance = randf_range(400.0, RADAR_RANGE)
	var rads = deg_to_rad(spawn_angle_deg)
	var spawn_pos = radar_center.position + Vector2(cos(rads) * distance, sin(rads) * distance)
	
	# var speed = 130.0 if hazard_type == "Missile" else 80.0 
	var speed = 80.0
	var vel = (radar_center.position - spawn_pos).normalized() * speed
	
	# --- VISUAL SETUP ---
	var vis = ColorRect.new()
	# if hazard_type == "Missile":
	# 	vis.size = Vector2(4, 20)
	# 	vis.position = spawn_pos - Vector2(2, 10)
	# 	vis.color = Color(1.0, 0.2, 0.2)
	# 	vis.pivot_offset = Vector2(2, 10) 
	# else:
	vis.size = Vector2(20, 20)
	vis.position = spawn_pos - Vector2(10, 10)
	vis.color = Color(1.0, 0.6, 0.1)
	vis.pivot_offset = Vector2(10, 10)
	add_child(vis)
	
	# --- DIRECTIONAL AUDIO SETUP ---
	var aud = AudioStreamPlayer2D.new()
	aud.position = spawn_pos
	# aud.stream = sfx_missile if hazard_type == "Missile" else sfx_asteroid
	aud.stream = sfx_asteroid
	
	# These 3 settings make it "Blind-Playable":
	aud.max_distance = 1200.0    # Can hear it from far away
	aud.panning_strength = 4.0   # EXTRA STRONG: Distinct Left vs Right separation
	aud.attenuation = 2.5        # Sound gets much louder as it hits the ship
	
	add_child(aud)
	aud.play()
	
	var hazard_data = {"type": hazard_type, "visual": vis, "audio": aud, "velocity": vel}
	# if hazard_type == "Missile": active_missile = hazard_data
	# else: active_asteroid = hazard_data
	active_asteroid = hazard_data
	
func update_health_ui(new_health: int):
	# 1. Update the Text Label
	if health_label != null:
		health_label.text = "Ship Health: " + str(new_health) + "%"
		health_label.add_theme_color_override("font_color", Color.RED if new_health <= 30 else Color.WHITE)

	# 2. Determine the Voice Message
	var msg = ""
	
	if new_health <= 0:
		msg = "Ship destroyed. Game over."
	
	elif new_health > last_known_health:
		# The Mechanic repaired the ship!
		msg = "Mechanic repaired ship. Health " + str(new_health) + " percent."
	
	elif new_health <= 30:
		# Danger zone!
		msg = "Critical damage! Ship health " + str(new_health) + " percent."
	
	else:
		# Standard hit
		msg = "Ship has been hit. Current integrity " + str(new_health) + " percent."

	# 3. Speak the message
	DisplayServer.tts_stop()
	var voices = DisplayServer.tts_get_voices_for_language("en")
	var voice_id = voices[0] if voices.size() > 0 else ""
	DisplayServer.tts_speak(msg, voice_id)

	# 4. Save the current health for the next comparison
	last_known_health = new_health

# func gunner_destroyed_target(hazard_type: String):
# 	_cleanup_hazard(hazard_type)
