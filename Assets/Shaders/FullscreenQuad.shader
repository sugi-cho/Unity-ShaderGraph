Shader "Unlit/FullscreenQuad"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Background-1000"}
        LOD 100 
        Cull Off
        ZWrite Off Ztest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float2 GetFullScreenTriangleTexCoord(uint vertexID)
            {
            #if UNITY_UV_STARTS_AT_TOP
                return float2((vertexID << 1) & 2, 1.0 - (vertexID & 2));
            #else
                return float2((vertexID << 1) & 2, vertexID & 2);
            #endif
            }

            float4 GetFullScreenTriangleVertexPosition(uint vertexID, float z = UNITY_NEAR_CLIP_VALUE)
            {
                float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
                return float4(uv * 2.0 - 1.0, z, 1.0);
            }

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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v, uint vIdx : SV_VertexID)
            {
                v2f o;
                o.vertex = GetFullScreenTriangleVertexPosition(vIdx);
                o.uv = GetFullScreenTriangleTexCoord(vIdx);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = half4(i.uv, 0,1);
                return col;
            }
            ENDCG
        }
    }
}
