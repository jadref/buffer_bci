using UnityEngine;
using System.Collections;

public class Config : MonoBehaviour {

	public static string bufferServerAppPackageName = "nl.dcc.buffer_bci";
	public static string bufferServerPackageName = "nl.dcc.buffer_bci.bufferserverservice.BufferServerService";
	public static string bufferClientsPackageName = "nl.dcc.buffer_bci.bufferclientsservice.BufferClientsService";
	public static int bufferThreadStartActionID = 8;
	public static int bufferThreadStopActionID = 6;
	//public static string[] bufferClientThreadList = {"MuseConnection", "AlphaLatContClassifierThread"};
	public static string[] bufferClientThreadList = {"SignalProxyThread", "AlphaLatContClassifierThread"}; // debug config, no-muse needed

	public static bool preMeasure = false; // pre-baseline before first trials baseline
	public static bool awayTraining = false; 	//false (true not implemented yet)


	public static float trainingDuration = 60; 	//180

	public static int trainingBlocks = 3; 		//12=42min

	public static float alphaLimit = 3;
	public static float badnessThreshold = .25f; // above this value is indicated as bad
	public static float badnessLimit = 2.5f;   // max badness score allowed after threshold applied
	public static float badnessFilter= .9f;   // exp smoothing threshold for badness

	public static float qualityLimit = 150f;    //256

	public static bool artefactVisual = true; 	//true

	public static bool stimulusVisual = true; 	//true

	public static bool questionaire = true; 	//true
	public static string questionaireText = "Nu volgt een korte vragenlijst waarin we u een aantal vragen stellen over hoe u zich op dit moment voelt. \n\nU kunt uw antwoord geven door met uw vinger de stippen te verschuiven.";


	public static bool evaluation = true; 		//true

	public static bool askUserInfo       = false;
	public static string userEventType     = "subject";
	public static string sessionEventType  = "session";
	public static string agenticEventType  = "stimulus.agenticMode";

	public static float baselineDuration = 30; // 30; 		//60
	public static string baselineEventType = "stimulus.baseline";
	public static string baselineText = "Nu volgt een korte rustmeting met ogen open.\n\nHoud aub tijdens de meting uw ogen gericht op het fixatiekruis. \n\nDruk op ok om te starten met de rustmeting (30 seconden).";
	public static string baselineCueText = "";

	public static float fixationDuration   = 30;
	public static string restEventType     = "stimulus.rest";
	public static string trialEventType    = "stimulus.trial";
	public static string targetEventType   = "stimulus.target";
	public static string feedbackEventType = "classifier.prediction";

	public static string experimentInstructText = "We beginnen nu met trainingsfase.\n\nElke fase begint met een korte ontspanningsfase met open ogen gevolgd door een fase waarin feedback leer om de positie van een bal.";
	public static string approachCueText = "U krijgt zometeen een bal te zien die naar u toe beweegt of van u af beweegt.\n\nDe bal wordt bestuurd door uw hersenactiviteit. \n\nUw doel is om de bal zo dicht mogelijk naar u toe te bewegen. \n\nDe bal zal lang niet altijd doen wat u wil. Maar door goed naar de bal te blijven kijken leert uw brein automatisch de bal te controleren.";
	public static string avoidCueText    = "Probeer de bal naar u toe te bewegen!";
	public static string premeasureText = "We beginnen met een korte rustmeting met ogen open.\n\nHoud aub tijdens de meting uw ogen gericht op het fixatiekruis. \n\nDruk op ok om te starten met de rustmeting (30 seconden).";

	public static string eyesClosedEventType = "stimulus.eyesclosed";
	public static bool eyesClosedTest = true;
	public static float eyesClosedDuration = 60; //60;
	public static string eyesClosedText = "Welkom bij deze neurofeedback sessie. We beginnen met een rustmeting met ogen dicht.\n\nHoud aub tijdens de meting uw ogen dicht en doe uw ogen pas open wanneer het piepje klinkt. \n\nDruk op ok om te starten met de rustmeting (60 seconden).";
	public static string eyesClosedCue  = "Ogen dicht aub";

	public static string eyesOpenEventType = "stimulus.eyesopen";
	public static bool eyesOpenTest = false;
	public static float eyesOpenDuration = 60; // 60;
	public static string eyesOpenText = "We beginnen met een rustmeting met ogen open.\n\nHoud aub tijdens de meting uw ogen gericht op het fixatiekruis. \n\nDruk op ok om te starten met de rustmeting (60 seconden).";

	public static string farwellText = "Dit is het einde van deze sessie.\nHartelijk dank en tot een volgende keer";

}
