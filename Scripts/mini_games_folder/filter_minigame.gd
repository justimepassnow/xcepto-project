extends Control

# CHANGE 1: Match the signal name in MechanicUI
signal game_finished(success, node)

@export var total_debris: int = 8
var cleared_debris: int = 0
var is_game_over: bool = false

@onready var win_label: Label = $WinLabel

func _ready() -> void:
	win_label.hide()
	
	# Wait one frame to ensure the UI has a real size
	await get_tree().process_frame
	spawn_debris()

func spawn_debris() -> void:
	# Use a safe fallback size if the viewport is reporting 0
	var screen_size = get_viewport_rect().size
	if screen_size.x == 0:
		screen_size = Vector2(1152, 648) # Default Godot window size
	
	for i in range(total_debris):
		var poly = Button.new()
		
		# Give the button a minimum size so it's not invisible
		var w = randf_range(60.0, 100.0)
		var h = randf_range(60.0, 100.0)
		poly.custom_minimum_size = Vector2(w, h)
		poly.size = Vector2(w, h)
		
		# Calculate random position within the screen
		var pos_x = randf_range(100.0, screen_size.x - 100.0)
		var pos_y = randf_range(100.0, screen_size.y - 100.0)
		poly.position = Vector2(pos_x, pos_y)
		
		poly.pivot_offset = Vector2(w/2, h/2)
		poly.rotation = randf_range(0.0, TAU)
		
		# Styling the debris
		var style = StyleBoxFlat.new()
		style.bg_color = Color(randf(), randf(), randf(), 1.0)
		style.set_border_width_all(2)
		style.border_color = Color.BLACK
		style.corner_radius_top_left = randi_range(0, 20) # Random jagged shapes
		
		poly.add_theme_stylebox_override("normal", style)
		poly.add_theme_stylebox_override("hover", style)
		poly.add_theme_stylebox_override("pressed", style)
		
		# Connect the click
		poly.pressed.connect(_on_poly_clicked.bind(poly))
		
		add_child(poly)

func _on_poly_clicked(poly: Button) -> void:
	if is_game_over:
		return
		
	poly.queue_free()
	cleared_debris += 1
	
	if cleared_debris >= total_debris:
		is_game_over = true
		win_label.show()
		await get_tree().create_timer(1.5).timeout
		
		# Emit success to MechanicUI
		game_finished.emit(true, self)
