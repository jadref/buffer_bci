using UnityEngine;
using System.Collections;

public class Config : MonoBehaviour {

	public static bool awayTraining = false; 	//false (true not implemented yet)

	public static int restInterval = 60; 		//60

	public static int trainingInterval = 180; 	//180

	public static int trainingBlocks = 4; 		//4

	public static float badnessLimit = 256f;    //256

	public static float qualityLimit = 256f;    //256

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
