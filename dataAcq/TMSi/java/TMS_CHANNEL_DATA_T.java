public class TMS_CHANNEL_DATA_T
{
  public int ns; //*< number of samples in 'data'
  public int rs; //*< already received samples in 'data'
  public int sc; //*< sample counter
  public double td; //*< tick duration [s]
//C++ TO JAVA CONVERTER TODO TASK: The typedef 'tms_data_t' was defined in multiple preprocessor conditionals and cannot be replaced in-line:
  public tms_data_t data; //*< data samples
}