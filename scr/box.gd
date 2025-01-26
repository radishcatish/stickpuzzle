extends Grabbable
@onready var area_2d: Area2D = $Area2D
func _ready() -> void:
	hold_height = -36
func _physics_process(delta: float) -> void:

	if being_held: 
		area_2d.monitorable = false
		return
	
	area_2d.monitorable = true
	velocity.y += 900 * delta
	if is_on_floor():
		velocity.x *= .9 
	move_and_slide()
	
