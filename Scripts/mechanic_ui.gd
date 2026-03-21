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

# --- UI & NODE REFERENCES ---
@onready var health_label = $HUD/HealthLabel
@onready var health_bar = $HUD/ShipHealthBar
@onready var parallax_bg = $ParallaxBackground
@onready var player = $Level/spaceship/MechanicPlayer
@onready var repair_button = $HUD/RepairButton

func _ready():
	# 1. Setup all rooms automatically
	for room in rooms:
		# Hide all glows at the start
		if room.has_node("Glow"):
			room.get_node("Glow").visible = false
		
		# Connect the Area2D signals via code
		room.body_entered.connect(_on_player_entered_room.bind(room))
		room.body_exited.connect(_on_player_exited_room.bind(room))

	# 2. Setup the Repair Button
	if repair_button:
		repair_button.hide() # Make sure it's hidden when the game starts
		repair_button.pressed.connect(_on_repair_button_pressed)

	# 3. Start the very first emergency 2 seconds after the game starts
	print("Mechanic Shift Started...")
	await get_tree().create_timer(2.0).timeout
	trigger_new_emergency()


func _process(delta):
	# --- INFINITE PARALLAX SCROLLING ---
	if is_instance_valid(parallax_bg):
		parallax_bg.scroll_offset.y += 100.0 * delta # 100.0 is your "Ship Speed"


# ==========================================
# EMERGENCY & ROOM LOGIC
# ==========================================

func trigger_new_emergency():
	# 1. Create a list of rooms the player is NOT currently in
	var available_rooms = []
	for room in rooms:
		if room != player_current_room:
			available_rooms.append(room)
	
	# 2. Pick a random room from that safe list
	if available_rooms.size() > 0:
		current_emergency_room = available_rooms.pick_random()
		
		# 3. Turn on the Red Glow!
		if current_emergency_room.has_node("Glow"):
			current_emergency_room.get_node("Glow").visible = true
			
		print("ALERT! System broken in: ", current_emergency_room.name)


func _on_player_entered_room(body, room):
	if body.name == "MechanicPlayer":
		player_current_room = room
		
		# If they walk into the broken room, show the button!
		if room == current_emergency_room:
			print("Mechanic is in position. Ready to repair.")
			repair_button.show()


func _on_player_exited_room(body, room):
	if body.name == "MechanicPlayer" and player_current_room == room:
		player_current_room = null
		
		# If they walk away from the emergency, hide the button!
		repair_button.hide()


# ==========================================
# MINIGAME SPAWNING & COMPLETION
# ==========================================

func _on_repair_button_pressed():
	# 1. Hide the button so they can't double-click it
	repair_button.hide()
	
	# 2. Turn off the red room glow now that they are working on it
	if current_emergency_room and current_emergency_room.has_node("Glow"):
		current_emergency_room.get_node("Glow").visible = false
	
	current_emergency_room = null
	
	# 3. Freeze the player so they can't walk away during the minigame
	player.set_physics_process(false)
	
	# 4. LOAD THE MINIGAME SCENE ON TOP OF THE HUD
	print("Loading Minigame Scene...")
	
	# IMPORTANT: You need to create a scene called "Minigame.tscn" for this to work!
	var minigame_scene_resource = preload("res://Minigame.tscn") 
	var minigame_instance = minigame_scene_resource.instantiate()
	
	# Connect the custom signal from the minigame
	minigame_instance.connect("game_finished", _on_minigame_completed)
	
	# Add it to the HUD so it renders on top of the screen
	$HUD.add_child(minigame_instance)


func _on_minigame_completed(success: bool, minigame_node: Node):
	# 1. Delete the minigame scene from the screen
	minigame_node.queue_free()
	
	# 2. Unfreeze the player
	player.set_physics_process(true)
	
	# 3. Heal the ship if they won!
	if success:
		print("Task Completed! Ship repaired.")
		
		if get_parent().has_method("add_health"):
			get_parent().add_health.rpc_id(1, 15) 
		
	# 4. Start the timer for the next emergency
	start_next_emergency_timer()


func start_next_emergency_timer():
	print("Systems stable... for now. Waiting 5 seconds.")
	await get_tree().create_timer(5.0).timeout
	trigger_new_emergency()


# ==========================================
# SERVER UI UPDATES
# ==========================================

func update_health_ui(new_health: int):
	# 1. Update the Text Label
	if health_label != null:
		health_label.text = "Ship Health: " + str(new_health) + "%"
		
		if new_health <= 30:
			health_label.add_theme_color_override("font_color", Color.RED)
		else:
			health_label.add_theme_color_override("font_color", Color.WHITE)
			
	# 2. Update the Visual Progress Bar
	if health_bar != null:
		health_bar.value = new_health
