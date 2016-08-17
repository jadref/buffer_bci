using System;
using System.Collections;

namespace FieldTrip.Buffer
{
	public class DataType {
		public  const  int UNKNOWN = -1;
		public  const  int CHAR    = 0;
		public  const  int UINT8   = 1;
		public  const  int UINT16  = 2;
		public const  int UINT32  = 3;
		public const  int UINT64  = 4;
		public const  int INT8    = 5;
		public const  int INT16   = 6;
		public const  int INT32   = 7;
		public const  int INT64   = 8;
		public const  int FLOAT32 = 9;
		public const  int FLOAT64 = 10;
	
		public static readonly  int[] wordSize = {1,1,2,4,8,1,2,4,8,4,8};
		
		public static object getObject(int type, int numel, ByteBuffer buf) {
			switch(type) {
				case CHAR:
					byte[] strBytes = new byte[numel];
					buf.get(ref strBytes);
					System.Text.Encoding encoding = buf.encoding();
					string val = encoding.GetString(strBytes, 0, strBytes.Length);
					return val;
					
				case INT8:
					goto case UINT8;
				case UINT8:
					byte[] int8array = new byte[numel];
					buf.get(ref int8array);
					return (object)int8array;
					
				case INT16:
					goto case UINT16;
				case UINT16:
					short[] int16array = new short[numel];
					// The following would be faster, but DOES NOT
					// increment the position of the original ByteBuffer!!!
					// buf.asShortBuffer().get(int16array);
					for (int i=0;i<numel;i++) int16array[i] = buf.getShort();
					return (object)int16array;
	
				case INT32:
				 goto case UINT32;
				case UINT32:
					int[] int32array = new int[numel];
					for (int i=0;i<numel;i++) int32array[i] = buf.getInt();
					return (object)int32array;
					
				case INT64:
					goto case UINT64;
				case UINT64:
					long[] int64array = new long[numel];
					for (int i=0;i<numel;i++) int64array[i] = buf.getLong();
					return (object)int64array;	
					
				case FLOAT32:
					float[] float32array = new float[numel];
					for (int i=0;i<numel;i++) float32array[i] = buf.getFloat();
					return (object)float32array;			
	
				case FLOAT64:
					double[] float64array = new double[numel];
					for (int i=0;i<numel;i++) float64array[i] = buf.getDouble();
					return (object)float64array;			
	
				default:
					return null;
			}
		}
	}	
}