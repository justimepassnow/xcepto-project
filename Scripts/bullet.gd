extends Node2D

var speed = 600

func _process(delta):
	position += Vector2.UP.rotated(rotation) * speed * delta

func _ready():
	await get_tree().create_timer(2.0).timeout
	queue_free()
