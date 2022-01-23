extends StaticBody
tool

onready var mesh_instance = $MeshInstance

export(OpenSimplexNoise) var noise = OpenSimplexNoise.new() setget set_noise
export var amplitude = 10 setget set_amplitude
export var radius = 100 setget set_radius

# Called when the node enters the scene tree for the first time.
func _ready():
	refresh_mesh()
	if not Engine.editor_hint: mesh_instance.create_trimesh_collision()

func refresh_mesh():
	if not Engine.editor_hint and not mesh_instance:
		return
	var mesh = ArrayMesh.new()
	var plane = PlaneMesh.new()
	plane.subdivide_width = 400
	plane.subdivide_depth = 400
	plane.size = Vector2(400, 400)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		var height = noise.get_noise_2d(vertex.x, vertex.z) * amplitude
		# Outside radius we ramp down
		var r2_max = radius*radius
		var r2 = vertex.x * vertex.x + vertex.z * vertex.z
		if r2 > r2_max:
			var drop_off_dist = 16000
			var delta_h = clamp(r2-r2_max, 0, drop_off_dist)/drop_off_dist*amplitude
			height -= delta_h
		vertex.y += height
		mdt.set_vertex(i, vertex)
	# Calculate vertex normals, face-by-face.
	for i in range(mdt.get_face_count()):
		# Get the index in the vertex array.
		var a = mdt.get_face_vertex(i, 0)
		var b = mdt.get_face_vertex(i, 1)
		var c = mdt.get_face_vertex(i, 2)
		# Get vertex position using vertex index.
		var ap = mdt.get_vertex(a)
		var bp = mdt.get_vertex(b)
		var cp = mdt.get_vertex(c)
		# Calculate face normal.
		var n = (bp - cp).cross(ap - bp).normalized()
		# Add face normal to current vertex normal.
		# This will not result in perfect normals, but it will be close.
		mdt.set_vertex_normal(a, n + mdt.get_vertex_normal(a))
		mdt.set_vertex_normal(b, n + mdt.get_vertex_normal(b))
		mdt.set_vertex_normal(c, n + mdt.get_vertex_normal(c))
	
	# Run through vertices one last time to normalize normals and
	# set color to normal.
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex_normal(i).normalized()
		mdt.set_vertex_normal(i, v)
	
	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)
	mesh_instance.mesh = mesh

func set_noise(n):
	noise = n
	if Engine.editor_hint: refresh_mesh()

func set_amplitude(a):
	amplitude = a
	if Engine.editor_hint: refresh_mesh()

func set_radius(r):
	radius = r
	if Engine.editor_hint: refresh_mesh()
