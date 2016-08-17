using System;
using System.Collections;

namespace FieldTrip.Buffer
{
	public class WrappedObject {
		public int type;
		public int numel;
		public int size;
		public object array;
		
		public WrappedObject() {
			type  = DataType.UNKNOWN;
			numel = 0;
			size  = 0;
			array = null;
		}
		
		public WrappedObject(string s) {
			type  = DataType.CHAR;
			numel = s.Length;
			size  = numel;
			array = s;
		}
		
		public WrappedObject(double x) {
			type  = DataType.FLOAT64;
			numel = 1;
			size  = 8;
			array = new double[] {x};
		}	
		
		public WrappedObject(float x) {
			type  = DataType.FLOAT32;
			numel = 1;
			size  = 4;
			array = new float[] {x};
		}
		
		public WrappedObject(long x) {
			type  = DataType.INT64;
			numel = 1;
			size  = 8;
			array = new long[] {x};
		}	
		
		public WrappedObject(int x) {
			type  = DataType.INT32;
			numel = 1;
			size  = 4;
			array = new int[] {x};
		}
		
		public WrappedObject(short x) {
			type  = DataType.INT16;
			numel = 1;
			size  = 2;
			array = new short[] {x};
		}
		
		public WrappedObject(byte x) {
			type  = DataType.INT8;
			numel = 1;
			size  = 1;
			array = new byte[] {x};
		}	
		
		public WrappedObject(object obj) {
	
			Type cls = obj.GetType();
			string name = cls.FullName;
	
			if (cls.IsArray) {
				Type elc = cls.GetElementType();
				if (!elc.IsPrimitive) return;
				
				if (name == "System.Double[]") {
					type = DataType.FLOAT64;
					array = ((double[]) obj).Clone();
					numel = ((double[]) obj).Length;
				} else if (name == "System.Single[]") {
					type = DataType.FLOAT32;
					array = ((float[]) obj).Clone();
					numel = ((float[]) obj).Length;
				} else if (name == "System.Int64[]") {
					type = DataType.INT64;
					array = ((long[]) obj).Clone();
					numel = ((long[]) obj).Length;
				} else if (name == "System.Int32[]") {
					type = DataType.INT32;
					array = ((int[]) obj).Clone();
					numel = ((int[]) obj).Length;
				} else if (name == "System.Int16[]") {
					type = DataType.INT16;
					array = ((short[]) obj).Clone();
					numel = ((short[]) obj).Length;
				} else if (name == "System.Byte[]") {
					type = DataType.INT8;
					array = ((byte[]) obj).Clone();
					numel = ((byte[]) obj).Length;
				} else {
					return; // keep as unknown
				}
				size  = numel * DataType.wordSize[type];
				return;
			} else if (name == "System.String") {
				type = DataType.CHAR;
				array = obj;
				numel = ((string) obj).Length;
				size  = numel;
				return;
			} else if (name == "System.Double") {
				type = DataType.FLOAT64;
				array = new double[] {((double) obj)};
			} else if (name == "System.Single") {
				type = DataType.FLOAT32;
				array = new float[] {((float) obj)};
			} else if (name == "System.Int64") {
				type = DataType.INT64;
				array = new long[] {((long) obj)};
			} else if (name == "System.Int32") {
				type = DataType.INT32;
				array = new int[] {((Int32) obj)};
			} else if (name == "System.Int16") {
				type = DataType.INT16;
				array = new short[] {((short) obj)};
			} else if (name == "System.Byte") {
				type = DataType.INT8;
				array = new byte[] {((byte) obj)};		
			} else {
				return;
			}
			numel = 1;
			size  = DataType.wordSize[type];
		}	
			
		public void serialize(ByteBuffer buf) {
			switch(type) {
				case DataType.CHAR:
					buf.putString(array.ToString());
					break;
				case DataType.UINT8:
				case DataType.INT8:
					buf.put((byte[]) array);
					break;
				case DataType.UINT16:
				case DataType.INT16:
					buf.asShortBuffer().put((short[]) array);
					break;
				case DataType.UINT32:
				case DataType.INT32:
					buf.asIntBuffer().put((int[]) array);
					break;
				case DataType.UINT64:
				case DataType.INT64:
					buf.asLongBuffer().put((long[]) array);
					break;
				case DataType.FLOAT32:
					buf.asFloatBuffer().put((float[]) array);
					break;
				case DataType.FLOAT64:
					buf.asDoubleBuffer().put((double[]) array);
					break;
			}
		}	
		
		public string toString() {
			if (type == DataType.CHAR) return (string) array;
			if (type == DataType.FLOAT64) return (((double[]) array)[0]).ToString();
			if (type == DataType.FLOAT32) return (((float[]) array)[0]).ToString();
			if (type == DataType.INT64) return (((long[]) array)[0]).ToString();
			if (type == DataType.INT32) return (((int[]) array)[0]).ToString();
			if (type == DataType.INT16) return (((short[]) array)[0]).ToString();
			if (type == DataType.INT8) return (((byte[]) array)[0]).ToString();
			return array.ToString();
		}
	}
}



