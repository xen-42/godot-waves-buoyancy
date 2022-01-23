shader_type spatial;
render_mode depth_draw_always, specular_phong, diffuse_burley, cull_disabled;

uniform vec4 water_colour: hint_color;
uniform vec4 deep_water_colour : hint_color;

// amplitude, steepness, wavelength
uniform vec3 wave_a = vec3(1.0, 1.0, 10.0);
uniform vec2 wave_a_dir = vec2(1.0, 0.0);

uniform vec3 wave_b = vec3(1.0, 0.25, 20.0);
uniform vec2 wave_b_dir = vec2(1.0, 1.0);

uniform vec3 wave_c = vec3(1.0, 0.15, 1.0);
uniform vec2 wave_c_dir = vec2(1.0, 0.5);

uniform sampler2D noise;

uniform float foam_level = 0.4;

uniform float time;

const float PI = 3.14159265358979323;
varying mat4 CAMERA;
varying float wave_height;

void fragment() {
	float depthRaw = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0;
	float water_depth = PROJECTION_MATRIX[3][2] / (depthRaw + PROJECTION_MATRIX[2][2]);
	
	// Normalmaps
	vec2 direction = vec2(-1.0, 0.0);
	NORMALMAP = texture(noise, UV + direction * TIME * 0.05).xyz;
	NORMALMAP_DEPTH = 0.5;
	
	// Refraction
	vec2 offset = vec2(0.0);
//	if (water_depth - VERTEX.z > 0.0) {
//		offset = mix(NORMALMAP.xy - vec2(0.5), NORMAL.xz/10.0, 0.3);
//	}
	
	vec4 bg = texture(SCREEN_TEXTURE, SCREEN_UV + (offset * 0.2));
	float foam_ammount = clamp((foam_level - water_depth - VERTEX.z) / foam_level, 0.0, 1.0);
	vec4 colour = mix(water_colour, deep_water_colour, 1.0-clamp((wave_height)/1.0, 0, 1));
	colour = mix(colour, vec4(1.0), foam_ammount);
	
	float fog_factor = exp(-0.2 * water_depth/20.0);
	
	// Set everything
	EMISSION = mix(colour, bg, fog_factor).xyz * (1.0 - colour.a);
	ALBEDO = colour.xyz;
	ALPHA = 1.0;
	SPECULAR = 0.4;
	ROUGHNESS = 0.05;
}

vec3 gerstnerWave(vec3 wave, vec2 wave_dir, vec3 p, inout vec3 tangent, inout vec3 binormal, float t) {
	float amplitude = wave.x;
	float steepness = wave.y;
	float wavelength = wave.z;
	
	float k = 2.0 * PI / wavelength;
	float c = sqrt(9.8 / k); // phase speed
	vec2 d = normalize(wave_dir);
	float f = k * (dot(d, p.xz) - (c * t));
	float a = steepness / k;
	
	tangent += normalize(vec3(
		1.0 - d.x * d.x * steepness * sin(f),
		d.x * steepness * cos(f),
		-d.x * d.y * (steepness * sin(f))
	));
	binormal += normalize(vec3(
		-d.x * d.y * (steepness * sin(f)),
		d.y * steepness * cos(f),
		1.0 - (d.y * d.y * steepness * sin(f))
	));
	
	return vec3(
		d.x * (a * cos(f)),
		amplitude * a * sin(f),
		d.y * (a * cos(f))
	);
}

void vertex() {
	vec3 original_p = (WORLD_MATRIX * vec4(VERTEX.xyz, 1.0)).xyz;
	vec3 p = VERTEX.xyz;
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	
	p += gerstnerWave(wave_a, wave_a_dir, original_p, tangent, binormal, time);
	p += gerstnerWave(wave_b, wave_b_dir, original_p, tangent, binormal, time);
	p += gerstnerWave(wave_c, wave_c_dir, original_p, tangent, binormal, time);
	
	vec3 normal = normalize(cross(binormal, tangent));
	
	VERTEX = p;
	TANGENT = tangent;
	BINORMAL = binormal;
	NORMAL = normal;
	
	CAMERA = CAMERA_MATRIX;
	wave_height = p.y;
}