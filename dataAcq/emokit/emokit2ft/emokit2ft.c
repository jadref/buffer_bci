/*
 * This piece of code demonstrates how an acquisition device could be
 * writing header information (e.g. number of channels and sampling
 * frequency) and streaming EEG data to the buffer.
 *
 * Copyright (C) 2008, Robert Oostenveld
 * F.C. Donders Centre for Cognitive Neuroimaging, Radboud University Nijmegen,
 * Kapittelweg 29, 6525 EN Nijmegen, The Netherlands
 *
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <signal.h>
#include "buffer.h"
#include "emokit/emokit.h"

#if defined(__WIN32__) || defined(__WIN64__)
 #define SIGALRM -1
#endif


static const float FSAMPLE   = 127.94;
static const int NCHANS    = 17; /* 14 eeg, +counter + 2gyro channels */
static int BUFFRATE  = 64; /* 2 sample per data block */
typedef FLOAT32_T emokit_samp_t;
#define DATATYPE_EMOKIT (DATATYPE_FLOAT32);
static const int WORDSIZE_EMOKIT=WORDSIZE_FLOAT32;
static const int eeg_zero_offset=2^13;
static const emokit_samp_t eeg_scale =0.51; /* scale to convert to muV */

static const int FREQ=1;
static const float PI=3.15;

const char *labels[] = {
	"COUNTER",
	"AF3",
	"F7",
	"F3",
	"FC5",
	"T7",
	"P7",
	"O1",
	"O2",
	"P8",
	"T8", 
	"FC6",
	"F4",
	"F8",
	"AF4",
	"GYROX", 
	"GYROY"
};

void sig_handler(int32_t sig) 
{
  fprintf(stdout,"\nStop grabbing with signal %d\n",sig);
  exit(sig);
}

int readresponse(int serverfd, messagedef_t *responsedef){
  /* N.B. this could happen at a later time */
  /* 2. Read the response */
  /* 2.1 Read response message */
  int n=0;
  char*         responsebuf = NULL;
  if ((n = bufread(serverfd, responsedef, sizeof(messagedef_t))) != sizeof(messagedef_t)) {
	 fprintf(stderr, "packet size = %d, should be %d\n", n, sizeof(messagedef_t));
	 sig_handler(-1);
	 }
  /* 2.2 Read response data if needed */
  if (responsedef->bufsize>0) {
	 responsebuf = malloc(responsedef->bufsize);
	 if ((n = bufread(serverfd, responsebuf, responsedef->bufsize)) != responsedef->bufsize) {
		fprintf(stderr, "read size = %d, should be %d\n", n, responsedef->bufsize);
		sig_handler(-1);
	 }
		/* ignore the response and free the memory */
	 free(responsebuf); 
  }
  return 0;
}

void usage(){
  fprintf(stderr, "Usage: emokit2ft buffersocket buffrate\n");
  fprintf(stderr, "\t buffersocket\t is a string of the form bufferhost:bufferport         (localhost:1972)\n");
  fprintf(stderr, "\t buffrate\t is the frequency in Hz that data is sent to the buffer    (%d)\n",BUFFRATE);
}


int main(int argc, char *argv[]) {
  struct emokit_device* d;  
  struct emokit_frame c;

  int32_t i, j, k, nsamp = 0, nblk=0, si=0, status = 0, verbose = 1;
  int32_t putdatrequestsize=0;
  long int elapsedusec=0, printtime=0;
  struct timeval starttime, curtime;
  host_t buffhost;

  /* these represent the acquisition system properties */
  int nchans         = NCHANS;
  int fsample        = FSAMPLE;
  int blocksize      = roundf(fsample/((float)BUFFRATE));
  int channamesize   = 0;
  char *labelsbuf    = NULL;

  /* these are used in the communication and represent statefull information */
  int serverfd             = -1;
  message_t     request;
  char          *requestbuf = NULL;
  data_t        data;
  emokit_samp_t *samples=NULL;
  message_t     *response = NULL;
  messagedef_t  responsedef;
  header_t      header;
  ft_chunkdef_t chunkdef; // for holding the channel names

  if ( argc==1 ) usage();
  if ( argc>1 && (strcmp(argv[1],"-help")==0 || strcmp(argv[1],"-h")==0) ) { usage();  sig_handler(0); }

  if (argc>1) {
	 char *fname=argv[1];
	 int ci=0;
	 /* find the which splits the host and port info */
	 for (ci=0; fname[ci]!=0; ci++){ 
		if ( fname[ci]==':' ) { /* parse the port info */
		  buffhost.port=atoi(&(fname[ci+1]));
		  break;
		}
	 }
	 memcpy(buffhost.name,fname,ci); buffhost.name[ci]=0; /* copy hostname out and null-terminate */
  }
  else {
	 sprintf(buffhost.name, "%s", DEFAULT_HOSTNAME);
	 buffhost.port = DEFAULT_PORT;
  }

  if (verbose>0) fprintf(stderr, "emokit2ft: buffer = %s:%d\n", buffhost.name,buffhost.port);

  if ( argc>2 ) {
	 BUFFRATE = atoi(argv[2]);
	 blocksize = (int)(roundf(fsample/((float)BUFFRATE)));	 
  }
  if (verbose>0) fprintf(stderr, "emokit2ft: BUFFRATE = %d\n", BUFFRATE); 
  if (verbose>0) fprintf(stderr, "emokit2ft: blocksize = %d\n", blocksize); 

  //-------------------------------------------------------------------------------
  // open the emotive device
  d = emokit_create();
  k = emokit_get_count(d, EMOKIT_VID, EMOKIT_PID);
  printf("Current epoc devices connected: %d\n", k);
  status=-1;
  if ( k>0 ){
	 for ( i=k-1; i>=0 & i<k; i--){
		status = emokit_open(d, EMOKIT_VID, EMOKIT_PID, i);
		if(status == 0 ) { 
		  printf("Connected : %d:%d\n",i,status);
		  break;
		} else {
		  printf("CANNOT CONNECT: %d:%d\n", i,status); 
		}
	 }
  }
  if ( status != 0 ) { 
	 printf("Could not connect to any device\nDo you have permission to read from : /dev/hidrawX\nsee https://github.com/openyou/emokit/issues/89\n"); 
	 return 1; 
  }

  //-------------------------------------------------------------------------------
  /* allocate the elements that will be used in the buffer communication */
  request.def = malloc(sizeof(messagedef_t));
  request.buf = NULL;
  request.def->version = VERSION;
  request.def->bufsize = 0;

  header.def = malloc(sizeof(headerdef_t));
  header.buf = NULL; /* header buf contains the channel names */
  //header.buf = labels;

  /* define the header */
  header.def->nchans    = nchans;
  header.def->nsamples  = 0;
  header.def->nevents   = 0;
  header.def->fsample   = fsample;
  header.def->data_type = DATATYPE_EMOKIT;
  header.def->bufsize   = 0;
		
  //-------------------------------------------------------------------------------
  /* define the stuff for the channel names */
  /* compute the size of the channel names set */
  channamesize=0;
  for( i=0; i<nchans; i++){
	 for ( j=0; labels[i][j]!='\0'; j++); j++;
	 channamesize+=j;
  }
  /* allocate the memory for the channel names, and copy them into
	  it */
  labelsbuf = malloc(WORDSIZE_CHAR*channamesize);
  k=0;
  for( i=0; i<nchans; i++){
	 for ( j=0; labels[i][j]!='\0'; j++,k++) {
		labelsbuf[k]=labels[i][j];
	 }
	 labelsbuf[k]=labels[i][j]; k++;
  }
  chunkdef.type = FT_CHUNK_CHANNEL_NAMES;
  chunkdef.size = k;
  // add this info to the header buffer
  header.def->bufsize = append(&header.buf, header.def->bufsize, &chunkdef, sizeof(ft_chunkdef_t));
  header.def->bufsize = append(&header.buf, header.def->bufsize, labelsbuf, chunkdef.size);

  //-------------------------------------------------------------------------------
  /* initialization phase, send the header */
  request.def->command = PUT_HDR;
  request.def->bufsize = append(&request.buf, request.def->bufsize, header.def, sizeof(headerdef_t));
  request.def->bufsize = append(&request.buf, request.def->bufsize, header.buf, header.def->bufsize);

  fprintf(stderr,"emokit2ft: Attempting to open connection to buffer....");
  while ( (serverfd = open_connection(buffhost.name,buffhost.port)) < 0 ){
	 fprintf(stderr, "emokit2ft; failed to create socket. waiting\n");
	 usleep(1000000);/* sleep for 1second and retry */
  }
  fprintf(stderr,"done.\nSending header...");
  status = tcprequest(serverfd, &request, &response);
  if (status) {
	 fprintf(stderr, "emokit2ft: put header error = %d\n",status);
	 sig_handler(-1);
  } 
  fprintf(stderr, "done\n");
  free(request.buf);
  free(request.def);		
  if (response->def->command != PUT_OK) {
	 fprintf(stderr, "emokit2ft: error in 'put header' request.\n");
    sig_handler(-1);
  }
  FREE(response->buf);
  free(response->def);
  free(response);

  /* add a small pause between writing header + first data block */
  usleep(200000);


  //-------------------------------------------------------------------------------
  /* allocate space for the putdata request as 1 block, this contains
	  [ request_def data_def data ] */
  putdatrequestsize = sizeof(messagedef_t) + sizeof(datadef_t) + WORDSIZE_EMOKIT*nchans*blocksize;
  requestbuf  = malloc(putdatrequestsize);
  /* define the constant part of the send-data request and allocate space for the variable part */
  request.def = requestbuf ;
  request.buf = request.def + 1; /* N.B. cool pointer arithemetic trick for above! */
  request.def->version = VERSION;
  request.def->command = PUT_DAT;
  request.def->bufsize = putdatrequestsize - sizeof(messagedef_t);
  /* setup the data part of the message */
  data.def            = request.buf;
  data.buf            = data.def + 1; /* N.B. cool pointer arithemetic trick for above */
  samples             = data.buf;     /* version with correct type */
  /* define the constant part of the data */
  data.def->nchans    = nchans;
  data.def->nsamples  = blocksize;
  data.def->data_type = DATATYPE_EMOKIT;
  data.def->bufsize   = WORDSIZE_EMOKIT * nchans * blocksize;

  //-------------------------------------------------------------------------------
  // Loop sending the data in blocks as it becomes available
  gettimeofday(&starttime,NULL); /* get time we started to compute delay before next sample */
  while (1) {

	 //-------------------------------------------------------------------------------
	 for ( si=0; si<blocksize; si++){ // get a block's worth of samples
		// wait until new data to get, 4 milliSec N.B. inter-sample ~= 8 milliSec
		while( emokit_read_data(d)<=0 ) { usleep(2000); } 
		/* get the new data */
		c = emokit_get_next_frame(d);
		if ( verbose>1 ) {
		  printf("%5d) %5d\t%5d\t%5d\t%5d\t%5d\t%5d\n", nsamp, c.counter, c.gyroX, c.gyroY, c.F3, c.FC6, c.P7);  
		  fflush(stdout);
		}
		// copy the samples into the data buffer, in the order we
		// *said* they should be
		samples[(si*nchans)+0] =c.counter;
		samples[(si*nchans)+1] =(c.AF3 - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+2] =(c.F7  - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+3] =(c.F3  - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+4] =(c.FC5 - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+5] =(c.T7  - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+6] =(c.P7  - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+7] =(c.O1  - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+8] =(c.O2  - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+9] =(c.P8  - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+10]=(c.T8  - eeg_zero_offset)*eeg_scale; 
		samples[(si*nchans)+11]=(c.FC6 - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+12]=(c.F4  - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+13]=(c.F8  - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+14]=(c.AF4 - eeg_zero_offset)*eeg_scale;
		samples[(si*nchans)+15]=c.gyroX;
		samples[(si*nchans)+16]=c.gyroY;
		nsamp+=1;/*nsamp; */
	 }

	 //-------------------------------------------------------------------------------
	 /* send the data to the buffer */
	 /* 0. If send data already read response to previous put-data */
	 if ( nblk > 0 ) {
		if ( readresponse(serverfd,&responsedef) !=0 ||
			  responsedef.command != PUT_OK ) {
		  fprintf(stderr,"emokit2ft: Error writing samples.\n");		  
		}
	 }
	 
	 /* 1. Send the new data, but don't wait for a response */	 
	 if ((k = bufwrite(serverfd, request.def, putdatrequestsize)) != putdatrequestsize) {
		fprintf(stderr, "write size = %d, should be %d\n", k, putdatrequestsize);
		sig_handler(-1);
	 }

	 /* do some logging */
	 gettimeofday(&curtime,NULL);
	 elapsedusec=(curtime.tv_usec + 1000000 * curtime.tv_sec) - (starttime.tv_usec + 1000000 * starttime.tv_sec);
	 if ( elapsedusec / 1000000 >= printtime ) {
		fprintf(stderr,"%d %d %d %f (blk,samp,event,sec)\r",nblk,nsamp,0,elapsedusec/1000000.0);
		printtime+=10;
	 }
	 nblk+=1;
  } /* while(1) */

  // free all the stuff we've allocated
  free(labelsbuf);
  free(requestbuf);
}

