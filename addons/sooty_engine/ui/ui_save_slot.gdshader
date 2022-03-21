shader_type canvas_item;

uniform float zoom = 1.0;

void fragment() {
	
	float x = length(UV.x - .5) * 2.0 * 1.0;
	float y = length(UV.y - .5) * 2.0 * 1.2;
	float t = smoothstep(0.5, 0.6, max(x, y));
	COLOR = texture(TEXTURE, UV * (1.0 + zoom * .1));
	COLOR.a *= 1.0 - t;
}
