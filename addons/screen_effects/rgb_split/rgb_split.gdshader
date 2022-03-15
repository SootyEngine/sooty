shader_type canvas_item;

uniform float dist : hint_range(0.0, 8.0) = 2.0;
uniform float blur : hint_range(0.0, 2.0) = 0.5;

void fragment() {
	COLOR.r = textureLod(SCREEN_TEXTURE, SCREEN_UV-SCREEN_PIXEL_SIZE*vec2(dist, 1.0), blur).r;
	COLOR.g = textureLod(SCREEN_TEXTURE, SCREEN_UV+SCREEN_PIXEL_SIZE*vec2(dist, 1.0), blur).g;
	COLOR.b = textureLod(SCREEN_TEXTURE, SCREEN_UV, 2.0).b;
}
