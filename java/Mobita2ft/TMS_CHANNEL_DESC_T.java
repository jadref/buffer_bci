package nl.dcc.buffer_bci;

public class TMS_CHANNEL_DESC_T
{
//C++ TO JAVA CONVERTER TODO TASK: The typedef 'tms_type_desc_t' was defined in multiple preprocessor conditionals and cannot be replaced in-line:
	public TMS_TYPE_DESC_T Type = new TMS_TYPE_DESC_T(); // channel type descriptor
	public String ChannelDescription; // String pointer identifying the channel
	public float GainCorrection; // Optional gain correction
	public float OffsetCorrection; // Optional offset correction
}
