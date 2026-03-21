extends Control

signal task_completed

var correct_code = ""
var current_input = ""

@onready var code_display = $CodeDisplay
@onready var input_display = $InputDisplay
@onready var win_label = $WinLabel

func _ready():
	win_label.hide()
	
	# Generate a random 4-digit code (e.g., "8259")
	correct_code = str(randi() % 10) + str(randi() % 10) + str(randi() % 10) + str(randi() % 10)
	code_display.text = "TARGET O2 CODE: " + correct_code
	input_display.text = "ENTER: "

	# Automatically connect all 9 buttons to our click function!
	for button in $GridContainer.get_children():
		button.pressed.connect(_on_button_pressed.bind(button.text))

func _on_button_pressed(digit: String):
	current_input += digit
	input_display.text = "ENTER: " + current_input

	# Check if they typed 4 numbers
	if current_input.length() == 4:
		if current_input == correct_code:
			input_display.add_theme_color_override("font_color", Color.GREEN)
			win_label.show()
			await get_tree().create_timer(1.5).timeout
			task_completed.emit()
			queue_free()
		else:
			# WRONG CODE! Flash red and reset.
			input_display.add_theme_color_override("font_color", Color.RED)
			await get_tree().create_timer(0.5).timeout
			current_input = ""
			input_display.text = "ENTER: "
			input_display.add_theme_color_override("font_color", Color.WHITE)
