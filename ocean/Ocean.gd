extends Spatial
tool

var time = 0

export var wave_a = Vector3(0.7, 1.0, 10.0) setget set_wave_a
export var wave_a_dir = Vector2(1.0, 0) setget set_wave_a_dir

export var wave_b = Vector3(0.4, 0.4, 16.0) setget set_wave_b
export var wave_b_dir = Vector2(1.0, 1.0) setget set_wave_b_dir

export var wave_c = Vector3(0.8, 0.4, 9) setget set_wave_c
export var wave_c_dir = Vector2(1.0, 0.5) setget set_wave_c_dir

onready var water_scene = preload("res://ocean/Water.tscn")
onready var water_resource = preload("res://ocean/Water.tres")
var water_material

var water_tiles = {}
const water_tile_width = 20

onready var sailboat = $Sailboat
onready var player = $Player

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(-10, 10):
		for j in range(-10, 10):
			var water = water_scene.instance()
			var pos = Vector2(i*water_tile_width, j*water_tile_width)
			add_child(water)
			water.translation.x = pos.x
			water.translation.z = pos.y
			water_tiles[pos] = water
			water.set_surface_material(0, water_resource)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	if water_resource: water_resource.set_shader_param("time", time) 

func _input(event):
	if Input.is_action_just_pressed("interact"):
		sailboat.is_active = not sailboat.is_active
		player.bound_object = sailboat
		player.bound_offset = player.global_transform.origin - sailboat.global_transform.origin
		player.state = player.STATE.SAILING if sailboat.is_active else player.STATE.WALKING

func dot(a, b):
	return (a.x * b.x) + (a.y * b.y)

func P(wave: Vector3, wave_dir: Vector2, p: Vector2, t):
	var amplitude = wave.x
	var steepness = wave.y
	var wavelength = wave.z
	var k = 2.0 * PI / wavelength
	var c = sqrt(9.8 / k)
	var d = wave_dir.normalized()
	var f = k * (dot(d, p) - (c * t))
	var a = steepness / k
	
	var dx = d.x * a * cos(f)
	var dy = amplitude * a * sin(f)
	var dz = d.y * a * cos(f)
	
	return Vector3(dx, dy, dz)

func _get_wave(x, z):
	var v = Vector3(x, 0, z)
	v += P(wave_a, wave_a_dir, Vector2(x, z), time)
	v += P(wave_b, wave_b_dir, Vector2(x, z), time)
	v += P(wave_c, wave_c_dir, Vector2(x, z), time)
	return v

func get_wave(x, z):
	var v0 = _get_wave(x, z)
	var offset = Vector2(x - v0.x, z - v0.z)
	var v1 = _get_wave(x+offset.x/4.0, z+offset.y/4.0)
	
	return v1

func set_wave_a(a):
	wave_a = a
	if water_resource: water_resource.set_shader_param("wave_a", a)

func set_wave_a_dir(a):
	wave_a_dir = a
	if water_resource: water_resource.set_shader_param("wave_a_dir", a)

func set_wave_b(b):
	wave_b = b
	if water_resource: water_resource.set_shader_param("wave_b", b)

func set_wave_b_dir(b):
	wave_b_dir = b
	if water_resource: water_resource.set_shader_param("wave_b_dir", b)

func set_wave_c(c):
	wave_c = c
	if water_resource: water_resource.set_shader_param("wave_c", c)

func set_wave_c_dir(c):
	wave_c_dir = c
	if water_resource: water_resource.set_shader_param("wave_c_dir", c)
