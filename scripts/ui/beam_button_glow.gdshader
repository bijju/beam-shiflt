shader_type canvas_item;
render_mode blend_add;
// Energy beam travelling clockwise around a rounded-rect outline. One progress value, no textures.

uniform vec2 rect_size = vec2(830.0, 280.0);
uniform float corner_radius = 70.0;
uniform float edge_inset = 10.0;
uniform float beam_progress : hint_range(0.0, 1.0) = 0.0;
uniform float beam_width : hint_range(0.001, 0.3) = 0.035;
uniform float beam_softness = 14.0;
uniform float beam_strength : hint_range(0.0, 3.0) = 0.0;
uniform float trail_length : hint_range(0.0, 0.5) = 0.16;
uniform float base_glow : hint_range(0.0, 1.0) = 0.22;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D art_tex : filter_linear;
uniform vec4 art_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 beam_color : source_color = vec4(0.2, 0.85, 1.0, 1.0);

// distance from top-centre, clockwise, to right-centre for a point on the top-right quadrant boundary
float quad_s(vec2 n, float a, float b, float qa) {
	float dx = n.x - a;
	float dy = n.y + b;
	if (dx > 0.0 && dy < 0.0) {
		return a + qa * atan(dx, -dy) / 1.5707963;
	}
	if (dy >= 0.0) {
		return a + qa + dy;
	}
	return n.x;
}

void fragment() {
	vec2 h = rect_size * 0.5;
	vec2 p = UV * rect_size - h;
	float r = min(corner_radius, min(h.x, h.y) - 1.0);
	vec2 hi = h - vec2(edge_inset);
	float ri = max(r - edge_inset, 1.0);
	vec2 q = abs(p) - (hi - vec2(ri));
	float sdf = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - ri;

	float a = hi.x - ri;
	float b = hi.y - ri;
	float qa = 1.5707963 * ri;
	float Q = a + qa + b;
	float L = 4.0 * Q;

	// nearest boundary point, mirrored into the top-right quadrant
	vec2 m = abs(p);
	vec2 qq = m - vec2(a, b);
	vec2 n;
	if (qq.x > 0.0 && qq.y > 0.0) {
		n = vec2(a, b) + normalize(qq) * ri;
	} else if (qq.x > qq.y) {
		n = vec2(hi.x, min(m.y, b));
	} else {
		n = vec2(min(m.x, a), hi.y);
	}
	n.y = -n.y;
	float f = quad_s(n, a, b, qa);
	float s;
	if (p.x >= 0.0 && p.y < 0.0) {
		s = f;
	} else if (p.x >= 0.0) {
		s = Q + (Q - f);
	} else if (p.y >= 0.0) {
		s = 2.0 * Q + f;
	} else {
		s = 3.0 * Q + (Q - f);
	}
	float u = s / L;

	float radial = exp(-pow(sdf / beam_softness, 2.0));
	float arc = (qq.x > 0.0 && qq.y > 0.0) ? 1.0 : 0.0;

	float behind = mod(beam_progress - u + 1.0, 1.0);
	float ahead = min(behind, 1.0 - behind);
	float head = exp(-pow(ahead / beam_width, 2.0));
	float trail = behind < trail_length ? pow(1.0 - behind / max(trail_length, 0.0001), 2.0) * 0.55 : 0.0;
	float beam = (head + trail) * beam_strength;
	beam *= 1.0 + 0.7 * arc * head;

	float glow = base_glow * (0.7 + 0.3 * arc) + flash * 0.6;
	vec3 hot = mix(beam_color.rgb, vec3(1.0), clamp(head * beam_strength, 0.0, 1.0) * 0.45);
	float k = radial * (glow + beam);
	// keep the light on the visible art only (the chamfered corners are transparent in the PNG)
	k *= smoothstep(0.35, 0.95, texture(art_tex, art_rect.xy + UV * art_rect.zw).a);
	COLOR = vec4(hot, clamp(k, 0.0, 1.0));
}
