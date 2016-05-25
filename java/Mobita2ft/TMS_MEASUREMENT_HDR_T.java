package Mobita2ft;


import java.time.Instant;
import java.time.LocalDateTime;

/** TMS measurement header struct */
public class TMS_MEASUREMENT_HDR_T
{
  public int nsamples; //*< number of samples in this recording
  public LocalDateTime startTime = LocalDateTime.now(); //*< start time
  public LocalDateTime endTime = LocalDateTime.now(); //*< end time
  public int frontendSerialNr; //*< frontendSerial Number
  public short frontendHWNr; //*< frontend Hardware version Number
  public short frontendSWNr; //*< frontend Software version Number
}
