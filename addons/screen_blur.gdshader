shader_type canvas_item;

uniform float blur : hint_range(0.0, 4.0) = 1.0;

void fragment() {
	COLOR *= textureLod(SCREEN_TEXTURE, SCREEN_UV, blur);
}
