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

#define DEFAULTHOSTNAME localhost
#define DEFAULTPORT     1972
#define WAITTIMEOUT     5000

int   exitExpt=0;
/* if get a ctrl-c then exit experiment at next good point. */
void SIGINT_handler(int sig){
  fprintf(stderr,"Caught <ctrl-c> stopping...");
  exitExpt=1;
}

int main(int argc, char *argv[]) {
  host_t buffhost;

  /* these are used in the communication and represent statefull information */
  int serverfd   = -1;
  int status   =0;
  message_t    request  ;
  message_t    *response ;
  message_t    *getevtresponse;
  messagedef_t requestdef;
  header_t     header;
  waitdef_t waitdef;
  samples_events_t sampevents; 
  int          nEvents = 0;
  event_t      event;
  eventsel_t   eventsel;
  eventdef_t   echoeventdef;
  int   exitExpt=0;
  int offset = 0;

  /* Note on WINDOWs you *must* do this for socket functions to work */
  // startup WinSock in Windows
#if defined(__WIN32__) || defined(__WIN64__)
  WSADATA wsa_data;
  WSAStartup(MAKEWORD(1,1), &wsa_data);
#endif    
  signal(SIGINT, SIGINT_handler); /* register signal handler for ctrl-c */
  
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


  /* open the TCP socket */
  while ( (serverfd = open_connection(buffhost.name,buffhost.port)) < 0 ){
	 fprintf(stderr, "cclient; failed to create socket. waiting\n");
	 usleep(1000000);/* sleep for 1second and retry */
  }
    
  //-------------------------------------------------------------------------------
  /* get the header information */
  requestdef.version=VERSION;
  requestdef.bufsize=0;
  requestdef.command=GET_HDR;
  request.def = &requestdef;
  while ( (status = tcprequest(serverfd, &request, &response)) || (response->def->command!=GET_OK) ){
	 fprintf(stderr, "cclient: invalid header response = %d\n",status);
	 usleep(1000000);/* sleep for 1second and retry */
  }
  /* print the recieved header */
  header.def = (headerdef_t *)response->buf;
  header.buf = (char *) response->buf+sizeof(headerdef_t);
  fprintf(stderr, "headerdef.nchans    = %u\n", header.def->nchans);
  fprintf(stderr, "headerdef.nsamples  = %u\n", header.def->nsamples);
  fprintf(stderr, "headerdef.nevents   = %u\n", header.def->nevents);
  fprintf(stderr, "headerdef.fsample   = %f\n", header.def->fsample);
  fprintf(stderr, "headerdef.data_type = %u\n", header.def->data_type);
  fprintf(stderr, "headerdef.bufsize   = %u\n", header.def->bufsize);
  /* free the response definition, but *not* the buf as that holds the header info */
  FREE(response->def); FREE(response);
  
  nEvents=header.def->nevents;
  while ( exitExpt==0 ) {

	 /* wait until we have more events to process */
	 waitdef.threshold.nsamples = -1;
	 waitdef.threshold.nevents  = nEvents;
	 waitdef.milliseconds       = WAITTIMEOUT;
	 requestdef.command = WAIT_DAT;
	 requestdef.bufsize = sizeof(waitdef_t);
	 request.def        = &requestdef;
	 request.buf        = &waitdef;	 
	 if ( (status=tcprequest(serverfd, &request, &response)) || (response->def->command!=WAIT_OK) ) {
		fprintf(stderr, "cclient: invalid wait-data response = %d,%d\n",status,response->def->command);
		exit(-1);
	 }
	 sampevents = *((samples_events_t *) response->buf); /* *copy* of the response value */
	 FREE(response->buf); FREE(response->def); FREE(response);/* free the memory allocated for the response */


	 if ( sampevents.nevents == nEvents ) {
		fprintf(stderr,"wait timeout\n");
	 } else if ( sampevents.nevents < nEvents ) {
		fprintf(stderr,"Buffer reset detected!");
		nEvents=sampevents.nevents;
	 } else {  /* new events to process */
		
		/* get the events we haven't processed yet */
		eventsel.begevent  = nEvents;
		eventsel.endevent  = sampevents.nevents-1; /* N.B. -1! */
		requestdef.command = GET_EVT;
		requestdef.bufsize = sizeof(eventsel_t);
		request.def        = &requestdef;
		request.buf        = &eventsel;
		if ( (status=tcprequest(serverfd, &request, &getevtresponse)) || (getevtresponse->def->command!=GET_OK) ) {
		  fprintf(stderr, "cclient: invalid get-events response = %d,%d\n",status,response->def->command);
		  exit(-1);
		}
		nEvents = sampevents.nevents; /* update number of events processed */

		/* process the returned events */
		/* loop over the returned events */ 
		for (offset=0; offset<getevtresponse->def->bufsize; offset+=sizeof(eventdef_t)+event.def->bufsize){
		  /* while (offset<response.bufsize) { */

		  /* extract the event info */
		  event.def = (eventdef_t*)((char*)getevtresponse->buf+offset);
		  event.buf = (char*)getevtresponse->buf+offset+sizeof(eventdef_t);


		  /* test for special event types we should ignore */
		  if ( event.def->type_type == DATATYPE_CHAR ){
			 if (        strncmp(event.buf,"echo",sizeof("echo"))==0 ) { 
				continue; 				/* don't echo echo events */
			 } else if ( strncmp(event.buf,"exit",sizeof("exit"))==0 ) {
				exitExpt=1;          /* quit for exit events */
				continue; 				/* don't echo exit events */
			 }
		  }		  

		  /* print debug info about this event */
		  fprintf(stderr,"%d)",sampevents.nsamples);
		  if (event.def->type_type == DATATYPE_CHAR ){
			 fprintf(stderr,"t:%.*s",event.def->type_numel, (char *) event.buf);
		  }else{
			 fprintf(stderr,"t:unknown");
		  }
		  if ( event.def->value_type == DATATYPE_CHAR) {
			 fprintf(stderr," v:%.*s\n",event.def->value_numel, (char *) event.buf + event.def->type_numel);
		  }else{
			 fprintf(stderr," v:unknown\n");
		  }

		  /* not an ignored event, so echo this event */

		  /* setup the echo send event request */
		  requestdef.command = PUT_EVT;
		  requestdef.bufsize = 0;
		  request.def        = &requestdef;
		  request.buf        = NULL;
		  /* modify the recieved event definition to reflect the echo event */
		  echoeventdef = *(event.def); /* copy definition from the input event */
		  echoeventdef.type_type  = DATATYPE_CHAR;
		  echoeventdef.type_numel = sizeof("echo");
		  echoeventdef.bufsize    = echoeventdef.type_numel*wordsize_from_type(echoeventdef.type_type) 
			 + echoeventdef.value_numel*wordsize_from_type(echoeventdef.value_type);
		  /* make a new event buf which contains the new event type and a copy of the value */
		  /* N.B. append *allocates* new ram, so be sure to free it afterwards */
		  /* first add the event definition */
		  requestdef.bufsize = append(&request.buf, requestdef.bufsize, &echoeventdef, sizeof(echoeventdef));
		  /* then the event type information, which is now just the string "echo" */
		  requestdef.bufsize = append(&request.buf, requestdef.bufsize, "echo", sizeof("echo"));
		  /* then the event value information, which is copied from the received event */
		  requestdef.bufsize = append(&request.buf, requestdef.bufsize,
										 (char *)event.buf + event.def->type_numel*wordsize_from_type(event.def->type_type), 
												event.def->value_numel*wordsize_from_type(event.def->value_type));
		  /* send the echo event */
		  if ( (status=tcprequest(serverfd, &request, &response)) || (response->def->command!=PUT_OK) ) { 
			 fprintf(stderr, "cclient: invalid put-event response = %d,%d\n",status,response->def->command);
			 exit(-1);
		  }
		  FREE(request.buf); FREE(response->def); FREE(response); /* deallocate the buffer */
		}
		/* deallocate memory used to store the received events */
		FREE(getevtresponse->buf);FREE(getevtresponse->def); FREE(getevtresponse);
	 }		
  }

  FREE(header.def); /* deallocate memory used for storing the header info */

  /* shutdown windows sockets correctly */
#if defined(__WIN32__) || defined(__WIN64__)
  WSACleanup();
#endif
  return(0);
}
