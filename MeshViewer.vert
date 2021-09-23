#version 330

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 normal;

/*
uniform mat4 mvMatrix;
uniform mat4 mvpMatrix;
uniform mat4 norMatrix;
uniform vec4 lightPos;
*/
 
out float diffTerm;
out vec2 texCoords;
out Vertex
{
  vec3 normal;
  vec2 texCoords;
} vertex;


void main()
{
	vertex.normal = normal;
	gl_Position = vec4(vec3(position), 1);
}