extends Area2D

var speed = 200

func _ready():
	z_index = 10  # ✅ correct place

func _process(delta):
	position.y += speed * delta

	# delete when off screen
	if position.y > 800:
		queue_free()

# ✅ only ONE signal function
func _on_body_entered(body):
	if body.is_in_group("ship"):
		print("Ship Hit!")
		queue_free()
