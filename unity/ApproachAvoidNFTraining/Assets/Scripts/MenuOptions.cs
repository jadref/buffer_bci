using UnityEngine;
using System.Collections;

public class MenuOptions : MonoBehaviour {

	public FieldtripServicesInterfaceMain FTSInterface;

	public GameObject mainPanel;
	public GameObject connectionPanel;
	public GameObject restIntroPanel;
	public GameObject trainingIntroPanel;
	public GameObject questionairePanel1;
	public GameObject questionairePanel2;
	public GameObject questionairePanel3;
	public GameObject evaluationPanel;
	public GameObject loadingPanel;

	public GameObject restStage;
	public GameObject trainingStage;

	private GameObject[] menus;

	// Initialize
	void Awake ()
	{
		Screen.sleepTimeout = SleepTimeout.NeverSleep;

		trainingStage.GetComponent<Training> ().Initialize ();

		menus = new GameObject[transform.childCount];
		for (int i = 0; i < transform.childCount; i++)
		{
			menus [i] = transform.GetChild (i).gameObject;
		}
		LoadStartMenu();

	}

	// Some shortcuts
	public void Hide (GameObject obj)
	{
		obj.SetActive (false);
	}

	public void Show (GameObject obj)
	{
		obj.SetActive (true);
	}

	public void HideAllBut (GameObject obj)
	{
		for (int i = 0; i < menus.Length; i++)
		{
			Hide (menus [i]);
		}
		Hide (trainingStage);
		Hide (restStage);

		Show (obj);
	}


	// Menu Options

	public void LoadStartMenu()
	{
		FTSInterface.setMenu (false);
		HideAllBut (mainPanel);
	}

	public void Connect()
	{
		HideAllBut (connectionPanel);
		FTSInterface.setMenu (true);
		StartCoroutine (FTSInterface.startServerAndAllClients());
	}

	public void Refresh()
	{
		StartCoroutine (FTSInterface.refreshClientAndServer ());
	}

	public void Disconnect (bool silent)
	{
		if (silent) {
			StartCoroutine (FTSInterface.stopClientAndServer ());
		} else {
			StartCoroutine (SafeDisconnect ());
		}
	}

	public IEnumerator SafeDisconnect()
	{
		Show(loadingPanel);
		yield return StartCoroutine (FTSInterface.stopClientAndServer ());
		Hide (loadingPanel);
	}

	public void Quit()
	{
		HideAllBut (loadingPanel);
		StartCoroutine (SafeShutdown());
	}

	public IEnumerator SafeShutdown()
	{
		Debug.Log ("Shutting down safely");
		yield return SafeDisconnect ();
		Application.Quit ();
	}

	public void StartTask()
	{
		if (FTSInterface.getSystemIsReady()) {
			FTSInterface.setMenu (false);
			HideAllBut (restIntroPanel);
		}
	}

	public void LoadRestIntro()
	{
		Show (restIntroPanel);
	}

	public void LoadRestBaseline()
	{
		FTSInterface.sendEvent (Config.restEventType, "start"); // first is pure rest, i.e. no baseline
		HideAllBut (restStage);
	}

	public void EndRestBaseline()
	{
		FTSInterface.sendEvent (Config.restEventType, "end"); 
		LoadRest ();
	}

	public void LoadRest()
	{
		FTSInterface.sendEvent (Config.restEventType, "start");
		FTSInterface.sendEvent (Config.baselineEventType, "start"); // rest is also baseline
		HideAllBut (restStage);
	}

	public void EndRest()
	{
		FTSInterface.sendEvent (Config.restEventType, "end");
		FTSInterface.sendEvent (Config.baselineEventType, "end");
	}

	public void LoadTrainingIntro()
	{
		HideAllBut (trainingIntroPanel);
	}

	public void LoadTraining() {
		FTSInterface.sendEvent (Config.approachEventType, "start");
		HideAllBut (trainingStage);
	}

	public void EndTraining() {
		FTSInterface.sendEvent (Config.approachEventType, "end");
	}

	public void LoadQuestionPage(int page)
	{
		if (page == 1)
		{
			HideAllBut (questionairePanel1);
		}
		else if (page == 2)
		{
			HideAllBut (questionairePanel2);
		}
		else if (page == 3)
		{
			HideAllBut (questionairePanel3);
		}
	}

	public void LoadEvaluationPage()
	{
		HideAllBut (evaluationPanel);
	}
}
