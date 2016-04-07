using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;
using System.Runtime.InteropServices;


public static class FieldtripServicesControlerInterface {


	private static AndroidJavaObject mainActivity;
	private static AndroidJavaObject serverController;
	private static AndroidJavaObject clientsController;

	public static void StartPackage(string package){
		// wrapper script to start an android package
		AndroidJavaClass activityClass;
		AndroidJavaObject packageManager;
		AndroidJavaObject launch;

		#if UNITY_ANDROID && !UNITY_EDITOR
		Debug.Log("getting the info to make the start activity ");
		activityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
		mainActivity = activityClass.GetStatic<AndroidJavaObject>("currentActivity");
		packageManager = mainActivity.Call<AndroidJavaObject>("getPackageManager");
		launch = packageManager.Call<AndroidJavaObject>("getLaunchIntentForPackage",package);
		Debug.Log("start inttent = " + launch);
		mainActivity.Call("startActivity",launch);
		#endif
	}

	public static void StartService(string package,string service){
		// wrapper script to start an android package
		AndroidJavaClass activityClass;
		AndroidJavaObject packageManager;
		AndroidJavaObject launch;

		#if UNITY_ANDROID && !UNITY_EDITOR
		Debug.Log("getting the info to make the start activity ");
		activityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
		mainActivity = activityClass.GetStatic<AndroidJavaObject>("currentActivity");
		AndroidJavaObject intent = new AndroidJavaObject("android.content.Intent");
		intent = intent.Call<AndroidJavaObject>("setClassName",package,service);
		Debug.Log("service intent = " + intent);
		//intent.Call<AndroidJavaObject>("setAction",package);
		AndroidJavaObject cname = mainActivity.Call<AndroidJavaObject>("startService",intent);
		#endif
	}


	public static void StopService(string package, string service){
		// wrapper script to start an android package
		AndroidJavaClass activityClass;
		AndroidJavaObject packageManager;
		AndroidJavaObject launch;

		#if UNITY_ANDROID && !UNITY_EDITOR
		Debug.Log("getting the info to make the start activity ");
		activityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
		mainActivity = activityClass.GetStatic<AndroidJavaObject>("currentActivity");
		AndroidJavaObject intent = new AndroidJavaObject("android.content.Intent");
		intent.Call<AndroidJavaObject>("setAction",package);
		mainActivity.Call<AndroidJavaObject>("stopService",intent);
		#endif
	}

	public static void Initialize () {
		#if !NOSERVICESCONTROLLER && UNITY_ANDROID && !UNITY_EDITOR
		AndroidJavaClass jc = new AndroidJavaClass ("com.unity3d.player.UnityPlayer");
		mainActivity = jc.GetStatic<AndroidJavaObject> ("currentActivity");
		serverController = mainActivity.Get<AndroidJavaObject>("serverController");
		clientsController = mainActivity.Get<AndroidJavaObject>("clientsController");
		#endif
	}


	//Server Interface
	public static string startServerApp(){
		Debug.Log ("Starting the main app:");
		StartPackage (Config.bufferServerAppPackageName);
		return "";
	}

	public static string startServer(){
		Debug.Log ("Starting the server service");
		StartService(Config.bufferServerAppPackageName,Config.bufferServerPackageName);
		return "";
	}

	public static bool stopServer(){
		StopService(Config.bufferServerAppPackageName,Config.bufferServerPackageName);
		return true; //mainActivity.Call<bool>("stopServer");
	}
		
	//Clients in Buffer Interface
	public static string startClients(){
		Debug.Log ("Starting the clients");
		StartService(Config.bufferServerAppPackageName,Config.bufferClientsPackageName);
		//return mainActivity.Call<string>("startClients");
		return "";
	}

	public static bool stopClients(){
		StopService(Config.bufferServerAppPackageName,Config.bufferClientsPackageName);
		//return mainActivity.Call<bool>("stopClients");
		return true;
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
		// wrapper script to start an android package
		AndroidJavaClass activityClass;
		AndroidJavaObject packageManager;
		AndroidJavaObject launch;

		#if UNITY_ANDROID && !UNITY_EDITOR
		Debug.Log("getting the info to make the start activity ");
		activityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
		mainActivity = activityClass.GetStatic<AndroidJavaObject>("currentActivity");
		AndroidJavaObject intent = new AndroidJavaObject("android.content.Intent","nl.dcc.buffer_bci.bufferclientsservice.clientsfilter");
		intent = intent.Call<AndroidJavaObject>("putExtra","a",8);
		intent = intent.Call<AndroidJavaObject>("putExtra","t_id",4);
		Debug.Log("service intent = " + intent);
		//intent.Call<AndroidJavaObject>("setAction",package);
		mainActivity.Call("sendBroadcast",intent);
		#endif
		//clientsController.Call("startThread", threadID);
	}

	public static void stopThread(int threadID){
		clientsController.Call("stopThread", threadID);
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
}
