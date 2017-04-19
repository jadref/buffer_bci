using UnityEngine;
using System.Collections;

public class Config : MonoBehaviour {

	public static string bufferServerAppPackageName = "nl.dcc.buffer_bci";
	public static string bufferServerPackageName = "nl.dcc.buffer_bci.bufferserverservice.BufferServerService";
	public static string bufferClientsPackageName = "nl.dcc.buffer_bci.bufferclientsservice.BufferClientsService";
	public static int bufferThreadStartActionID = 8;
	public static int bufferThreadStopActionID = 6;
	public static string[] bufferClientThreadList = {"MuseConnection", "AlphaLatContClassifierThread"};
	//public static string[] bufferClientThreadList = {"SignalProxyThread", "AlphaLatContClassifierThread"}; // debug config, no-muse needed


	// EVENTS

	public static string restEventType     = "stimulus.rest";
	public static string trialEventType    = "stimulus.trial";
	public static string targetEventType   = "stimulus.target";

	public static string feedbackEventType = "classifier.prediction";
	public static string rawfeedbackEventType="classifier.rawprediction";
	public static string baselineEventType = "stimulus.baseline";
	public static string eyesClosedEventType = "stimulus.eyesclosed";
	public static string eyesOpenEventType = "stimulus.eyesopen";

	public static string preQuestionEventType = "questionnaire.pre";
	public static string postQuestionEventType = "questionnaire.post";
	public static string evalQuestionEventType = "questionnaire.eval";

    // SIGNAL QUALITY

    public static float qualityThresholdActiveUncal = 5; //uncalibrated
    public static float qualityThresholdRollingUncal = 10;
    public static float qualityLimitBadUncal = 10;
    public static float qualityThresholdActiveCal = 5; //calibrated
    public static float qualityThresholdRollingCal = 5;
    public static float qualityLimitBadCal = 10;
	public static float qualityThresholdDisconnected = .5f; // below this is not-connected
	public static float qualityThresholdDisconnectedCal = -3.0f; // below this is not-connected
    public static int qualitySamplesRequired = 120;
    public static int qualityTimeOut = 60; // timeout (samples) after one or more channels have dropped again

    public static string qualityText = "Signaalcontrole \n\nZet de Muse goed op uw hoofd, zodat de cirkels langdurig groen blijven";


    // REST & BASELINE

    public static float baselineDuration = 30; // 30;
	public static string baselineText = string.Format ("Nu volgt een korte rustmeting met ogen open.\n\nHoud aub tijdens de meting uw ogen gericht op het fixatiekruis. \n\nDruk op ok om te starten met de rustmeting ({0} seconden)", baselineDuration);
	public static string baselineCueText = "";

	public static bool eyesClosedPre = true;
	public static bool eyesClosedPost = true;
	public static float eyesClosedDuration = 60; //60;
	public static string eyesClosedText = string.Format ("We beginnen een korte rustmeting met ogen <color=#AD3448>dicht</color>.\n\nHoud aub tijdens de meting uw ogen <color=#AD3448>dicht</color> en doe uw ogen pas open wanneer het piepje klinkt. \n\nDruk op ok om te starten met de rustmeting ({0} seconden)", eyesClosedDuration);
    public static string eyesClosedPostText = string.Format("Ter afsluiting volgt nu een rustmeting met ogen <color=#AD3448>dicht</color>.\n\nHoud aub tijdens de meting uw ogen <color=#AD3448>dicht</color> en doe uw ogen pas open wanneer het piepje klinkt. \n\nDruk op ok om te starten met de rustmeting ({0} seconden)", eyesClosedDuration);
    public static string eyesClosedCue  = "Ogen dicht aub";

	public static bool eyesOpenPre = false;
	public static bool eyesOpenPost = false;
	public static float eyesOpenDuration = 60; // 60;
	public static string eyesOpenText = string.Format ("We beginnen met een korte rustmeting met ogen open.\n\nHoud aub tijdens de meting uw ogen gericht op het fixatiekruis. \n\nDruk op ok om te starten met de rustmeting ({0} seconden)", eyesOpenDuration);
	public static string eyesOpenCue  = "";


	// TRAINING

	public static float trainingDuration = 180; 	//180
	public static int trainingBlocks = 5; 		//5

	public static float alphaLimit = 3;
	public static float badnessThreshold = .5f; // above this value is indicated as bad
	public static float badnessLimit = 2.5f;   // max badness score allowed after threshold applied
	public static float badnessFilter= .9f;   // exp smoothing threshold for badness

	public static string approachCueText = string.Format("Nu volgt een training met de bal.\n\nUw doel is om de bal naar u toe te laten bewegen. \n\nDruk op ok om te starten met de training ({0} min.)",trainingDuration/60f);
	public static string avoidCueText    = string.Format("Nu volgt een training met de bal.\n\nUw doel is om de bal van u af te laten bewegen. \n\nDruk op ok om te starten met de training ({0} min.)",trainingDuration/60f);


	// QUESTIONNAIRE

	public static bool questionaire = true; 	//true
	public static bool evaluation = true; 		//true

	public static string preQuestionnaireText = "Welkom in deze neurofeedback training sessie. Voordat we beginnen stellen we u eerst drie vragen over hoe u zich op dit moment voelt. \n\nU kunt uw antwoord geven door met uw vinger de stip te verschuiven naar de meest passende plaats tussen de twee aangegeven woorden.";
	public static string postQuestionnaireText = "Ter afsluiting van deze sessie willen we u graag vragen om een korte vragenlijst in te vullen.";

	public static string[,] preQuestionnaire = new string[3,3]
	{
		{"Hoe voelt u zich op dit moment?","Zeer onplezierig","Zeer plezierig"},
		{"Hoe voelt u zich op dit moment?","Zeer rustig","Zeer opgewonden"},
		{"Voelt u zich op dit moment moe?","Geheel niet","Zeer"}
	};

	public static string[,] postQuestionnaire = new string[20,3]
	{
		{"Hoe voelt u zich op dit moment?","Zeer onplezierig","Zeer plezierig"},
		{"Hoe voelt u zich op dit moment?","Zeer rustig","Zeer opgewonden"},
		{"Voelt u zich op dit moment moe?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment tevreden?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment ontspannen?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment overstuur?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment opgewekt?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment geirriteerd?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment lusteloos?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment somber?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment energiek?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment enthousiast?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment nerveus?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment verveeld?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment kalm?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment angstig?","Geheel niet","Zeer"},
		{"Voelt u zich op dit moment schuldig?","Geheel niet","Zeer"},
		{"Kunt u zich op dit moment goed concentreren?","Geheel niet","Zeer"},
		{"Piekert u op dit moment veel?","Geheel niet","Zeer"},
		{"Hebt u de afgelopen nacht goed geslapen?","Geheel niet","Zeer"}
	};

	public static string[,] evalQuestionnaire = new string[3,3]
	{
		{"Hoeveel controle had u over de bal?","Weinig","Veel"},
		{"Hoe vaak gebruikte u gedachten en gevoelens als strategie voor het bewegen van de bal?","Nooit","Continu"},
		{"Hoe vaak kon u de bal met wilskracht alleen beinvloeden?","Nooit","Continu"}
	};


	// CUES

	public static string introText = "Welkom in deze neurofeedback training sessie.";

	public static string experimentInstructText1 = string.Format ("Nu volgt de trainingsfase. \n\nElke training start met een korte rustmeting met ogen open ({0}s), \ngevolgd door een training met de bal ({1} min.)",baselineDuration,trainingDuration/60f);
	public static string experimentInstructText2 = "Tijdens de training krijgt u een bal te zien die bestuurd wordt door uw hersenactiviteit. Uw doel is om de bal naar u toe te laten bewegen. \n\nDe bal zal lang niet altijd doen wat u wil, maar door goed naar de bal te blijven kijken leert uw brein vanzelf de bal te controleren.";

	public static string farewellText = "Dit is het einde van deze sessie.\nHartelijk dank en tot een volgende keer";

}
