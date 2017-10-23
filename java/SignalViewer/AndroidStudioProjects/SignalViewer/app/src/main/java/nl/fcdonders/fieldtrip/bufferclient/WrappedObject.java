/*
 * Copyright (C) 2010, Stefan Klanke
 * Donders Institute for Donders Institute for Brain, Cognition and Behaviour,
 * Centre for Cognitive Neuroimaging, Radboud University Nijmegen,
 * Kapittelweg 29, 6525 EN Nijmegen, The Netherlands
 */
package nl.fcdonders.fieldtrip.bufferclient;

import java.nio.*;

/** A class for wrapping relevant Java objects in a way that
	is easily convertible to FieldTrip data types.
*/
public class WrappedObject {
	protected int type;
	protected int numel;
	protected int size;
	protected Object array;
	
	public WrappedObject() {
		type  = DataType.UNKNOWN;
		numel = 0;
		size  = 0;
		array = null;
	}
	
	public WrappedObject(String s) {
		type  = DataType.CHAR;
		numel = s.getBytes().length;
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

	public WrappedObject(boolean x) {
		type  = DataType.INT8;
		numel = 1;
		size  = 1;
		array = new byte[]{(byte)(x?1:0)};
	}
	
	public WrappedObject(Object obj) {
		this();
	
		Class cls = obj.getClass();
		String name = cls.getName();
		//System.out.println("cls="+cls+" name=" + name);
		
		if (cls.isArray()) {
			Class elc = cls.getComponentType();
			
         if ( name == null ) {
             return; // keep as unknown

         }else if   (name.equals("[D")) {
				type = DataType.FLOAT64;
				array = ((double[]) obj).clone();
				numel = ((double[]) obj).length;

			} else if  (name.equals("[Ljava.lang.Double") || name.equals("[Ljava.lang.Double;") ) {
				type = DataType.FLOAT64;
				double[] tmp = new double[((Double[])obj).length];
				for ( int i=0; i<tmp.length; i++ ) tmp[i] = (double) ((Double[])obj)[i];
				array = tmp;
				numel = tmp.length;

			} else if (name.equals("[F")) {
				type = DataType.FLOAT32;
				array = ((float[]) obj).clone();
				numel = ((float[]) obj).length;

			} else if  (name.equals("[Ljava.lang.Float") || name.equals("[Ljava.lang.Float;")) {
				type = DataType.FLOAT32;
				float[] tmp = new float[((Float[])obj).length];
				for ( int i=0; i<tmp.length; i++ ) tmp[i] = (float) ((Float[])obj)[i];
				array = tmp;
				numel = tmp.length;

			} else if (name.equals("[J")) {
				type = DataType.INT64;
				array = ((long[]) obj).clone();
				numel = ((long[]) obj).length;

			} else if (name.equals("[I")) {
				type = DataType.INT32;
				array = ((int[]) obj).clone();
				numel = ((int[]) obj).length;
			
			} else if  (name.equals("[Ljava.lang.Integer") || name.equals("[Ljava.lang.Integer;")) {
				type = DataType.INT32;
				int[] tmp = new int[((Integer[])obj).length];
				for ( int i=0; i<tmp.length; i++ ) tmp[i] = (int) ((Integer[])obj)[i];
				array = tmp;
				numel = tmp.length;

			} else if (name.equals("[S")) {
				type = DataType.INT16;
				array = ((short[]) obj).clone();
				numel = ((short[]) obj).length;
			
			} else if (name.equals("[B")) {
				type = DataType.INT8;
				array = ((byte[]) obj).clone();
				numel = ((byte[]) obj).length;
			
			} else if  (name.equals("[Ljava.lang.Byte") || name.equals("[Ljava.lang.Byte;") ) {
				type = DataType.INT8;
				double[] tmp = new double[((Boolean[])obj).length];
				for ( int i=0; i<tmp.length; i++ ) tmp[i] = (byte)((Byte[])obj)[i];
				array = tmp;
				numel = tmp.length;

			} else if (name.equals("[Z")) { // boolean
				type = DataType.INT8;
				byte[] tmp = new byte[((boolean[])obj).length];
				for ( int i=0; i<tmp.length; i++ ) tmp[i] = (byte)((((boolean[])obj)[i])?1:0);
				array = tmp;
				numel = tmp.length;

			} else if  (name.equals("[Ljava.lang.Boolean") || name.equals("[Ljava.lang.Boolean;") ) {
				type = DataType.INT8;
				double[] tmp = new double[((Boolean[])obj).length];
				for ( int i=0; i<tmp.length; i++ ) tmp[i] = (byte)((((Boolean[])obj)[i])?1:0);
				array = tmp;
				numel = tmp.length;

			} else {
				return; // keep as unknown
			}
			size  = numel * DataType.wordSize[type];
			return;
		} else if (name.equals("java.lang.String")) {
			type = DataType.CHAR;
			array = obj;
			numel = ((String) obj).getBytes().length;
			size  = numel;
			return;
		} else if (name.equals("java.lang.Double")) {
			type = DataType.FLOAT64;
			array = new double[] {((Double) obj).doubleValue()};
		} else if (name.equals("java.lang.Float")) {
			type = DataType.FLOAT32;
			array = new float[] {((Float) obj).floatValue()};
		} else if (name.equals("java.lang.Long")) {
			type = DataType.INT64;
			array = new long[] {((Long) obj).longValue()};
		} else if (name.equals("java.lang.Integer")) {
			type = DataType.INT32;
			array = new int[] {((Integer) obj).intValue()};
		} else if (name.equals("java.lang.Short")) {
			type = DataType.INT16;
			array = new short[] {((Short) obj).shortValue()};
		} else if (name.equals("java.lang.Byte")) {
			type = DataType.INT8;
			array = new byte[] {((Byte) obj).byteValue()};		
		} else if (name.equals("java.lang.Boolean")) {
			type = DataType.INT8;
			array = new byte[] {(byte)(((Boolean) obj).booleanValue()?1:0)};		
		} else {
			return;
		}
		numel = 1;
		size  = DataType.wordSize[type];
	}	
		
	public void serialize(ByteBuffer buf) {
		switch(type) {
			case DataType.CHAR:
				buf.put(((String) array).getBytes());
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
	
	 // methods to extract info from the data
	 public int getType() { return type; }
	 public Object getArray() { return array; }

	public String toString() {
		 String str=new String();
		if (type == DataType.CHAR) return (String) array;
		if (type == DataType.FLOAT64) {
			 str = String.valueOf(((double[]) array)[0]);
			 for ( int i=1; i<numel; i++ ){
				  str = str + "," + String.valueOf(((double[]) array)[i]);
			 }
			 return str;
		}
		if (type == DataType.FLOAT32) {
			 str = String.valueOf(((float[]) array)[0]);
			 for ( int i=1; i<numel; i++ ){
				  str = str + "," + String.valueOf(((float[]) array)[i]);
			 }
			 return str;
		}
		if (type == DataType.INT64) {
			 str = String.valueOf(((long[]) array)[0]);
			 for ( int i=1; i<numel; i++ ){
				  str = str + "," + String.valueOf(((long[]) array)[i]);
			 }
			 return str;
		}
		if (type == DataType.INT32) {
			 str = String.valueOf(((int[]) array)[0]);
			 for ( int i=1; i<numel; i++ ){
				  str = str + "," + String.valueOf(((int[]) array)[i]);
			 }
			 return str;
		}
		if (type == DataType.INT16) {
			 str = String.valueOf(((short[]) array)[0]);
			 for ( int i=1; i<numel; i++ ){
				  str = str + "," + String.valueOf(((short[]) array)[i]);
			 }
			 return str;
		}
		if (type == DataType.INT8) {
			 str = String.valueOf(((byte[]) array)[0]);
			 for ( int i=1; i<numel; i++ ){
				  str = str + "," + String.valueOf(((byte[]) array)[i]);
			 }
			 return str;
		}
		return array.toString();
	}
}
