extends Control

signal task_completed

var total_debris = 6
var cleared_debris = 0

@onready var win_label = $WinLabel

func _ready():
	win_label.hide()
	spawn_debris()

func spawn_debris():
	for i in range(total_debris):
		var poly = Button.new()
		# Randomize the look so they act like random polygons!
		poly.size = Vector2(randf_range(40, 100), randf_range(40, 100))
		poly.position = Vector2(randf_range(100, 800), randf_range(100, 400))
		poly.rotation = randf_range(0, 6.28) # Random spin
		poly.modulate = Color(randf(), randf(), randf()) # Random color
		
		# Connect the click event
		poly.pressed.connect(_on_poly_clicked.bind(poly))
		add_child(poly)

func _on_poly_clicked(poly: Button):
	poly.queue_free() # Destroy the clicked polygon
	cleared_debris += 1
	
	if cleared_debris >= total_debris:
		win_label.show()
		# Wait 2 seconds so the player can read the message
		await get_tree().create_timer(2.0).timeout
		task_completed.emit()
		queue_free() # Close the minigame window
