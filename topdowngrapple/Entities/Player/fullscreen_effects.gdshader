shader_type canvas_item;

void fragment() {
	vec2 cp=-1.0+2.0*FRAGCOORD.xy*(1.0/SCREEN_PIXEL_SIZE).xy;
	float cl=length(cp);
	vec2 uv=(FRAGCOORD.xy/(1.0/SCREEN_PIXEL_SIZE).xy)+(cp/cl)*cos(cl*5.0-TIME*8.0)*.02;
	vec3 col=texture(TEXTURE, uv).xyz;
	COLOR=vec4(col, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
