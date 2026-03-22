extends Control

# --- VARIABLES ---
@onready var rooms = [
	$Level/rooms/room1,
	$Level/rooms/room2,
	$Level/rooms/room3,
	$Level/rooms/room4
]
var current_emergency_room = null
var player_current_room = null
var is_minigame_active = false # The Gatekeeper!
# The dynamic player tracker!
var current_player_node = null 
var current_ship_health: int = 100
# --- UI & NODE REFERENCES ---
@onready var health_label = $HUD/HealthLabel
@onready var health_bar = $HUD/ShipHealthBar
@onready var parallax_bg = $ParallaxBackground
@onready var repair_button = $HUD/RepairButton

func _ready():
	# 1. Setup all rooms automatically
	for room in rooms:
		if room.has_node("Glow"):
			room.get_node("Glow").visible = false
		room.body_entered.connect(_on_player_entered_room.bind(room))
		room.body_exited.connect(_on_player_exited_room.bind(room))

	# 2. Setup the Repair Button
	if repair_button:
		repair_button.hide() 
		repair_button.pressed.connect(_on_repair_button_pressed)

	# 3. Start the very first emergency
	print("Mechanic Shift Started...")
	await get_tree().create_timer(2.0).timeout
	trigger_new_emergency()

func _process(delta):
	# --- INFINITE PARALLAX SCROLLING ---
	if is_instance_valid(parallax_bg):
		parallax_bg.scroll_offset.y += 100.0 * delta


# ==========================================
# EMERGENCY & ROOM LOGIC
# ==========================================

func trigger_new_emergency():
	# --- THE HEALTH CHECK ---
	#if current_ship_health >= 75:
		#print("Health is ", current_ship_health, "% - Skipping emergency.")
		#start_next_emergency_timer() # Check again in 5 seconds
		#return
	# ------------------------

	var available_rooms = []
	for room in rooms:
		if room != player_current_room:
			available_rooms.append(room)
	
	if available_rooms.size() > 0:
		current_emergency_room = available_rooms.pick_random()
		if current_emergency_room.has_node("Glow"):
			current_emergency_room.get_node("Glow").visible = true
		print("ALERT! System broken in: ", current_emergency_room.name)

func _on_player_entered_room(body, room):
	# Wait for the actual mechanic
	if body.name == "MechanicPlayer": 
		# CAPTURE THE PLAYER DYNAMICALLY!
		current_player_node = body
		player_current_room = room 
		
		print("--- MECHANIC ENTERED: ", room.name, " ---")
		if current_emergency_room != null:
			if room.name == current_emergency_room.name:
				print(">>> SUCCESS: NAMES MATCH! Showing button... <<<")
				repair_button.show()
				repair_button.global_position = Vector2(500, 300)


func _on_player_exited_room(body, room):
	# Use current_player_node instead of "player"
	if body == current_player_node and player_current_room == room:
		player_current_room = null
		repair_button.hide()


# ==========================================
# MINIGAME SPAWNING & COMPLETION
# ==========================================

func _on_repair_button_pressed():
	# --- THE GATEKEEPER ---
	if is_minigame_active == true:
		return # Stop immediately! Don't run the rest of the code.
	
	is_minigame_active = true # Lock the door for any future clicks
	# ----------------------

	repair_button.hide()
	
	if current_emergency_room and current_emergency_room.has_node("Glow"):
		current_emergency_room.get_node("Glow").visible = false
	current_emergency_room = null
	
	if current_player_node:
		current_player_node.set_physics_process(false)
	
	print("Loading Random Minigame...")
	
	var minigame_paths = [
		"res://scenes/mini_games/engine_minigame.tscn",
		"res://scenes/mini_games/o2_minigame.tscn",
		"res://scenes/mini_games/circuit_minigame.tscn",
		"res://scenes/mini_games/filter_minigame.tscn"
	]
	
	var random_path = minigame_paths.pick_random()
	var minigame_scene_resource = load(random_path) 
	var minigame_instance = minigame_scene_resource.instantiate()
	
	minigame_instance.connect("game_finished", _on_minigame_completed)
	$HUD.add_child(minigame_instance)
	

func _on_minigame_completed(success: bool, minigame_node: Node):
	is_minigame_active = false 
	
	# Delete the minigame scene
	if is_instance_valid(minigame_node):
		minigame_node.queue_free()
	
	# Unfreeze the player
	if current_player_node:
		current_player_node.set_physics_process(true)
	
	if success:
		print("Minigame Won! Sending repair signal to server...")
		
		# Match the function name in your NetworkManager.gd (heal_ship)
		if get_parent().has_method("heal_ship"):
			# Send 15 HP to the server (ID 1)
			get_parent().heal_ship.rpc_id(1, 15) 
		else:
			print("Error: Network Manager is missing heal_ship method!")
		
	# Start the wait for the next broken room
	start_next_emergency_timer()


func start_next_emergency_timer():
	print("Systems stable... for now. Waiting 5 seconds.")
	await get_tree().create_timer(5.0).timeout
	trigger_new_emergency()


# ==========================================
# SERVER UI UPDATES
# ==========================================

func update_health_ui(new_health: int):
	current_ship_health = new_health # <-- ADD THIS LINE
	
	if health_label != null:
		health_label.text = "Ship Health: " + str(new_health) + "%"
		if new_health <= 30:
			health_label.add_theme_color_override("font_color", Color.RED)
		else:
			health_label.add_theme_color_override("font_color", Color.WHITE)
			
	if health_bar != null:
		health_bar.value = new_health
