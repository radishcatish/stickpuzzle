extends Grabbable
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	super()
	hold_height = -36
	

func _physics_process(delta: float) -> void:
	print(being_held)
	if being_held: 
		area_2d.monitorable = false
		collision_shape_2d.disabled = true
		velocity = Vector2.ZERO
		move_and_slide()
		return
		

		

	area_2d.monitorable = true
	velocity.y += 900 * delta
	if is_on_floor():
		velocity.x *= .9 
		
	collision_shape_2d.disabled = false
	move_and_slide()
