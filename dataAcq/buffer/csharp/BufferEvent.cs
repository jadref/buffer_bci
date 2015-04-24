using System.Collections;
using System.Text;

namespace FieldTrip.Buffer
{
	public class BufferEvent
	{
		public BufferEvent()
		{
			wType = new WrappedObject();
			wValue = new WrappedObject();
			sample = -1;
			offset = 0;
			duration = 0;
		}

		public BufferEvent(string type, string value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, long value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, int value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, short value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, byte value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, double value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, float value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}
		
		//--- Arrays ----------
		public BufferEvent(string type, string[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, long[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, int[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, short[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, byte[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, double[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		public BufferEvent(string type, float[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.sample = sample;
			offset = duration = 0;
		}

		
		
		public BufferEvent(ByteBuffer buf)
		{
			wType = new WrappedObject();
			wValue = new WrappedObject();	
			
			wType.type = buf.GetInt();
			wType.numel = buf.GetInt();
			wValue.type = buf.GetInt();
			wValue.numel = buf.GetInt();
			sample = buf.GetInt();
			offset = buf.GetInt();
			duration = buf.GetInt();
			int size = buf.GetInt();
		
			wType.array = DataType.GetObject(wType.type, wType.numel, buf);
			if (wType.array != null) {
				wType.size = wType.numel * DataType.wordSize[wType.type];
			}
			
			wValue.array = DataType.GetObject(wValue.type, wValue.numel, buf);
			if (wValue.array != null) {
				wValue.size = wValue.numel * DataType.wordSize[wValue.type];
			}
			
			size -= wType.size + wValue.size;
			if (size != 0) {
				buf.Position = buf.Position + size;
			}
		}

		public WrappedObject Type {
			get {
				return wType;
			}
		}

		public WrappedObject Value {
			get {
				return wValue;
			}
		}

		public bool SetType(object typeObj)
		{
			wType = new WrappedObject(typeObj);
			return wType.type != DataType.UNKNOWN;
		}

		public bool SetValue(object valueObj)
		{
			wValue = new WrappedObject(valueObj);
			return wValue.type != DataType.UNKNOWN;
		}

		public bool SetValueUnsigned(byte[] array)
		{
			wValue = new WrappedObject();
			wValue.array = array.Clone();
			wValue.numel = array.Length;
			wValue.size = array.Length;
			wValue.type = DataType.UINT8;
			return true;
		}

		public int Size()
		{
			return 32 + wType.size + wValue.size;
		}

		public static int Count(ByteBuffer buf)
		{
			int num = 0;
			long pos = buf.Position;
		
			while (buf.Remaining >= 32) {
				int typeType = buf.GetInt();
				int typeNumEl = buf.GetInt();
				int valueType = buf.GetInt();
				int valueNumEl = buf.GetInt();
				buf.GetInt(); // sample
				buf.GetInt(); // offset
				buf.GetInt(); // duration
				int size = buf.GetInt();
				int sizeType = typeNumEl * DataType.wordSize[typeType];
				int sizeValue = valueNumEl * DataType.wordSize[valueType];
			
				if (sizeType < 0 || sizeValue < 0 || sizeType + sizeValue > size) {
					return -(1 + num);
				}
			
				buf.Position = buf.Position + size;
				num++;
			}
			buf.Position = pos;
			return num;
		}

		public void Serialize(ByteBuffer buf)
		{
			buf.PutInt(wType.type);
			buf.PutInt(wType.numel);
			buf.PutInt(wValue.type);
			buf.PutInt(wValue.numel);
			buf.PutInt(sample);
			buf.PutInt(offset);
			buf.PutInt(duration);
			buf.PutInt(wType.size + wValue.size);
			wType.Serialize(buf);
			wValue.Serialize(buf);
		}
		
        
		//For a general C# application change the UnityEngine.Debug.Log() with Console.WriteLine()
		public override string ToString()
		{
			//UnityEngine.Debug.Log("-------Begin Event Printout-------");
			//UnityEngine.Debug.Log("Sample registered = "+sample.ToString());
			//UnityEngine.Debug.Log("Type = "+wType.array.ToString());
	
			string result = "";
			result = "Sample:" + sample.ToString() + " Type:" + wType.array.ToString() + " Value:";
			if (wValue.array is string) {
				result += wValue.array as string;
			}
			if (wValue.array is byte[]) {
				byte[] val;
				val = wValue.array as byte[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			if (wValue.array is short[]) {
				short[] val;
				val = wValue.array as short[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			if (wValue.array is int[]) {
				int[] val;
				val = wValue.array as int[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			if (wValue.array is long[]) {
				long[] val;
				val = wValue.array as long[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			if (wValue.array is float[]) {
				float[] val;
				val = wValue.array as float[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			if (wValue.array is double[]) {
				double[] val;
				val = wValue.array as double[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			//UnityEngine.Debug.Log("Value = "+result);
			//UnityEngine.Debug.Log("-------End Event Printout-------");
			return result;
		}

		public int sample;
		public int offset;
		public int duration;
		protected WrappedObject wType;
		protected WrappedObject wValue;
	}
}