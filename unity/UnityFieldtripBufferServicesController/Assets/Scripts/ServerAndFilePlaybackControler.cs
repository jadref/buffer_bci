using UnityEngine;
using System.Collections;

public class ServerAndFilePlaybackControler : MonoBehaviour {

	bool androidDevice = false;
	int threadID;

	void Start () {
		#if UNITY_ANDROID && !UNITY_EDITOR
			FieldtripServicesControlerInterface.Initialize();
			androidDevice = true;
		#endif

		StartCoroutine(startServerAndAllClients());
	}
	

	void Update () {
	
	}


	public IEnumerator startServerAndAllClients(){
		if(androidDevice){
			//Start Server
			Debug.Log ("Started: "+FieldtripServicesControlerInterface.startServer());

			yield return new WaitForSeconds(10);//These waits are for the Services to have time to pass around their intents

			//Start Clients
			Debug.Log ("Started: "+FieldtripServicesControlerInterface.startClients());

			yield return new WaitForSeconds(1);

			//Start FilePlayback client
			string[] result = FieldtripServicesControlerInterface.getAllThreadsNamesAndIDs();
			while(result.Length==0){//Wait until the ClientsService updates the controller with all the available threads
				yield return new WaitForSeconds(1);
				result = FieldtripServicesControlerInterface.getAllThreadsNamesAndIDs();
			}
			for(int i=0; i<result.Length; ++i){
				if(result[i].Split(':')[1] == "File Playback"){
					Debug.Log ("Starting FilePlayback");
					threadID = int.Parse(result[i].Split(':')[0]);
					FieldtripServicesControlerInterface.startThread(threadID);
				}
			}
			yield return new WaitForSeconds(1);

			//Start the internal buffer client
			GameObject.Find("Sphere").GetComponent<MovingWithAlphaLatEvents>().initializeBuffer();
		}
	} 


	public IEnumerator stopFilePlaybackCLientAndServer(){

		FieldtripServicesControlerInterface.stopThread(threadID);
		yield return new WaitForSeconds(0.5f);

		//Stop Clients
		Debug.Log ("Stopped Clients = "+FieldtripServicesControlerInterface.stopClients());

		//Stop Server
		Debug.Log ("Stopped Server = "+FieldtripServicesControlerInterface.stopServer());

	}
}
