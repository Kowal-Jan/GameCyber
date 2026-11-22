shader_type canvas_item;

void fragment() {
	float top = smoothstep(0.2, 0.0, UV.y);
	float bot = smoothstep(0.78, 1.0, UV.y);
	vec3 neon = mix(vec3(1.0, 0.18, 0.55), vec3(0.1, 0.85, 1.0), UV.y);
	COLOR = vec4(neon, (top + bot) * 0.16);
}
