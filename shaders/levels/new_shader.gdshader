shader_type canvas_item;

uniform vec2 rect_size = vec2(208.0, 384.0);   // размер ColorRect в пикселях
uniform vec3 left_color : source_color = vec3(0.239, 0.941, 1.0);
uniform vec3 right_color : source_color = vec3(1.0, 0.239, 0.604);

uniform float band_px = 16.0;     // толщина сплошной неоновой стены
uniform float edge_px = 2.0;      // яркая кромка на внутренней границе стены
uniform float glow_px = 24.0;     // свечение, уходящее внутрь коридора
uniform float steps = 6.0;        // ступени яркости (пиксельный вид)
uniform float flow_speed = 40.0;  // скорость импульсов вверх, px/сек
uniform float flow_len = 28.0;    // длина одного импульса

void fragment() {
	vec2 p = UV * rect_size;
	float d_left = p.x;
	float d_right = rect_size.x - p.x;
	float d = min(d_left, d_right);
	vec3 col = d_left < d_right ? left_color : right_color;

	float in_band = 1.0 - step(band_px, d);

	// стена: темнее у края экрана, ярче к коридору
	float t = clamp(d / band_px, 0.0, 1.0);
	float tone = floor(mix(0.30, 0.90, t) * steps) / steps;

	// импульсы бегут вверх по стене
	float flow = 0.5 + 0.5 * sin((p.y + TIME * flow_speed) / flow_len * 6.28318);
	flow = floor(flow * 3.0) / 3.0;
	tone *= 0.8 + 0.2 * flow;

	// раскалённая кромка
	float edge = in_band * step(band_px - edge_px, d);

	// свечение в коридор
	float g = clamp(1.0 - (d - band_px) / glow_px, 0.0, 1.0);
	g = floor(pow(g, 2.0) * steps) / steps;
	g *= (1.0 - in_band);

	vec3 rgb = col * tone;
	rgb = mix(rgb, vec3(1.0), edge * 0.7);

	float a = in_band * 0.95 + g * 0.55;
	COLOR = vec4(rgb, a);
}