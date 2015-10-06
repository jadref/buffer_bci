package nl.dcc.buffer_bci.bufferclientsservice;

import android.os.Parcel;
import android.os.Parcelable;

public class ThreadInfo implements Parcelable {
    public static final Parcelable.Creator<ThreadInfo> CREATOR = new Parcelable.Creator<ThreadInfo>() {
        @Override
        public ThreadInfo createFromParcel(final Parcel in) {
            return new ThreadInfo(in);
        }

        @Override
        public ThreadInfo[] newArray(final int size) {
            return new ThreadInfo[size];
        }
    };
    public int threadID;
    public String title;
    public String status;
    public boolean running;

    public ThreadInfo(final int threadID, final String title, final String status, final boolean running) {
        this.threadID = threadID;
        this.title = title;
        this.status = status;
        this.running = running;
    }

    private ThreadInfo(final Parcel in) {
        threadID = in.readInt();
        title = in.readString();
        status = in.readString();
        running = in.readInt() == 1;

    }

    @Override
    public int describeContents() {
        return C.THREAD_INFO_TYPE;
    }

    @Override
    public String toString() {
        return title;
    }

    public void update(final ThreadInfo update) {
        threadID = update.threadID;
        title = update.title;
        status = update.status;
        running = update.running;
    }

    @Override
    public void writeToParcel(final Parcel out, final int flags) {
        // Gathering data
        // Write it to parcel
        out.writeInt(threadID);
        out.writeString(title);
        out.writeString(status);
        out.writeInt(running ? 1 : 0);
    }
}