#version 330 core

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in ATTRIB_OUT
{
    vec3 position;
    vec2 texCoords;
} attribIn[];

out ATTRIB_VS_OUT
{
    vec2 texCoords;    
    vec3 emission;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
} attribOut;

uniform mat4 view;
uniform mat4 modelView;
uniform mat3 normalMatrix;

struct Material
{
    vec3 emission;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

struct UniversalLight
{
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    vec3 position;
    vec3 spotDirection;
};

layout (std140) uniform LightingBlock
{
    Material mat;
    UniversalLight lights[3];
    vec3 lightModelAmbient;
    bool useBlinn;
    bool useSpotlight;
    bool useDirect3D;
    float spotExponent;
    float spotOpeningAngle;
};


void main()
{
    vec3 p0 = attribIn[0].position;
    vec3 p1 = attribIn[1].position;
    vec3 p2 = attribIn[2].position;
    vec3 N = normalize(cross(p1 - p0, p2 - p0));
    vec3 center = (p0 + p1 + p2) / 3.0;
    vec3 centerView = (modelView * vec4(center, 1.0)).xyz;
    vec3 normalView = normalize(normalMatrix * N);
    vec3 V = normalize(-centerView);
    vec3 ambientSum = vec3(0.0);
    vec3 diffuseSum = vec3(0.0);
    vec3 specularSum = vec3(0.0);
    for (int i = 0; i < 3; i++) {
        vec3 lightPosition = (view * vec4(lights[i].position, 1.0)).xyz;
        vec3 L = normalize(lightPosition - centerView);
        float NdotL = max(dot(normalView, L), 0.0);
        vec3 ambient = mat.ambient * lights[i].ambient;
        vec3 diffuse = mat.diffuse * lights[i].diffuse * NdotL;
        vec3 specular = vec3(0.0);
        if (NdotL > 0.0) {
            if (useBlinn) {
                vec3 H = normalize(L + V);
                specular = mat.specular * lights[i].specular * pow(max(dot(normalView, H), 0.0), mat.shininess);
            } else {
                vec3 R = reflect(-L, normalView);
                specular = mat.specular * lights[i].specular * pow(max(dot(V, R), 0.0), mat.shininess);
            }
        }
        if (useSpotlight) {
            vec3 spotDir = normalize((view * vec4(lights[i].spotDirection, 0.0)).xyz);
            float cosGamma = dot(-L, spotDir);
            float cosDelta = cos(radians(spotOpeningAngle));
            if (cosGamma > cosDelta) {
                float factor;
                if (useDirect3D) {
                    float cosOuter = pow(cosDelta, 1.01 + spotExponent/2.0);
                    factor = smoothstep(cosOuter, cosDelta, cosGamma);
                } else {
                    factor = pow(cosGamma, spotExponent);
                }
                ambient *= factor;
                diffuse *= factor;
                specular *= factor;
            } else {
                ambient = diffuse = specular = vec3(0.0);
            }
        }
        ambientSum += ambient;
        diffuseSum += diffuse;
        specularSum += specular;
    }
    for (int i = 0; i < 3; i++) {
        attribOut.texCoords = attribIn[i].texCoords;
        attribOut.emission = mat.emission;
        attribOut.ambient = ambientSum;
        attribOut.diffuse = diffuseSum;
        attribOut.specular = specularSum;
        gl_Position = gl_in[i].gl_Position;
        EmitVertex();
    }
    EndPrimitive();
}
