extends Area2D

var speed = 200
var target_node: Node2D = null
var damage_amount = 15 

# THE FIX FOR HEALTH DROPPING TO 0: This guarantees only 1 hit!
var has_hit = false 

# --- AUDIO REFERENCE ---
@onready var engine_sfx = $AudioStreamPlayer2D # Add an AudioStreamPlayer2D named 'EngineSound'

func _ready():
	z_index = 10
	
	# Start the incoming rocket sound
	if engine_sfx:
		engine_sfx.play()
	
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta):
	if has_hit:
		return 

	if target_node and is_instance_valid(target_node):
		var direction = (target_node.global_position - global_position).normalized()
		global_position += direction * speed * delta

		if global_position.distance_to(target_node.global_position) < 5.0:
			_deal_damage_to_ship()
	else:
		position.y += speed * delta

	if global_position.y > 1500:
		queue_free()

func _on_body_entered(body):
	if body.name == "shipbody" or body.is_in_group("ship"):
		_deal_damage_to_ship()

func _on_area_entered(area):
	if area.name == "shipbody" or area.is_in_group("ship"):
		_deal_damage_to_ship()

func _deal_damage_to_ship():
	if has_hit:
		return 
		
	has_hit = true 
	
	# --- STOP AUDIO ON IMPACT ---
	if engine_sfx:
		engine_sfx.stop()
	
	print("💥 SHIP HIT! Dealing damage...")
	
	if target_node and is_instance_valid(target_node):
		var gunner_ui = target_node.get_parent().get_parent()
		if gunner_ui.has_method("take_damage"):
			gunner_ui.take_damage(damage_amount)
			
	queue_free()
