shader_type canvas_item;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float d = 0.5 - length(UV - .5);
	COLOR *= textureLod(SCREEN_TEXTURE, SCREEN_UV, 1.0) * tex;
}
