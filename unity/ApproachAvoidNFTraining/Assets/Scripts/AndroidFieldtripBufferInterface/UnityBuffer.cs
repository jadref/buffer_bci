using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;
using System.IO;
using System.Threading;
using FieldTrip.Buffer;

//A delegate to be used as an Event Handler for changes in the buffer that need to notify other objects
public  delegate void BufferChangeEventHandler(UnityBuffer buffer, EventArgs e);

public class UnityBuffer : MonoBehaviour {

	public string hostname = null;
	public int port = 1972;
	public int storedSamples;
	public int nChans;
	public float fSample;
	public bool newDataIn=false;
	public bool storeData=false; // Flag if we store new data in our internal buffer?
	public int dataPacketsLost=0;
	public int bufferEventsMaxCapacity = 100;
	public int MAXDATASAMPLES=100000;
	public int MINUPDATEINTERVAL_ms=100; // at most update every 10Hz
	private int DATAUPDATEINTERVAL_SAMP=1;
	public bool bufferConnectionInitialized=false;
	public bool bufferIsConnected = false;

	private Header hdr;
	private BufferClient bufferClient;
	private Thread bufferUpdateThread;
	private int latestBufferSample=-1;
	private int latestCapturedSample=-1;
	private int timeout_ms = 1; //In msecs. This blocks the Update of the UnityBuffer so this gives the maximum fps the app will run so keep it a low number unless blocking is required
	private float lastUpdateTime=0; //in sec, time we last did a buffer.poll()
	private object data;							//Holds the latest data of the fieldtrip buffer between the two last updates of the fieldtrip buffer
	private int lastNumberOfEvents;
	private int latestNumberOfEventsInBuffer;
	private List<BufferEvent> bufferEvents; //Holds the last bufferEventsMaxCapacity events as they are added to the fieldtrip buffer
	private BufferTimer bufferTimer;


	//An event that notifies when new data have been captured in the buffer
	public event BufferChangeEventHandler NewDataCaptured=null;

	//An event that notifies when new events have been put in the buffer
	public event BufferChangeEventHandler NewEventsAdded=null;

	protected virtual void OnNewDataCaptured(EventArgs e){
		if(NewDataCaptured!=null){
			NewDataCaptured(this, e);
		}
	}

	protected virtual void OnNewEventsAdded(EventArgs e){
		if(NewEventsAdded!=null){
			NewEventsAdded(this, e);
		}
	}

	private void Start(){
	}


	// when made visible
	void OnEnable(){

	}
	// called when the app is made invisible..
	void OnDisable() {
		stopThread();
		Debug.Log ("disabling unity buffer");
	}

	void Awake () {
		Debug.Log ("Awoke UnityBuffer");
		bufferClient = new BufferClient();
		bufferEvents = new List<BufferEvent>();

		latestCapturedSample = -1;
		newDataIn=false;
		dataPacketsLost = 0;
		lastNumberOfEvents = -1;
		latestNumberOfEventsInBuffer =-1;
	}

	public static string GetLocalIPAddress()
	{
		System.Net.IPHostEntry host;
		string localIP = "";
		host = System.Net.Dns.GetHostEntry(System.Net.Dns.GetHostName());

		foreach (System.Net.IPAddress ip in host.AddressList)
		{
			localIP = ip.ToString();

			if (ip.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
			{
				break;
			}
			else
			{
				localIP = null;
			}
		}

		return localIP;
	}

	public void initializeBuffer(){
		if (hostname == null) {
			//hostname = GetLocalIPAddress ();
			hostname = "127.0.0.1";
		}
		Debug.Log ("Connecting to " + hostname + ":" + port);
		if (!bufferClient.isConnected()){ // attempt to re-connect
			bufferClient.connect (hostname, port); 
		}
		if(bufferClient.isConnected()){
			Debug.Log("Connected to "+hostname+":"+port+" succeeded");
			hdr = bufferClient.getHeader();
			if(bufferClient.errorReturned == BufferClient.BUFFER_READ_ERROR){
				Debug.Log("No header on "+hostname+":"+port+" failed");
				bufferConnectionInitialized = false;
				return;
			}
			latestBufferSample = hdr.nSamples;
			lastNumberOfEvents = hdr.nEvents;
			nChans = hdr.nChans;
			fSample = hdr.fSample;
			if ( storeData ) { initializeData(); }
			bufferTimer = new BufferTimer(fSample);
			Debug.Log("Got valid header on "+hostname+":"+port);
			// compute the min-update-interval in samples
			if ( MINUPDATEINTERVAL_ms>0 ) {
				DATAUPDATEINTERVAL_SAMP = (int)(MINUPDATEINTERVAL_ms * 1000.0 / hdr.fSample) ;
				if ( DATAUPDATEINTERVAL_SAMP<1 ) DATAUPDATEINTERVAL_SAMP=1;
			}
			bufferConnectionInitialized = true;
			if ( bufferUpdateThread==null  ){
				bufferUpdateThread = new Thread (run){ Name = "BufferUpdateThread" };
				bufferUpdateThread.Start (); // start the buffer-monitoring thread
			}
		}else{
			Debug.Log("Connection to "+hostname+":"+port+" failed");
			bufferConnectionInitialized = false;
			return;
		}
	}



	private void initializeData(){
		Debug.Log ("Initialize Data");
		int dataType = hdr.dataType;
		storedSamples = hdr.nSamples;
		if (storedSamples*nChans > MAXDATASAMPLES) storedSamples = MAXDATASAMPLES/nChans;
		switch(dataType){
			case DataType.CHAR:
				data = new char[storedSamples, nChans];
			break;

			case DataType.INT8:
				goto case DataType.UINT8;
			case DataType.UINT8:
			data = new byte[storedSamples, nChans];
			break;

			case DataType.INT16:
				goto case DataType.UINT16;
			case DataType.UINT16:
			data = new short[storedSamples, nChans];
			break;

			case DataType.INT32:
			 goto case DataType.UINT32;
			case DataType.UINT32:
			data = new int[storedSamples, nChans];
			break;

			case DataType.INT64:
				goto case DataType.UINT64;
			case DataType.UINT64:
			data = new long[storedSamples, nChans];
			break;

			case DataType.FLOAT32:
			data = new float[storedSamples, nChans];
			break;

			case DataType.FLOAT64:
			data = new double[storedSamples, nChans];
			break;

			default:
				Debug.LogError("Uknown data format received from Buffer");
			break;
		}
	}


	public void disconnect(){
		if(bufferConnectionInitialized){
			bufferClient.disconnect();
			bufferConnectionInitialized = false;
		}
	}

	private bool running;
	private  System.Diagnostics.Stopwatch elapsedsw;
	void stopThread(){
		running = false;
	}
	void run(){
		elapsedsw = System.Diagnostics.Stopwatch.StartNew ();
		running = true;
		while (running) {
			if (elapsedsw.ElapsedMilliseconds > MINUPDATEINTERVAL_ms) {
				updateBuffer ();
				elapsedsw.Reset (); 
				elapsedsw.Start ();
			} else {
				Thread.Sleep (MINUPDATEINTERVAL_ms);
			}
		}
	}

	public bool bufferClientIsConnected(){
		if (bufferClient != null && bufferConnectionInitialized && bufferIsConnected) {
			return bufferClient.isConnected ();
		}
		return false;
	}

	// N.B. this function is called EVERY VIDEO FRAME!..... so should be as fast as possible...
	// TODO: the buffer communication should really move to be in a seperate thread!!!
	void updateBuffer () {
		if( bufferClient!=null && bufferConnectionInitialized ){
			//int dataTrigger=-1;
			//if ( storeData ) {
			//	dataTrigger = latestCapturedSample+DATAUPDATEINTERVAL_SAMP;
			//}
			SamplesEventsCount count = null;
			bufferIsConnected = bufferClient.isConnected ();
			if ( !bufferIsConnected ) { // if we are not connected try to re-connect..
				Debug.LogError("Buffer connection closed..... trying to reconnect!");
				bufferClient.reconnect ();
				return;
			}
			try { 
				count = bufferClient.poll ();
			} catch { // poll failed.... why?
				Debug.LogError("Poll failed.... waiting for valid response!");
				return;
			}
			latestNumberOfEventsInBuffer = count.nEvents;
			latestBufferSample = count.nSamples;
			// reset if we have been re-awoken
			if ( latestCapturedSample<0 ) latestCapturedSample=latestBufferSample;
			if ( lastNumberOfEvents<0 ) lastNumberOfEvents=latestNumberOfEventsInBuffer;
			if ( latestBufferSample < latestCapturedSample ) {
				Debug.LogError("Buffer restart detected .. skipping everything before now...");
				bufferTimer.reset();
				latestCapturedSample = latestBufferSample;
				lastNumberOfEvents = latestNumberOfEventsInBuffer;
			}
			bufferTimer.addSampleToRegression(latestBufferSample);//Updates the bufferTimer with the new samples.

			// Loop ot push events to the event stream
			while(lastNumberOfEvents < latestNumberOfEventsInBuffer){
				try { // Watch out can miss events if we are too slow...
				    bufferEvents.Add(bufferClient.getEvents(lastNumberOfEvents, lastNumberOfEvents)[0]);
				} catch ( IOException ex ) {
				}
				lastNumberOfEvents +=1;
				if(bufferEvents.Count > bufferEventsMaxCapacity){// Implement a ring-buffer for the events we store...
					bufferEvents.RemoveAt(0);
				}
				OnNewEventsAdded(EventArgs.Empty);//This notifies anyone who's listening that there had been an extra event added in the buffer
			}
			lastNumberOfEvents=latestNumberOfEventsInBuffer;

			// push new data into the data event stream
			if(latestBufferSample>latestCapturedSample){
				if ( storeData ) { // if we should track and store the data
					storedSamples = latestBufferSample - latestCapturedSample;
					if (storedSamples*nChans > MAXDATASAMPLES) storedSamples = MAXDATASAMPLES/nChans;
					data = bufferClient.getFloatData(latestBufferSample-storedSamples,latestBufferSample-1); //TO DO: The getFloat needs to change according to the buffers type of data
					OnNewDataCaptured(EventArgs.Empty); //That notifies anyone who's listening that data have been updated in the buffer
					if(newDataIn){
						dataPacketsLost+=1;
					}else{
						newDataIn = true;
					}
				}
			}
			latestCapturedSample = latestBufferSample;
		}
	}



	public T[,] getData<T>(){
		return (T[,])data;
	}

	public BufferEvent getLatestEvent(){
		return bufferEvents[bufferEvents.Count-1];
	}

	public int getCurrentSampleNumber(){
		return latestBufferSample;
	}
	public int getCurrentEventsNumber(){
		return lastNumberOfEvents;
	}

	public int getSampleNumberNow(){
		if ( bufferTimer!=null ) return bufferTimer.getSampleNow();
		return -1;
	}

	public int getSampleNumberAtTime(DateTime time){
		if (bufferTimer!=null) return bufferTimer.getSampleAtTime(time);
		return -1;
	}


	public void putEvent<T>(string type, T val){
		putEvent<T> (type, val, getSampleNumberNow());
	}
	public void putEvent<T>(string type, T val, int sample){

		if (!bufferClient.isConnected ()) { // re-connect if the connection was dropped
			Debug.LogError("Buffer Connection reset detected!  reconnecting........");
			bufferClient.reconnect ();
			if (!bufferClient.isConnected ()) {
				
			}
		}


		Type cls = typeof(T);
		string typeOfVal = cls.FullName;
		if (cls.IsArray) {
			Type elc = cls.GetElementType();
			if (!elc.IsPrimitive) return;

			if(typeOfVal == "System.String[]"){
				string[] temp = (string[])(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Byte[]"){
				byte[] temp = (byte[])(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Int16[]"){
				short[] temp = (short[])(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Int32[]"){
				int[] temp = (int[])(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Int64[]"){
				long[] temp = (long[])(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Single[]"){
				float[] temp = (float[])(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Double[]"){
				double[] temp = (double[])(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else {
				Debug.LogError("Unknown/Unsupported value type");
			}
		}else{
			if(typeOfVal == "System.String"){
				string temp = (string)(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Byte"){
				byte temp = (byte)(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Int16"){
				short temp = (short)(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Int32"){
				int temp = (int)(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Int64"){
				long temp = (long)(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Single"){
				float temp = (float)(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else if(typeOfVal == "System.Double"){
				double temp = (double)(object)val;
				BufferEvent ev = new BufferEvent(type, temp, sample);
				bufferClient.putEvent(ev);
			} else {
				Debug.LogError("Unknown/unsupported value type");
			}
		}
	}


	public void printHeaderInfo(){
		Debug.Log("#channels....: "+hdr.nChans);
		Debug.Log("#samples.....: "+hdr.nSamples);
		Debug.Log("#events......: "+hdr.nEvents);
		Debug.Log("Sampling Freq: "+hdr.fSample);
		Debug.Log("data type....: "+hdr.dataType);

		for (int n=0;n<nChans;n++) {
			if (hdr.labels[n] != null) {
				Debug.Log("Channel number " + n + ": " + hdr.labels[n]);
			}
		}
	}

}

