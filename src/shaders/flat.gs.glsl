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

float calcSpotIntensity(vec3 sDir, vec3 lDir, vec3 norm, float cosAngle, float cosFalloff)
{
    float normDot = dot(sDir, norm);
    if(normDot < 0.0) return 0.0;
    
    float spotDot = dot(lDir, sDir);
    
    if(useDirect3D) {
        return smoothstep(cosFalloff, cosAngle, spotDot);
    } else {
        return spotDot > cosAngle ? pow(spotDot, spotExponent) : 0.0;
    }
}

void calcLightComponents(int idx, vec3 norm, vec3 lDir, vec3 vDir, out vec3 diff, out vec3 spec)
{
    float diffFactor = max(dot(norm, lDir), 0.0);
    diff = diffFactor * lights[idx].diffuse * mat.diffuse;
    
    float specFactor;
    if(useBlinn) {
        vec3 halfVec = normalize(lDir + vDir);
        specFactor = max(dot(norm, halfVec), 0.0);
    } else {
        vec3 reflectVec = reflect(-lDir, norm);
        specFactor = max(dot(vDir, reflectVec), 0.0);
    }
    
    specFactor = pow(specFactor, mat.shininess);
    spec = specFactor * lights[idx].specular * mat.specular;
}

void main()
{
    vec3 edge1 = attribIn[1].position - attribIn[0].position;
    vec3 edge2 = attribIn[2].position - attribIn[0].position;
    vec3 faceNormal = cross(edge1, edge2);
    
    vec3 faceCenter = (attribIn[0].position + attribIn[1].position + attribIn[2].position) * 0.333333;
    vec3 normalView = normalize(normalMatrix * faceNormal);
    vec4 centerView = modelView * vec4(faceCenter, 1.0);
    vec3 viewDir = normalize(-centerView.xyz);
    
    float cosAngleLimit = cos(radians(spotOpeningAngle));
    float cosFalloff = pow(cosAngleLimit, 1.01 + spotExponent / 2.0);
    
    vec3 lightVectors[3];
    vec3 spotVectors[3];
    vec3 diffuseResults[3];
    vec3 specularResults[3];
    float spotIntensities[3];
    
    vec3 ambientTotal = mat.ambient * (lightModelAmbient + 
                      lights[0].ambient + 
                      lights[1].ambient + 
                      lights[2].ambient);
    
    vec3 diffuseTotal = vec3(0.0);
    vec3 specularTotal = vec3(0.0);
    
    for(int i = 0; i < 3; i++) {
        lightVectors[i] = normalize((view * vec4(lights[i].position, 1.0)).xyz - centerView.xyz);
        spotVectors[i] = normalize(mat3(view) * -lights[i].spotDirection);
        
        calcLightComponents(i, normalView, lightVectors[i], viewDir, diffuseResults[i], specularResults[i]);
        
        spotIntensities[i] = useSpotlight ? 
            calcSpotIntensity(spotVectors[i], lightVectors[i], normalView, cosAngleLimit, cosFalloff) : 1.0;
        
        diffuseTotal += diffuseResults[i] * spotIntensities[i];
        specularTotal += specularResults[i] * spotIntensities[i];
    }
    
    for(int i = 0; i < gl_in.length(); i++) {
        gl_Position = gl_in[i].gl_Position;
        attribOut.texCoords = attribIn[i].texCoords;
        attribOut.emission = mat.emission;
        attribOut.ambient = ambientTotal;
        attribOut.diffuse = diffuseTotal;
        attribOut.specular = specularTotal;
        EmitVertex();
    }
    EndPrimitive();
}
