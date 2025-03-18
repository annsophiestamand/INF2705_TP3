#version 330 core

in vec2 vertexCoords;
out vec4 FragColor;

uniform sampler2D tex;

void main()
{
    vec4 texColor = texture(tex, vertexCoords);
    FragColor = texColor;
}
