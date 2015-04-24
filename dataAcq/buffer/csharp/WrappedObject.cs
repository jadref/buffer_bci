using System;
using System.Collections;

namespace FieldTrip.Buffer
{
	public class WrappedObject
	{
        /// <summary>
        /// The type of data contained in the WrappedObject.
        /// </summary>
		public int Type{ get; set; }

        /// <summary>
        /// The number of elements.
        /// </summary>
		public int Numel{ get; set; }

        /// <summary>
        /// Size in bytes.
        /// </summary>
		public int Size{ get; set; }

        /// <summary>
        /// The data as an array.
        /// </summary>
		public object Array{ get; set; }

		public WrappedObject()
		{
			Type = DataType.UNKNOWN;
			Numel = 0;
			Size = 0;
			Array = null;
		}

		public WrappedObject(string s)
		{
			Type = DataType.CHAR;
			Numel = s.Length;
			Size = Numel;
			Array = s;
		}

		public WrappedObject(double x)
		{
			Type = DataType.FLOAT64;
			Numel = 1;
			Size = 8;
			Array = new double[] { x };
		}

		public WrappedObject(float x)
		{
			Type = DataType.FLOAT32;
			Numel = 1;
			Size = 4;
			Array = new float[] { x };
		}

		public WrappedObject(long x)
		{
			Type = DataType.INT64;
			Numel = 1;
			Size = 8;
			Array = new long[] { x };
		}

		public WrappedObject(int x)
		{
			Type = DataType.INT32;
			Numel = 1;
			Size = 4;
			Array = new int[] { x };
		}

		public WrappedObject(short x)
		{
			Type = DataType.INT16;
			Numel = 1;
			Size = 2;
			Array = new short[] { x };
		}

		public WrappedObject(byte x)
		{
			Type = DataType.INT8;
			Numel = 1;
			Size = 1;
			Array = new byte[] { x };
		}

        /// <summary>
        /// Create a wrapped object from a given object.
        /// </summary>
        /// <param name="obj"></param>
		public WrappedObject(object obj)
		{
	
			Type cls = obj.GetType();
			string name = cls.FullName;
	
			if (cls.IsArray) {
				Type elc = cls.GetElementType();
				if (!elc.IsPrimitive)
					return;
				
				if (name == "System.Double[]") {
					Type = DataType.FLOAT64;
					Array = ((double[])obj).Clone();
					Numel = ((double[])obj).Length;
				} else if (name == "System.Single[]") {
					Type = DataType.FLOAT32;
					Array = ((float[])obj).Clone();
					Numel = ((float[])obj).Length;
				} else if (name == "System.Int64[]") {
					Type = DataType.INT64;
					Array = ((long[])obj).Clone();
					Numel = ((long[])obj).Length;
				} else if (name == "System.Int32[]") {
					Type = DataType.INT32;
					Array = ((int[])obj).Clone();
					Numel = ((int[])obj).Length;
				} else if (name == "System.Int16[]") {
					Type = DataType.INT16;
					Array = ((short[])obj).Clone();
					Numel = ((short[])obj).Length;
				} else if (name == "System.Byte[]") {
					Type = DataType.INT8;
					Array = ((byte[])obj).Clone();
					Numel = ((byte[])obj).Length;
				} else {
					return; // keep as unknown
				}
				Size = Numel * DataType.wordSize[Type];
				return;
			} else if (name == "System.String") {
				Type = DataType.CHAR;
				Array = obj;
				Numel = ((string)obj).Length;
				Size = Numel;
				return;
			} else if (name == "System.Double") {
				Type = DataType.FLOAT64;
				Array = new double[] { ((double)obj) };
			} else if (name == "System.Single") {
				Type = DataType.FLOAT32;
				Array = new float[] { ((float)obj) };
			} else if (name == "System.Int64") {
				Type = DataType.INT64;
				Array = new long[] { ((long)obj) };
			} else if (name == "System.Int32") {
				Type = DataType.INT32;
				Array = new int[] { ((Int32)obj) };
			} else if (name == "System.Int16") {
				Type = DataType.INT16;
				Array = new short[] { ((short)obj) };
			} else if (name == "System.Byte") {
				Type = DataType.INT8;
				Array = new byte[] { ((byte)obj) };		
			} else {
				return;
			}
			Numel = 1;
			Size = DataType.wordSize[Type];
		}

        /// <summary>
        /// Serialize the WrappedObject to the specified <see cref="FieldTrip.Buffer.ByteBuffer"/>.
        /// </summary>
        /// <param name="buf">The buffer to serialize to.</param>
		public void Serialize(ByteBuffer buf)
		{
			switch (Type) {
				case DataType.CHAR:
					buf.PutString(Array.ToString());
					break;
				case DataType.UINT8:
				case DataType.INT8:
					buf.Put((byte[])Array);
					break;
				case DataType.UINT16:
				case DataType.INT16:
					buf.AsShortBuffer().Put((short[])Array);
					break;
				case DataType.UINT32:
				case DataType.INT32:
					buf.AsIntBuffer().Put((int[])Array);
					break;
				case DataType.UINT64:
				case DataType.INT64:
					buf.AsLongBuffer().Put((long[])Array);
					break;
				case DataType.FLOAT32:
					buf.AsFloatBuffer().Put((float[])Array);
					break;
				case DataType.FLOAT64:
					buf.AsDoubleBuffer().Put((double[])Array);
					break;
			}
		}

        /// <summary>
        /// Creates a string representation of the data.
        /// </summary>
        /// <returns>The string representation of the data.</returns>
		public override string ToString()
		{
			if (Type == DataType.CHAR)
				return (string)Array;
			if (Type == DataType.FLOAT64)
				return (((double[])Array)[0]).ToString();
			if (Type == DataType.FLOAT32)
				return (((float[])Array)[0]).ToString();
			if (Type == DataType.INT64)
				return (((long[])Array)[0]).ToString();
			if (Type == DataType.INT32)
				return (((int[])Array)[0]).ToString();
			if (Type == DataType.INT16)
				return (((short[])Array)[0]).ToString();
			if (Type == DataType.INT8)
				return (((byte[])Array)[0]).ToString();
			return Array.ToString();
		}
	}
}



