#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texCoords;

out ATTRIB_OUT
{
    vec3 position;
    vec2 texCoords;
} attribOut;

uniform mat4 modelView;
uniform mat4 mvp;

void main()
{
    vec4 posView = modelView * vec4(position, 1.0);
    gl_Position = mvp * vec4(position, 1.0);
    attribOut.texCoords = texCoords;
    attribOut.position  = position.xyz;
}
