using UnityEngine;
using System.Collections;
using UnityEngine.EventSystems;
using System.IO;

public class MenuOptions : MonoBehaviour {
	// This class contains the main controller for the whole experiment!

	public FieldtripServicesInterfaceMain FTSInterface;
    public QualityCheck Quality;

	public GameObject mainPanel;
	public GameObject optionsPanel;
	public GameObject loadingPanel;
    public GameObject qualityPanel;
	public GameObject cuePanel;
	public GameObject questionairePanel;
	public GameObject scorePanel;

	public GameObject LoadingButton;
	public UnityEngine.UI.Text 		 StatusText;
	public UnityEngine.UI.Text       cueText;
	public UnityEngine.UI.Text		 cueButton;
	public UnityEngine.UI.Text       restCueText;
	public UnityEngine.UI.Text		 questionnaireQuestionText;
	public UnityEngine.UI.Text		 questionnaireAnswerLeftText;
	public UnityEngine.UI.Text		 questionnaireAnswerRightText;
	public UnityEngine.UI.Slider	 questionnaireSlider;
	public UnityEngine.UI.Text		 scoreText;
	public AudioSource sfx_ding;

	public GameObject restStage;
	public GameObject trainingStage;

	private IEnumerator phaseMachine; // stateMachine for the experiment
	private bool moveForward = true;
	private bool agenticControl = false;
	private int currentSession = 0;
	private int currentQuestion = 0;
	private float[] sessionScores;

	// Rest.cs uses this to see how long the rest should take
	public float currentRestDuration = 0f;

    // game state controller to switch between stages of the experiment/game
    // N.B. you should never call this directly, but via the nextStage function
    private IEnumerable nextStageInner() {

        // Start screen
        HideAllBut(mainPanel);
        yield return null; // wait to be called back when the stage has finished

        // Load connections, then wait for continue
        HideAllBut(loadingPanel);
        LoadingButton.SetActive(false);

        //ConnectServices();
        RefreshServices(); // BODGE: blindly stop services to make sure they aren't still running before starting a new instance
        yield return null; // wait to be called back when the stage has finished

        // Quality check
        Quality.enable(true);
        HideAllBut(qualityPanel);
        yield return null;

        if ((bool)Config.questionaire) {
            cueText.text = Config.preQuestionnaireText;
            cueButton.text = "verder";
            HideAllBut(cuePanel);
            yield return null;

            currentQuestion = 0;
            while (currentQuestion < Config.preQuestionnaire.GetLength(0)) {
                if (moveForward)
                    currentQuestion++;
                else
                    currentQuestion--;
                createQuestion(Config.preQuestionnaire);

                yield return null;
                string answer = string.Format("{0}, {1:N2}", currentQuestion, questionnaireSlider.value);
                FTSInterface.sendEvent(Config.preQuestionEventType, answer);
            }
        }

        else {
            cueText.text = Config.introText;
            cueButton.text = "verder";
            HideAllBut(cuePanel);
            yield return null;
        }

        if (Config.eyesOpenPre) {
            // quality check
            if (!Quality.getAvgQualityStatus())
            {
                HideAllBut(qualityPanel);
                yield return null;
            }
            Quality.resetAverage();

            currentRestDuration = Config.eyesOpenDuration;
            cueText.text = Config.eyesOpenText;
            cueButton.text = "verder";
            HideAllBut(cuePanel);
            yield return null;

            restCueText.text = Config.baselineCueText;
            HideAllBut(restStage);
            FTSInterface.sendEvent(Config.eyesOpenEventType, "start"); // first is pure rest, i.e. no baseline
            yield return null;
            FTSInterface.sendEvent(Config.eyesOpenEventType, "end");
        }

        if (Config.eyesClosedPre) {
            // quality check
            if (!Quality.getAvgQualityStatus())
            {
                HideAllBut(qualityPanel);
                yield return null;
            }
            Quality.resetAverage();

            currentRestDuration = Config.eyesClosedDuration;
            cueText.text = Config.eyesClosedText;
            cueButton.text = "ok";
            HideAllBut(cuePanel);
            yield return null;

            restCueText.text = Config.eyesClosedCue;
            HideAllBut(restStage);
            FTSInterface.sendEvent(Config.eyesClosedEventType, "start"); // first is pure rest, i.e. no baseline
            yield return null;
            FTSInterface.sendEvent(Config.eyesClosedEventType, "end");
            sfx_ding.Play();
        }

        // Trial Instructions
        cueText.text = Config.experimentInstructText1;
        cueButton.text = "verder";
        HideAllBut(cuePanel);
        yield return null;

        cueText.text = Config.experimentInstructText2;
        yield return null;


        // Run Trial sessions
        string trialType = "";
        sessionScores = new float[Config.trainingBlocks];
        for (int si = 0; si < Config.trainingBlocks; si++) {
            // quality check
            if (!Quality.getAvgQualityStatus())
            {
                HideAllBut(qualityPanel);
                yield return null;
            }
            Quality.resetAverage();

            // run the baseline stage
            currentRestDuration = Config.baselineDuration;
            cueText.text = Config.baselineText;
            cueButton.text = "ok";
            HideAllBut(cuePanel);
            yield return null;
            restCueText.text = Config.baselineCueText;
            HideAllBut(restStage);
            FTSInterface.sendEvent(Config.baselineEventType, "start"); // rest is also baseline
            yield return null;

            FTSInterface.sendEvent(Config.baselineEventType, "end");

            // quality check (now calibrated)
            Quality.setCalibration(true);
            if (!Quality.getAvgQualityStatus())
            {
                HideAllBut(qualityPanel);
                yield return null;
            }
            Quality.resetAverage();

            // instructions before the control phase
            if (agenticControl && si % 2 == 1)
                trialType = "avoid";
            else
                trialType = "approach";
            if (trialType.Equals("avoid")) {
                cueText.text = Config.avoidCueText;
            } else if (trialType.Equals("approach")) {
                cueText.text = Config.approachCueText;
            }
            cueButton.text = "ok";
            HideAllBut(cuePanel);
            yield return null;

            // run the training stage
            FTSInterface.sendEvent(Config.trialEventType, "start");
            FTSInterface.sendEvent(Config.targetEventType, trialType);
            HideAllBut(trainingStage);
            yield return null;
            FTSInterface.sendEvent(Config.trialEventType, "end");
            currentSession += 1;
        }

        if (Config.eyesOpenPost) {
            // quality check
            if (!Quality.getAvgQualityStatus())
            {
                HideAllBut(qualityPanel);
                yield return null;
            }
            Quality.resetAverage();

            currentRestDuration = Config.eyesOpenDuration;
            cueText.text = Config.eyesOpenText;
            cueButton.text = "verder";
            HideAllBut(cuePanel);
            yield return null;

            restCueText.text = Config.baselineCueText;
            HideAllBut(restStage);
            FTSInterface.sendEvent(Config.eyesOpenEventType, "start"); // first is pure rest, i.e. no baseline
            yield return null;
            FTSInterface.sendEvent(Config.eyesOpenEventType, "end");
        }

        if (Config.eyesClosedPost) {
            // quality check
            if (!Quality.getAvgQualityStatus())
            {
                HideAllBut(qualityPanel);
                yield return null;
            }
            Quality.resetAverage();

            currentRestDuration = Config.eyesClosedDuration;
            cueText.text = Config.eyesClosedPostText;
            cueButton.text = "ok";
            HideAllBut(cuePanel);
            sfx_ding.Play();
            yield return null;

            restCueText.text = Config.eyesClosedCue;
            HideAllBut(restStage);
            FTSInterface.sendEvent(Config.eyesClosedEventType, "start"); // first is pure rest, i.e. no baseline
            yield return null;
            FTSInterface.sendEvent(Config.eyesClosedEventType, "end");
            sfx_ding.Play();
        }

        // turn off quality check to save resources
        Quality.enable(false);

        if ((bool)Config.questionaire) {
            cueText.text = Config.postQuestionnaireText;
            cueButton.text = "verder";
            HideAllBut(cuePanel);
            yield return null;

            currentQuestion = 0;
            while (currentQuestion < Config.postQuestionnaire.GetLength(0)) {
                if (moveForward)
                    currentQuestion++;
                else
                    currentQuestion--;
                createQuestion(Config.postQuestionnaire);

                yield return null;
                string answer = string.Format("{0}, {1}", currentQuestion, questionnaireSlider.value);
                FTSInterface.sendEvent(Config.postQuestionEventType, answer);
            }
        }

        if ((bool)Config.evaluation) {
            currentQuestion = 0;
            while (currentQuestion < Config.evalQuestionnaire.GetLength(0)) {
                if (moveForward)
                    currentQuestion++;
                else
                    currentQuestion--;
                createQuestion(Config.evalQuestionnaire);

                yield return null;
                string answer = string.Format("{0}, {1}", currentQuestion, questionnaireSlider.value);
                FTSInterface.sendEvent(Config.evalQuestionEventType, answer);
            }
        }

        //Say goodbye
        cueText.text = Config.farewellText;
        cueButton.text = "sluiten";
        HideAllBut(cuePanel);
        yield return null;

        //End
        Quit();
	}

	public void nextStage(){
		moveForward = true;
		phaseMachine.MoveNext ();
	}

	public void previousStage(){
		moveForward = false;
		phaseMachine.MoveNext ();
	}

	public IEnumerator ShutDown()
	{
		StatusText.text = "Afsluiten...";
		LoadingButton.SetActive (false);
		HideAllBut (loadingPanel);

		Debug.Log ("Disconnecting.");
		DisconnectServices();

		while (FTSInterface.systemIsReady())
		{
			yield return new WaitForSeconds(1);
		}

		yield return new WaitForSeconds (1);
		Debug.Log ("Quitting.");
		Application.Quit ();
		// Kill insurance
		System.Diagnostics.Process.GetCurrentProcess ().Kill ();
	}

	public void logScore(float score) {
		sessionScores [currentSession] = score;
		Debug.Log (string.Format("Score of session {0}: {1}",currentSession,score));
	}

	public void toggleOptionsPanel(bool toggle){
		if (toggle) {
			HideAllBut (optionsPanel);
		} else {
			//Save options
			HideAllBut (mainPanel);
		}
	}

	public void createQuestion(string[,] content){
		int i = currentQuestion-1;
		questionnaireQuestionText.text = content[i,0];
		questionnaireAnswerLeftText.text = content[i,1];
		questionnaireAnswerRightText.text = content[i,2];
		questionnaireSlider.value = (float)(questionnaireSlider.maxValue+questionnaireSlider.minValue)/2;
		HideAllBut (questionairePanel);
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

	public void ConnectServices()
	{
		StartCoroutine (FTSInterface.startServerAndAllClients ());
	}

	public void RefreshServices()
	{
		StartCoroutine (FTSInterface.refreshClientAndServer ());
	}

	public void DisconnectServices ()
	{
		StartCoroutine (FTSInterface.stopClientAndServer ());
	}

	public void Quit()
	{
        StartCoroutine(ShutDown());
    }
}
