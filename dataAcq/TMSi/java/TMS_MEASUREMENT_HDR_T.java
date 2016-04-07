/** TMS measurement header struct */
public class TMS_MEASUREMENT_HDR_T
{
  public int nsamples; //*< number of samples in this recording
  public time_t startTime = new time_t(); //*< start time
  public time_t endTime = new time_t(); //*< end time
  public int frontendSerialNr; //*< frontendSerial Number
  public short frontendHWNr; //*< frontend Hardware version Number
  public short frontendSWNr; //*< frontend Software version Number
}