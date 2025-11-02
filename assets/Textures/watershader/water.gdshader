shader_type spatial;
render_mode unshaded;

uniform float wave_speed = 1.0;
uniform float wave_height = 0.3;
uniform float wave_frequency = 2.0;
uniform vec4 deep_color : source_color = vec4(0.0, 0.2, 0.5, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.1, 0.4, 0.7, 1.0);

void vertex() {
	VERTEX.y += sin(VERTEX.x * wave_frequency + TIME * wave_speed) * wave_height;
	VERTEX.y += cos(VERTEX.z * wave_frequency + TIME * wave_speed) * wave_height;
}

void fragment() {
	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, UV.y);
}
