extends Control

signal task_completed

@onready var slider1 = $HBoxContainer/VSlider1
@onready var slider2 = $HBoxContainer/VSlider2
@onready var slider3 = $HBoxContainer/VSlider3
@onready var win_label = $WinLabel

func _ready():
	win_label.hide()
	# Scramble the sliders randomly at the start!
	slider1.value = randf_range(10, 90)
	slider2.value = randf_range(10, 90)
	slider3.value = randf_range(10, 90)

func _process(_delta):
	# Check if all 3 sliders are in the middle "Safe Zone" (Between 45 and 55)
	if is_safe(slider1.value) and is_safe(slider2.value) and is_safe(slider3.value):
		set_process(false) # Stop checking to prevent multiple wins
		win_label.show()
		
		# Wait 1.5 seconds, tell the main game we won, and close the window!
		await get_tree().create_timer(1.5).timeout
		task_completed.emit()
		queue_free()

func is_safe(val):
	# This is our safe zone logic!
	return val > 45 and val < 55
