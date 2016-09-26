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
	bool systemIsReady = false;

	string serverUptime = "00:00";
	int serverDowntime = 0;
	int museThreadID;
	int ccThreadID;
	Dictionary<int, string> threads;

	UnityBuffer buffer;
	Boolean bufferIsOn = false;
	double[] currentAlphaLat;

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

			//Start Buffer
			logStatus ("Verbinden met buffer...");
			while ( ! bufferIsOn ){
				initializeBuffer ();
				if ( ! bufferIsOn ){
					yield return new WaitForSeconds(1);
				}
			}
		#endif
		logStatus ("Wachten...");
		yield return new WaitForSeconds(1);
		logStatus ("Gereed!");
		systemIsReady = true;
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
		if ( bufferIsOn ){
			buffer.disconnect ();
			bufferIsOn = false;
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
		systemIsReady = false; //signals Unity it is safe to close down as well
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
		if(bufferIsOn && latestEvent.getType().toString()==Config.feedbackEventType)
		{
			IList alphaLatObjects = latestEvent.getValue().array as IList;
			currentAlphaLat = alphaLatObjects.Cast<double>().ToArray();
		}
	}

	public void initializeBuffer(){
		if( buffer == null ) buffer = gameObject.AddComponent<UnityBuffer>();
		buffer.initializeBuffer();
		if(buffer!=null && buffer.bufferIsConnected){
			//Attach the buffer's event handler to the eventsAdded function
			buffer.NewEventsAdded += new BufferChangeEventHandler(eventsAdded);
			bufferIsOn = true;
		}else{
			Debug.Log ("Failed to initialize Unity Buffer Client");
		}
	}

	public void sendEvent(string eventType, string eventData)
	{
		Debug.Log ("Event sent to buffer: " + eventType + ": " + eventData);
		if (buffer != null) {
			buffer.putEvent (eventType, eventData, buffer.getSampleNumberNow ());
		}
	}

	// Interfacing

	public bool getSystemIsReady()
	{
		return systemIsReady;
	}

	public double[] getFeedback()
	{
		return currentAlphaLat;
	}

	public float getAlpha()
	{
		return (float)currentAlphaLat[0];
	}

	public float getBadness()
	{
		//float badness = normalize ((float)currentAlphaLat [1], badnessLimit);
		//badnessFilter = (float) (0.3 * badness + 0.7 * badnessFilter);
		return (float)currentAlphaLat [1];//badnessFilter;
	}

	public float getQualityCh1()
	{
		return (float)currentAlphaLat [currentAlphaLat.Length-2];
	}

	public float getQualityCh2()
	{
		return (float)currentAlphaLat [currentAlphaLat.Length-1];
	}
 }
