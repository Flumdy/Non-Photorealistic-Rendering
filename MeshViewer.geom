#version 400

layout (triangles_adjacency) in;
layout (triangle_strip, max_vertices = 6) out;

uniform sampler2D pencilStroke[3];
uniform mat4 mvMatrix;
uniform mat4 mvpMatrix;
uniform mat4 norMatrix;
uniform vec3 lightPos;
uniform vec4 eyePos;

in Vertex
{
  vec3 normal;
} vertex[];

out vec3 texVec;
out vec2 texCoords;
out vec4 twoToneColor;
out float diffTerm;

void getTexVec() 
{
	//returns texture combination based on diffTerm

	vec3 texWeight = vec3(0, 0, 1);
	if (diffTerm > -0 && diffTerm < 0.05)
	{
		texWeight = vec3(0, 0.5, 0.5);
	}
	else if (diffTerm >= 0.05 && diffTerm < 0.1)
	{
		texWeight = vec3(0, 0.75, 0.25);
	}
	else if (diffTerm >= 0.1 && diffTerm < 0.6) 
	{
		texWeight = vec3(0, 1, 0);
	}
	else if (diffTerm >= 0.6 && diffTerm < 0.65)
	{
		texWeight = vec3(0.25, 0.75, 0);
	}
	else if (diffTerm >= 0.65 && diffTerm < 0.7)
	{
		texWeight = vec3(0.5, 0.5, 0);
	}
	else if (diffTerm >= 0.7 && diffTerm < 0.75)
	{
		texWeight = vec3(0.75, 0.25, 0);
	}
	else if (diffTerm >= 0.75)
	{
		texWeight = vec3(1, 0, 0);
	}
	texVec = texWeight;
}

void getTwoTone() 
{
	//returns color of object based on diffTerm
	twoToneColor = vec4(0.2, 0.2, 0.2, 1); //ambient
	if (diffTerm > 0 && diffTerm < 0.7) 
	{
		twoToneColor = vec4(0.5, 0.5, 0, 1); //midterm
	}
	else if (diffTerm >= 0.7) 
	{
		twoToneColor = vec4(1, 1, 0, 1); //material colour
	}
}

vec4 surfaceNormal(vec4 P1, vec4 P2, vec4 P3)
{
	vec4 V1 = (mvMatrix * P2) - (mvMatrix * P1);
	vec4 V2 = (mvMatrix * P3) - (mvMatrix * P1);
	float normx = (V1.y * V2.z) - (V1.z * V2.y);
	float normy = (V1.z * V2.x) - (V1.x * V2.z);
	float normz = (V1.x * V2.y) - (V1.y * V2.x);

	return vec4(normx, normy, normz, 1);
}

void drawCrease(vec4 mainSurfNorm, vec4 adjTriNorm, vec4 adjacentVec, vec4 currentVec)
{

	//get angle between two face normals
	float dotP = dot(adjTriNorm, mainSurfNorm);
	float magA = sqrt((mainSurfNorm.x * mainSurfNorm.x) + (mainSurfNorm.y * mainSurfNorm.y) + (mainSurfNorm.z * mainSurfNorm.z));
	float magB = sqrt((adjTriNorm.x * adjTriNorm.x) + (adjTriNorm.y * adjTriNorm.y) + (adjTriNorm.z * adjTriNorm.z));
	float angle = acos(dotP / (magA * magB));
	angle = angle * 180 / 3.1415; //convert from radians to degrees
	
	if (angle < 3) {
		//create and emit new vertices and primitive
		//variables as seen lecture[6] - slide 26
		//first side
		vec4 U = normalize(currentVec - adjacentVec);
		vec4 V = normalize(adjTriNorm + mainSurfNorm);
		float W = normalize((U.x + U.y + U.z) * (V.x + V.y + V.z));
		float offSet = 1;
		
		vec4 vert1 = adjacentVec + (V * offSet) + (W * offSet);
		gl_Position = mvpMatrix * vert1;
		EmitVertex();

		vec4 vert2 = adjacentVec + (V * offSet) - (W * offSet);
		gl_Position = mvpMatrix * vert2;
		EmitVertex();


		//second side
		U = normalize(adjacentVec - currentVec);
		W = normalize((U.x + U.y + U.z) * (V.x + V.y + V.z));

		vec4 vert3 = currentVec + (V * offSet) + (W * offSet);
		gl_Position = mvpMatrix * vert3;
		EmitVertex();

		vec4 vert4 = currentVec + (V * offSet) - (W * offSet);
		gl_Position = mvpMatrix * vert4;
		EmitVertex();

		EndPrimitive();
	}
}

float getAngle(vec4 V1, vec4 V2)
{
	//get angle between two vectors
	float dotP = dot(V1, V2);
	float magA = sqrt((V1.x * V1.x) + (V1.y * V1.y) + (V1.z * V1.z));
	float magB = sqrt((V2.x * V2.x) + (V2.y * V2.y) + (V2.z * V2.z));
	float angle = acos(dotP / (magA * magB));
	angle = angle * 180 / 3.1415; //convert from radians to degrees

	return angle;
}

void drawSilhouette(vec4 mainSurfNorm, vec4 adjTriNorm, vec4 adjacentVec, vec4 currentVec, vec4 previousVec) 
{
	//draw all valid silhouette edges
	vec4 mainTriPos = vec4((adjacentVec + currentVec + previousVec) / 3);
	vec4 eyeVect = mainTriPos - eyePos;

	
	if (mainSurfNorm.z > 0 && adjTriNorm.z <= 0) //if one edge facing and the other not
	{
		vec4 v = normalize(mainSurfNorm + adjTriNorm);

		vec4 vert1 = adjacentVec + 0.001 * v;
		gl_Position = mvpMatrix * vert1;
		EmitVertex();

		vec4 vert2 = adjacentVec + 0.03 * v;
		gl_Position = mvpMatrix * vert2;
		EmitVertex();

		vec4 vert3 = currentVec + 0.001 * v;
		gl_Position = mvpMatrix * vert3;
		EmitVertex();

		vec4 vert4 = currentVec + 0.03 * v;
		gl_Position = mvpMatrix * vert4;
		EmitVertex();

		EndPrimitive();
	}

}

void main()
{
	
	for (int i = 0; i < gl_in.length(); i = i + 2) //for each vertex in main triangle (every 2nd)
	{
		// lighting
		vec4 posn = gl_in[i].gl_Position;
		vec4 posnEye = mvMatrix * vec4(vec3(posn), 1);
		vec4 normalEye = norMatrix * vec4(vertex[i].normal.xyz, 0);
		vec3 unitNormal = normalize(normalEye.xyz);
		vec3 lgtVec = normalize(lightPos.xyz - posnEye.xyz); 

		diffTerm = max(dot(lgtVec, unitNormal), 0.2);

		//texture coords
		if (i == 0)
		{
			texCoords = vec2(0, 0);
		}
		if (i == 2) {
			texCoords = vec2(0.5, 0);
		} 
		else if (i == 4) {
			texCoords = vec2(0.25, 0.5);
		}

		//texture vecter for assigning texture by weight
		getTexVec();

		//two tone color assignment
		getTwoTone();

		gl_Position = mvpMatrix * posn;

		EmitVertex();
	}
	EndPrimitive();


	//add crease and silhouette edges
	vec4 mainSurfNorm = surfaceNormal(gl_in[0].gl_Position, gl_in[2].gl_Position, gl_in[4].gl_Position);
	for (int i = 0; i < gl_in.length(); i = i + 2)
	{
		diffTerm = -1;
		vec4 currentVec = gl_in[i].gl_Position;
		vec4 oppositeVec = gl_in[(i + 1) % 6].gl_Position;
		vec4 adjacentVec = gl_in[(i + 2) % 6].gl_Position;
		vec4 previousVec = gl_in[(i + 4) % 6].gl_Position;
		vec4 adjTriNorm = surfaceNormal(currentVec, oppositeVec, adjacentVec);

		//drawCrease(mainSurfNorm, adjTriNorm, adjacentVec, currentVec);
		drawSilhouette(mainSurfNorm, adjTriNorm, adjacentVec, currentVec, previousVec);
	}
}