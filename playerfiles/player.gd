extends Grabbable
class_name Player
@onready var audio_listener_2d: AudioListener2D = $Node/AudioListener2D

@onready var sprite: AnimatedSprite2D = $sprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var collision_top: CollisionShape2D = $CollisionShape2D2

@onready var snd_land: AudioStreamPlayer2D = $Node/land
@onready var snd_step: AudioStreamPlayer2D = $Node/step
@onready var snd_throw: AudioStreamPlayer2D = $Node/throw
@onready var snd_jump: AudioStreamPlayer2D = $Node/jump
@onready var snd_jumpholding: AudioStreamPlayer2D = $Node/jumpholding
@onready var snd_skid: AudioStreamPlayer2D = $Node/skid


@export var opaque_head   := true
@export var has_arms      := true
@export var has_water     := false
@export var outline_color := Color(1, 0, 0)
@export var head_color    := Color(1, 1, 1, int(opaque_head))

var has_control := false
var friction: float
var accel: float = 3
var force_crawl := false
var held_object
var direction :int= 0
var directionnotzero:int
var hey_just_picked_this_shit_up_dont_throw_it_please := false

const WALK_SPEED = 280.0
const JUMP_VELOCITY = -400.0

#region shader stuff
const STICKMANPLAYERSHADER = preload("res://playerfiles/stickmanplayershader.gdshader")
@onready var mat := ShaderMaterial.new()
func _ready() -> void:
	super()
	direction = randi_range(0, 1)
	if direction == 0:
		direction = -1
	sprite.flip_h = direction == -1
	force_crawl = randi_range(1,5) == 1
	outline_color = Color(randf_range(0, .6), randf_range(0, .6), randf_range(0, .6))
	head_color = Color(randf_range(.7, 1), randf_range(.7, 1), randf_range(.7, 1), 1)
	
	
	mat.shader = STICKMANPLAYERSHADER
	if opaque_head: has_water = false
	mat.set_shader_parameter("original_colors", 
	[Color(1, 0, 0), Color(0, 1, 0)])
	mat.set_shader_parameter("replace_colors", 
	[outline_color, head_color])
	sprite.material = mat
	
#endregion
	hold_height = -48


enum PlayerState {NONE, IDLE, WALK, MIDAIR, SKID, HELD, THROW, CROUCHING, CRAWLING, WAITING_UP, WAITING_DOWN}

#var test: PlayerState
var state := PlayerState.NONE#:
	#get:
		#return test
	#set(value):
		#if test == PlayerState.THROW:
			#breakpoint
		#test = value

func _process(_delta: float) -> void:
	if direction != 0: sprite.flip_h = direction == -1
	sprite.rotation = (velocity.x / 720) * .9

	match state:
		PlayerState.HELD:
			collision_top.disabled = true
			sprite.rotation = 0
			sprite.play("held")
			area_2d.monitoring = false
			area_2d.monitorable = false
			
		PlayerState.IDLE:
			collision_top.disabled = false
			sprite.rotation = 0
			if held_object:
				sprite.play("holdingidle")
				area_2d.monitoring = false
				area_2d.monitorable = false
			else:
				area_2d.monitoring = true
				area_2d.monitorable = true
				if force_crawl and not has_control or (Input.is_action_pressed("down") and has_control):
					collision_top.disabled = true
					force_crawl = true
					sprite.play("crouch")
				elif Input.is_action_pressed("up") and has_control:
					sprite.play("lookup")
					force_crawl = false
				else:
					force_crawl = false
					sprite.play("idle")


		PlayerState.WALK:
			collision_top.disabled = false
			sprite.rotation = 0
			if held_object:
				area_2d.monitoring = false
				area_2d.monitorable = false
				sprite.play("holdingwalk", abs(self.velocity.x) / 120)
			else:
				
				if Input.is_action_pressed("down") and has_control:
					collision_top.disabled = true
					sprite.play("crawl", abs(self.velocity.x) / 60)
				else:
					area_2d.monitoring = true
					area_2d.monitorable = true
					sprite.play("walk", abs(self.velocity.x) / 60)

		PlayerState.MIDAIR:
			collision_top.disabled = false
			if held_object:
				area_2d.monitoring = false
				area_2d.monitorable = false
				sprite.rotation = 0
				sprite.play("holdingjump")
			else:
				area_2d.monitoring = true
				area_2d.monitorable = true
				sprite.rotation = (velocity.x / 720) * .9
				sprite.play("midair")
				sprite.frame = clamp(velocity.y / 100 + 2, 0, 4)
			
		PlayerState.SKID:
			sprite.rotation = 0
			if not held_object and not Input.is_action_pressed("down"):
				sprite.play("skid")
				collision_top.disabled = false
				if not snd_skid.playing:
					snd_skid.play()
			
				
		PlayerState.THROW:
			collision_top.disabled = false
			sprite.rotation = 0
			sprite.play("throw")
			if sprite.frame == 4:
				state = PlayerState.NONE
			area_2d.monitoring = false
			area_2d.monitorable = false

			
		PlayerState.CRAWLING:
			collision_top.disabled = true
			sprite.rotation = 0
			sprite.play("crawl")
			
		PlayerState.WAITING_UP:
			collision_top.disabled = false
			sprite.rotation = 0
			sprite.play("waitingup")
			
		PlayerState.WAITING_DOWN:
			collision_top.disabled = true
			sprite.rotation = 0
			sprite.play("waitingdown")

	
var last_on_floor := false
var just_now_on_floor := false
func _physics_process(delta: float) -> void:
	just_now_on_floor = is_on_floor() and not last_on_floor
	last_on_floor = is_on_floor()
	directionnotzero = -1 if sprite.flip_h else 1
	
	if held_object:
		held_object.being_held = true
		held_object.position = position + Vector2(0, held_object.hold_height)
	
	if being_held: 
		state = PlayerState.HELD
		velocity = Vector2.ZERO
		return
		
		
	var is_skidding := (velocity.x < 0 and direction > 0) or (velocity.x > 0 and direction < 0)
	if has_control and state != PlayerState.THROW:
		direction = Input.get_axis("left", "right") as int
	else:
		direction = 0
	

	
	if not state == PlayerState.THROW:
		if is_on_floor():
			if abs(velocity.x) < 50: 
				state = PlayerState.IDLE
			else: 
				if direction:
					state = PlayerState.WALK
				else:
					state = PlayerState.SKID
			
			if Input.is_action_just_pressed("jump")  and has_control:
				velocity.y += JUMP_VELOCITY + float(has_water) * 80
				snd_jump.pitch_scale = randf_range(0.8, 1.2)
				snd_jump.play()
				
			if is_skidding and not state in [PlayerState.CROUCHING,PlayerState.CRAWLING]:
				accel = 3
				state = PlayerState.SKID
			
			if just_now_on_floor:
				snd_land.pitch_scale = randf_range(0.8, 1.2)
				snd_land.play()
			
		else:
			accel = 40
			if (Input.is_action_just_released("jump")) and velocity.y < -200:
				velocity.y = -200
			state = PlayerState.MIDAIR
		
		
	if not has_control:
		if is_on_floor():
			velocity.x *= .9 - (float(has_water) / 10)
		else:
			velocity.y += 900 * delta
		direction = sign(velocity.x)
		move_and_slide()
		return
		
		

		
	if Input.is_action_just_pressed("interact") and has_control and not being_held and has_arms and not hey_just_picked_this_shit_up_dont_throw_it_please:
		if not held_object:
			interact()
		else:
			held_object.being_held = false
			if not Input.is_action_pressed("down"):
				state = PlayerState.THROW
				snd_throw.play()
				held_object.velocity += velocity - Vector2(-200 * directionnotzero, 300)
				if held_object is Player:
					held_object.state = PlayerState.MIDAIR
					if Input.is_action_pressed("up"):
						global.switch_player(held_object)
			held_object = null
		
		



			
	if abs(velocity.x) < WALK_SPEED and has_control:
		velocity.x += direction * accel
	
	if Input.is_action_pressed("down") and is_on_floor():

		velocity.x *= .5 - (float(has_water) / 10)
	else:
		velocity.x *= .9 - (float(has_water) / 10)

	accel = 100
	if held_object: velocity.x *= .8
	velocity.y += (900 - (int(Input.is_action_pressed("jump")) * 100)) * delta
	move_and_slide()
	hey_just_picked_this_shit_up_dont_throw_it_please = false


func interact():
	if not (area_2d.monitoring or has_control): return
		#if overlapping.is_empty():
		#if Input.is_action_pressed("down"):
			#state = PlayerState.WAITING_DOWN
		#elif Input.is_action_pressed("up"):
			#state = PlayerState.WAITING_UP

	var closest: Node
	var closest_dist_sqr := INF
	for node: Node in get_tree().get_nodes_in_group("Grabbable"):
		if node == self:
			continue
		var dist_sqr := position.distance_squared_to(node.position)
		if dist_sqr < closest_dist_sqr:
			closest = node
			closest_dist_sqr = dist_sqr
	
	
	



func clicked_on(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and not being_held:
		global.switch_player(self)
		get_viewport().set_input_as_handled()


func _on_anim_frame_changed() -> void:
	if sprite.animation == "walk" or sprite.animation == "holdingwalk":
		if sprite.frame == 3:
			snd_step.pitch_scale = randf_range(0.8, 1)
			snd_step.play()
