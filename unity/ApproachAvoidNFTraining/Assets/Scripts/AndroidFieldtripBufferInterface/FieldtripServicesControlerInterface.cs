using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;
using System.Runtime.InteropServices;

public static class FieldtripServicesControlerInterface {
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

	public static void StartPackage(string package){
		#if UNITY_ANDROID && !UNITY_EDITOR
		AndroidJavaClass activityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
		AndroidJavaObject mainActivity = activityClass.GetStatic<AndroidJavaObject>("currentActivity");
		AndroidJavaObject packageManager = mainActivity.Call<AndroidJavaObject>("getPackageManager");
		AndroidJavaObject launch = packageManager.Call<AndroidJavaObject>("getLaunchIntentForPackage",package);
		Debug.Log("start inttent = " + launch);
		mainActivity.Call("startActivity",launch);
		#endif
	}

	public static void StartService(string package,string service){
	    #if UNITY_ANDROID && !UNITY_EDITOR
		AndroidJavaClass activityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
		AndroidJavaObject mainActivity = activityClass.GetStatic<AndroidJavaObject>("currentActivity");
		AndroidJavaObject intent = new AndroidJavaObject("android.content.Intent");
		intent = intent.Call<AndroidJavaObject>("setClassName",package,service);
		Debug.Log("service intent = " + intent);
		AndroidJavaObject cname = mainActivity.Call<AndroidJavaObject>("startService",intent);
		#endif
	}
	public static void StopService(string package, string service){
		#if UNITY_ANDROID && !UNITY_EDITOR
		AndroidJavaClass activityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
		AndroidJavaObject mainActivity = activityClass.GetStatic<AndroidJavaObject>("currentActivity");
		AndroidJavaObject intent = new AndroidJavaObject("android.content.Intent");
		intent = intent.Call<AndroidJavaObject>("setClassName",package,service);
		bool succ = mainActivity.Call<bool>("stopService",intent);
		#endif
	}

	public static void Initialize () {
	}

	//Threads (Clients) Interface
	public static void startThread(int threadID){
		#if UNITY_ANDROID && !UNITY_EDITOR
		Debug.Log("getting the info to make the start activity ");
		AndroidJavaClass activityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
		AndroidJavaObject mainActivity = activityClass.GetStatic<AndroidJavaObject>("currentActivity");
		AndroidJavaObject intent = new AndroidJavaObject("android.content.Intent","nl.dcc.buffer_bci.bufferclientsservice.clientsfilter");
		intent = intent.Call<AndroidJavaObject>("putExtra","a",Config.bufferThreadStartActionID);
		intent = intent.Call<AndroidJavaObject>("putExtra","t_id",threadID);
		Debug.Log("service intent = " + intent);
		mainActivity.Call("sendBroadcast",intent);
		#endif
	}
	//Threads (Clients) Interface
	public static void startThread(String threadName){
		#if UNITY_ANDROID && !UNITY_EDITOR
		Debug.Log("getting the info to make the start activity ");
		AndroidJavaClass activityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
		AndroidJavaObject mainActivity = activityClass.GetStatic<AndroidJavaObject>("currentActivity");
		AndroidJavaObject intent = new AndroidJavaObject("android.content.Intent","nl.dcc.buffer_bci.bufferclientsservice.clientsfilter");
		intent = intent.Call<AndroidJavaObject>("putExtra","a",Config.bufferThreadStartActionID);
		intent = intent.Call<AndroidJavaObject>("putExtra","t_name",threadName);
		Debug.Log("service intent = " + intent);
		mainActivity.Call("sendBroadcast",intent);
		#endif
	}

	public static void stopThread(int threadID){
		#if UNITY_ANDROID && !UNITY_EDITOR
		Debug.Log("getting the info to make the start activity ");
		AndroidJavaClass activityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
		AndroidJavaObject mainActivity = activityClass.GetStatic<AndroidJavaObject>("currentActivity");
		AndroidJavaObject intent = new AndroidJavaObject("android.content.Intent","nl.dcc.buffer_bci.bufferclientsservice.clientsfilter");
		intent = intent.Call<AndroidJavaObject>("putExtra","a",Config.bufferThreadStopActionID);
		intent = intent.Call<AndroidJavaObject>("putExtra","t_id",threadID);
		Debug.Log("service intent = " + intent);
		mainActivity.Call("sendBroadcast",intent);
		#endif
	}
	public static void stopThread(String threadName){
		#if UNITY_ANDROID && !UNITY_EDITOR
		Debug.Log("getting the info to make the start activity ");
		AndroidJavaClass activityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
		AndroidJavaObject mainActivity = activityClass.GetStatic<AndroidJavaObject>("currentActivity");
		AndroidJavaObject intent = new AndroidJavaObject("android.content.Intent","nl.dcc.buffer_bci.bufferclientsservice.clientsfilter");
		intent = intent.Call<AndroidJavaObject>("putExtra","a",Config.bufferThreadStopActionID);
		intent = intent.Call<AndroidJavaObject>("putExtra","t_id",threadName);
		Debug.Log("service intent = " + intent);
		mainActivity.Call("sendBroadcast",intent);
		#endif
	}
}
