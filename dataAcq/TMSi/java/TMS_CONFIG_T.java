/** TMS config struct */
public class TMS_CONFIG_T
{
  public short version; //*< PC Card protocol version number 0x0314
  public short hdrSize; //*< size of measurement header 0x0200
  public short fileType; //*< File Type (0: .ini 1: .smp 2:evt)
  public int cfgSize; //*< size of config.ini  0x400
  public short sampleRate; //*< File Type (0: .ini 1: .smp 2:evt)
  public short nrOfChannels; //*< number of channels
  public int startCtl; //*< start control
  public int endCtl; //*< end control
  public short cardStatus; //*< card status
  public int initId; //*< Initialisation Identifier
  public short sampleRateDiv; //*< Sample Rate Divider
  public short mindecimation; //*< Minimum Decimantion of all channels
//C++ TO JAVA CONVERTER TODO TASK: The typedef 'tms_storage_t' was defined in multiple preprocessor conditionals and cannot be replaced in-line:
  public tms_storage_t[] storageType = new tms_storage_t[64]; //*< Storage Type
  public byte[] fileName = new byte[12]; //*< Measurement file name
  public time_t alarmTime = new time_t(); //*< alarm time
  public byte[] info = new byte[700]; //*< patient of measurement info
}