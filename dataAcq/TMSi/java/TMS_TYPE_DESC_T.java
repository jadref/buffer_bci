public class TMS_TYPE_DESC_T
{
  public short Size; // Size in words of this structure
  public short java.lang.Class; // Channel type id code
  public short SubType; // Channel subtype
  public short Format; // Format id
  public float a; // Information for converting bits to units:
  public float b; // Unit  = a * Bits  + b ;
  public byte UnitId; // Id identifying the units
  public byte Exp; // Unit exponent, 3 for Kilo, -6 for micro, etc.
}