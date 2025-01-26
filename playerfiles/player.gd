extends Grabbable
class_name Player



@onready var sprite: AnimatedSprite2D = $sprite
@onready var area2d: Area2D = $Area2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var collision_top: CollisionShape2D = $CollisionShape2D2




@export var opaque_head   := true
@export var has_arms      := true
@export var has_water     := false
@export var outline_color := Color(1, 0, 0)
@export var head_color    := Color(1, 1, 1, int(opaque_head))
var has_control := false

var held_object
var direction :int= 0
var directionnotzero:int
#region shader stuff
const STICKMANPLAYERSHADER = preload("res://playerfiles/stickmanplayershader.gdshader")
@onready var mat := ShaderMaterial.new()
func _ready() -> void:
	mat.shader = STICKMANPLAYERSHADER
	head_color = Color(1, 1, 1, int(opaque_head))
	if opaque_head: has_water = false
	mat.set_shader_parameter("original_colors", 
	[Color(1, 0, 0), Color(0, 1, 0)])
	mat.set_shader_parameter("replace_colors", 
	[outline_color, head_color])
	sprite.material = mat
	
#endregion
	hold_height = -48


const WALK_SPEED = 280.0
const JUMP_VELOCITY = -400.0


var friction: float
var accel: float = 3

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
	if direction == 1: sprite.flip_h = false
	if direction == -1: sprite.flip_h = true
	sprite.rotation = (velocity.x / 720) * .9

	match state:
		PlayerState.HELD:
			collision_top.disabled = true
			sprite.rotation = 0
			sprite.play("held")
			area2d.monitoring = false
			area2d.monitorable = false
			
		PlayerState.IDLE:
			collision_top.disabled = false
			sprite.rotation = 0
			if held_object:
				sprite.play("holdingidle")
				area2d.monitoring = false
				area2d.monitorable = false
			else:
				if Input.is_action_pressed("down") and has_control:
					collision_top.disabled = true
					sprite.play("crouch")
				else:
					sprite.play("idle")
				area2d.monitoring = true
				area2d.monitorable = true

		PlayerState.WALK:
			collision_top.disabled = false
			sprite.rotation = 0
			if held_object:
				area2d.monitoring = false
				area2d.monitorable = false
				sprite.play("holdingwalk", abs(self.velocity.x) / 120)
			else:
				
				if Input.is_action_pressed("down") and has_control:
					collision_top.disabled = true
					sprite.play("crawl", abs(self.velocity.x) / 60)
				else:
					area2d.monitoring = true
					area2d.monitorable = true
					sprite.play("walk", abs(self.velocity.x) / 60)

		PlayerState.MIDAIR:
			collision_top.disabled = false
			if held_object:
				area2d.monitoring = false
				area2d.monitorable = false
				sprite.rotation = 0
				sprite.play("holdingjump")
			else:
				area2d.monitoring = true
				area2d.monitorable = true
				sprite.rotation = (velocity.x / 720) * .9
				sprite.play("midair")
				sprite.frame = clamp(velocity.y / 100 + 2, 0, 4)
			
		PlayerState.SKID:
			sprite.rotation = 0
			if not held_object and not Input.is_action_pressed("down"):
				sprite.play("skid")
				collision_top.disabled = false
			
				
		PlayerState.THROW:
			collision_top.disabled = false
			sprite.rotation = 0
			sprite.play("throw")
			if sprite.frame == 4:
				state = PlayerState.NONE
			area2d.monitoring = false
			area2d.monitorable = false

			
		PlayerState.CRAWLING:
			collision_top.disabled = true
			sprite.rotation = 0
			sprite.play("crawl")
			
		PlayerState.WAITING_UP:
			collision_top.disabled = false
			sprite.rotation = 0
			sprite.play("waitingdown")
			
		PlayerState.WAITING_DOWN:
			collision_top.disabled = true
			sprite.rotation = 0
			sprite.play("waitingdown")

	

func _physics_process(delta: float) -> void:
	
	if being_held: 
		state = PlayerState.HELD
		velocity = Vector2.ZERO
		return
		
	var is_skidding := (velocity.x < 0 and direction > 0) or (velocity.x > 0 and direction < 0)
	if has_control and state != PlayerState.THROW:
		direction = Input.get_axis("left", "right") as int
		if direction != 0:
			directionnotzero = direction
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
		else:
			accel = 40
			if (Input.is_action_just_released("jump")) and velocity.y < -200:
				velocity.y = -200
			state = PlayerState.MIDAIR
		
	
	if held_object:
		held_object.position = position + Vector2(0, held_object.hold_height)
		
	if Input.is_action_just_pressed("interact") and has_control and not being_held and has_arms:
		if not held_object:
			interact()
		else:
			held_object.being_held = false
			if not Input.is_action_pressed("down"):
				state = PlayerState.THROW
				held_object.velocity += velocity - Vector2(-200 * directionnotzero, 300)
				if held_object is Player:
					global.switch_player(held_object)
			held_object = null
		
		
	if is_skidding and is_on_floor() and not state in [PlayerState.CROUCHING,PlayerState.CRAWLING]:
		accel = 3
		state = PlayerState.SKID

	if abs(velocity.x) < WALK_SPEED and has_control:
		velocity.x += direction * accel
	
	if Input.is_action_pressed("down") and not held_object:
		accel = 15
	else:
		accel = 100
	if direction == 0 or not is_on_floor() or not is_skidding:
		velocity.x *= .9 - (float(has_water) / 10)
	else:
		velocity.x *= .8 - (float(has_water) / 10)
		
	if held_object: velocity.x *= .8
	velocity.y += (900 - (int(Input.is_action_pressed("jump")) * 100)) * delta
	move_and_slide()


func interact():
	if not area2d.monitoring: return
	
	for area in area2d.get_overlapping_areas():
		print(area)
		var area_prnt := area.get_parent()
		if area_prnt is Grabbable:
			held_object = area_prnt
			held_object.being_held = true
			break



func clicked_on(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not being_held:
		global.switch_player(self)
