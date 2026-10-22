// The wire's look (Wire sets the uniforms). Default: the plain line. Flow, unpowered: the same
// line at dim_strength. Flow, powered: dashes scrolling away from the root at
// current_speed_px_s. pulse_progress 0 to 1 draws a bright band moving away from the root, in
// any mode; at 1 or more it is hidden. Uses only features the Compatibility renderer supports.
// The look values (dash_px to band_px) are placeholder art for the owner to change.
// Serves AC V-02, V-03.
shader_type canvas_item;

// The line's length in px; Line2D's STRETCH texture mode maps UV.x 0 to 1 along it.
uniform float length_px = 1.0;
uniform bool powered = false;
uniform bool flow_mode = false;
uniform float pulse_progress = 1.0;
// True when the line's last point is nearer the root than its first.
uniform bool root_at_end = false;
uniform float current_speed_px_s = 48.0;
uniform float dash_px = 6.0;
uniform float gap_px = 6.0;
uniform float dim_strength = 0.35;
uniform float band_px = 12.0;

void fragment() {
	// COLOR is already the line's color times the white strip texture.
	vec4 look = COLOR;
	float from_root = (root_at_end ? 1.0 - UV.x : UV.x) * length_px;
	if (flow_mode) {
		float strength = dim_strength;
		if (powered) {
			float phase = mod(from_root - TIME * current_speed_px_s, dash_px + gap_px);
			strength = phase < dash_px ? 1.0 : dim_strength;
		}
		look.a *= strength;
	}
	if (pulse_progress < 1.0) {
		float front = pulse_progress * (length_px + band_px);
		if (from_root <= front && from_root > front - band_px) {
			look = vec4(mix(look.rgb, vec3(1.0), 0.8), COLOR.a);
		}
	}
	COLOR = look;
}
