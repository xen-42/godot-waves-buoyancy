extends RigidBody

onready var camera = $Head/Camera
onready var camera_base = $Head
onready var ground_ray_cast = $GroundRayCast
onready var state_label = $Head/Camera/StateLabel
onready var ocean = get_node("/root/Ocean")

var camera_x_rotation = 0

const mouse_sensitivity = 0.3
const SPEED = 10
const SPRINT_MOD = 2
var jump_impulse = 10

var paused = false

enum STATE {
	FLOATING,
	DIVING,
	WALKING,
	SAILING
}

var bound_object = null
var bound_offset = Vector2()

var state = STATE.WALKING

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Mouse movement
	if not paused:
		if event is InputEventMouseMotion:
			camera_base.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
			
			var x_delta = event.relative.y * mouse_sensitivity
			if camera_x_rotation + x_delta > -90 and camera_x_rotation + x_delta < 90:
				camera.rotate_x(deg2rad(-x_delta))
				camera_x_rotation += x_delta

func grounded():
	return ground_ray_cast.is_colliding()

func _integrate_forces(physics_state):
	# State machine
	state = swap_state()
	
	if not paused:
		var acc = Vector3()
		var direction = Vector3()
		var camera_base_basis = camera.get_global_transform().basis
		var mod = SPRINT_MOD if Input.is_action_pressed("sprint") else 1
		
		if Input.is_action_pressed("forward"):
			direction -= camera_base_basis.z #forward is negative in Godot
		if Input.is_action_pressed("backward"):
			direction += camera_base_basis.z
		
		# Strafe
		if Input.is_action_pressed("left"):
			direction -= camera_base_basis.x
		if Input.is_action_pressed("right"):
			direction += camera_base_basis.x
		
		match state:
			STATE.WALKING:
				if Input.is_action_just_pressed("jump") and grounded():
					physics_state.apply_central_impulse(Vector3.UP * jump_impulse)
				else:
					# Process inputs (only in the xz plane
					acc.x = direction.x * SPEED * mod
					acc.z = direction.z * SPEED * mod
				if not grounded():
					acc.y = -weight
			STATE.DIVING:
				# Process inputs in all directions
				acc = direction * SPEED * mod
			STATE.FLOATING:
				physics_state.add_central_force(Vector3.DOWN * 9.8)
	
				var wave = ocean.get_wave(translation.x, translation.z)
				var wave_height = wave.y
				var height = translation.y
				
				acc = direction * SPEED * mod
				
				if height < wave_height:
					var buoyancy = clamp((wave_height - height) / 0.001, 0, 1) * 5
					physics_state.add_central_force(Vector3(0, 9.8 * buoyancy, 0))
					#physics_state.add_central_force(buoyancy * -physics_state.linear_velocity * 0.5)
					#physics_state.add_torque(buoyancy * -physics_state.angular_velocity * 0.5)
			STATE.SAILING:
				self.transform = bound_object.transform
				self.translate(bound_offset)
		
		physics_state.add_central_force(acc * mass)

func swap_state():
	var wave_height = ocean.get_wave(translation.x, translation.z).y
	var new_state = state
	match state:
		STATE.WALKING:
			# Are we in water
			if translation.y < wave_height:
				if linear_velocity.y < -5:
					new_state = STATE.DIVING
				else:
					new_state = STATE.FLOATING
		STATE.DIVING:
			# Are we on or above water
			if translation.y >= wave_height:
				new_state = STATE.FLOATING
		STATE.FLOATING:
			if grounded():
				new_state = STATE.WALKING
			if translation.y < wave_height - 0.1:
				new_state = STATE.DIVING
	
	return new_state

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	state_label.text = "%s" % STATE.keys()[state]

func toggle_pause():
	paused = !paused
	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
