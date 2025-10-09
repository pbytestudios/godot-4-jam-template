shader_type canvas_item;

instance uniform float blink: hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(1,1,1,1);

void fragment()
{
    COLOR = mix(COLOR, color * COLOR.a, blink);
}
