extends Area2D

var speed = 600
@export var explosion_scene: PackedScene

func _ready():
	z_index = 10

func _process(delta):
	position += Vector2.UP.rotated(rotation) * speed * delta

func _on_body_entered(body):
	if body.is_in_group("obstacle"):
		
		# prevent double collision
		set_deferred("monitoring", false)

		body.queue_free()
		explode()

func explode():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	
	get_tree().root.add_child.call_deferred(explosion)
	queue_free()
