shader_type canvas_item;
// should be a black and white gradient texture
uniform sampler2D wipe_texture;
// if = 1.0, then no texture is used and the wipe is alpha
uniform float wipe_alpha_only:hint_range(0.0, 1.0, 1.0) = 1.0;
uniform float progress:hint_range(0.0, 1.0, 0.05) = 0.5;
uniform vec4 wipe_color : source_color;

void fragment() {
	vec4 dissolve_color = texture(wipe_texture, UV);
	float mask = 1.0 - (dissolve_color.r + dissolve_color.g + dissolve_color.b + dissolve_color.a) / 4.0;

	vec4 texture_wipe = mix(wipe_color, COLOR, step(progress, mask));
	vec4 alpha_wipe = vec4(wipe_color.rgb, progress);
	COLOR = mix(texture_wipe, alpha_wipe, wipe_alpha_only);
}
