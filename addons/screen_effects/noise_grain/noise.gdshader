shader_type canvas_item;

uniform float noise = 512.0;
uniform float time_scale : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
	float lum = dot(vec3(0.30, 0.59, 0.11), screen.rgb);
	vec2 uv = SCREEN_UV;
	uv.y *= (SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y );
	uv = round(uv * noise);
	float n = fract(sin(dot(uv, vec2(12.9898 + TIME * mix(.00001, .002, time_scale), 78.233))) * 43758.5453);
	COLOR.rgb = vec3(pow(lum, n * .75)) * screen.rgb;
}
