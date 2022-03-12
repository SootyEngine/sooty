shader_type canvas_item;

uniform float scale : hint_range(1.0, 1000.0) = 1000.0;
uniform float ss1 : hint_range(0.0, 1.0) = 0.3;
uniform float ss2 : hint_range(0.0, 1.0) = 0.8;
uniform float density : hint_range(0.1, 4.0) = 2.0;
uniform sampler2D noise : hint_white, repeat_enable;

// https://www.shadertoy.com/view/Mt2cRd
void fragment() {
	vec2 mul = vec2(0.25 , 8.0);
	float time_scale = -TIME * 3.0;
	float rotation = 0.0;//sin(TIME) / 10.0;
	vec2 add = vec2(time_scale, rotation);
	vec2 uv = (UV - .5) * 32.0;
	vec2 ppos = vec2(length(uv), atan(uv.y, uv.x)/TAU);
	vec2 fpos = (vec2(-sqrt(1.0/ppos.x), ppos.y) + add) * mul;
	COLOR.a *= smoothstep(0.1, 0.7, texture(noise, fpos).r);
}