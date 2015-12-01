using UnityEngine;
using System.Collections;

public class Config : MonoBehaviour {

	public static bool preMeasure = false; // pre-baseline before first trials baseline
	public static bool awayTraining = false; 	//false (true not implemented yet)

	public static int restInterval = 30; 		//60

	public static int trainingInterval = 180; 	//180

	public static int trainingBlocks = 8; 		//4

	public static float alphaLimit = 3;
	public static float badnessThreshold = .5f; // above this value is indicated as bad
	public static float badnessLimit = 2.5f;   // max badness score allowed after threshold applied
	public static float badnessFilter= .9f;   // exp smoothing threshold for badness

	public static float qualityLimit = 150f;    //256

	public static bool artefactVisual = true; 	//true

	public static bool stimulusVisual = true; 	//true

	public static bool questionaire = true; 	//true

	public static bool evaluation = true; 		//true

	public static string userEventType     = "subject";
	public static string sessionEventType  = "session";
	public static string agenticEventType  = "stimulus.agenticMode";
	public static string baselineEventType = "stimulus.baseline";
	public static string restEventType     = "stimulus.rest";
	public static string trialEventType    = "stimulus.trial";
	public static string targetEventType   = "stimulus.target";
	public static string feedbackEventType = "classifier.prediction";

	public static string experimentInstructText = "Do what you are told!";
	public static string approachCueText = "Approach\n Move the ball towards you!";
	public static string avoidCueText    = "Avoid\n Move the ball away from you!";

}
