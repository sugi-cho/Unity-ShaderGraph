//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

void MainLight_half(float3 WorldPos, out half3 Direction, out half3 Color, out half DistanceAtten, out half ShadowAtten)
{
#ifdef SHADERGRAPH_PREVIEW
    Direction = normalize(half3(-1,1,-1));
    Color = half3(1,1,1);
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
#ifdef SHADERGRAPH_PREVIEW
    Diffuse = 0;
    Specular = 0;
#else
    half3 diffuseColor = 0;
    half3 specularColor = 0;
 
    Smoothness = exp2(10 * Smoothness + 1);
    WorldNormal = normalize(WorldNormal);
    WorldView = SafeNormalize(WorldView);
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, WorldPosition, half4(1,1,1,1));
        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
        diffuseColor += LightingLambert(attenuatedLightColor, light.direction, WorldNormal);
        specularColor += LightingSpecular(attenuatedLightColor, light.direction, WorldNormal, WorldView, half4(SpecColor, 0), Smoothness);
    }
 
    Diffuse = diffuseColor;
    Specular = specularColor;
#endif
}

sampler3D _DitherMaskLOD;
void DitheringShadow_half(half alpha, half2 screenPos, bool shadowCascaded, out half outAlpha, out half clipThreshold)
{
    outAlpha = alpha;
    clipThreshold = 0;
#if (!defined(SHADERGRAPH_PREVIEW))
    {
        half2 vpos = screenPos * _MainLightShadowmapSize.z;
        vpos *= shadowCascaded ? 0.5 : 1;
        outAlpha = tex3D(_DitherMaskLOD, float3(vpos.xy * 0.25, alpha * 0.9375)).a;
        clipThreshold = 0.5;
    }
#endif
}

void SimpleLit_half(
half3 positionWS, half3 normalWS,half2 uv1, half2 uv2, half3 viewDirectionWS,
half3 diffuse, half4 specular, half smoothness, half3 emission,
out half4 color)
{
#ifdef SHADERGRAPH_PREVIEW
    color = 1;
#else
    smoothness = exp2(10 * smoothness + 1);
    half4 positionCS = TransformWorldToHClip(positionWS);
    half cascadeIndex = ComputeCascadeIndex(positionWS);
    half4 shadowCoord = mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS, 1.0));
    
    InputData inputData;
    inputData.positionWS = positionWS;
    inputData.normalWS = normalWS;
    inputData.viewDirectionWS = viewDirectionWS;
    inputData.shadowCoord = shadowCoord;
    inputData.fogCoord = ComputeFogFactor(positionCS.z);
    inputData.vertexLighting = half3(0, 0, 0);
    inputData.bakedGI = shadergraph_LWBakedGI(positionWS, normalWS, uv1, uv2, true);
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(positionCS);
    inputData.shadowMask = half4(1, 1, 1, 1);
    
    color = UniversalFragmentBlinnPhong(inputData, diffuse, specular, smoothness, emission, 1.);
#endif

}