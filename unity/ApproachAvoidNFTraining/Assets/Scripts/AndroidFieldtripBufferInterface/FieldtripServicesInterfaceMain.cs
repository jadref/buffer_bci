using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;
using System.Runtime.InteropServices;
using FieldTrip.Buffer;
using UnityEngine.UI;
using System.Linq;

public class FieldtripServicesInterfaceMain : MonoBehaviour {

	bool androidDevice = false;
	bool updateStatus = false;
	private bool _systemIsReady = false;

	string serverUptime = "00:00";
	int serverDowntime = 0;
	int museThreadID;
	int ccThreadID;
	Dictionary<int, string> threads;

	UnityBuffer buffer;
	double[] currentAlphaLat;
	double[] currentrawpred;

	public bool verbose;
	public UnityEngine.UI.Text StatusText;
	public GameObject LoadingButton;

	void Start () {
		#if UNITY_ANDROID && !UNITY_EDITOR
		Screen.sleepTimeout = (int)SleepTimeout.NeverSleep;
		androidDevice = true;
		#endif

		currentAlphaLat = new double[] {0, 0, 0, 0};
	}

	// called when the app is made invisible..
	void OnDisable() {
		Debug.Log ("disable");
	}

	// called when frame is made visible
	void OnEnable() {
		Debug.Log ("enable");
	}

	// Maintenance

	private void logStatus(string status)
	{
		Debug.Log ("Status: "+status);
		if (updateStatus) {
			StatusText.text = status;
		}
	}

	private float normalize(float input, float limit)
	{
		if (input > limit) {
			return 1.0f;
		} else {
			return input/limit;
		}
	}

	// System Startup and Shutdown

	public IEnumerator startServerAndAllClients(){
		updateStatus = true; // show status in loading screen
		#if UNITY_ANDROID && !UNITY_EDITOR
			//Start Server
			logStatus ("Server opstarten...");
			Debug.Log ("Started: " + FieldtripServicesControlerInterface.startServer ());
			yield return new WaitForSeconds (4);//These waits are for the Services to have time to pass around their intents. Used to be 10.

			//Start Clients
			logStatus ("Client opstarten...");
			Debug.Log ("Started: " + FieldtripServicesControlerInterface.startClients ());
			yield return new WaitForSeconds (2);

			for ( int i =0 ; i < Config.bufferClientThreadList.Length; i++ ) {
				string clientname=Config.bufferClientThreadList[i];
				logStatus(clientname + "\nopstarten");
				FieldtripServicesControlerInterface.startThread(clientname);
				yield return new WaitForSeconds (1);//These waits are for the Services to have time to pass around their intents.
			}

		#endif
		//Start Buffer
		logStatus ("Verbinden met buffer...");
		bool inited = false;
		while ( ! inited ){
			inited = initializeBuffer ();
			if ( ! inited ){
				yield return new WaitForSeconds(1);
			}
		}

		logStatus ("Wachten...");
		yield return new WaitForSeconds(1);
		logStatus ("Gereed!");
		updateStatus = false;
		LoadingButton.SetActive (true);
	}


	public IEnumerator stopClientAndServer(){
		#if UNITY_ANDROID && !UNITY_EDITOR
			//Stop Threads
			for ( int i =0 ; i < Config.bufferClientThreadList.Length; i++ ) {
				string clientname=Config.bufferClientThreadList[i];
				logStatus(clientname + "\nstoppen");
				FieldtripServicesControlerInterface.stopThread(clientname);
				yield return new WaitForSeconds (1);//These waits are for the Services to have time to pass around their intents.
			}
		#endif

		//Stop buffer
		logStatus ("Buffer stoppen...");
		if ( buffer != null && _systemIsReady ){
			buffer.disconnect ();
		}
		yield return new WaitForSeconds (1);

		#if UNITY_ANDROID && !UNITY_EDITOR
			//Stop Clients
			logStatus ("Client stoppen...");
			Debug.Log ("Stopped: " + FieldtripServicesControlerInterface.stopClients ());
			yield return new WaitForSeconds (2);

			//Stop Server
			logStatus ("Server stoppen...");
			Debug.Log ("Stopped: " + FieldtripServicesControlerInterface.stopServer ());
			yield return new WaitForSeconds (2);
     	#endif

      	//Update Status
		_systemIsReady = false; //signals Unity it is safe to close down as well
		logStatus ("Systeem offline");
	}

	public IEnumerator refreshClientAndServer(){
		logStatus("Client en server herstarten...");
		yield return StartCoroutine (stopClientAndServer ());
		yield return StartCoroutine (startServerAndAllClients());
	}


	// Buffer
	// TODO: This is a horrible combination of service management and buffer/event tracking... should separate into different pieces.
	private void eventsAdded(UnityBuffer _buffer, EventArgs e){
		
		BufferEvent latestEvent = _buffer.getLatestEvent();
		if (latestEvent.getType ().toString () == Config.feedbackEventType) {
			IList alphaLatObjects = latestEvent.getValue ().array as IList;
			currentAlphaLat = alphaLatObjects.Cast<double> ().ToArray ();
		} else if (latestEvent.getType ().toString () == Config.rawfeedbackEventType) {
			IList rawpred = latestEvent.getValue ().array as IList;
			currentrawpred = rawpred.Cast<double> ().ToArray ();
		}
	}

	public int getCurrentSampleNumber(){
		if ( systemIsReady() ) {
			return buffer.getCurrentSampleNumber ();
		} else {
			return -1;
		}
	}
	public int getCurrentEventsNumber(){
		if ( systemIsReady() ) {
			return buffer.getCurrentEventsNumber ();
		} else {
			return -1;
		}
	}

	public bool initializeBuffer(){
		if( buffer == null ) buffer = gameObject.AddComponent<UnityBuffer>();
		if (!systemIsReady ()) {
			buffer.initializeBuffer ();
		}
		if(systemIsReady()){
			//Attach the buffer's event handler to the eventsAdded function
			buffer.NewEventsAdded += new BufferChangeEventHandler(eventsAdded);
			return true;
		}else{
			Debug.Log ("Failed to initialize Unity Buffer Client");
			return false;
		}
	}

	public void sendEvent(string eventType, string eventData)
	{
		if ( systemIsReady() ) {
			buffer.putEvent (eventType, eventData);
			Debug.Log ("Event sent to buffer: " + eventType + ": " + eventData);
		} else {
			Debug.Log ("Error: Could not sent event to buffer: " + eventType + ": " + eventData);
		}
	}

	// Interfacing
	public bool systemIsReady()
	{
		if (buffer != null && buffer.bufferConnectionInitialized && buffer.bufferIsConnected && buffer.bufferClientIsConnected ()) {
			_systemIsReady = true;
		} else {
			_systemIsReady = false;
		}
		return _systemIsReady;
	}

	public double[] getFeedback()
	{
		return currentAlphaLat;
	}

	public float getAlpha()
	{
		if (currentAlphaLat.Length > 0) { 
			return (float)currentAlphaLat [0];
		} else {
			return -1;
		}
	}

	public float getBadness()
	{
		//float badness = normalize ((float)currentAlphaLat [1], badnessLimit);
		//badnessFilter = (float) (0.3 * badness + 0.7 * badnessFilter);
		if (currentAlphaLat.Length > 1) { 
			return (float)currentAlphaLat [1];//badnessFilter;
		} else {
			return 1e6f;
		}
	}

	public float getQualityCh1()
	{
		if (currentrawpred!=null && currentrawpred.Length > 2) { // use raw predictions if available, fall back on baselined if not
			return (float)currentrawpred [currentrawpred.Length - 2];
		} else if (currentAlphaLat.Length > 2) { 
			return (float)currentAlphaLat [currentAlphaLat.Length - 2];
		} else {
			return -1;
		}
	}

	public float getQualityCh2()
	{
		if (currentrawpred!=null && currentrawpred.Length > 3) {
			return (float)currentrawpred [currentrawpred.Length - 1];
		} else if (currentAlphaLat.Length > 3) {
			return (float)currentAlphaLat [currentAlphaLat.Length - 1];
		} else {
			return -1;
		}
	}
 }
