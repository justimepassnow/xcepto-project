extends CharacterBody2D

const SPEED = 300.0

@onready var anim = $AnimatedSprite2D
@onready var health_label = $HealthLabel
func _physics_process(_delta):
	var direction_x = Input.get_axis("ui_left", "ui_right")
	var direction_y = Input.get_axis("ui_up", "ui_down")
	
	velocity.x = direction_x * SPEED
	velocity.y = direction_y * SPEED
	
	if velocity.length() > 0:
		anim.play("walk")
		
		# Notice we are rotating 'anim' now, not the whole body!
		if velocity.x > 0:
			anim.rotation_degrees = 90  # Right
		elif velocity.x < 0:
			anim.rotation_degrees = -90 # Left
		elif velocity.y > 0:
			anim.rotation_degrees = 180 # Down
		elif velocity.y < 0:
			anim.rotation_degrees = 0   # Up
			
	else:
		anim.play("idle")

	move_and_slide()


# The NetworkManager will automatically find this and run it!
func update_health_ui(new_health: int):
	if health_label != null:
		health_label.text = "Ship Health: " + str(new_health) + "%"
		
		if new_health <= 30:
			health_label.add_theme_color_override("font_color", Color.RED)
		else:
			health_label.add_theme_color_override("font_color", Color.WHITE)
