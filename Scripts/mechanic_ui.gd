extends Control

# --- VARIABLES ---
@onready var health_label = $HealthLabel
@onready var health_bar = $HUD/ShipHealthBar

# The NetworkManager will knock on this door, and this script will answer!
func update_health_ui(new_health: int):
	
	# 1. Update the Text Label
	if health_label != null:
		health_label.text = "Ship Health: " + str(new_health) + "%"
		
		if new_health <= 30:
			health_label.add_theme_color_override("font_color", Color.RED)
		else:
			health_label.add_theme_color_override("font_color", Color.WHITE)
			
	# 2. Update the Visual Progress Bar
	if health_bar != null:
		health_bar.value = new_health
