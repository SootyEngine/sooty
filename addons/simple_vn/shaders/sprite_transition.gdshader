shader_type canvas_item;

uniform sampler2D next : hint_white;
uniform float blend : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR = mix(texture(TEXTURE, UV), texture(next, UV), blend);
}
