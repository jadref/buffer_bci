package edu.nl.ru.fieldtripclientsservice.threads;

import android.util.Log;
import edu.nl.ru.fieldtripclientsservice.base.Argument;
import edu.nl.ru.fieldtripclientsservice.base.ThreadBase;
import nl.fcdonders.fieldtrip.bufferclient.BufferClient;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.DataType;
import nl.fcdonders.fieldtrip.bufferclient.Header;

import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;


public class FilePlayback extends ThreadBase {

    public static final String TAG = FilePlayback.class.toString();

    private final BufferClient client = new BufferClient();
    private int VERB = 1; // global verbosity level
    private int BUFFERSIZE = 65500;
    private InputStream dataReader = null;
    private InputStream eventReader = null;
    private InputStream headerReader = null;
    private String address;
    private int port;
    private double speedup;
    private int buffsamp;

    @Override
    public Argument[] getArguments() {
        final Argument[] arguments = new Argument[3];

        arguments[0] = new Argument("Buffer Address", "localhost:1972");
        arguments[1] = new Argument("Speedup", 1.0, false);
        arguments[2] = new Argument("Buffer size", 5, false);

        return arguments;
    }

    @Override
    public String getName() {
        return "File Playback";
    }


    @Override
    public void validateArguments(Argument[] arguments) {
        final String address = arguments[0].getString();

        try {
            final String[] split = address.split(":");
            arguments[0].validate();
            try {
                Integer.parseInt(split[1]);
            } catch (final NumberFormatException e) {
                arguments[0].invalidate("Wrong address format.");
            }

        } catch (final ArrayIndexOutOfBoundsException e) {
            arguments[0].invalidate("Integer expected after colon.");
        }
    }


    @Override
    public void mainloop() {
        Log.i(TAG, "Main loop of File Playback called");
        final String[] split = arguments[0].getString().split(":");
        address = split[0];
        port = Integer.parseInt(split[1]);
        speedup = arguments[1].getDouble();
        buffsamp = arguments[2].getInteger();


        // print the current settings
        android.updateStatus("Buffer server: " + address + " : " + port);
        Log.i(TAG, "Buffer server: " + address + " : " + port);
        Log.i(TAG, "speedup : " + speedup);
        Log.i(TAG, "buffSamp : " + buffsamp);

        // Open the header/events/samples files
        initFiles();

        run = true;
        // open the connection to the buffer server
        while (!client.isConnected()) {
            android.updateStatus("Connecting to " + address + ":" + port);
            try {
                // FIXME causes android.os.NetworkOnMainThreadException
                client.connect(address, port);
            } catch (IOException ex) {
                Log.e(TAG, "Could not connect to the buffer. Maybe the address or port is wrong?");
            }
            if (!client.isConnected()) {
                android.updateStatus("Couldn't connect. Waiting");

                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }

        // send the header information
        // Load the header information in one go into a bytebuffer
        byte[] rawbytebuf = new byte[BUFFERSIZE];

        int n = 0;

        try {
            n = headerReader.read(rawbytebuf);
        } catch (IOException e) {
            e.printStackTrace();
        }


        // Byte-buffer used to parse the byte-stream. Force native ordering
        ByteBuffer hdrBuf = ByteBuffer.wrap(rawbytebuf, 0, n);
        hdrBuf.order(ByteOrder.nativeOrder());
        Header hdr = new Header(hdrBuf);
        if (VERB > 0) {
            android.updateStatus("Sending header: " + hdr.toString());
        }
        hdr.nSamples = 0; // reset number of samples to 0

        try {
            client.putHeader(hdr);
        } catch (IOException e) {
            e.printStackTrace();
        }


        // Interval between sending samples to the buffer
        int pktSamples = hdr.nChans * buffsamp; // number data samples in each buffer packet
        int pktBytes = pktSamples * DataType.wordSize[hdr.dataType];
        int nsamp = 0; // sample counter
        int nblk = 0;
        int nevent = 0;
        byte[] samples = new byte[pktBytes];

        // Size of the event header: type,type_numel,val,val_numel,sample,offset,duration,bufsz
        int evtHdrSz = DataType.wordSize[DataType.INT32] * 8;
        byte[] evtRawBuf = new byte[BUFFERSIZE]; // buffer to hold complete event structure

        // Byte-buffer used to parse the byte-stream. Force native ordering
        ByteBuffer evtBuf = ByteBuffer.wrap(evtRawBuf);
        evtBuf.order(ByteOrder.nativeOrder());
        int payloadSz = 0;
        int evtSample = 0;
        int evtSz = 0;
        long sample_ms = 0;
        long starttime_ms = java.lang.System.currentTimeMillis();
        long elapsed_ms = 0;
        long print_ms = 0;

        // Now do the data forwarding
        boolean eof = false;


        while (!eof && run) { //The run switch allows control of stopping the thread and getting out of the loop
            // Read one buffer packets worth of samples
            // increment the cursor position
            if (VERB > 0 && elapsed_ms > print_ms + 500) {
                print_ms = elapsed_ms;
                android.updateStatus(nblk + " " + nsamp + " " + nevent + " " + elapsed_ms / 1000 + " (blk,samp,event," +
                        "sec)\r");
            }


            // read and write the samples
            try {
                n = dataReader.read(samples);
            } catch (IOException e) {
                e.printStackTrace();
            }
            if (n <= 0) {
                eof = true;
                break;
            } // stop if run out of samples

            try {
                client.putRawData(buffsamp, hdr.nChans, hdr.dataType, samples);
            } catch (IOException e) {
                e.printStackTrace();
            }

            // update the sample count
            nsamp += buffsamp;
            while (evtSample <= nsamp) {
                if (evtSample > 0) { // send the current event
                    try {
                        client.putRawEvent(evtRawBuf, 0, evtSz);
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    nevent++;
                }

                // read the next event
                try {
                    n = eventReader.read(evtRawBuf, 0, evtHdrSz); // read the fixed size header
                } catch (IOException e) {
                    e.printStackTrace();
                }
                if (n <= 0) {
                    eof = true;
                    break;
                }
                evtSample = ((ByteBuffer) evtBuf.position(4 * 4)).getInt(); // sample index for this event
                payloadSz = ((ByteBuffer) evtBuf.position(4 * 7)).getInt(); // payload size for this event
                evtSz = evtHdrSz + payloadSz;

                // read the variable part
                try {
                    n = eventReader.read(evtRawBuf, evtHdrSz, payloadSz);
                } catch (IOException e) {
                    e.printStackTrace();
                }
                if (n <= 0) {
                    eof = true;
                    break;
                }

                // print the event we just read
                if (VERB > 1) {
                    ByteBuffer tmpev = ByteBuffer.wrap(evtRawBuf, 0, evtSz);
                    tmpev.order(evtBuf.order());
                    BufferEvent evt = new BufferEvent(tmpev);
                    android.updateStatus("Read Event: " + evt);
                }
            }

            // sleep until the next packet should be send OR EOF
            /*when to send the next sample */
            sample_ms = (long) ((float) (nsamp * 1000) / hdr.fSample / (float) speedup);
            elapsed_ms = java.lang.System.currentTimeMillis() - starttime_ms; // current time
            if (sample_ms > elapsed_ms) try {
                Thread.sleep(sample_ms - elapsed_ms);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            nblk++;
        }

        stop();
    }

    public void stop() {
        super.stop();
        try {
            cleanup();
            client.disconnect();
        } catch (final IOException e) {
            e.printStackTrace();
        }
    }


    void initFiles() {
        String samples_str = "res/raw/samples";
        String events_str = "res/raw/events";
        String header_str = "res/raw/header";
        dataReader = this.getClass().getClassLoader().getResourceAsStream(samples_str);
        eventReader = this.getClass().getClassLoader().getResourceAsStream(events_str);
        headerReader = this.getClass().getClassLoader().getResourceAsStream(header_str);
    }


    void cleanup() throws IOException {
        if (headerReader != null) {
            headerReader.close();
            headerReader = null;
        }
        if (eventReader != null) {
            eventReader.close();
            eventReader = null;
        }
        if (dataReader != null) {
            dataReader.close();
            dataReader = null;
        }
        run = false;
    }


}