/** Frontend system info struct */
public class TMS_FRONTENDINFO_T
{
  public short nrofuserchannels; // nr of channels set by host (<=nrofswchannels and >0)
							  // first 'nrofuserchannels' channels of system
							  //  will be sent by frontend (only when supported by frontend software!)
  public short currentsampleratesetting;
  public short mode;
  public short maxRS232; // Maximum RS232 send frequentie in Hz
  public int serialnumber; // System serial number, low uint16_t first
  public short nrEXG; // nr of EXG (unipolar) channels
  public short nrAUX; // nr of BIP and AUX channels
  public short hwversion; // frontend hardware version number
								// hundreds is major part, ones is minor
  public short swversion; // frontend software version number
								// hundreds is major part, ones is minor
  public short cmdbufsize; // number of uint16_ts in frontend receive buffer
  public short sendbufsize; // number of uint16_ts in frontend send buffer
  public short nrofswchannels; // total nr of channels in frontend
  public short basesamplerate; // base sample frequency (in Hz)
  // power and  hardwarecheck not implemented yet, for future use, send 0xFFFF
  public short power;
  public short hardwarecheck;
}