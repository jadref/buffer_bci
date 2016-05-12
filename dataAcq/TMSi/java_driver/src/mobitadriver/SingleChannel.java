/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package mobitadriver;

import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 *
 * @author H.G. van den Boorn
 */
public class SingleChannel {

    private static int dbg = 0x0000; //*< debug level
    private static int vb = 0x0000; //*< verbose level
    private static tmsi tms = new tmsi();

    /**
     * Print usage to file 'fp'.
     *
     * @return number of printed characters.
     */
    private static int single_channel_intro(PrintStream fp) {

        int nc = 0;

        fp = fp.format("single_channel: %s\n", DefineConstants.VERSION);
        fp = fp.format("Usage: single_channel [-i <in>] [-o <out>] [-c <chn>] [-t <sd>] [-s <srd>] [-l <log>] [-v <vb>] [-d <dbg>] [-h]\n");
        fp = fp.format("  Press CTRL+c to stop capturing bio-data\n");
        fp = fp.format("in   : bluetooth address (default=%s)\n", DefineConstants.INDEF);
        fp = fp.format("out  : output report file (default=%s)\n", DefineConstants.OUTDEF);
        fp = fp.format("chn  : channel report selection [0..13] (default=%d)\n", DefineConstants.CHNDEF);
        fp = fp.format("srd  : log2 of sample rate divider: fs=2048/(1<<srd) (default=%d)\n", DefineConstants.SRDDEF);
        fp = fp.format("sd   : sampling duration (0.0 = forever) (default=%6.3f)\n", DefineConstants.SDDEF);
        fp = fp.format("log  : packet logging file (default=%s)\n", DefineConstants.LOGDEF);
        fp = fp.format("h    : show this manual page\n");
        fp = fp.format("vb   : verbose switch (default=0x%02X)\n", vb);
        fp = fp.format("        0x01 : log all packets in log\n");
        fp = fp.format("dbg  : debug value (default=0x%02X)\n", dbg);
        return (1);
    }

    private static void parse_cmd(int argc, String[] argv, RefObject<String> iname, RefObject<String> oname, RefObject<String> lname, RefObject<Integer> srd, RefObject<Integer> chn, RefObject<Double> sd) {

        int i; //*< general index
        LocalDateTime now = LocalDateTime.now();

        iname.argValue = DefineConstants.INDEF;
        oname.argValue = "";
        lname.argValue = DefineConstants.LOGDEF;
        srd.argValue = DefineConstants.SRDDEF;
        chn.argValue = DefineConstants.CHNDEF;
        sd.argValue = DefineConstants.SDDEF;

        for (i = 1; i < argc; i++) {
            if (argv[i].charAt(0) != '-') {
                System.out.printf("missing - in argument %s\n", argv[i]);
            } else {
                switch (argv[i].charAt(1)) {
                    case 'i':
                        iname.argValue = argv[++i];
                        break;
                    case 'o':
                        oname.argValue = argv[++i];
                        break;
                    case 'l':
                        lname.argValue = argv[++i];
                        break;
                    case 'c':
//                        chn.argValue = strtol(argv[++i], null, 0);
                        chn.argValue = (int) tmsi.strtol(argv[++i], null, i, 0);
                        break;
                    case 't':
                        sd.argValue = (double) tmsi.strtol(argv[++i], null, i, 0);
                        break;
                    case 's':
                        srd.argValue = (int) tmsi.strtol(argv[++i], null, i, 0);
                        break;
                    case 'v':
                        vb = (int) tmsi.strtol(argv[++i], null, i, 0);
                        break;
                    case 'd':
                        dbg = (int) tmsi.strtol(argv[++i], null, i, 0);
                        break;
                    case 'h':
                        single_channel_intro(System.err);
                        System.exit(0);
                        break;
                    default:
                        System.out.printf("can't understand argument %s\n", argv[i]);
                }
            }
        }
        if (srd.argValue < 0) {
            srd.argValue = 0;
        }
        if (srd.argValue > 4) {
            srd.argValue = 4;
        }

        if (oname.argValue.length() < 1) {
            /* use day and current time as file name */
//            time(now);
            now = LocalDateTime.now();
//            t0 = localtime(now);
            oname.argValue = now.format(DateTimeFormatter.ofPattern("%Y%m%d_%H%M%S")) + ".txt";
//            strftime(oname.argValue, DefineConstants.MNCN, "%Y%m%d_%H%M%S.txt", t0);
        }

    }

    private void sig_handler(int sig) {
        System.out.format("\nStop grabbing with signal %d\n", sig);
        tms.tms_shutdown();
        tms.tms_close_log();
        System.exit(sig);
    }

    final class DefineConstants {

        public static final int MNCN = 1024; //*< Maximum number of characters in file name
        public static final String INDEF = "00:A0:96:1B:44:C6"; //*< default bluetooth address
        public static final String OUTDEF = "%Y%m%d_%H%M%S.txt"; //*< default output filename
        public static final int CHNDEF = 0; //*< default swith report channel
        public static final String LOGDEF = "nexus.log"; //*< default logging filename
        public static final double SDDEF = 5.0; //*< default maximum number of samples
        public static final int SRDDEF = 0; //*< default log2 of sample rate divider
        public static final String VERSION = "$Revision: 0.2 $ $Date: 2008/01/07 16:30:00 $";
    }

    public static void main(String[] args) {
        PrintStream fp = null; //*< report file pointer
        PrintStream fpl = null; //*< log file pointer
        RefObject<String> iname = new RefObject<>(new String(new char[DefineConstants.MNCN])); //*< bluetooth address
        RefObject<String> oname = new RefObject<>(new String(new char[DefineConstants.MNCN])); //*< output report file
        RefObject<String> lname = new RefObject<>(new String(new char[DefineConstants.MNCN])); //*< output logging file
        RefObject<Integer> srd = new RefObject<>(0); //*< log2 of sample rate divider
        RefObject<Integer> chn = new RefObject<>(0); //*< channel switch
        RefObject<Double> sd = new RefObject<>(0.0); //*< maximum number of samples
        TMS_CHANNEL_DATA_T[] channel; //*< channel data
        int i;
//        () signal(SIGINT, sig_handler);

        /* parse command line arguments */
        parse_cmd(args.length, args, iname, oname, lname, srd, chn, sd);

        /* set debug level in tms module */
        tms.tms_set_vb(vb);

        /* open log file for verbose output */
        if (vb > 0) {
            fpl = tms.tms_open_log(lname, new RefObject<String>("w"));
        }

        tms.tms_init(iname, srd.argValue);

        channel = tms.tms_alloc_channel_data();
        if (channel == null) {
            System.err.println("# main: tms_alloc_channel_data problem!!basesamplerate!\n");
            System.exit(-1);
        }

        if (chn.argValue >= tms.tms_get_number_of_channels() || chn.argValue < 0) {
            System.err.format("Incorrect channel number %d\n", chn);
            System.exit(-1);
        }

        System.err.format("Write data values to file: %s\n", oname);
        try {
            fp = new PrintStream(oname.argValue);
        } catch (FileNotFoundException ex) {
            System.err.println("Data files could not be written");
            System.exit(-1);
        }

        fp.format("#%9s %8s %1c%8s %1c%8s %2s\n", "t[s]", "nr", "A" + chn.argValue, "sample", "A" + chn.toString(), "isample", "fl");

        /* grab sample to 'sd' seconds or forever if 'sd==0.0' */
        while ((sd.argValue == 0.0) || (tms.tms_elapsed_time(channel) < sd.argValue)) {
            tms.tms_get_samples(channel);
            for (i = 0; i < channel[chn.argValue].rs; i++) {
                fp.format(" %9.4f %8d %9g %9d %2d\n", (channel[chn.argValue].sc + i) * channel[chn.argValue].td, channel[chn.argValue].sc + i, channel[chn.argValue].data[i].sample, channel[chn.argValue].data[i].isample, channel[chn.argValue].data[i].flag);
            }
        }

        fp.close();
        tms.tms_shutdown();
        tms.tms_close_log();
    }

}
