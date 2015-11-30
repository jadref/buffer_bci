using UnityEngine;
using System.Collections;

public class MenuOptions : MonoBehaviour {
	// This class contains the main controller for the whole experiment!


	public FieldtripServicesInterfaceMain FTSInterface;

	public GameObject mainPanel;
	public GameObject connectionPanel;
	public GameObject userInfoPanel;
	public UnityEngine.UI.InputField userTxt;
	public UnityEngine.UI.InputField sessionTxt;
	public GameObject restIntroPanel;
	public GameObject trainingIntroPanel;
	public GameObject pausePanel;
	public GameObject questionairePanel1;
	public GameObject questionairePanel2;
	public GameObject questionairePanel3;
	public GameObject evaluationPanel;
	public GameObject loadingPanel;

	public GameObject restStage;
	public GameObject trainingStage;

	private GameObject[] menus;

	private static int sessions;

	private IEnumerator phaseMachine; // stateMachine for the experiment
	private bool moveForward = true;
	private bool endAll=false;


	// game state controller to switch between stages of the experiment/game
	// N.B. you should never call this directly, but via the nextStage function
	private IEnumerable nextStageInner(){
		while (!endAll) {
				// Start screen
			FTSInterface.setMenu (false);
			HideAllBut (mainPanel);
			yield return null; // wait to be called back when the stage has finished
			if ( endAll ) break; // finish if quit from main-menu

			HideAllBut (connectionPanel);
			FTSInterface.setMenu (true);
			Connect (); // connect to buffer
			yield return null;

			HideAllBut (userInfoPanel);  // ask user information
			yield return null;
			if ( userTxt.text != null ) FTSInterface.sendEvent (Config.userEventType,userTxt.text);
			if ( sessionTxt.text != null ) FTSInterface.sendEvent (Config.sessionEventType,sessionTxt.text);

			if (FTSInterface.getSystemIsReady()) {
				FTSInterface.setMenu (false);
				HideAllBut (restIntroPanel);
			}
			yield return null;

			if (Config.preMeasure) {
				FTSInterface.sendEvent (Config.restEventType, "start"); // first is pure rest, i.e. no baseline
				HideAllBut (restStage);
				yield return null;
				FTSInterface.sendEvent (Config.restEventType, "end");
			}

			HideAllBut (trainingIntroPanel);
			yield return 0;

			for (int si=0; si<Config.trainingBlocks; si++) {
				// run the rest stage
				FTSInterface.sendEvent (Config.restEventType, "start");
				FTSInterface.sendEvent (Config.baselineEventType, "start"); // rest is also baseline
				HideAllBut (restStage);
				yield return null;
				FTSInterface.sendEvent (Config.restEventType, "end");
				FTSInterface.sendEvent (Config.baselineEventType, "end");

				// run the training stage
				FTSInterface.sendEvent (Config.approachEventType, "start");
				HideAllBut (trainingStage);
				yield return null;
				FTSInterface.sendEvent (Config.approachEventType, "end");

				HideAllBut(pausePanel); // wait for user to continue
				yield return null;
			}

			if ((bool)Config.questionaire) {
				int questionaireStage = 0;
				while (questionaireStage < 3) {
					if (moveForward)
						questionaireStage++;
					else
						questionaireStage--;

					if (questionaireStage == 1)
					{
						HideAllBut (questionairePanel1);
					}
					else if (questionaireStage == 2)
					{
						HideAllBut (questionairePanel2);
					}
					else if (questionaireStage == 3)
					{
						HideAllBut (questionairePanel3);
					}
					yield return null;

				}
			}

			if ((bool)Config.evaluation) {
				LoadEvaluationPage ();
				yield return null;
			}
		}
		HideAllBut (loadingPanel);
		Disconnect(true);
	}

	public void nextStage(){
		moveForward = true;
		phaseMachine.MoveNext ();
	}
	public void previousStage(){
		moveForward = false;
		phaseMachine.MoveNext ();
	}

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
		// start the first stage and get an iterator to the state-machine management
		phaseMachine = nextStageInner ().GetEnumerator(); // get the state machine object 
		nextStage (); // start the 1st stage
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
	public void Connect()
	{
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
		endAll = true;
		nextStage ();
	}

	public IEnumerator SafeShutdown()
	{
		Debug.Log ("Shutting down safely");
		yield return SafeDisconnect ();
		Application.Quit ();
	}
	
	public void LoadEvaluationPage()
	{
		HideAllBut (evaluationPanel);
	}
}
