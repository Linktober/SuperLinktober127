extends ScrollContainer

signal next_page

const SNAP_THRESHOLD: float = 0.1
const LERP_THRESHOLD: float = 8.0
export var lerp_speed: float

var target_scroll: float = -1
var last_scroll: float

# hacky code but i really dont want to care rn ,, 
export var page_loading: bool
var child: Node

func _process(delta):
	if abs(last_scroll - scroll_vertical) > LERP_THRESHOLD:
		target_scroll = scroll_vertical
		scroll_vertical = last_scroll
	
	if target_scroll > -1:
		scroll_vertical = lerp(scroll_vertical, target_scroll, delta * lerp_speed)
		if abs(target_scroll - scroll_vertical) < SNAP_THRESHOLD:
			scroll_vertical = target_scroll
			target_scroll = -1
	
	if page_loading and target_scroll > 0:
		if not is_instance_valid(child):
			child = get_child(0)
		
		if target_scroll != last_scroll and target_scroll > child.rect_size.y - rect_size.y - 32:
			emit_signal("next_page")
	
	last_scroll = scroll_vertical


func _ready():
	follow_focus = false
	get_viewport().connect("gui_focus_changed", self, "gui_focus_changed")


export var custom_follow_focus: bool
func gui_focus_changed(control: Control):
	if not custom_follow_focus: return
	if not is_visible_in_tree(): return
	if LastInputDevice.is_mouse: return
	if not is_a_parent_of(control): return
	
	scroll_vertical = (control.rect_position.y + control.rect_size.y) - rect_size.y/2
