extends Control

signal task_completed

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
	
	# FORCE the lines folder to draw ON TOP of the background
	lines_container.z_index = 10 
	
	right_colors = colors.duplicate()
	right_colors.shuffle()
	
	var left_buttons = left_container.get_children()
	var right_buttons = right_container.get_children()
	
	for i in range(4):
		_style_button(left_buttons[i], colors[i], false)
		left_buttons[i].pressed.connect(_on_left_clicked.bind(left_buttons[i], colors[i]))
		
		_style_button(right_buttons[i], right_colors[i], false)
		right_buttons[i].pressed.connect(_on_right_clicked.bind(right_buttons[i], right_colors[i]))

# --- THE VISUAL FIX ---
func _style_button(btn: Button, color: Color, is_selected: bool) -> void:
	var style = StyleBoxFlat.new()
	
	if is_selected:
		style.bg_color = Color(color.r, color.g, color.b, 1.0)
		style.border_width_all = 3
		style.border_color = Color.WHITE
	else:
		style.bg_color = Color(color.r, color.g, color.b, 0.4)
		
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.flat = false 

# --- THE GAME LOGIC ---
func _on_left_clicked(btn: Button, color: Color) -> void:
	if color in connected_colors:
		return
		
	print("Left clicked: ", color) 
		
	if active_left_btn != null:
		_style_button(active_left_btn, active_left_color, false)
		
	active_left_btn = btn
	active_left_color = color
	
	_style_button(active_left_btn, active_left_color, true)

func _on_right_clicked(btn: Button, color: Color) -> void:
	print("Right clicked: ", color)
	
	if active_left_btn != null and not (color in connected_colors):
		if active_left_color == color:
			print("MATCH SUCCESS!")
			_draw_connection(active_left_btn, btn, color)
			
			_style_button(active_left_btn, active_left_color, true)
			_style_button(btn, color, true)
			
			active_left_btn = null
			active_left_color = Color.TRANSPARENT
		else:
			print("WRONG MATCH!")
			_style_button(active_left_btn, active_left_color, false)
			active_left_btn = null
			active_left_color = Color.TRANSPARENT

# --- THE LINE DRAWING FIX ---
func _draw_connection(left_btn: Button, right_btn: Button, color: Color) -> void:
	var line = Line2D.new()
	line.default_color = color
	line.width = 8
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	line.top_level = true 
	line.z_index = 10 
	
	var start_pos = left_btn.global_position + (left_btn.size / 2.0)
	var end_pos = right_btn.global_position + (right_btn.size / 2.0)
	
	line.add_point(start_pos)
	line.add_point(end_pos)
	
	lines_container.add_child(line)
	connected_colors.append(color)
	
	if connected_colors.size() == 4:
		print("GAME WON!")
		win_label.show()
		await get_tree().create_timer(1.5).timeout
		task_completed.emit()
		queue_free()
