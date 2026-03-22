extends Control

# CHANGE 1: Match the signal name used by your MechanicUI
signal game_finished(success, node)

@onready var left_container = $LeftNodes
@onready var right_container = $RightNodes
@onready var lines_container = $Lines
@onready var win_label = $WinLabel

var colors = [Color.RED, Color.CYAN, Color.GREEN, Color.YELLOW] 
var right_colors = []

var active_left_btn: Button = null
var active_left_color: Color = Color.TRANSPARENT
var connected_colors = []

func _ready() -> void:
	win_label.hide()
	
	# 1. Get the lists of buttons
	var left_buttons = left_container.get_children()
	var right_buttons = right_container.get_children()
	
	# 2. SAFETY CHECK: Ensure we have exactly 4 on each side
	if left_buttons.size() < 4 or right_buttons.size() < 4:
		print("ERROR: You need 4 buttons in LeftNodes and 4 in RightNodes!")
		return

	# 3. Prepare the colors
	# The left side always uses RED, CYAN, GREEN, YELLOW in order
	right_colors = colors.duplicate() 
	right_colors.shuffle() # Randomize the order for the right side

	# 4. Apply the colors and connect signals
	for i in range(4):
		# Setup Left Side (Button 1=Red, 2=Cyan, 3=Green, 4=Yellow)
		_style_button(left_buttons[i], colors[i], false)
		# Disconnect old signals if they exist to prevent double-firing
		if left_buttons[i].pressed.is_connected(_on_left_clicked):
			left_buttons[i].pressed.disconnect(_on_left_clicked)
		left_buttons[i].pressed.connect(_on_left_clicked.bind(left_buttons[i], colors[i]))
		
		# Setup Right Side (Randomized order, but SAME 4 colors)
		_style_button(right_buttons[i], right_colors[i], false)
		if right_buttons[i].pressed.is_connected(_on_right_clicked):
			right_buttons[i].pressed.disconnect(_on_right_clicked)
		right_buttons[i].pressed.connect(_on_right_clicked.bind(right_buttons[i], right_colors[i]))
func _style_button(btn: Button, color: Color, is_selected: bool) -> void:
	# FIX: Give the button a size so it isn't 0x0 pixels
	btn.custom_minimum_size = Vector2(60, 60)
	
	var style = StyleBoxFlat.new()
	
	if is_selected:
		style.bg_color = color
		# Use the method instead of direct assignment
		style.set_border_width_all(4) 
		style.border_color = Color.WHITE
	else:
		style.bg_color = Color(color.r, color.g, color.b, 0.4)
		# Use the method instead of direct assignment
		style.set_border_width_all(2)
		style.border_color = color
		
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
func _on_left_clicked(btn: Button, color: Color) -> void:
	if color in connected_colors: return
	
	if active_left_btn != null:
		_style_button(active_left_btn, active_left_color, false)
		
	active_left_btn = btn
	active_left_color = color
	_style_button(active_left_btn, active_left_color, true)

func _on_right_clicked(btn: Button, color: Color) -> void:
	if active_left_btn != null and not (color in connected_colors):
		if active_left_color == color:
			_draw_connection(active_left_btn, btn, color)
			_style_button(btn, color, true)
			active_left_btn = null
			active_left_color = Color.TRANSPARENT
		else:
			_style_button(active_left_btn, active_left_color, false)
			active_left_btn = null
			active_left_color = Color.TRANSPARENT

func _draw_connection(left_btn: Button, right_btn: Button, color: Color) -> void:
	var line = Line2D.new()
	line.default_color = color
	line.width = 10
	line.z_index = -1 # Draw lines behind the buttons
	
	# Calculate center positions
	var start_pos = left_btn.global_position + (left_btn.size / 2.0)
	var end_pos = right_btn.global_position + (right_btn.size / 2.0)
	
	# Adjust positions if the minigame is a child of a HUD
	start_pos -= global_position
	end_pos -= global_position
	
	line.add_point(start_pos)
	line.add_point(end_pos)
	
	lines_container.add_child(line)
	connected_colors.append(color)
	
	if connected_colors.size() == 3:
		win_label.show()
		await get_tree().create_timer(1.5).timeout
		game_finished.emit(true, self) # Send success to MechanicUI
