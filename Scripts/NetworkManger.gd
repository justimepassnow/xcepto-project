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
# Dictionary tracks which Peer ID holds which role. 0 means empty.
var roles = {"Navigator": 0, "Gunner": 0, "Mechanic": 0}

func _ready():
	# Connect Menu
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	start_btn.pressed.connect(_on_start_pressed)
	start_btn.hide() # Hide start button initially
	
	# Connect Role Buttons (Using bind to pass the role string)
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
	
	# Updated text to remind the Host to pick a role!
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

# Step A: Player clicks a button and asks the server for the role
func _request_role(role_name: String):
	# Send the request to the Host (Peer ID 1)
	receive_role_request.rpc_id(1, role_name)

# Step B: The Server receives the request and checks if it's allowed
@rpc("any_peer", "call_local")
func receive_role_request(requested_role: String):
	if not multiplayer.is_server(): return # Only the Host runs this
	
	var sender_id = multiplayer.get_remote_sender_id()
	
	# Check if the role is completely empty
	if roles[requested_role] == 0:
		# Remove this player from any previous role they had
		for r in roles:
			if roles[r] == sender_id:
				roles[r] = 0
		
		# Assign the new role
		roles[requested_role] = sender_id
		
		# Tell EVERYONE to update their buttons
		sync_roles.rpc(roles)

# Step C: Everyone updates their screen based on the Server's ruling
@rpc("authority", "call_local")
func sync_roles(new_roles: Dictionary):
	roles = new_roles
	var my_id = multiplayer.get_unique_id()
	
	# Update button text and disable them if someone else took it
	btn_nav.text = "Navigator (Taken)" if roles["Navigator"] != 0 else "Select Navigator"
	btn_nav.disabled = (roles["Navigator"] != 0 and roles["Navigator"] != my_id)
	
	btn_gun.text = "Gunner (Taken)" if roles["Gunner"] != 0 else "Select Gunner"
	btn_gun.disabled = (roles["Gunner"] != 0 and roles["Gunner"] != my_id)
	
	btn_mech.text = "Mechanic (Taken)" if roles["Mechanic"] != 0 else "Select Mechanic"
	btn_mech.disabled = (roles["Mechanic"] != 0 and roles["Mechanic"] != my_id)
	
	# Only the Host checks if the game is ready to start
	if multiplayer.is_server():
		if roles["Navigator"] != 0 and roles["Gunner"] != 0 and roles["Mechanic"] != 0:
			start_btn.show() # All roles filled!
		else:
			start_btn.hide() # Someone unselected a role

# --- 3. CONNECTION EVENTS ---
func _on_peer_connected(id):
	player_list.add_item("Player " + str(id) + " connected.")

func _on_peer_disconnected(id):
	player_list.add_item("Player " + str(id) + " left.")
	# If a player disconnects, free up their role!
	if multiplayer.is_server():
		for r in roles:
			if roles[r] == id:
				roles[r] = 0
		sync_roles.rpc(roles) # Update buttons

func _on_connected_to_server():
	player_list.add_item("Successfully joined server!")

# --- 4. STARTING THE GAME ---
func _on_start_pressed():
	start_match.rpc()

@rpc("authority", "call_local")
func start_match():
	lobby_container.hide()
	var my_id = multiplayer.get_unique_id()
	
	# Figure out which role I have, and load that specific scene
	if roles["Navigator"] == my_id:
		add_child(preload("res://Scenes/NavigatorUI.tscn").instantiate())
	elif roles["Gunner"] == my_id:
		add_child(preload("res://Scenes/GunnerUI.tscn").instantiate())
	elif roles["Mechanic"] == my_id:
		add_child(preload("res://Scenes/MechanicUI.tscn").instantiate())
