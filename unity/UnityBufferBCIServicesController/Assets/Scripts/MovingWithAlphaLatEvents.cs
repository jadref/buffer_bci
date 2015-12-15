using UnityEngine;
using System;
using System.Collections;
using FieldTrip.Buffer;
using System.Collections.Generic;

public class MovingWithAlphaLatEvents : MonoBehaviour {
	
	UnityBuffer buffer;
	Boolean isBufferOn = false;
	BufferEvent latestEvent;
	BufferEvent previousEvent;

	public float smoothTime = 0.3F;
	private Vector3 velocity = Vector3.zero;

	public float turningRate = 30f;

	private Quaternion _targetRotation = Quaternion.identity;
	

	// Use this for initialization
	void Start () {
		latestEvent = new BufferEvent("",0.0f,0);
		previousEvent = new BufferEvent("",0.0f,0);
	}
	
	// Update is called once per frame
	void Update () {
		if(isBufferOn && latestEvent.getType().toString()=="alphaLat" &&
		   latestEvent.getValue().toString()!=previousEvent.getValue().toString()){

			float alphaLatValue = float.Parse(latestEvent.getValue().toString());

			Vector3 targetPosition = new Vector3(0, 0, alphaLatValue);
			transform.position = Vector3.SmoothDamp(transform.position, targetPosition, ref velocity, smoothTime);

			previousEvent = latestEvent;
			Debug.Log (alphaLatValue);
		}
		if(isBufferOn){
			transform.Rotate (turningRate*Time.deltaTime, 0, 0);
		}
	}
	


	private void eventsAdded(UnityBuffer _buffer, EventArgs e){
		latestEvent = _buffer.getLatestEvent();
		Debug.Log (latestEvent.getType().toString()+": "+latestEvent.getValue().toString());
	}
	
	
	public void initializeBuffer(){
		buffer = gameObject.AddComponent<UnityBuffer>();
		buffer.initializeBuffer();
		if(buffer!=null && buffer.bufferIsConnected){
			buffer.NewEventsAdded += new BufferChangeEventHandler(eventsAdded);//Attach the buffer's event handler to the eventsAdded function
			isBufferOn = true;
		}else{
			Debug.Log ("Failed to initialize Unity Buffer Client");
		}
	}
}