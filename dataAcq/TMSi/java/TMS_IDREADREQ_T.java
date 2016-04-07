//C++ TO JAVA CONVERTER TODO TASK: The typedef 'tms_frontendinfo_t' was defined in multiple preprocessor conditionals and cannot be replaced in-line:
//C++ TO JAVA CONVERTER NOTE: The following #define macro was replaced in-line:
//ORIGINAL LINE: #define TMSFRONTENDINFOSIZE (sizeof(tms_frontendinfo_t))


public class TMS_IDREADREQ_T
{
  public short startaddress; // start adress in de buffer with ID data;
									// 4 MSB bits Device number
  public short length; // amount of words requested;
									// length <= max_length = 0x80 = 128 words
}