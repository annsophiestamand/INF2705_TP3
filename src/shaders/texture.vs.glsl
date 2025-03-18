#version 330 core

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec2 in_vertexCoords;

out vec2 vertexCoords;

uniform mat4 mvp;

void main()
{
    gl_Position = mvp * vec4(in_position, 1.0);
    vertexCoords = in_vertexCoords;
}

