extends Node
class_name GlobalScript
@onready var players: Node = $"../level/players"
@onready var camera: Camera2D = $Camera2D
@onready var arrow: AnimatedSprite2D = $Arrow

var cur_plr: Player
var cur_plr_idx := 0
func _ready() -> void:
	cur_plr = players.get_child(cur_plr_idx)
	cur_plr.has_control = true
	cur_plr.z_index = 100
	
func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("switch"):
		var found : Player
		while true:
			cur_plr_idx = (cur_plr_idx + 1) % players.get_child_count()
			found = players.get_child(cur_plr_idx)
			if not found.being_held:
				break
		switch_player(found)
		

	if event.is_action_pressed(&"pause"):
		Engine.time_scale = 0.0 if Engine.time_scale == 1.0 else 1.0
		print(Engine.time_scale)
		get_viewport().set_input_as_handled()

func switch_player(player: Player):
	cur_plr.z_index = 0
	cur_plr.has_control = false
	cur_plr = player
	cur_plr.has_control = true
	cur_plr.z_index = 100
	arrow.play("animation")
	arrow.frame = 0
	arrow.material.set_shader_parameter("replace_colors", [cur_plr.outline_color, cur_plr.head_color])
	
	
	

func _process(delta: float) -> void:
	camera.position.x = cur_plr.position.x 
	camera.position.y = cur_plr.position.y


	camera.offset = lerp(camera.offset, cur_plr.velocity / 3, 5.0 * delta)
	arrow.position = cur_plr.position + Vector2(0, -48)
