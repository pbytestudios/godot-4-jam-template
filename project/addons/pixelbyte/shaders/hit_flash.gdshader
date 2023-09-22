shader_type canvas_item;

uniform bool on = false;
uniform float flash_frequency = 10;
uniform vec4 color : source_color = vec4(1,1,1,1);

void fragment() 
{
	if(on){
		vec4 hit_color = color * COLOR.a;
		COLOR = mix(hit_color, COLOR, 0.5 + 0.5 * cos(TAU * flash_frequency * TIME));
	}
}
