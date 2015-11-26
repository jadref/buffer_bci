using UnityEngine;
using System.Collections;

public class Config : MonoBehaviour {

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

	public static string baselineEventType = "stimulus.baseline";
	public static string restEventType     = "stimulus.rest";
	public static string approachEventType = "stimulus.approach";
	public static string avoidEventType    = "stimulus.avoid";
	public static string feedbackEventType = "classifier.prediction";

}
