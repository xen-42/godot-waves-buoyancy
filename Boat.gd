extends RigidBody

# Called when the node enters the scene tree for the first time.
var desired_direction = -get_global_transform().basis.z.normalized()

func _ready():
	print(desired_direction)


func _physics_process(delta):
	var basis = get_global_transform().basis
	
	if Input.is_action_pressed("forward"):
		add_central_force(-basis.z * 50)
	if Input.is_action_pressed("left"):
		add_torque(Vector3(0, 300, 0))
	if Input.is_action_pressed("right"):
		add_torque(Vector3(0, -300, 0))


