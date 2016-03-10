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
	public UnityEngine.UI.Toggle     agenticToggle;
	public UnityEngine.UI.Text       cueText;
	public UnityEngine.UI.Text       splashText;
	public UnityEngine.UI.Text       restCueText;
	public AudioSource audio;
	public GameObject cuePanel;
	public GameObject questionairePanel1;
	public GameObject questionairePanel2;
	public GameObject questionairePanel3;
	public GameObject evaluationPanel;
	public GameObject loadingPanel;

	public GameObject restStage;
	public GameObject trainingStage;

	private static int sessions;

	private IEnumerator phaseMachine; // stateMachine for the experiment
	private bool moveForward = true;
	private bool endAll=false;
	private bool agenticControl=false;

	// game state controller to switch between stages of the experiment/game
	// N.B. you should never call this directly, but via the nextStage function
	private IEnumerable nextStageInner(){
		while (!endAll) {
				// Start screen
			FTSInterface.setMenu (false);
			HideAllBut (mainPanel);
			yield return null; // wait to be called back when the stage has finished
			if ( endAll ) break; // finish if quit from main-menu

			// show the connection panel, start trying to connect to the buffer, wait for continue to be pressed
			HideAllBut (connectionPanel);
			FTSInterface.setMenu (true);// BODGE: manually tell the FTS interface that it's visible.....
			//Connect (); // connect to Buffer
			yield return null;
			if ( endAll ) break; // finish if quit from main-menu

			HideAllBut (userInfoPanel);  // ask user information
			yield return null;
			if ( userTxt.text != null ) FTSInterface.sendEvent (Config.userEventType,userTxt.text);
			if ( sessionTxt.text != null ) FTSInterface.sendEvent (Config.sessionEventType,sessionTxt.text);
			agenticControl = agenticToggle.isOn; 
			if ( agenticControl ) {
				FTSInterface.sendEvent (Config.agenticEventType,"agentic");
			} else {
				FTSInterface.sendEvent (Config.agenticEventType,"operant");
			}

			if (FTSInterface.getSystemIsReady()) {
				FTSInterface.setMenu (false);
			}


			if (Config.preMeasure) {
			cueText.text = Config.premeasureText;
			HideAllBut (cuePanel);
			yield return null;
			if (endAll)
				break; // finish if quit from main-menu

				HideAllBut (restStage);
				FTSInterface.sendEvent (Config.restEventType, "start"); // first is pure rest, i.e. no baseline
				yield return null;
				FTSInterface.sendEvent (Config.restEventType, "end");
			}
			if (Config.eyesOpenTest) {
				cueText.text = Config.eyesOpenText;
				HideAllBut (cuePanel);
				yield return null;
				if (endAll)
					break; // finish if quit from main-menu

				restCueText.text = Config.baselineCueText;
				HideAllBut (restStage);
				FTSInterface.sendEvent (Config.eyesOpenEventType, "start"); // first is pure rest, i.e. no baseline
				yield return null;
				FTSInterface.sendEvent (Config.eyesOpenEventType, "end");
			}
			if (Config.eyesClosedTest) {
				cueText.text = Config.eyesClosedText;
				HideAllBut (cuePanel);
				yield return null;
				if (endAll)
					break; // finish if quit from main-menu

				restCueText.text = Config.eyesClosedCue;
				HideAllBut (restStage);
				FTSInterface.sendEvent (Config.eyesClosedEventType, "start"); // first is pure rest, i.e. no baseline
				yield return null;
				FTSInterface.sendEvent (Config.eyesClosedEventType, "end");
				audio.Play ();
			}

			cueText.text = Config.experimentInstructText;
			HideAllBut (cuePanel);
			yield return 0;
			if ( endAll ) break; // finish if quit from main-menu

			string trialType="";
			for (int si=0; si<Config.trainingBlocks; si++) {
				// run the baseline stage
				cueText.text = Config.baselineText;
				HideAllBut (cuePanel);
				yield return null;
				restCueText.text = Config.baselineCueText;
				HideAllBut (restStage);
				FTSInterface.sendEvent (Config.baselineEventType, "start"); // rest is also baseline
				yield return null;
				if ( endAll ) break; // finish if quit from main-menu
				FTSInterface.sendEvent (Config.baselineEventType, "end");

				// instructions before the control phase
				if ( agenticControl && si%2==1 ) 
					trialType="avoid"; 
				else 
					trialType="approach";
				if ( trialType.Equals("avoid") ) {
					cueText.text = Config.avoidCueText;
				} else if ( trialType.Equals("approach") ){
					cueText.text = Config.approachCueText;
				}
				HideAllBut (cuePanel);
				yield return 0;
				if ( endAll ) break; // finish if quit from main-menu

				// run the training stage
				FTSInterface.sendEvent (Config.trialEventType, "start");
				FTSInterface.sendEvent (Config.targetEventType, trialType);
				HideAllBut (trainingStage);
				yield return null;
				FTSInterface.sendEvent (Config.trialEventType, "end");
				if ( endAll ) break; // finish if quit from main-menu
			}

			if ((bool)Config.questionaire) {

				cueText.text = Config.questionaireText;
				HideAllBut (cuePanel);
				yield return null;
				if ( endAll ) break; // finish if quit from main-menu

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
					if ( endAll ) break; // finish if quit from main-menu

				}
			}

			if ((bool)Config.evaluation) {
				LoadEvaluationPage ();
				yield return null;
				if ( endAll ) break; // finish if quit from main-menu
			}
		}

		splashText.text = Config.farwellText;
		HideAllBut (loadingPanel);
		Disconnect(true);
		Application.Quit ();
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
		Screen.sleepTimeout = (int)(Config.trainingDuration * 2.0); //SleepTimeout.NeverSleep;

		//trainingStage.GetComponent<Training> ().Initialize ();
		HideAll();
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

	public void HideAll ()
	{
		Hide (trainingStage);
		Hide (restStage);
		for (int i = 0; i < transform.childCount; i++) {
			GameObject menu = transform.GetChild (i).gameObject;
			Hide (menu);
		}
	}

	public void HideAllBut (GameObject obj)
	{
		HideAll ();
		Show (obj);
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
