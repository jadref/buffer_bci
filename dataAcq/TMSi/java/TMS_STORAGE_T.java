/** TMS storage type struct */
public class TMS_STORAGE_T
{
  public byte ref; //*< reference channel nr. 0...63 and -1 none
  public byte deci; //*< decimation 0,1,3,7,15,63,127 or 255
  public byte delta; //*< delta 0:no storage 1: 8 bit delta 2: 16 bit delta 3: 24 bit data
  public byte shift; //*< shift delta==3 -> 0, delta==2 -> 0..6, delta==1 -> 0..14
  public int period; //*< sample period
  public int overflow; //*< overflow value
}