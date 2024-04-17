shader_type canvas_item;

uniform sampler2D wipe_texture;
uniform float dissolve_value : hint_range(0.0, 1.0, 0.05);
uniform vec4 wipe_color : source_color;
//If true, then we ignore the wipe texture and do a simple alpha fade where alpha= dissolve_value
uniform bool use_alpha = false;

void fragment() {
	vec4 texColor = texture(TEXTURE, UV);
	vec4 dissolve_color = texture(wipe_texture, UV);
	float mask = 1.0 - (dissolve_color.r + dissolve_color.g + dissolve_color.b + dissolve_color.a) / 4.0;

	if (use_alpha) {
		COLOR.rgba = vec4(wipe_color.rgb, dissolve_value);
	}
	else if (mask >= dissolve_value) {
		COLOR.rgba = vec4(wipe_color.rgb, 0.0);
	}
	else {
		COLOR.rgba = wipe_color;
	}
}
