/*
 * This code sends data from a TMSi mobita device to a buffer-device
 * using the put_dat methods.
 *
 */

#include <math.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <signal.h>
#include "buffer.h"
#include "tmsi.h"

#define TMSIDEFAULT "10.11.12.13:4242" /* "00:A0:96:1B:44:C6" */  /**< default bluetooth address */
#define SRDDEF                  (0)  /**< default log2 of sample rate divider */
#define DATATYPE_MOBITA       (DATATYPE_FLOAT32)
typedef FLOAT32_T mobita_samp_t;
static const int WORDSIZE_MOBITA=WORDSIZE_FLOAT32;
static int BUFFRATE=50; /* rate (Hz) at which samples are sent to the buffer */
/* N.B. for now only ratedivider of 0 or 1 seems to work!, larger causes samples to be missed... */
static int SAMPLERATEDIVIDER=1; /**< log2 of sample rate divider */
static const int MAXSAMPLE=-1;/*10000;*/ /* for timeout based execution */
static int BUFFERSUBSAMPLESIZE=1; /* number of buffer samples per amplifier sample */
static int MAXMISSEDSAMPLES=100; /* number of missed samples in a row to cause exit. */

#if defined(__WIN32__) || defined(__WIN64__)
 #define SIGALRM -1
 #if defined(NOBACKGROUNDSCAN)
    #include <wlanapi.h>
 #endif
#endif

void sig_handler(int32_t sig) 
{
  fprintf(stdout,"\nStop grabbing with signal %d\n",sig);
  tms_shutdown();
  tms_close_log();
  //raise(SIGALRM);  
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
	 sig_handler(-2);
	 }
  /* 2.2 Read response data if needed */
  if (responsedef->bufsize>0) {
	 responsebuf = malloc(responsedef->bufsize);
	 if ((n = bufread(serverfd, responsebuf, responsedef->bufsize)) != responsedef->bufsize) {
		fprintf(stderr, "read size = %d, should be %d\n", n, responsedef->bufsize);
		sig_handler(-2);
	 }
		/* ignore the response and free the memory */
	 free(responsebuf); 
  }
  return 0;
}

void usage(){
  fprintf(stderr, "Usage: mobita2ft tmsisocket buffersocket buffrate sampleratedivider\n");
  fprintf(stderr, "where:\n");
  fprintf(stderr, "\t tmsisocket\t is a string of the form tmsihost:tmsiport               (%s)\n",TMSIDEFAULT);
  fprintf(stderr, "\t buffersocket\t is a string of the form bufferhost:bufferport         (localhost:1972)\n");
  fprintf(stderr, "\t buffrate\t is the frequency in Hz that data is sent to the buffer    (%d)\n",BUFFRATE);
  fprintf(stderr, "\t buffsampledivider\t is number of amp-samples to use in each buffer sample (%d)\n",BUFFERSUBSAMPLESIZE);
  fprintf(stderr, "\t sampleratedivider\t is log2 of sample rate divider                   (%d)\n",SAMPLERATEDIVIDER);
  /*sig_handler(0);*/
}

int main(int argc, char *argv[]) {

  int32_t i, j, k, nsamp = 0, nblk=0, tmssamp=0, si=0, chi=0, status = 0, verbose = 1, nbad=0;
  int32_t putdatrequestsize=0;
  long int elapsedusec=0, sampleusec=0, printtime=0;
  host_t buffhost;
  char   *tmsidev; /* string to hold the name of the driver device*/

  /* these represent the acquisition system properties */
  int nchans         = -1;
  float fsample      = -1;
  int blocksize      = 1;
  int channamesize   = 0;
  char *labelsbuf    = NULL;

  /* these are used in the communication and represent statefull information */
  int serverfd             = -1;
  message_t     request;
  char          *requestbuf = NULL;
  data_t        data;
  mobita_samp_t *samples=NULL;
  message_t     *response = NULL;
  messagedef_t  responsedef;
  char*         responsebuf = NULL;
  header_t      header;
  ft_chunkdef_t chunkdef; // for holding the channel names

  /* these are specific structures for the acquisation device */
  tms_channel_data_t *channel;   /**< channel data */
  int32_t srd=SAMPLERATEDIVIDER;                 /**< log2 of sample rate divider */
  struct timeval starttime, curtime;

  (void)signal(SIGINT,sig_handler);
  /* Note on WINDOWs you *must* do this for socket functions to work */
  // startup WinSock in Windows
#if defined(__WIN32__) || defined(__WIN64__)
  WSADATA wsa_data;
  WSAStartup(MAKEWORD(1,1), &wsa_data);
#endif    
	 
  if ( argc==1 || ( argc>1 && (strcmp(argv[1],"-help")==0 || strcmp(argv[1],"-h")==0) ) ) usage(); 

  if (argc>1) {
	 tmsidev = argv[1];
  } else {
	 tmsidev = TMSIDEFAULT;
  }
  if (verbose>0) fprintf(stderr, "mobita2ft: tmsidev = %s\n", tmsidev);

  if (argc>2) {
	 char *fname=argv[2];
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
	 snprintf(buffhost.name, 256, "%s", DEFAULT_HOSTNAME);
	 buffhost.port = DEFAULT_PORT;
  }
  if (verbose>0) fprintf(stderr, "mobita2ft: buffer = %s:%d\n", buffhost.name,buffhost.port);
  
  if ( argc>3 ) {
	 BUFFRATE = atoi(argv[3]);
	 if (verbose>0) fprintf(stderr, "mobita2ft: BUFFRATE = %d\n", BUFFRATE); 
  }
  if ( argc>4 ) {
	 BUFFERSUBSAMPLESIZE = atoi(argv[4]);
	 if (verbose>0) fprintf(stderr, "mobita2ft: BUFFERSAMPLERATEDIVIDER = %d\n", BUFFERSUBSAMPLESIZE); 
  }
  if ( argc>5 ) {
	 SAMPLERATEDIVIDER = atoi(argv[5]);
	 if (verbose>0) fprintf(stderr, "mobita2ft: SAMPLERATEDIVIDER = %d\n", SAMPLERATEDIVIDER); 
  }

  //-------------------------------------------------------------------------------
  // open the mobita device
  status=tms_init(tmsidev,srd);
  if(status != 0)
	 {
		fprintf(stderr,"mobita2ft: CANNOT CONNECT: %d\n", status);
		return 1;
	 }
 
  channel=tms_alloc_channel_data();
  if (channel==NULL) {
    fprintf(stderr,"mobita2ft: # main: tms_alloc_channel_data problem!! basesamplerate!\n");
    sig_handler(-3);
  }
  fprintf(stderr,"mobita2ft: Connected\n");
  nchans = tms_get_number_of_channels();
  fsample = tms_get_sample_freq()/BUFFERSUBSAMPLESIZE;
  blocksize = fsample/BUFFRATE;
  if (verbose>0) fprintf(stderr, "mobita2ft: fsample=%f  blocksize = %d\n", fsample, blocksize); 
  
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
  header.def->data_type = DATATYPE_MOBITA;
  header.def->bufsize   = 0;
  		
  //-------------------------------------------------------------------------------
  /* define the stuff for the channel names */
  /* compute the size of the channel names set */
  channamesize=0;
  for( i=0; i<nchans; i++){
	 for ( j=0; tms_get_in_dev()->Channel[i].ChannelDescription[j]!='\0'; j++); j++;
	 channamesize+=j;
  }
  /* allocate the memory for the channel names, and copy them into it */
  labelsbuf = malloc(WORDSIZE_CHAR*channamesize);
  k=0;
  for( i=0; i<nchans; i++){
	 for ( j=0; tms_get_in_dev()->Channel[i].ChannelDescription[j]!='\0'; j++,k++) {
		labelsbuf[k]=tms_get_in_dev()->Channel[i].ChannelDescription[j];
	 }
	 labelsbuf[k]=tms_get_in_dev()->Channel[i].ChannelDescription[j]; k++;
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

  fprintf(stderr,"mobita2ft: Attempting to open connection to buffer....");
  while ( (serverfd = open_connection(buffhost.name,buffhost.port)) < 0 ){
	 fprintf(stderr, "mobita2ft; failed to create socket. waiting\n");
	 usleep(1000000);/* sleep for 1second and retry */
  }
  fprintf(stderr,"done.\nSending header...");
  status = tcprequest(serverfd, &request, &response);
  fprintf(stderr,"done.\n");
  if (verbose>1) fprintf(stderr, "mobita2ft: tcprequest returned %d\n", status);
  if (status) {
	 fprintf(stderr, "mobita2ft: put header error = %d\n",status);
    sig_handler(-4);
  }
  free(request.buf);
  free(request.def);
		
  if (response->def->command != PUT_OK) {
	 fprintf(stderr, "mobita2ft: error in 'put header' request.\n");
    sig_handler(-5);
  }
  FREE(response->buf);
  free(response->def);
  free(response);
  response=NULL;

  /* add a small pause between writing header + first data block */
  usleep(200000);


  //-------------------------------------------------------------------------------

  /* allocate space for the putdata request as 1 block, this contains
	  [ request_def data_def data ] */
  putdatrequestsize = sizeof(messagedef_t) + sizeof(datadef_t) + WORDSIZE_MOBITA*nchans*blocksize;
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
  data.def->data_type = DATATYPE_MOBITA;
  data.def->bufsize   = WORDSIZE_MOBITA * nchans * blocksize;

  //-------------------------------------------------------------------------------
  // Loop sending the data in blocks as it becomes available
  gettimeofday(&starttime,NULL); /* get time we started to compute delay before next sample */
  while (1) {

	 //-------------------------------------------------------------------------------
	 if ( BUFFERSUBSAMPLESIZE>1 ) for ( i=0; i<blocksize*nchans; i++ ) samples[i]=0.0;
	 for ( si=0; si<blocksize*BUFFERSUBSAMPLESIZE; si++){ // get a block's worth of TMSIsamples
												 // -- assumes 1 sample per call!
		/* get the new data */
		tmssamp=0;
		while ( tmssamp<=0 ) { // get new data samples
		  tmssamp=tms_get_samples(channel);
		  if ( tmssamp != nchans ) {
			 nbad++;
			 /* Note: the number of samples returned by the tms_get_samples seems
				 to be garbage so ignore it for now */
			 fprintf(stderr, "mobita2ft: tms_get_samples error got %d samples when expected 1.\n",tmssamp);
			 if ( nbad<MAXMISSEDSAMPLES ) {
				usleep(500); /* sleep for 500 micro-seconds = .5ms -- to stop cpu hogging */
				continue;
			 } else {
				fprintf(stderr,"mobita2ft: tmp_get_samples returned *BAD* samples too many times.\n");
				sig_handler(-6);
			 }
		  } else {
			 if ( nbad>0 ) nbad--;
		  }
		}
		
		// copy the samples into the data buffer, in the order we
		if ( BUFFERSUBSAMPLESIZE>1 ) {/* accumulate over BUFFERSUBSAMPLESIZE device samples */
		  int buffsi = si/BUFFERSUBSAMPLESIZE; /* sample index in the buffer data packet */
		  for (chi=0; chi<nchans; chi++){
			 samples[(buffsi*nchans)+chi]+=channel[chi].data[channel[chi].rs-1].sample;
		  }
		} else { /* 1 amp sample per buffer sample */
		  for (chi=0; chi<nchans; chi++){
			 samples[(si*nchans)+chi]=channel[chi].data[channel[chi].rs-1].sample;
		  }
		}
		nsamp+=1;/*nsamp; */
	 }
	 if ( BUFFERSUBSAMPLESIZE>1 ) { /* convert multi-samples summs into means */
		  for ( i=0; i<blocksize*nchans; i++ ) samples[i]/=BUFFERSUBSAMPLESIZE;
	 }
	 if ( MAXSAMPLE>0 && nsamp>MAXSAMPLE ) break;

	 //-------------------------------------------------------------------------------
	 /* send the data to the buffer */
	 /* 0. If send data already read response to previous put-data */
	 if ( nblk > 0 ) {
		if ( readresponse(serverfd,&responsedef) !=0 ||
			  responsedef.command != PUT_OK ) {
		  fprintf(stderr,"mobita2ft: Error writing samples.\n");		  
		}
	 }
	 
	 /* 1. Send the new data, but don't wait for a response */	 
	 if ((k = bufwrite(serverfd, request.def, putdatrequestsize)) != putdatrequestsize) {
		fprintf(stderr, "write size = %d, should be %d\n", k, putdatrequestsize);
		sig_handler(-7);
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

#if defined(__WIN32__) || defined(__WIN64__)
    WSACleanup();
#endif
	 sig_handler(0);
}
