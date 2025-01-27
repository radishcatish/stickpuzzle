extends Grabbable
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	super()
	hold_height = -48
	sliding.pitch_scale = .9
	
@onready var land: AudioStreamPlayer2D = $land
@onready var sliding: AudioStreamPlayer2D = $sliding

var last_on_floor := false
var just_now_on_floor := false
func _physics_process(delta: float) -> void:
	just_now_on_floor = is_on_floor() and not last_on_floor
	last_on_floor = is_on_floor()

	if being_held: 
		area_2d.monitorable = false
		collision_shape_2d.disabled = false
		velocity = Vector2.ZERO
		move_and_slide()
		return
		

		
	if just_now_on_floor: land.play()
	area_2d.monitorable = true
	velocity.y += 900 * delta
	if is_on_floor():
		velocity.x *= .9 
		if (abs(velocity.x) > 10 and not sliding.playing):
			
			sliding.play()

	move_and_slide()
