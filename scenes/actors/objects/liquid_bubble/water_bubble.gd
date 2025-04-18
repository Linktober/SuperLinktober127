extends GameObject

var radius := 600.0
var color := Color(0.19, 0.52, 1)
var render_in_front := false
var tag = "default"

var last_radius : float
var last_color : Color
var last_front : bool

var moving : bool = false
var horizontal : bool = false
var match_level : float = 0.0
var move_speed : float = 1.0
var toxicity : float = 0.0
var tap_mode : bool = true

var save_pos : Vector2

onready var area = $Col
onready var area_collision = $Col/Shape
onready var sprite = $Fill
onready var waves = $Line

func _set_properties():
	savable_properties = ["radius", "color", "render_in_front", "tag", "toxicity", "tap_mode"]
	editable_properties = ["radius", "color", "render_in_front", "tag", "toxicity", "tap_mode"]

func _set_property_values():
	set_property("radius", radius, true)
	set_property("color", color, true)
	set_property("render_in_front", render_in_front, true)
	set_property("tag", tag, true)
	set_property("toxicity", toxicity, true)
	set_property("tap_mode", tap_mode, true)
	set_bool_alias("tap_mode", "Move", "Scale")

func _ready():
	var id = Singleton.CurrentLevelData.level_data.vars.current_liquid_id
	if Singleton.CurrentLevelData.level_data.vars.liquid_positions.size() > Singleton.CurrentLevelData.area and Singleton.CurrentLevelData.level_data.vars.liquid_positions[Singleton.CurrentLevelData.area].size() > id:
		var set_position = Singleton.CurrentLevelData.level_data.vars.liquid_positions[Singleton.CurrentLevelData.area][id]
		if set_position != Vector2():
			global_position = set_position
			save_pos = set_position
	Singleton.CurrentLevelData.level_data.vars.current_liquid_id += 1
	
	color.a = 0.5
	area_collision.shape = area_collision.shape.duplicate()
	change_size()
	last_radius = radius
	
	area_collision.disabled = !enabled
	
	Singleton.CurrentLevelData.level_data.vars.liquids.append([tag.to_lower(), self])

func change_size():
	area.set_radius(radius)
	
	sprite.material = sprite.get_material().duplicate()
	sprite.get_material().set_shader_param("color_tint", color)
	
	waves.material = waves.get_material().duplicate()
	waves.get_material().set_shader_param("color_tint", color)
	
	z_index = -1 if !render_in_front else 25
	
	last_radius = radius
	last_color = color
	last_front = render_in_front

func _physics_process(_delta):
	for body in area.get_overlapping_bodies():
		if body is Character:
			body.breath -= 0.25 * toxicity
			if body.breath <= 0:
				body.breath = 100
				body.damage(1, "hit", 0)
	
	if !moving: return
	
	if !horizontal:
		var end_pos := global_position.y
		var speed_modifier : float = transform.basis_xform(Vector2(0.0, 1.0)).y
		global_position.y = move_toward(global_position.y, match_level, move_speed * 2)
		if global_position.y == match_level:
			moving = false
			return
		if !tap_mode:
			radius += speed_modifier * ((end_pos - global_position.y))
			change_size() # Letting it happen in _process causes issues
	else:
		var end_pos := global_position.x
		if global_position.x == end_pos:
			moving = false
			return
		var speed_modifier : float = transform.basis_xform(Vector2(0.0, 1.0)).x
		global_position.x = move_toward(global_position.x, match_level, move_speed * 2)
		if global_position.x == match_level:
			moving = false
			return
		if !tap_mode:
			radius += speed_modifier * ((end_pos - global_position.x))
			change_size() # Letting it happen in _process causes issues

func _process(_delta):
	if "\n" in tag:
		tag = tag.replace("\n", "")
	if (radius != radius ||
			color != last_color ||
			render_in_front != last_front):
		change_size()
