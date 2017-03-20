package nl.dcc.buffer_bci;

public class TMS_ACKNOWLEDGE_T
{
   public short descriptor;
	 // received blockdescriptor (type+size) being acknowledged
   public short errorcode;
}
