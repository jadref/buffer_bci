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
	bool inMenu = true;
	bool updateServer = false;
	bool clientIsConnected = false;
	bool systemIsReady = false;

	string serverUptime = "00:00";
	int serverDowntime = 0;
	int museThreadID;
	int ccThreadID;
	Dictionary<int, string> threads;

	UnityBuffer buffer;
	Boolean bufferIsOn = false;
	BufferEvent latestEvent;
	BufferEvent previousEvent;
	double[] currentAlphaLat;

	float badnessFilter;
	float badnessLimit;
	float qualityLimit;

	public bool verbose;
	public Image ServerStatusIcon;
	public Image MuseStatusIcon;
	public Image SignalAStatusIcon;
	public Image SignalBStatusIcon;
	public Button StatusButton;

	private Color themeGreen = new Color (0.42f, 0.56f, 0.36f, 1.0f);
	private Color themeRed = new Color (0.79f, 0.38f, 0.27f, 1.0f);
	private ColorBlock buttonColors = ColorBlock.defaultColorBlock;

	void Start () {
		#if UNITY_ANDROID && !UNITY_EDITOR
		FieldtripServicesControlerInterface.Initialize();
		androidDevice = true;
		#endif
		badnessFilter = 0.0f;
		badnessLimit = Config.badnessLimit;
		qualityLimit = Config.qualityLimit;

		latestEvent = new BufferEvent("",0.0f,0);
		previousEvent = new BufferEvent("",0.0f,0);
		currentAlphaLat = new double[] {0, 0, 0, 0};
		resetStatus();
	}

	void Update(){
		#if UNITY_ANDROID && !UNITY_EDITOR
		if (androidDevice && inMenu) {
			if (updateServer){
				string serverUptimeNew = FieldtripServicesControlerInterface.getBufferUptime ();
				if (serverUptimeNew != serverUptime) {
					serverUptime = serverUptimeNew;
					serverDowntime = 0;
					ServerStatusIcon.color = themeGreen;
				} else {
					serverDowntime += 1;
					if (serverDowntime > 120) {
						ServerStatusIcon.color = themeRed;
						systemIsReady = false;
					}
				}
			}
			if (clientIsConnected) {
				float qch1 = getQualityCh1();
				float qch2 = getQualityCh2();
				if (qch1 >= 0.9f) {
					SignalAStatusIcon.color = themeRed;
				} else {
					SignalAStatusIcon.color = themeGreen;
				}
				if (qch2 >= 0.9f) {
					SignalBStatusIcon.color = themeRed;
				} else {
					SignalBStatusIcon.color = themeGreen;
				}
			}
		}
       #endif
	}


	// Maintenance

	private void logStatus(string status)
	{
		if (inMenu) {
			StatusButton.GetComponentInChildren<Text> ().text = status;
		}
		if (verbose) {
			Debug.Log ("Status: "+status);
		}
	}

	public void resetStatus()
	{
		ServerStatusIcon.color = Color.grey;
		MuseStatusIcon.color = Color.grey;
		SignalAStatusIcon.color = Color.grey;
		SignalBStatusIcon.color = Color.grey;
		buttonColors.normalColor = Color.grey;
		buttonColors.highlightedColor = Color.grey;
		StatusButton.colors = buttonColors;
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
		#if UNITY_ANDROID && !UNITY_EDITOR
		if (androidDevice) {
			//Start Server
			logStatus ("starting server...");
			Debug.Log ("Started: " + FieldtripServicesControlerInterface.startServer ());
			ServerStatusIcon.color = themeRed;
			yield return new WaitForSeconds (4);//These waits are for the Services to have time to pass around their intents. Used to be 10.
			updateServer = true;


			//Start Clients
			logStatus ("starting client...");
			Debug.Log ("Started: " + FieldtripServicesControlerInterface.startClients ());
			yield return new WaitForSeconds (1);

			//Start Threads
			logStatus ("loading threads...");
			bool museIsAvailable = false;
			string[] result = FieldtripServicesControlerInterface.getAllThreadsNamesAndIDs ();
			while (result.Length==0) {//Wait until the ClientsService updates the controller with all the available threads
				yield return new WaitForSeconds (1);
				result = FieldtripServicesControlerInterface.getAllThreadsNamesAndIDs ();
			}
			for (int i=0; i<result.Length; ++i) {
				if (result [i].Split (':') [1].Contains ("Muse")) {
					logStatus ("connecting to muse...");
					museIsAvailable = true;
					MuseStatusIcon.color = themeRed;
					museThreadID = int.Parse (result [i].Split (':') [0]);
					if (verbose) {
						Debug.Log ("Starting MuseConnection @ thread: " + museThreadID.ToString ());
					}
					FieldtripServicesControlerInterface.startThread (museThreadID);
				}
			}

			if (museIsAvailable) {
				//Start Buffer
				logStatus ("creating buffer...");
				initializeBuffer ();

				//Check Muse connection
				logStatus ("waiting for muse...");
				int museClientID = 0;
				int currentSamples = FieldtripServicesControlerInterface.getClientSamplesPut (museClientID);
				int samplesPut = currentSamples;
				while (samplesPut < 100) {//Wait for Muse to put some samples in the buffer
					yield return new WaitForSeconds (1);
					samplesPut = FieldtripServicesControlerInterface.getClientSamplesPut (museClientID);
				}
				MuseStatusIcon.color = themeGreen;

				logStatus ("sending events to buffer...");
				for (int i=0; i<result.Length; ++i) {
					if (result [i].Split (':') [1].Contains ("Continuous")) {
						ccThreadID = int.Parse (result [i].Split (':') [0]);
						Debug.Log ("Starting ContinuousClassifier @ thread: " + ccThreadID.ToString ());
						FieldtripServicesControlerInterface.startThread (ccThreadID);
					}
				}
				while (!clientIsConnected) {
					yield return new WaitForSeconds(0.5f);
				}

				logStatus ("check signal quality...");
				yield return new WaitForSeconds (2f);
			}

			//buffer.putEvent("stimulus.startbaseline", "start", buffer.getCurrentSampleNumber());

		} else {
			logStatus ("pretending to do something...");
			yield return new WaitForSeconds(2);
		}
		#else
			//Start Buffer
			logStatus ("creating buffer...");
			while ( ! bufferIsOn ){
				initializeBuffer ();
				yield return new WaitForSeconds(1);
			}
			logStatus ("pretending to do something...");
			yield return new WaitForSeconds(2);
        #endif
		buttonColors.normalColor = themeGreen;
		buttonColors.highlightedColor = themeGreen;
		StatusButton.colors = buttonColors;
		logStatus ("start");
		systemIsReady = true;
	}


	public IEnumerator stopClientAndServer(){
		systemIsReady = false;
		#if UNITY_ANDROID && !UNITY_EDITOR
		if (androidDevice) {
			//Stop Clients
			clientIsConnected = false;
			logStatus ("stopping classifier...");
			FieldtripServicesControlerInterface.stopThread (ccThreadID);
			yield return new WaitForSeconds (1);
			logStatus ("stopping muse...");
			FieldtripServicesControlerInterface.stopThread (museThreadID);
			yield return new WaitForSeconds (1);
			logStatus ("shutting down clients...");
			Debug.Log ("Stopped Clients = " + FieldtripServicesControlerInterface.stopClients ());
			yield return new WaitForSeconds (1);

			//Stop buffer
			logStatus ("removing buffer...");
			bufferIsOn = false;
			buffer.disconnect ();
			yield return new WaitForSeconds (1);

			//Stop Server
			logStatus ("shutting down server...");
			updateServer = false;
			Debug.Log ("Stopped Server = " + FieldtripServicesControlerInterface.stopServer ());
			yield return new WaitForSeconds (1);

			//Update Status
			clientIsConnected = false;
			logStatus ("system offline");
			resetStatus ();
		}
		#else
		logStatus ("pretending to do something...");
		yield return new WaitForSeconds(2);
        #endif
	}

	public IEnumerator refreshClientAndServer(){
		logStatus("Resetting Client and Server");
		yield return StartCoroutine (stopClientAndServer ());
		yield return StartCoroutine (startServerAndAllClients());
	}


	// Buffer

	private void eventsAdded(UnityBuffer _buffer, EventArgs e){
		previousEvent = latestEvent;
		latestEvent = _buffer.getLatestEvent();
		if(bufferIsOn && latestEvent.getType().toString()=="alphaLat")
		{
			clientIsConnected = true;
			IList alphaLatObjects = latestEvent.getValue().array as IList;
			currentAlphaLat = alphaLatObjects.Cast<double>().ToArray();
			Debug.Log (currentAlphaLat[0].ToString()+" "+currentAlphaLat[1].ToString()+" "+currentAlphaLat[2].ToString()+" "+currentAlphaLat[3].ToString());
		}
	}

	public void initializeBuffer(){
		buffer = gameObject.AddComponent<UnityBuffer>();
		buffer.initializeBuffer();
		if(buffer!=null && buffer.bufferIsConnected){
			buffer.NewEventsAdded += new BufferChangeEventHandler(eventsAdded);//Attach the buffer's event handler to the eventsAdded function
			bufferIsOn = true;
		}else{
			Debug.Log ("Failed to initialize Unity Buffer Client");
		}
	}

	public void sendEvent(string eventType, string eventData)
	{
		Debug.Log ("Event sent to buffer: " + eventType + ": " + eventData);
		buffer.putEvent (eventType, eventData, buffer.getSampleNumberNow ());
	}


	// Interfacing

	public bool getSystemIsReady()
	{
		return systemIsReady;
	}

	public float getAlpha()
	{
		return (float)currentAlphaLat[0];
	}

	public float getBadness()
	{
		float badness = normalize ((float)currentAlphaLat [1], badnessLimit);
		badnessFilter = (float) (0.3 * badness + 0.7 * badnessFilter);
		return badnessFilter;
	}

	public float getQualityCh1()
	{
		return normalize ((float)currentAlphaLat [2], qualityLimit);
	}

	public float getQualityCh2()
	{
		return normalize ((float)currentAlphaLat [3], qualityLimit);
	}

	public void setMenu(bool value)
	{
		inMenu = value;
	}
}
