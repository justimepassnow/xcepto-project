extends Control

signal task_completed

# Added type hints for better performance and editor autocomplete
var correct_code: String = ""
var current_input: String = ""
var is_processing: bool = false # This lock prevents input spamming

@onready var code_display: Label = $CodeDisplay
@onready var input_display: Label = $InputDisplay
@onready var win_label: Label = $WinLabel
@onready var keypad: GridContainer = $GridContainer

func _ready() -> void:
	win_label.hide()
	generate_new_code()
	
	# Loop through the grid, but safely verify the node is actually a Button
	for node in keypad.get_children():
		if node is Button:
			node.pressed.connect(_on_button_pressed.bind(node.text))

func generate_new_code() -> void:
	# Generates a random 4-digit code using numbers 1-9
	correct_code = str(randi_range(1, 9)) + str(randi_range(1, 9)) + str(randi_range(1, 9)) + str(randi_range(1, 9))
	code_display.text = "TARGET O2 CODE: " + correct_code
	reset_input()

func _on_button_pressed(digit: String) -> void:
	# Block input if the game is currently pausing for a win/loss animation
	if is_processing or current_input.length() >= 4:
		return
		
	current_input += digit
	input_display.text = "ENTER: " + current_input

	# Check the code exactly when 4 digits are entered
	if current_input.length() == 4:
		_check_code()

func _check_code() -> void:
	is_processing = true # Lock the keypad
	
	if current_input == correct_code:
		# --- SUCCESS STATE ---
		input_display.add_theme_color_override("font_color", Color.GREEN)
		win_label.show()
		
		# Disable buttons so they can't be clicked during the closing transition
		for node in keypad.get_children():
			if node is Button:
				node.disabled = true
				
		await get_tree().create_timer(1.5).timeout
		task_completed.emit()
		queue_free()
		
	else:
		# --- FAIL STATE ---
		input_display.add_theme_color_override("font_color", Color.RED)
		await get_tree().create_timer(0.5).timeout
		reset_input()

func reset_input() -> void:
	current_input = ""
	input_display.text = "ENTER: "
	input_display.add_theme_color_override("font_color", Color.WHITE)
	is_processing = false # Unlock the keypad for the next attempt
