extends GameObject

onready var area = $Area2D
onready var sprite = $AnimatedSprite
onready var metal_bounce_noise = $AudioStreamPlayer2D

const METAL_KNOCKBACK = 400
const METAL_KNOCKBACK_SPEED_LIMIT = 800
const METAL_DOWNWARD_KNOCKBACK_LIMIT = 100

var propeller_speed : int = 12

func _set_properties():
	savable_properties = ["propeller_speed"]
	editable_properties = ["propeller_speed"]

func _set_property_values():
	set_property("propeller_speed", propeller_speed, true, null)
	
	
func is_vanish(body):
	return body.powerup != null and body.powerup.id == "Vanish"

func is_metal_or_rainbow(body):
	return body.powerup != null and (body.powerup.id == "Metal" or body.powerup.id == "Rainbow")

func kill(body):
	if !(enabled and body.name.begins_with("Character") and !body.dead and body.controllable):
		return
	
	if is_metal_or_rainbow(body):
		var added_speed = global_position.direction_to(body.global_position) * METAL_KNOCKBACK
		body.velocity.x += added_speed.x
		body.velocity.y = added_speed.y
		body.velocity.limit_length(METAL_KNOCKBACK_SPEED_LIMIT)
		metal_bounce_noise.play()
#		body.velocity = global_position.direction_to(body.global_position) * METAL_KNOCKBACK
#		if body.velocity.y > METAL_DOWNWARD_KNOCKBACK_LIMIT:
#			body.velocity.y = METAL_DOWNWARD_KNOCKBACK_LIMIT
		
	if !is_vanish(body):
		body.knockback(global_position)
		if body.global_position.y > (global_position.y - 4):
			body.velocity.y = 55
		if !body.invulnerable:
			body.damage()
		else:
			body.sound_player.play_hit_sound()

func _ready():
	if mode != 1:
		var _connect = area.connect("body_entered", self, "kill")
	else:
		var _connect = connect("property_changed", self, "update_property")
		area.get_child(0).disabled = !enabled
		if is_preview:
			z_index = 0
			sprite.z_index = 0
	
	sprite.animation = String(palette)
	sprite.speed_scale = propeller_speed

func update_property(key, value):
	if key == "propeller_speed":
		sprite.speed_scale = value
