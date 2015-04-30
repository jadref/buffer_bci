using System.IO;
using System.Text;
using MiscUtil.IO;
using MiscUtil.Conversion;

namespace FieldTrip.Buffer
{
	//Implements the fieldtrip buffer required parts of Java's ByteBuffer
	//using C# MemoryStream and an EndianBinaryWriter and EndianBinaryReader
	//(which are the equivalent of the BinaryWriter and BinaryReader but also allowing
	//a choice of Endianess)
	public class ByteBuffer
	{
		
		protected MemoryStream stream;
		protected EndianBinaryWriter writer;
		protected EndianBinaryReader reader;
		
		private EndianBitConverter bitConverter;
		private ByteOrder byteorder;
		
		//Constructors
		public ByteBuffer()
		{
			stream = new MemoryStream();
			bitConverter = new LittleEndianBitConverter();
			writer = new EndianBinaryWriter(bitConverter, stream);
			reader = new EndianBinaryReader(bitConverter, stream);
		}

		public ByteBuffer(int capacity)
		{
			stream = new MemoryStream();
			bitConverter = new LittleEndianBitConverter();
			writer = new EndianBinaryWriter(bitConverter, stream);
			reader = new EndianBinaryReader(bitConverter, stream);
			stream.Capacity = capacity;
		}

		public ByteBuffer(int capacity, int position, MemoryStream _stream)
		{
			stream = new MemoryStream();
			bitConverter = new LittleEndianBitConverter();
			writer = new EndianBinaryWriter(bitConverter, stream);
			reader = new EndianBinaryReader(bitConverter, stream);
			stream.Capacity = capacity;
			stream.Position = position;
			stream = _stream;
		}

		public ByteBuffer(Endianness _endianess, System.Text.Encoding _encoding)
		{
			stream = new MemoryStream();
			if (_endianess == Endianness.BigEndian)
				bitConverter = new BigEndianBitConverter();
			else
				bitConverter = new LittleEndianBitConverter();
			writer = new EndianBinaryWriter(bitConverter, stream, _encoding);
			reader = new EndianBinaryReader(bitConverter, stream, _encoding);
		}

		public ByteBuffer(Endianness _endianess, System.Text.Encoding _encoding, int capacity, int position, MemoryStream _stream)
		{
			stream = new MemoryStream();
			if (_endianess == Endianness.BigEndian)
				bitConverter = new BigEndianBitConverter();
			else
				bitConverter = new LittleEndianBitConverter();
			writer = new EndianBinaryWriter(bitConverter, stream, _encoding);
			reader = new EndianBinaryReader(bitConverter, stream, _encoding);
			stream.Capacity = capacity;
			stream.Position = position;
			stream = _stream;
		}
		
		//put functions
		public ByteBuffer Put(byte[] src, int offset, int length)
		{
			this.writer.Write(src, offset, length);
			return this;
		}

		public ByteBuffer Put(byte[] src)
		{
			this.writer.Write(src, 0, src.Length);
			return this;
		}

		public ByteBuffer PutByte(byte src)
		{
			this.writer.Write(src);
			return this;
		}

		public ByteBuffer PutString(string src)
		{
			this.writer.Write(src);
			return this;
		}

		public ByteBuffer PutShort(short src)
		{
			this.writer.Write(src);
			return this;
		}

		public ByteBuffer PutInt(int src)
		{
			this.writer.Write(src);
			return this;
		}

		public ByteBuffer PutLong(long src)
		{
			this.writer.Write(src);
			return this;
		}

		public ByteBuffer PutDouble(double src)
		{
			this.writer.Write(src);
			return this;
		}

		public ByteBuffer PutFloat(float src)
		{
			this.writer.Write(src);
			return this;
		}
	
		//get functions
		public ByteBuffer Get(ref byte[] bytes)
		{
			bytes = reader.ReadBytes((int)bytes.Length);
			return this;
		}

		public byte Get()
		{
			return reader.ReadByte();
		}

		public short GetShort()
		{
			return reader.ReadInt16();
		}

		public int GetInt()
		{
			return reader.ReadInt32();
		}

		public long GetLong()
		{
			return reader.ReadInt64();
		}

		public double GetDouble()
		{
			return reader.ReadDouble();
		}

		public float GetFloat()
		{
			return reader.ReadSingle();
		}
		
		//as functions
		public ShortBuffer AsShortBuffer()
		{
			ShortBuffer shortbuffer = new ShortBuffer(this);
			return shortbuffer;
		}

		public IntBuffer AsIntBuffer()
		{
			IntBuffer intbuffer = new IntBuffer(this);
			return intbuffer;
		}

		public LongBuffer AsLongBuffer()
		{
			LongBuffer longbuffer = new LongBuffer(this);
			return longbuffer;
		}

		public DoubleBuffer AsDoubleBuffer()
		{
			DoubleBuffer doublebuffer = new DoubleBuffer(this);
			return doublebuffer;
		}

		public FloatBuffer AsFloatBuffer()
		{
			FloatBuffer floatbuffer = new FloatBuffer(this);
			return floatbuffer;
		}
		
		
		//other functions
		public static ByteBuffer Allocate(int capacity)
		{
			ByteBuffer newBuffer = new ByteBuffer(capacity);
			return newBuffer;
		}

		public ByteOrder Order()
		{
			return byteorder;
		}

		public ByteBuffer Order(ByteOrder _byteorder)
		{
			byteorder = _byteorder;
			if (byteorder == ByteOrder.BIG_ENDIAN)
				bitConverter = new BigEndianBitConverter();
			else
				bitConverter = new LittleEndianBitConverter();
			return this;
		}

		public long Position {
			get {
				return stream.Position;	
			}
			set {
				stream.Position = value;
			}
		}

		public long Remaining {
			get {
				return stream.Length - stream.Position;
			}
		}

		public int Capacity {
			get {
				return stream.Capacity;
			}
		}

		public int Length {
			get {
				return (int)stream.Length;
			}
		}

		public ByteBuffer Rewind()
		{
			stream.Position = 0;
			return this;
		}

		public Encoding Encoding {
			get {
				if (reader.Encoding != writer.Encoding)
					throw new IOException("EndianBinaryWriter's and EndianBinaryReader's encoding are not the same.");
				return writer.Encoding;	
			}
		}

		public ByteBuffer Slice()
		{
			ByteBuffer newBuffer = new ByteBuffer((int)(stream.Capacity - stream.Position), 0, this.stream);
			newBuffer.bitConverter = this.bitConverter;
			newBuffer.byteorder = this.byteorder;
			newBuffer.reader = this.reader;
			newBuffer.writer = this.writer;
			return newBuffer;
		}

		public ByteBuffer Clear()
		{
			stream.SetLength(0);
			return this;
		}
	
	}
	
	
	
	//Specific Type Byffers ====================
	
	public class ShortBuffer
	{
		private ByteBuffer bytebuffer;

		public ShortBuffer(ByteBuffer _bytebuffer)
		{
			bytebuffer = _bytebuffer;
		}

		public ShortBuffer Get(short[] dst)
		{
			for (int i = 0; i < bytebuffer.Remaining; ++i)
				dst[i] = bytebuffer.GetShort();
			return this;
		}

		public ShortBuffer Put(short[] src)
		{
			for (int i = 0; i < src.Length; ++i)
				bytebuffer.PutShort(src[i]);
			return this;
		}
	}

	public class IntBuffer
	{
		private ByteBuffer bytebuffer;

		public IntBuffer(ByteBuffer _bytebuffer)
		{
			bytebuffer = _bytebuffer;
		}

		public IntBuffer Get(int[] dst)
		{
			for (int i = 0; i < bytebuffer.Remaining; ++i)
				dst[i] = bytebuffer.GetInt();
			return this;
		}

		public IntBuffer Put(int[] src)
		{
			for (int i = 0; i < src.Length; ++i)
				bytebuffer.PutInt(src[i]);
			return this;
		}
	}

	
	public class LongBuffer
	{
		private ByteBuffer bytebuffer;

		public LongBuffer(ByteBuffer _bytebuffer)
		{
			bytebuffer = _bytebuffer;
		}

		public LongBuffer Get(long[] dst)
		{
			for (int i = 0; i < bytebuffer.Remaining; ++i)
				dst[i] = bytebuffer.GetLong();
			return this;
		}

		public LongBuffer Put(long[] src)
		{
			for (int i = 0; i < src.Length; ++i)
				bytebuffer.PutLong(src[i]);
			return this;
		}
	}

	
	public class DoubleBuffer
	{
		private ByteBuffer bytebuffer;

		public DoubleBuffer(ByteBuffer _bytebuffer)
		{
			bytebuffer = _bytebuffer;
		}

		public DoubleBuffer Get(double[] dst)
		{
			for (int i = 0; i < bytebuffer.Remaining; ++i)
				dst[i] = bytebuffer.GetDouble();
			return this;
		}

		public DoubleBuffer Put(double[] src)
		{
			for (int i = 0; i < src.Length; ++i)
				bytebuffer.PutDouble(src[i]);
			return this;
		}
	}

	
	public class FloatBuffer
	{
		private ByteBuffer bytebuffer;

		public FloatBuffer(ByteBuffer _bytebuffer)
		{
			bytebuffer = _bytebuffer;
		}

		public FloatBuffer Get(float[] dst)
		{
			for (int i = 0; i < bytebuffer.Remaining; ++i)
				dst[i] = bytebuffer.GetFloat();
			return this;
		}

		public FloatBuffer Put(float[] src)
		{
			for (int i = 0; i < src.Length; ++i)
				bytebuffer.PutFloat(src[i]);
			return this;
		}
	}
	
	//=================================
	
	
	
	public sealed class ByteOrder
	{
	
		private EndianBitConverter bitConverter;
		
		public static readonly ByteOrder BIG_ENDIAN = new ByteOrder("BIG_ENDIAN");
		public static readonly ByteOrder LITTLE_ENDIAN = new ByteOrder("LITTLE_ENDIAN");

		public static string ByteOrder_Endianess { get; private set; }

		private ByteOrder(string endianess)
		{
			ByteOrder_Endianess = endianess;
			if (ByteOrder_Endianess == "BIG_ENDIAN")
				bitConverter = new BigEndianBitConverter();
			else
				bitConverter = new LittleEndianBitConverter();
		}

		public static ByteOrder NativeOrder()
		{
			if (System.BitConverter.IsLittleEndian) {
				return ByteOrder.LITTLE_ENDIAN;
			} else {
				return ByteOrder.BIG_ENDIAN;
			}
		}

		public override string ToString()
		{
			return ByteOrder_Endianess;
		}
	}
}