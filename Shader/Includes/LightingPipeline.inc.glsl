#pragma once

#pragma include "Includes/Configuration.inc.glsl"
#pragma include "Includes/Structures/Material.struct.glsl"
#pragma include "Includes/LightCulling.inc.glsl"
#pragma include "Includes/Lights.inc.glsl"
#pragma include "Includes/LightTypes.inc.glsl"
#pragma include "Includes/BRDF.inc.glsl"

uniform isampler2DArray CellIndices;
uniform isamplerBuffer PerCellLights;
uniform samplerBuffer AllLightsData;

uniform vec3 cameraPosition;

vec3 shade_material_from_tile_buffer(Material m, ivec3 tile) {
    
    // Find per tile lights
    int cellIndex = texelFetch(CellIndices, tile, 0).x;
    int dataOffs = cellIndex * (MAX_LIGHTS_PER_CELL+1);
    int numLights = min(MAX_LIGHTS_PER_CELL, texelFetch(PerCellLights, dataOffs).x);

    vec3 shadingResult = vec3(0);

    // Compute view vector
    vec3 v = normalize(cameraPosition - m.position);

        
    // Iterate over all lights
    for (int i = 0; i < numLights; i++) {

        // Fetch light ID
        int lightOffs = texelFetch(PerCellLights, dataOffs + i + 1).x * 4;

        // Fetch per light packed data
        vec4 data0 = texelFetch(AllLightsData, lightOffs + 0);
        vec4 data1 = texelFetch(AllLightsData, lightOffs + 1);
        vec4 data2 = texelFetch(AllLightsData, lightOffs + 2);
        vec4 data3 = texelFetch(AllLightsData, lightOffs + 3);

        // Extract common light data, which is equal for each light type
        int lightType = int(data0.x);
        vec3 lightPos = data0.yzw;
        vec3 lightColor = data1.xyz;

        float attenuation = 0;
        vec3 l = vec3(0);

        // Special handling for different light types
        if (lightType == LT_POINT_LIGHT) {
            float radius = data1.w;
            float innerRadius = data2.x;
            innerRadius = 2.0;
            attenuation = computePointLightAttenuation(radius, distance(m.position, lightPos));
            l = normalize(lightPos - m.position);
        }

        shadingResult += applyLight(m, v, l, lightColor, attenuation, 1.0);


    }

    return shadingResult;
}