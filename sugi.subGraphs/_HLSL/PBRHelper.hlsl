//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"


inline void InitializeBRDFData_(half3 albedo, half metallic, half3 specular, half smoothness, half alpha, out BRDFData outBRDFData)
{
    half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    half reflectivity = 1.0 - oneMinusReflectivity;

    outBRDFData = (BRDFData) 0;
    outBRDFData.diffuse = albedo * oneMinusReflectivity;
    outBRDFData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);

    outBRDFData.grazingTerm = saturate(smoothness + reflectivity);
    outBRDFData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    outBRDFData.roughness = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN);
    outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;

    outBRDFData.normalizationTerm = outBRDFData.roughness * 4.0h + 2.0h;
    outBRDFData.roughness2MinusOne = outBRDFData.roughness2 - 1.0h;
}

void GetLightingPBR_half(half3 positionWS, half3 normalWS, half3 viewWS,
     half3 base, half metallic, half smoothness, out half3 outColor
)
{
#if SHADERGRAPH_PREVIEW
    outColor = 1;
#else    
    BRDFData brdfData = (BRDFData)0;
    InitializeBRDFData_(base, metallic, 0., smoothness, 1., brdfData);
    half cascadeIndex = ComputeCascadeIndex(positionWS);
    half4 shadowCoord = mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS, 1.0)); //TransformWorldToShadowCoord(WorldPos);
    float3 bakedGI = float3(0, 0, 0);
    
    Light mainLight = GetMainLight(shadowCoord);
    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half shadowStrength = GetMainLightShadowStrength();
    mainLight.shadowAttenuation = SampleShadowmap(shadowCoord, TEXTURE2D_ARGS(_MainLightShadowmapTexture,
            sampler_MainLightShadowmapTexture),
            shadowSamplingData, shadowStrength, false);

    half3 color = GlobalIllumination(brdfData, bakedGI, 1.0, normalWS, viewWS)
                + LightingPhysicallyBased(brdfData, mainLight, normalWS, viewWS);
    
#ifndef SHADERGRAPH_PREVIEW
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, positionWS);
        color += LightingPhysicallyBased(brdfData, light, normalWS, viewWS);
    }

    outColor = color;
#endif
#endif
}
