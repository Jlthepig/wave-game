shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Wave parameters
uniform float wave_speed = 2.0;
uniform float wave_height = 0.15;
uniform float wave_frequency = 1.5;

// Cartoon colors - vibrant and saturated
uniform vec4 deep_color : source_color = vec4(0.05, 0.3, 0.65, 0.85);
uniform vec4 shallow_color : source_color = vec4(0.2, 0.55, 0.85, 0.7);
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);

// Textures
uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

// Depth foam (around objects)
uniform float edge_foam_distance : hint_range(0.0, 2.0) = 0.5;
uniform float edge_foam_falloff : hint_range(1.0, 20.0) = 5.0;

// Surface foam
uniform float foam_scale = 6.0;
uniform float foam_threshold : hint_range(0.0, 1.0) = 0.65;
uniform float foam_speed = 0.4;

// Stylization
uniform int color_bands : hint_range(2, 8) = 3;
uniform float specular_strength : hint_range(0.0, 2.0) = 0.8;
uniform float specular_size : hint_range(0.0, 1.0) = 0.3;

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Multiple wave layers
    float wave = 0.0;
    wave += sin(world_position.x * wave_frequency + TIME * wave_speed) * wave_height;
    wave += cos(world_position.z * wave_frequency * 1.3 - TIME * wave_speed * 1.1) * wave_height * 0.7;
    wave += sin((world_position.x - world_position.z) * wave_frequency * 0.8 + TIME * wave_speed * 0.6) * wave_height * 0.4;
    
    VERTEX.y += wave;
}

void fragment() {
    // === DEPTH-BASED FOAM ===
    float scene_depth = texture(depth_texture, SCREEN_UV).x;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, scene_depth);
    vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view_pos.xyz /= view_pos.w;
    float linear_depth = -view_pos.z;
    
    float fragment_depth = -VERTEX.z;
    float depth_difference = linear_depth - fragment_depth;
    
    // Create foam at edges
    float edge_foam = 1.0 - smoothstep(0.0, edge_foam_distance, depth_difference);
    edge_foam = pow(edge_foam, edge_foam_falloff);
    
    // === SURFACE FOAM (animated) ===
    // Two layers of noise moving in different directions
    vec2 uv1 = world_position.xz / foam_scale + vec2(TIME * foam_speed * 0.5, TIME * foam_speed * 0.3);
    vec2 uv2 = world_position.xz / foam_scale * 1.4 - vec2(TIME * foam_speed * 0.3, -TIME * foam_speed * 0.4);
    
    float noise1 = texture(noise_texture, uv1).r;
    float noise2 = texture(noise_texture, uv2).r;
    float foam_noise = noise1 * 0.6 + noise2 * 0.4;
    
    // Add more variation with third layer
    vec2 uv3 = world_position.xz / (foam_scale * 2.0) + vec2(-TIME * foam_speed * 0.2);
    float noise3 = texture(noise_texture, uv3).r;
    foam_noise = foam_noise * 0.8 + noise3 * 0.2;
    
    // Create foam patches
    float surface_foam = step(foam_threshold, foam_noise);
    
    // Soften edges slightly
    surface_foam = smoothstep(foam_threshold - 0.05, foam_threshold + 0.05, foam_noise);
    
    // Add foam to edges
    float total_foam = clamp(edge_foam + surface_foam * 0.5, 0.0, 1.0);
    
    // === WATER COLOR (cartoon style) ===
    // Use depth for color variation
    float depth_factor = clamp(depth_difference / 3.0, 0.0, 1.0);
    
    // Posterize for cel-shading
    depth_factor = floor(depth_factor * float(color_bands)) / float(color_bands);
    
    vec3 water_base = mix(shallow_color.rgb, deep_color.rgb, depth_factor);
    
    // === FAKE SPECULAR HIGHLIGHT (cartoon style) ===
    vec3 view_dir = normalize(VIEW);
    vec3 light_dir = normalize(vec3(0.5, 1.0, 0.3)); // Fake sun direction
    
    // Simple Blinn-Phong for cartoon highlight
    vec3 normal = normalize(NORMAL);
    vec3 half_dir = normalize(view_dir + light_dir);
    float spec = pow(max(dot(normal, half_dir), 0.0), 32.0);
    spec = smoothstep(specular_size, specular_size + 0.1, spec) * specular_strength;
    
    // === FINAL COLOR ===
    vec3 final_color = mix(water_base, foam_color.rgb, total_foam);
    final_color += vec3(spec) * (1.0 - total_foam); // Add specular to water only
    
    ALBEDO = final_color;
    ALPHA = mix(shallow_color.a, 1.0, total_foam);
    ROUGHNESS = mix(0.1, 0.9, total_foam);
}