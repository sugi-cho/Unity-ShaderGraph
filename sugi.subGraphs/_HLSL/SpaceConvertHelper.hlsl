void viewportToLocal_half(float3 viewportPos, out float3 localPos)
{
    float n = _ProjectionParams.y;
    float f = _ProjectionParams.z;
				
    float w = viewportPos.z;
    float z = w * (2 * (w - n) / (f - n) - 1);
    float2 xy = w * (2 * viewportPos.xy - 1);
    float4 viewPos = mul(unity_CameraInvProjection, float4(xy, z, w));
    viewPos.w = 1;
    localPos = mul(viewPos, UNITY_MATRIX_IT_MV).xyz;
}

void viewToClip_half(float3 viewPos, out float4 clipPos) 
{
    clipPos = TransformWViewToHClip(viewPos);
}

void clipToView_half(float4 clipPos, out float3 viewPos)
{
    viewPos = mul(UNITY_MATRIX_I_P, clipPos);
}