// Converted/modified from ShaderToy: https://www.shadertoy.com/view/ldBXDD
// And GodotShader: https://godotshaders.com/shader/vignette-3/
// Attach this shader to a ColorRect

shader_type canvas_item;

uniform bool on=true;

uniform float wave_count : hint_range(1.0, 20.0, 1.0) = 20.0;
uniform float speed : hint_range(-50.0, 50.0, 0.1) = 3.0;
uniform float height : hint_range(0.0, 0.1, 0.001) = 0.003;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest_mipmap;
uniform float time_offset=0.0;

uniform float outerRadius : hint_range(0.0, 5.0) = 1.0;
uniform float MainAlpha : hint_range(0.0, 1.0) = 1.0;
uniform vec4 vignette_color: source_color;

void fragment() {
	if (on){
		vec2 cPos = -1.0 + 2.0 * UV / (1.0 / TEXTURE_PIXEL_SIZE);
		float cLength = length(cPos);
		vec2 uv = FRAGCOORD.xy / (1.0 / SCREEN_PIXEL_SIZE).xy + (cPos/cLength) * cos(cLength * wave_count - (TIME * speed+1.0-time_offset*speed)) * height;
	    vec3 col = texture(SCREEN_TEXTURE, uv).xyz;
		//COLOR = vec4(col,1.0);

		float x = abs(UV.x-.5)*2.0;	float y = abs(UV.y-.5)*2.0;
		float v = (sqrt((x*x)+(y*y))/outerRadius);
		COLOR = vec4(col, 1.0)+vec4(vignette_color.rgb,v*MainAlpha);
	} else {
		COLOR=vec4(0);
	}
}