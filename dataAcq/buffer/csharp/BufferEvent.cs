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
			Sample = -1;
			Offset = 0;
			Duration = 0;
		}

		public BufferEvent(string type, string value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, long value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, int value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, short value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, byte value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, double value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, float value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}
		
		//--- Arrays ----------
		public BufferEvent(string type, string[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, long[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, int[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, short[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, byte[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, double[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		public BufferEvent(string type, float[] value, int sample)
		{
			wType = new WrappedObject(type);
			wValue = new WrappedObject(value);
			this.Sample = sample;
			Offset = Duration = 0;
		}

		
		
		public BufferEvent(ByteBuffer buf)
		{
			wType = new WrappedObject();
			wValue = new WrappedObject();	
			
			wType.Type = buf.GetInt();
			wType.Numel = buf.GetInt();
			wValue.Type = buf.GetInt();
			wValue.Numel = buf.GetInt();
			Sample = buf.GetInt();
			Offset = buf.GetInt();
			Duration = buf.GetInt();
			int size = buf.GetInt();
		
			wType.Array = DataType.GetObject(wType.Type, wType.Numel, buf);
			if (wType.Array != null) {
				wType.Size = wType.Numel * DataType.wordSize[wType.Type];
			}
			
			wValue.Array = DataType.GetObject(wValue.Type, wValue.Numel, buf);
			if (wValue.Array != null) {
				wValue.Size = wValue.Numel * DataType.wordSize[wValue.Type];
			}
			
			size -= wType.Size + wValue.Size;
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
			return wType.Type != DataType.UNKNOWN;
		}

		public bool SetValue(object valueObj)
		{
			wValue = new WrappedObject(valueObj);
			return wValue.Type != DataType.UNKNOWN;
		}

		public bool SetValueUnsigned(byte[] array)
		{
			wValue = new WrappedObject();
			wValue.Array = array.Clone();
			wValue.Numel = array.Length;
			wValue.Size = array.Length;
			wValue.Type = DataType.UINT8;
			return true;
		}

		public int Size()
		{
			return 32 + wType.Size + wValue.Size;
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
			buf.PutInt(wType.Type);
			buf.PutInt(wType.Numel);
			buf.PutInt(wValue.Type);
			buf.PutInt(wValue.Numel);
			buf.PutInt(Sample);
			buf.PutInt(Offset);
			buf.PutInt(Duration);
			buf.PutInt(wType.Size + wValue.Size);
			wType.Serialize(buf);
			wValue.Serialize(buf);
		}
		
        
		//For a general C# application replace the UnityEngine.Debug.Log() with Console.WriteLine()
		public override string ToString()
		{
			//UnityEngine.Debug.Log("-------Begin Event Printout-------");
			//UnityEngine.Debug.Log("Sample registered = "+sample.ToString());
			//UnityEngine.Debug.Log("Type = "+wType.array.ToString());
	
			string result = "";
			result = "Sample:" + Sample.ToString() + " Type:" + wType.Array.ToString() + " Value:";
			if (wValue.Array is string) {
				result += wValue.Array as string;
			}
			if (wValue.Array is byte[]) {
				byte[] val;
				val = wValue.Array as byte[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			if (wValue.Array is short[]) {
				short[] val;
				val = wValue.Array as short[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			if (wValue.Array is int[]) {
				int[] val;
				val = wValue.Array as int[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			if (wValue.Array is long[]) {
				long[] val;
				val = wValue.Array as long[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			if (wValue.Array is float[]) {
				float[] val;
				val = wValue.Array as float[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			if (wValue.Array is double[]) {
				double[] val;
				val = wValue.Array as double[];
				foreach (var i in val)
					result += i.ToString() + ", ";
			}
			//UnityEngine.Debug.Log("Value = "+result);
			//UnityEngine.Debug.Log("-------End Event Printout-------");
			return result;
		}

		public int Sample{ get; set; }

		public int Offset{ get; set; }

		public int Duration{ get; set; }

		protected WrappedObject wType;
		protected WrappedObject wValue;
	}
}