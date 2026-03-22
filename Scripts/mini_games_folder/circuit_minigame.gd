extends Control

signal game_finished(success, node)

@onready var left_container = $LeftNodes
@onready var right_container = $RightNodes
@onready var lines_container = $Lines
@onready var win_label = $WinLabel

# The 4 core colors
var colors = [Color.RED, Color.CYAN, Color.GREEN, Color.YELLOW] 
var active_left_btn: Button = null
var active_left_color: Color = Color.TRANSPARENT
var connected_colors = []

func _ready() -> void:
	win_label.hide()
	
	# 1. Get exact children
	var left_buttons = left_container.get_children()
	var right_buttons = right_container.get_children()
	
	# 2. Use the count of buttons actually in the scene (e.g., 3 or 4)
	var button_count = min(left_buttons.size(), right_buttons.size())
	var active_colors = colors.slice(0, button_count)
	
	# 3. Create a shuffled version for the right side
	var shuffled_colors = active_colors.duplicate()
	shuffled_colors.shuffle()

	# 4. Apply colors
	for i in range(button_count):
		# Left Side
		_style_button(left_buttons[i], active_colors[i], false)
		left_buttons[i].pressed.connect(_on_left_clicked.bind(left_buttons[i], active_colors[i]))
		
		# Right Side
		_style_button(right_buttons[i], shuffled_colors[i], false)
		right_buttons[i].pressed.connect(_on_right_clicked.bind(right_buttons[i], shuffled_colors[i]))

func _style_button(btn: Button, color: Color, is_selected: bool) -> void:
	btn.custom_minimum_size = Vector2(40, 50)
	var style = StyleBoxFlat.new()
	
	if is_selected:
		style.bg_color = color
		style.set_border_width_all(6)
		style.border_color = Color.WHITE
	else:
		style.bg_color = Color(color.r, color.g, color.b, 0.6)
		style.set_border_width_all(4)
		style.border_color = Color.WHITE
		
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func _on_left_clicked(btn: Button, color: Color) -> void:
	if color in connected_colors: return
	if active_left_btn != null: _style_button(active_left_btn, active_left_color, false)
	
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
			# Deselect if wrong
			_style_button(active_left_btn, active_left_color, false)
			active_left_btn = null
			active_left_color = Color.TRANSPARENT

func _draw_connection(left_btn: Button, right_btn: Button, color: Color) -> void:
	var line = Line2D.new()
	line.default_color = color
	line.width = 12
	line.z_index = -1 
	
	# IMPORTANT: Using local position relative to the minigame root
	var start_pos = left_btn.global_position - self.global_position + (left_btn.size / 2.0)
	var end_pos = right_btn.global_position - self.global_position + (right_btn.size / 2.0)
	
	line.add_point(start_pos)
	line.add_point(end_pos)
	lines_container.add_child(line)
	connected_colors.append(color)
	
	if connected_colors.size() == left_container.get_child_count():
		win_label.show()
		await get_tree().create_timer(1.0).timeout
		game_finished.emit(true, self)
