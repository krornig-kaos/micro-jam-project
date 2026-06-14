shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float saturation : hint_range(0.0, 1.0) = 1.0;
uniform float max_grain_strength : hint_range(0.0, 0.5) = 0.15;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	
	// 1. Desaturar el color original según el progreso
	float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grayscale = vec3(luma);
	vec3 base_color = mix(grayscale, color.rgb, saturation);
	
	// 2. Calcular fuerza de grano dinámica (va a cero cuando la saturación es 1.0)
	float grain_strength = (1.0 - saturation) * max_grain_strength;
	
	// 3. Generar ruido animado pseudo-aleatorio basado en SCREEN_UV y TIME
	vec2 noise_uv = SCREEN_UV + vec2(fract(sin(TIME) * 437.5854), fract(cos(TIME) * 923.1415));
	float noise_val = rand(noise_uv);
	
	// 4. Mezclar el granulado (oscilando entre oscuro/claro alrededor de base_color)
	vec3 final_color = base_color + (noise_val - 0.5) * grain_strength;
	
	COLOR = vec4(final_color, color.a);
}
