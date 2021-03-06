shader_type canvas_item;
render_mode unshaded,blend_mix;

uniform vec3 modulator = vec3(1.0);
uniform float power = 1.0;

vec2 wave(vec2 uv, float time, float speed, float waves)
{
	vec2 pos;
	pos.x = uv.x + sin(time + uv.y / waves) * speed * power;
	pos.y = uv.y + cos(time + uv.x / waves) * speed * power;
	return pos;
}


void fragment()
{
	COLOR = min(texture(TEXTURE,wave(UV,TIME,0.5,2.0)),texture(TEXTURE,wave(UV,TIME,0.7,1.0)));
	COLOR.rgb *= modulator;
}