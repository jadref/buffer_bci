using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;
using System.Runtime.InteropServices;


public static class FieldtripServicesControlerInterface {

	#if !NOSERVICESCONTROLLER && UNITY_ANDROID && !UNITY_EDITOR
	private static AndroidJavaObject mainActivity;
	private static AndroidJavaObject serverController;
	private static AndroidJavaObject clientsController;

	public static void Initialize () {
		AndroidJavaClass jc = new AndroidJavaClass ("com.unity3d.player.UnityPlayer");
		mainActivity = jc.GetStatic<AndroidJavaObject> ("currentActivity");
		serverController = mainActivity.Get<AndroidJavaObject>("serverController");
		clientsController = mainActivity.Get<AndroidJavaObject>("clientsController");
	}


	//Server Interface
	public static string startServer(){
		return mainActivity.Call<string>("startServer");
	}

	public static bool stopServer(){
		return mainActivity.Call<bool>("stopServer");
	}

	public static void PutHeader(){
		serverController.Call("PutHeader");
	}

	public static void FlushHeader(){
		serverController.Call("FlushHeader");
	}

	public static void FlushSamples(){
		serverController.Call("FlushSamples");
	}

	public static void FlushEvents(){
		serverController.Call("FlushEvents");
	}

	public static string getBufferUptime(){
		return serverController.Call<String>("getBufferUptime");
	}

	public static int getBufferPort(){
		return serverController.Call<int>("getBufferPort");
	}

	public static int getBuffernSamples(){
		return serverController.Call<int>("getBuffernSamples");
	}

	public static int getBuffernEvents(){
		return serverController.Call<int>("getBuffernEvents");
	}

	public static int getBuffernChannels(){
		return serverController.Call<int>("getBuffernChannels");
	}

	public static int getBuffernDataType(){
		return serverController.Call<int>("getBuffernDataType");
	}

	public static float getBufferfSample(){
		return serverController.Call<float>("getBufferfSample");
	}

	public static void setBufferPort(int port){
		serverController.Call("setBufferPort", port);
	}

	public static void setnBufferSamples(int port){
		serverController.Call("setnBufferSamples", port);
	}

	public static void setBuffernEvents(int port){
		serverController.Call("setBuffernEvents", port);
	}

	public static void setBuffernChannels(int port){
		serverController.Call("setBuffernChannels", port);
	}



	//Clients in Buffer Interface
	public static string startClients(){
		return mainActivity.Call<string>("startClients");
	}

	public static bool stopClients(){
		return mainActivity.Call<bool>("stopClients");
	}

	public static int getClientSamplesPut(int id){
		return serverController.Call<int>("getClientSamplesPut",id);
	}

	public static int getClientSamplesGotten(int id){
		return serverController.Call<int>("getClientSamplesGotten",id);
	}

	public static int getClientEventsPut(int id){
		return serverController.Call<int>("getClientEventsPut",id);
	}

	public static int getClientEventsGotten(int id){
		return serverController.Call<int>("getClientEventsGotten",id);
	}

	public static int getClientLastActivity(int id){
		return serverController.Call<int>("getClientLastActivity",id);
	}

	public static int getClientWaitSamples(int id){
		return serverController.Call<int>("getClientWaitSamples",id);
	}

	public static int getClientError(int id){
		return serverController.Call<int>("getClientError",id);
	}

	public static long getClientTimeLastActivity(int id){
		return serverController.Call<long>("getClientTimeLastActivity",id);
	}

	public static long getClientTime(int id){
		return serverController.Call<long>("getClientTime",id);
	}

	public static long getClientWaitTimeout(int id){
		return serverController.Call<long>("getClientWaitTimeout",id);
	}

	public static bool getClientConnected(int id){
		return serverController.Call<bool>("getClientConnected",id);
	}

	public static bool getClientChanged(int id){
		return serverController.Call<bool>("getClientChanged",id);
	}

	public static int getClientDiff(int id){
		return serverController.Call<int>("getClientDiff",id);
	}

	public static string getClientAddress (int id){
		return serverController.Call<string>("getClientAddress", id);
	}

	public static int[] getClientIDs(){
		AndroidJavaObject obj = serverController.Call<AndroidJavaObject>("getClientIDs");
		int[] emptyResult = new int[0];
		if (obj.GetRawObject().ToInt32() != 0)
		{
			int[] result = AndroidJNIHelper.ConvertFromJNIArray<int[]>(obj.GetRawObject());
			obj.Dispose();
			return result;
		}
		else{
			Debug.Log ("Got null getClientIDs array");
			obj.Dispose();
			return emptyResult;
		}
	}





	//Threads (Clients) Interface
	public static void startThread(int threadID){
		clientsController.Call("startThread", threadID);
	}

	public static void stopThread(int threadID){
		clientsController.Call("stopThread", threadID);
	}

	public static string getThreadStatus (int threadID){
		return clientsController.Call<string>("getThreadStatus", threadID);
	}

	public static string[] getAllThreadsNamesAndIDs(){
		Debug.Log ("Trying to get thread names and IDs");
		string[] emptyResult = new string[0];
		AndroidJavaObject obj = clientsController.Call<AndroidJavaObject>("getAllThreadNamesAndIDs");
		if (obj.GetRawObject().ToInt32() != 0)
		{
			string[] result = AndroidJNIHelper.ConvertFromJNIArray<string[]>(obj.GetRawObject());
			Debug.Log ("Length of returned array: "+result.Length.ToString());
			obj.Dispose();
			return result;
		}
		else
		{
			obj.Dispose();
			Debug.Log ("Got null getAllThreadNamesAndIDs array");
			return emptyResult;
		}
	}
	#endif
}
