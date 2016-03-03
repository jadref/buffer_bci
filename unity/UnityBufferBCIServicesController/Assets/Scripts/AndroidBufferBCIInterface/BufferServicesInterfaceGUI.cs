using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;
using System.Runtime.InteropServices;
using UnityEngine.UI;
using System.Linq;

public class BufferServicesInterfaceGUI : MonoBehaviour {

	String serverServiceName = "";
	String clientsServiceName = "";

	bool androidDevice = false;
	bool updateClientInfo = false;
	List<int> clientIDsToUpdateInfo;

	GameObject serverSwitch;
	GameObject clientsSwitch;
	string serverUptime = "00:00";
	Dictionary<int, string> threads;
	Dictionary<int, int> threadIDsToClientIDs;

	[SerializeField] Transform threadsDropDownPanel;
	[SerializeField] GameObject buttonPreFab;
	[SerializeField] GameObject clientInfoPanel;

	public bool verbose;

	void Start () {
		#if UNITY_ANDROID && !UNITY_EDITOR
			BufferServicesControllerInterface.Initialize();
			androidDevice = true;
		#endif

		serverSwitch = GameObject.Find("ToggleServerStart");
		clientsSwitch = GameObject.Find("ToggleClientsStart");

		clientIDsToUpdateInfo = new List<int>();
	}


	
	void Update(){
		if(androidDevice){
			string serverUptimeNew = BufferServicesControllerInterface.getBufferUptime();

			if(serverUptimeNew!=serverUptime){
				serverUptime = serverUptimeNew;
				GameObject.Find("UptimeText").GetComponent<Text>().text = serverUptime;
			}

			if(updateClientInfo){
				foreach(int id in clientIDsToUpdateInfo){
					GameObject infoPanel = GameObject.FindWithTag("clientID "+id.ToString());
					int samplesPut = BufferServicesControllerInterface.getClientSamplesPut(id);
					int samplesGotten = BufferServicesControllerInterface.getClientSamplesGotten(id);
					int eventsPut = BufferServicesControllerInterface.getClientEventsPut(id);
					int eventsGotten = BufferServicesControllerInterface.getClientEventsGotten(id);
					infoPanel.transform.Find ("ClientSamplesPutText").GetComponent<Text>().text = "Samples Put: "+samplesPut.ToString();
					infoPanel.transform.Find ("ClientSamplesGottenText").GetComponent<Text>().text = "Samples Gotten: "+samplesGotten.ToString();
					infoPanel.transform.Find ("ClientEventsPutText").GetComponent<Text>().text = "Events Put: "+eventsPut.ToString();
					infoPanel.transform.Find ("ClientEventsGottenText").GetComponent<Text>().text = "Events Gotten: "+eventsGotten.ToString();

					int threadID = threadIDsToClientIDs.FirstOrDefault(x => x.Value == id).Key;
					string status = BufferServicesControllerInterface.getThreadStatus(threadID);
					infoPanel.transform.Find("ThreadStatusText").GetComponent<Text>().text = "Status: "+status;
				}
			}
		}
	}




	public void startServer(){
		if(serverSwitch.GetComponent<Toggle>().isOn){
			if(androidDevice){
				serverServiceName = BufferServicesControllerInterface.startServer();
				GameObject.Find("ServerNotifications").GetComponent<Text>().text = serverServiceName;

			}
			GameObject.Find("ServerButtonText").GetComponent<Text>().text = "Stop Server";
		}
	}

	public void stopServer(){
		if(!serverSwitch.GetComponent<Toggle>().isOn){
			if(androidDevice){
				if(BufferServicesControllerInterface.stopServer())
					serverServiceName = "None";
				GameObject.Find("ServerNotifications").GetComponent<Text>().text = serverServiceName;
				serverUptime = "00:00";
			}
			GameObject.Find("ServerButtonText").GetComponent<Text>().text = "Start Server";
		}
	}




	public void startClients(){
		if(clientsSwitch.GetComponent<Toggle>().isOn){
			if(androidDevice){
				clientsServiceName = BufferServicesControllerInterface.startClients();
				GameObject.Find("ClientsNotifications").GetComponent<Text>().text = clientsServiceName;
			}
			GameObject.Find("ClientsButtonText").GetComponent<Text>().text = "Stop Clients";
			StartCoroutine(getAllThreads());
		}
	}
	
	public void stopClients(){
		if(!clientsSwitch.GetComponent<Toggle>().isOn){
			if(androidDevice){
				if(BufferServicesControllerInterface.stopClients())
					clientsServiceName = "None";
				GameObject.Find("ClientsNotifications").GetComponent<Text>().text = clientsServiceName;
			}
			GameObject.Find("ClientsButtonText").GetComponent<Text>().text = "Start Clients";
			clearThreadsDropDownPanel();
		}
	}



	public IEnumerator getAllThreads(){
		threads = new Dictionary<int, string>();
		threadIDsToClientIDs = new Dictionary<int, int>();
		yield return new WaitForSeconds(1);
		if(androidDevice){
			string[] result = BufferServicesControllerInterface.getAllThreadsNamesAndIDs();
			for(int i=0; i<result.Length; ++i){
				threads.Add(int.Parse(result[i].Split(':')[0]), result[i].Split(':')[1]);
			}
		}else{
			threads.Add(0,"Hello");
			threads.Add(1,"You");
		}
		generateThreadsDropDownPanel();
	}



	private void generateThreadsDropDownPanel(){
		clearThreadsDropDownPanel();
		for(int i=0; i<threads.Count; ++i){
			GameObject button = (GameObject)Instantiate (buttonPreFab);
			Text buttonText = button.GetComponentInChildren<Text>();
			buttonText.text = "Start "+threads[i];
			int index = i;
			button.GetComponent<Toggle>().onValueChanged.AddListener(
				delegate {changeThreadState(index,button.GetComponent<Toggle>().isOn, button);
			});
			button.transform.SetParent(threadsDropDownPanel);
		}
	}



	private void clearThreadsDropDownPanel(){
		foreach(Transform existingButton in threadsDropDownPanel){
			GameObject.Destroy(existingButton.gameObject);
		}
	}



	private void changeThreadState(int threadID, bool state, GameObject button){
		if(state){
			StartCoroutine(startThread(threadID, button));
			button.GetComponentInChildren<Text>().text = "Stop "+ threads[threadID];
		}else{
			stopThread(threadID, button);
			button.GetComponentInChildren<Text>().text = "Start "+ threads[threadID];
		}
	}


	private IEnumerator startThread(int threadID, GameObject button){
		if(androidDevice){
			//Get the clientIDs of all the clients running before we start a new one
			List<int> oldRunningClientIDs = new List<int>();
			int[] result = BufferServicesControllerInterface.getClientIDs();
			for(int i=0; i<result.Length; ++i){
				oldRunningClientIDs.Add(result[i]);
			}
			if(verbose){Debug.Log ("size of old clients list = "+oldRunningClientIDs.Count);}

			//Start a new thread (client)
			BufferServicesControllerInterface.startThread(threadID);
			if(verbose){Debug.Log("Starting thread: "+threadID.ToString());}
			yield return new WaitForSeconds(1f);


			//Get the new client ID by comparing the old returned list of ids with the new one
			List<int> newRunningClientIDs = new List<int>();
			result = BufferServicesControllerInterface.getClientIDs();
			for(int i=0; i<result.Length; ++i){
				newRunningClientIDs.Add(result[i]);
			}
			if(verbose){Debug.Log ("size of new clients list = "+newRunningClientIDs.Count);}

			//Client IDs get created but do not get deleted so connect a new client ID to a thread ID or call a preexisting client ID by the button's thread ID
			int clientID = -1;
			IEnumerable<int> newClientID = new List<int>();
			newClientID = (from s in newRunningClientIDs where !oldRunningClientIDs.Contains(s) select s);
			if(newClientID.Count()>0){
				clientID = newClientID.ElementAt(0);
				threadIDsToClientIDs.Add(threadID, clientID);
			}else{
				clientID = threadIDsToClientIDs[threadID];
			}

			//Make the info panel
			GameObject clientInfo = (GameObject) Instantiate(clientInfoPanel);
			clientInfo.transform.SetParent(button.transform);
			clientInfo.tag = "clientID "+clientID.ToString();
			RectTransform clientInfoTransform = clientInfo.GetComponent<RectTransform>();
			clientInfoTransform.anchoredPosition = new Vector3(0, 0, 0);
			clientInfo.transform.Find("ClientIDText").GetComponent<Text>().text = "Client ID: "+clientID.ToString();

			updateClientInfo = true;
			clientIDsToUpdateInfo.Add(clientID);
		}
	}


	private void stopThread(int threadID, GameObject button){
		if(androidDevice){
			BufferServicesControllerInterface.stopThread(threadID);
			updateClientInfo = false;
			int clientID = Convert.ToInt32(button.transform.Find("ClientInfoPanel(Clone)").tag.Split(' ')[1]);
			clientIDsToUpdateInfo.Remove(clientID);
		}
		GameObject.Destroy(button.transform.Find("ClientInfoPanel(Clone)").gameObject);
	}

}
