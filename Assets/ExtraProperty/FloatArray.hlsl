#define DataCount 32
float _Array[DataCount];

void GetData_float(uint idx, out float val)
{
    val = _Array[idx];
}