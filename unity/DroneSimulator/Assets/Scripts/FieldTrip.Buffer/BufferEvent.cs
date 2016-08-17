using System.Collections;
using System.Linq;
using System.Text;

namespace FieldTrip.Buffer
{	
	public class 
	BufferEvent {
		public BufferEvent() {
			wType  = new WrappedObject();
			wValue = new WrappedObject();
			sample     = -1;
			offset     = 0;
			duration   = 0;
		}
		
		public BufferEvent(string type, string value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}
		
		public BufferEvent(string type, long value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}		
		
		public BufferEvent(string type, int value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}	
		
		public BufferEvent(string type, short value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}	
		
		public BufferEvent(string type, byte value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}	
		
		public BufferEvent(string type, double value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}	
	
		public BufferEvent(string type, float value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}		
		
		//--- Arrays ----------
		public BufferEvent(string type, string[] value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}
		
		public BufferEvent(string type, long[] value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}		
		
		public BufferEvent(string type, int[] value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}	
		
		public BufferEvent(string type, short[] value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}	
		
		public BufferEvent(string type, byte[] value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}	
		
		public BufferEvent(string type, double[] value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}	
	
		public BufferEvent(string type, float[] value, int sample) {
			wType  = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}		
		
		
		
		public BufferEvent(ByteBuffer buf) {
			wType  = new WrappedObject();
			wValue = new WrappedObject();	
			
			wType.type   = buf.getInt();
			wType.numel  = buf.getInt();
			wValue.type  = buf.getInt();
			wValue.numel = buf.getInt();
			sample       = buf.getInt();
			offset       = buf.getInt();
			duration     = buf.getInt();
			int size = buf.getInt();
		
			wType.array  = DataType.getObject(wType.type, wType.numel, buf);
			if (wType.array != null) {
				wType.size = wType.numel * DataType.wordSize[wType.type];
			}
			
			wValue.array = DataType.getObject(wValue.type, wValue.numel, buf);
			if (wValue.array != null) {
				wValue.size = wValue.numel * DataType.wordSize[wValue.type];
			}
			
			size -= wType.size + wValue.size;
			if (size != 0) {
				buf.position(buf.position() + size);
			}
		}
		
		public WrappedObject getType() {
			return wType;
		}
		
		public WrappedObject getValue() {
			return wValue;
		}	
		
		public bool setType(object typeObj) {
			wType = new WrappedObject(typeObj);
			return wType.type != DataType.UNKNOWN;
		}
		
		public bool setValue(object valueObj) {
			wValue = new WrappedObject(valueObj);
			return wValue.type != DataType.UNKNOWN;
		}
		
		public bool setValueUnsigned(byte[] array) {
			wValue = new WrappedObject();
			wValue.array = array.Clone();
			wValue.numel = array.Length;
			wValue.size  = array.Length;
			wValue.type  = DataType.UINT8;
			return true;
		}
	
		public int size() {
			return 32 + wType.size + wValue.size;
		}
		
		public static int count(ByteBuffer buf) {
			int num = 0;
			long pos = buf.position();
		
			while (buf.remaining() >= 32) {
				int typeType   = buf.getInt();
				int typeNumEl  = buf.getInt();
				int valueType  = buf.getInt();
				int valueNumEl = buf.getInt();
				buf.getInt(); // sample
				buf.getInt(); // offset
				buf.getInt(); // duration
				int size = buf.getInt();
				int sizeType  = typeNumEl  * DataType.wordSize[typeType];
				int sizeValue = valueNumEl * DataType.wordSize[valueType];
			
				if (sizeType < 0 || sizeValue < 0 || sizeType + sizeValue > size) {
					return -(1+num);
				}
			
				buf.position(buf.position() + size);
				num++;
			}
			buf.position(pos);
			return num;
		}
		
		public void serialize(ByteBuffer buf) {
			buf.putInt(wType.type);
			buf.putInt(wType.numel);
			buf.putInt(wValue.type);
			buf.putInt(wValue.numel);
			buf.putInt(sample);
			buf.putInt(offset);
			buf.putInt(duration);
			buf.putInt(wType.size+wValue.size);
			wType.serialize(buf);
			wValue.serialize(buf);
		}
		
		//For a general C# application change the UnityEngine.Debug.Log() with System.Console.WriteLine()
		public void print() {
			System.Console.WriteLine("-------Begin Event Printout-------");
			System.Console.WriteLine("Sample registered = "+sample.ToString());
			System.Console.WriteLine("Type = "+wType.array.ToString());
	
			string result="";
			if ( wValue.array is string){
				result = wValue.array as string;
			}
			if ( wValue.array is byte[]){
				byte[] val;
				val = wValue.array as byte[];
				foreach(var i in val) result+=i.ToString()+", ";
			}
			if ( wValue.array is short[]){
				short[] val;
				val = wValue.array as short[];
				foreach(var i in val) result+=i.ToString()+", ";
			}
			if ( wValue.array is int[]){
				int[] val;
				val = wValue.array as int[];
				foreach(var i in val) result+=i.ToString()+", ";
			}
			if ( wValue.array is long[]){
				long[] val;
				val = wValue.array as long[];
				foreach(var i in val) result+=i.ToString()+", ";
			}
			if ( wValue.array is float[]){
				float[] val;
				val = wValue.array as float[];
				foreach(var i in val) result+=i.ToString()+", ";
			}
			if ( wValue.array is double[]){
				double[] val;
				val = wValue.array as double[];
				foreach(var i in val) result+=i.ToString()+", ";
			}
			System.Console.WriteLine("Value = "+result);
			System.Console.WriteLine("-------End Event Printout-------");
		}
		
		public int sample;
		public int offset;
		public int duration;
		protected WrappedObject wType;
		protected WrappedObject wValue;
	}
}