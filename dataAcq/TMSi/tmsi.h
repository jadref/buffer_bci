#include <stdint.h>

#ifndef NEXUS_H
#define NEXUS_H

#define DEFAULTPORT 4242 /**< default port number for the frontend server >**/
#define ZAAGCH 13 /**< default channels for sawtooth signal >**/

#define MNCN  (1024)  /**< maximum characters in filename */


#define TMSACKNOWLEDGE      (0x00)
#define TMSCHANNELDATA      (0x01)
#define TMSFRONTENDINFOREQ  (0x03)
#define TMSRTCREADREQ       (0x06) 
#define TMSRTCDATA          (0x07) 
#define TMSRTCTIMEREADREQ   (0x1E) 
#define TMSRTCTIMEDATA      (0x1F) 
#define TMSFRONTENDINFO     (0x02)
#define TMSKEEPALIVEREQ     (0x27)
#define TMSVLDELTADATA      (0x2F)
#define TMSVLDELTAINFOREQ   (0x30) 
#define TMSVLDELTAINFO      (0x31)
#define TMSIDREADREQ        (0x22)
#define TMSIDDATA           (0x23)

#define TMSCFGSIZE          (1024)

typedef struct TMS_ACKNOWLEDGE_T {
   uint16_t descriptor;    
     // received blockdescriptor (type+size) being acknowledged
   uint16_t errorcode;
     //   numbers 0x0000 - 0x0010 are reserved for system errors
     // 0x00 - no error, positive acknowledge
     // 0x01 - unknown or not implemented blocktype
     // 0x02 - CRC error in received block
     // 0x03 - error in command data (can't do that)
     // 0x04 - wrong blocksize (too large)
     //   numbers 0x0010 - 0xFFFF are reserved for user errors
     // 0x11 - No external power supplied
     // 0x12 - Not possible because the Front is recording
     // 0x13 - Storage medium is busy
     // 0x14 - Flash memory not present
     // 0x15 - nr of words to read from flash memory out of range
     // 0x16 - flash memory is write protected
     // 0x17 - incorrect value for initial inflation pressure
     // 0x18 - wrong size or values in BP cycle list
     // 0x19 - sample frequency divider out of range (<0, >max)
     // 0x1A - wrong nr of user channels (<=0, >maxUSRchan)
     // 0x1B - adress flash memory out of range
     // 0x1C - Erasing not possible because battery low 
} tms_acknowledge_t, *ptms_acknowledge_t;


/** Frontend system info struct */
typedef struct TMS_FRONTENDINFO_T {
  uint16_t nrofuserchannels;  // nr of channels set by host (<=nrofswchannels and >0)
                              // first 'nrofuserchannels' channels of system
                              //  will be sent by frontend (only when supported by frontend software!)
  uint16_t currentsampleratesetting;
    // When imp.mode, then only effect when stopping the impedance mode (changing to other mode)
    // 0 = base sample rate (when supported by hardware)
    // 1 = base sample rate /2 (when supported by hardware)
    // 2 = base sample rate /4 (when supported by hardware)
    // 3 = base sample rate /8 (when supported by hardware)
    // 4 = base sample rate /16 (when supported by hardware)
  uint16_t mode;
    // bit 0.. 7 is status bits active low
    // bit 8..15 is mask bits active low
    // bit 0 = datamode    0 = normal, Channel data send enabled
    //                     1 = nodata, Channel data send disabled
    // bit 1 = storagemode 0 = storage on  (only if supported by frontend hardware/software)
    //                     1 = storage off
	 // last 13 uint16_t have valid values only from frontend to PC
  uint16_t maxRS232;         	// Maximum RS232 send frequentie in Hz
  uint32_t serialnumber;      // System serial number, low uint16_t first
  uint16_t nrEXG;             // nr of EXG (unipolar) channels
  uint16_t nrAUX;             // nr of BIP and AUX channels
  uint16_t hwversion;        	// frontend hardware version number
                          	  // hundreds is major part, ones is minor
  uint16_t swversion;        	// frontend software version number
                          	  // hundreds is major part, ones is minor
  uint16_t cmdbufsize;       	// number of uint16_ts in frontend receive buffer
  uint16_t sendbufsize;      	// number of uint16_ts in frontend send buffer
  uint16_t nrofswchannels;   	// total nr of channels in frontend
  uint16_t basesamplerate;    // base sample frequency (in Hz)
  // power and  hardwarecheck not implemented yet, for future use, send 0xFFFF
  uint16_t power; 
    //bit 0 - line power detected
    //bit 1 - battery detected
    //bit 2 - RTC battery detected
    //bit 3 - line power low
    //bit 4 - battery low
    //bit 5 - RTC battery low
  uint16_t hardwarecheck;
    //bit 0 vext_error   = 0x0001   'POSTcode'
    //bit 1 vbat_error   = 0x0002    P ower
    //bit 2 vRTC_error   = 0x0004     O n
    //bit 3 BPM_error    = 0x0008      S elf
    //bit 4 UART_error   = 0x0010       T est
    //bit 5 ADC_error    = 0x0020        code
    //bit 6 PCM_error    = 0x0040
    //bit 7 extmem_error = 0x0080
} tms_frontendinfo_t, *ptms_frontendinfo_t;

#define TMSFRONTENDINFOSIZE (sizeof(tms_frontendinfo_t))


typedef struct TMS_IDREADREQ_T {
  uint16_t startaddress;		// start adress in de buffer with ID data;
				                    // 4 MSB bits Device number
  uint16_t length;		      // amount of words requested;
				                    // length <= max_length = 0x80 = 128 words
} tms_idreadreq_t, *ptms_idreadreq_t;


typedef struct TMS_TYPE_DESC_T {
  uint16_t Size;	  // Size in words of this structure 
  uint16_t Type;	  // Channel type id code
			  //	0 UNKNOWN
				//	1 EXG
				//	2 BIP
				//	3 AUX
				//	4 DIG
				//	5 TIME
				//	6 LEAK
			  //	7 PRESSURE
				//	8 ENVELOPE
				//	9 MARKER
				//	10 ZAAG
				//	11 SAO2
  uint16_t SubType;			// Channel subtype	
        // (+256: unipolar reference, +512: impedance reference)
				//	.0 Unknown
				//	.1 EEG
				//	.2 EMG
				//	.3 ECG
				//	.4 EOG
				//	.5 EAG
				//	.6 EGG
				//	.257 EEGREF	(for specific unipolar reference)
				//	.10 resp
				//	.11 flow
				//	.12 snore
				//	.13 position
				//	.522 resp/impref (impedance reference)
				//	.20 SaO2
				//	.21 plethysmogram
				//	.22 heartrate
				//	.23 sensor status
				//	.30 PVES
				//	.31 PURA
				//	.32 PABD
				//	.33 PDET
  uint16_t Format;			// Format id
				//	0x00xx xbit unsigned
				//	0x01xx xbit signed
				// examples:
				//	0x0001 1bit unsigned
				//	0x0101 1bit signed
				//	0x0002 2bit unsigned
				//	0x0102 2bit signed
				//	0x0008 8bit unsigned
				//	0x0108 8bit signed
  float a;			 	// Information for converting bits to units:
  float b;			 	// Unit  = a * Bits  + b ; 
  uint8_t UnitId;	// Id identifying the units
			  //	0 bit (no unit) (do not use with front6)
				//	1 Volt
				//	2 %
				//	3 Bpm
				//	4 Bar
				//	5 Psi
				//	6 mH2O
				//	7 mHg
				//	8 bit
  int8_t Exp;	// Unit exponent, 3 for Kilo, -6 for micro, etc.
} tms_type_desc_t, *ptms_type_desc_t; 


typedef struct TMS_CHANNEL_DESC_T {
    tms_type_desc_t Type;		   // channel type descriptor 
    char *ChannelDescription;	 // String pointer identifying the channel
    float	GainCorrection;		   // Optional gain correction 
    float	OffsetCorrection;		 // Optional offset correction 
} tms_channel_desc_t, *ptms_channel_desc_t;	 // Size = 6 words


typedef struct TMS_INPUT_DEVICE_T {
  uint16_t Size;         // Size of this structure in words (device not present: send 2)
  uint16_t Totalsize;    // Total size ID data from this device in words (device not present: send 2)
  uint32_t SerialNumber; // Serial number of this input device 
  uint16_t Id;           // Device ID 
  char    *DeviceDescription;	      // String pointer identifying the device 
  uint16_t NrOfChannels;		        // Number of channels of this input device 
  uint16_t DataPacketSize;	        // Size simple PCM data packet over all channels
  tms_channel_desc_t *Channel;        // Pointer to all channel descriptions
} tms_input_device_t, *ptms_input_device_t;  

typedef struct TMS_VLDELTA_INFO_T {
  uint16_t Config;         // Config&0x0001 -> 0: original VLDelta encoding 1: Huffman
                           // Config&0x0100 -> 0: same 1: different
  uint16_t Length;         // Size [bits] of the length block before a delta sample
  uint16_t TransFreqDiv;   // Transmission frequency divisor Transfreq = MainSampFreq / TransFreqDiv
  uint16_t NrOfChannels;   
  uint16_t *SampDiv;       // Real sample frequence divisor per channel
} tms_vldelta_info_t, *ptms_vldelta_info_t;   

typedef struct TMS_DATA_T {
  float   sample;    /**< real sample value */
  int32_t isample;   /**< integer representation of sample */
  int32_t flag;      /**< sample status: 0x00: ok 0x01: overflow */
} tms_data_t, *ptms_data_t;   

typedef struct TMS_CHANNEL_DATA_T {
  int32_t      ns;   /**< number of samples in 'data' */
  int32_t      rs;   /**< already received samples in 'data' */
  int32_t      sc;   /**< sample counter */
  double       td;   /**< tick duration [s] */
  tms_data_t *data;  /**< data samples */
} tms_channel_data_t, *ptms_channel_data_t;   

typedef struct TMS_RTC_T {
  uint16_t seconds;      
  uint16_t minutes;    
  uint16_t hours;    
  uint16_t day;    
  uint16_t month;    
  uint16_t year;    
  uint16_t century;    
  uint16_t weekday;    // Sunday = 1
} tms_rtc_t, *ptms_rtc_t;  

/** TMS storage type struct */
typedef struct TMS_STORAGE_T {
  int8_t  ref;       /**< reference channel nr. 0...63 and -1 none */
  int8_t  deci;      /**< decimation 0,1,3,7,15,63,127 or 255 */
  int8_t  delta;     /**< delta 0:no storage 1: 8 bit delta 2: 16 bit delta 3: 24 bit data */
  int8_t  shift;     /**< shift delta==3 -> 0, delta==2 -> 0..6, delta==1 -> 0..14 */
  int32_t period;    /**< sample period */
  int32_t overflow;  /**< overflow value */
} tms_storage_t, *ptms_storage_t;

/** TMS config struct */
typedef struct TMS_CONFIG_T {
  int16_t version;       /**< PC Card protocol version number 0x0314 */
  int16_t hdrSize;       /**< size of measurement header 0x0200 */
  int16_t fileType;      /**< File Type (0: .ini 1: .smp 2:evt) */
  int32_t cfgSize;       /**< size of config.ini  0x400         */
  int16_t sampleRate;    /**< File Type (0: .ini 1: .smp 2:evt) */
  int16_t nrOfChannels;  /**< number of channels */
  int32_t startCtl;      /**< start control       */
  int32_t endCtl;        /**< end control       */
  int16_t cardStatus;    /**< card status */
  int32_t initId;        /**< Initialisation Identifier */
  int16_t sampleRateDiv; /**< Sample Rate Divider */
  int16_t mindecimation; /**< Minimum Decimantion of all channels */
  tms_storage_t storageType[64]; /**< Storage Type */
  uint8_t fileName[12];  /**< Measurement file name */
  time_t  alarmTime;     /**< alarm time */
  uint8_t info[700];     /**< patient of measurement info */
} tms_config_t, *ptms_config_t;
 
/** TMS measurement header struct */
typedef struct TMS_MEASUREMENT_HDR_T {
  int32_t nsamples;         /**< number of samples in this recording */
  time_t  startTime;        /**< start time */
  time_t  endTime;          /**< end time */
  int32_t frontendSerialNr; /**< frontendSerial Number */
  int16_t frontendHWNr;     /**< frontend Hardware version Number */
  int16_t frontendSWNr;     /**< frontend Software version Number */
} tms_measurement_hdr_t, *ptms_measurement_hdr_t;

/** set verbose level of module TMS to 'new_vb'.
 * @return old verbose value
*/
int32_t tms_set_vb(int32_t new_vb);

/** get verbose variable for module TMS
 * @return current verbose level
*/
int32_t tms_get_vb();

/** Get integer of 'n' bytes from byte array 'msg' starting at position 's'.
 * @note n<=4 to avoid bit loss
 * @note on return start position 's' is incremented with 'n'.
 * @return integer value.
 */
int32_t tms_get_int(uint8_t *msg, int32_t *s, int32_t n);

/** Get current time in [sec] since 1970-01-01 00:00:00.
 * @note current time has micro-seconds resolution.
 * @return current time in [sec].
*/
double get_time();

/** Open bluetooth device 'fname' to TMSi aquisition device
  *  Nexus-10 or Mobi-8.
  * @return socket >0 on success.
*/
int32_t tms_open_port(char *fname);

/** Close file descriptor 'fd'.
 * @return 0 on successm, errno on failure.
*/
int32_t tms_close_port(int32_t fd);

/** General check of TMS message 'msg' of 'n' bytes.
 * @return 0 on correct checksum, 1 on failure.
*/
int32_t tms_chk_msg(uint8_t *msg, int32_t n);

/** Check checksum buffer 'msg' of 'n' bytes.
 * @return packet type.
*/
int16_t tms_get_type(uint8_t *msg, int32_t n);

/** Read at max 'n' bytes of TMS message 'msg' for 
 *   bluetooth device descriptor 'fd'.
 * @return number of bytes read.
*/
int32_t tms_rcv_msg(int fd, uint8_t *msg, int32_t n);

/** Convert buffer 'msg' of 'n' bytes into tms_acknowledge_t 'ack'.
 * @return >0 on failure and 0 on success 
*/
int32_t tms_get_ack(uint8_t *msg, int32_t n, tms_acknowledge_t *ack);

/** Print tms_acknowledge_t 'ack' to file 'fp'.
 *  @return number of printed characters.
*/
int32_t tms_prt_ack(FILE *fp, tms_acknowledge_t *ack);

/** Send frontend Info request to 'fd'.
 *  @return bytes send.
*/
int32_t tms_snd_FrontendInfoReq(int32_t fd);

/** Write frontendinfo_t 'fei' into socket 'fd'.
 * @return number of bytes written (<0: failure)
*/
int32_t tms_write_frontendinfo(int32_t fd, tms_frontendinfo_t *fei);

/** Convert buffer 'msg' of 'n' bytes into frontendinfo_t 'fei'
 * @note 'b' needs size of TMSFRONTENDINFOSIZE
 * @return -1 on failure and on succes number of frontendinfo structs
*/
int32_t tms_get_frontendinfo(uint8_t *msg, int32_t n, tms_frontendinfo_t *fei);


/** Return the cached FEI structure
 * @return -1 on failure and on succes number of frontendinfo structs
*/
const tms_frontendinfo_t* tms_get_fei();

/** Print tms_frontendinfo_t 'fei' to file 'fp'.
 *  @return number of printed characters.
*/
int32_t tms_prt_frontendinfo(FILE *fp, tms_frontendinfo_t *fei, int nr, int hdr);

int32_t tms_fetch_iddata(int32_t fd, uint8_t *msg, int32_t n);
int32_t tms_get_iddata(uint8_t *msg, int32_t n, tms_input_device_t *inpdev);
int32_t tms_get_input_device(uint8_t *msg, int32_t n, int32_t start, tms_input_device_t *inpdev);
int32_t tms_prt_iddata(FILE *fp, tms_input_device_t *inpdev);

/** Get the cached input-device
 *
 */
const tms_input_device_t* tms_get_in_dev();

/** Construct channel data block with frontend info 'fei' and
 *   input device 'dev' with eventually vldelta_info 'vld'.
 * @return pointer to channel_data_t struct, NULL on failure.
*/
tms_channel_data_t *tms_alloc_channel_data();

/** Print channel data block 'chd' of tms device 'dev' to file 'fp'.
 * @param print switch md 0: integer  1: float values
 * @return number of printed characters.
*/
int32_t tms_prt_channel_data(FILE *fp, tms_input_device_t *dev, tms_channel_data_t *chd, int32_t md);

/** Get TMS data from message 'msg' of 'n' bytes into floats 'val'.
 * @return number of samples.
*/
int32_t tms_get_data(uint8_t *msg, int32_t n, tms_input_device_t *dev, 
		     tms_channel_data_t *chd);

/** Print TMS channel data 'chd' to file 'fp'.
 * @param md: print switch 0: float 1: integer values
 * @param cs: channel selector A: 0x01 B: 0x02 C: 0x04 ...
 * @return number of characters printed.
 */
int32_t tms_prt_samples(FILE *fp, tms_channel_data_t *chd, int32_t cs, int32_t md);

/** Send VLDeltaInfo request to file descriptor 'fd'
*/
int32_t tms_snd_vldelta_info_request(int32_t fd);

/** Convert buffer 'msg' of 'n' bytes into tms_vldelta_info_t 'vld' for 'nch' channels.
 * @return number of bytes processed.
*/
int32_t tms_get_vldelta_info(uint8_t *msg, int32_t n, int32_t nch, tms_vldelta_info_t *vld);

/** Print tms_rtc_t 'rtc' to file 'fp'.
 *  @return number of printed characters.
*/
int32_t tms_prt_vldelta_info(FILE *fp, tms_vldelta_info_t *vld, int nr, int hdr);

/** Send keepalive request to 'fd'.
 *  @return bytes send.
*/
int32_t tms_snd_keepalive(int32_t fd);

/** Send Real Time Clock (RTC) read request to file descriptor 'fd'
*  @return number of bytes send.
*/
int32_t tms_send_rtc_time_read_req(int32_t fd);

/** Convert buffer 'msg' of 'n' bytes into tms_rtc_t 'rtc'
 * @return 0 on failure and number of bytes processed
*/
int32_t tms_get_rtc(uint8_t *msg, int32_t n, tms_rtc_t *rtc);

/** Print tms_rtc_t 'rtc' to file 'fp'.
 *  @return number of printed characters.
*/
int32_t tms_prt_rtc(FILE *fp, tms_rtc_t *rtc, int nr, int hdr);

/** Open TMS log file with name 'fname' and mode 'md'.
 * @return file pointer.
*/
FILE *tms_open_log(char *fname, char *md);

/** Close TMS log file
 * @return 0 in success.
*/
int32_t tms_close_log();


/** Log TMS buffer 'msg' of 'n' bytes to log file.
 * @return return number of printed characters.
*/
int32_t tms_write_log_msg(uint8_t *msg, int32_t n, char *comment);

/** Read TMS log number 'nr' into buffer 'msg' of maximum 'n' bytes from log file.
 * @return return length of message.
*/
int32_t tms_read_log_msg(uint32_t nr, uint8_t *msg, int32_t n);

/** Grep 'n' bits signed long integer from byte buffer 'buf' 
 *  @return 'n' bits signed integer
 */
int32_t get_int32_t(uint8_t *buf, int32_t *bip, int32_t n);


/*********************************************************************/
/* Functions for reading the data from the SD flash cards            */
/*********************************************************************/

/** Get 16 bytes TMS date for 'msg' starting at position 'i'.
 * @note position after parsing in returned in 'i'.
 * @return 0 on success, -1 on failure.
*/
int32_t tms_get_date(uint8_t *msg, int32_t *i, time_t *t);

/** Put time_t 't' as 16 bytes TMS date into 'msg' starting at position 'i'.
 * @note position after parsing in returned in 'i'.
 * @return 0 always.
*/
int32_t tms_put_date(time_t *t, uint8_t *msg, int32_t *i);

/** Convert buffer 'msg' starting at position 'i' into tms_config_t 'cfg'
 * @note new position byte will be return in 'i'
 * @return number of bytes parsed
 */
int32_t tms_get_cfg(uint8_t *msg, int32_t *i, tms_config_t *cfg);

/** Put tms_config_t 'cfg' into buffer 'msg' starting at position 'i'
 * @note new position byte will be return in 'i'
 * @return number of bytes put
 */
int32_t tms_put_cfg(uint8_t *msg, int32_t *i, tms_config_t *cfg);

/** Print tms_config_t 'cfg' to file 'fp'
 * @param prt_info !=0 -> print measurement/patient info
 * @return number of characters printed.
 */
int32_t tms_prt_cfg(FILE *fp, tms_config_t *cfg, int32_t prt_info);

/** Read tms_config_t 'cfg' from file 'fp'
 * @return number of characters printed.
 */
int32_t tms_rd_cfg(FILE *fp, tms_config_t *cfg);

/** Convert buffer 'msg' starting at position 'i' into tms_measurement_hdr_t 'hdr'
 * @note new position byte will be return in 'i'
 * @return number of bytes parsed
 */
int32_t tms_get_measurement_hdr(uint8_t *msg, int32_t *i, tms_measurement_hdr_t *hdr);

/** Print tms_config_t 'cfg' to file 'fp'
 * @param prt_info 0x01 print measurement/patient info
 * @return number of characters printed.
 */
int32_t tms_prt_measurement_hdr(FILE *fp, tms_measurement_hdr_t *hdr);



/*********************************************************************/
/* Functions for bluetooth connection                                */
/*********************************************************************/

/** Initialize TMSi device with Bluetooth address 'fname' and
 *   sample rate divider 'sample_rate_div'.
 * @note no timeout implemented yet.
 * @return always 0
*/
int32_t tms_init(char *fname, int32_t sample_rate_div);

/** Get elapsed time [s] of this tms_channel_data_t 'channel'.
* @return -1 of failure, elapsed seconds in success.
*/
double tms_elapsed_time(tms_channel_data_t *channel);

/** Get one or more samples for all channels
*  @note all samples are returned via 'channel'
* @return total number of samples in 'channel'
*/
int32_t tms_get_samples(tms_channel_data_t *channel);

/** Get the number of channels of this TMSi device
 * @return number of channels
*/
int32_t tms_get_number_of_channels();

/* Get the current sample frequency.
* @return current sample frequency [Hz]
*/
double tms_get_sample_freq();

/** shutdown sample capturing.
 *  @return 0 always.
*/
int32_t tms_shutdown();

#endif
