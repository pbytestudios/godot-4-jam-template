shader_type canvas_item;

uniform sampler2D wipe_texture;
uniform float dissolve_value : hint_range(0.0, 1.0, 0.05);
uniform vec4 wipe_color : source_color;

void fragment() {
	vec4 texColor = texture(TEXTURE, UV);
	vec4 dissolve_color = texture(wipe_texture, UV);
	float mask = 1.0 - (dissolve_color.r + dissolve_color.g + dissolve_color.b + dissolve_color.a) / 4.0;

	if (mask >= dissolve_value) {
		COLOR.rgba = vec4(texColor.rgb, 0.0);
	}
	else {
		COLOR.rgba = wipe_color;
	}
}
