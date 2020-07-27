//#include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"


void GetLightingPBR_half(half3 positionWS, half3 normalWS, half3 viewWS,
     half3 base, half metallic, half smoothness, out half3 outColor
)
{
#if SHADERGRAPH_PREVIEW
    outColor = 1;
#else    
    BRDFData brdfData;
    InitializeBRDFData(base, metallic, 0., smoothness, 1., brdfData);
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
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

void MainLight_half(float3 WorldPos, out half3 Direction, out half3 Color, out half DistanceAtten, out half ShadowAtten)
{
#if SHADERGRAPH_PREVIEW
    Direction = half3(0.5,0.5,0);
    Color = 1;
    DistanceAtten = 1;
    ShadowAtten = 1;
#else
    
    half cascadeIndex = ComputeCascadeIndex(WorldPos);
    half4 shadowCoord = mul(_MainLightWorldToShadow[cascadeIndex], float4(WorldPos, 1.0)); //TransformWorldToShadowCoord(WorldPos);
    Light mainLight = GetMainLight(shadowCoord);
    Direction = mainLight.direction;
    Color = mainLight.color;
    DistanceAtten = mainLight.distanceAttenuation;
 
    //ShadowAtten = mainLight.shadowAttenuation;
 
    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half shadowStrength = GetMainLightShadowStrength();
    ShadowAtten = SampleShadowmap(shadowCoord, TEXTURE2D_ARGS(_MainLightShadowmapTexture,
            sampler_MainLightShadowmapTexture),
            shadowSamplingData, shadowStrength, false);
#endif
}

void AdditionalLights_half(half3 SpecColor, half Smoothness, half3 WorldPosition, half3 WorldNormal, half3 WorldView, out half3 Diffuse, out half3 Specular)
{
    half3 diffuseColor = 0;
    half3 specularColor = 0;
 
#ifndef SHADERGRAPH_PREVIEW
    Smoothness = exp2(10 * Smoothness + 1);
    WorldNormal = normalize(WorldNormal);
    WorldView = SafeNormalize(WorldView);
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, WorldPosition);
        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
        diffuseColor += LightingLambert(attenuatedLightColor, light.direction, WorldNormal);
        specularColor += LightingSpecular(attenuatedLightColor, light.direction, WorldNormal, WorldView, half4(SpecColor, 0), Smoothness);
    }
#endif
 
    Diffuse = diffuseColor;
    Specular = specularColor;
}

sampler3D _DitherMaskLOD;
void DitheringShadow_half(half alpha, half2 screenPos, bool shadowCascaded, out half outAlpha, out half clipThreshold)
{
    outAlpha = alpha;
    clipThreshold = 0;
#ifdef SHADERPASS_SHADOWCASTER
    half2 vpos = screenPos * _MainLightShadowmapSize.z;
    vpos *= shadowCascaded? 0.5 : 1;
    outAlpha = tex3D(_DitherMaskLOD, float3(vpos.xy * 0.25, alpha * 0.9375)).a;
    clipThreshold = 0.5;
#endif
}