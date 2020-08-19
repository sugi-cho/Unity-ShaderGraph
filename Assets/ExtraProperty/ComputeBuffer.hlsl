struct myData
{
    half3 pos;
    half4 color;
};
uniform StructuredBuffer<myData> _MyData;

void GetColor_half(uint idx, out half4 outColor)
{
    outColor = _MyData[idx].color;
}