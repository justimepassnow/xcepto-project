extends Control

# The correct signal is now at the top where Godot expects it
signal game_finished(success, node)

@onready var label = $Label 
@onready var win_label = $WinLabel
@onready var hbox = $HBoxContainer

@onready var slider1 = $HBoxContainer/VSlider1
@onready var slider2 = $HBoxContainer/VSlider2
@onready var slider3 = $HBoxContainer/VSlider3

@onready var val_label1 = $HBoxContainer/VSlider1/Label
@onready var val_label2 = $HBoxContainer/VSlider2/Label
@onready var val_label3 = $HBoxContainer/VSlider3/Label

func _ready():
	win_label.hide()
	
	# Set the target Label text to a random number between 10 and 250
	label.text = str(randi_range(10, 250)) 
	
	# Scramble the sliders randomly at the start
	slider1.value = randf_range(10, 90)
	slider2.value = randf_range(10, 90)
	slider3.value = randf_range(10, 90)

func _process(_delta):
	var val1 = round(slider1.value)
	var val2 = round(slider2.value)
	var val3 = round(slider3.value)
	
	val_label1.text = str(val1)
	val_label2.text = str(val2)
	val_label3.text = str(val3)
	
	var target_number = int(label.text)
	var current_sum = val1 + val2 + val3
	
	if current_sum == target_number:
		set_process(false) 
		label.hide()
		hbox.hide()
		win_label.show()
		
		await get_tree().create_timer(1.5).timeout
		
		# Emit the correct signal to the main scene
		game_finished.emit(true, self)
