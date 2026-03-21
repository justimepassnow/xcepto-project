extends Control

signal task_completed

@export var total_debris: int = 6
var cleared_debris: int = 0
var is_game_over: bool = false

@onready var win_label: Label = $WinLabel

func _ready() -> void:
	win_label.hide()
	spawn_debris()

func spawn_debris() -> void:
	var screen_size: Vector2 = get_viewport_rect().size
	
	for i in range(total_debris):
		var poly: Button = Button.new()
		
		var w: float = randf_range(50.0, 120.0)
		var h: float = randf_range(50.0, 120.0)
		poly.size = Vector2(w, h)
		
		var max_x: float = max(screen_size.x - w - 20.0, 50.0)
		var max_y: float = max(screen_size.y - h - 20.0, 50.0)
		poly.position = Vector2(randf_range(20.0, max_x), randf_range(20.0, max_y))
		
		poly.pivot_offset = poly.size / 2.0
		poly.rotation = randf_range(0.0, TAU)
		
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(randf(), randf(), randf(), 0.9)
		style.border_width_bottom = 4
		style.border_width_right = 4
		style.border_color = Color(0.1, 0.1, 0.1, 0.8)
		
		poly.add_theme_stylebox_override("normal", style)
		poly.add_theme_stylebox_override("hover", style)
		poly.add_theme_stylebox_override("pressed", style)
		
		poly.pressed.connect(_on_poly_clicked.bind(poly))
		
		add_child(poly)
		move_child(poly, 0)

func _on_poly_clicked(poly: Button) -> void:
	if is_game_over:
		return
		
	poly.queue_free()
	cleared_debris += 1
	
	if cleared_debris >= total_debris:
		is_game_over = true
		win_label.show()
		await get_tree().create_timer(1.5).timeout
		task_completed.emit()
		queue_free()
