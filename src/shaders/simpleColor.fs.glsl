#version 330 core

uniform sampler2D grid_texture;
out vec4 FragColor;

void main()
{
    vec2 texCoords = gl_FragCoord.xy / 100.0;
    vec4 texColor = texture(grid_texture, texCoords);

    vec3 tintColor = vec3(0.25, 0.8, 1.0);
    FragColor = vec4(texColor.rgb * tintColor, texColor.a);
}
