Shader "Unlit/DitherMASK"
{
    Properties
    {
        _Alpha("alpha", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler3D _DitherMaskLOD;
            half _Alpha;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                half3 uv = half3(i.uv, _Alpha*.975);
                fixed4 col = tex3D(_DitherMaskLOD, uv).a;
                return col;
            }
            ENDCG
        }

        Pass
        {

            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

                // Render State
                Blend One Zero, One Zero
                Cull Back
                ZTest LEqual
                ZWrite On
                // ColorMask: <None>

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityStandardShadow.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler3D _DitherMaskLOD;
            half _Alpha;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag(v2f i, UNITY_POSITION(vpos)) : SV_Target
            {
                half alpha = _Alpha;
                half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy * 0.25,alpha * 0.9375)).a;
                clip(alphaRef - 0.01);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
