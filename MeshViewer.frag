#version 330

uniform int wireMode;
uniform int flag;
uniform sampler2D pencilStroke[3];
uniform int NPRMode;

in float diffTerm;
in vec2 texCoords;
in vec4 twoToneColor;
in vec3 texVec;
in flat int definitionEdge;

out vec4 FragColor;

vec4 getTexColor() 
{
	//return colour of primitive based on texture vector
	//apply textures
	vec4 lightShade = texture(pencilStroke[0], texCoords);
	vec4 midShade = texture(pencilStroke[1], texCoords);
	vec4 darkShade = texture(pencilStroke[2], texCoords);

	vec4 texColor = (lightShade * texVec.x) + (midShade * texVec.y) + (darkShade * texVec.z);

	return texColor;
}

void main() 
{
	vec4 lineColor = vec4(0, 0, 0, 1); //black sillhouette line color
	vec4 color = twoToneColor; //assume two tone NPRMode

	if (wireMode == 1)   //Wireframe
	{
		color = vec4(0, 0, 1, 1); //blue wireframe
	}
	else			//Fill + lighting
	{
		if (NPRMode == 1) { //1st pass
			color = getTexColor(); //pencil stroke rendering
		}
		if (diffTerm == -1)
		{
			color = vec4(0, 0, 0, 1); // crease/silhouette line
		}
	}

	vec4 diffVect = vec4(diffTerm, diffTerm, diffTerm, 1);
    vec4 grey = vec4(0.2, 0.2, 0.2, 0.2);

	FragColor = color * (diffVect + grey);
}