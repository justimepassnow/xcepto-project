extends Area2D

var speed = 200
var target_node: Node2D = null

func _ready():
	z_index = 10
	
	# ✅ FIX: Automatically connect the collision signals!
	# Without these lines, Godot ignores collisions.
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta):
	if target_node and is_instance_valid(target_node):
		var direction = (target_node.global_position - global_position).normalized()
		global_position += direction * speed * delta

		# Backup delete just in case it reaches the absolute center
		if global_position.distance_to(target_node.global_position) < 5.0:
			print("💥 Reached exact center of target! Deleting.")
			queue_free()
	else:
		position.y += speed * delta

	if position.y > 800:
		queue_free()

# ✅ Detects if the ship is a CharacterBody2D or RigidBody2D
func _on_body_entered(body):
	if body.is_in_group("ship"):
		print("🚢 Ship Hit! (Collision with Body)")
		queue_free()

# ✅ Detects if the ship is an Area2D (which your 'shipbody' is!)
func _on_area_entered(area):
	if area.is_in_group("ship"):
		print("🚢 Ship Hit! (Collision with Area)")
		queue_free()
	else:
		print("⚠️ Ignored collision with: ", area.name, " (It does not have 'ship' group)")
