using System.Collections;
using System.IO;
using MiscUtil.IO;
using MiscUtil.Conversion;

namespace FieldTrip.Buffer
{
	//Implements the fieldtrip buffer required parts of Java's ByteBuffer
	//using C# MemoryStream and an EndianBinaryWriter and EndianBinaryReader
	//(which are the equivalent of the BinaryWriter and BinaryReader but also allowing
	//a choice of Endianess)
	public class ByteBuffer {
		
		protected MemoryStream stream;
		protected EndianBinaryWriter writer;
		protected EndianBinaryReader reader;
		
		private EndianBitConverter bitConverter;
		private ByteOrder byteorder;
		
		//Constructors
		public ByteBuffer(){
			stream = new MemoryStream();
			bitConverter = new LittleEndianBitConverter();
			writer = new EndianBinaryWriter(bitConverter, stream);
			reader = new EndianBinaryReader(bitConverter, stream);
		}
		
		public ByteBuffer(int capacity){
			stream = new MemoryStream();
			bitConverter = new LittleEndianBitConverter();
			writer = new EndianBinaryWriter(bitConverter, stream);
			reader = new EndianBinaryReader(bitConverter, stream);
			stream.Capacity = capacity;
		}
		
		public ByteBuffer(int capacity, int position, MemoryStream _stream){
			stream = new MemoryStream();
			bitConverter = new LittleEndianBitConverter();
			writer = new EndianBinaryWriter(bitConverter, stream);
			reader = new EndianBinaryReader(bitConverter, stream);
			stream.Capacity = capacity;
			stream.Position = position;
			stream = _stream;
		}
		
		public ByteBuffer(Endianness _endianess, System.Text.Encoding _encoding){
			stream = new MemoryStream();
			if(_endianess==Endianness.BigEndian)
				bitConverter = new BigEndianBitConverter();
			else
				bitConverter = new LittleEndianBitConverter();
			writer = new EndianBinaryWriter(bitConverter, stream, _encoding);
			reader = new EndianBinaryReader(bitConverter, stream, _encoding);
		}
		
		public ByteBuffer(Endianness _endianess, System.Text.Encoding _encoding, int capacity, int position, MemoryStream _stream){
			stream = new MemoryStream();
			if(_endianess==Endianness.BigEndian)
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
		public ByteBuffer put(byte[] src, int offset, int length){
			this.writer.Write(src, offset, length);
			return this;
		}
		
		public ByteBuffer put(byte[] src){
			this.writer.Write(src, 0, src.Length);
			return this;
		}
		
		public ByteBuffer putByte(byte src){
			this.writer.Write(src);
			return this;
		}
		
		public ByteBuffer putString(string src){
			this.writer.Write(src);
			return this;
		}
		
		public ByteBuffer putShort(short src){
			this.writer.Write(src);
			return this;
		}
		
		public ByteBuffer putInt(int src){
			this.writer.Write(src);
			return this;
		}
		
		public ByteBuffer putLong(long src){
			this.writer.Write(src);
			return this;
		}
		
		public ByteBuffer putDouble(double src){
			this.writer.Write(src);
			return this;
		}
		
		public ByteBuffer putFloat(float src){
			this.writer.Write(src);
			return this;
		}
	
		//get functions
		public ByteBuffer get(ref byte[] bytes){
			bytes = reader.ReadBytes((int)bytes.Length);
			return this;
		}
		
		public byte get(){
			return reader.ReadByte();
		}
		
		public short getShort(){
			return reader.ReadInt16();
		}
		
		public int getInt(){
			return reader.ReadInt32();
		}
		
		public long getLong(){
			return reader.ReadInt64();
		}
		
		public double getDouble(){
			return reader.ReadDouble();
		}
		
		public float getFloat(){
			return reader.ReadSingle();
		}
		
		//as functions
		public ShortBuffer asShortBuffer(){
			ShortBuffer shortbuffer = new ShortBuffer(this);
			return shortbuffer;
		} 
		
		public IntBuffer asIntBuffer(){
			IntBuffer intbuffer = new IntBuffer(this);
			return intbuffer;
		} 
		
		public LongBuffer asLongBuffer(){
			LongBuffer longbuffer = new LongBuffer(this);
			return longbuffer;
		} 
		
		public DoubleBuffer asDoubleBuffer(){
			DoubleBuffer doublebuffer = new DoubleBuffer(this);
			return doublebuffer;
		} 
		
		public FloatBuffer asFloatBuffer(){
			FloatBuffer floatbuffer = new FloatBuffer(this);
			return floatbuffer;
		} 
		
		
		//other functions
		public static ByteBuffer allocate(int capacity){
			ByteBuffer newBuffer = new ByteBuffer(capacity);
			return newBuffer;
		}
		
		public ByteOrder order(){
			return byteorder;
		}
		
		public ByteBuffer order(ByteOrder _byteorder){
				byteorder = _byteorder;
				if(byteorder == ByteOrder.BIG_ENDIAN)
					bitConverter = new BigEndianBitConverter();
				else
					bitConverter = new LittleEndianBitConverter();
			return this;
		}
		
		public long position(){
			return stream.Position;	
		}
		
		public void position(long newposition){
			stream.Position = newposition;
		}
		
		
		public long remaining(){
			return stream.Length - stream.Position;
		}
		
		public int capacity(){
			return stream.Capacity;
		}
		
		public int length(){
			return (int)stream.Length;
		}
		
		public ByteBuffer rewind(){
			stream.Position = 0;
			return this;
		}	
		
		public System.Text.Encoding encoding(){
			if(reader.Encoding!=writer.Encoding)
				throw new IOException("EndianBinaryWriter's and EndianBinaryReader's encoding are not the same.");
			return writer.Encoding;	
		}
		
		public ByteBuffer slice(){
			ByteBuffer newBuffer = new ByteBuffer((int)(stream.Capacity - stream.Position), 0, this.stream);
			newBuffer.bitConverter = this.bitConverter;
			newBuffer.byteorder = this.byteorder;
			newBuffer.reader = this.reader;
			newBuffer.writer = this.writer;
			return newBuffer;
		}
		
		public ByteBuffer clear(){
			stream.SetLength(0);
			return this;
		}
	
	}
	
	
	
	//Specific Type Byffers ====================
	
	public class ShortBuffer {
		private ByteBuffer bytebuffer;
		
		public ShortBuffer(ByteBuffer _bytebuffer){
			bytebuffer = _bytebuffer;
		}
		
		public ShortBuffer get(short[] dst){
			for(int i=0; i<bytebuffer.remaining(); ++i)
				dst[i] = bytebuffer.getShort();
			return this;
		}
		
		public ShortBuffer put(short[] src){
			for(int i=0; i<src.Length; ++i)
				bytebuffer.putShort(src[i]);
			return this;
		}
	}
	
	public class IntBuffer {
		private ByteBuffer bytebuffer;
		
		public IntBuffer(ByteBuffer _bytebuffer){
			bytebuffer = _bytebuffer;
		}
		
		public IntBuffer get(int[] dst){
			for(int i=0; i<bytebuffer.remaining(); ++i)
				dst[i] = bytebuffer.getInt();
			return this;
		}
		
		public IntBuffer put(int[] src){
			for(int i=0; i<src.Length; ++i)
				bytebuffer.putInt(src[i]);
			return this;
		}
	}
	
	
	public class LongBuffer {
		private ByteBuffer bytebuffer;
		
		public LongBuffer(ByteBuffer _bytebuffer){
			bytebuffer = _bytebuffer;
		}
		
		public LongBuffer get(long[] dst){
			for(int i=0; i<bytebuffer.remaining(); ++i)
				dst[i] = bytebuffer.getLong();
			return this;
		}
		
		public LongBuffer put(long[] src){
			for(int i=0; i<src.Length; ++i)
				bytebuffer.putLong(src[i]);
			return this;
		}
	}
	
	
	public class DoubleBuffer {
		private ByteBuffer bytebuffer;
		
		public DoubleBuffer(ByteBuffer _bytebuffer){
			bytebuffer = _bytebuffer;
		}
		
		public DoubleBuffer get(double[] dst){
			for(int i=0; i<bytebuffer.remaining(); ++i)
				dst[i] = bytebuffer.getDouble();
			return this;
		}
		
		public DoubleBuffer put(double[] src){
			for(int i=0; i<src.Length; ++i)
				bytebuffer.putDouble(src[i]);
			return this;
		}
	}
	
	
	public class FloatBuffer {
		private ByteBuffer bytebuffer;
		
		public FloatBuffer(ByteBuffer _bytebuffer){
			bytebuffer = _bytebuffer;
		}
		
		public FloatBuffer get(float[] dst){
			for(int i=0; i<bytebuffer.remaining(); ++i)
				dst[i] = bytebuffer.getFloat();
			return this;
		}
		
		public FloatBuffer put(float[] src){
			for(int i=0; i<src.Length; ++i)
				bytebuffer.putFloat(src[i]);
			return this;
		}
	}
	
	//=================================
	
	
	
	public sealed class ByteOrder{
	
		private EndianBitConverter bitConverter;
		
		public static readonly ByteOrder BIG_ENDIAN= new ByteOrder("BIG_ENDIAN");
		public static readonly ByteOrder LITTLE_ENDIAN= new ByteOrder("LITTLE_ENDIAN");
		
		public static string ByteOrder_Endianess {get; private set;}
		
		private ByteOrder(string endianess){
				ByteOrder_Endianess = endianess;
				if(ByteOrder_Endianess == "BIG_ENDIAN")
					bitConverter = new BigEndianBitConverter();
				else
					bitConverter = new LittleEndianBitConverter();
		}
		
		public static ByteOrder nativeOrder(){
			if(System.BitConverter.IsLittleEndian){
				return ByteOrder.LITTLE_ENDIAN;
			}else{
				return ByteOrder.BIG_ENDIAN;
			}
		}
		
		public string toString(){
			return ByteOrder_Endianess;
		}
	}
}