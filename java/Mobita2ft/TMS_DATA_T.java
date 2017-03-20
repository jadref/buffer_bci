package nl.dcc.buffer_bci;

public class TMS_DATA_T
{
  public float sample; //*< real sample value
  public int isample; //*< integer representation of sample
  public int flag; //*< sample status: 0x00: ok 0x01: overflow
}
