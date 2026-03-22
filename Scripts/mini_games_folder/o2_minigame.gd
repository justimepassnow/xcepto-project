extends Control

signal game_finished(success, node)

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
	# Generates a number between 0 and 9999, then formats it as a 4-digit string
	var raw_num = randi() % 2000
	correct_code = "%04d" % raw_num # This ensures it's always exactly 4 chars
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
	is_processing = true 
	
	if current_input == correct_code:
		# --- SUCCESS STATE ---
		input_display.add_theme_color_override("font_color", Color.GREEN)
		win_label.show()
		
		for node in keypad.get_children():
			if node is Button:
				node.disabled = true
				
		await get_tree().create_timer(1.5).timeout
		
		# Notify MechanicUI (Success = true, node = self)
		game_finished.emit(true, self)
		
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
