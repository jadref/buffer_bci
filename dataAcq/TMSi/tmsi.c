#include <stdio.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <sys/time.h>
#include <math.h>
#include <stdint.h>
#include <errno.h>
#include <time.h>


#if defined(__WIN32__) || defined(__WIN64__)
 #include <winsock2.h>
#else
 #include <sys/ioctl.h>
 #include <sys/socket.h>
 #include <termios.h>
 /** for the tcp connection **/
 #include <netinet/in.h>
 #include <netdb.h> 
#endif

/* disable NAGLE packet merging algorithm, which can delay small
	packets by up to 30ms! */
#ifdef DISABLE_NAGLE
 #include <netinet/tcp.h>
#endif

#ifdef BLUETOOTH
 #include <bluetooth/bluetooth.h>
 #include <bluetooth/rfcomm.h>
#endif

#include "tmsi.h"

#define VERSION "$Revision: 0.1 $"

#define TMSBLOCKSYNC (0xAAAA)    /**< TMS block sync word */

#define RESPSIZE 2048 /* max size of the response message */

static int32_t  vb=0x0000; /**< verbose level */
static FILE   *fpl=NULL;          /**< log file pointer */

static tms_frontendinfo_t *fei=NULL;        /**< storage for all frontend info structs */
static tms_vldelta_info_t *vld=NULL;
static tms_input_device_t *in_dev=NULL;     /**< TMSi input device */

/** set verbose level of module TMS to 'new_vb'.
 * @return old verbose value
*/
int32_t tms_set_vb(int32_t new_vb) {

  int32_t old_vb=vb;

  vb=new_vb;
  return(old_vb);
}
 
/** get verbose variable for module TMS
 * @return current verbose level
*/
int32_t tms_get_vb() {
  return(vb);
}

// A uint32_t send from PC to the front end: first low uint16_t, second high uint16_t
// A uint32_t send from front end to the PC: first low uint16_t, second high uint16_t
// EXCEPTION: channeldata samples are transmitted as first high uint16_t, second low uint16_t
// When transmitted as bytes (serial interface): first low-byte, then hi-byte


/** Get current time in [sec] since 1970-01-01 00:00:00.
 * @note current time has micro-seconds resolution.
 * @return current time in [sec].
*/
double get_time() {

  struct timeval tv;   /**< time value */
  //struct timezone tz;  /**< time zone NOT used under linux */
  double ts=0.0;       /**< default time [s] */

  if (gettimeofday(&tv,NULL)!=0) {
    fprintf(stderr,"time_us: Error in gettimeofday\n");
    return(ts);
  }
  ts=1e-6*tv.tv_usec + tv.tv_sec;
  return(ts);
}


/** Get integer of 'n' bytes from byte array 'msg' starting at position 's'.
 * @note n<=4 to avoid bit loss
 * @note on return start position 's' is incremented with 'n'.
 * @return integer value.
 */
int32_t tms_get_int(uint8_t *msg, int32_t *s, int32_t n) {

  int32_t i;   /**< general index */
  int32_t b=0; /**< temp result */
  
  /* skip overflow bytes */
  if (n>4) { n=4; }
  /* get MSB byte first */
  for (i=n-1; i>=0; i--) {
    b=(b<<8) | (msg[(*s)+i] & 0xFF);
  }
  /* increment start position 's' */
  (*s)+=n;
  return(b);
}

/** Put 'n' LSB bytes of 'a' into byte array 'msg' 
 *   starting at location 's'.
 * @note n<=4.
 * @note start location is incremented at return.
 * @return number of bytes put.
 */
int32_t tms_put_int(int32_t a, uint8_t *msg, int32_t *s, int32_t n) {

  int32_t i=0;

  if (n>4) { n=4; }

  for (i=0; i<n; i++) {
    msg[(*s)+i]=(uint8_t)(a & 0xFF);
    a=(a>>8);
  }
  /* increment start location */
  (*s)+=n;
  /* return number of byte processed */
  return(n);
}

/* byte reverse */
uint8_t tms_byte_reverse(uint8_t a) {

 uint8_t b=0;
 int32_t i;

 for (i=0; i<8; i++) { 
   b=(b<<1) | (a & 0x01); a=a>>1;
 }
 return b; 
}

/** Grep 'n' bits signed long integer from byte buffer 'buf'
 *  @note most significant byte first. 
 *  @return 'n' bits signed integer
 */
int32_t get_int32_t(uint8_t *buf, int32_t *bip, int32_t n) {

  int32_t i=*bip;   /**< start location */
  int32_t a=0;      /**< wanted integer value */
  int32_t mb;       /**< maximum usefull bits in 'byte[i/8]' */
  int32_t wb;       /**< number of wanted bits in current byte 'buf[i/8]' */

  while (n>0) {
    /* calculate number of usefull bits in this byte */
    mb=8-(i%8);
    /* select maximum needed number of bits */
    if (n>mb) { wb=mb; } else { wb=n; }
    /* grep 'wb' bits out of byte 'buf[i/8]' */
    a=(a<<wb) | ((buf[i/8]>>(mb-wb)) & ((1<<wb)-1));
    /* decrement number of needed bits, and increment bit index */
    n-=wb; i+=wb;
  }

  /* put back resulting bit position */
  (*bip)=i; 
  return(a);
}

/** Grep 'n' bits signed long integer from byte buffer 'buf' 
 *  @note least significant byte first. 
 *  @return 'n' bits signed integer
 */
int32_t get_lsbf_int32_t(uint8_t *buf, int32_t *bip, int32_t n) {

  int32_t i=*bip;   /**< start location */
  int32_t a=0;      /**< wanted integer value */
  int32_t mb;       /**< maximum usefull bits in 'byte[i/8]' */
  int32_t wb;       /**< number of wanted bits in current byte 'buf[i/8]' */
  int32_t m=0;      /**< number of already written bits in 'a' */

  while (n>0) {
    /* calculate number of usefull bits in this byte */
    mb=8-(i%8);
    /* select maximum needed number of bits */
    if (n>mb) { wb=mb; } else { wb=n; }
    /* grep 'wb' bits out of byte 'buf[i/8]' */
    a|=(((buf[i/8]>>(i%8))&((1<<wb)-1)))<<m; 
    /* decrement number of needed bits, and increment bit index */
    n-=wb; i+=wb; m+=wb;
  }
  /* put back resulting bit position */
  (*bip)=i; 

  return(a);
}

/** Grep 'n' bits sign extented long integer from byte buffer 'buf' 
 *  @note least significant byte first. 
 *  @return 'n' bits signed integer
 */
int32_t get_lsbf_int32_t_sign_ext(uint8_t *buf, int32_t *bip, int32_t n)
{
  int32_t a;

  a = get_lsbf_int32_t(buf,bip,n);
  /* check MSB-1 bits */
  if ((1<<(n-1)&a)==0) {
    /* add heading one bits for negative numbers */
    a= (~((1<<n)-1))|a;
  }
  return(a);
}

/** Get 4 byte long float for 'buf' starting at byte 'sb'.
  * @return float
*/
float tms_get_float(uint8_t *msg, int32_t *sb) {

  float   sign;
  int32_t expi;
  float   mant;
  int32_t manti;
  int32_t bip=0;
  float   a;
  int32_t i;
  uint8_t buf[4];
  
  buf[0]=msg[*sb+3]; 
  buf[1]=msg[*sb+2]; 
  buf[2]=msg[*sb+1]; 
  buf[3]=msg[*sb+0]; 
  
  if ((buf[0]==0) && (buf[1]==0) && (buf[2]==0) && (buf[3]==0)) {
    (*sb)+=4;
    return(0.0);
  }
  /* fetch sign bit */  
  if (get_int32_t(buf,&bip,1)==1) { sign=-1.0; } else { sign=+1.0; }
  /* fetch 8 bits exponent */
  expi=get_int32_t(buf,&bip,8);
  /* fetch 23 bits mantissa */
  manti=(get_int32_t(buf,&bip,23)+(1<<23));
  mant=(float)(manti);
  
  if (vb&0x10) {
    for (i=0; i<4; i++) {
      fprintf(stderr," %02X",buf[i]);
    }
    fprintf(stderr," sign %2.1f expi %6xd manti 0x%06X\n",sign,expi,manti);
    /* print this only once */
    vb=vb & ~0x10;    
  }
  /* construct float */  
  /* f = ((h&0x8000)<<16) | (((h&0x7c00)+0x1C000)<<13) | ((h&0x03FF)<<13).
	  00)<<16) | (((h&0x7c00)+0x1C000)<<13) | ((h&0x03FF)<<13). */

  //a=sign*mant*pow(2.0,(float)(expo-23-127));
  a=ldexpf(sign*mant,expi-23-127); // ldexp should be much faster than pow...
  
  /* 4 bytes float */
  (*sb)+=4;
  /* return found float 'a' */
  return(a);
}

/** Get string starting at position 'start' of message 'msg' of 'n' bytes.
 * @note will malloc storage space for the null terminated string.
 * @return pointer to string or NULL on no success.
*/ 
char *tms_get_string(uint8_t *msg, int32_t n, int32_t start) {

  int32_t size;         /**< string size [byte] */
  int32_t i=start;      /**< general index */
  char    *string=NULL; /**< string pointer */
  
  size=2*(tms_get_int(msg,&i,2)-1);
  if (i+size>n) {
    fprintf(stderr,"# Error: tms_get_string: index 0x%04X out of range 0x%04X\n",i+size,n);
  } else {
    /* malloc space for the string */
    string = malloc(size);
    /* copy content */
    strncpy(string,(char *)&msg[i],size);
  }
  return(string);
}

/** Calculate checksum of message 'msg' of 'n' bytes.
 * @return checksum.
*/
int16_t tms_cal_chksum(uint8_t *msg, int32_t n) {

  int32_t i;                   /**< general index */
  int16_t sum=0x0000;          /**< checksum */
  
  for (i=0; i<(n/2); i++){
    sum += (msg[2*i+1] << 8) + msg[2*i];
  }
  return(sum);
}
 
/** Check checksum buffer 'msg' of 'n' bytes.
 * @return packet type.
*/
int16_t tms_get_type(uint8_t *msg, int32_t n) {

  int16_t rv =(int16_t)msg[3]; /**< packet type */
  
  return(rv);
}
 
/** Get payload size of TMS message 'msg' of 'n' bytes.
 *  @note 'i' will return start byte address of payload.
 *  @return payload size.
*/
int32_t tms_msg_size(uint8_t *msg, int32_t n, int32_t *i) {

  int32_t size=0; /**< payload size */
  
  (*i)=2; /* address location */
  size=tms_get_int(msg,i,1);
  (*i)=4; 
  if (size==0xFF) {
    size=tms_get_int(msg,i,4);
  }
  return(size);
}

/** Open TMS log file with name 'fname' and mode 'md'.
 * @return file pointer.
*/
FILE *tms_open_log(char *fname, char *md) {

  /* open log file */
  if ((fpl=fopen(fname,md))==NULL) {
    perror(fname);
  }
  return(fpl);
}

/** Close TMS log file
 * @return 0 in success.
*/
int32_t tms_close_log() {

  /* close log file */
  if (fpl!=NULL) {
    fclose(fpl);
  }
  return(0);
}

/** Log TMS buffer 'msg' of 'n' bytes to log file.
 * @return return number of printed characters.
*/
int32_t tms_write_log_msg(uint8_t *msg, int32_t n, char *comment) {

  static int32_t nr=0;   /**< message counter */
  int32_t nc=0;          /**< number of characters printed */
  int32_t sync;    /**< sync */
  int32_t type;    /**< type */
  int32_t size;          /**< payload size */
  int32_t pls;           /**< payload start adres */
  int32_t calsum;  /**< calculated checksum */
  int32_t i=0;           /**< general index */
  
  if (fpl==NULL) {
    return(nc);
  }
  i=0;
  sync=tms_get_int(msg,&i,2);
  type=tms_get_type(msg,n);
  size=tms_msg_size(msg,n,&pls);
  calsum=tms_cal_chksum(msg,n);
  nc+=fprintf(fpl,"# %s sync 0x%04X type 0x%02X size 0x%02X checksum 0x%04X\n",comment,sync,type,size,calsum);
  nc+=fprintf(fpl,"#%3s %4s %2s %2s %2s\n","nr","ba","wa","d1","d0");
  i=0;
  while (i<n) {
    nc+=fprintf(fpl," %3d %04X %02X %02X %02X %1c %1c\n",
          nr,(i&0xFFFF),((i-pls)/2)&0xFF,msg[i+1],msg[i],
          ((msg[i+1]>=0x20 && msg[i+1]<=0x7F) ? msg[i+1] : '.'),
          ((msg[i  ]>=0x20 && msg[i  ]<=0x7F) ? msg[i  ] : '.')
         );
    i+=2;
  }
  /* increment message counter */
  nr++;
  return(nc);
}

/** Read TMS log number 'en' into buffer 'msg' of maximum 'n' bytes from log file.
 * @return return length of message.
*/
int32_t tms_read_log_msg(uint32_t en, uint8_t *msg, int32_t n) {

  int32_t br=0;          /**< number of bytes read */
  char line[0x100];      /**< temp line buffer */
  int32_t nr;            /**< log event number */
  int32_t ba;            /**< byte address */
  int32_t wa;            /**< word address */
  int32_t d0,d1;         /**< byte data value */
  int32_t sec=0;         /**< sequence error counter */
  int32_t lc=0;          /**< line counter */
  int32_t ni=0;          /**< number of input arguments */
  
  if (fpl==NULL) {
    return(br);
  }
  /* seek to begin of file */
  fseek(fpl,0,SEEK_SET);
  /* read whole ASCII EEG sample file */ 
  while (!feof(fpl)) {
    /* clear line */
    line[0]='\0';
    /* read one line with hist data */
    fgets(line,sizeof(line)-1,fpl); lc++;
    /* skip comment lines or too small lines */
    if ((line[0]=='#') || (strlen(line)<2)) {
      continue;
    } 
    ni=sscanf(line,"%d %X %X %X %X",&nr,&ba,&wa,&d1,&d0);
    if (ni!=5) {
      if (sec==0) {
        fprintf(stderr,"# Error: tms_read_log_msg : wrong argument count %d on line %d. Skip it\n",ni,lc);
      }
      sec++;
      continue;
    }
    if (ba>=n) {
      fprintf(stderr,"# Error: tms_read_log_msg : size array 'msg' %d too small %d\n",n,nr);
    } else 
    if (en==nr) {
      msg[ba+1]=d1; msg[ba]=d0; br+=2;
    }
  }
  return(br);
}

/*********************************************************************/
/* Functions for reading the data from the SD flash cards            */
/*********************************************************************/

/** Get 16 bytes TMS date for 'msg' starting at position 'i'.
 * @note position after parsing in returned in 'i'.
 * @return 0 on success, -1 on failure.
*/
int32_t tms_get_date(uint8_t *msg, int32_t *i, time_t *t) {
 
  int32_t j;         /**< general index */
  int32_t wrd[8];    /**< TMS date format */
  struct tm cal;     /**< broken calendar time */
  int32_t zeros=0;   /**< zero counter */
  int32_t ffcnt=0;   /**< no value counter */

  for (j=0; j<8; j++) {
    wrd[j]=tms_get_int(msg,i,2); 
    if (wrd[j]==0) { zeros++; }
    if ((wrd[j]&0xFF)==0xFF) { ffcnt++; }
  }
  if (vb&0x01) {
    fprintf(stderr," %02d%02d-%02d-%02d %02d:%02d:%02d\n",
	wrd[0],wrd[1],wrd[2],wrd[3],wrd[5],wrd[6],wrd[7]);
  }
  if ((zeros==8) || (ffcnt>0)) {
    /* by definition 1970-01-01 00:00:00 GMT */
    (*t)=(time_t)0;
    return(-1);
  } else {
    /* year since 1900 */
    cal.tm_year=(wrd[0]*100+wrd[1])-1900;
    /* months since January [0,11] */
    cal.tm_mon =wrd[2]-1;
    /* day of the month [1,31] */
    cal.tm_mday=wrd[3];
    /* hours since midnight [0,23] */
    cal.tm_hour=wrd[5];
    /* minutes since the hour [0,59] */
    cal.tm_min =wrd[6];
    /* seconds since the minute [0,59] */
    cal.tm_sec =wrd[7];
    /* convert to broken calendar to calendar */
    (*t)=mktime(&cal);
    return(0);
  }
}

/** Put time_t 't' as 16 bytes TMS date into 'msg' starting at position 'i'.
 * @note position after parsing in returned in 'i'.
 * @return 0 always.
*/
int32_t tms_put_date(time_t *t, uint8_t *msg, int32_t *i) {
 
  int32_t j;         /**< general index */
  int32_t wrd[8];    /**< TMS date format */
  struct tm cal;     /**< broken calendar time */

  if (*t==(time_t)0) {
    /* all zero for t-zero */
    for (j=0; j<8; j++) {
      wrd[j]=0;
    }
  } else {
    cal=*localtime(t);
    /* year since 1900 */
    wrd[0]=(cal.tm_year+1900)/100;
    wrd[1]=(cal.tm_year+1900)%100;
    /* months since January [0,11] */
    wrd[2]=cal.tm_mon+1;
    /* day of the month [1,31] */
    wrd[3]=cal.tm_mday;
    /* day of the week [0,6] ?? sunday = ? */
    wrd[4]=cal.tm_wday; /** !!! checken */
     /* hours since midnight [0,23] */
    wrd[5]=cal.tm_hour;
    /* minutes since the hour [0,59] */
    wrd[6]=cal.tm_min;
    /* seconds since the minute [0,59] */
    wrd[7]=cal.tm_sec;
  }
  /* put 16 bytes */
  for (j=0; j<8; j++) {
    tms_put_int(wrd[j],msg,i,2); 
  }
  if (vb&0x01) {
    fprintf(stderr," %02d%02d-%02d-%02d %02d:%02d:%02d\n",
	wrd[0],wrd[1],wrd[2],wrd[3],wrd[5],wrd[6],wrd[7]);
  }
  return(0);
}

/** Convert buffer 'msg' starting at position 'i' into tms_config_t 'cfg'
 * @note new position byte will be return in 'i'
 * @return number of bytes parsed
 */
int32_t tms_get_cfg(uint8_t *msg, int32_t *i, tms_config_t *cfg) {

  int32_t i0=*i;    /**< start index */
  int32_t j;        /**< general index */

  cfg->version      =tms_get_int(msg,i,2); /**< PC Card protocol version number 0x0314 */
  cfg->hdrSize      =tms_get_int(msg,i,2); /**< size of measurement header 0x0200 */
  cfg->fileType     =tms_get_int(msg,i,2); /**< File Type (0: .ini 1: .smp 2:evt) */
  (*i)+=2; /**< skip 2 reserved bytes */
  cfg->cfgSize      =tms_get_int(msg,i,4); /**< size of config.ini  0x400         */
  (*i)+=4; /**< skip 4 reserved bytes */
  cfg->sampleRate   =tms_get_int(msg,i,2); /**< sample frequency [Hz] */
  cfg->nrOfChannels =tms_get_int(msg,i,2); /**< number of channels */
  cfg->startCtl     =tms_get_int(msg,i,4); /**< start control       */
  cfg->endCtl       =tms_get_int(msg,i,4); /**< end control       */
  cfg->cardStatus   =tms_get_int(msg,i,2); /**< card status */
  cfg->initId       =tms_get_int(msg,i,4); /**< Initialisation Identifier */
  cfg->sampleRateDiv=tms_get_int(msg,i,2); /**< Sample Rate Divider */
  (*i)+=2; /**< skip 2 reserved bytes */
  for (j=0; j<64; j++) {
    cfg->storageType[j].shift=(int8_t)tms_get_int(msg,i,1); /**< shift */
    cfg->storageType[j].delta=(int8_t)tms_get_int(msg,i,1); /**< delta */
    cfg->storageType[j].deci =(int8_t)tms_get_int(msg,i,1); /**< decimation */
    cfg->storageType[j].ref  =(int8_t)tms_get_int(msg,i,1); /**< ref */
    cfg->storageType[j].period=0;                           /**< sample period */
    cfg->storageType[j].overflow=(0xFFFFFF80)<<(8*(cfg->storageType[j].delta-1)); /**< overflow */
  }
  for (j=0; j<12; j++) {
    cfg->fileName[j]=tms_get_int(msg,i,1); /**< Measurement file name */
  }
  /**< alarm time */
  tms_get_date(msg,i,&cfg->alarmTime);
  (*i)+=2; /**< skip 2 or 4 reserved bytes !!! check it */
  for (j=0; j<sizeof(cfg->info); j++) {
    cfg->info[j]=tms_get_int(msg,i,1);
  }

  /* find minimum decimation */
  cfg->mindecimation=255;
  for (j=0; j<cfg->nrOfChannels; j++) {
    if ((cfg->storageType[j].delta>0) && (cfg->storageType[j].deci<cfg->mindecimation)) {
      cfg->mindecimation=cfg->storageType[j].deci;
    }
  }
  /* calculate channel period */ 
  for (j=0; j<cfg->nrOfChannels; j++) {
    if (cfg->storageType[j].delta>0) {
      cfg->storageType[j].period=(cfg->storageType[j].deci+1)/(1<<cfg->mindecimation);
    }
  }

  return((*i)-i0);
}

/** Put tms_config_t 'cfg' into buffer 'msg' starting at position 'i'
 * @note new position byte will be return in 'i'
 * @return number of bytes put
 */
int32_t tms_put_cfg(uint8_t *msg, int32_t *i, tms_config_t *cfg) {

  int32_t i0=*i;    /**< start index */
  int32_t j;        /**< general index */

  tms_put_int(cfg->version,msg,i,2);  /**< PC Card protocol version number 0x0314 */
  tms_put_int(cfg->hdrSize,msg,i,2);  /**< size of measurement header 0x0200 */
  tms_put_int(cfg->fileType,msg,i,2); /**< File Type (0: .ini 1: .smp 2:evt) */
  tms_put_int(0xFFFF,msg,i,2);        /**< 2 reserved bytes */
  tms_put_int(cfg->cfgSize,msg,i,4);  /**< size of config.ini  0x400         */
  tms_put_int(0xFFFFFFFF,msg,i,4);    /**< 4 reserved bytes */
  tms_put_int(cfg->sampleRate   ,msg,i,2); /**< sample frequency [Hz] */
  tms_put_int(cfg->nrOfChannels ,msg,i,2); /**< number of channels */
  tms_put_int(cfg->startCtl     ,msg,i,4); /**< start control       */
  tms_put_int(cfg->endCtl       ,msg,i,4); /**< end control       */
  tms_put_int(cfg->cardStatus   ,msg,i,2); /**< card status */
  tms_put_int(cfg->initId       ,msg,i,4); /**< Initialisation Identifier */
  tms_put_int(cfg->sampleRateDiv,msg,i,2); /**< Sample Rate Divider */
  tms_put_int(0x0000,msg,i,2);        /**< 2 reserved bytes */
  for (j=0; j<64; j++) {
    tms_put_int(cfg->storageType[j].shift,msg,i,1); /**< shift */
    tms_put_int(cfg->storageType[j].delta,msg,i,1); /**< delta */
    tms_put_int(cfg->storageType[j].deci ,msg,i,1); /**< decimation */
    tms_put_int(cfg->storageType[j].ref  ,msg,i,1); /**< ref */
  }
  for (j=0; j<12; j++) {
    tms_put_int(cfg->fileName[j],msg,i,1); /**< Measurement file name */
  }
  tms_put_date(&cfg->alarmTime,msg,i); /**< alarm time */
  tms_put_int(0xFFFFFFFF,msg,i,2);     /**< 2 or 4 reserved bytes. check it!!! */
  /* put info part */
  j=0;
  while ((j<sizeof(cfg->info)) && (*i<TMSCFGSIZE)) {
    tms_put_int(cfg->info[j],msg,i,1); j++;
  }
  //fprintf(stderr,"tms_put_cfg: i %d j %d\n",*i,j);
  return((*i)-i0);
}

/** Print tms_config_t 'cfg' to file 'fp'
 * @param prt_info !=0 -> print measurement/patient info
 * @return number of characters printed.
 */
int32_t tms_prt_cfg(FILE *fp, tms_config_t *cfg, int32_t prt_info) {

  int32_t nc=0;        /**< printed characters */
  int32_t i;           /**< index */
  char    atime[MNCN]; /**< alarm time */

  nc+=fprintf(fp,"v 0x%04X ; Version\n",cfg->version);
  nc+=fprintf(fp,"h 0x%04X ; hdrSize \n",cfg->hdrSize);
  nc+=fprintf(fp,"c 0x%04X ; cardStatus\n",cfg->cardStatus   ); 
  nc+=fprintf(fp,"t 0x%04x ; ",cfg->fileType);
  switch (cfg->fileType) {
    case 0:
      nc+=fprintf(fp,"ini");
      break;
    case 1:
      nc+=fprintf(fp,"smp");
      break;
    case 2:
      nc+=fprintf(fp,"evt");
      break;
    default:
      nc+=fprintf(fp,"unknown?");
      break;
  }    
  nc+=fprintf(fp," fileType\n");
  nc+=fprintf(fp,"g 0x%08X ; cfgSize\n",cfg->cfgSize);
  nc+=fprintf(fp,"r   %8d ; sample Rate [Hz]\n",cfg->sampleRate   );
  nc+=fprintf(fp,"n   %8d ; nr of Channels\n",cfg->nrOfChannels );

  nc+=fprintf(fp,"b 0x%08X ; startCtl:",cfg->startCtl);
  if (cfg->startCtl&0x01) {
    nc+=fprintf(fp," RTC_SET");
  }
  if (cfg->startCtl&0x02) {
    nc+=fprintf(fp," RECORD_AUTO_START");
  }
  if (cfg->startCtl&0x04) {
    nc+=fprintf(fp," BUTTON_ENABLE");
  }
  nc+=fprintf(fp,"\n");

  nc+=fprintf(fp,"e 0x%08X ; endCtl\n",cfg->endCtl       ); 
  nc+=fprintf(fp,"i 0x%08X ; initId\n",cfg->initId       ); 
  nc+=fprintf(fp,"d   %8d ; sample Rate Divider\n",cfg->sampleRateDiv); 
  strftime(atime,MNCN,"%Y-%m-%d %H:%M:%S",localtime(&cfg->alarmTime));
  nc+=fprintf(fp,"a   %8d ; alarm time %s\n",(int32_t)cfg->alarmTime,atime);
  nc+=fprintf(fp,"f %12s ; file name\n",cfg->fileName);
  nc+=fprintf(fp,"# nr refer decim delta shift ; ch period\n");
  for (i=0; i<64; i++) {
    if (cfg->storageType[i].delta!=0) {
      nc+=fprintf(fp,"s %2d %5d %5d %5d %5d ;  %1c %6d\n",i,
	  cfg->storageType[i].ref,
	  cfg->storageType[i].deci,
	  cfg->storageType[i].delta,
	  cfg->storageType[i].shift,
          'A'+i,
	  cfg->storageType[i].period);
    }
  }
  if (prt_info) {
    for (i=0; i<sizeof(cfg->info); i++) {
      if (i%16==0) { 
        if (i>0) {
          nc+=fprintf(fp,"\n");
        } 
        nc+=fprintf(fp,"o 0x%04X",i);
      }
      nc+=fprintf(fp," 0x%02X",cfg->info[i]);
    }
    nc+=fprintf(fp,"\n");
  }
  nc+=fprintf(fp,"q  ; end of configuration\n");
  return(nc);
}

/** Read tms_config_t 'cfg' from file 'fp'
 * @return number of characters printed.
 */
int32_t tms_rd_cfg(FILE *fp, tms_config_t *cfg) {

  int32_t lc=0;                /**< line counter */
  char line[2*MNCN];           /**< temp line buffer */
  char **endptr;               /**< end pointer of integer parsing */
  char *token;                 /**< token on the input line */
  int32_t nr;
  int32_t ref,decim,delta,shift;  /**< nr, ref, decim and delta storage */
  int32_t go_on=1; 
  
  /* all zero as default */
  memset(cfg,0,sizeof(tms_config_t));
  /* default no channel reference */
  for (nr=0; nr<64; nr++) {
    cfg->storageType[nr].ref=-1;
  }
 
  while (!feof(fp) && (go_on==1)) {
    /* clear line */
    line[0]='\0';
    /* read one line with hist data */
    fgets(line,sizeof(line)-1,fp); lc++;
    /* skip comment and data lines */
    if ((line[0]=='#') || (line[0]==' ')) { continue; }
    switch (line[0]) {
      case 'v': 
        cfg->version=strtol(&line[2],endptr,0);
        break;
      case 'h': 
        cfg->hdrSize=strtol(&line[2],endptr,0);
        break;
      case 't': 
        cfg->fileType=strtol(&line[2],endptr,0);
        break;
      case 'g': 
        cfg->cfgSize=strtol(&line[2],endptr,0);
        break;
      case 'r': 
        cfg->sampleRate=strtol(&line[2],endptr,0);
        break;
      case 'n': 
        cfg->nrOfChannels=strtol(&line[2],endptr,0);
        break;
      case 'b': 
        cfg->startCtl=strtol(&line[2],endptr,0);
        break;
      case 'e': 
        cfg->endCtl=strtol(&line[2],endptr,0);
        break;
      case 'i': 
        cfg->initId=strtol(&line[2],endptr,0);
        break;
      case 'c': 
        cfg->cardStatus=strtol(&line[2],endptr,0);
        break;
      case 'd': 
        cfg->sampleRateDiv=strtol(&line[2],endptr,0);
        break;
      case 'a': 
        cfg->alarmTime=strtol(&line[2],endptr,0);
        break;
      case 'f':
        sscanf(line,"f %s ;",cfg->fileName); endptr=NULL;
        break;
      case 's': 
        sscanf(line,"s %d %d %d %d %d ;",&nr,&ref,&decim,&delta,&shift); 
        endptr=NULL;
 	if ((nr>=0) && (nr<64)) {
          cfg->storageType[nr].ref  =ref;
	  cfg->storageType[nr].deci =decim;
	  cfg->storageType[nr].delta=delta;
	  cfg->storageType[nr].shift=shift;
        }
        break;
      case 'o':
        /* start parsing direct after character 'o' */
        token=strtok(&line[1]," \n");
        if (token!=NULL) {
          /* get start address */
          nr=strtol(token,endptr,0);
          /* parse data bytes */
          while ((token=strtok(NULL," \n"))!=NULL) {
            if ((nr>=0) && (nr<sizeof(cfg->info))) 
            cfg->info[nr]=strtol(token,endptr,0);
            nr++;
          }
        }
        break; 
      case 'q':
        go_on=0;
        break; 
      default: 
        break;
    } 
    if (endptr!=NULL) {
      fprintf(stderr,"# Warning: line %d has an configuration error!!!\n",lc);
    }       
  }
  return(lc);
}

/** Convert buffer 'msg' starting at position 'i' into tms_measurement_hdr_t 'hdr'
 * @note new position byte will be return in 'i'
 * @return number of bytes parsed
 */
int32_t tms_get_measurement_hdr(uint8_t *msg, int32_t *i, tms_measurement_hdr_t *hdr) {

  int32_t i0=*i;   /**< start byte index */
  int32_t err=0;   /**< error status of tms_get_date */

  (*i)+=4; /**< skip 4 reserved bytes */
  hdr->nsamples=tms_get_int(msg,i,4); /**< number of samples in this recording */
  err=tms_get_date(msg,i,&hdr->startTime);
  if (err!=0) {
    fprintf(stderr,"# Warning: start time incorrect!!!\n");
  }
  err=tms_get_date(msg,i,&hdr->endTime);
  if (err!=0) {
    fprintf(stderr,"# Warning: end time incorrect, unexpected end of recording!!!\n");
  }
  hdr->frontendSerialNr=tms_get_int(msg,i,4); /**< frontendSerial Number */
  hdr->frontendHWNr    =tms_get_int(msg,i,2); /**< frontend Hardware version Number */
  hdr->frontendSWNr    =tms_get_int(msg,i,2); /**< frontend Software version Number */
  return((*i)-i0);
}

/** Print tms_config_t 'cfg' to file 'fp'
 * @param prt_info 0x01 print measurement/patient info
 * @return number of characters printed.
 */
int32_t tms_prt_measurement_hdr(FILE *fp, tms_measurement_hdr_t *hdr) {

  int32_t nc=0;        /**< printed characters */
  char    stime[MNCN]; /**< start time */
  char    etime[MNCN]; /**< end time */

  strftime(stime,MNCN,"%Y-%m-%d %H:%M:%S",localtime(&hdr->startTime));
  strftime(etime,MNCN,"%Y-%m-%d %H:%M:%S",localtime(&hdr->endTime));
  nc+=fprintf(fp,"# time start %s end %s\n",stime,etime);
  nc+=fprintf(fp,"# Frontend SerialNr 0x%08X HWNr 0x%04X SWNr 0x%04X\n",
      hdr->frontendSerialNr,
      hdr->frontendHWNr,hdr->frontendSWNr); 
  nc+=fprintf(fp,"# nsamples %9d\n",hdr->nsamples); 

  return(nc);
}

/*********************************************************************/
/* Functions for reading and setting up the bluetooth connection     */
/*********************************************************************/

/** General check of TMS message 'msg' of 'n' bytes.
 * @return 0 on correct checksum, 1 on failure.
*/
int32_t tms_chk_msg(uint8_t *msg, int32_t n) {

  int32_t i;       /**< general index */
  int32_t sync;    /**< TMS block sync */
  int32_t size;    /**< TMS block size */
  int32_t calsum;  /**< calculate checksum of TMS block */
  
  /* check sync */
  i=0;
  sync=tms_get_int(msg,&i,2);
  if (sync!=TMSBLOCKSYNC) {
    fprintf(stderr,"# Warning: found sync %04X != %04X\n",
      sync,TMSBLOCKSYNC);
    return(-1);
  }
  /* size check */
  size=tms_msg_size(msg,n,&i);
  if (n!=(2*size+i+2)) {
    fprintf(stderr,"# Warning: found size %d != expected size %d\n",size,(n-i-2)/2);
  }  
  /* check checksum and get type */
  calsum=tms_cal_chksum(msg,n);
  if (calsum!=0x0000) {
    fprintf(stderr,"# Warning: checksum 0x%04X != 0x0000\n",calsum);
    return(1);
  } else {
    return(0);
  }
}

/** Put checksum at end of buffer 'msg' of 'n' bytes.
 * @return total size of 'msg' including checksum.
*/
int16_t tms_put_chksum(uint8_t *msg, int32_t n) {

  int32_t i;                   /**< general index */
  int16_t sum=0x0000;          /**< checksum */

  if (n%2==1) {
    fprintf(stderr,"Warning: tms_put_chksum: odd packet length %d\n",n);
  }
  /* calculate checksum */  
  for (i=0; i<(n/2); i++){
    sum += (msg[2*i+1] << 8) + msg[2*i];
  }
  /* checksum should add up to 0x0000 */
  sum=-sum;
  /* put it */
  i=n; tms_put_int(sum,msg,&i,2);
  /* return total size of 'msg' including checksum */
  return(i);
}

/** Read at max 'n' bytes of TMS message 'msg' for 
 *   socket device descriptor 'fd'.
 * @return number of bytes read.
*/
int32_t tms_rcv_msg(int fd, uint8_t *msg, int32_t n) {
  
  int32_t i=0;         /**< byte index */
  int32_t ii=0;        /**< tempory byte index */
  int32_t br=0;        /**< bytes read */
  int32_t tbr=0;       /**< total bytes read */
  int32_t sync=0x0000; /**< sync block */
  int32_t rtc=0;       /**< retry counter */
  int32_t size=0;      /**< payload size [uint16_t] */
  int32_t size8=0;    /**< payload size in [uint8_t] */
  
  /* clear recieve buffer */
  memset(msg,0x00,n);

  /* wait (not too long) for 2-byte sync block, 
	  and discard any data which isn't sync information. */
  br=0;
  while ((rtc<1000) && (sync!=TMSBLOCKSYNC)) {
    if (br>0) { /* discard non-sync data */
		msg[0]=msg[1]; /* shift bit back */
		if ( tbr>1 ) {
		  fprintf(stderr,"discarded non-sync data\n");
		}
    }
    br=recv(fd,&msg[1],1,0); tbr+=br; // Blocking call, may wait forever!
    if ((br>0) && (tbr>1)) {
      i=0; sync=tms_get_int(msg,&i,2);
    }
    rtc++;
  }
  if (rtc>=1000) {
    fprintf(stderr,"# Error: timeout on waiting for block sync\n");
    return(-1);    
  }
  /* read 2 byte description */
  br=recv(fd,&msg[i],2,0); i+=br; tbr+=br;
  /* while ((rtc<1000) && (i<4)) { */
  /* br=recv(fd,&msg[i],1,0); i+=br; tbr+=br; */
  /*   rtc++; */
  /* } */
  if (rtc>=1000) {
    fprintf(stderr,"# Error: timeout on waiting description\n");
    return(-2);    
  }
  ii=2;
  size=tms_get_int(msg,&ii,1);
  //size=msg[2]; /* size is 1 byte = measured in 16-bit words! so max message size is 256*2? */
  if (size==0xFF) {
	 fprintf(stderr,"multibyte msg size\n");
  }

  /* read rest of message */
  size8=2*size+6;  /* message size including a final checksum of 6 bytes? */
  if ( size8 > n ) {
    fprintf(stderr,"# Warning: message buffer size %d too small %d. Extra discarded !\n",n,size8);	 
  }
  while ( rtc<1000  && i<size8 ) {
	 if ( size8<n ) {
		br=recv(fd,&msg[i],size8-i,0); /* read the whole message in 1 call */
	 } else if( i<n ) { /* read until the buffer is full */
		br=recv(fd,&msg[i],1,0); 
		//br=recv(fd,&msg[i],n-i,0); 
	 } else { /* read and discard rest of message */
		br=recv(fd,&msg[n],1,0); 
	 }
	 i+=br; tbr+=br;
    rtc++;
  }
  if (rtc>=1000) {
    fprintf(stderr,"# Error: timeout on rest of message\n");
    return(-3);    
  }
  if (vb&0x01) {
    /* log response */
    tms_write_log_msg(msg,tbr,"receive message");
  }
  
  return(tbr);
}
  

/** Convert buffer 'msg' of 'n' bytes into tms_acknowledge_t 'ack'.
 * @return >0 on failure and 0 on success 
*/
int32_t tms_get_ack(uint8_t *msg, int32_t n, tms_acknowledge_t *ack) {

  int32_t i;     /**< general index */
  int32_t type;  /**< message type */
  int32_t size;  /**< payload size */
 
  /* get message type */ 
  type=tms_get_type(msg,n);
  if (type!=TMSACKNOWLEDGE) {
    fprintf(stderr,"# Warning: type %02X != %02X\n",
              type,TMSFRONTENDINFO);
    return(-1);
  }
  /* get payload size and payload pointer 'i' */
  size=tms_msg_size(msg,n,&i);
  ack->descriptor=tms_get_int(msg,&i,2);
  ack->errorcode=tms_get_int(msg,&i,2);
  /* number of found Frontend system info structs */  
  return(ack->errorcode);
}


/** Print tms_acknowledge_t 'ack' to file 'fp'.
 *  @return number of printed characters.
*/
int32_t tms_prt_ack(FILE *fp, tms_acknowledge_t *ack) {
 
  int32_t nc=0;
  
  if (fp==NULL) {
    return(nc);
  }
  nc+=fprintf(fp,"# Ack: desc %04X err %04X",
         ack->descriptor,ack->errorcode);
  switch (ack->errorcode) {
    case 0x01: 
      nc+=fprintf(fp," unknown or not implemented blocktype"); break;
    case 0x02: 
      nc+=fprintf(fp," CRC error in received block"); break;
    case 0x03: 
      nc+=fprintf(fp," error in command data (can't do that)"); break;
    case 0x04: 
      nc+=fprintf(fp," wrong blocksize (too large)"); break;
    // 0x0010 - 0xFFFF are reserved for user errors
    case 0x11: 
      nc+=fprintf(fp," No external power supplied"); break;
    case 0x12: 
      nc+=fprintf(fp," Not possible because the Front is recording"); break;
    case 0x13: 
      nc+=fprintf(fp," Storage medium is busy"); break;
    case 0x14: 
      nc+=fprintf(fp," Flash memory not present"); break;
    case 0x15: 
      nc+=fprintf(fp," nr of words to read from flash memory out of range"); break;
    case 0x16: 
      nc+=fprintf(fp," flash memory is write protected"); break;
    case 0x17: 
      nc+=fprintf(fp," incorrect value for initial inflation pressure"); break;
    case 0x18: 
      nc+=fprintf(fp," wrong size or values in BP cycle list"); break;
    case 0x19: 
      nc+=fprintf(fp," sample frequency divider out of range (<0, >max)"); break;
    case 0x1A: 
      nc+=fprintf(fp," wrong nr of user channels (<=0, >maxUSRchan)"); break;
    case 0x1B:
      nc+=fprintf(fp," adress flash memory out of range"); break;
    case 0x1C:
      nc+=fprintf(fp," Erasing not possible because battery low"); break;
    default:
     // 0x00 - no error, positive acknowledge
     break;
  }
  nc+=fprintf(fp,"\n");
  return(nc);
}


/** Send frontend Info request to 'fd'.
 *  @return bytes send.
*/
int32_t tms_snd_FrontendInfoReq(int32_t fd) {

  int32_t i;       /**< general index */
  uint8_t msg[6];  /**< message buffer */
  int32_t bw;      /**< byte written */
  
  i=0;
  /* construct frontendinfo req message */ 
  /* block sync */ 
  tms_put_int(TMSBLOCKSYNC,msg,&i,2);
  /* length 0, no data */
  msg[2] = 0x00;
  /* FrontendInfoReq type */
  msg[3] = TMSFRONTENDINFOREQ;
  /* add checksum */
  bw=tms_put_chksum(msg,4);

  if (vb&0x01) {
    tms_write_log_msg(msg,bw,"send frontendinfo request");
  }
  /* send request */
  bw=send(fd,msg,bw,0);
  /* return number of byte actualy written */ 
  return(bw);
}


/** Send keepalive request to 'fd'.
 *  @return bytes send.
*/
int32_t tms_snd_keepalive(int32_t fd) {

  int32_t i;       /**< general index */
  uint8_t msg[6];  /**< message buffer */
  int32_t bw;      /**< byte written */
  
  i=0;
  /* construct frontendinfo req message */ 
  /* block sync */ 
  tms_put_int(TMSBLOCKSYNC,msg,&i,2);
  /* length 0, no data */
  msg[2] = 0x00;
  /* FrontendInfoReq type */
  msg[3] = TMSKEEPALIVEREQ;
  /* add checksum */
  bw=tms_put_chksum(msg,4);

  if (vb&0x01) {
    tms_write_log_msg(msg,bw,"send keepalive");
  }
  /* send request */
  bw=send(fd,msg,bw,0);
  /* return number of byte actualy written */ 
  return(bw);
}

/** Convert buffer 'msg' of 'n' bytes into frontendinfo_t 'fei'
 * @note 'b' needs size of TMSFRONTENDINFOSIZE
 * @return -1 on failure and on succes number of frontendinfo structs
*/
int32_t tms_get_frontendinfo(uint8_t *msg, int32_t n, tms_frontendinfo_t *fei) {

  int32_t i;     /**< general index */
  int32_t type;  /**< message type */
  int32_t size;  /**< payload size */
  int32_t nfei;  /**< number of frontendinfo_t structs */
 
  /* get message type */ 
  type=tms_get_type(msg,n);
  if (type!=TMSFRONTENDINFO) {
    fprintf(stderr,"# Warning: tms_get_frontendinfo type %02X != %02X\n",
              type,TMSFRONTENDINFO);
    return(-3);
  }
  /* get payload size and start pointer */
  size=tms_msg_size(msg,n,&i);
  /* number of available frontendinfo_t structs */
  nfei=(2*size)/TMSFRONTENDINFOSIZE;
  if (nfei>1) {
    fprintf(stderr,"# Error: tms_get_frontendinfo found %d struct > 1\n",nfei);
  }
  fei->nrofuserchannels=tms_get_int(msg,&i,2);
  fei->currentsampleratesetting=tms_get_int(msg,&i,2);
  fei->mode=tms_get_int(msg,&i,2);
  fei->maxRS232=tms_get_int(msg,&i,2);
  fei->serialnumber=tms_get_int(msg,&i,4);
  fei->nrEXG=tms_get_int(msg,&i,2);
  fei->nrAUX=tms_get_int(msg,&i,2);
  fei->hwversion=tms_get_int(msg,&i,2);
  fei->swversion=tms_get_int(msg,&i,2);
  fei->cmdbufsize=tms_get_int(msg,&i,2);
  fei->sendbufsize=tms_get_int(msg,&i,2);
  fei->nrofswchannels=tms_get_int(msg,&i,2);
  fei->basesamplerate=tms_get_int(msg,&i,2);
  fei->power=tms_get_int(msg,&i,2);
  fei->hardwarecheck=tms_get_int(msg,&i,2);
  /* number of found Frontend system info structs */  
  return(nfei);
}

const tms_frontendinfo_t* tms_get_fei(){
  return fei;
}

/** Write frontendinfo_t 'fei' into socket 'fd'.
 * @return number of bytes written (<0: failure)
*/
int32_t tms_write_frontendinfo(int32_t fd, tms_frontendinfo_t *fei) {

  int32_t i;         /**< general index */
  uint8_t msg[0x40]; /**< message buffer */
  int32_t bw;        /**< byte written */
  
  i=0;
  /* construct frontendinfo req message */ 
  /* block sync */ 
  tms_put_int(TMSBLOCKSYNC,msg,&i,2);
  /* length */
  tms_put_int(TMSFRONTENDINFOSIZE/2,msg,&i,1);
  /* FrontendInfoReq type */
  tms_put_int(TMSFRONTENDINFO,msg,&i,1);

  /* readonly !!! */
  tms_put_int(fei->nrofuserchannels,msg,&i,2);

  /* writable*/
  tms_put_int(fei->currentsampleratesetting,msg,&i,2);
  tms_put_int(fei->mode,msg,&i,2);
 
  /* readonly !!! */
  tms_put_int(fei->maxRS232,msg,&i,2);
  tms_put_int(fei->serialnumber,msg,&i,4);
  tms_put_int(fei->nrEXG,msg,&i,2);
  tms_put_int(fei->nrAUX,msg,&i,2);
  tms_put_int(fei->hwversion,msg,&i,2);
  tms_put_int(fei->swversion,msg,&i,2);
  tms_put_int(fei->cmdbufsize,msg,&i,2);
  tms_put_int(fei->sendbufsize,msg,&i,2);
  tms_put_int(fei->nrofswchannels,msg,&i,2);
  tms_put_int(fei->basesamplerate,msg,&i,2);
  tms_put_int(fei->power,msg,&i,2);
  tms_put_int(fei->hardwarecheck,msg,&i,2);
  /* add checksum */
  bw=tms_put_chksum(msg,i);

  if (vb&0x01) {
    tms_write_log_msg(msg,bw,"write frontendinfo");
  }
  /* send request */
  bw=send(fd,msg,bw,0);
  /* return number of byte actualy written */ 
  return(bw);
}

/** Print tms_frontendinfo_t 'fei' to file 'fp'.
 *  @return number of printed characters.
*/
int32_t tms_prt_frontendinfo(FILE *fp, tms_frontendinfo_t *fei, int nr, int hdr) {

  int32_t nc=0;  /**< number of printed characters */
  
  if (fp==NULL) {
    return(nc);
  }
  if (hdr) {
    nc+=fprintf(fp,"# TMSi frontend info\n");
    nc+=fprintf(fp,"# %3s %3s %2s %4s %9s %4s %4s %4s %4s %4s %4s %4s %4s %4s %4s\n",
         "uch","css","md","mxfs","serialnr","nEXG","nAUX","hwv","swv","cmds","snds","nc","bfs","pw","hwck");
  }
  nc+=fprintf(fp," %4d %3d %02X %4d %9d %4d %4d %04X %04X %4d %4d %4d %4d %04X %04X\n",
    fei->nrofuserchannels,
    fei->currentsampleratesetting,
    fei->mode,
    fei->maxRS232,
    fei->serialnumber,
    fei->nrEXG,
    fei->nrAUX,
    fei->hwversion,
    fei->swversion,
    fei->cmdbufsize,
    fei->sendbufsize,
    fei->nrofswchannels,
    fei->basesamplerate,
    fei->power,
    fei->hardwarecheck);
  return(nc);
}

#define TMSIDREADREQ (0x22) 
#define TMSIDDATA    (0x23) 

/** Send IDData request to file descriptor 'fd'
*/

int32_t tms_send_iddata_request(int32_t fd, int32_t adr, int32_t len)
{
  uint8_t req[10];    /**< id request message */
  int32_t i=0;
  int32_t bw;         /**< byte written */

  /* block sync */ 
  tms_put_int(TMSBLOCKSYNC,req,&i,2);
  /* length 2 */
  tms_put_int(0x02,req,&i,1);
  /* IDReadReq type */
  tms_put_int(TMSIDREADREQ,req,&i,1);
  /* start address */
  tms_put_int(adr,req,&i,2);
  /* maximum length */
  tms_put_int(len,req,&i,2);
  /* add checksum */
  bw=tms_put_chksum(req,i);

  if (vb&0x01) {
    tms_write_log_msg(req,bw, "send IDData request");
  }
  /* send request */
  bw = send(fd,req,bw,0);
  if(bw < 0)
  {
      perror("# Warning: tms_send_iddata_request write problem");
  }
  return bw;
}

/** Get IDData from device descriptor 'fd' into byte array 'msg'
 *   with maximum size 'n'.
 * @return bytes in 'msg'.
*/
int32_t tms_fetch_iddata(int32_t fd, uint8_t *msg, int32_t n) {

  int32_t i,j;        /**< general index */
  int16_t adr=0x0000; /**< start address of buffer ID data */
  int16_t len=0x80;   /**< amount of words requested */
  int32_t br=0;       /**< bytes read */
  int32_t tbw=0;      /**< total bytes written in 'msg' */
  uint8_t rcv[512];   /**< recieve buffer */
  int32_t type;       /**< received IDData type */
  int32_t size;       /**< received IDData size */
  int32_t tsize=0;    /**< total received IDData size */
  int32_t start=0;    /**< start address in receive ID Data packet */
  int32_t length=0;   /**< length in receive ID Data packet */
  int32_t rtc=0;      /**< retry counter */
  
  /* prepare response header */
  tbw=0;
  /* block sync */ 
  tms_put_int(TMSBLOCKSYNC,msg,&tbw,2);
  /* length 0xFF */
  tms_put_int(0xFF,msg,&tbw,1);
  /* IDData type */
  tms_put_int(TMSIDDATA,msg,&tbw,1);
  /* temp zero length, final will be put at the end */
  tms_put_int(0,msg,&tbw,4);
  
  /* start address and maximum length */
  adr=0x0000; 
  len=0x80;
  
  rtc=0;
  /* keep on requesting id data until all data is read */
  while ((rtc<10) && (len>0) && (tbw<n)) {
    rtc++;
    if (tms_send_iddata_request(fd,adr,len) < 0) {
      continue;
    }
    /* get response */
    br=tms_rcv_msg(fd,rcv,sizeof(rcv)); 
    
    /* check checksum and get type of response */
    type=tms_get_type(rcv,br);
    if (type!=TMSIDDATA) {
      fprintf(stderr,"# Warning: tms_get_iddata: unexpected type 0x%02X\n",type);
      continue;
    } else {
      /* get payload of 'rcv' */
      size=tms_msg_size(rcv,sizeof(rcv),&i);
      /* get start address */
      start=tms_get_int(rcv,&i,2);
      /* get length */
      length=tms_get_int(rcv,&i,2);
      /* copy response to final result */
      if (tbw+2*length>n) {
        fprintf(stderr,"# Error: tms_get_iddata: msg too small %d\n",tbw+2*length);
      } else { 
        for (j=0; j<2*length; j++) {
          msg[tbw+j]=rcv[i+j];
        }
        tbw+=2*length;
        tsize+=length; 
      }
      /* update address admin */
      adr+=length;
      /* if block ends with 0xFFFF, then this one was the last one */ 
      if ((rcv[2*size-2]==0xFF) && (rcv[2*size-1]==0xFF)) { len=0; }
    }
  }
  /* put final total size */
  i=4; tms_put_int(tsize,msg,&i,4);
  /* add checksum */
  tbw=tms_put_chksum(msg,tbw);
  
  /* return number of byte actualy written */ 
  return(tbw);
}

/** Convert buffer 'msg' of 'n' bytes into tms_type_desc_t 'td'
 * @return 0 on success, -1 on failure
*/
int32_t tms_get_type_desc(uint8_t *msg, int32_t n, int32_t start, tms_type_desc_t *td) {

  int32_t i=start;   /**< general index */

  td->Size=tms_get_int(msg,&i,2);
  td->Type=tms_get_int(msg,&i,2);
  td->SubType=tms_get_int(msg,&i,2);
  td->Format=tms_get_int(msg,&i,2);
  td->a=tms_get_float(msg,&i);
  td->b=tms_get_float(msg,&i);
  td->UnitId=tms_get_int(msg,&i,1);
  td->Exp=tms_get_int(msg,&i,1);
  if (i<=n) { return(0); } else { return(-1); }
}


/** Get input device struct 'inpdev' at position 'start' of message 'msg' of 'n' bytes
 * @return always on success, -1 on failure
*/
int32_t tms_get_input_device(uint8_t *msg, int32_t n, int32_t start, tms_input_device_t *inpdev) {

  int32_t i=start,j;          /**< general index */
  int32_t idx;                /**< location */
  int32_t ChannelDescriptionSize;
  int32_t nb;                 /**< number of bits */
  int32_t tnb;                /**< total number of bits */
  
  inpdev->Size=tms_get_int(msg,&i,2);
  inpdev->Totalsize=tms_get_int(msg,&i,2);
  inpdev->SerialNumber=tms_get_int(msg,&i,4);
  inpdev->Id=tms_get_int(msg,&i,2);
  idx=2*tms_get_int(msg,&i,2)+start;
  inpdev->DeviceDescription = tms_get_string(msg,n,idx);
  inpdev->NrOfChannels=tms_get_int(msg,&i,2);
  ChannelDescriptionSize=tms_get_int(msg,&i,2);
  /* allocate space for all channel descriptions */
  inpdev->Channel=(tms_channel_desc_t *)calloc(inpdev->NrOfChannels,sizeof(tms_channel_desc_t));
  /* get pointer to first channel description */
  idx=2*tms_get_int(msg,&i,2)+start; 
  /* goto first channel descriptor */
  i=idx;
  /* get all channel descriptions */
  for (j=0; j<inpdev->NrOfChannels; j++) {
    idx=2*tms_get_int(msg,&i,2)+start;
    tms_get_type_desc(msg,n,idx,&inpdev->Channel[j].Type);
    idx=2*tms_get_int(msg,&i,2)+start;
    inpdev->Channel[j].ChannelDescription=tms_get_string(msg,n,idx);
    inpdev->Channel[j].GainCorrection    =tms_get_float(msg,&i);
    inpdev->Channel[j].OffsetCorrection  =tms_get_float(msg,&i);
  }
  /* count total number of bits needed */
  tnb=0;
  for (j=0; j<inpdev->NrOfChannels; j++) {
    nb=inpdev->Channel[j].Type.Format & 0xFF;
    if (nb%8!=0) {
      fprintf(stderr,"# Warning: tms_get_input_device: channel %d has %d bits\n",j,nb);
    } 
    tnb+=nb;
  }
  if (tnb%16!=0) {
    fprintf(stderr,"# Warning: tms_get_input_device: total bits count %d %% 16 !=0\n",tnb);
  }
  inpdev->DataPacketSize=tnb/16;

  if (i<=n) { return(0); } else { return(-1); }
}

const tms_input_device_t* tms_get_in_dev(){
  return in_dev;
}


/** Get input device struct 'inpdev' at position 'start' of message 'msg' of 'n' bytes
 * @return always on success, -1 on failure
 */
int32_t tms_get_iddata(uint8_t *msg, int32_t n, tms_input_device_t *inpdev) {

  int32_t type;    /**< message type */
  int32_t i=0;     /**< general index */
  int32_t size;    /**< payload size */

  /* get message type */ 
  type=tms_get_type(msg,n);
  if (type!=TMSIDDATA) {
    fprintf(stderr,"# Warning: type %02X != %02X\n",type,TMSIDDATA);
    return(-1);
  }
  size=tms_msg_size(msg,n,&i);
  return(tms_get_input_device(msg,n,i,inpdev));
}

/** Print tms_type_desc_t 'td' to file 'fp'.
 *  @return number of printed characters.
 */
int32_t tms_prt_type_desc(FILE *fp, tms_type_desc_t *td, int nr, int hdr) {

  int32_t nc=0;  /**< number of printed characters */

  if (fp==NULL) {
    return(nc);
  }
  if (hdr) {
    nc+=fprintf(fp," %6s %4s %4s %4s %4s %2s %3s %9s %9s %3s %4s %3s\n",
	"size","type","typd","sty","styd","sg","bit","a","b","uid","uidd","exp");
  }
  if (td==NULL) {
    return(nc);
  }

  /* print struct info */
  nc+=fprintf(fp," %6d %4d",td->Size,td->Type);
  switch (td->Type) {
    case  0: nc+=fprintf(fp," %4s","UNKN"); break;
    case  1: nc+=fprintf(fp," %4s","EXG"); break;
    case  2: nc+=fprintf(fp," %4s","BIP"); break;
    case  3: nc+=fprintf(fp," %4s","AUX"); break;
    case  4: nc+=fprintf(fp," %4s","DIG "); break;
    case  5: nc+=fprintf(fp," %4s","TIME"); break;
    case  6: nc+=fprintf(fp," %4s","LEAK"); break;
    case  7: nc+=fprintf(fp," %4s","PRES"); break;
    case  8: nc+=fprintf(fp," %4s","ENVE"); break;
    case  9: nc+=fprintf(fp," %4s","MARK"); break;
    case 10: nc+=fprintf(fp," %4s","ZAAG"); break;
    case 11: nc+=fprintf(fp," %4s","SAO2"); break;
    default: break;
  }    
  // (+256: unipolar reference, +512: impedance reference)
  nc+=fprintf(fp," %4d",td->SubType);
  /* SybType description */
  switch (td->SubType) {
    case   0: nc+=fprintf(fp," %4s","Unkn"); break;
    case   1: nc+=fprintf(fp," %4s","EEG"); break;
    case   2: nc+=fprintf(fp," %4s","EMG"); break;
    case   3: nc+=fprintf(fp," %4s","ECG"); break;
    case   4: nc+=fprintf(fp," %4s","EOG"); break;
    case   5: nc+=fprintf(fp," %4s","EAG"); break;
    case   6: nc+=fprintf(fp," %4s","EGG"); break;
    case 257: nc+=fprintf(fp," %4s","EEGR"); break;
    case  10: nc+=fprintf(fp," %4s","resp"); break;
    case  11: nc+=fprintf(fp," %4s","flow"); break;
    case  12: nc+=fprintf(fp," %4s","snor"); break;
    case  13: nc+=fprintf(fp," %4s","posi"); break;
    case 522: nc+=fprintf(fp," %4s","impr"); break;
    case  20: nc+=fprintf(fp," %4s","SaO2"); break;
    case  21: nc+=fprintf(fp," %4s","plet"); break;
    case  22: nc+=fprintf(fp," %4s","hear"); break;
    case  23: nc+=fprintf(fp," %4s","sens"); break;
    case  30: nc+=fprintf(fp," %4s","PVES"); break;
    case  31: nc+=fprintf(fp," %4s","PURA"); break;
    case  32: nc+=fprintf(fp," %4s","PABD"); break;
    case  33: nc+=fprintf(fp," %4s","PDET"); break;
    default: break;
  }    

  nc+=fprintf(fp," %2s %3d %9e %9e %3d",
      (td->Format&0x0100 ? "S" : "U"),(td->Format&0xFF),
      td->a,td->b,td->UnitId);
  /* UnitId description */
  switch (td->UnitId) {
    case 0: nc+=fprintf(fp," %4s","bit"); break;
    case 1: nc+=fprintf(fp," %4s","Volt"); break;
    case 2: nc+=fprintf(fp," %4s","%"); break;
    case 3: nc+=fprintf(fp," %4s","Bpm"); break;
    case 4: nc+=fprintf(fp," %4s","Bar"); break;
    case 5: nc+=fprintf(fp," %4s","Psi"); break;
    case 6: nc+=fprintf(fp," %4s","mH2O"); break;
    case 7: nc+=fprintf(fp," %4s","mHg"); break;
    case 8: nc+=fprintf(fp," %4s","bit"); break;
    default: break;
  }
  nc+=fprintf(fp," %3d\n",td->Exp);
  return(nc);
}


/** Print input device struct 'inpdev' to file 'fp'
 * @return number of characters printed.
 */
int32_t tms_prt_iddata(FILE *fp, tms_input_device_t *inpdev) {

  int32_t i=0;     /**< general index */
  int32_t nc=0;    /**< number of printed characters */

  if (fp==NULL) {
    return(nc);
  } 
  nc+=fprintf(fp,"# Input Device %s Serialnr %d\n",
      inpdev->DeviceDescription,
      inpdev->SerialNumber);
  /* ChannelDescriptions */
  nc+=fprintf(fp,"#%3s %7s %12s %12s","nr","Channel","Gain","Offset");
  nc+=tms_prt_type_desc(fp,NULL,0,(0==0));

  /* print all channel descriptors */
  for (i=0; i<inpdev->NrOfChannels; i++) {
    nc+=fprintf(fp," %3d %7s %12e %12e",
	i,
	inpdev->Channel[i].ChannelDescription,
	inpdev->Channel[i].GainCorrection,
	inpdev->Channel[i].OffsetCorrection);
    /* print type description */  
    nc+=tms_prt_type_desc(fp,&inpdev->Channel[i].Type,i,(1==0));
  }
  return(nc);
}

/** Open socket device 'fname' to TMSi aquisition device
 *  Nexus-10 or Mobi-8.
 * @return socket >0 on success.
 */
int32_t tms_open_port(char *fname) {  
  int s, status=0, ci=0, isbt=0, optval=0;
  
  /* test if this is a BT connection or a socket connection */
  /* Heuristic is: if >1 ':' character then is BT address... */
  isbt=0;
  for (ci=0; fname[ci]!=0; ci++){ 
	 if ( fname[ci]==':' ) isbt++;
	 /* alternative if have >1 '.' is a socket address */
	 if ( fname[ci]=='.' ) isbt=-1;
  }
  isbt = isbt>1;
  
  if ( isbt ){  
#ifdef BLUETOOTH
    struct sockaddr_rc addr = { 0 };
	 fprintf(stderr,"Opening BT device\n");
	 /* allocate a socket */
	 s = socket(AF_BLUETOOTH, SOCK_STREAM, BTPROTO_RFCOMM);

	 /* set the connection parameters (who to connect to) */
	 addr.rc_family = AF_BLUETOOTH;
	 addr.rc_channel = (uint8_t) 1;
	 str2ba(fname, &addr.rc_bdaddr );

	 /* open connection to TMSi hardware */
	 status = connect(s, (struct sockaddr *)&addr, sizeof(addr));
#else
	 fprintf(stderr,"Bluetooth not supported!");
	 exit(1);
#endif
  } else { /* this is a network socket connection */
	 fprintf(stderr,"Opening TCP/IP device\n");
    /* N.B. Type: TCP, Port: 4242 */
	 /* split the name into host:port parts */
	 struct sockaddr_in serveraddr;
	 struct hostent *server;
	 char hostname[MNCN];
	 int portno=DEFAULTPORT;
	 /* find the which splits the host and port info */
	 for (ci=0; fname[ci]!=0; ci++){ 
		if ( fname[ci]==':' ) { /* parse the port info */
		  portno=atoi(&(fname[ci+1]));
		  break;
		}
	 }
	 memcpy(hostname,fname,ci); hostname[ci]=0; /* copy hostname out and null-terminate */
	 
    /* socket: create the socket */
    s = socket(AF_INET, SOCK_STREAM, 0);
	 fprintf(stderr,"socket created\n");
    if (s < 0) {
		fprintf(stderr,"ERROR opening socket: %d\n",s);
		exit(0);
    }
	 /* enlarge the buffers to allow for some delay in processing the
		 data */
	 optval=163840; status=setsockopt(s,SOL_SOCKET,SO_RCVBUF,  (const char*)&optval,sizeof(optval));
	 if ( status < 0) {
		fprintf(stderr,"setsockopt error RCVBUF: %d\n",status);
	 }
	 optval=163840; status=setsockopt(s,SOL_SOCKET,SO_SNDBUF,  (const char*)&optval,sizeof(optval));
	 if ( status < 0) {
		fprintf(stderr,"setsockopt error SNDBUF: %d\n",status);
	 }
	 optval=1000;   status=setsockopt(s,SOL_SOCKET,SO_RCVTIMEO,(const char*)&optval,sizeof(optval));
	 if ( status < 0) {
	 	fprintf(stderr,"setsockopt error RCVTIMEO: %d\n",status);
	 }
#if !defined(__WIN32__) && !defined(__WIN64__)
	 optval=1; status=setsockopt(s,SOL_SOCKET,SO_REUSEPORT,(const char*)&optval,sizeof(optval));
	 if ( status < 0) {
	 	fprintf(stderr,"setsockopt error REUSEPORT: %d\n",status);
	 }
#endif
	 optval=0; status=setsockopt(s,SOL_SOCKET,SO_KEEPALIVE,(const char*)&optval,sizeof(optval));
	 if ( status < 0) {
	 	fprintf(stderr,"setsockopt error KEEPALIVE: %d\n",status);
	 }
#ifdef DISABLE_NAGLE
	 /* disable the Nagle buffering algorithm */
	 optval=1; status=setsockopt(s, IPPROTO_TCP, TCP_NODELAY,(const char*)&optval,sizeof(optval));
#endif
	 if ( status < 0) {
		fprintf(stderr,"setsockopt error NODELAY: %d\n",status);
	 }

    server = gethostbyname(hostname);
	 fprintf(stderr,"host resovled\n");
    if (server == NULL) {
		fprintf(stderr,"ERROR, no such host as %s\n", hostname);
		exit(0);
    }

    /* build the server's Internet address */
    memset((char *) &serveraddr, 0, sizeof(serveraddr));
    serveraddr.sin_family = AF_INET;
    memcpy((char *)&serveraddr.sin_addr.s_addr, (char *)server->h_addr,server->h_length);
    serveraddr.sin_port = htons(portno);

	 /* open connection to TMSi hardware */
    /* connect: create a connection with the server */
    if (connect(s, &serveraddr, sizeof(serveraddr)) < 0) {
		fprintf(stderr,"ERROR, connecting to %s:%d\n", hostname,portno);
		exit(0);
    }
	 fprintf(stderr,"connection made\n");
  }

  /* return socket */
  return(s);
}


/** Close file descriptor 'fd'.
 * @return 0 on successm, errno on failure.
 */
int32_t tms_close_port(int32_t fd) {

  if (close(fd) == -1) {
    perror("close_port: Error closing port - ");
    return errno;
  }
  return(0);
}


/** Print channel data block 'chd' of tms device 'dev' to file 'fp'.
 * @param print switch md 0: integer  1: float values
 * @return number of printed characters.
 */
int32_t tms_prt_channel_data(FILE *fp, tms_input_device_t *dev, tms_channel_data_t *chd, int32_t md)
{
  int32_t i,j;  /**< general index */
  int32_t nc=0;

  nc+=fprintf(fp,"# Channel data\n");   
  for (j=0; j<dev->NrOfChannels; j++) {
    nc+=fprintf(fp,"%2d %2d %2d |",j,chd[j].ns,chd[j].rs);
    for (i=0; i<chd[j].rs; i++) {
      if (md==0) {
	nc+=fprintf(fp," %08X%1C",chd[j].data[i].isample,
	    (chd[j].data[i].flag&0x01 ? '*' : ' '));
      } else {
	nc+=fprintf(fp," %9g%1C",chd[j].data[i].sample,
	    (chd[j].data[i].flag&0x01 ? '*' : ' '));
      }
    }
    nc+=fprintf(fp,"\n");
  }  
  return(nc);
}

/* Print bit string of 'msg' */
int32_t tms_prt_bits(FILE *fp, uint8_t *msg, int32_t n, int32_t idx)
{
  int32_t nc=0;
  int32_t i,j,a;

  /* hex values */
  nc+=fprintf(fp,"Hex MSB");
  for (i=n-1; i>=idx; i--) {
    nc+=fprintf(fp,"       %02X",msg[i]);
  }
  nc+=fprintf(fp," LSB\n");

  /* bin values */
  nc+=fprintf(fp,"Bin MSB");
  for (i=n-1; i>=idx; i--) {
    fprintf(fp," ");
    a=msg[i];
    for (j=0; j<8; j++) {
      nc+=fprintf(fp,"%1d",(a&0x80 ? 1 : 0));
      a=a<<1;
    }
  }
  nc+=fprintf(fp," LSB\n");
  return(nc);
}

/** Get TMS data from message 'msg' of 'n' bytes into floats 'val'.
 * @return number of samples.
 */
int32_t tms_get_data(uint8_t *msg, int32_t n, tms_input_device_t *dev, 
							tms_channel_data_t *chd)
{
  int32_t nbps;             /**< number of bytes per sample */ 
  int32_t type,size;        /**< TMS type and packet size */
  int32_t i,j;              /**< general index */
  int32_t bip;              /**< bit index pointer */
  int32_t cnt=0;            /**< sample counter */
  int32_t len,dv,overflow;  /**< delta sample: length, value and overflow flag */
  static int32_t *srp=NULL; /**< sample receiving period */
  static int32_t *sample_cnt=NULL; /**< sample count per channel */
  int32_t maxns;            /**< maximum number of samples */
  int32_t totns;            /**< total number of samples in this block */
  int32_t pc;               /**< period counter */

  int zaagch = ZAAGCH; /**< sawtooth channel */
  if ( tms_get_number_of_channels()>zaagch ) { /* BODGE: assume ZAAG is last channel */
	 zaagch = tms_get_number_of_channels()-1;
  }

  /* get message type */ 
  type=tms_get_type(msg,n);
  /* parse packet data */
  size=tms_msg_size(msg,n,&i);

  for (j=0; j<dev->NrOfChannels; j++) {
    /* only 1, 2 or 3 bytes width expected !!! */
    nbps=(dev->Channel[j].Type.Format & 0xFF)/8;
    /* get integer sample values */
    chd[j].data[0].isample=tms_get_int(msg,&i,nbps);
    /* sign extension for signed samples */    
    if (dev->Channel[j].Type.Format & 0x0100) {
      chd[j].data[0].isample=(chd[j].data[0].isample<<(32-8*nbps))>>(32-8*nbps);
    }
    /* check for overflow or underflow */
    chd[j].data[0].flag=0x00;
    if (chd[j].data[0].isample ==(0xFFFFFF80<<(8*(nbps-1)))) {
      chd[j].data[0].flag|=0x01;
    }
    /* increment receive counter */
    chd[j].rs=1;
  }

  if (sample_cnt==NULL) {
    sample_cnt=(int32_t *)calloc(dev->NrOfChannels,sizeof(int32_t));
    for (j=0; j<dev->NrOfChannels; j++) {
      sample_cnt[j]=0;
    }
  }

  /* continue with packets with VL Delta samples */
  if (type==TMSVLDELTADATA) {
    /* allocate space once for sample receive period */
    if (srp==NULL) {
      srp=(int32_t *)calloc(dev->NrOfChannels,sizeof(int32_t));
    }
    /* find maximum period and count total number of samples */
    maxns=0; totns=0;
    for (j=0; j<dev->NrOfChannels; j++) {
      if (!chd[j].data[0].flag&0x01) {
		  if (maxns<chd[j].ns) { maxns=chd[j].ns; }
		  totns+=chd[j].ns;
      } else {
		  totns++;
      }
    } 
    /* calculate sample receive period per channel */
    for (j=0; j<dev->NrOfChannels; j++) {
      srp[j]=maxns/chd[j].ns;
    } 
    if (vb&0x04) {
      /* print delta block */
      fprintf(stderr,"\nDelta block of %d bytes totns %d\n",n-2-i,totns);
      tms_prt_bits(stderr,msg,n-2,i);
      /* Delta block */
      fprintf(stderr,"Delta block:");
    }
    bip=8*i; cnt=dev->NrOfChannels; j=0; pc=1;
    while ((cnt<totns) && (bip<8*n-16)) {
      len=get_lsbf_int32_t(msg,&bip,4);
      if (len==0) {
		  dv=get_lsbf_int32_t(msg,&bip,2); overflow=0;
		  switch (dv) {
		  case 0: dv= 0; overflow=0; break; /* delta sample = 0 */ 
		  case 1: dv= 0; overflow=0; break; /* not used */ 
		  case 2: dv= 0; overflow=1; break; /* overflow */ 
		  case 3: dv=-1; overflow=0; break; /* delta sample =-1 */ 
		  default: break;
		  }
      } else {
		  dv=get_lsbf_int32_t_sign_ext(msg,&bip,len);
		  overflow=0;
      }
      if (vb&0x04) { fprintf(stderr," %d:%d",len,dv); }
      /* find channel not in overflow and needs this sample */
      while ((chd[j].data[0].flag&0x01) || (chd[j].rs>=chd[j].ns) || ((pc % srp[j])!=0)) {
		  /* next channel nr */
		  j++; if (j==dev->NrOfChannels) { j=0; pc++; }
		  if (pc>maxns) break;
      }
      chd[j].data[chd[j].rs].isample=dv;
      chd[j].data[chd[j].rs].flag=overflow;
      if (len==15) {
		  if (((dv&0x7FFF)==0x0000) || ((dv&0x7FFF)==0x7FFF)) {
			 chd[j].data[chd[j].rs].flag|=0x02; 
		  }
      }
      chd[j].rs++;
      /* delta sample counter */
      cnt++;
      /* next channel nr */
      j++; if (j==dev->NrOfChannels) { j=0; pc++; }
    }
    if (vb&0x04) { fprintf(stderr," cnt %d\n",cnt); }
  }

  /* convert integer samples to real floats */
  for (j=0; j<dev->NrOfChannels; j++) {
    /* integrate delta value to actual values or fill skipped overflow channels */
    for (i=1; i<chd[j].ns; i++) {
      /* check overflow */
      if (chd[j].data[0].flag&0x01) {
		  chd[j].data[i].isample =chd[j].data[0].isample;
		  chd[j].data[i].flag    =chd[j].data[0].flag;
      } else {
		  chd[j].data[i].isample+=chd[j].data[i-1].isample;
      }
    }

    /* convert to real (calibrated) float values */
	 for (i=0; i<chd[j].ns; i++) {
		if ( j!=zaagch ){ // apply the scaling and offset correction
		  chd[j].data[i].sample=(dev->Channel[j].Type.a)*chd[j].data[i].isample + dev->Channel[j].Type.b;
		} else { // zaagch is directly the isample version
		  chd[j].data[i].sample=chd[j].data[i].isample;
		}
	 }
    /* update sample counter */
    chd[j].sc=sample_cnt[j];
    sample_cnt[j]+=chd[j].ns;
  }
  return(cnt);
}

/** Print TMS channel data 'chd' to file 'fp'.
 * @param md: print switch 0: float 1: integer values
 * @param cs: bit-mask to select channels A: 0x01 B: 0x02 C: 0x04 ...
 * @return number of characters printed.
 */
int32_t tms_prt_samples(FILE *fp, tms_channel_data_t *chd, int32_t cs, int32_t md)
{
  int32_t nc=0;                 /**< number of characters printed */ 
  static int32_t maxns=0;       /**< maximum number of samples over all channels */
  int32_t mns;                  /**< current maxns */
  int32_t i,j,jm,idx;           /**< general index */
  int32_t ssf;                  /**< sub-sample factor */
  static tms_data_t *prt=NULL;  /**< printer storage for all samples over all channels */

  /* search for current maximum number of samples over all channels */
  mns=0;
  for (j=0; j<tms_get_number_of_channels(); j++) {
    if (mns<chd[j].ns)  { 
      mns=chd[j].ns;
    }
  }

  if (mns>maxns) {
    maxns=mns;
    if (prt!=NULL) { 
      /* free previous printer storage space */
      free(prt); 
    }
    /* malloc storage space for rectangle print data array */
    prt=(tms_data_t *)calloc(maxns*tms_get_number_of_channels(),sizeof(tms_data_t));
  }

  /* search for channel 'jm' with maximum number of samples over all wanted channels */
  mns=0; jm=0;
  for (j=0; j<tms_get_number_of_channels(); j++) {
    if (cs&(1<<j)) {
      if (mns<chd[j].ns) {
	mns=chd[j].ns;
	jm=j;
      }
    }
  }

  /* fill all wanted channels */  
  for (j=0; j<tms_get_number_of_channels(); j++) {
    if (cs&(1<<j)) {
      ssf=mns/chd[j].ns;
      for (i=0; i<mns; i++) {
        idx=maxns*j+i;
        if ((i % ssf)==0) {
	  /* copy samples into rectanglar array 'ptr' */
          prt[idx]=chd[j].data[i/ssf];
        } else {
	  /* fill all unavailable samples with "NaN" -> flag=0x04 */
          prt[idx].isample=0; prt[idx].sample=0.0; prt[idx].flag=0x04;
	}
      }
    }
  }
  /* print output file header */
  if (chd[0].sc==0) {
    nc+=fprintf(fp,"#%9s %8s","t[s]","sc");
    for (j=0; j<tms_get_number_of_channels(); j++) {
      if (cs&(1<<j)) {
	nc+=fprintf(fp," %8s%1c","",'A'+j);
      }
    }
    nc+=fprintf(fp,"\n");
  }

  /* print all wanted channels */
  for (i=0; i<mns; i++) {
    nc+=fprintf(fp," %9.4f %8d",(chd[jm].sc+i)*chd[jm].td,chd[jm].sc+i);
    for (j=0; j<tms_get_number_of_channels(); j++) {
      if (cs&(1<<j)) {
        idx=maxns*j+i;
        if (prt[idx].flag!=0) {
          /* all overflows and not availables are mapped to "NaN" */
	  nc+=fprintf(fp," %9s","NaN");
	} else {
	  if (md==0) {
	    nc+=fprintf(fp," %9.3f",prt[idx].sample);
          } else {
  	    nc+=fprintf(fp," %9d",prt[idx].isample);
	  } 
        }
      }
    }
    nc+=fprintf(fp,"\n");
  }
  return(nc);
}

/** Send VLDeltaInfo request to file descriptor 'fd'
*/
int32_t tms_snd_vldelta_info_request(int32_t fd)
{
  uint8_t req[10];    /**< id request message */
  int32_t i=0;
  int32_t bw;         /**< byte written */

  /* block sync */ 
  tms_put_int(TMSBLOCKSYNC,req,&i,2);
  /* length 0 */
  tms_put_int(0x00,req,&i,1);
  /* IDReadReq type */
  tms_put_int(TMSVLDELTAINFOREQ,req,&i,1);
  /* add checksum */
  bw=tms_put_chksum(req,i);

  if (vb&0x01) {
    tms_write_log_msg(req,bw,"send VLDeltaInfo request");
  }
  /* send request */
  bw = send(fd,req,bw,0);
  if(bw < 0)
  {
    perror("# Warning: tms_send_vl_delta_info_request write problem");
  }
  return bw;
}

/** Convert buffer 'msg' of 'n' bytes into tms_vldelta_info_t 'vld' for 'nch' channels.
 * @return number of bytes processed.
 */
int32_t tms_get_vldelta_info(uint8_t *msg, int32_t n, int32_t nch, tms_vldelta_info_t *vld) {

  int32_t i,j;   /**< general index */
  int32_t type;  /**< message type */
  int32_t size;  /**< payload size */

  /* get message type */ 
  type=tms_get_type(msg,n);
  if (type!=TMSVLDELTAINFO) {
    fprintf(stderr,"# Warning: tms_get_vldelta_info type %02X != %02X\n",
	type,TMSVLDELTAINFO);
    return(-1);
  }
  /* get payload size and payload pointer 'i' */
  size=tms_msg_size(msg,n,&i);
  vld->Config=tms_get_int(msg,&i,2);
  vld->Length=tms_get_int(msg,&i,2);
  vld->TransFreqDiv=tms_get_int(msg,&i,2);
  vld->NrOfChannels=nch;
  vld->SampDiv=(uint16_t *)calloc(nch,sizeof(int16_t));
  for (j=0; j<nch; j++) {
    vld->SampDiv[j]=tms_get_int(msg,&i,2);
  }
  /* number of found Frontend system info structs */  
  return(i);
}

/** Print tms_rtc_t 'rtc' to file 'fp'.
 *  @return number of printed characters.
 */
int32_t tms_prt_vldelta_info(FILE *fp, tms_vldelta_info_t *vld, int nr, int hdr) {

  int32_t nc=0;  /**< number of printed characters */
  int32_t j;     /**< general index */

  if (fp==NULL) {
    return(nc);
  }
  if (hdr) {
    nc+=fprintf(fp,"# VL Delta Info\n");
    nc+=fprintf(fp,"# %5s %6s %6s %6s %6s\n","nr","Config","Length","TransFS","SampDiv");
  }
  nc+=fprintf(fp," %6d %6d %6d %6d",nr,vld->Config,vld->Length,vld->TransFreqDiv);
  for (j=0; j<vld->NrOfChannels; j++) {
    nc+=fprintf(fp," %6d",vld->SampDiv[j]);
  }
  nc+=fprintf(fp,"\n");
  return(nc);
}

/** Send Real Time Clock (RTC) read request to file descriptor 'fd'
 *  @return number of bytes send.
 */
int32_t tms_send_rtc_time_read_req(int32_t fd)
{
  uint8_t req[10];    /**< id request message */
  int32_t i=0;
  int32_t bw;         /**< byte written */

  /* block sync */ 
  tms_put_int(TMSBLOCKSYNC,req,&i,2);
  /* length 0 */
  tms_put_int(0x00,req,&i,1);
  /* IDReadReq type */
  tms_put_int(TMSRTCTIMEREADREQ,req,&i,1);
  /* add checksum */
  bw=tms_put_chksum(req,i);

  if (vb&0x01) {
    tms_write_log_msg(req,bw,"send rtc read request");
  }
  /* send request */
  bw = send(fd,req,bw,0);
  if(bw < 0)
  {
    perror("# Warning: tms_rtc_time_read_request write problem");
  }
  return(bw);
}

/** Convert buffer 'msg' of 'n' bytes into tms_rtc_t 'rtc'
 * @return 0 on failure and number of bytes processed
 */
int32_t tms_get_rtc(uint8_t *msg, int32_t n, tms_rtc_t *rtc) {

  int32_t i;     /**< general index */
  int32_t type;  /**< message type */
  int32_t size;  /**< payload size */

  /* get message type */ 
  type=tms_get_type(msg,n);
  if (type!=TMSRTCTIMEDATA) {
    fprintf(stderr,"# Warning: type %02X != %02X\n",
	type,TMSRTCTIMEDATA);
    return(-3);
  }
  /* get payload size and start pointer */
  size=tms_msg_size(msg,n,&i);
  if (size!=8) {
    fprintf(stderr,"# Warning: tms_get_rtc: unexpected size %d iso %d\n",size,8);
  }
  /* parse message 'msg' */
  rtc->seconds=tms_get_int(msg,&i,2);
  rtc->minutes=tms_get_int(msg,&i,2);
  rtc->hours  =tms_get_int(msg,&i,2);
  rtc->day    =tms_get_int(msg,&i,2);
  rtc->month  =tms_get_int(msg,&i,2);
  rtc->year   =tms_get_int(msg,&i,2);
  rtc->century=tms_get_int(msg,&i,2);
  rtc->weekday=tms_get_int(msg,&i,2);
  return(i);
}

/** Print tms_rtc_t 'rtc' to file 'fp'.
 *  @return number of printed characters.
 */
int32_t tms_prt_rtc(FILE *fp, tms_rtc_t *rtc, int nr, int hdr) {

  int32_t nc=0;  /**< number of printed characters */
  int32_t utc=0; /**< number of seconds since 00:00:00 */
  static int32_t putc=0; /**< number of seconds since 00:00:00 */
  static int32_t pnr=0;

  if (fp==NULL) {
    return(nc);
  }
  if (hdr) {
    nc+=fprintf(fp,"# Real time clock\n");
    nc+=fprintf(fp,"#    nr yyyy-mm-dd hh:mm:ss  utc\n");
  }

  utc=rtc->seconds+60*(rtc->minutes+60*rtc->hours);
  nc+=fprintf(fp," %6d %02d%02d-%02d-%02d %02d:%02d:%02d %8d",
      nr,rtc->century,rtc->year,rtc->month,rtc->day,rtc->hours,rtc->minutes,rtc->seconds,utc);
  nc+=fprintf(fp," %6d %6d\n",nr-pnr,utc-putc);
  /* remember previous values */
  pnr=nr; putc=utc;
  return(nc);
}

/** Get the number of channels of this TMSi device
 * @return number of channels
*/
int32_t tms_get_number_of_channels()
{
  if (in_dev==NULL) {
    return -1;
  }
  return in_dev->NrOfChannels;
}

/** Get the number of channels of this TMSi device
 * @return number of channels
*/
tms_input_device_t* tms_input_device()
{
  if (in_dev==NULL) {
    return -1;
  }
  return in_dev;
}

/* Get the current sample frequency.
* @return current sample frequency [Hz]
*/
double tms_get_sample_freq()
{
  if (fei==NULL) {
    return -1;
  }
  return (double) (fei->basesamplerate/(1<<fei->currentsampleratesetting));

  }

/** Construct channel data block with frontend info 'fei' and
 *   input device 'dev' with eventually vldelta_info 'vld'.
 * @return pointer to channel_data_t struct, NULL on failure.
 */
tms_channel_data_t *tms_alloc_channel_data()
{
  int32_t i;                 /**< general index */
  tms_channel_data_t *chd;   /**< channel data block pointer */
  int32_t ns_max=1;          /**< maximum number of samples of all channels */
    
  /* allocate storage space for all channels */
  chd=(tms_channel_data_t *)calloc(in_dev->NrOfChannels,sizeof(tms_channel_data_t));
  for (i=0; i<in_dev->NrOfChannels; i++) {
    if (vld==NULL) {
      chd[i].ns=1;
    } else {
      chd[i].ns=(vld->TransFreqDiv+1)/(vld->SampDiv[i]+1);
    }
    /* reset sample counter */
    chd[i].sc=0;
    if (chd[i].ns>ns_max)
    {
      ns_max=chd[i].ns;
    }
    chd[i].data=(tms_data_t *)calloc(chd[i].ns,sizeof(tms_data_t));
  }  
  for (i=0; i<in_dev->NrOfChannels; i++) {
    chd[i].td=ns_max/(chd[i].ns*tms_get_sample_freq());
  }
  return(chd);
}

/** Free channel data block */
void tms_free_channel_data(tms_channel_data_t *chd)
{
  int32_t i;                 /**< general index */
    
  /* free storage space for all channels */
  for (i=0; i<in_dev->NrOfChannels; i++) {
      free(chd[i].data);
  }
  free(chd);
}

static int32_t state=0;   /**< State machine */
static int32_t fd=0;      /**< File descriptor of socket socket */

/** Initialize TMSi device with Socket address 'fname' and
 *   sample rate divider 'sample_rate_div'.
 * @note no timeout implemented yet.
 * @return always 0
*/
int32_t tms_init(char *fname, int32_t sample_rate_div)
{
  int bw = 0;                    /**< bytes written */
  int br = 0;                    /**< bytes read */
  int32_t fs=0;                  /**< sample frequency */
  uint8_t resp[RESPSIZE];        /**< TMS response to challenge */
  int32_t type;                  /**< TMS message type */
  
  tms_acknowledge_t  ack;        /**< TMS acknowlegde */
  
  fei = (tms_frontendinfo_t *)malloc(sizeof(tms_frontendinfo_t));
  vld = (tms_vldelta_info_t *)malloc(sizeof(tms_vldelta_info_t));
  in_dev = (tms_input_device_t *)malloc(sizeof(tms_input_device_t));

  fd = tms_open_port(fname);
  printf("Opened socket %d\n", fd);

  while (state < 4)
  {
    switch (state)
    {
      case 0: 
        /* send frontend Info request */
        bw=tms_snd_FrontendInfoReq(fd);
        /* receive response to frontend Info request */
        br=tms_rcv_msg(fd,resp,sizeof(resp));
        break;
      case 1:  
        /* switch off data capture when it is on */
        /* stop capture */
        fei->mode|=0x01;          
		  /* stop storage */
		  fei->mode|=0x02;
        /* set sample rate divider */
        fs=fei->basesamplerate/(1<<sample_rate_div);
        fei->currentsampleratesetting=sample_rate_div;
        /* send it */
        tms_write_frontendinfo(fd,fei);
        /* receive ack */
        br=tms_rcv_msg(fd,resp,sizeof(resp));
        break;
      case 2:
        /* receive ID Data */
        br=tms_fetch_iddata(fd,resp,sizeof(resp));
        break;
      case 3:
        /* send vldelta info request */
        bw=tms_snd_vldelta_info_request(fd);
        /* receive response to vldelta info request */
        br=tms_rcv_msg(fd,resp,sizeof(resp));
        break;
    }
    
    if (vb&0x01) {
      fprintf(fpl,"# State %d\n", state);
    }
    /* process response */
    if (br<0) {
      fprintf(stderr,"# Error: no valid response in state %d\n",state);
      continue;
    }

    /* check checksum and get type of response */
    if (tms_chk_msg(resp,br)!=0) {
      fprintf(stderr,"# checksum error !!!\n");
    } else {
      
      type=tms_get_type(resp,br);
      
      switch (type) {
      
        case TMSVLDELTADATA:
        case TMSCHANNELDATA:
        case TMSRTCTIMEDATA:
	  break;
        case TMSVLDELTAINFO:
          tms_get_vldelta_info(resp,br,in_dev->NrOfChannels,vld);
          if (vb&0x02) {
            tms_prt_vldelta_info(fpl,vld,0,0==0);
          }
          state++;
          break;
          
        case TMSACKNOWLEDGE:
          tms_get_ack(resp,br,&ack);
          if (vb&0x02) {
            tms_prt_ack(fpl,&ack);
          }
          state++;
          break;
          
        case TMSIDDATA:
          tms_get_iddata(resp,br,in_dev);
          if (vb&0x02) {
            tms_prt_iddata(fpl,in_dev);
          }
          state++;
          break;
          
        case TMSFRONTENDINFO:
          /* decode packet to struct */
          tms_get_frontendinfo(resp,br,fei);
          if (vb&0x02) {
            tms_prt_frontendinfo(fpl,fei,0,(0==0));
          }
          state++;
          break;
        default:
          fprintf(stderr,"# don't understand type %02X\n",type);
          break;
      }
    }
  }
  return 0;
}

/** Get elapsed time [s] of this tms_channel_data_t 'channel'.
* @return -1 of failure, elapsed seconds in success.
*/
double tms_elapsed_time(tms_channel_data_t *channel) {

  if (channel==NULL) {
    return(-1.0);
  }
  /* elapsed time = previous sample counter * tick duration */
  return(channel[0].sc*channel[0].td);
}

/** Get one or more samples for all channels
*  @note all samples are returned via 'channel'
* @return total number of samples in 'channel'
*/
int32_t tms_get_samples(tms_channel_data_t *channel)
{
  int br = 0;                    /**< bytes read */
  uint8_t resp[RESPSIZE];            /**< TMS response to challenge */
  int32_t type;                  /**< TMS message type */
  static int32_t dpc=0;          /**< data packet counter */
  double t;                      /**< current time */
  static double tka;             /**< keep-alive time */
  static double datastarttime;   /**< time we started receiving data */
  static int32_t pzaag=62;       /**< previous zaag value */
  int32_t zaag;                  /**< current zaag value */
  int32_t zaagincrement;         /**< amount by which zaag increases between samples */
  static int32_t tzerr=0;        /**< total zaag error counter */
  int32_t zerr=0;                /**< zaag error value */
  int32_t cnt=0;                 /**< sample counter */
  tms_acknowledge_t  ack;        /**< TMS acknowlegde */
  int zaagch = ZAAGCH; /**< sawtooth channel */
  if ( tms_get_number_of_channels()>zaagch ) { /* BODGE: assume ZAAG is last channel */
	 zaagch = tms_get_number_of_channels()-1;
  }
 
  if (state < 4 || state > 5)
	 {
		return -1;
	 }
  if  (state==4) 
	 {
		/* switch to data capture */
		//fei->mode=0x02; /* send data, no storage */
		fei->mode= fei->mode & (~0x01); /* turn on data sending -- by setting bit 0 -> low (0), no storage */
		/* start data capturing */
		tms_write_frontendinfo(fd,fei);
		/* receive ack */
		br=tms_rcv_msg(fd,resp,sizeof(resp));
		type=tms_get_type(resp,br);
		if (type != TMSACKNOWLEDGE)
		  {
			 return -1;
		  }
		else
		  {
			 tms_get_ack(resp,br,&ack);
			 if (vb&0x02) {
				tms_prt_ack(fpl,&ack);
			 }
			 state++;
		  }
	 }
  if (state==5)
	 {
		br=tms_rcv_msg(fd,resp,sizeof(resp));
		if (tms_chk_msg(resp,br)!=0) {
		  fprintf(stderr,"# checksum error !!!\n");
		} else {
      
		  type=tms_get_type(resp,br);
      
		  switch (type) {
      
        case TMSVLDELTADATA:
        case TMSCHANNELDATA:
			 /* get current time */
			 t=get_time();
			 /* first sample */
			 if (dpc==0) { 
				/* start keep alive timer */
				tka=t;
				datastarttime=t;
			 }
			 /* convert channel data to float's */
			 cnt=tms_get_data(resp,br,in_dev,channel);
			 if (vb&0x04) {
				/* print wanted channels !!! */
				tms_prt_channel_data(stderr,in_dev,channel,1);
			 }
			 /* check zaag !!! */
			 zaagincrement = 2<<(fei->currentsampleratesetting); /* check for reduced sample rate */
			 zaag=channel[zaagch].data[0].isample;
			 if (dpc>0 && (zaag-pzaag+64) % 64 >zaagincrement) {
				fprintf(stderr,"%fs # Zaag: %d PZaag: %d\n", t-datastarttime, (zaag+64)%64, (pzaag+64)%64);
				/* correct data packet counter with saw jump */
				/* !!! 5 bits for saw is too small -> firmware fix in Mobi-8 */
				/*dpc+=((zaag-pzaag+62) % 64)/zaagincrement; */
				/* saw error */
				zerr=1;
				tzerr++;
			 }
			 pzaag=zaag; 
	  
			 /* check if keep alive is needed */
			 if (t-tka>60.0) {
				//tms_snd_keepalive(fd);
				tka=t;
			 }  
			 /* increment data packet counter */
			 dpc++;
          break;
		  case TMSACKNOWLEDGE:
			 break;
		  default:
			 fprintf(stderr,"Unrecognised packet type: %d\n",type);
          break;       
		  }
		}
	 }

  /* report zaag errors */
  if (zerr>0) {
    fprintf(stderr,"# %d zaag errors\n",tzerr);
  }
  return(cnt);
}

/** shutdown sample capturing.
 *  @return 0 always.
*/
int32_t tms_shutdown()
{
  int br = 0;                    /**< bytes read */
  uint8_t resp[RESPSIZE];        /**< TMS response to challenge */
  int32_t type;                  /**< TMS message type */
  int32_t got_ack=0;
  int rtc=0; 
  //TODO

  if ( fd<=0 ) {
	 /* no connection made yet! */
	 return(state);
  }
  
  /* stop capturing data */
  fei->mode=0x01;
  tms_write_frontendinfo(fd,fei);

  /* wait for ack is received OR until 10s timeout */  
  fprintf(stderr,"Wait ACK:");
  do
  {
    br=tms_rcv_msg(fd,resp,sizeof(resp));
    if (tms_chk_msg(resp,br)!=0) {
      fprintf(stderr,"# checksum error !!!\n");
    } else {
      type=tms_get_type(resp,br);
      if (type==TMSACKNOWLEDGE) {
	got_ack=1;
      }
    }
    fprintf(stderr,".");
	 rtc++;
  } while (!got_ack && rtc<1000);

  state=0;
  /* close socket */
  /*fprintf(stderr,"5");*/
  tms_close_port(fd);
  /* fprintf(stderr,"6"); */

  free(fei);
  free(vld);
  free(in_dev);
  return(state);
}

