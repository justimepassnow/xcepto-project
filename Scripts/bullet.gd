extends Area2D

var speed = 600
@export var explosion_scene: PackedScene
var sfx_explosion = preload("res://assets/sounds/astroid blast.wav")

func _ready():
	z_index = 10
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _process(delta):
	position += Vector2.UP.rotated(rotation) * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("obstacle"):
		print("Bullet hit obstacle")
		set_deferred("monitoring", false)
		area.queue_free()
		explode()

func explode():
	# --- 1. THE SOUND LOGIC ---
	if sfx_explosion:
		var sfx_player = AudioStreamPlayer2D.new()
		sfx_player.stream = sfx_explosion
		sfx_player.global_position = global_position
		sfx_player.pitch_scale = randf_range(0.9, 1.1) # Add slight variety
		
		# Add to root so it isn't deleted with the bullet
		get_tree().root.add_child(sfx_player)
		sfx_player.play()
		
		# Auto-delete the player node when the sound finishes
		sfx_player.finished.connect(func(): sfx_player.queue_free())

	# --- 2. THE VISUAL EXPLOSION ---
	if explosion_scene != null:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().root.add_child.call_deferred(explosion)

	queue_free()
