extends Area2D

var speed = 600
@export var explosion_scene: PackedScene

func _ready():
	z_index = 10
	
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _process(delta):
	position += Vector2.UP.rotated(rotation) * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("obstacle"):
		print("Bullet hit obstacle")

		# stop extra collisions
		set_deferred("monitoring", false)

		area.queue_free()
		explode()

func explode():
	if explosion_scene != null:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().root.add_child.call_deferred(explosion)

	queue_free()
