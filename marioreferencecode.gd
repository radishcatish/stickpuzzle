extends CharacterBody2D
#Nodes
#region Nodes
@onready var sprite: AnimatedSprite2D = $sprite

@onready var collision: CollisionShape2D = $collision
@onready var damage_box: Area2D = $damagebox
@onready var hitbox: Area2D = $hitbox

@onready var tmr_coyotetime:     Timer = $tmr/coyotetime
@onready var tmr_jumpqueue:      Timer = $tmr/jumpqueue
@onready var tmr_wallcoyotetime: Timer = $tmr/wallcoyotetime
@onready var tmr_iframes:        Timer = $tmr/iframes
@onready var tmr_stuntime:       Timer = $tmr/stuntime

@onready var snd_jump: AudioStreamPlayer = $snd/jump
@onready var snd_skid: AudioStreamPlayer = $snd/skid
@onready var snd_bump: AudioStreamPlayer = $snd/bump
@onready var snd_kick: AudioStreamPlayer = $snd/kick
@onready var snd_hurt: AudioStreamPlayer = $snd/hurt
@onready var snd_coin: AudioStreamPlayer = $snd/coin
@onready var snd_dive: AudioStreamPlayer = $snd/dive
@onready var snd_spin: AudioStreamPlayer = $snd/spinjump







#endregion

#Variables

var pause := false
@export var direction = 0
var friction := .99
var can_jump := false
var health := 3

var just_now_not_on_floor := false
var last_on_floor := false
var just_now_on_floor := false
var ceiling_hit_velocity := 0.0
var floor_angle: float = 0
var just_now_not_on_wall_only := false
var last_not_on_wall_only := false
var last_walljump_direction: int = 0
var coins_until_hp := 0
var y_inertia := 0.0
var directionnotzero = 1
var last_pos := Vector2.ZERO
var positional_velocity := Vector2.ZERO
var did_midair_action: bool = true
@export var locked: bool = false
@export var cant_move: bool = false
var is_slippery: bool = false

enum PlayerState {NONE, IDLE, WALK, MIDAIR, SKID, HURT, WALLSLIDE, CROUCH, DIVE, KICK, SPINJUMP}
#var cock: PlayerState
@export var state := PlayerState.NONE#
	#get:
		#return cock
	#set(value):
		#if cock == PlayerState.KICK:
			#breakpoint # this will break when it changes from kick to anything else
		#cock = value
func _ready() -> void:
	
	if locked:
		state = PlayerState.NONE
		sprite.play(&"invisible")
		for area in hitbox.get_overlapping_areas():
			interactions(area)
	
const JUMP_HEIGHT: float = -250
const RUN_SPEED := 160
var accel := 8.0

func _process(delta):
	if locked or health < 1:
		state = PlayerState.NONE
		sprite.play(&"invisible")
		return
	sprite.skew = (velocity.x / 720) * .9
	
	$temp.text = &"\n [center]" + PlayerState.find_key(state) + &"[/center]"

	if direction == 1: sprite.flip_h = false
	if direction == -1: sprite.flip_h = true

	match state:
		PlayerState.NONE:
			sprite.play(&"invisible")

		PlayerState.IDLE:
			sprite.play(&"idle")
			damage_box.monitoring = false
			sprite.rotation = floor_angle / 4
			
			
			
		PlayerState.WALK:
			sprite.speed_scale = 1
			sprite.play(&"walk", self.velocity.x / 150)
			damage_box.monitoring = false
			sprite.rotation = floor_angle / 2
			
		PlayerState.MIDAIR:
			damage_box.monitoring = false
			sprite.play(&"jump")
			if velocity.y > 0:
				sprite.play(&"fall")
				damage_box.monitoring = true
				damage_box.scale = Vector2(8, 11)
				damage_box.position = Vector2(0, 3)
				sprite.rotation = move_toward(sprite.rotation, 0, delta)
				if velocity.y > -JUMP_HEIGHT:
					sprite.play(&"fastfall")


		PlayerState.HURT:
			sprite.play(&"hurt")
			damage_box.monitoring = false
			
		PlayerState.CROUCH:
			sprite.play(&"crouch")
			damage_box.monitoring = false
			
		PlayerState.WALLSLIDE:
			sprite.play(&"wallsliding")
			damage_box.monitoring = false
			sprite.rotation = 0
			
		PlayerState.SKID:
			sprite.play(&"skid")
			if not snd_skid.is_playing():
				snd_skid.play()
			damage_box.monitoring = false
				
		PlayerState.KICK:
			sprite.speed_scale = 2
			sprite.play(&"kick")
			if sprite.frame == 5:
				state = PlayerState.MIDAIR
			damage_box.scale = Vector2(8, 16)
			damage_box.position = Vector2(6 * directionnotzero, 0)
			damage_box.monitoring = sprite.frame < 5
			sprite.rotation = 0
				
		PlayerState.DIVE:
			sprite.play(&"dive")
			damage_box.monitoring = true
			damage_box.scale = Vector2(15, 15)
			damage_box.position = Vector2(0, 2)
			if is_on_floor():
				damage_box.monitoring = false
				sprite.play(&"dive_sliding")
				sprite.rotation = floor_angle
				velocity.x *= 0.95
			else:
				sprite.rotation = Vector2(abs(velocity.x), velocity.y).angle() * direction
				
			if directionnotzero == Input.get_axis(&"left", &"right") * -1:
				velocity.x /= 1.05
			if directionnotzero == Input.get_axis(&"left", &"right"):
				velocity.x += 0.01
			velocity.x *= 0.99
			
		PlayerState.SPINJUMP:
			sprite.play(&"spinjump", 5)
			damage_box.monitoring = true
			damage_box.scale = Vector2(15, 15)
			damage_box.position = Vector2(0, 0)
			
			
			
	var flicker: bool = true
	if not tmr_iframes.is_stopped():
		flicker = bool(int(tmr_iframes.time_left * 100 ) % 2)
	else: 
		flicker = true
		
	if flicker:
		sprite.self_modulate = Color(1,1,1,1)
	else:
		sprite.self_modulate = Color(1,1,1,0.2)
	
	sprite.scale = Vector2(
		move_toward(sprite.scale.x, 1 , 3 * delta), 
		move_toward(sprite.scale.y, 1 , 3 * delta)
		)

	sprite.position = Vector2(
		velocity.x / 64,
		move_toward(sprite.position.y, .25, 1)
		)
		

	

	
func _physics_process(_delta):
	if locked or health < 1: return
	just_now_not_on_floor = not is_on_floor() and last_on_floor
	just_now_on_floor = is_on_floor() and not last_on_floor
	last_on_floor = is_on_floor()

	if abs(velocity.x) < 30 and not direction:
		velocity.x = 0
	
	if last_pos != position:
		positional_velocity = last_pos - position
		last_pos = position
	
	if not state in [PlayerState.HURT, PlayerState.DIVE] and not cant_move:
		direction = Input.get_axis(&"left", &"right")

		
	if direction != 0:
		directionnotzero = direction
		
	if direction == 0: 
		friction = .8
	else: 
		friction = .99
	
		
	if tmr_stuntime.is_stopped() or not locked:

		floor_snap_length = 8 + positional_velocity.length()
		camera_interested_in_pos = Vector2(0,0)
		
		for area in hitbox.get_overlapping_areas():
			interactions(area)
			
	
			
		if is_on_floor():
			tmr_wallcoyotetime.stop()
			last_walljump_direction = 0
			can_jump = true
			floor_angle =  get_floor_angle(up_direction) * sign(get_floor_normal().x)
			
			if direction:
				velocity.x += get_floor_normal().x * 10
			if abs(floor_angle) > .79 or is_slippery:
				velocity.x += get_floor_normal().x * 30
				
			if not state in [PlayerState.KICK, PlayerState.DIVE]:
				did_midair_action = false
				
				if abs(velocity.x) < 25 and direction == 0:
					state = PlayerState.IDLE
				else:
					state = PlayerState.WALK
				
				if ((direction == 1 and velocity.x < 0) or (direction == -1 and velocity.x > 0)) and abs(velocity.x) > 45:
						state = PlayerState.SKID
						accel = 4.0
						velocity.x *= 0.998
		else: midair()
		
		if Input.is_action_just_pressed(&"X") and not cant_move: 
			attackhandler()
		if (Input.is_action_just_pressed(&"Z") or not tmr_jumpqueue.is_stopped()) and can_jump and not cant_move and not state == PlayerState.KICK: 
			jump()
		
	else:
		velocity.y += 14
		velocity.x *= 0.9
		state = PlayerState.HURT
		direction = 0
		

	if abs(velocity.x) < RUN_SPEED and not state == PlayerState.DIVE:
		velocity.x = velocity.x + direction * (accel)
	accel = 8.0
	velocity.x *= friction
	velocity.y = clamp(velocity.y, -600, 500)
	if !locked:
		move_and_slide()

func jump():
	can_jump = false
	did_midair_action = false
	if abs(-get_floor_normal().x) < 0.5:
		velocity.y = JUMP_HEIGHT + clamp(abs(velocity.x / 3) * -1, -100, 100) + (positional_velocity.y * -30)
	else:
		velocity.y = -get_floor_normal().y * (JUMP_HEIGHT + (positional_velocity.y * -30) )
		
		velocity.x = 1.5 * -get_floor_normal().x * (-200 + positional_velocity.y * 30)
	position.y -= 3
	state = PlayerState.MIDAIR
	sprite.scale.y = 1.5
	snd_jump.play()
	snd_jump.pitch_scale = 1 + clamp(abs(velocity.x) / 1000, 0.0, 0.200)
	tmr_jumpqueue.stop()

func midair():
	y_inertia = velocity.y
	friction = .99
	floor_angle = 0
	just_now_not_on_wall_only = not is_on_wall_only() and last_not_on_wall_only
	last_not_on_wall_only = is_on_wall_only()
	if just_now_not_on_wall_only: 
		tmr_wallcoyotetime.start()
	
		
	if just_now_not_on_floor: tmr_coyotetime.start()
	
	if not state in [PlayerState.KICK, PlayerState.DIVE, PlayerState.HURT, PlayerState.SPINJUMP]:
		state = PlayerState.MIDAIR
		velocity.y += 14 - (int(Input.is_action_pressed(&"Z")) * 3) + sign(velocity.y) 
	else:
		velocity.y += 14
		if state == PlayerState.SPINJUMP:
			velocity.y -= (int(Input.is_action_pressed(&"X")) * 3) + sign(velocity.y) 
	
	
	if (Input.is_action_just_released(&"Z")) and velocity.y < -100:
		velocity.y = -100
		
	if Input.is_action_just_pressed(&"Z"):
		tmr_jumpqueue.start()
	
	if state == PlayerState.DIVE:
		velocity.x += Input.get_axis(&"left", &"right") * 4
		
	var walljumpangle =  -int(Input.is_action_pressed(&"up"))
	if !pause or tmr_stuntime.is_stopped():
		if (is_on_wall_only() or not tmr_wallcoyotetime.is_stopped()) and (get_wall_normal().x > 0 and not last_walljump_direction == 1 or get_wall_normal().x < 0 and not last_walljump_direction == -1):
			if Input.is_action_just_pressed(&"Z") or not tmr_jumpqueue.is_stopped():
				did_midair_action = false
				snd_kick.play()
				state = PlayerState.MIDAIR
				tmr_jumpqueue.stop()
				sprite.scale.y = 1.35
				velocity.y = JUMP_HEIGHT + (walljumpangle * 30)
				tmr_wallcoyotetime.stop()
				var bleh: int = sign(get_wall_normal().x)
				if bleh != last_walljump_direction:
					last_walljump_direction = bleh
					velocity.x = bleh * RUN_SPEED - walljumpangle * 30

	if is_on_wall_only():
		state = PlayerState.WALLSLIDE
	
	if not is_on_ceiling() and velocity.y < 0: 
		ceiling_hit_velocity = velocity.y 
		
	if is_on_ceiling_only():
		position.y += 2
		velocity.y -= ceiling_hit_velocity / 4
		sprite.scale.y = .9 - ((ceiling_hit_velocity * -1)) / 800
		sprite.scale.x = 1 + ((ceiling_hit_velocity * -1)) / 800
		sprite.position.y =  2 - (ceiling_hit_velocity) / 100
		snd_jump.stop()
		snd_bump.play()



func attackhandler():
	if not is_on_floor():
		if !direction:
			kick()
		else:
			dive()
	else:
		spinjump()

func kick():
	if did_midair_action == false:
		snd_jump.stop()
		snd_kick.play()
		velocity.y = JUMP_HEIGHT 
		position.y -= 3
		velocity.x /= 2
		state = PlayerState.KICK
		did_midair_action = true

func dive():
	if did_midair_action == false:
		snd_jump.stop()
		if Input.is_action_pressed(&"up"):
			velocity.y = JUMP_HEIGHT * 1.3
			velocity.x = 100 * direction
		else:
			velocity.y = JUMP_HEIGHT / 1.5
			velocity.x += 120 * direction
			
		state = PlayerState.DIVE
		did_midair_action = true
		snd_dive.play()

func spinjump():
	snd_spin.play()
	velocity.y = JUMP_HEIGHT
	state = PlayerState.SPINJUMP


var camera_interested_in_pos: Vector2
func interactions(area):
	if area.get_parent() is Coin and area.get_parent().state == 0:
		area.get_parent().state = 1
		global.coins += 1
		global.score += 2
		snd_coin.play()
		if not health >= 3:
			coins_until_hp += 1
		coins_until_hp = clamp(coins_until_hp, 0, 4)
		
		if coins_until_hp >= 4:
			health += 1
			coins_until_hp = 0
			

	if area.name.containsn("cam"):
		camera_interested_in_pos = area.global_position

		
		
	if area is Hurtbox and ((not state == PlayerState.HURT) and tmr_iframes.is_stopped()):
		velocity.x =  directionnotzero * -300
		health -= area.get_owner().DAMAGE
		tmr_stuntime.start()
		sprite.play(&"hurt")
		state = PlayerState.HURT
		velocity.y = -200
		sprite.skew = 0
		sprite.scale.y = 1
		sprite.position = Vector2.ZERO
		direction = 0
		snd_hurt.play()
		snd_jump.stop()

# Timers
func coyotetimetimeout(): 
	can_jump = false
func _on_stuntime_timeout(): 
	tmr_iframes.start()
