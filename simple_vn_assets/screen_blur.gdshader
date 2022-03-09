shader_type canvas_item;

uniform float amount = 0.0;

void fragment() {
	COLOR *= textureLod(SCREEN_TEXTURE, SCREEN_UV, amount) * texture(TEXTURE, UV);
}
