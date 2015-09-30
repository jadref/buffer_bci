/*
 * This code sends simulated noise data to a running buffer using the
 * putDat methods
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

static int BUFFRATE=50; /* rate (Hz) at which samples are sent to the buffer */
#define DATATYPE_PROXY       (DATATYPE_FLOAT32)
static const int WORDSIZE_PROXY=WORDSIZE_FLOAT32;
static int VERBOSE =0;
long int sleeptime=0;
long int sleepcount=0;

#if defined(__WIN32__) || defined(__WIN64__)
 #define SIGALRM -1
#endif

int exitExpt=0;
void sig_handler(int32_t sig) 
{
  fprintf(stdout,"\nStop grabbing with signal %d\n",sig);
  fprintf(stdout,"Sleep Ave = %fusec\n",(float)(sleeptime)/(float)(sleepcount));
  //raise(SIGALRM);  
  exitExpt=1;
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



int main(int argc, char *argv[]) {

  int32_t i, n=0, nsamp = 0, nblk=0, si=0, chi=0, status = 0, verbose = 1;
  int32_t putdatrequestsize=0;
  double elapsedusec=0, sampleusec=0, printtime=0;
  host_t buffhost;

  /* these represent the acquisition system properties */
  int nchans         = 3;
  float fsample      = 100;
  float sinFreq         = 10; /* frequency of ossilation in hz */
  int blocksize      = 1;
  int channamesize   = 0;
  char *labelsbuf    = NULL;

  /* these are used in the communication and represent statefull information */
  int serverfd       = -1;
  message_t     request;
  char *requestbuf = NULL;
  data_t        data;
  float *samples, *ampsamples;
  message_t     *response = NULL;
  messagedef_t  responsedef;
  char*         responsebuf = NULL;
  header_t      header;
  ft_chunkdef_t chunkdef; // for holding the channel names
  struct timeval starttime, curtime;

  (void)signal(SIGINT,sig_handler);
/* Note on WINDOWs you *must* do this for socket functions to work */
    // startup WinSock in Windows
#if defined(__WIN32__) || defined(__WIN64__)
    WSADATA wsa_data;
    WSAStartup(MAKEWORD(1,1), &wsa_data);
#endif    
  
	 if(argc>1&&(strcmp(argv[1],"--help")==0 || strcmp(argv[1],"-help")==0 || strcmp(argv[1],"-h")==0)){
		fprintf(stderr, "Usage: csignalproxy buffersocket fsample nchans buffrate\n");
		fprintf(stderr, "where:\n");
		fprintf(stderr, "\t buffersocket\t is a string of the form bufferhost:bufferport (localhost:1972)\n");
		fprintf(stderr, "\t fsample\t is the frequency data is generated in Hz                 (100)\n");
		fprintf(stderr, "\t nchans\t is the number of simulated channels to make                 (3)\n");
		fprintf(stderr, "\t buffrate\t is the frequency in Hz that data is sent to the buffer   (50)\n");
		exit(0);
	 }

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
	 } else {
		sprintf(buffhost.name, "%s", DEFAULT_HOSTNAME);
		buffhost.port = DEFAULT_PORT;
	 }
	 if (verbose>0) fprintf(stderr, "csignalproxy: buffer      = %s:%d\n", buffhost.name,buffhost.port);
  
	 if ( argc>2 ) {
		fsample = atoi(argv[2]);
		if (verbose>0) fprintf(stderr, "csignalproxy: fsample   = %f\n", fsample); 
	 }

	 if ( argc>3 ) {
		nchans = atoi(argv[3]);
		if (verbose>0) fprintf(stderr, "csignalproxy: nChannels = %d\n", nchans); 
	 }

	 if ( argc>4 ) {
		BUFFRATE = atoi(argv[4]);
		if (verbose>0) fprintf(stderr, "csignalproxy: BUFFRATE = %d\n", BUFFRATE); 
	 }

  
  //-------------------------------------------------------------------------------
  /* allocate the elements that will be used in the buffer communication */
  request.def = malloc(sizeof(messagedef_t));
  request.buf = NULL;
  request.def->version = VERSION;
  request.def->bufsize = 0;

  header.def = malloc(sizeof(headerdef_t));
  header.buf = NULL; /* header buf contains the channel names */
  //header->buf = labels;


  /* define the header */
  header.def->nchans    = nchans;
  header.def->nsamples  = 0;
  header.def->nevents   = 0;
  header.def->fsample   = fsample;
  header.def->data_type = DATATYPE_PROXY;
  header.def->bufsize   = 0;
  		
  //-------------------------------------------------------------------------------
  /* define the stuff for the channel names */
  /* compute the size of the channel names set */
  channamesize=4; /* 4 characters per channel, %3d + \0 */
  /* allocate the memory for the channel names, and copy them into it */
  labelsbuf = malloc(WORDSIZE_CHAR*channamesize*nchans);
  for( i=0; i<nchans-1; i++){
	 snprintf(&(labelsbuf[i*channamesize]),channamesize,"%03d",i);
  }
  /* last channel is the sin channel */
  snprintf(&(labelsbuf[(nchans-1)*channamesize]),channamesize,"sin");
  chunkdef.type = FT_CHUNK_CHANNEL_NAMES;
  chunkdef.size = channamesize*nchans*WORDSIZE_CHAR;
  // add this info to the header buffer
  header.def->bufsize = append(&header.buf, header.def->bufsize, &chunkdef, sizeof(ft_chunkdef_t));
  header.def->bufsize = append(&header.buf, header.def->bufsize, labelsbuf, chunkdef.size);

  //-------------------------------------------------------------------------------
  /* initialization phase, send the header */
  request.def->command = PUT_HDR;
  request.def->bufsize = append(&request.buf, request.def->bufsize, header.def, sizeof(headerdef_t));
  request.def->bufsize = append(&request.buf, request.def->bufsize, header.buf, header.def->bufsize);

  fprintf(stderr,"csignalproxy: Attempting to open connection to buffer....");
  while ( ((serverfd = open_connection(buffhost.name,buffhost.port)) < 0) & (exitExpt==0) ){
	 fprintf(stderr, "csignalproxy; failed to create socket. waiting\n");
	 usleep(1000000);/* sleep for 1second and retry */
  }
  if ( exitExpt ){ fprintf(stderr,"<ctrl-c> exiting\n"); exit(1); } 
  fprintf(stderr,"done.\nSending header...");
  status = tcprequest(serverfd, &request, &response);
  fprintf(stderr,"done.\n");
  if (verbose>1) fprintf(stderr, "csignalproxy: tcprequest returned %d\n", status);
  if (status) {
	 fprintf(stderr, "csignalproxy: put header error = %d\n",status);
    sig_handler(-1);
  }
  free(request.buf);
  free(request.def);
  free(header.buf);
		
  if (response->def->command != PUT_OK) {
	 fprintf(stderr, "csignalproxy: error in 'put header' request.\n");
    sig_handler(-1);
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
  blocksize   = fsample/BUFFRATE;
  if (verbose>0) fprintf(stderr, "csignalproxy: blocksize = %d\n", blocksize); 
  putdatrequestsize = sizeof(messagedef_t) + sizeof(datadef_t) + WORDSIZE_PROXY*nchans*blocksize;
  requestbuf  = calloc(putdatrequestsize,1);
  /* define the constant part of the send-data request and allocate space for the variable part */
  request.def = requestbuf ;
  /* request.buf = (char*)(request.def) + sizeof(messagedef_t);  */  /* N.B. cast char so pointer math works */
  request.buf = request.def + 1; /* N.B. cool pointer arithemetic trick for above! */
  request.def->version = VERSION;
  request.def->command = PUT_DAT;
  request.def->bufsize = sizeof(datadef_t) + WORDSIZE_PROXY*nchans*blocksize;
  /* setup the data part of the message */
  data.def            = request.buf;
  /*data.buf            = ((char*)data.def) + sizeof(datadef_t); *//* N.B. cast char so pointer math works */
  data.buf            = data.def + 1; /* N.B. cool pointer arithemetic trick for above */
  samples             = (float*)(data.buf);  /* version with correct type */
  /* define the constant part of the data and allocate space for the variable part */
  data.def->nchans    = nchans;
  data.def->nsamples  = blocksize;
  data.def->data_type = DATATYPE_PROXY;
  data.def->bufsize   = WORDSIZE_PROXY * nchans * blocksize;

  /* define where we hold the single sample stuff */
  ampsamples = calloc(nchans * WORDSIZE_PROXY,1);

  //-------------------------------------------------------------------------------
  // Loop sending the data in blocks as it becomes available
  gettimeofday(&starttime,NULL); /* get time we started to compute delay before next sample */
  while ( exitExpt==0 ) {

	 //-------------------------------------------------------------------------------
	 // get the data	 
	 for ( si=0; si<blocksize; si++){ // get a block's worth of samples
		// -- assumes 1 sample per call!
		/* wait until next sample should be generated */
		gettimeofday(&curtime,NULL);
		elapsedusec=(curtime.tv_usec + 1000000.0*curtime.tv_sec) - (starttime.tv_usec + 1000000.0*starttime.tv_sec);
		sampleusec =nsamp*(1000000/fsample); /* time at which to send the next sample */
		if( VERBOSE > 0 ) 
		  fprintf(stderr,"%d) e=%f s=%f delta=%f\n",nsamp,elapsedusec,sampleusec,sampleusec-elapsedusec);
		if( sampleusec>elapsedusec )  {
		  usleep(sampleusec-elapsedusec);/*sleep until next sample should be generated */
		  sleeptime += sampleusec-elapsedusec;
		  sleepcount ++;
		}
		/* get the new data */
		for ( chi=0; chi<nchans-1; chi++) { 
		  ampsamples[chi]=ampsamples[chi]+ (float)(rand()-RAND_MAX/2)/((float)RAND_MAX); 
		}
		/* add the sin channel data */
		ampsamples[chi]= (float)(sinf(nsamp*2.0*(M_PI)*sinFreq/fsample)); 

		// copy the samples into the data buffer, 1 amp sample per buffer sample */
		for (chi=0; chi<nchans; chi++){ samples[(si*nchans)+chi]=ampsamples[chi]; }
		
		nsamp+=1;/*nsamp; */
	 }
	 
	 if ( elapsedusec / 1000000 >= printtime ) {
		fprintf(stderr,"%d %d %d %f (blk,samp,event,sec)\r",nblk,nsamp,0,elapsedusec/1000000.0);
		printtime+=10;
	 }
				
#ifndef SPLITREQ	 
	 status = tcprequest(serverfd, &request, &response);
	 if (status) {
		fprintf(stderr, "csignalproxy: putdata err = %d\n",status);
		sig_handler(-1);
	 }				
	 if (response == NULL || response->def == NULL || response->def->command!=PUT_OK) {
		fprintf(stderr,"csignalproxy: Error when writing samples.\n");
	 }
	 cleanup_message((void**)&response);
	 response=NULL;
#else
	 /* this is an alternative way to send the data where we split 
		 sending the data from waiting for the response.  Thus the
		 sending function does not wait for the buffer to process the
		 message. Preventing lost samples due to buffer delays */
#ifdef READLATE
	 /* 0. Get the response from the previous put-data */
	 /* This shows how you can fire-and-forget the data and only check
		 if the buffer processed it correctly just before you send the next
		 sample packet. */
	 if ( nblk > 0 ) {
		if ( readresponse(serverfd,&responsedef) !=0 ||
			  responsedef.command != PUT_OK ) {
		  fprintf(stderr,"csignalproxy: Error writing samples.\n");		  
		}
	 }
#endif
	 /* 1. Send the data */	 
	 if ((n = bufwrite(serverfd, request.def, putdatrequestsize)) != putdatrequestsize) {
		fprintf(stderr, "write size = %d, should be %d\n", n, putdatrequestsize);
		sig_handler(-1);
	 }
#ifndef READLATE
	 /* N.B. this could happen at a later time */
	 /* 2. Read the response */
	 /* 2.1 Read response message */
	 if ((n = bufread(serverfd, &responsedef, sizeof(messagedef_t))) != sizeof(messagedef_t)) {
		fprintf(stderr, "packet size = %d, should be %d\n", n, sizeof(messagedef_t));
		sig_handler(-1);
	 }
	 /* 2.2 Read response data if needed */
	 if (responsedef.bufsize>0) {
		responsebuf = malloc(responsedef.bufsize);
		if ((n = bufread(serverfd, responsebuf, responsedef.bufsize)) != responsedef.bufsize) {
		  fprintf(stderr, "read size = %d, should be %d\n", n, responsedef.bufsize);
		  sig_handler(-1);
		}
		/* ignore the response and free the memory */
		free(responsebuf); 
	 }
#endif
#endif

	 nblk+=1;
  } /* while(1) */

  // free all the stuff we've allocated
  free(requestbuf);
  free(labelsbuf);
  free(header.def);
  free(ampsamples);

#if defined(__WIN32__) || defined(__WIN64__)
    WSACleanup();
#endif
	 return 0;
}
