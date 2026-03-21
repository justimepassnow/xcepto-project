extends CharacterBody2D

const SPEED = 100.0

@onready var anim = $AnimatedSprite2D
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
