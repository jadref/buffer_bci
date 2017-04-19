package nl.dcc.buffer_bci;


// TODO: convert to non java8 version
import java.util.Date;

/** TMS measurement header struct */
public class TMS_MEASUREMENT_HDR_T
{
  public int nsamples; //*< number of samples in this recording
  public Date startTime = new java.util.Date(); //*< start time
  public Date endTime = new java.util.Date(); //*< end time
  public int frontendSerialNr; //*< frontendSerial Number
  public short frontendHWNr; //*< frontend Hardware version Number
  public short frontendSWNr; //*< frontend Software version Number
}
