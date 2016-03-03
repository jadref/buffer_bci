using UnityEngine;
using System;
using System.Collections;
using FieldTrip.Buffer;
using System.Collections.Generic;

public class TestingFBClient : MonoBehaviour {

	UnityBuffer buffer;
	Boolean isBufferOn = false;

	// Use this for initialization
	void Start () {
	}
	
	// Update is called once per frame
	void Update () {
	}



	private void eventsAdded(UnityBuffer _buffer, EventArgs e){
		BufferEvent latestEvent = _buffer.getLatestEvent();
		Debug.Log (latestEvent.getType().toString()+": "+latestEvent.getValue().toString());
	}


	public void initializeBuffer(){
		buffer = gameObject.AddComponent<UnityBuffer>();
		buffer.initializeBuffer();
		if(buffer!=null && buffer.bufferIsConnected){
			buffer.NewEventsAdded += new BufferChangeEventHandler(eventsAdded);//Attach the buffer's event hadnler to the eventsAdded function
			isBufferOn = true;
		}
	}
}
