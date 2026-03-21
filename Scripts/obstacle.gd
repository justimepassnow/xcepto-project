extends Area2D

var speed = 200
var target_node: Node2D = null
var damage_amount = 15 # Set how much damage you want it to do!

# 🛡️ THE FIX FOR HEALTH DROPPING TO 0: This guarantees only 1 hit!
var has_hit = false 

func _ready():
	z_index = 10
	
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta):
	# If we already hit the ship, stop moving and wait to be deleted
	if has_hit:
		return 

	if target_node and is_instance_valid(target_node):
		var direction = (target_node.global_position - global_position).normalized()
		global_position += direction * speed * delta

		# Backup delete just in case it reaches the absolute center
		if global_position.distance_to(target_node.global_position) < 5.0:
			_deal_damage_to_ship()
	else:
		position.y += speed * delta

	# Increased the delete boundary just in case your screen is taller
	if global_position.y > 1500:
		queue_free()

# ✅ Detects if the ship is a CharacterBody2D or RigidBody2D
func _on_body_entered(body):
	if body.name == "shipbody" or body.is_in_group("ship"):
		_deal_damage_to_ship()

# ✅ Detects if the ship is an Area2D (Which your 'shipbody' is!)
func _on_area_entered(area):
	if area.name == "shipbody" or area.is_in_group("ship"):
		_deal_damage_to_ship()

func _deal_damage_to_ship():
	# If this bullet already did damage in the last microsecond, ignore this!
	if has_hit:
		return 
		
	has_hit = true # Lock the door! No more damage allowed from this bullet.
	
	print("💥 SHIP HIT! Dealing damage...")
	
	# Navigate up from the shipbody -> Turret -> Gunner UI Root
	# And deal the damage safely
	if target_node and is_instance_valid(target_node):
		var gunner_ui = target_node.get_parent().get_parent()
		if gunner_ui.has_method("take_damage"):
			gunner_ui.take_damage(damage_amount)
		else:
			print("⚠️ Error: Found the UI, but take_damage() is missing!")
			
	# Destroy the bullet
	queue_free()
