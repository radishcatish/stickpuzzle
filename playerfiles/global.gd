extends Node
class_name GlobalScript
@onready var players: Node = $"../level/players"
@onready var camera: Camera2D = $Camera2D
@onready var arrow: AnimatedSprite2D = $Arrow
@onready var cursorshadow: AnimatedSprite2D = $CanvasLayer/cursorshadow
@onready var audio_listener_2d: AudioListener2D = $AudioListener2D

@onready var cursor: AnimatedSprite2D = $CanvasLayer/cursor

var zoom : float = 1
var cur_plr: Player
var cur_plr_idx := 0
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	cur_plr = players.get_child(cur_plr_idx)
	cur_plr.has_control = true
	cur_plr.z_index = 100
	cursor.material.set_shader_parameter("replace_colors", [cur_plr.outline_color, cur_plr.head_color])

func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("switch"):
		var found : Player
		while true:
			cur_plr_idx = (cur_plr_idx + 1) % players.get_child_count()
			found = players.get_child(cur_plr_idx)
			if not found.being_held:
				break
		switch_player(found)
		
	if event.is_action_pressed("zoomout") and zoom > 0.4:
		zoom -= 0.1
	elif event.is_action_pressed("zoomin") and zoom < 1:
		zoom += 0.1
		
	if event.is_action_pressed(&"pause"):
		Engine.time_scale = 0.001 if Engine.time_scale == 1.0 else 1.0
		print(Engine.time_scale)
		get_viewport().set_input_as_handled()
@onready var swap: AudioStreamPlayer = $swap

func switch_player(player: Player):
	if player == cur_plr: return
	cur_plr.z_index = 0
	cur_plr.has_control = false
	cur_plr = player
	swap.pitch_scale = randf_range(0.9, 1.1)
	swap.play()
	cur_plr.has_control = true
	cur_plr.z_index = 100
	arrow.play("animation")
	arrow.frame = 0
	arrow.material.set_shader_parameter("replace_colors", [cur_plr.outline_color, cur_plr.head_color])
	
	
	
var cursor_last_pos := Vector2.ZERO
var cursor_positional_velocity := Vector2.ZERO
var cursor_rot: float
func _process(delta: float) -> void:
	cursor.material.set_shader_parameter("replace_colors", [cur_plr.outline_color, cur_plr.head_color])
	

	cur_plr.audio_listener_2d.make_current()
	camera.position.x = cur_plr.position.x 
	camera.position.y = cur_plr.position.y
	camera.zoom = Vector2(zoom, zoom)
	camera.offset = lerp(camera.offset, cur_plr.velocity / 3, 5.0 * delta)
	arrow.position = cur_plr.position + Vector2(0, -48)
	
	var cursor_pos := get_viewport().get_mouse_position()
	
	if cursor_last_pos != cursor_pos:
		cursor_positional_velocity = cursor_last_pos - cursor_pos
		cursor_last_pos = cursor_pos
	cursor_rot = 0
	cursor_rot = -cursor_positional_velocity.x + (cursor_positional_velocity.y /2)
	
	cursor.global_position = cursor_pos
	cursorshadow.global_position = cursor_pos + Vector2(2, 2 * (cursor_pos.y / 100))
	cursorshadow.modulate = Color(1,1,1, cursorshadow.global_position.y / 500)
	cursorshadow.frame = cursor.frame
	cursor.rotation_degrees = clampf(lerp(cursor.rotation_degrees, cursor_rot * 20, 0.1) * .7, -45, 145)
	cursorshadow.rotation_degrees = cursor.rotation_degrees
