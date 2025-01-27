extends CharacterBody2D
class_name Grabbable
var being_held := false
var hold_height: int
var cursor_hovered := false
var just_clicked_on := false
var last_being_held := false
var just_now_being_held := false
@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	self.add_to_group("Grabbable")
	area_2d.mouse_entered.connect(_mouse_entered)
	area_2d.mouse_exited.connect(_mouse_exited)
	area_2d.input_event.connect(_click_to_grab)

func _mouse_entered() -> void: cursor_hovered = true
func _mouse_exited() -> void: cursor_hovered = false
func _click_to_grab(_viewport: Node, event: InputEvent, _shape_idx: int) -> void: 
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not being_held:
		if self == global.cur_plr or global.cur_plr.held_object or global.cur_plr.being_held or (self is Player and self.held_object):
			return
		if global.cur_plr.position.distance_squared_to(self.position) <= 2000:
			being_held = true
			global.cur_plr.held_object = self
			get_viewport().set_input_as_handled()
			global.cur_plr.hey_just_picked_this_shit_up_dont_throw_it_please = true
	
