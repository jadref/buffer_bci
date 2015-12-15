package nl.dcc.buffer_bci.monitor;

import android.os.Parcel;
import android.os.Parcelable;
import nl.dcc.buffer_bci.C;

public class BufferInfo implements Parcelable {

    public static final Parcelable.Creator<BufferInfo> CREATOR = new Parcelable.Creator<BufferInfo>() {
        @Override
        public BufferInfo createFromParcel(final Parcel in) {
            return new BufferInfo(in);
        }

        @Override
        public BufferInfo[] newArray(final int size) {
            return new BufferInfo[size];
        }
    };
    private static final long serialVersionUID = -5926084016803995100L;
    public String address;
    public int nSamples = 0;
    public int nEvents = 0;
    public int dataType = -1;
    public int nChannels = -1;
    public float fSample = -1;
    public long startTime;
    public boolean changed = true;

    private BufferInfo(Parcel in) {
        int[] integers = new int[4];

        address = in.readString();
        in.readIntArray(integers);
        fSample = in.readFloat();
        startTime = in.readLong();

        nSamples = integers[0];
        nEvents = integers[1];
        dataType = integers[2];
        nChannels = integers[3];
    }

    public BufferInfo(String address, long startTime) {
        this.address = address;
        this.startTime = startTime;
    }

    @Override
    public int describeContents() {
        return C.BUFFER_INFO_PARCEL;
    }

    @Override
    public void writeToParcel(final Parcel out, final int flags) {
        final int[] integers = new int[]{nSamples, nEvents, dataType, nChannels};

        out.writeString(address);
        out.writeIntArray(integers);
        out.writeFloat(fSample);
        out.writeLong(startTime);
    }

}