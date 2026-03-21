extends Control

# --- RADAR & GAME SETTINGS ---
var sweep_angle = -90.0 
var sweep_direction = 1 
const FOV_MIN = -120.0 
const FOV_MAX = -60.0  
const RADAR_RANGE = 500.0
const COLLISION_RADIUS = 40.0 # The "Hit Zone" around the ship!

@onready var radar_center = $RadarCenter

var sfx_missile = preload("res://assets/sounds/missileincoming.wav")
var sfx_asteroid = preload("res://assets/sounds/astroids.wav")

# Enforce the "Only 1 of each" rule by storing them here
var active_missile = null
var active_asteroid = null

func _process(delta):
	# 1. Sweep the radar
	sweep_angle += 60.0 * sweep_direction * delta
	if sweep_angle > FOV_MAX:
		sweep_angle = FOV_MAX
		sweep_direction = -1
	elif sweep_angle < FOV_MIN:
		sweep_angle = FOV_MIN
		sweep_direction = 1
		
	# 2. MOVE THE HAZARDS AND CHECK COLLISIONS
	if active_missile != null:
		_move_and_check_collision(active_missile, delta, 25) # Missiles do 25 damage

	if active_asteroid != null:
		_move_and_check_collision(active_asteroid, delta, 15) # Asteroids do 15 damage
		
	queue_redraw()

# --- THE PHYSICS & COLLISION ENGINE ---
func _move_and_check_collision(hazard: Dictionary, delta: float, damage: int):
	if not is_instance_valid(hazard.visual) or not is_instance_valid(hazard.audio):
		return
		
	# Move the visual dot and the audio node toward the ship!
	hazard.visual.position += hazard.velocity * delta
	hazard.audio.position += hazard.velocity * delta
	
	# Check if it hit the collision zone
	var current_dist = hazard.visual.position.distance_to(radar_center.position - Vector2(8,8))
	
	if current_dist < COLLISION_RADIUS:
		# BOOM! It hit the ship.
		_take_damage(damage)
		_cleanup_hazard(hazard.type)

func _cleanup_hazard(type: String):
	if type == "Missile" and active_missile != null:
		if is_instance_valid(active_missile.visual): active_missile.visual.queue_free()
		if is_instance_valid(active_missile.audio): active_missile.audio.queue_free()
		active_missile = null
		
	elif type == "Asteroid" and active_asteroid != null:
		if is_instance_valid(active_asteroid.visual): active_asteroid.visual.queue_free()
		if is_instance_valid(active_asteroid.audio): active_asteroid.audio.queue_free()
		active_asteroid = null

# --- THE NETWORK UPDATE ---
func _take_damage(amount: int):
	print("CRASH! Sending damage report to Server...")
	
	# Fire the RPC to the Host (ID 1) to update the global health!
	get_parent().apply_damage.rpc_id(1, amount)
	
	# HACKATHON POLISH: Flash the screen red when you take damage!
	var flash = ColorRect.new()
	flash.set_anchors_preset(PRESET_FULL_RECT)
	flash.color = Color(1, 0, 0, 0.4) # Transparent red
	add_child(flash)
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(flash): flash.queue_free()

# --- DRAWING THE SCREEN ---
func _draw():
	var center = radar_center.position
	
	# Draw the faint red Collision Zone so you can see where it hits
	draw_circle(center, COLLISION_RADIUS, Color(1, 0, 0, 0.2)) 
	# Draw the Ship
	draw_circle(center, 15.0, Color.GREEN) 
	
	# Draw the Radar Sweep
	var sweep_rads = deg_to_rad(sweep_angle)
	var end_point = center + Vector2(cos(sweep_rads) * RADAR_RANGE, sin(sweep_rads) * RADAR_RANGE)
	draw_line(center, end_point, Color(0, 1, 0, 0.8), 3.0) 

# --- SPAWNING LOGIC ---
func play_hazard(hazard_type: String, direction: String):
	# Instantly delete the old one if it exists
	_cleanup_hazard(hazard_type)

	var spawn_angle_deg = randf_range(FOV_MIN, -95.0) if direction == "Left" else randf_range(-85.0, FOV_MAX)
	var distance = randf_range(350.0, RADAR_RANGE)
	var rads = deg_to_rad(spawn_angle_deg)
	var spawn_pos = radar_center.position + Vector2(cos(rads) * distance, sin(rads) * distance)
	
	var vis = ColorRect.new()
	vis.size = Vector2(16, 16)
	vis.position = spawn_pos - Vector2(8, 8)
	vis.color = Color.RED if hazard_type == "Missile" else Color.ORANGE
	add_child(vis)
	
	var aud = AudioStreamPlayer2D.new()
	aud.position = spawn_pos
	aud.stream = sfx_missile if hazard_type == "Missile" else sfx_asteroid
	aud.max_distance = 800.0
	aud.attenuation = 2.0
	add_child(aud)
	aud.play()
	
	var target_pos = radar_center.position - Vector2(8, 8)
	var speed = 120.0 if hazard_type == "Missile" else 70.0 
	var vel = (target_pos - vis.position).normalized() * speed
	
	var hazard_data = {
		"type": hazard_type,
		"visual": vis,
		"audio": aud,
		"velocity": vel
	}
	
	if hazard_type == "Missile":
		active_missile = hazard_data
	else:
		active_asteroid = hazard_data

# (The old local test timer has been removed because NetworkManager handles it now!)
