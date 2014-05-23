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
#include "buffer.h"
#include "emokit/emokit.h"


static const int FSAMPLE   = 128;
static const int NCHANS    = 17; /* 14 eeg, +counter + 2gyro channels */
static const int BLOCKSIZE = 2;  /* 2 sample per data block */
typedef int emokit_samp_t;
#define DATATYPE_EMOKIT DATATYPE_INT32;
static const int WORDSIZE_EMOKIT=WORDSIZE_INT32;
static const int eeg_zero_offset=2^13;

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


int main(int argc, char *argv[]) {
  struct emokit_device* d;  
  struct emokit_frame c;

  int i, j, k, sample = 0, si=0, status = 0, verbose = 0;
  host_t host;

  /* these represent the acquisition system properties */
  int nchans         = NCHANS;
  int fsample        = FSAMPLE;
  int blocksize      = BLOCKSIZE;
  int channamesize   = 0;
  char *labelsbuf    = NULL;

  /* these are used in the communication and represent statefull information */
  int server             = -1;
  message_t    *request  = NULL;
  message_t    *response = NULL;
  header_t     *header   = NULL;
  data_t       *data     = NULL;
  emokit_samp_t *databuf  = NULL; // for holding the sample info
  event_t      *event    = NULL;
  ft_chunkdef_t chunkdef; // for holding the channel names

  if (argc>2) {
	 sprintf(host.name, "%s", argv[1]);
	 host.port = atoi(argv[2]);
  }
  else {
	 sprintf(host.name, "%s", DEFAULT_HOSTNAME);
	 host.port = DEFAULT_PORT;
  }

  if (verbose>0) fprintf(stderr, "emokit2ft: host.name =  %s\n", host.name);
  if (verbose>0) fprintf(stderr, "emokit2ft: host.port =  %d\n", host.port);

  //-------------------------------------------------------------------------------
  // open the emotive device
  d = emokit_create();
  printf("Current epoc devices connected: %d\n", emokit_get_count(d, EMOKIT_VID, EMOKIT_PID));
  status = emokit_open(d, EMOKIT_VID, EMOKIT_PID, 1);
  if(status != 0)
	 {
		printf("CANNOT CONNECT: %d\n", status);
		return 1;
	 }
  printf("Connected\n");

  //-------------------------------------------------------------------------------
  /* allocate the elements that will be used in the buffer communication */
  request      = malloc(sizeof(message_t));
  request->def = malloc(sizeof(messagedef_t));
  request->buf = NULL;
  request->def->version = VERSION;
  request->def->bufsize = 0;

  header      = malloc(sizeof(header_t));
  header->def = malloc(sizeof(headerdef_t));
  header->buf = NULL; /* header buf contains the channel names */
  //header->buf = labels;

  data      = malloc(sizeof(data_t));
  data->def = malloc(sizeof(datadef_t));
  data->buf = NULL;

  event      = malloc(sizeof(event_t));
  event->def = malloc(sizeof(eventdef_t));
  event->buf = NULL;

  /* define the header */
  header->def->nchans    = nchans;
  header->def->nsamples  = 0;
  header->def->nevents   = 0;
  header->def->fsample   = fsample;
  header->def->data_type = DATATYPE_EMOKIT;
  header->def->bufsize   = 0;
  FREE(header->buf);
		
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
  header->def->bufsize = append(&header->buf, header->def->bufsize, &chunkdef, sizeof(ft_chunkdef_t));
  header->def->bufsize = append(&header->buf, header->def->bufsize, labelsbuf, chunkdef.size);

  //-------------------------------------------------------------------------------
  /* initialization phase, send the header */
  request->def->command = PUT_HDR;
  request->def->bufsize = append(&request->buf, request->def->bufsize, header->def, sizeof(headerdef_t));
  request->def->bufsize = append(&request->buf, request->def->bufsize, header->buf, header->def->bufsize);

  server = open_connection(host.name, host.port);
  status = tcprequest(server, request, &response);
  if (verbose>0) fprintf(stderr, "emokit2ft: clientrequest returned %d\n", status);
  if (status) {
	 fprintf(stderr, "emokit2ft: put header error\n");
	 exit(1);
  }
  free(request->def);
  free(request);
		
  FREE(response->buf);
  if (response->def->command != PUT_OK) {
	 fprintf(stderr, "emokit2ft: error in 'put header' request.\n");
	 exit(1);
  }
  free(response->def);
  free(response);

  /* add a small pause between writing header + first data block */
  usleep(200000);


  //-------------------------------------------------------------------------------
  /* define the constant part of the data and allocate space for the variable part */
  data->def->nchans    = nchans;
  data->def->nsamples  = blocksize;
  data->def->data_type = DATATYPE_EMOKIT;
  data->def->bufsize   = WORDSIZE_EMOKIT * nchans * blocksize;
  FREE(data->buf);
  databuf              = malloc(WORDSIZE_EMOKIT*nchans*blocksize);
  data->buf            = databuf;

  //-------------------------------------------------------------------------------
  // Loop sending the data in blocks as it becomes available
  while (1) {

	 //-------------------------------------------------------------------------------
	 for ( si=0; si<blocksize; si++){ // get a block's worth of samples
		sample++;
		// wait until new data to get, 4 milliSec N.B. inter-sample ~= 8 milliSec
		while( emokit_read_data(d)<=0 ) { usleep(4000); } 
		/* get the new data */
		c = emokit_get_next_frame(d);
		if ( verbose>0 ) {
		  printf("%5d) %5d\t%5d\t%5d\t%5d\t%5d\t%5d\n", sample, c.counter, c.gyroX, c.gyroY, c.F3, c.FC6, c.P7);  
		  fflush(stdout);
		}
		// copy the samples into the data buffer, in the order we
		// *said* they should be
		databuf[(si*nchans)+0] =c.counter;
		databuf[(si*nchans)+1] =c.AF3 - eeg_zero_offset;
		databuf[(si*nchans)+2] =c.F7  - eeg_zero_offset;
		databuf[(si*nchans)+3] =c.F3  - eeg_zero_offset;
		databuf[(si*nchans)+4] =c.FC5 - eeg_zero_offset;
		databuf[(si*nchans)+5] =c.T7  - eeg_zero_offset;
		databuf[(si*nchans)+6] =c.P7  - eeg_zero_offset;
		databuf[(si*nchans)+7] =c.O1  - eeg_zero_offset;
		databuf[(si*nchans)+8] =c.O2  - eeg_zero_offset;
		databuf[(si*nchans)+9] =c.P8  - eeg_zero_offset;
		databuf[(si*nchans)+10]=c.T8  - eeg_zero_offset; 
		databuf[(si*nchans)+11]=c.FC6 - eeg_zero_offset;
		databuf[(si*nchans)+12]=c.F4  - eeg_zero_offset;
		databuf[(si*nchans)+13]=c.F8  - eeg_zero_offset;
		databuf[(si*nchans)+14]=c.AF4 - eeg_zero_offset;
		databuf[(si*nchans)+15]=c.gyroX;
		databuf[(si*nchans)+16]=c.gyroY;
	 }


	 //-------------------------------------------------------------------------------
	 /* create the request */
	 /* TODO: re-use the request structures rather than re-allocating
		 every time */
	 request      = malloc(sizeof(message_t));
	 request->def = malloc(sizeof(messagedef_t));
	 request->buf = NULL;
	 request->def->version = VERSION;
	 request->def->command = PUT_DAT;
	 request->def->bufsize = 0;
	 request->def->bufsize = append(&request->buf, request->def->bufsize, data->def, sizeof(datadef_t));
	 request->def->bufsize = append(&request->buf, request->def->bufsize, data->buf, data->def->bufsize);
				
	 status = tcprequest(server, request, &response);
	 if (verbose>0) fprintf(stderr, "emokit2ft: clientrequest returned %d\n", status);
	 if (status) {
		fprintf(stderr, "emokit2ft: err3\n");
		exit(1);
	 }				
	 cleanup_message((void**)&request);
				
	 if (response == NULL || response->def == NULL || response->def->command!=PUT_OK) {
		fprintf(stderr, "Error when writing samples.\n");
	 }
	 cleanup_message((void**)&response);
  } /* while(1) */

  // free all the stuff we've allocated
  free(labelsbuf);
  free(databuf);
  cleanup_message((void**)&header);
  cleanup_message((void**)&event);
  cleanup_message((void**)&data);
}

