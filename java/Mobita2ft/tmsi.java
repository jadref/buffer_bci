/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package nl.dcc.buffer_bci;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketException;
import java.net.UnknownHostException;

// TODO: convert to non java8 version for backward compatability
import java.util.Date;
// import java.time.Instant;
// import java.time.LocalDateTime;
// import java.time.ZoneId;
// import java.time.ZoneOffset;
// import java.time.format.DateTimeFormatter;

import java.util.Calendar;
import java.util.Date;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author H.G. van den Boorn
 */
public class tmsi {

    final String VERSION = "$Revision: 0.1 $";
    final static int TMSBLOCKSYNC = (0xAAAA);
    /**
     * < TMS block sync word
     */
    final int RESPSIZE = 2048; /* max size of the response message */

    static int vb = 0x0000;
    /**
     * < verbose level
     */
    static PrintStream fpl = null;
    static String filename = null;
    /**
     * < log file pointer
     */

    static TMS_FRONTENDINFO_T fei = null;
    /**
     * < storage for all frontend info structs
     */
    static TMS_VLDELTA_INFO_T vld = null;
    static TMS_INPUT_DEVICE_T in_dev = null;
    static int TMSFRONTENDINFOSIZE = 14 * 2 + 4;//(sizeof(TMS_FRONTENDINFO_T));
    public static final int DEFAULTPORT = 4242; //*< default port number for the frontend server >*
    public static final int ZAAGCH = 13; //*< default channels for sawtooth signal >*
    public static final int MNCN = 1024; //*< maximum characters in filename
    public static final int TMSACKNOWLEDGE = 0x00;
    public static final int TMSCHANNELDATA = 0x01;
    public static final int TMSFRONTENDINFOREQ = 0x03;
    public static final int TMSRTCREADREQ = 0x06;
    public static final int TMSRTCDATA = 0x07;
    public static final int TMSRTCTIMEREADREQ = 0x1E;
    public static final int TMSRTCTIMEDATA = 0x1F;
    public static final int TMSFRONTENDINFO = 0x02;
    public static final int TMSKEEPALIVEREQ = 0x27;
    public static final int TMSVLDELTADATA = 0x2F;
    public static final int TMSVLDELTAINFOREQ = 0x30;
    public static final int TMSVLDELTAINFO = 0x31;
    public static final int TMSIDREADREQ = 0x22;
    public static final int TMSIDDATA = 0x23;
    public static final int TMSCFGSIZE = 1024;

    /**
     * set verbose level of module TMS to 'new_vb'.
     *
     * @return old verbose value
     */
    public int tms_set_vb(int new_vb) {

        int old_vb = vb;

        vb = new_vb;
        return (old_vb);
    }

    /**
     * get verbose variable for module TMS
     *
     * @return current verbose level
     */
    public int tms_get_vb() {
        return (vb);
    }

// A uint32_t send from PC to the front end: first low uint16_t, second high uint16_t
// A uint32_t send from front end to the PC: first low uint16_t, second high uint16_t
// EXCEPTION: channeldata samples are transmitted as first high uint16_t, second low uint16_t
// When transmitted as bytes (serial interface): first low-byte, then hi-byte
    /**
     * Get current time in [sec] since 1970-01-01 00:00:00.
     *
     * @note current time has micro-seconds resolution.
     * @return current time in [sec].
     */
    public double get_time() {
        long ms = System.currentTimeMillis() * 1000;
        return ((double) ms) * 1e-6;
    }

    /**
     * Get integer of 'n' bytes from byte array 'msg' starting at position 's'.
     *
     * @note n<=4 to avoid bit loss @note on return s tart position 's' is
     * incremented with 'n'. @return integer value.
     */
    public int TMS_GET_INT(byte[] msg, RefObject<Integer> s, int n) {

        int i; //*< general index
        int b = 0; //*< temp result

        /* skip overflow bytes */
        if (n > 4) {
            n = 4;
        }
        /* get MSB byte first */
        for (i = n - 1; i >= 0; i--) {
            b = (b << 8) | (msg[s.argValue + i] & 0xFF);
        }
        /* increment start position 's' */
        s.argValue += n;
        return (b);
    }

    /**
     * Put 'n' LSB bytes of 'a' into byte array 'msg' starting at location 's'.
     *
     * @note n<=4. @ note start location is incremented at return. @return
     * number of bytes put.
     */
    public int TMS_PUT_INT(int a, byte[] msg, RefObject<Integer> s, int n) {

        int i = 0;

        if (n > 4) {
            n = 4;
        }

        for (i = 0; i < n; i++) {
				//System.out.format("byte %d = %02x\n",i,(byte) (a & 0x00FF));
            msg[s.argValue + i] = (byte) (a & 0x00FF);
//C++ TO JAVA CONVERTER WARNING: The right shift operator was not replaced by Java's logical right shift operator since the left operand was not confirmed to be of an unsigned type, but you should review whether the logical right shift operator (>>>) is more appropriate:
            a = (a >>> 8);
				//System.out.format("%04x ",i,msg[s.argValue+i]);
        }
        /* increment start location */
        s.argValue += n;
        /* return number of byte processed */
        return (n);
    }

    /* byte reverse */
    public byte tms_byte_reverse(byte a) {
        byte b = 0;
        for (int i = 0; i < 8; i++) {
            b = (byte) ((b << ((byte) 1)) | (a & ((byte) 0x01)));
//C++ TO JAVA CONVERTER WARNING: The right shift operator was replaced by Java's logical right shift operator since the left operand was originally of an unsigned type, but you should confirm this replacement:
            a = (byte) (a >>> 1);
        }
        return b;
    }

    /**
     * Grep 'n' bits signed long integer from byte buffer 'buf'
     *
     * @note most significant byte first.
     * @return 'n' bits signed integer
	  *
	  * TODO: Validate this extraction works with out roundoff issues
     */
    public int get_int32_t(byte[] buf, RefObject<Integer> bip, int n) {

        int i = bip.argValue; //*< start location
        int a = 0; //*< wanted integer value
        int mb; //*< maximum usefull bits in 'byte[i/8]'
        int wb; //*< number of wanted bits in current byte 'buf[i/8]'

        while (n > 0) {
            /* calculate number of usefull bits in this byte */
            mb = 8 - (i % 8);
            /* select maximum needed number of bits */
            if (n > mb) {
                wb = mb;
            } else {
                wb = n;
            }
            /* grep 'wb' bits out of byte 'buf[i/8]' */
//C++ TO JAVA CONVERTER WARNING: The right shift operator was not replaced by Java's logical right shift operator since the left operand was not confirmed to be of an unsigned type, but you should review whether the logical right shift operator (>>>) is more appropriate:
            a = (a << wb) | ((buf[i / 8] >>> (mb - wb)) & ((1 << wb) - 1));
            /* decrement number of needed bits, and increment bit index */
            n -= wb;
            i += wb;
        }

        /* put back resulting bit position */
        bip.argValue = i;
        return (a);
    }

    /**
     * Grep 'n' bits signed long integer from byte buffer 'buf'
     *
     * @note least significant byte first.
     * @return 'n' bits signed integer
     */
    public int get_lsbf_int32_t(byte[] buf, RefObject<Integer> bip, int n) {

        int i = bip.argValue; //*< start location
        int a = 0; //*< wanted integer value
        int mb; //*< maximum usefull bits in 'byte[i/8]'
        int wb; //*< number of wanted bits in current byte 'buf[i/8]'
        int m = 0; //*< number of already written bits in 'a'

        while (n > 0) {
            /* calculate number of usefull bits in this byte */
            mb = 8 - (i % 8);
            /* select maximum needed number of bits */
            if (n > mb) {
                wb = mb;
            } else {
                wb = n;
            }
            /* grep 'wb' bits out of byte 'buf[i/8]' */
//C++ TO JAVA CONVERTER WARNING: The right shift operator was not replaced by Java's logical right shift operator since the left operand was not confirmed to be of an unsigned type, but you should review whether the logical right shift operator (>>>) is more appropriate:
            a |= (((buf[i / 8] >> (i % 8)) & ((1 << wb) - 1))) << m;
            /* decrement number of needed bits, and increment bit index */
            n -= wb;
            i += wb;
            m += wb;
        }
        /* put back resulting bit position */
        bip.argValue = i;

        return (a);
    }

    /**
     * Grep 'n' bits sign extented long integer from byte buffer 'buf'
     *
     * @note least significant byte first.
     * @return 'n' bits signed integer
     */
    public int get_lsbf_int32_t_sign_ext(byte[] buf, RefObject<Integer> bip, int n) {
        int a;

        a = get_lsbf_int32_t(buf, bip, n);
        /* check MSB-1 bits */
        if ((1 << (n - 1) & a) == 0) {
            /* add heading one bits for negative numbers */
            a = (~((1 << n) - 1)) | a;
        }
        return (a);
    }

    /**
     * Get 4 byte long float for 'buf' starting at byte 'sb'.
     *
     * @return float
     */
    public float tms_get_float(byte[] msg, RefObject<Integer> sb) {

        float sign;
        int expi;
        float mant;
        int manti;
        RefObject<Integer> bip = new RefObject<Integer>(0);
        float a;
        int i;
        byte[] buf = new byte[4];

        buf[0] = msg[sb.argValue + 3];
        buf[1] = msg[sb.argValue + 2];
        buf[2] = msg[sb.argValue + 1];
        buf[3] = msg[sb.argValue + 0];

        if ((buf[0] == 0) && (buf[1] == 0) && (buf[2] == 0) && (buf[3] == 0)) {
            sb.argValue += 4;
            return ((float) 0.0);
        }
        /* fetch sign bit */
        if (get_int32_t(buf, bip, 1) == 1) {
            sign = -1.0F;
        } else {
            sign = +1.0F;
        }
        /* fetch 8 bits exponent */
        expi = get_int32_t(buf, bip, 8);
        /* fetch 23 bits mantissa */
        manti = (get_int32_t(buf, bip, 23) + (1 << 23));
        mant = (float) (manti);

        if ((vb & 0x10) != 0) {
            for (i = 0; i < 4; i++) {
                System.err.format(" %02X", buf[i]);
            }
            System.err.format(" sign %2.1f expi %6xd manti 0x%06X\n", sign, expi, manti);
            /* print this only once */
            vb = vb & ~0x10;
        }
        /* construct float */
        /* f = ((h&0x8000)<<16) | (((h&0x7c00)+0x1C000)<<13) | ((h&0x03FF)<<13).
         00)<<16) | (((h&0x7c00)+0x1C000)<<13) | ((h&0x03FF)<<13). */

        //a=sign*mant*pow(2.0,(float)(expo-23-127));
        a = sign*mant*((float)Math.pow(2.0F, expi - 23 - 127));

        /* 4 bytes float */
        sb.argValue += 4;
        /* return found float 'a' */
        return (a);
    }

    /**
     * Get string starting at position 'start' of message 'msg' of 'n' bytes.
     *
     * @note will malloc storage space for the null terminated string.
     * @return pointer to string or NULL on no success.
     */
    public String tms_get_string(byte[] msg, int n, int start) {

        int size; //*< string size [byte]
        RefObject<Integer> i = new RefObject(start); //*< general index
        String str=null; //*< string pointer

        size = 2 * (TMS_GET_INT(msg, i, 2) - 1);
        if (i.argValue + size > n) {
            System.err.format("# Error: tms_get_string: index 0x%04X out of range 0x%04X\n", i.argValue + size, n);
        } else {
            /* malloc space for the string */
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'malloc' has no equivalent in Java:
            /* copy content */
            if (str == null) {
                str = ((char) ((byte) msg[i.argValue])) + "";
            } else {
                str += ((char) ((byte) msg[i.argValue])) + "";
            }
        }
        return str;
    }

    /**
     * Calculate checksum of message 'msg' of 'n' bytes.
     *
     * @return checksum.
     */
    public short tms_cal_chksum(byte[] msg, int n) {

        int i; //*< general index
		  int tmp=0;
        int sum = 0; //*< checksum

		  //System.out.format("chksum 0 = %08x\n",sum);
		  // Argh! all primitive types in java are signed!!! including byte... thus byte>a0 -> neg number
        for (i = 0; i < n; i+=2) {
				tmp= ((int)msg[i]) & 0x00ff;                         //LSByte
            sum += tmp;
				//System.out.format("chksum %d.l : + %02x(%04x) = %08x\n",i,msg[i],tmp,sum);
				tmp= ( ((int)msg[i + 1]) & 0x00ff) << 8;             //MSByte
				sum += tmp;   //MSByte
				//System.out.format("chksum %d.m : + %02x(%04x) = %08x\n",i,msg[i + 1],tmp,sum);
        }
        return (short)(sum & 0xFFFF);
    }

    /**
     * Check checksum buffer 'msg' of 'n' bytes.
     *
     * @return packet type.
     */
    public short tms_get_type(byte[] msg, int n) {

        short rv = (short) msg[3]; //*< packet type

        return (rv);
    }

    /**
     * Get payload size of TMS message 'msg' of 'n' bytes.
     *
     * @note 'i' will return start byte address of payload.
     * @return payload size.
     */
    public int TMS_MSG_SIZE(byte[] msg, int n, RefObject<Integer> i) {

        int size = 0; //*< payload size

        i.argValue = 2; // address location
        size = TMS_GET_INT(msg, i, 1);
        i.argValue = 4;
        if (size == 0xFF) {
            size = TMS_GET_INT(msg, i, 4);
        }
        return (size);
    }

    /**
     * Open TMS log file with name 'fname' and mode 'md'.
     *
     * @return file pointer.
     */
    public PrintStream tms_open_log(String fname, RefObject<String> md) {

        try {
            fpl = new PrintStream(fname);
            filename = fname;
        } catch (FileNotFoundException ex) {
            System.err.println("Error on opening log file");
        }
        return (fpl);
    }

    /**
     * Close TMS log file
     *
     * @return 0 in success.
     */
    public int tms_close_log() {

        /* close log file */
        if (fpl != null) {
            fpl.close();
        }
        return (0);
    }
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public int TMS_WRITE_LOG_MSG_nr = 0;

    /**
     * Log TMS buffer 'msg' of 'n' bytes to log file.
     *
     * @return return number of printed characters.
     */
    public int TMS_WRITE_LOG_MSG(byte[] msg, int n, String comment) {

//C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
//  static int nr=0; //*< message counter
        int nc = 0; //*< number of characters printed
        int sync; //*< sync
        int type; //*< type
        int size; //*< payload size
        RefObject<Integer> pls = new RefObject<Integer>(0); //*< payload start adres
        int calsum; //*< calculated checksum

        if (fpl == null) {
            return (nc);
        }
        RefObject<Integer> i = new RefObject<Integer>(0);
        sync = TMS_GET_INT(msg, i, 2);
        type = tms_get_type(msg, n);
        size = TMS_MSG_SIZE(msg, n, pls);
        calsum = tms_cal_chksum(msg, n);
        fpl = fpl.format("# %s sync 0x%04X type 0x%02X size 0x%02X checksum 0x%04X\n", comment, sync, type, size, calsum);
        fpl = fpl.format("#%3s %4s %2s %2s %2s\n", "nr", "ba", "wa", "d1", "d0");
        i.argValue = 0;
        while (i.argValue < n) {
            fpl = fpl.format(" %3d %04X %02X %02X %02X %1c %1c\n", TMS_WRITE_LOG_MSG_nr, (i.argValue & 0xFFFF),
                    ((i.argValue - pls.argValue) / 2) & 0xFF, msg[i.argValue + 1], msg[i.argValue], ((msg[i.argValue + 1] >= 0x20
                    && msg[i.argValue + 1] <= 0x7F) ? msg[i.argValue + 1] : '.'), ((msg[i.argValue] >= 0x20 && msg[i.argValue] <= 0x7F) ? msg[i.argValue] : '.'));
            i.argValue += 2;
        }
        /* increment message counter */
        TMS_WRITE_LOG_MSG_nr++;
        return (nc);
    }

    public String replace(String str, int index, char replace) {
        if (str == null) {
            return str;
        } else if (index < 0 || index >= str.length()) {
            return str;
        }
        char[] chars = str.toCharArray();
        chars[index] = replace;
        return String.valueOf(chars);
    }

    /**
     * Read TMS log number 'en' into buffer 'msg' of maximum 'n' bytes from log
     * file.
     *
     * @return return length of message.
     */
    public int tms_read_log_msg(int en, byte[] msg, int n) {

        int br = 0; //*< number of bytes read
        String line = new String(new char[0x100]); //*< temp line buffer
        Integer nr = 0; //*< log event number
        Integer ba = 0; //*< byte address
        Integer wa = 0; //*< word address
        Byte d0 = 0; //*< byte data value
        Byte d1 = 0;
        int sec = 0; //*< sequence error counter
        int lc = 0; //*< line counter
        int ni = 0; //*< number of input arguments
        byte[] bytes = new byte[0x100];
        byte[] new_bytes = new byte[0x100];

        if (fpl == null) {
            return (br);
        }
        /* seek to begin of file */
        //fseek(fpl, 0, 0);
        fpl.flush();

        try {
            FileInputStream in = new FileInputStream(filename);
            /* read whole ASCII EEG sample file */
            while (in.available() > 0) {
                /* clear line */
                line = replace(line, 0, '\0');
                /* read one line with hist data */
//            fgets(line, Byte.SIZE - 1, fpl);
                int b = in.read(bytes, 0, 0x100 - 1);
                System.arraycopy(bytes, 0, new_bytes, 0, b);
                line = new String(new_bytes);

                lc++;
                /* skip comment lines or too small lines */
                if ((line.charAt(0) == '#') || (line.length() < 2)) {
                    continue;
                }
                Object[] obj = {nr, ba, wa, d1, d0};
                ni = Sscanf.scan2(line, "%d %X %X %X %X", obj);
                if (ni != 5) {
                    if (sec == 0) {
                        System.err.format("# Error: tms_read_log_msg : wrong argument count %d on line %d. Skip it\n", ni, lc);
                    }
                    sec++;
                    continue;
                }
                if (ba >= n) {
                    System.err.format("# Error: tms_read_log_msg : size array 'msg' %d too small %d\n", n, nr);
                } else {
                    if (en == nr) {
                        msg[ba + 1] = (byte) d1;
                        msg[ba] = (byte) d0;
                        br += 2;
                    }
                }
            }
        } catch (Exception ex) {
            System.err.println("Error on opening file.");
            return 0;
        }

        return (br);
    }

    /**
     * ******************************************************************
     */
    /* Functions for reading the data from the SD flash cards            */
    /**
     * ******************************************************************
     */
    /**
     * Get 16 bytes TMS date for 'msg' starting at position 'i'.
     *
     * @note position after parsing in returned in 'i'.
     * @return 0 on success, -1 on failure.
     */
//C++ TO JAVA CONVERTER TODO TASK: Pointer arithmetic is detected on the parameter 't', so pointers on this parameter are left unchanged:
    public int tms_get_date(byte[] msg, RefObject<Integer> i, java.util.Date t) {

        int j; //*< general index
        int[] wrd = new int[8]; //*< TMS date format
        Calendar cal = Calendar.getInstance(); //broken calendar

        int zeros = 0; //*< zero counter
        int ffcnt = 0; //*< no value counter

        for (j = 0; j < 8; j++) {
            wrd[j] = TMS_GET_INT(msg, i, 2);
            if (wrd[j] == 0) {
                zeros++;
            }
            if ((wrd[j] & 0xFF) == 0xFF) {
                ffcnt++;
            }
        }
        if ((vb & 0x01) != 0) {
            System.err.format(" %02d%02d-%02d-%02d %02d:%02d:%02d\n", wrd[0], wrd[1], wrd[2], wrd[3], wrd[5], wrd[6], wrd[7]);
        }
        if ((zeros == 8) || (ffcnt > 0)) {
            /* by definition 1970-01-01 00:00:00 GMT */
            t = new java.util.Date(0); 
            return (-1);
        } else {
            /* year since 1900 */
            cal.set(Calendar.YEAR, (wrd[0] * 100 + wrd[1]) - 1900);
//            cal.tm_year = (wrd[0] * 100 + wrd[1]) - 1900;
            /* months since January [0,11] */
            cal.set(Calendar.MONTH, (wrd[2] - 1));
//            cal.tm_mon = wrd[2] - 1;
            /* day of the month [1,31] */
            cal.set(Calendar.DATE, wrd[3]);
//            cal.tm_mday = wrd[3];
            /* hours since midnight [0,23] */
            cal.set(Calendar.HOUR_OF_DAY, wrd[5]);
//            cal.tm_hour = wrd[5];
            /* minutes since the hour [0,59] */
            cal.set(Calendar.MINUTE, wrd[6]);
//            cal.tm_min = wrd[6];
            /* seconds since the minute [0,59] */
            cal.set(Calendar.SECOND, wrd[7]);
//            cal.tm_sec = wrd[7];
            /* convert to broken calendar to calendar */
            Date ts = cal.getTime();
            //Instant instant = Instant.ofEpochMilli(ts.getTime());
            t = ts;//LocalDateTime.ofInstant(instant, ZoneId.systemDefault());
//            t = mktime(cal);
            return (0);
        }
    }

    /**
     * Put time_t 't' as 16 bytes TMS date into 'msg' starting at position 'i'.
     *
     * @note position after parsing in returned in 'i'.
     * @return 0 always.
     */
    public int tms_put_date(Date t, byte[] msg, RefObject<Integer> i) {

        int j; //*< general index
        int[] wrd = new int[8]; //*< TMS date format
        Calendar cal = Calendar.getInstance(); //*< broken calendar time

        if (t.getTime() == 0 ) {
            /* all zero for t-zero */
            for (j = 0; j < 8; j++) {
                wrd[j] = 0;
            }
        } else {
//            cal = localtime(t);
            /* year since 1900 */
            wrd[0] = (cal.get(Calendar.YEAR) + 1900) / 100;
            wrd[1] = (cal.get(Calendar.YEAR) + 1900) % 100;
            /* months since January [0,11] */
            wrd[2] = cal.get(Calendar.MONTH) + 1;
            /* day of the month [1,31] */
            wrd[3] = cal.get(Calendar.DATE);
            /* day of the week [0,6] ?? sunday = ? */
            wrd[4] = cal.get(Calendar.DAY_OF_WEEK); //* !!! checken
	 /* hours since midnight [0,23] */
            wrd[5] = cal.get(Calendar.HOUR);
            /* minutes since the hour [0,59] */
            wrd[6] = cal.get(Calendar.MINUTE);
            /* seconds since the minute [0,59] */
            wrd[7] = cal.get(Calendar.SECOND);
        }
        /* put 16 bytes */
        for (j = 0; j < 8; j++) {
            TMS_PUT_INT(wrd[j], msg, i, 2);
        }
        if ((vb & 0x01) != 0) {
            System.err.format(" %02d%02d-%02d-%02d %02d:%02d:%02d\n", wrd[0], wrd[1], wrd[2], wrd[3], wrd[5], wrd[6], wrd[7]);
        }
        return (0);
    }

    /**
     * Convert buffer 'msg' starting at position 'i' into tms_config_t 'cfg'
     *
     * @note new position byte will be return in 'i'
     * @return number of bytes parsed
     */
    public int tms_get_cfg(byte[] msg, RefObject<Integer> i, TMS_CONFIG_T cfg) {

        int i0 = i.argValue; //*< start index
        int j; //*< general index

        cfg.version = (short) TMS_GET_INT(msg, i, 2); //*< PC Card protocol version number 0x0314
        cfg.hdrSize = (short) TMS_GET_INT(msg, i, 2); //*< size of measurement header 0x0200
        cfg.fileType = (short) TMS_GET_INT(msg, i, 2); //*< Stream Type (0: .ini 1: .smp 2:evt)
        i.argValue += 2; //*< skip 2 reserved bytes
        cfg.cfgSize = TMS_GET_INT(msg, i, 4); //*< size of config.ini  0x400
        i.argValue += 4; //*< skip 4 reserved bytes
        cfg.sampleRate = (short) TMS_GET_INT(msg, i, 2); //*< sample frequency [Hz]
        cfg.nrOfChannels = (short) TMS_GET_INT(msg, i, 2); //*< number of channels
        cfg.startCtl = (short) TMS_GET_INT(msg, i, 4); //*< start control
        cfg.endCtl = TMS_GET_INT(msg, i, 4); //*< end control
        cfg.cardStatus = (short) TMS_GET_INT(msg, i, 2); //*< card status
        cfg.initId = TMS_GET_INT(msg, i, 4); //*< Initialisation Identifier
        cfg.sampleRateDiv = (short) TMS_GET_INT(msg, i, 2); //*< Sample Rate Divider
        i.argValue += 2; //*< skip 2 reserved bytes
        for (j = 0; j < 64; j++) {
            cfg.storageType[j].shift = (byte) TMS_GET_INT(msg, i, 1); //*< shift
            cfg.storageType[j].delta = (byte) TMS_GET_INT(msg, i, 1); //*< delta
            cfg.storageType[j].deci = (byte) TMS_GET_INT(msg, i, 1); //*< decimation
            cfg.storageType[j].ref = (byte) TMS_GET_INT(msg, i, 1); //*< ref
            cfg.storageType[j].period = 0; //*< sample period
            cfg.storageType[j].overflow = (0xFFFFFF80) << (8 * (cfg.storageType[j].delta - 1)); //*< overflow
        }
        for (j = 0; j < 12; j++) {
            cfg.fileName[j] = (byte) TMS_GET_INT(msg, i, 1); //*< Measurement file name
        }
        /**
         * < alarm time
         */
        tms_get_date(msg, i, cfg.alarmTime);
        i.argValue += 2; //*< skip 2 or 4 reserved bytes !!! check it
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
        for (j = 0; j < cfg.info.length; j++) {
            cfg.info[j] = (byte) TMS_GET_INT(msg, i, 1);
        }

        /* find minimum decimation */
        cfg.mindecimation = 255;
        for (j = 0; j < cfg.nrOfChannels; j++) {
            if ((cfg.storageType[j].delta > 0) && (cfg.storageType[j].deci < cfg.mindecimation)) {
                cfg.mindecimation = cfg.storageType[j].deci;
            }
        }
        /* calculate channel period */
        for (j = 0; j < cfg.nrOfChannels; j++) {
            if (cfg.storageType[j].delta > 0) {
                cfg.storageType[j].period = (cfg.storageType[j].deci + 1) / (1 << cfg.mindecimation);
            }
        }

        return (i.argValue - i0);
    }

    /**
     * Put tms_config_t 'cfg' into buffer 'msg' starting at position 'i'
     *
     * @note new position byte will be return in 'i'
     * @return number of bytes put
     */
    public int tms_put_cfg(byte[] msg, RefObject<Integer> i, TMS_CONFIG_T cfg) {

        int i0 = i.argValue; //*< start index
        int j; //*< general index

        TMS_PUT_INT(cfg.version, msg, i, 2); //*< PC Card protocol version number 0x0314
        TMS_PUT_INT(cfg.hdrSize, msg, i, 2); //*< size of measurement header 0x0200
        TMS_PUT_INT(cfg.fileType, msg, i, 2); //*< Stream Type (0: .ini 1: .smp 2:evt)
        TMS_PUT_INT(0xFFFF, msg, i, 2); //*< 2 reserved bytes
        TMS_PUT_INT(cfg.cfgSize, msg, i, 4); //*< size of config.ini  0x400
        TMS_PUT_INT(0xFFFFFFFF, msg, i, 4); //*< 4 reserved bytes
        TMS_PUT_INT(cfg.sampleRate, msg, i, 2); //*< sample frequency [Hz]
        TMS_PUT_INT(cfg.nrOfChannels, msg, i, 2); //*< number of channels
        TMS_PUT_INT(cfg.startCtl, msg, i, 4); //*< start control
        TMS_PUT_INT(cfg.endCtl, msg, i, 4); //*< end control
        TMS_PUT_INT(cfg.cardStatus, msg, i, 2); //*< card status
        TMS_PUT_INT(cfg.initId, msg, i, 4); //*< Initialisation Identifier
        TMS_PUT_INT(cfg.sampleRateDiv, msg, i, 2); //*< Sample Rate Divider
        TMS_PUT_INT(0x0000, msg, i, 2); //*< 2 reserved bytes
        for (j = 0; j < 64; j++) {
            TMS_PUT_INT(cfg.storageType[j].shift, msg, i, 1); //*< shift
            TMS_PUT_INT(cfg.storageType[j].delta, msg, i, 1); //*< delta
            TMS_PUT_INT(cfg.storageType[j].deci, msg, i, 1); //*< decimation
            TMS_PUT_INT(cfg.storageType[j].ref, msg, i, 1); //*< ref
        }
        for (j = 0; j < 12; j++) {
            TMS_PUT_INT(cfg.fileName[j], msg, i, 1); //*< Measurement file name
        }
        tms_put_date(cfg.alarmTime, msg, i); //*< alarm time
        TMS_PUT_INT(0xFFFFFFFF, msg, i, 2); //*< 2 or 4 reserved bytes. check it!!!
  /* put info part */
        j = 0;
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
        while ((j < cfg.info.length) && (i.argValue < TMSCFGSIZE)) {
            TMS_PUT_INT(cfg.info[j], msg, i, 1);
            j++;
        }
        //System.out.println(stderr,"tms_put_cfg: i %d j %d\n",*i,j);
        return (i.argValue - i0);
    }

    /**
     * Print tms_config_t 'cfg' to file 'fp'
     *
     * @param prt_info !=0 -> print measurement/patient info
     * @return number of characters printed.
     */
    public int tms_prt_cfg(PrintStream fp, TMS_CONFIG_T cfg, int prt_info) {

        int nc = 0; //*< printed characters
        int i; //*< index
        String atime = new String(new char[MNCN]); //*< alarm time

        fp = fp.format("v 0x%04X ; Version\n", cfg.version);
        fp = fp.format("h 0x%04X ; hdrSize \n", cfg.hdrSize);
        fp = fp.format("c 0x%04X ; cardStatus\n", cfg.cardStatus);
        fp = fp.format("t 0x%04x ; ", cfg.fileType);
        switch (cfg.fileType) {
            case 0:
                fp = fp.format("ini");
                break;
            case 1:
                fp = fp.format("smp");
                break;
            case 2:
                fp = fp.format("evt");
                break;
            default:
                fp = fp.format("unknown?");
                break;
        }
        fp = fp.format(" fileType\n");
        fp = fp.format("g 0x%08X ; cfgSize\n", cfg.cfgSize);
        fp = fp.format("r   %8d ; sample Rate [Hz]\n", cfg.sampleRate);
        fp = fp.format("n   %8d ; nr of Channels\n", cfg.nrOfChannels);

        fp = fp.format("b 0x%08X ; startCtl:", cfg.startCtl);
        if ((cfg.startCtl & 0x01) != 0) {
            fp = fp.format(" RTC_SET");
        }
        if ((cfg.startCtl & 0x02) != 0) {
            fp = fp.format(" RECORD_AUTO_START");
        }
        if ((cfg.startCtl & 0x04) != 0) {
            fp = fp.format(" BUTTON_ENABLE");
        }
        fp = fp.format("\n");

        fp = fp.format("e 0x%08X ; endCtl\n", cfg.endCtl);
        fp = fp.format("i 0x%08X ; initId\n", cfg.initId);
        fp = fp.format("d   %8d ; sample Rate Divider\n", cfg.sampleRateDiv);

        //atime = cfg.alarmTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
//        atime = cfg.alarmTime.ofPattern("yyyy-MM-dd HH:mm:ss").format(LocalDateTime.now());
        fp = fp.format("a   %8d ; alarm time %s\n", cfg.alarmTime.toString());
        fp = fp.format("f %12s ; file name\n", cfg.fileName);
        fp = fp.format("# nr refer decim delta shift ; ch period\n");
        for (i = 0; i < 64; i++) {
            if (cfg.storageType[i].delta != 0) {
                fp.format("s %2d %5d %5d %5d %5d ;  %1c %6d\n", i, cfg.storageType[i].ref, cfg.storageType[i].deci, cfg.storageType[i].delta, cfg.storageType[i].shift, 'A' + i, cfg.storageType[i].period);
            }
        }
        if (prt_info != 0) {
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
            for (i = 0; i < cfg.info.length; i++) {
                if (i % 16 == 0) {
                    if (i > 0) {
                        fp = fp.format("\n");
                    }
                    fp = fp.format("o 0x%04X", i);
                }
                fp = fp.format(" 0x%02X", cfg.info[i]);
            }
            fp = fp.format("\n");
        }
        fp = fp.format("q  ; end of configuration\n");
        return (nc);
    }

    public static long strtol(String input, RefObject<Integer> endptr, int base, int start) {
        input = input.toLowerCase().trim();
        long result = 0L;
        for (endptr.argValue = start + 1; endptr.argValue <= input.length(); endptr.argValue++) {
            try {
                result = Long.parseLong(input.substring(start, endptr.argValue), base);
            } catch (NumberFormatException e) {
                break;
            }
        }
        return result;
    }

    /**
     * Read tms_config_t 'cfg' from file 'fp'
     *
     * @return number of characters printed.
     */
    public int tms_rd_cfg(InputStream fp, TMS_CONFIG_T cfg) throws IOException {

        int lc = 0; //*< line counter
        String line = new String(new char[2 * MNCN]); //*< temp line buffer
        int max_s = 2 * MNCN;
        byte[] bytes = new byte[max_s];
        byte[] new_bytes = new byte[max_s];
        RefObject<Integer> endptr = new RefObject<Integer>(0); //*< end pointer of integer parsing
        String token; //*< token on the input line
        Byte nr = 0;
        Byte ref = 0; //*< nr, ref, decim and delta storage
        Byte decim = 0;
        Byte delta = 0;
        Byte shift = 0;
        int go_on = 1;

        /* all zero as default */
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'memset' has no equivalent in Java:
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
//        memset(cfg, 0, sizeof(cfg));
        /* default no channel reference */
        for (nr = 0; nr < 64; nr++) {
            cfg.storageType[nr].ref = -1;
        }

        while (fp.available() > 0 && (go_on == 1)) {
            /* clear line */
            replace(line, 0, '\0');
            /* read one line with hist data */
//            fgets(line, Byte.SIZE - 1, fp);
            int b = fp.read(bytes, 0, max_s - 1);

            System.arraycopy(bytes, 0, new_bytes, 0, b);
            line = new String(new_bytes);

            lc++;
            /* skip comment and data lines */
            if ((line.charAt(0) == '#') || (line.charAt(0) == ' ')) {
                continue;
            }

            switch (line.charAt(0)) {
                case 'v':
                    cfg.version = (short) strtol(line, endptr, 0, 2);
                    break;
                case 'h':
                    cfg.hdrSize = (short) strtol(line, endptr, 0, 2);
                    break;
                case 't':
                    cfg.fileType = (short) strtol(line, endptr, 0, 2);
                    break;
                case 'g':
                    cfg.cfgSize = (short) strtol(line, endptr, 0, 2);
                    break;
                case 'r':
                    cfg.sampleRate = (short) strtol(line, endptr, 0, 2);
                    break;
                case 'n':
                    cfg.nrOfChannels = (short) strtol(line, endptr, 0, 2);
                    break;
                case 'b':
                    cfg.startCtl = (short) strtol(line, endptr, 0, 2);
                    break;
                case 'e':
                    cfg.endCtl = (short) strtol(line, endptr, 0, 2);
                    break;
                case 'i':
                    cfg.initId = (short) strtol(line, endptr, 0, 2);
                    break;
                case 'c':
                    cfg.cardStatus = (short) strtol(line, endptr, 0, 2);
                    break;
                case 'd':
                    cfg.sampleRateDiv = (short) strtol(line, endptr, 0, 2);
                    break;
                case 'a':
                    cfg.alarmTime = new java.util.Date(strtol(line, endptr, 0, 2));
                    break;
                case 'f':
//                    sscanf(line, "f %s ;", cfg.fileName);
                    Sscanf.scan2(line, "f %s ;", cfg.fileName);
                    endptr = null;
                    break;
                case 's':
                    Byte[] obj = {nr, ref, decim, delta, shift};
                    Sscanf.scan2(line, "s %d %d %d %d %d ;", obj);
                    endptr = null;
                    if ((nr >= 0) && (nr < 64)) {
                        cfg.storageType[nr].ref = ref;
                        cfg.storageType[nr].deci = decim;
                        cfg.storageType[nr].delta = delta;
                        cfg.storageType[nr].shift = shift;
                    }
                    break;
                case 'o':
                    /* start parsing direct after character 'o' */
                    token = StringFunctions.strTok(line.charAt(1) + "", " \n");
                    if (token != null) {
                        /* get start address */
                        nr = (byte) strtol(token, endptr, 0, 0);
                        /* parse data bytes */
                        while ((token = StringFunctions.strTok(null, " \n")) != null) {
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
                            if ((nr >= 0) && (nr < cfg.info.length)) {
                                cfg.info[nr] = (byte) strtol(token, endptr, 0, 0);
                            }
                            nr++;
                        }
                    }
                    break;
                case 'q':
                    go_on = 0;
                    break;
                default:
                    break;
            }
            if (endptr != null) {
                System.err.format("# Warning: line %d has an configuration error!!!\n", lc);
            }
        }
        return (lc);
    }
//----------------------------------------------------------------------------------------
//	Copyright © 2006 - 2015 Tangible Software Solutions Inc.
//	This class can be used by anyone provided that the copyright notice remains intact.
//
//	This class provides the ability to simulate various classic C string functions
//	which don't have exact equivalents in the Java framework.
//----------------------------------------------------------------------------------------

    public final static class StringFunctions {
        //------------------------------------------------------------------------------------
        //	This method allows replacing a single character in a string, to help convert
        //	C++ code where a single character in a character array is replaced.
        //------------------------------------------------------------------------------------

        public static String changeCharacter(String sourceString, int charIndex, char changeChar) {
            return (charIndex > 0 ? sourceString.substring(0, charIndex) : "")
                    + Character.toString(changeChar) + (charIndex < sourceString.length() - 1 ? sourceString.substring(charIndex + 1) : "");
        }

        //------------------------------------------------------------------------------------
        //	This method simulates the classic C string function 'isxdigit' (and 'iswxdigit').
        //------------------------------------------------------------------------------------
        public static boolean isXDigit(char character) {
            if (Character.isDigit(character)) {
                return true;
            } else if ("ABCDEFabcdef".indexOf(character) > -1) {
                return true;
            } else {
                return false;
            }
        }

        //------------------------------------------------------------------------------------
        //	This method simulates the classic C string function 'strchr' (and 'wcschr').
        //------------------------------------------------------------------------------------
        public static String strChr(String stringToSearch, char charToFind) {
            int index = stringToSearch.indexOf(charToFind);
            if (index > -1) {
                return stringToSearch.substring(index);
            } else {
                return null;
            }
        }

        //------------------------------------------------------------------------------------
        //	This method simulates the classic C string function 'strrchr' (and 'wcsrchr').
        //------------------------------------------------------------------------------------
        public static String strRChr(String stringToSearch, char charToFind) {
            int index = stringToSearch.lastIndexOf(charToFind);
            if (index > -1) {
                return stringToSearch.substring(index);
            } else {
                return null;
            }
        }

        //------------------------------------------------------------------------------------
        //	This method simulates the classic C string function 'strstr' (and 'wcsstr').
        //------------------------------------------------------------------------------------
        public static String strStr(String stringToSearch, String stringToFind) {
            int index = stringToSearch.indexOf(stringToFind);
            if (index > -1) {
                return stringToSearch.substring(index);
            } else {
                return null;
            }
        }

        //------------------------------------------------------------------------------------
        //	This method simulates the classic C string function 'strtok' (and 'wcstok').
        //------------------------------------------------------------------------------------
        public static String activeString;
        public static int activePosition;

        public static String strTok(String stringToTokenize, String delimiters) {
            if (stringToTokenize != null) {
                activeString = stringToTokenize;
                activePosition = -1;
            }

            //the stringToTokenize was never set:
            if (activeString == null) {
                return null;
            }

            //all tokens have already been extracted:
            if (activePosition == activeString.length()) {
                return null;
            }

            //bypass delimiters:
            activePosition++;
            while (activePosition < activeString.length() && delimiters.indexOf(activeString.charAt(activePosition)) > -1) {
                activePosition++;
            }

            //only delimiters were left, so return null:
            if (activePosition == activeString.length()) {
                return null;
            }

            //get starting position of string to return:
            int startingPosition = activePosition;

            //read until next delimiter:
            do {
                activePosition++;
            } while (activePosition < activeString.length() && delimiters.indexOf(activeString.charAt(activePosition)) == -1);

            return activeString.substring(startingPosition, activePosition);
        }
    }

    /**
     * Convert buffer 'msg' starting at position 'i' into tms_measurement_hdr_t
     * 'hdr'
     *
     * @note new position byte will be return in 'i'
     * @return number of bytes parsed
     */
    public int tms_get_measurement_hdr(byte[] msg, RefObject<Integer> i, TMS_MEASUREMENT_HDR_T hdr) {

        int i0 = i.argValue; //*< start byte index
        int err = 0; //*< error status of tms_get_date

        i.argValue += 4; //*< skip 4 reserved bytes
        hdr.nsamples = TMS_GET_INT(msg, i, 4); //*< number of samples in this recording
        err = tms_get_date(msg, i, hdr.startTime);
        if (err != 0) {
            System.err.println("# Warning: start time incorrect!!!\n");
        }
        err = tms_get_date(msg, i, hdr.endTime);
        if (err != 0) {
            System.err.println("# Warning: end time incorrect, unexpected end of recording!!!\n");
        }
        hdr.frontendSerialNr = TMS_GET_INT(msg, i, 4); //*< frontendSerial Number
        hdr.frontendHWNr = (short) TMS_GET_INT(msg, i, 2); //*< frontend Hardware version Number
        hdr.frontendSWNr = (short) TMS_GET_INT(msg, i, 2); //*< frontend Software version Number
        return (i.argValue - i0);
    }

    /**
     * Print tms_config_t 'cfg' to file 'fp'
     *
     * @param prt_info 0x01 print measurement/patient info
     * @return number of characters printed.
     */
    public int tms_prt_measurement_hdr(PrintStream fp, TMS_MEASUREMENT_HDR_T hdr) {

        int nc = 0; //*< printed characters
        String stime = new String(new char[MNCN]); //*< start time
        String etime = new String(new char[MNCN]); //*< end time

        stime = hdr.startTime.toString();//format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        etime = hdr.endTime.toString();//format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        fp = fp.format("# time start %s end %s\n", stime, etime);
        fp = fp.format("# Frontend SerialNr 0x%08X HWNr 0x%04X SWNr 0x%04X\n", hdr.frontendSerialNr, hdr.frontendHWNr, hdr.frontendSWNr);
        fp = fp.format("# nsamples %9d\n", hdr.nsamples);

        return (1);
    }

    /**
     * ******************************************************************
     */
    /* Functions for reading and setting up the bluetooth connection     */
    /**
     * ******************************************************************
     */
    /**
     * General check of TMS message 'msg' of 'n' bytes.
     *
     * @return 0 on correct checksum, 1 on failure.
     */
    public int tms_chk_msg(byte[] msg, int n) {

        int sync; //*< TMS block sync
        int size; //*< TMS block size
        short calsum; //*< calculate checksum of TMS block

        /* check sync */
        RefObject<Integer> i = new RefObject<Integer>(0);
        sync = TMS_GET_INT(msg, i, 2);
        if (sync != TMSBLOCKSYNC) {
            System.err.format("# Warning: found sync %04X != %04X\n", sync, TMSBLOCKSYNC);
            return (-1);
        }
        /* size check */
        size = TMS_MSG_SIZE(msg, n, i);
        if (n != (2 * size + i.argValue + 2)) {
            System.err.format("# Warning: found size %d != expected size %d\n", size, (n - i.argValue - 2) / 2);
        }
        /* check checksum and get type */
        calsum = tms_cal_chksum(msg, n);
        if (calsum != 0x0000) {
            System.err.format("# Warning: checksum 0x%04X != 0x0000\n", calsum);
            return (1);
        } else {
            return (0);
        }
    }

    /**
     * Put checksum at end of buffer 'msg' of 'n' bytes.
     *
     * @return total size of 'msg' including checksum.
     */
    public short TMS_PUT_CHKSUM(byte[] msg, int n) {

        int sum = 0; //*< checksum
        if (n % 2 == 1) {
            System.err.format("Warning: TMS_PUT_CHKSUM: odd packet length %d\n", n);
        }
		  // TODO: call cal_sum
        /* calculate checksum */
		  //System.out.format("put_chksum 0 = %08x\n",sum);
		  // Argh! all primitive types in java are signed!!! including byte... thus byte>a0 -> neg number
		  int tmp=0;
        for (int i = 0; i < n; i+=2) {
				tmp= ((int)msg[i]) & 0x00ff;                         //LSByte
            sum += tmp;
				//System.out.format("put_chksum %d.l : + %02x(%04x) = %08x\n",i,msg[i],tmp,sum);
				tmp= ( ((int)msg[i + 1]) & 0x00ff) << 8;             //MSByte
				sum += tmp;   //MSByte
				//System.out.format("put_chksum %d.m : + %02x(%04x) = %08x\n",i,msg[i + 1],tmp,sum);
        }
        /* checksum should add up to 0x0000 */
        sum = -sum;
		  //System.out.format("put_chksum sum : %08x\n",sum);
        /* put it */
        TMS_PUT_INT(sum, msg, new RefObject<Integer>(n), 2);
        /* return total size of 'msg' including checksum */
        return (short) (n+2);
    }


	 void dumpMsg(byte[] msg, int n, int start){
		  for ( int iii=start; iii<n; iii++)
				System.err.format("%02x ",msg[iii]);
		  System.err.println();
	 }
	 
    /**
     * Read at max 'n' bytes of TMS message 'msg' for socket device descriptor
     * 'fd'.
     *
     * @return number of bytes read.
     */
    public int tms_rcv_msg(Socket fd, byte[] msg, int n) {

        RefObject<Integer> i = new RefObject<Integer>(0); //*< byte index
        RefObject<Integer> ii = new RefObject<Integer>(0); //*< tempory byte index
        int br = 0; //*< bytes read
        int tbr = 0; //*< total bytes read
        int sync = 0x0000; //*< sync block
        int rtc = 0; //*< retry counter
        int size = 0; //*< payload size [uint16_t]
        int size8 = 0; //*< payload size in [uint8_t]

        /* clear recieve buffer */
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'memset' has no equivalent in Java:
        for (int in = 0; in < n; in++) {
            msg[in] = 0x00;
        }
        byte[] bytes = new byte[n];
        /* wait (not too long) for 2-byte sync block, 
         and discard any data which isn't sync information. */
        br = 0;
		  //System.err.println("Wait for sync");
        while ((rtc < 1000) && (sync != TMSBLOCKSYNC)) {
            if (br > 0) { // discard non-sync data
                msg[0] = msg[1]; // shift bit back
                if (tbr > 1) {
                    System.err.println("discarded non-sync data\n");
                }
            }

				//            br = recv(fd, msg[1], 1, 0);
            try {
                br = fd.getInputStream().read(bytes, 0, 1);
            } catch (IOException ex) {
					 System.err.println(ex);
            }
            msg[1] = bytes[0];
            tbr += br; // Blocking call, may wait forever!
            if ((br > 0) && (tbr > 1)) {
                i.argValue = 0;
                sync = TMS_GET_INT(msg, i, 2);
            }
            rtc++;
				//System.err.print('.');
        }
        if (rtc >= 1000) {
            System.err.println("# Error: timeout on waiting for block sync\n");
            return (-1);
        }
		  //System.err.println("Waiting for message description");
        try {
            /* read 2 byte description */
//        br = recv(fd, msg[i.argValue], 2, 0);
            br = fd.getInputStream().read(msg,i.argValue,2);
				i.argValue += br;
        } catch (IOException ex) {
            Logger.getLogger(tmsi.class.getName()).log(Level.SEVERE, null, ex);
        }

        tbr += br;
        try {
            /* read 2 byte size */
        /* while ((rtc<1000) && (i<4)) { */
        /* br=recv(fd,&msg[i],1,0); i+=br; tbr+=br; */
        /*   rtc++; */
        /* } */
				while ( i.argValue < 4 ) {
					 br = fd.getInputStream().read(msg, i.argValue, 1);
					 i.argValue += br;
				}
        } catch (IOException ex) {
            Logger.getLogger(tmsi.class.getName()).log(Level.SEVERE, null, ex);
        }
        if (rtc >= 1000) {
            System.err.println("# Error: timeout on waiting description\n");
            return (-2);
        }
		  // System.err.println("message so far:\n");
		  // for ( int iii=0; iii<i.argValue; iii++)
		  // 		System.err.format("%02x ",msg[iii]);
		  // System.err.println();
				
        ii.argValue = 2;
        size = TMS_GET_INT(msg, ii, 1);
		  //System.err.format("Message size : %d\n",size);
        //size=msg[2]; /* size is 1 byte = measured in 16-bit words! so max message size is 256*2? */
        if (size == 0xFF) {
            System.err.println("multibyte msg size\n");
        }

        /* read rest of message */
        size8 = 2 * size + 6; // message size including a final checksum of 6 bytes?
        if (size8 > n) {
            System.err.format("# Warning: message buffer size %d too small %d. Extra discarded !\n", n, size8);
        }
		  //System.err.println("Waiting for message payload");
        while (rtc < 1000 && i.argValue < size8) {
            if (size8 < n) {
//                br = recv(fd, msg[i], size8 - i, 0); // read the whole message in 1 call
                try {
                    br = fd.getInputStream().read(msg, i.argValue, size8 - i.argValue);
                } catch (IOException ex) {
                    System.err.println("Error on first if-statement");
						  System.err.println(ex);
                }
            } else if (i.argValue < n) { // read until the buffer is full
//                br = recv(fd, msg[i.argValue], 1, 0);
                //br=recv(fd,&msg[i],n-i,0); 
                try {
                    br = fd.getInputStream().read(msg, i.argValue, n-i.argValue);
                } catch (IOException ex) {
                    System.err.println("Error on first if-statement");
						  System.err.println(ex);
                }
            } else { // read and discard rest of message
//                br = recv(fd, msg[n], 1, 0);
                try {
                    br = fd.getInputStream().read(msg, i.argValue, 1);
                } catch (IOException ex) {
                    System.err.println("Error on first if-statement");
						  System.err.println(ex);
                }
            }
            i.argValue += br;
            tbr += br;
            rtc++;
        }
        if (rtc >= 1000) {
            System.err.println("# Error: timeout on rest of message\n");
            return (-3);
        }
        if ((vb & 0x01) != 0) {
            /* log response */
            TMS_WRITE_LOG_MSG(msg, tbr, "received message");
        }

		  //System.err.println("Final recieved message:\n");dumpMsg(msg,0,i.argValue);

        return (tbr);
    }

    /**
     * Convert buffer 'msg' of 'n' bytes into TMS_ACKNOWLEDGE_T 'ack'.
     *
     * @return >0 on failure and 0 on success
     */
    public int tms_get_ack(byte[] msg, int n, TMS_ACKNOWLEDGE_T ack) {

        RefObject<Integer> i = new RefObject<Integer>(0); //*< general index
        int type; //*< message type
        int size; //*< payload size

        /* get message type */
        type = tms_get_type(msg, n);
        if (type != TMSACKNOWLEDGE) {
            System.err.format("# Warning: type %02X != %02X\n", type, TMSFRONTENDINFO);
            return (-1);
        }
        /* get payload size and payload pointer 'i' */
        size = TMS_MSG_SIZE(msg, n, i);
        ack.descriptor = (short) TMS_GET_INT(msg, i, 2);
        ack.errorcode = (short) TMS_GET_INT(msg, i, 2);
        /* number of found Frontend system info structs */
        return (ack.errorcode);
    }

    /**
     * Print TMS_ACKNOWLEDGE_T 'ack' to file 'fp'.
     *
     * @return number of printed characters.
     */
    public int tms_prt_ack(PrintStream fp, TMS_ACKNOWLEDGE_T ack) {

        int nc = 0;

        if (fp == null) {
            return (nc);
        }
        fp = fp.format("# Ack: desc %04X err %04X", ack.descriptor, ack.errorcode);
        switch (ack.errorcode) {
            case 0x01:
                fp = fp.format(" unknown or not implemented blocktype");
                break;
            case 0x02:
                fp = fp.format(" CRC error in received block");
                break;
            case 0x03:
                fp = fp.format(" error in command data (can't do that)");
                break;
            case 0x04:
                fp = fp.format(" wrong blocksize (too large)");
                break;
            // 0x0010 - 0xFFFF are reserved for user errors
            case 0x11:
                fp = fp.format(" No external power supplied");
                break;
            case 0x12:
                fp = fp.format(" Not possible because the Front is recording");
                break;
            case 0x13:
                fp = fp.format(" Storage medium is busy");
                break;
            case 0x14:
                fp = fp.format(" Flash memory not present");
                break;
            case 0x15:
                fp = fp.format(" nr of words to read from flash memory out of range");
                break;
            case 0x16:
                fp = fp.format(" flash memory is write protected");
                break;
            case 0x17:
                fp = fp.format(" incorrect value for initial inflation pressure");
                break;
            case 0x18:
                fp = fp.format(" wrong size or values in BP cycle list");
                break;
            case 0x19:
                fp = fp.format(" sample frequency divider out of range (<0, >max)");
                break;
            case 0x1A:
                fp = fp.format(" wrong nr of user channels (<=0, >maxUSRchan)");
                break;
            case 0x1B:
                fp = fp.format(" adress flash memory out of range");
                break;
            case 0x1C:
                fp = fp.format(" Erasing not possible because battery low");
                break;
            default:
                // 0x00 - no error, positive acknowledge
                break;
        }
        fp = fp.format("\n");
        return (1);
    }

    /**
     * Send frontend Info request to 'fd'.
     *
     * @return bytes send.
     */
    public int tms_snd_FrontendInfoReq(Socket fd) {
        byte[] msg = new byte[6]; //*< message buffer
        int bw; //*< byte written

        RefObject<Integer> i = new RefObject<Integer>(0); //*< general index
        /* construct frontendinfo req message */
        /* block sync */
        TMS_PUT_INT(TMSBLOCKSYNC, msg, i, 2);
        /* length 0, no data */
        msg[2] = 0x00;
        /* FrontendInfoReq type */
        msg[3] = TMSFRONTENDINFOREQ;
        /* add checksum */
        bw = TMS_PUT_CHKSUM(msg, 4);

        if ((vb & 0x01) != 0) {
            TMS_WRITE_LOG_MSG(msg, bw, "send frontendinfo request");
        }
        try {
            /* send request */
//        bw = send(fd, msg, bw, 0);
				//System.err.print("Writing message : ");dumpMsg(msg,0,bw);
				OutputStream fdout = fd.getOutputStream();
            fdout.write(msg,0,bw);
				fdout.flush();
				
        } catch (IOException ex) {
            System.err.println("Error writing output...");
            return 0;
        }
        /* return number of byte actualy written */
        return (1);
    }

    /**
     * Send keepalive request to 'fd'.
     *
     * @return bytes send.
     */
    public int tms_snd_keepalive(Socket fd) {

        RefObject<Integer> i = new RefObject<Integer>(0); //*< general index
        byte[] msg = new byte[6]; //*< message buffer
        int bw; //*< byte written

        /* construct frontendinfo req message */
        /* block sync */
        TMS_PUT_INT(TMSBLOCKSYNC, msg, i, 2);
        /* length 0, no data */
        msg[2] = 0x00;
        /* FrontendInfoReq type */
        msg[3] = TMSKEEPALIVEREQ;
        /* add checksum */
        bw = TMS_PUT_CHKSUM(msg, 4);

        if ((vb & 0x01) != 0) {
            TMS_WRITE_LOG_MSG(msg, bw, "send keepalive");
        }
        try {
            /* send request */
//        bw = send(fd, msg, bw, 0);
				OutputStream fdout = fd.getOutputStream();
            fdout.write(msg,0,bw);
				fdout.flush();
        } catch (IOException ex) {
            System.err.println("Error writing output...");
            return 0;
        }
        return (1);
    }

    /**
     * Convert buffer 'msg' of 'n' bytes into frontendinfo_t 'fei'
     *
     * @note 'b' needs size of TMSFRONTENDINFOSIZE
     * @return -1 on failure and on succes number of frontendinfo structs
     */
    public int tms_get_frontendinfo(byte[] msg, int n, TMS_FRONTENDINFO_T fei) {

        RefObject<Integer> i = new RefObject<Integer>(0); //*< general index
        int type; //*< message type
        int size; //*< payload size
        int nfei; //*< number of frontendinfo_t structs

        /* get message type */
        type = tms_get_type(msg, n);
        if (type != TMSFRONTENDINFO) {
            System.err.format("# Warning: tms_get_frontendinfo type %02X != %02X\n", type, TMSFRONTENDINFO);
            return (-3);
        }
        /* get payload size and start pointer */
        size = TMS_MSG_SIZE(msg, n, i);
        /* number of available frontendinfo_t structs */
        nfei = (2 * size) / TMSFRONTENDINFOSIZE;
        if (nfei > 1) {
            System.err.format("# Error: tms_get_frontendinfo found %d struct > 1\n", nfei);
        }
        fei.nrofuserchannels = (short) TMS_GET_INT(msg, i, 2);
        fei.currentsampleratesetting = (short) TMS_GET_INT(msg, i, 2);
        fei.mode = (short) TMS_GET_INT(msg, i, 2);
        fei.maxRS232 = (short) TMS_GET_INT(msg, i, 2);
        fei.serialnumber = TMS_GET_INT(msg, i, 4);
        fei.nrEXG = (short) TMS_GET_INT(msg, i, 2);
        fei.nrAUX = (short) TMS_GET_INT(msg, i, 2);
        fei.hwversion = (short) TMS_GET_INT(msg, i, 2);
        fei.swversion = (short) TMS_GET_INT(msg, i, 2);
        fei.cmdbufsize = (short) TMS_GET_INT(msg, i, 2);
        fei.sendbufsize = (short) TMS_GET_INT(msg, i, 2);
        fei.nrofswchannels = (short) TMS_GET_INT(msg, i, 2);
        fei.basesamplerate = (short) TMS_GET_INT(msg, i, 2);
        fei.power = (short) TMS_GET_INT(msg, i, 2);
        fei.hardwarecheck = (short) TMS_GET_INT(msg, i, 2);
        /* number of found Frontend system info structs */
        return (nfei);
    }

    public TMS_FRONTENDINFO_T tms_get_fei() {
        return fei;
    }

    /**
     * Write frontendinfo_t 'fei' into socket 'fd'.
     *
     * @return number of bytes written (<0: failure)
     */
    public int tms_write_frontendinfo(Socket fd, TMS_FRONTENDINFO_T fei) {

        RefObject<Integer> i = new RefObject<Integer>(0); //*< general index
        byte[] msg = new byte[0x40]; //*< message buffer
        int bw; //*< byte written

        /* construct frontendinfo req message */
        /* block sync */
        TMS_PUT_INT(TMSBLOCKSYNC, msg, i, 2);
        /* length */
        TMS_PUT_INT(TMSFRONTENDINFOSIZE / 2, msg, i, 1);
        /* FrontendInfoReq type */
        TMS_PUT_INT(TMSFRONTENDINFO, msg, i, 1);

        /* readonly !!! */
        TMS_PUT_INT(fei.nrofuserchannels, msg, i, 2);

        /* writable*/
        TMS_PUT_INT(fei.currentsampleratesetting, msg, i, 2);
        TMS_PUT_INT(fei.mode, msg, i, 2);

        /* readonly !!! */
        TMS_PUT_INT(fei.maxRS232, msg, i, 2);
        TMS_PUT_INT(fei.serialnumber, msg, i, 4);
        TMS_PUT_INT(fei.nrEXG, msg, i, 2);
        TMS_PUT_INT(fei.nrAUX, msg, i, 2);
        TMS_PUT_INT(fei.hwversion, msg, i, 2);
        TMS_PUT_INT(fei.swversion, msg, i, 2);
        TMS_PUT_INT(fei.cmdbufsize, msg, i, 2);
        TMS_PUT_INT(fei.sendbufsize, msg, i, 2);
        TMS_PUT_INT(fei.nrofswchannels, msg, i, 2);
        TMS_PUT_INT(fei.basesamplerate, msg, i, 2);
        TMS_PUT_INT(fei.power, msg, i, 2);
        TMS_PUT_INT(fei.hardwarecheck, msg, i, 2);
        /* add checksum */
        bw = TMS_PUT_CHKSUM(msg, i.argValue);

        if ((vb & 0x01) != 0) {
            TMS_WRITE_LOG_MSG(msg, bw, "write frontendinfo");
        }
        /* send request */
        try {
            /* send request */
//        bw = send(fd, msg, bw, 0);
				OutputStream fdout = fd.getOutputStream();
            fdout.write(msg,0,bw);
				fdout.flush();
        } catch (IOException ex) {
            System.err.println("Error writing output...");
            return 0;
        }
        return 1;
    }

    /**
     * Print TMS_FRONTENDINFO_T 'fei' to file 'fp'.
     *
     * @return number of printed characters.
     */
    public int tms_prt_frontendinfo(PrintStream fp, TMS_FRONTENDINFO_T fei, int nr, int hdr) {

        int nc = 0; //*< number of printed characters

        if (fp == null) {
            return (nc);
        }
        if (hdr != 0) {
            fp = fp.format("# TMSi frontend info\n");
            fp = fp.format("# %3s %3s %2s %4s %9s %4s %4s %4s %4s %4s %4s %4s %4s %4s %4s\n", "uch", "css", "md", "mxfs", "serialnr", "nEXG", "nAUX", "hwv", "swv", "cmds", "snds", "nc", "bfs", "pw", "hwck");
        }
        fp = fp.format(" %4d %3d %02X %4d %9d %4d %4d %04X %04X %4d %4d %4d %4d %04X %04X\n", fei.nrofuserchannels, fei.currentsampleratesetting, fei.mode, fei.maxRS232, fei.serialnumber, fei.nrEXG, fei.nrAUX, fei.hwversion, fei.swversion, fei.cmdbufsize, fei.sendbufsize, fei.nrofswchannels, fei.basesamplerate, fei.power, fei.hardwarecheck);
        return (1);
    }

    /**
     * Send IDData request to file descriptor 'fd'
     */
    public int tms_send_iddata_request(Socket fd, int adr, int len) {
        byte[] req = new byte[10]; //*< id request message
        RefObject<Integer> i = new RefObject<Integer>(0);
        int bw; //*< byte written

        /* block sync */
        TMS_PUT_INT(TMSBLOCKSYNC, req, i, 2);
        /* length 2 */
        TMS_PUT_INT(0x02, req, i, 1);
        /* IDReadReq type */
        TMS_PUT_INT(DefineConstants.TMSIDREADREQ, req, i, 1);
        /* start address */
        TMS_PUT_INT(adr, req, i, 2);
        /* maximum length */
        TMS_PUT_INT(len, req, i, 2);
        /* add checksum */
        bw = TMS_PUT_CHKSUM(req, i.argValue);

        if ((vb & 0x01) != 0) {
            TMS_WRITE_LOG_MSG(req, bw, "send IDData request");
        }
        try {
            /* send request */
//        bw = send(fd, req, bw, 0);
				//System.err.print("Sending iddata req:");dumpMsg(req,0,bw);
				OutputStream fdout = fd.getOutputStream();
            fdout.write(req,0,bw);
				fdout.flush();
        } catch (IOException ex) {
            System.err.println("Error writing output...");
            return 0;
        }
        return 1;
    }

    final class DefineConstants {

        public static final int TMSIDREADREQ = 0x22;
        public static final int TMSIDDATA = 0x23;
    }

    /**
     * Get IDData from device descriptor 'fd' into byte array 'msg' with maximum
     * size 'n'.
     *
     * @return bytes in 'msg'.
     */
    public int tms_fetch_iddata(Socket fd, byte[] msg, int n) {

        RefObject<Integer> i = new RefObject<Integer>(0); //*< general index
        int j;
        short adr = 0x0000; //*< start address of buffer ID data
        short len = 0x80; //*< amount of words requested
        int br = 0; //*< bytes read
        RefObject<Integer> tbw = new RefObject<Integer>(0); //*< total bytes written in 'msg'
        byte[] rcv = new byte[512]; //*< recieve buffer
        int type; //*< received IDData type
        int size; //*< received IDData size
        int tsize = 0; //*< total received IDData size
        int start = 0; //*< start address in receive ID Data packet
        int length = 0; //*< length in receive ID Data packet
        int rtc = 0; //*< retry counter

        /* prepare response header */
        /* block sync */
        TMS_PUT_INT(TMSBLOCKSYNC, msg, tbw, 2);
        /* length 0xFF */
        TMS_PUT_INT(0xFF, msg, tbw, 1);
        /* IDData type */
        TMS_PUT_INT(TMSIDDATA, msg, tbw, 1);
        /* temp zero length, final will be put at the end */
        TMS_PUT_INT(0, msg, tbw, 4);

        /* start address and maximum length */
        adr = 0x0000;
        len = 0x80;

        rtc = 0;
        /* keep on requesting id data until all data is read */
		  System.err.format("Requesting ID data, of up to %d bytes\n",n);
        while ((rtc < 10) && (len > 0) && (tbw.argValue < n)) {
            rtc++;
            if (tms_send_iddata_request(fd, adr, len) < 0) {
					 System.err.println("IDData Request failed");
                continue;
            }
            /* get response */
            br = tms_rcv_msg(fd, rcv, rcv.length);
				//System.err.println("IDdata req, resp-size : " +br);
				
            /* check checksum and get type of response */
            type = tms_get_type(rcv, br);
            if (type != TMSIDDATA) {
                System.err.format("# Warning: tms_get_iddata: unexpected type 0x%02X\n", type);
                continue;
            } else {
                /* get payload of 'rcv' */
                size = TMS_MSG_SIZE(rcv, Byte.SIZE, i);
                /* get start address */
                start = TMS_GET_INT(rcv, i, 2);
                /* get length */
                length = TMS_GET_INT(rcv, i, 2);
                /* copy response to final result */
                if (tbw.argValue + 2 * length > n) {
                    System.err.format("# Error: tms_get_iddata: msg too small %d\n", tbw.argValue + 2 * length);
                } else {
                    for (j = 0; j < 2 * length; j++) {
                        msg[tbw.argValue + j] = rcv[i.argValue + j];
                    }
                    tbw.argValue += 2 * length;
                    tsize += length;
                }
                /* update address admin */
                adr += length;
                /* if block ends with 0xFFFF, then this one was the last one */
                if ((rcv[2 * size - 2] == 0xFF) && (rcv[2 * size - 1] == 0xFF)) {
						  //System.err.println("IDData - got end block");
                    len = 0;
                }
            }
        }
        /* put final total size */
        i.argValue = 4;
        TMS_PUT_INT(tsize, msg, i, 4);
        /* add checksum */
        tbw.argValue = (int) TMS_PUT_CHKSUM(msg, tbw.argValue);
		  
        /* return number of byte actualy written */
        return (tbw.argValue);
    }

    /**
     * Convert buffer 'msg' of 'n' bytes into tms_type_desc_t 'td'
     *
     * @return 0 on success, -1 on failure
     */
    public int tms_get_type_desc(byte[] msg, int n, int start, TMS_TYPE_DESC_T td) {

        RefObject<Integer> i = new RefObject<Integer>(start); //*< general index

        td.Size = (short) TMS_GET_INT(msg, i, 2);
        td.Type = (short) TMS_GET_INT(msg, i, 2);
        td.SubType = (short) TMS_GET_INT(msg, i, 2);
        td.Format = (short) TMS_GET_INT(msg, i, 2);
        td.a = tms_get_float(msg, i);
        td.b = tms_get_float(msg, i);
        td.UnitId = (byte) TMS_GET_INT(msg, i, 1);
        td.Exp = (byte) TMS_GET_INT(msg, i, 1);
        if (i.argValue <= n) {
            return (0);
        } else {
            return (-1);
        }
    }

    /**
     * Get input device struct 'inpdev' at position 'start' of message 'msg' of
     * 'n' bytes
     *
     * @return always on success, -1 on failure
     */
    public int tms_get_input_device(byte[] msg, int n, int start, TMS_INPUT_DEVICE_T inpdev) {

        RefObject<Integer> i = new RefObject<Integer>(start); //*< general index
        int j;
        int idx; //*< location
        int ChannelDescriptionSize;
        int nb; //*< number of bits
        int tnb; //*< total number of bits

		  //System.err.println("tms_get_input_dev");dumpMsg(msg,n,start);		  
		  
        inpdev.Size = (short) TMS_GET_INT(msg, i, 2);
        inpdev.Totalsize = (short) TMS_GET_INT(msg, i, 2);
        inpdev.SerialNumber = TMS_GET_INT(msg, i, 4);
        inpdev.Id = (short) TMS_GET_INT(msg, i, 2);
        idx = 2 * TMS_GET_INT(msg, i, 2) + start;
        inpdev.DeviceDescription = tms_get_string(msg, n, idx);
		  System.err.println("tms_get_input_dev: devdescript= " + inpdev.DeviceDescription);
        inpdev.NrOfChannels = (short) TMS_GET_INT(msg, i, 2);
		  System.err.println("tms_get_input_dev: nrCh= " + inpdev.NrOfChannels);
        ChannelDescriptionSize = TMS_GET_INT(msg, i, 2);
        /* allocate space for all channel descriptions */
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'calloc' has no equivalent in Java:
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
        inpdev.Channel = new TMS_CHANNEL_DESC_T[inpdev.NrOfChannels];
		  for ( int iii=0; iii<inpdev.Channel.length; iii++) inpdev.Channel[iii]=new TMS_CHANNEL_DESC_T();
        /* get pointer to first channel description */
        idx = 2 * TMS_GET_INT(msg, i, 2) + start;
        /* goto first channel descriptor */
        i.argValue = idx;
        /* get all channel descriptions */
        for (j = 0; j < inpdev.NrOfChannels; j++) {
            idx = 2 * TMS_GET_INT(msg, i, 2) + start;
            tms_get_type_desc(msg, n, idx, inpdev.Channel[j].Type);
            idx = 2 * TMS_GET_INT(msg, i, 2) + start;
            inpdev.Channel[j].ChannelDescription = tms_get_string(msg, n, idx);
            inpdev.Channel[j].GainCorrection = tms_get_float(msg, i);
            inpdev.Channel[j].OffsetCorrection = tms_get_float(msg, i);
        }
        /* count total number of bits needed */
        tnb = 0;
        for (j = 0; j < inpdev.NrOfChannels; j++) {
            nb = inpdev.Channel[j].Type.Format & 0xFF;
            if (nb % 8 != 0) {
                System.err.format("# Warning: tms_get_input_device: channel %d has %d bits\n", j, nb);
            }
            tnb += nb;
        }
        if (tnb % 16 != 0) {
            System.err.format("# Warning: tms_get_input_device: total bits count %d %% 16 !=0\n", tnb);
        }
        inpdev.DataPacketSize = (short) (tnb / 16);

        if (i.argValue <= n) {
            return (0);
        } else {
            return (-1);
        }
    }

    public TMS_INPUT_DEVICE_T tms_get_in_dev() {
        return in_dev;
    }

    /**
     * Get input device struct 'inpdev' at position 'start' of message 'msg' of
     * 'n' bytes
     *
     * @return always on success, -1 on failure
     */
    public int tms_get_iddata(byte[] msg, int n, TMS_INPUT_DEVICE_T inpdev) {

        int type; //*< message type
        RefObject<Integer> i = new RefObject<Integer>(0); //*< general index
        int size; //*< payload size

        /* get message type */
        type = tms_get_type(msg, n);
        if (type != TMSIDDATA) {
            System.err.format("# Warning: type %02X != %02X\n", type, TMSIDDATA);
            return (-1);
        }
        size = TMS_MSG_SIZE(msg, n, i);
        return (tms_get_input_device(msg, n, i.argValue, inpdev));
    }

    /**
     * Print tms_type_desc_t 'td' to file 'fp'.
     *
     * @return number of printed characters.
     */
    public int tms_prt_type_desc(PrintStream fp, TMS_TYPE_DESC_T td, int nr, int hdr) {

        int nc = 0; //*< number of printed characters

        if (fp == null) {
            return (nc);
        }
        if (hdr != 0) {
            fp = fp.format(" %6s %4s %4s %4s %4s %2s %3s %9s %9s %3s %4s %3s\n", "size", "type", "typd", "sty", "styd", "sg", "bit", "a", "b", "uid", "uidd", "exp");
        }
        if (td == null) {
            return (nc);
        }

        fp = fp.format(" %6d %4d", td.Size, td.Type);
        switch (td.Type) {
            case 0:
                fp = fp.format(" %4s", "UNKN");
                break;
            case 1:
                fp = fp.format(" %4s", "EXG");
                break;
            case 2:
                fp = fp.format(" %4s", "BIP");
                break;
            case 3:
                fp = fp.format(" %4s", "AUX");
                break;
            case 4:
                fp = fp.format(" %4s", "DIG ");
                break;
            case 5:
                fp = fp.format(" %4s", "TIME");
                break;
            case 6:
                fp = fp.format(" %4s", "LEAK");
                break;
            case 7:
                fp = fp.format(" %4s", "PRES");
                break;
            case 8:
                fp = fp.format(" %4s", "ENVE");
                break;
            case 9:
                fp = fp.format(" %4s", "MARK");
                break;
            case 10:
                fp = fp.format(" %4s", "ZAAG");
                break;
            case 11:
                fp = fp.format(" %4s", "SAO2");
                break;
            default:
                break;
        }

        // (+256: unipolar reference, +512: impedance reference)
        fp = fp.format(" %4d", td.SubType);
        /* SybType description */
        switch (td.SubType) {
            case 0:
                fp = fp.format(" %4s", "Unkn");
                break;
            case 1:
                fp = fp.format(" %4s", "EEG");
                break;
            case 2:
                fp = fp.format(" %4s", "EMG");
                break;
            case 3:
                fp = fp.format(" %4s", "ECG");
                break;
            case 4:
                fp = fp.format(" %4s", "EOG");
                break;
            case 5:
                fp = fp.format(" %4s", "EAG");
                break;
            case 6:
                fp = fp.format(" %4s", "EGG");
                break;
            case 257:
                fp = fp.format(" %4s", "EEGR");
                break;
            case 10:
                fp = fp.format(" %4s", "resp");
                break;
            case 11:
                fp = fp.format(" %4s", "flow");
                break;
            case 12:
                fp = fp.format(" %4s", "snor");
                break;
            case 13:
                fp = fp.format(" %4s", "posi");
                break;
            case 522:
                fp = fp.format(" %4s", "impr");
                break;
            case 20:
                fp = fp.format(" %4s", "SaO2");
                break;
            case 21:
                fp = fp.format(" %4s", "plet");
                break;
            case 22:
                fp = fp.format(" %4s", "hear");
                break;
            case 23:
                fp = fp.format(" %4s", "sens");
                break;
            case 30:
                fp = fp.format(" %4s", "PVES");
                break;
            case 31:
                fp = fp.format(" %4s", "PURA");
                break;
            case 32:
                fp = fp.format(" %4s", "PABD");
                break;
            case 33:
                fp = fp.format(" %4s", "PDET");
                break;
            default:
                break;
        }

        fp = fp.format(" %2s %3d %9e %9e %3d", ((td.Format & 0x0100) == 0 ? "S" : "U"), (td.Format & 0xFF), td.a, td.b, td.UnitId);
        /* UnitId description */
        switch (td.UnitId) {
            case 0:
                fp = fp.format(" %4s", "bit");
                break;
            case 1:
                fp = fp.format(" %4s", "Volt");
                break;
            case 2:
                fp = fp.format(" %4s", "%");
                break;
            case 3:
                fp = fp.format(" %4s", "Bpm");
                break;
            case 4:
                fp = fp.format(" %4s", "Bar");
                break;
            case 5:
                fp = fp.format(" %4s", "Psi");
                break;
            case 6:
                fp = fp.format(" %4s", "mH2O");
                break;
            case 7:
                fp = fp.format(" %4s", "mHg");
                break;
            case 8:
                fp = fp.format(" %4s", "bit");
                break;
            default:
                break;
        }
        fp = fp.format(" %3d\n", td.Exp);
        return (nc);
    }

    /**
     * Print input device struct 'inpdev' to file 'fp'
     *
     * @return number of characters printed.
     */
    public int tms_prt_iddata(PrintStream fp, TMS_INPUT_DEVICE_T inpdev) {

        int i = 0; //*< general index
        int nc = 0; //*< number of printed characters

        if (fp == null) {
            return (nc);
        }
        fp = fp.format("# Input Device %s Serialnr %d\n", inpdev.DeviceDescription, inpdev.SerialNumber);
        /* ChannelDescriptions */
        fp = fp.format("#%3s %7s %12s %12s", "nr", "Channel", "Gain", "Offset");
        nc += tms_prt_type_desc(fp, null, 0, 1);

        /* print all channel descriptors */
        for (i = 0; i < inpdev.NrOfChannels; i++) {
            fp = fp.format(" %3d %7s %12e %12e", i, inpdev.Channel[i].ChannelDescription, inpdev.Channel[i].GainCorrection, inpdev.Channel[i].OffsetCorrection);
            /* print type description */
            nc += tms_prt_type_desc(fp, inpdev.Channel[i].Type, i, 0);
        }
        return (nc);
    }

    /**
     * Open socket device 'fname' to TMSi aquisition device Nexus-10 or Mobi-8.
     *
     * @return socket >0 on success.
     */
    public Socket tms_open_port(String fname) {
        int status = 0;
        int ci = 0;
        int isbt = 0;
        int optval = 0;
        Socket s = null;

        /* test if this is a BT connection or a socket connection */
        /* Heuristic is: if >1 ':' character then is BT address... */
        isbt = 0;
        for (ci = 0; ci<fname.length(); ci++) {
            if (fname.charAt(ci) == ':') {
                isbt++;
            }
            /* alternative if have >1 '.' is a socket address */
            if (fname.charAt(ci) == '.') {
                isbt = -1;
            }
        }
        isbt = (isbt > 1) ? 1 : 0;
        System.out.println(fname);

        if (isbt != 0) {
            System.err.println("Bluetooth not supported!");
            System.exit(1);
        } else { // this is a network socket connection
            System.err.println("Opening TCP/IP device :" + fname);
            /* N.B. Type: TCP, Port: 4242 */
            /* split the name into host:port parts */
//            hostent server;
            String host = fname;
            int port = DEFAULTPORT;
				int sep = host.indexOf(':');
				if ( sep>0 ) {
					 port=Integer.parseInt(host.substring(sep+1,host.length()));
					 host=host.substring(0,sep);
				}

            /* socket: create the socket */
//            s = socket(AF_INET, SOCK_STREAM, 0);
            s = new Socket();
            System.err.println("socket created\n");
//            if (s. < 0) {
//                System.err.format("ERROR opening socket: %d\n", s);
//                System.exit(0);
//            }
            /* enlarge the buffers to allow for some delay in processing the
             data */
            optval = 163840;
            try {
                //            status = setsockopt(s, SOL_SOCKET, SO_RCVBUF, "" + optval, Integer.SIZE);
                s.setReceiveBufferSize(163840);
            } catch (SocketException ex) {
                System.err.format("setsockopt error RCVBUF: %d\n", status);
            }
            optval = 163840;
            try {
                //            status = setsockopt(s, SOL_SOCKET, SO_SNDBUF, "" + optval, Integer.SIZE);
                s.setSendBufferSize(163840);
            } catch (SocketException ex) {
                System.err.format("setsockopt error SNDBUF: %d\n", status);
            }

            optval = 1000;
//            status = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, "" + optval, Integer.SIZE);

            try {
                s.setSoTimeout(1000);
            } catch (SocketException ex) {

                System.err.format("setsockopt error RCVTIMEO: %d\n", status);

            }

            optval = 1;
            try {
                //            status = setsockopt(s, SOL_SOCKET, SO_REUSEPORT, "" + optval, Integer.SIZE);
                s.setReuseAddress(true);
            } catch (SocketException ex) {
                System.err.format("setsockopt error REUSEPORT: %d\n", status);
            }
            optval = 0;
            try {
                //            status = setsockopt(s, SOL_SOCKET, SO_KEEPALIVE, "" + optval, Integer.SIZE);
                s.setKeepAlive(false);
            } catch (SocketException ex) {
                System.err.format("setsockopt error KEEPALIVE: %d\n", status);
            }

	 /* disable the Nagle buffering algorithm */
            optval = 1;
            try {
                //            status = setsockopt(s, IPPROTO_TCP, TCP_NODELAY, "" + optval, Integer.SIZE);
                s.setTcpNoDelay(true);
            } catch (SocketException ex) {
                System.err.format("setsockopt error NODELAY: %d\n", status);
            }

//            server = gethostbyname(host);
            InetAddress server = null;
            try {
                server = InetAddress.getByName(host);
            } catch (UnknownHostException ex) {
                System.err.println("ERROR, no such host as :"+ host);
                System.exit(0);
            }
            System.err.println("host resovled : " + server);

            InetSocketAddress serveraddr = new InetSocketAddress(server, port);
            /* build the server's Internet address */
            try {
                /* open connection to TMSi hardware */
                /* connect: create a connection with the server */
					 System.err.println("Connecting to: " + serveraddr);
                s.connect(serveraddr);
            } catch (IOException ex) {
                System.err.println("ERROR, connecting to " + host + ":" + port);
					 System.err.println(ex);
                s=null;
            }
            System.err.println("connection made");
        }

        /* return socket */
        return s;
    }

    /**
     * Close file descriptor 'fd'.
     *
     * @return 0 on successm, errno on failure.
     */
    public int tms_close_port(Socket fd) {

        try {
            fd.close();
        } catch (IOException ex) {
            System.err.format("close_port: Error closing port - ");
            return 1;
        }

        return (0);
    }

    /**
     * Print channel data block 'chd' of tms device 'dev' to file 'fp'.
     *
     * @param print switch md 0: integer 1: float values
     * @return number of printed characters.
     */
    public int tms_prt_channel_data(PrintStream fp, TMS_INPUT_DEVICE_T dev, TMS_CHANNEL_DATA_T[] chd, int md) {
        int i; //*< general index
        int j;
        int nc = 0;

        fp = fp.format("# Channel data\n");
        for (j = 0; j < dev.NrOfChannels; j++) {
            fp = fp.format("%2d %2d %2d |", j, chd[j].ns, chd[j].rs);
            for (i = 0; i < chd[j].rs; i++) {
                if (md == 0) {
                    fp = fp.format(" %08X%1C", chd[j].data[i].isample, (chd[j].data[i].flag & 0x01) == 0 ? '*' : ' ');
                } else {
                    fp = fp.format(" %9g%1C", chd[j].data[i].sample, (chd[j].data[i].flag & 0x01) == 0 ? '*' : ' ');
                }
            }
            fp = fp.format("\n");
        }
        return (nc);
    }

    /* Print bit string of 'msg' */
    public int tms_prt_bits(PrintStream fp, byte[] msg, int n, int idx) {
        int nc = 0;
        int i;
        int j;
        int a;

        /* hex values */
        fp = fp.format("Hex MSB");
        for (i = n - 1; i >= idx; i--) {
            fp = fp.format("       %02X", msg[i]);
        }
        fp = fp.format(" LSB\n");

        /* bin values */
        fp = fp.format("Bin MSB");
        for (i = n - 1; i >= idx; i--) {
            fp = fp.format(" ");
            a = msg[i];
            for (j = 0; j < 8; j++) {
                fp = fp.format("%1d", ((a & 0x80) != 0 ? 1 : 0));
                a = a << 1;
            }
        }
        fp = fp.format(" LSB\n");
        return (1);
    }

    /**
     * Get TMS data from message 'msg' of 'n' bytes into floats 'val'.
     *
     * @return number of samples.
     */
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public static int[] tms_get_data_srp = null;
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public static int[] tms_get_data_sample_cnt = null;

    /**
     * Get TMS data from message 'msg' of 'n' bytes into floats 'val'.
     *
     * @return number of samples.
     */
//C++ TO JAVA CONVERTER TODO TASK: Java does not have an equivalent for pointers to value types:
//ORIGINAL LINE: int *srp=null;
    public int tms_get_data(byte[] msg, int n, TMS_INPUT_DEVICE_T dev, TMS_CHANNEL_DATA_T[] chd) {
        int nbps; //*< number of bytes per sample
        int type; //*< TMS type and packet size
        int size;
        RefObject<Integer> i = new RefObject<Integer>(0); //*< general index
        int j;
        int cnt = 0; //*< sample counter
        int len; //*< delta sample: length, value and overflow flag
        int dv;
        int overflow;
        //C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
        //  static int *srp=null; //*< sample receiving period
        //C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
        //  static int *sample_cnt=null; //*< sample count per channel
        int maxns; //*< maximum number of samples
        int totns; //*< total number of samples in this block
        int pc; //*< period counter

        int zaagch = ZAAGCH; //*< sawtooth channel
        if (tms_get_number_of_channels() > zaagch) { // BODGE: assume ZAAG is last channel
            zaagch = tms_get_number_of_channels() - 1;
        }

        /* get message type */
        type = tms_get_type(msg, n);
        /* parse packet data */
        size = TMS_MSG_SIZE(msg, n, i);

        for (j = 0; j < dev.NrOfChannels; j++) {
            /* only 1, 2 or 3 bytes width expected !!! */
            nbps = (dev.Channel[j].Type.Format & 0xFF) / 8;
            /* get integer sample values */

            chd[j].data[0].isample = TMS_GET_INT(msg, i, nbps);
            /* sign extension for signed samples */
            if ((dev.Channel[j].Type.Format & 0x0100) != 0) {
//C++ TO JAVA CONVERTER WARNING: The right shift operator was not replaced by Java's logical right shift operator since the left operand was not confirmed to be of an unsigned type, but you should review whether the logical right shift operator (>>>) is more appropriate:
                chd[j].data[0].isample = (chd[j].data[0].isample << (32 - 8 * nbps)) >> (32 - 8 * nbps);
            }
            /* check for overflow or underflow */
            chd[j].data[0].flag = 0x00;
            if (chd[j].data[0].isample == (0xFFFFFF80 << (8 * (nbps - 1)))) {
                chd[j].data[0].flag |= 0x01;
            }
            /* increment receive counter */
            chd[j].rs = 1;
        }

        if (tms_get_data_sample_cnt == null) {
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'calloc' has no equivalent in Java:
            tms_get_data_sample_cnt = new int[dev.NrOfChannels];
            for (j = 0; j < dev.NrOfChannels; j++) {
                tms_get_data_sample_cnt[j] = 0;
            }
        }

        /* continue with packets with VL Delta samples */
        if (type == TMSVLDELTADATA) {
            /* allocate space once for sample receive period */
            if (tms_get_data_srp == null) {
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'calloc' has no equivalent in Java:
                tms_get_data_srp = new int[dev.NrOfChannels];
            }
            /* find maximum period and count total number of samples */
            maxns = 0;
            totns = 0;
            for (j = 0; j < dev.NrOfChannels; j++) {
                if (chd[j].data[0].flag != 0) {
                    if (maxns < chd[j].ns) {
                        maxns = chd[j].ns;
                    }
                    totns += chd[j].ns;
                } else {
                    totns++;
                }
            }
            /* calculate sample receive period per channel */
            for (j = 0; j < dev.NrOfChannels; j++) {
                tms_get_data_srp[j] = maxns / chd[j].ns;
            }
            if ((vb & 0x04) != 0) {
                /* print delta block */
                System.err.format("\nDelta block of %d bytes totns %d\n", n - 2 - i.argValue, totns);
                tms_prt_bits(System.err, msg, n - 2, i.argValue);
                /* Delta block */
                System.err.println("Delta block:");
            }
            RefObject<Integer> bip = new RefObject<Integer>(8 * i.argValue);
            cnt = dev.NrOfChannels;
            j = 0;
            pc = 1;
            while ((cnt < totns) && (bip.argValue < 8 * n - 16)) {
                len = get_lsbf_int32_t(msg, bip, 4);
                if (len == 0) {
                    dv = get_lsbf_int32_t(msg, bip, 2);
                    overflow = 0;
                    switch (dv) {
                        case 0:
                            dv = 0;
                            overflow = 0;
                            break; // delta sample = 0
                        case 1:
                            dv = 0;
                            overflow = 0;
                            break; // not used
                        case 2:
                            dv = 0;
                            overflow = 1;
                            break; // overflow
                        case 3:
                            dv = -1;
                            overflow = 0;
                            break; // delta sample =-1
                        default:
                            break;
                    }
                } else {
                    dv = get_lsbf_int32_t_sign_ext(msg, bip, len);
                    overflow = 0;
                }
                if ((vb & 0x04) != 0) {
                    System.err.format(" %d:%d", len, dv);
                }
                /* find channel not in overflow and needs this sample */
                while ((chd[j].data[0].flag & 0x01) == 0 || (chd[j].rs >= chd[j].ns) || ((pc % tms_get_data_srp[j]) != 0)) {
                    /* next channel nr */
                    j++;
                    if (j == dev.NrOfChannels) {
                        j = 0;
                        pc++;
                    }
                    if (pc > maxns) {
                        break;
                    }
                }
                chd[j].data[chd[j].rs].isample = dv;
                chd[j].data[chd[j].rs].flag = overflow;
                if (len == 15) {
                    if (((dv & 0x7FFF) == 0x0000) || ((dv & 0x7FFF) == 0x7FFF)) {
                        chd[j].data[chd[j].rs].flag |= 0x02;
                    }
                }
                chd[j].rs++;
                /* delta sample counter */
                cnt++;
                /* next channel nr */
                j++;
                if (j == dev.NrOfChannels) {
                    j = 0;
                    pc++;
                }
            }
            if ((vb & 0x04) != 0) {
                System.err.format(" cnt %d\n", cnt);
            }
        }

        /* convert integer samples to real floats */
        for (j = 0; j < dev.NrOfChannels; j++) {
            /* integrate delta value to actual values or fill skipped overflow channels */
            for (i.argValue = 1; i.argValue < chd[j].ns; i.argValue++) {
                /* check overflow */
                if ((chd[j].data[0].flag & 0x01) != 0) {
                    chd[j].data[i.argValue].isample = chd[j].data[0].isample;
                    chd[j].data[i.argValue].flag = chd[j].data[0].flag;
                } else {
                    chd[j].data[i.argValue].isample += chd[j].data[i.argValue - 1].isample;
                }
            }

            /* convert to real (calibrated) float values */
            for (i.argValue = 0; i.argValue < chd[j].ns; i.argValue++) {
                if (j != zaagch) { // apply the scaling and offset correction
                    chd[j].data[i.argValue].sample = (dev.Channel[j].Type.a) * chd[j].data[i.argValue].isample + dev.Channel[j].Type.b;
                } else { // zaagch is directly the isample version
                    chd[j].data[i.argValue].sample = chd[j].data[i.argValue].isample;
                }
            }
            /* update sample counter */
            chd[j].sc = tms_get_data_sample_cnt[j];
            tms_get_data_sample_cnt[j] += chd[j].ns;
        }
        return (cnt);
    }
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public static int tms_prt_samples_maxns = 0;
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public static TMS_DATA_T[] tms_prt_samples_prt = null;

    /**
     * Print TMS channel data 'chd' to file 'fp'.
     *
     * @param md: print switch 0: float 1: integer values
     * @param cs: bit-mask to select channels A: 0x01 B: 0x02 C: 0x04 ...
     * @return number of characters printed.
     */
    public static int tms_prt_samples(PrintStream fp, TMS_CHANNEL_DATA_T[] chd, int cs, int md) {
        int nc = 0; //*< number of characters printed
        //C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
        //  static int maxns=0; //*< maximum number of samples over all channels
        int mns; //*< current maxns
        int i; //*< general index
        int j;
        int jm;
        int idx;
        int ssf; //*< sub-sample factor
        //C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
        //  static TMS_DATA_T *prt=null; //*< printer storage for all samples over all channels

        /* search for current maximum number of samples over all channels */
        mns = 0;
        for (j = 0; j < tms_get_number_of_channels(); j++) {
            if (mns < chd[j].ns) {
                mns = chd[j].ns;
            }
        }

        if (mns > tms_prt_samples_maxns) {
            tms_prt_samples_maxns = mns;
            if (tms_prt_samples_prt != null) {
                /* free previous printer storage space */
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'free' has no equivalent in Java:
            }
            /* malloc storage space for rectangle print data array */
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'calloc' has no equivalent in Java:
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
            tms_prt_samples_prt = new TMS_DATA_T[tms_prt_samples_maxns * tms_get_number_of_channels()];
				for ( int iii=0; iii<tms_prt_samples_prt.length; iii++) tms_prt_samples_prt[iii]=new TMS_DATA_T();
        }

        /* search for channel 'jm' with maximum number of samples over all wanted channels */
        mns = 0;
        jm = 0;
        for (j = 0; j < tms_get_number_of_channels(); j++) {
            if ((cs & (1 << j)) != 0) {
                if (mns < chd[j].ns) {
                    mns = chd[j].ns;
                    jm = j;
                }
            }
        }

        /* fill all wanted channels */
        for (j = 0; j < tms_get_number_of_channels(); j++) {
            if ((cs & (1 << j)) != 0) {
                ssf = mns / chd[j].ns;
                for (i = 0; i < mns; i++) {
                    idx = tms_prt_samples_maxns * j + i;
                    if ((i % ssf) == 0) {
                        /* copy samples into rectanglar array 'ptr' */
                        tms_prt_samples_prt[idx] = chd[j].data[i / ssf];
                    } else {
                        /* fill all unavailable samples with "NaN" -> flag=0x04 */
                        tms_prt_samples_prt[idx].isample = 0;
                        tms_prt_samples_prt[idx].sample = 0.0f;
                        tms_prt_samples_prt[idx].flag = 0x04;
                    }
                }
            }
        }
        /* print output file header */
        if (chd[0].sc == 0) {
            fp = fp.format("#%9s %8s", "t[s]", "sc");
            for (j = 0; j < tms_get_number_of_channels(); j++) {
                if ((cs & (1 << j)) != 0) {
                    fp = fp.format(" %8s%1c", "", 'A' + j);
                }
            }
            fp = fp.format("\n");
        }

        /* print all wanted channels */
        for (i = 0; i < mns; i++) {
            fp = fp.format(" %9.4f %8d", (chd[jm].sc + i) * chd[jm].td, chd[jm].sc + i);
            for (j = 0; j < tms_get_number_of_channels(); j++) {
                if ((cs & (1 << j)) != 0) {
                    idx = tms_prt_samples_maxns * j + i;
                    if (tms_prt_samples_prt[idx].flag != 0) {
                        /* all overflows and not availables are mapped to "NaN" */
                        fp = fp.format(" %9s", "NaN");
                    } else {
                        if (md == 0) {
                            fp = fp.format(" %9.3f", tms_prt_samples_prt[idx].sample);
                        } else {
                            fp = fp.format(" %9d", tms_prt_samples_prt[idx].isample);
                        }
                    }
                }
            }
            fp = fp.format("\n");
        }
        return (1);
    }

    /**
     * Send VLDeltaInfo request to file descriptor 'fd'
     */
    public int tms_snd_vldelta_info_request(OutputStream fd) {
        byte[] req = new byte[10]; //*< id request message
        RefObject<Integer> i = new RefObject<Integer>(0);
        int bw; //*< byte written

        /* block sync */
        TMS_PUT_INT(TMSBLOCKSYNC, req, i, 2);
        /* length 0 */
        TMS_PUT_INT(0x00, req, i, 1);
        /* IDReadReq type */
        TMS_PUT_INT(TMSVLDELTAINFOREQ, req, i, 1);
        /* add checksum */
        bw = TMS_PUT_CHKSUM(req, i.argValue);

        if ((vb & 0x01) != 0) {
            TMS_WRITE_LOG_MSG(req, bw, "send VLDeltaInfo request");
        }
        try {
            /* send request */
//        bw = send(fd, req, bw, 0);
            fd.write(req,0,bw);
				fd.flush();
        } catch (IOException ex) {
            System.err.println("# Warning: tms_send_vl_delta_info_request write problem");
        }
        return 1;
    }

    /**
     * Convert buffer 'msg' of 'n' bytes into TMS_VLDELTA_INFO_T 'vld' for 'nch'
     * channels.
     *
     * @return number of bytes processed.
     */
    public int tms_get_vldelta_info(byte[] msg, int n, int nch, TMS_VLDELTA_INFO_T vld) {

        RefObject<Integer> i = new RefObject<Integer>(0); //*< general index
        int j;
        int type; //*< message type
        int size; //*< payload size

        /* get message type */
        type = tms_get_type(msg, n);
        if (type != TMSVLDELTAINFO) {
            System.err.format("# Warning: tms_get_vldelta_info type %02X != %02X\n", type, TMSVLDELTAINFO);
            return (-1);
        }
        /* get payload size and payload pointer 'i' */
        size = TMS_MSG_SIZE(msg, n, i);
        vld.Config = (short) TMS_GET_INT(msg, i, 2);
        vld.Length = (short) TMS_GET_INT(msg, i, 2);
        vld.TransFreqDiv = (short) TMS_GET_INT(msg, i, 2);
        vld.NrOfChannels = (short) nch;
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'calloc' has no equivalent in Java:
        vld.SampDiv = new short[nch];
        for (j = 0; j < nch; j++) {
            vld.SampDiv[j] = (short) TMS_GET_INT(msg, i, 2);
        }
        /* number of found Frontend system info structs */
        return (i.argValue);
    }

    /**
     * Print TMS_RTC_T 'rtc' to file 'fp'.
     *
     * @return number of printed characters.
     */
    public static int tms_prt_vldelta_info(PrintStream fp, TMS_VLDELTA_INFO_T vld, int nr, int hdr) {

        int nc = 0; //*< number of printed characters
        int j; //*< general index

        if (fp == null) {
            return (nc);
        }
        if (hdr != 0) {
            fp = fp.format("# VL Delta Info\n");
            fp = fp.format("# %5s %6s %6s %6s %6s\n", "nr", "Config", "Length", "TransFS", "SampDiv");
        }
        fp = fp.format(" %6d %6d %6d %6d", nr, vld.Config, vld.Length, vld.TransFreqDiv);
        for (j = 0; j < vld.NrOfChannels; j++) {
            fp = fp.format(" %6d", vld.SampDiv[j]);
        }
        fp = fp.format("\n");
        return (nc);
    }

    /**
     * Send Real Time Clock (RTC) read request to file descriptor 'fd'
     *
     * @return number of bytes send.
     */
    public int tms_send_rtc_time_read_req(FileOutputStream fd) {
        byte[] req = new byte[10]; //*< id request message
        RefObject<Integer> i = new RefObject<Integer>(0);
        int bw; //*< byte written

        /* block sync */
        TMS_PUT_INT(TMSBLOCKSYNC, req, i, 2);
        /* length 0 */
        TMS_PUT_INT(0x00, req, i, 1);
        /* IDReadReq type */
        TMS_PUT_INT(TMSRTCTIMEREADREQ, req, i, 1);
        /* add checksum */
        bw = TMS_PUT_CHKSUM(req, i.argValue);

        if ((vb & 0x01) != 0) {
            TMS_WRITE_LOG_MSG(req, bw, "send rtc read request");
        }
        try {
            /* send request */
//        bw = send(fd, req, bw, 0);
            fd.write(req,0,bw);
				fd.flush();
        } catch (IOException ex) {
            System.err.println("# Warning: TMS_RTC_Time_read_request write problem");
        }

        return 1;
    }

    /**
     * Convert buffer 'msg' of 'n' bytes into TMS_RTC_T 'rtc'
     *
     * @return 0 on failure and number of bytes processed
     */
    public int tms_get_rtc(byte[] msg, int n, TMS_RTC_T rtc) {

        RefObject<Integer> i = new RefObject<Integer>(0); //*< general index
        int type; //*< message type
        int size; //*< payload size

        /* get message type */
        type = tms_get_type(msg, n);
        if (type != TMSRTCTIMEDATA) {
            System.err.format("# Warning: type %02X != %02X\n", type, TMSRTCTIMEDATA);
            return (-3);
        }
        /* get payload size and start pointer */
        size = TMS_MSG_SIZE(msg, n, i);
        if (size != 8) {
            System.err.format("# Warning: tms_get_rtc: unexpected size %d iso %d\n", size, 8);
        }
        /* parse message 'msg' */
        rtc.seconds = (short) TMS_GET_INT(msg, i, 2);
        rtc.minutes = (short) TMS_GET_INT(msg, i, 2);
        rtc.hours = (short) TMS_GET_INT(msg, i, 2);
        rtc.day = (short) TMS_GET_INT(msg, i, 2);
        rtc.month = (short) TMS_GET_INT(msg, i, 2);
        rtc.year = (short) TMS_GET_INT(msg, i, 2);
        rtc.century = (short) TMS_GET_INT(msg, i, 2);
        rtc.weekday = (short) TMS_GET_INT(msg, i, 2);
        return (i.argValue);
    }
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public static int tms_prt_rtc_putc = 0;
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public static int tms_prt_rtc_pnr = 0;

    /**
     * Print TMS_RTC_T 'rtc' to file 'fp'.
     *
     * @return number of printed characters.
     */
    public static int tms_prt_rtc(PrintStream fp, TMS_RTC_T rtc, int nr, int hdr) {

        int nc = 0; //*< number of printed characters
        int utc = 0; //*< number of seconds since 00:00:00
        //C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
        //  static int putc=0; //*< number of seconds since 00:00:00
        //C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
        //  static int pnr=0;

        if (fp == null) {
            return (nc);
        }
        if (hdr != 0) {
            fp = fp.format("# Real time clock\n");
            fp = fp.format("#    nr yyyy-mm-dd hh:mm:ss  utc\n");
        }

        utc = rtc.seconds + 60 * (rtc.minutes + 60 * rtc.hours);
        fp = fp.format(" %6d %02d%02d-%02d-%02d %02d:%02d:%02d %8d", nr, rtc.century, rtc.year, rtc.month, rtc.day, rtc.hours, rtc.minutes, rtc.seconds, utc);
        fp = fp.format(" %6d %6d\n", nr - tms_prt_rtc_pnr, utc - tms_prt_rtc_putc);
        /* remember previous values */
        tms_prt_rtc_pnr = nr;
        tms_prt_rtc_putc = utc;
        return (nc);
    }

    /**
     * Get the number of channels of this TMSi device
     *
     * @return number of channels
     */
    public static int tms_get_number_of_channels() {
        if (in_dev == null) {
            return -1;
        }
        return in_dev.NrOfChannels;
    }

    /**
     * Get the number of channels of this TMSi device
     *
     * @return number of channels
     */
    public static TMS_INPUT_DEVICE_T tms_input_device() {
        if (in_dev == null) {
            return null;
        }
        return in_dev;
    }

    /* Get the current sample frequency.
     * @return current sample frequency [Hz]
     */
    public static double tms_get_sample_freq() {
        if (fei == null) {
            return -1;
        }
        return (double) (fei.basesamplerate / (1 << fei.currentsampleratesetting));

    }

    /**
     * Construct channel data block with frontend info 'fei' and input device
     * 'dev' with eventually vldelta_info 'vld'.
     *
     * @return pointer to channel_data_t struct, NULL on failure.
     */
    public static TMS_CHANNEL_DATA_T[] tms_alloc_channel_data() {
        int i; //*< general index
        TMS_CHANNEL_DATA_T[] chd; //*< channel data block pointer
        int ns_max = 1; //*< maximum number of samples of all channels
        /* allocate storage space for all channels */
        chd = new TMS_CHANNEL_DATA_T[in_dev.NrOfChannels];
        for (i = 0; i < in_dev.NrOfChannels; i++) {
				chd[i] = new TMS_CHANNEL_DATA_T();
            if (vld == null) {
                chd[i].ns = 1;
            } else {
                chd[i].ns = (vld.TransFreqDiv + 1) / (vld.SampDiv[i] + 1);
            }
            /* reset sample counter */
            chd[i].sc = 0;
            if (chd[i].ns > ns_max) {
                ns_max = chd[i].ns;
            }
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'calloc' has no equivalent in Java:
//C++ TO JAVA CONVERTER TODO TASK: There is no Java equivalent to 'sizeof':
            chd[i].data = new TMS_DATA_T[chd[i].ns];
				for (int ii=0; ii<chd[i].data.length; ii++) chd[i].data[ii]=new TMS_DATA_T();
        }
        for (i = 0; i < in_dev.NrOfChannels; i++) {
            chd[i].td = ns_max / (chd[i].ns * tms_get_sample_freq());
        }
        return (chd);
    }

    /**
     * Free channel data block
     */
    public static void tms_free_channel_data(TMS_CHANNEL_DATA_T[] chd) {
        int i; //*< general index

        /* free storage space for all channels */
        for (i = 0; i < in_dev.NrOfChannels; i++) {
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'free' has no equivalent in Java:
        }
//C++ TO JAVA CONVERTER TODO TASK: The memory management function 'free' has no equivalent in Java:
    }

    public static int state = 0; //*< State machine
    public static Socket fd = null; //*< Stream descriptor of socket socket

    /**
     * Initialize TMSi device with Socket address 'fname' and sample rate
     * divider 'sample_rate_div'.
     *
     * @note no timeout implemented yet.
     * @return always 0
     */
    public int tms_init(String fname, int sample_rate_div) {
        int bw = 0; //*< bytes written
        int br = 0; //*< bytes read
        int fs = 0; //*< sample frequency
        byte[] resp = new byte[RESPSIZE]; //*< TMS response to challenge
        int type; //*< TMS message type

        TMS_ACKNOWLEDGE_T ack = new TMS_ACKNOWLEDGE_T(); //*< TMS acknowlegde

        fei = new TMS_FRONTENDINFO_T();
        vld = new TMS_VLDELTA_INFO_T();
        in_dev = new TMS_INPUT_DEVICE_T();

        fd = tms_open_port(fname);
        if ( fd == null ) {
            System.err.println("Failed to open socket");
            return -1;
        } 
        System.out.println("Opened socket " + fd);

        while (state < 4) {
            switch (state) {
                case 0:
						  System.err.println("State=0");
                    /* send frontend Info request */
                    bw = tms_snd_FrontendInfoReq(fd);
						  System.err.println("Sent FrontInfoReq");
                    /* receive response to frontend Info request */
                    br = tms_rcv_msg(fd, resp, resp.length);
						  //System.err.println("FrontInfoReqResp message so far:\n");dumpMsg(resp,br,0);
                    break;
                case 1:
						  System.err.println("State=1");
                    /* switch off data capture when it is on */
                    /* stop capture */
                    fei.mode |= 0x01;
                    /* stop storage */
                    fei.mode |= 0x02;
                    /* set sample rate divider */
                    fs = fei.basesamplerate / (1 << sample_rate_div);
                    fei.currentsampleratesetting = (short) sample_rate_div;
                    /* send it */
                    tms_write_frontendinfo(fd, fei);
                    /* receive ack */
                    br = tms_rcv_msg(fd, resp, resp.length);
                    break;
                case 2:
						  System.err.println("State=2");
                    /* receive ID Data */
                    br = tms_fetch_iddata(fd, resp, resp.length);
                    break;
                case 3: {
						  System.err.println("State=3");						  
                    try {
                        /* send vldelta info request */
                        bw = tms_snd_vldelta_info_request(fd.getOutputStream());
                    } catch (IOException ex) {
                        Logger.getLogger(tmsi.class.getName()).log(Level.SEVERE, null, ex);
                    }
                }
                /* receive response to vldelta info request */
                br = tms_rcv_msg(fd, resp, resp.length);
                break;
            }

            if ((vb & 0x01) != 0) {
                fpl.format("# State %d\n", state);
            }
            /* process response */
            if (br < 0) {
                System.err.format("# Error: no valid response in state %d\n", state);
                continue;
            }

            /* check checksum and get type of response */
            if (tms_chk_msg(resp, br) != 0) {
                System.err.println("# checksum error !!!\n");
            } else {

                type = tms_get_type(resp, br);

                switch (type) {

                    case TMSVLDELTADATA:
                    case TMSCHANNELDATA:
                    case TMSRTCTIMEDATA:
                        break;
                    case TMSVLDELTAINFO:
                        byte[] tempRef_resp = resp;
                        tms_get_vldelta_info(tempRef_resp, br, in_dev.NrOfChannels, vld);
                        resp = tempRef_resp;
                        if ((vb & 0x02) != 0) {
                            tms_prt_vldelta_info(fpl, vld, 0, 0);
                        }
                        state++;
                        break;

                    case TMSACKNOWLEDGE:
                        tms_get_ack(resp, br, ack);
                        if ((vb & 0x02) != 0) {
                            tms_prt_ack(fpl, ack);
                        }
                        state++;
                        break;

                    case TMSIDDATA:
                        tms_get_iddata(resp, br, in_dev);
                        if ((vb & 0x02) != 0) {
                            tms_prt_iddata(fpl, in_dev);
                        }
                        state++;
                        break;

                    case TMSFRONTENDINFO:
                        /* decode packet to struct */
                        tms_get_frontendinfo(resp, br, fei);
                        if ((vb & 0x02) != 0) {
                            tms_prt_frontendinfo(fpl, fei, 0, 0);
                        }
                        state++;
                        break;
                    default:
                        System.err.format("# don't understand type %02X\n", type);
                        break;
                }
            }
        }
        return 0;
    }

    /**
     * Get elapsed time [s] of this TMS_CHANNEL_DATA_T 'channel'.
     *
     * @return -1 of failure, elapsed seconds in success.
     */
    public static double tms_elapsed_time(TMS_CHANNEL_DATA_T[] channel) {

        if (channel == null) {
            return (-1.0);
        }
        /* elapsed time = previous sample counter * tick duration */
        return (channel[0].sc * channel[0].td);
    }
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public static int tms_get_samples_dpc = 0;
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public static double tms_get_samples_tka;
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public static double tms_get_samples_datastarttime;
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public static int tms_get_samples_pzaag = 62;
//C++ TO JAVA CONVERTER NOTE: This was formerly a static local variable declaration (not allowed in Java):
    public static int tms_get_samples_tzerr = 0;

    /**
     * Get one or more samples for all channels
     *
     * @note all samples are returned via 'channel'
     * @return total number of samples in 'channel'
     */
    public int tms_get_samples(TMS_CHANNEL_DATA_T[] channel) {
        int br = 0; //*< bytes read
        byte[] resp = new byte[RESPSIZE]; //*< TMS response to challenge
        int type; //*< TMS message type
        //C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
        //  static int dpc=0; //*< data packet counter
        double t; //*< current time
        //C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
        //  static double tka; //*< keep-alive time
        //C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
        //  static double datastarttime; //*< time we started receiving data
        //C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
        //  static int pzaag=62; //*< previous zaag value
        int zaag; //*< current zaag value
        int zaagincrement; //*< amount by which zaag increases between samples
        //C++ TO JAVA CONVERTER NOTE: This static local variable declaration (not allowed in Java) has been moved just prior to the method:
        //  static int tzerr=0; //*< total zaag error counter
        int zerr = 0; //*< zaag error value
        int cnt = 0; //*< sample counter
        TMS_ACKNOWLEDGE_T ack = new TMS_ACKNOWLEDGE_T(); //*< TMS acknowlegde
        int zaagch = ZAAGCH; //*< sawtooth channel
        if (tms_get_number_of_channels() > zaagch) { // BODGE: assume ZAAG is last channel
            zaagch = tms_get_number_of_channels() - 1;
        }

        if (state < 4 || state > 5) {
            return -1;
        }
        if (state == 4) {
            /* switch to data capture */
            //fei->mode=0x02; /* send data, no storage */
            fei.mode = (short) (fei.mode & (~0x01)); // turn on data sending -- by setting bit 0 -> low (0), no storage
			/* start data capturing */
            tms_write_frontendinfo(fd, fei);
            /* receive ack */
            br = tms_rcv_msg(fd, resp, resp.length);
            type = tms_get_type(resp, br);
            if (type != TMSACKNOWLEDGE) {
                return -1;
            } else {
                tms_get_ack(resp, br, ack);
                if ((vb & 0x02) != 0) {
                    tms_prt_ack(fpl, ack);
                }
                state++;
            }
        }
        if (state == 5) {
            br = tms_rcv_msg(fd, resp, resp.length);
            if (tms_chk_msg(resp, br) != 0) {
                System.err.println("# checksum error !!!\n");
            } else {

                type = tms_get_type(resp, br);

                switch (type) {

                    case TMSVLDELTADATA:
                    case TMSCHANNELDATA:
                        /* get current time */
                        t = get_time();
                        /* first sample */
                        if (tms_get_samples_dpc == 0) {
                            /* start keep alive timer */
                            tms_get_samples_tka = t;
                            tms_get_samples_datastarttime = t;
                        }
                        /* convert channel data to float's */
                        byte[] tempRef_resp = resp;
                        cnt = tms_get_data(tempRef_resp, br, in_dev, channel);
                        resp = tempRef_resp;
                        if ((vb & 0x04) != 0) {
                            /* print wanted channels !!! */
                            tms_prt_channel_data(System.err, in_dev, channel, 1);
                        }
                        /* check zaag !!! */
                        zaagincrement = 2 << (fei.currentsampleratesetting); // check for reduced sample rate
                        zaag = channel[zaagch].data[0].isample;
                        if (tms_get_samples_dpc > 0 && (zaag - tms_get_samples_pzaag + 64) % 64 > zaagincrement) {
                            System.err.format("%fs # Zaag: %d PZaag: %d\n", t - tms_get_samples_datastarttime, (zaag + 64) % 64, (tms_get_samples_pzaag + 64) % 64);
                            /* correct data packet counter with saw jump */
                            /* !!! 5 bits for saw is too small -> firmware fix in Mobi-8 */
                            /*dpc+=((zaag-pzaag+62) % 64)/zaagincrement; */
                            /* saw error */
                            zerr = 1;
                            tms_get_samples_tzerr++;
                        }
                        tms_get_samples_pzaag = zaag;

                        /* check if keep alive is needed */
                        if (t - tms_get_samples_tka > 60.0) {
                            //tms_snd_keepalive(fd);
                            tms_get_samples_tka = t;
                        }
                        /* increment data packet counter */
                        tms_get_samples_dpc++;
                        break;
                    case TMSACKNOWLEDGE:
                        break;
                    default:
                        System.err.format("Unrecognised packet type: %d\n", type);
                        break;
                }
            }
        }

        /* report zaag errors */
        if (zerr > 0) {
            System.err.format("# %d zaag errors\n", tms_get_samples_tzerr);
        }
        return (cnt);
    }

    /**
     * shutdown sample capturing.
     *
     * @return 0 always.
     */
    public int tms_shutdown() {
        int br = 0; //*< bytes read
        byte[] resp = new byte[RESPSIZE]; //*< TMS response to challenge
        int type; //*< TMS message type
        int got_ack = 0;
        int rtc = 0;
        //TODO

        if (fd == null) {
            /* no connection made yet! */
            return (state);
        }

        /* stop capturing data */
        fei.mode = 0x01;
        tms_write_frontendinfo(fd, fei);

        /* wait for ack is received OR until 10s timeout */
        System.err.println("Wait ACK:");
        do {
            br = tms_rcv_msg(fd, resp, resp.length);
            if (tms_chk_msg(resp, br) != 0) {
                System.err.println("# checksum error !!!\n");
            } else {
                type = tms_get_type(resp, br);
                if (type == TMSACKNOWLEDGE) {
                    got_ack = 1;
                }
            }
            //System.err.println(".");
            rtc++;
        } while (got_ack == 0 && rtc < 1000);

        state = 0;
        /* close socket */
        /*System.out.println(stderr,"5");*/
        tms_close_port(fd);
        /* System.out.println(stderr,"6"); */
        return (state);
    }
}
