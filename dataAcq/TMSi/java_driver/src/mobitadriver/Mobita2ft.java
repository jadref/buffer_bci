/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package mobitadriver;

import java.io.IOException;
import nl.fcdonders.fieldtrip.bufferclient.*;
import mobitadriver.*;

/**
 *
 * @author H.G. van den Boorn
 */
public class Mobita2ft {

    /**
     * < default bluetooth address
     */
//C++ TO JAVA CONVERTER NOTE: The following #define macro was replaced in-line:
//ORIGINAL LINE: #define DATATYPE_MOBITA (DATATYPE_FLOAT32)
//    private static final int WORDSIZE_MOBITA = WORDSIZE_FLOAT32;
    private static int BUFFRATE = 50; // rate (Hz) at which samples are sent to the buffer
/* N.B. for now only ratedivider of 0 or 1 seems to work!, larger causes samples to be missed... */
    private static int SAMPLERATEDIVIDER = 1; //*< log2 of sample rate divider
    private static final int MAXSAMPLE = -1; //10000;
 /* for timeout based execution */
    private static int BUFFERSUBSAMPLESIZE = 1; // number of buffer samples per amplifier sample
    private static int MAXMISSEDSAMPLES = 100; // number of missed samples in a row to cause exit.
    static int VERB = 0; // global verbosity level
    static int BUFFERSIZE = 65500;
    public tmsi tms = new tmsi();

//C++ TO JAVA CONVERTER TODO TASK: There is no preprocessor in Java:
///#if __WIN32__ || __WIN64__
//C++ TO JAVA CONVERTER TODO TASK: There is no preprocessor in Java:
    ///#if NOBACKGROUNDSCAN
    ///#endif
///#endif
    private void sig_handler(int sig) {
        System.out.format("\nStop grabbing with signal %d\n", sig);
        tms.tms_shutdown();
        tms.tms_close_log();
        //raise(SIGALRM);  
        System.exit(sig);
    }

    private int readresponse(int serverfd, messagedef_t responsedef) {
        /* N.B. this could happen at a later time */
        /* 2. Read the response */
        /* 2.1 Read response message */
        int n = 0;
        String responsebuf = null;
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
        if ((n = bufread(serverfd, responsedef, BUFFERSIZE)) != BUFFERSIZE) {
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
            System.err.format("packet size = %d, should be %d\n", n, BUFFERSIZE);
            sig_handler(-2);
        }
        /* 2.2 Read response data if needed */
        if (responsedef.bufsize > 0) {
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'malloc' has no equivalent in Java:
//            responsebuf = malloc(responsedef.bufsize);
            if ((n = bufread(serverfd, responsebuf, responsedef.bufsize)) != responsedef.bufsize) {
                System.err.format("read size = %d, should be %d\n", n, responsedef.bufsize);
                sig_handler(-2);
            }
            /* ignore the response and free the memory */
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'free' has no equivalent in Java:
//            free(responsebuf);
        }
        return 0;
    }

    private static void usage() {
        System.err.format("Usage: mobita2ft tmsisocket buffersocket buffrate sampleratedivider\n");
        System.err.format("where:\n");
        System.err.format("\t tmsisocket\t is a string of the form tmsihost:tmsiport               (%s)\n", DefineConstants.TMSIDEFAULT);
        System.err.format("\t buffersocket\t is a string of the form bufferhost:bufferport         (localhost:1972)\n");
        System.err.format("\t buffrate\t is the frequency in Hz that data is sent to the buffer    (%d)\n", BUFFRATE);
        System.err.format("\t buffsampledivider\t is number of amp-samples to use in each buffer sample (%d)\n", BUFFERSUBSAMPLESIZE);
        System.err.format("\t sampleratedivider\t is log2 of sample rate divider                   (%d)\n", SAMPLERATEDIVIDER);
        /*sig_handler(0);*/
    }

    public static void Main(String[] args) throws InterruptedException {
        Mobita2ft m = new Mobita2ft(args);
    }

    public Mobita2ft(String[] args) throws InterruptedException {

        int i;
        int j;
        int k;
        int nsamp = 0;
        int nblk = 0;
        int tmssamp = 0;
        int si = 0;
        int chi = 0;
        int status = 0;
        int verbose = 1;
        int nbad = 0;
        int putdatrequestsize = 0;
        int elapsedusec = 0;
        int sampleusec = 0;
        int printtime = 0;
        BufferClientClock buffhost = new BufferClientClock();
        RefObject<String> tmsidev; // string to hold the name of the driver device

        /* these represent the acquisition system properties */
        int nchans = -1;
        float fsample = -1F;
        int blocksize = 1;
        int channamesize = 0;
        String labelsbuf = "";

        /* these are used in the communication and represent statefull information */
        int serverfd = -1;
        message_t request = new message_t();
        String requestbuf = null;
        data_t data = new data_t();
        RefObject<Float[]> samples;
        message_t response = null;
        messagedef_t responsedef = new messagedef_t();
        String responsebuf = null;
        header_t header = new header_t();
        ft_chunkdef_t chunkdef = new ft_chunkdef_t(); // for holding the channel names
        int portnumber;
        String hostname;
        tmsi tms = new tmsi();

        /* these are specific structures for the acquisation device */
        TMS_CHANNEL_DATA_T[] channel; //*< channel data
        int srd = SAMPLERATEDIVIDER; //*< log2 of sample rate divider
        double starttime = tms.get_time();
        //        double starttime = new timeval();
        //        double curtime = new timeval();
        () signal(SIGINT, sig_handler);

//C++ TO JAVA CONVERTER TODO TASK: There is no preprocessor in Java:
///#if __WIN32__ || __WIN64__
//        WSADATA wsa_data = new WSADATA();
//        WSAStartup(MAKEWORD(1, 1), wsa_data);
///#endif
//                if (args.length == 1 || (args.length > 1 && ((args[1] == "-help") 0 || (args[1]== "-h")))) {
        if (args.length == 1 || (args.length > 1 && (args[1].equals("-help") || args[1].equals("-h")))) {
            usage();
        }

        if (args.length > 1) {
            tmsidev = new RefObject<>(args[1]);
        } else {
            tmsidev = new RefObject<>(DefineConstants.TMSIDEFAULT);
        }
        if (verbose > 0) {
            System.err.format("mobita2ft: tmsidev = %s\n", tmsidev);
        }

        if (args.length > 2) {
            String fname = args[2];
            int ci = 0;
            /* find the which splits the host and port info */
            portnumber = Integer.valueOf(fname.split("\\:")[1]);
//            for (ci = 0; fname.charAt(ci) != 0; ci++) {
//                if (fname.charAt(ci) == ':') { // parse the port info
//                    portnumber = Integer.parseInt((fname.charAt(ci + 1)+""));
//                    break;
//                }
//            }
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'memcpy' has no equivalent in Java:
//            memcpy(buffhost.name, fname, ci);
//            buffhost.name[ci] = 0; // copy hostname out and null-terminate
            hostname = fname.split("\\:")[0];
        } else {
            hostname = DefineConstants.DEFAULTHOSTNAME;
            portnumber = DefineConstants.DEFAULTPORT;
        }
        if (verbose > 0) {
            System.err.format("mobita2ft: buffer = %s:%d\n", hostname, portnumber);
        }

        if (args.length > 3) {
            BUFFRATE = Integer.parseInt(args[3]);
            if (verbose > 0) {
                System.err.format("mobita2ft: BUFFRATE = %d\n", BUFFRATE);
            }
        }
        if (args.length > 4) {
            BUFFERSUBSAMPLESIZE = Integer.parseInt(args[4]);
            if (verbose > 0) {
                System.err.format("mobita2ft: BUFFERSAMPLERATEDIVIDER = %d\n", BUFFERSUBSAMPLESIZE);
            }
        }
        if (args.length > 5) {
            SAMPLERATEDIVIDER = Integer.parseInt(args[5]);
            if (verbose > 0) {
                System.err.format("mobita2ft: SAMPLERATEDIVIDER = %d\n", SAMPLERATEDIVIDER);
            }
        }

        //-------------------------------------------------------------------------------
        // open the mobita device
        status = tms.tms_init(tmsidev, srd);
        if (status != 0) {
            System.err.format("mobita2ft: CANNOT CONNECT: %d\n", status);
//            return 1;
        }

        channel = tms.tms_alloc_channel_data();
        if (channel == null) {
            System.err.format("mobita2ft: # main: tms_alloc_channel_data problem!! basesamplerate!\n");
            sig_handler(-3);
        }
        System.err.format("mobita2ft: Connected\n");
        nchans = tms.tms_get_number_of_channels();
        fsample = (float) (tmsi.tms_get_sample_freq() / (double) BUFFERSUBSAMPLESIZE);
        blocksize = (int) (fsample / ((float) BUFFRATE));
        if (verbose > 0) {
            System.err.format("mobita2ft: fsample=%f  blocksize = %d\n", fsample, blocksize);
        }

        //-------------------------------------------------------------------------------
  /* allocate the elements that will be used in the buffer communication */
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'malloc' has no equivalent in Java:
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
        request.def = malloc(sizeof(messagedef_t));
        request.buf = null;
        request.def.argValue.version = DefineConstants.VERSION;
        request.def.argValue.bufsize = 0;

//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'malloc' has no equivalent in Java:
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
        header.def = malloc(sizeof(headerdef_t));
        header.buf = null; // header buf contains the channel names
        //header.buf = labels;

        /* define the header */
        header.def.argValue.nchans = nchans;
        header.def.argValue.nsamples = 0;
        header.def.argValue.nevents = 0;
        header.def.argValue.fsample = fsample;
        header.def.argValue.data_type = Float.TYPE;
        header.def.argValue.bufsize = 0;

        //-------------------------------------------------------------------------------
  /* define the stuff for the channel names */
        /* compute the size of the channel names set */
        channamesize = 0;
        for (i = 0; i < nchans; i++) {
            for (j = 0; tms.tms_get_in_dev().Channel[i].ChannelDescription.charAt(j) != '\0'; j++) {
                ;
            }
            j++;
            channamesize += j;
        }
        /* allocate the memory for the channel names, and copy them into it */
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'malloc' has no equivalent in Java:
//        labelsbuf = malloc(WORDSIZE_CHAR * channamesize);
        k = 0;
        for (i = 0; i < nchans; i++) {
            for (j = 0; tms.tms_get_in_dev().Channel[i].ChannelDescription.charAt(j) != '\0'; j++, k++) {
                labelsbuf += tms.tms_get_in_dev().Channel[i].ChannelDescription.charAt(j);
            }
            labelsbuf += tms.tms_get_in_dev().Channel[i].ChannelDescription.charAt(j);
            k++;
        }

        chunkdef.type = DefineConstants.FT_CHUNK_CHANNEL_NAMES;
        chunkdef.size = k;
        // add this info to the header buffer
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
        header.def.argValue.bufsize = append(header.buf, header.def.argValue.bufsize, chunkdef, sizeof(ft_chunkdef_t));
        header.def.argValue.bufsize = append(header.buf, header.def.argValue.bufsize, labelsbuf, chunkdef.size);

        //-------------------------------------------------------------------------------
  /* initialization phase, send the header */
        request.def.argValue.command = PUT_HDR;
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
        request.def.argValue.bufsize = append(request.buf, request.def.argValue.bufsize, header.def, sizeof(headerdef_t));
        request.def.argValue.bufsize = append(request.buf, request.def.argValue.bufsize, header.buf, header.def.argValue.bufsize);

        System.err.format("mobita2ft: Attempting to open connection to buffer....");

        while (!buffhost.isConnected()) {
            System.out.println("Connecting to " + hostname + ":" + portnumber);
            try {
                buffhost.connect(hostname, portnumber);
            } catch (IOException ex) {
            }
            if (!buffhost.isConnected()) {
                System.out.println("Couldn't connect. Waiting");
                Thread.sleep(1000);
            }
        }
//        while ((serverfd = tms.open_connection(hostname, portnumber)) < 0) {
//            System.err.format("mobita2ft; failed to create socket. waiting\n");
//            usleep(1000000); // sleep for 1second and retry
//        }
        System.err.format("done.\nSending header...");
        status = tms.tcprequest(serverfd, request, response);
        System.err.format("done.\n");
        if (verbose > 1) {
            System.err.format("mobita2ft: tcprequest returned %d\n", status);
        }
        if (status > 0) {
            System.err.format("mobita2ft: put header error = %d\n", status);
            sig_handler(-4);
        }
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'free' has no equivalent in Java:
        request.buf=null;
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'free' has no equivalent in Java:
        request.def=null;

        if (response.def.argValue.command != PUT_OK) {
            System.err.format("mobita2ft: error in 'put header' request.\n");
            sig_handler(-5);
        }
//        response.buf=null;
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'free' has no equivalent in Java:
//        response.def=null;
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'free' has no equivalent in Java:
        response = null;

        /* add a small pause between writing header + first data block */
        Thread.sleep(2000);

        //-------------------------------------------------------------------------------

        /* allocate space for the putdata request as 1 block, this contains
         [ request_def data_def data ] */
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
        putdatrequestsize = sizeof(messagedef_t) + sizeof(datadef_t) + WORDSIZE_MOBITA * nchans * blocksize;
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'malloc' has no equivalent in Java:
//        requestbuf = malloc(putdatrequestsize);
        /* define the constant part of the send-data request and allocate space for the variable part */
        request.def.argValue = requestbuf;
        request.buf.argValue = request.def + 1; // N.B. cool pointer arithemetic trick for above!
        request.def.argValue.version = DefineConstants.VERSION;
        request.def.argValue.command = PUT_DAT;
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
        request.def.bufsize = putdatrequestsize - sizeof(messagedef_t);
        /* setup the data part of the message */
        data.def.argValue = request.buf.argValue;
        data.buf.argValue = data.def + 1; // N.B. cool pointer arithemetic trick for above
        samples = data.buf; // version with correct type
  /* define the constant part of the data */
        data.def.nchans = nchans;
        data.def.nsamples = blocksize;
        data.def.data_type = DATATYPE_MOBITA;
        data.def.bufsize = WORDSIZE_MOBITA * nchans * blocksize;

        //-------------------------------------------------------------------------------
        // Loop sending the data in blocks as it becomes available
        starttime = tms.get_time(); // get time we started to compute delay before next sample
        while (true) {

            //-------------------------------------------------------------------------------
            if (BUFFERSUBSAMPLESIZE > 1) {
                for (i = 0; i < blocksize * nchans; i++) {
                    samples.argValue[i] = 0.0f;
                }
            }
            for (si = 0; si < blocksize * BUFFERSUBSAMPLESIZE; si++) { // get a block's worth of TMSIsamples
                // -- assumes 1 sample per call!
		/* get the new data */
                tmssamp = 0;
                while (tmssamp <= 0) { // get new data samples
                    tmssamp = tms.tms_get_samples(channel);
                    if (tmssamp != nchans) {
                        nbad++;
                        /* Note: the number of samples returned by the tms_get_samples seems
                         to be garbage so ignore it for now */
                        System.err.format("mobita2ft: tms_get_samples error got %d samples when expected 1.\n", tmssamp);
                        if (nbad < MAXMISSEDSAMPLES) {
                            Thread.sleep(1); // sleep for 500 micro-seconds = .5ms -- to stop cpu hogging
                            continue;
                        } else {
                            System.err.format("mobita2ft: tmp_get_samples returned *BAD* samples too many times.\n");
                            sig_handler(-6);
                        }
                    } else {
                        if (nbad > 0) {
                            nbad--;
                        }
                    }
                }

                // copy the samples into the data buffer, in the order we
                if (BUFFERSUBSAMPLESIZE > 1) { // accumulate over BUFFERSUBSAMPLESIZE device samples
                    int buffsi = si / BUFFERSUBSAMPLESIZE; // sample index in the buffer data packet
                    for (chi = 0; chi < nchans; chi++) {
                        samples.argValue[(buffsi * nchans) + chi] += channel[chi].data[channel[chi].rs - 1].sample;
                    }
                } else { // 1 amp sample per buffer sample
                    for (chi = 0; chi < nchans; chi++) {
                        samples.argValue[(si * nchans) + chi] = channel[chi].data[channel[chi].rs - 1].sample;
                    }
                }
                nsamp += 1; //nsamp;
            }
            if (BUFFERSUBSAMPLESIZE > 1) { // convert multi-samples summs into means
                for (i = 0; i < blocksize * nchans; i++) {
                    samples.argValue[i] /= BUFFERSUBSAMPLESIZE;
                }
            }
            if (MAXSAMPLE > 0 && nsamp > MAXSAMPLE) {
                break;
            }

            //-------------------------------------------------------------------------------
	 /* send the data to the buffer */
            /* 0. If send data already read response to previous put-data */
            if (nblk > 0) {
                if (readresponse(serverfd, responsedef) != 0 || responsedef.command != PUT_OK) {
                    System.err.format("mobita2ft: Error writing samples.\n");
                }
            }

            /* 1. Send the new data, but don't wait for a response */
            if ((k = bufwrite(serverfd, request.def, putdatrequestsize)) != putdatrequestsize) {
                System.err.format("write size = %d, should be %d\n", k, putdatrequestsize);
                sig_handler(-7);
            }


            /* do some logging */
//            gettimeofday(curtime, null);
            double curtime = tms.get_time();
            elapsedusec = (int) (curtime - starttime);
            if (elapsedusec / 1000000 >= printtime) {
                System.err.format("%d %d %d %f (blk,samp,event,sec)\r", nblk, nsamp, 0, elapsedusec / 1000000.0);
                printtime += 10;
            }
            nblk += 1;
        } // while(1)

        // free all the stuff we've allocated
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'free' has no equivalent in Java:
//        free(labelsbuf);
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'free' has no equivalent in Java:
//        free(requestbuf);
//C++ TO JAVA CONVERTER TODO TASK: There is no preprocessor in Java:
///#if __WIN32__ || __WIN64__
//        WSACleanup();
///#endif
        sig_handler(0);
    }

    public class messagedef_t {

        public int version; // see VERSION
        public int command; // see PUT_xxx, GET_xxx and FLUSH_xxx
        public long bufsize; // size of the buffer in bytes
    }

    public class message_t {

        public RefObject<messagedef_t> def;
        public RefObject<Object> buf;
    }

    /* the data definition is fixed */
    public class datadef_t {

        public int nchans;
        public int nsamples;
        public int data_type;
        public int bufsize; // size of the buffer in bytes
    }

    public class data_t {

        public RefObject<datadef_t> def;
        public RefObject<Object> buf;
    }

    /* the header definition is fixed, except for the channel labels */
    public class headerdef_t {

        public int nchans;
        public int nsamples;
        public int nevents;
        public int fsample;
        public int data_type;
        public int bufsize; // size of the buffer in bytes
    }

    public class header_t {

        public RefObject<headerdef_t> def;
        public RefObject<Object> buf; // FIXME this should contain the channel names
    }

    /* the event definition is fixed */
    public class eventdef_t {

        public int type_type; // usual would be DATATYPE_CHAR
        public int type_numel; // length of the type string
        public int value_type;
        public int value_numel;
        public int sample;
        public int offset;
        public int duration;
        public int bufsize; // size of the buffer in bytes
    }

    public class event_t {

        public RefObject<eventdef_t> def;
        public RefObject<Object> buf;
    }

    public class datasel_t {

        public int begsample; // indexing starts with 0, should be >=0
        public int endsample; // indexing starts with 0, should be <header.nsamples
    }

    public class eventsel_t {

        public int begevent;
        public int endevent;
    }

    public class samples_events_t {

        public int nsamples;
        public int nevents;
    }

    public class waitdef_t {

        public samples_events_t threshold = new samples_events_t();
        public int milliseconds;
    }

    public class ft_chunkdef_t {

        public int type; // One of FT_CHUNK_** (see above)
        public int size; // Size of chunk.data, total size is given by adding sizeof(ft_chunkdef_t)=8
    }

    public class ft_chunk_t {

        public ft_chunkdef_t def = new ft_chunkdef_t(); // See above. Note that this is not a pointer!
        public String data = new String(new char[1]); // Data contained in this chunk
    }
}
