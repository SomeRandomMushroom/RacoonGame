shader_type canvas_item;

uniform vec2 deformation = vec2(0, 0);
uniform float sideWaysDeformationFactor = 5.0;
uniform float knockbackFactor = 2.0;

void vertex() {
	vec2 deformationStrength = abs(deformation);
	float sideWaysDeformation = min(deformationStrength.x, deformationStrength.y);
	float spriteWidth = abs(VERTEX.x);
	if (sign(VERTEX.y) == sign(deformation.y)) {
		VERTEX.x += sideWaysDeformation * sideWaysDeformationFactor * spriteWidth * sign(deformation.x);
	}
	vec2 scale = 1.0 - deformationStrength;

	VERTEX.x *= scale.x / scale.y;
	VERTEX.y *= scale.y / scale.x;
	//VERTEX.xy=deformation*spriteWidth*knockbackFactor;
	//VERTEX.xy += (knockbackFactor*(-vec2(deformation.y, deformation.x)));//(vec2(deformationStrength.y, deformationStrength.x)));
}