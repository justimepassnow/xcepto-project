extends Control

const PORT = 8910
var peer = ENetMultiplayerPeer.new()

# --- UI CONTAINERS ---
@onready var menu_container = $MenuContainer
@onready var lobby_container = $LobbyContainer

# --- MENU NODES ---
@onready var host_btn = $MenuContainer/HostButton
@onready var join_btn = $MenuContainer/JoinButton
@onready var ip_input = $MenuContainer/IPInput
@onready var error_label = $MenuContainer/ErrorLabel

# --- LOBBY NODES ---
@onready var ip_label = $LobbyContainer/IPLabel
@onready var player_list = $LobbyContainer/PlayerList
@onready var start_btn = $LobbyContainer/StartButton

# --- ROLE BUTTONS ---
@onready var btn_nav = $LobbyContainer/RoleContainer/NavButton
@onready var btn_gun = $LobbyContainer/RoleContainer/GunButton
@onready var btn_mech = $LobbyContainer/RoleContainer/MechButton

# --- GAME STATE ---
var roles = {"Navigator": 0, "Gunner": 0, "Mechanic": 0}
var global_ship_health = 100
var current_ui = null # Tracks the player's screen so we can delete it on Game Over

func _ready():
	# Connect Menu
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	start_btn.pressed.connect(_on_start_pressed)
	start_btn.hide() 
	
	# Connect Role Buttons 
	btn_nav.pressed.connect(_request_role.bind("Navigator"))
	btn_gun.pressed.connect(_request_role.bind("Gunner"))
	btn_mech.pressed.connect(_request_role.bind("Mechanic"))
	
	# Connect Network Signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

# --- THE IP MATCHER ---
func get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172.16."):
			return addr
	return "IP not found. Check console."

# --- 1. HOST & JOIN LOGIC ---
func _on_host_pressed():
	var error = peer.create_server(PORT, 3) 
	if error != OK: return
	multiplayer.multiplayer_peer = peer
	
	menu_container.hide()
	lobby_container.show()
	ip_label.text = "IP: " + get_local_ip() + " | Please select your role."
	player_list.add_item("You are the Host (ID: 1)")

func _on_join_pressed():
	var ip = ip_input.text.strip_edges()
	if not ip.is_valid_ip_address():
		error_label.text = "Invalid IP format!"
		error_label.show()
		return
		
	var error = peer.create_client(ip, PORT)
	if error != OK: return
	multiplayer.multiplayer_peer = peer
	
	error_label.hide()
	menu_container.hide()
	lobby_container.show()
	ip_label.text = "Connected! Please select a role."

# --- 2. THE ROLE SELECTION LOGIC ---
func _request_role(role_name: String):
	receive_role_request.rpc_id(1, role_name)

@rpc("any_peer", "call_local")
func receive_role_request(requested_role: String):
	if not multiplayer.is_server(): return 
	
	var sender_id = multiplayer.get_remote_sender_id()
	if roles[requested_role] == 0:
		for r in roles:
			if roles[r] == sender_id:
				roles[r] = 0
		roles[requested_role] = sender_id
		sync_roles.rpc(roles)

@rpc("authority", "call_local")
func sync_roles(new_roles: Dictionary):
	roles = new_roles
	var my_id = multiplayer.get_unique_id()
	
	btn_nav.text = "Navigator (Taken)" if roles["Navigator"] != 0 else "Select Navigator"
	btn_nav.disabled = (roles["Navigator"] != 0 and roles["Navigator"] != my_id)
	
	btn_gun.text = "Gunner (Taken)" if roles["Gunner"] != 0 else "Select Gunner"
	btn_gun.disabled = (roles["Gunner"] != 0 and roles["Gunner"] != my_id)
	
	btn_mech.text = "Mechanic (Taken)" if roles["Mechanic"] != 0 else "Select Mechanic"
	btn_mech.disabled = (roles["Mechanic"] != 0 and roles["Mechanic"] != my_id)
	
	if multiplayer.is_server():
		# NOTE: If you are testing solo, temporarily change this to just: start_btn.show()
		if roles["Navigator"] != 0 and roles["Gunner"] != 0 and roles["Mechanic"] != 0:
			start_btn.show() 
		else:
			start_btn.hide() 

# --- 3. CONNECTION EVENTS ---
func _on_peer_connected(id):
	player_list.add_item("Player " + str(id) + " connected.")

func _on_peer_disconnected(id):
	player_list.add_item("Player " + str(id) + " left.")
	if multiplayer.is_server():
		for r in roles:
			if roles[r] == id: roles[r] = 0
		sync_roles.rpc(roles)

func _on_connected_to_server():
	player_list.add_item("Successfully joined server!")

# --- 4. STARTING THE GAME ---
func _on_start_pressed():
	start_match.rpc()

@rpc("authority", "call_local")
func start_match():
	lobby_container.hide()
	var my_id = multiplayer.get_unique_id()
	
	if roles["Navigator"] == my_id:
		current_ui = preload("res://Scenes/NavigatorUI.tscn").instantiate()
	elif roles["Gunner"] == my_id:
		current_ui = preload("res://Scenes/GunnerUI.tscn").instantiate()
	elif roles["Mechanic"] == my_id:
		current_ui = preload("res://Scenes/MechanicUI.tscn").instantiate()

	if current_ui != null:
		add_child(current_ui)

	# --- START SERVER HEARTBEAT ---
	if multiplayer.is_server():
		global_ship_health = 100 # Reset health
		var game_timer = Timer.new()
		game_timer.name = "GameLoopTimer"
		game_timer.wait_time = 4.0 
		game_timer.autostart = true
		game_timer.timeout.connect(_on_game_tick)
		add_child(game_timer)

# --- 5. THE GAME LOOP ---
func _on_game_tick():
	var hazards = ["Asteroid", "Missile"]
	var directions = ["Left", "Right"]
	var chosen_hazard = hazards.pick_random()
	var chosen_direction = directions.pick_random()
	
	print("SERVER TICK: Spawning ", chosen_hazard, " on the ", chosen_direction, "!")
	trigger_hazard.rpc(chosen_hazard, chosen_direction)

@rpc("authority", "call_local")
func trigger_hazard(hazard_type: String, direction: String):
	# Tell the Navigator screen to draw the dot and play the sound
	var nav_ui = get_node_or_null("NavigatorScreen") 
	if nav_ui != null:
		nav_ui.play_hazard(hazard_type, direction)

# --- 6. GLOBAL HEALTH & GAME OVER ---
@rpc("any_peer", "call_local")
func apply_damage(amount: int):
	if not multiplayer.is_server(): return 
	
	global_ship_health -= amount
	print("SERVER: Ship took damage! Health is now ", global_ship_health)
	
	if global_ship_health <= 0:
		trigger_game_over.rpc()

@rpc("authority", "call_local")
func trigger_game_over():
	print("GAME OVER TRIGGERED!")
	
	# Stop spawning hazards
	var timer = get_node_or_null("GameLoopTimer")
	if timer != null:
		timer.stop()
		timer.queue_free() 
		
	# Destroy the player's screen
	if current_ui != null:
		current_ui.queue_free()
		
	# Show Lobby
	lobby_container.show()
	ip_label.text = "GAME OVER! THE SHIP WAS DESTROYED."
	
	if multiplayer.is_server():
		start_btn.show()
